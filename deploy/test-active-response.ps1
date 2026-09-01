# test-active-response.ps1
# Orkestrator uji active response Wazuh (blok otomatis firewall-drop) dari Windows.
#
# Alur:
#   1. Deteksi IP publik client (default: IP sesi SSH aktif di server)
#   2. Baseline konektivitas (ping, HTTPS)
#   3. Upload & jalankan test-active-response.sh (injeksi login gagal ke auth.log)
#   4. Jadwalkan bukti sisi server (ar-proof-job.sh -> /home/wazuh/ar-proof.txt)
#   5. Verifikasi blokir dari client (ping, curl, SSH harus gagal)
#   6. Tunggu auto-unblock (default timeout Wazuh = 600 detik) lalu verifikasi pulih
#
# PERINGATAN: selama uji, IP client akan kehilangan SEMUA akses ke server
# hingga auto-unblock (default 600 detik). Jangan jalankan saat Anda butuh
# akses server. IP lain yang sedang terhubung TIDAK terpengaruh.

param(
    [string]$Server = "103.30.194.158",
    [string]$Domain  = "https://siemkampus-monitoring-app.duckdns.org",
    [string]$User    = "wazuh",
    [string]$Pass    = "@Wazuh1234567890",
    [string]$TargetIp = "",                 # kosong = pakai IP sesi SSH aktif
    [int]$LockoutSec = 600                  # default timeout AR Wazuh
)

$ErrorActionPreference = "Stop"
$Plink = "C:\Program Files\PuTTY\plink.exe"
$Pscp  = "C:\Program Files\PuTTY\pscp.exe"

function Invoke-Ssh([string]$Cmd, [int]$TimeoutSec = 60) {
    & $Plink -ssh "$User@$Server" -pw $Pass -batch $Cmd
    if ($LASTEXITCODE -ne 0) { throw "SSH gagal: $Cmd" }
}

# 1. Deteksi IP publik client
if (-not $TargetIp) {
    $out = Invoke-Ssh "who"
    $m = [regex]::Match(($out -join "`n"), "\((\d+\.\d+\.\d+\.\d+)\)")
    $TargetIp = $m.Groups[1].Value
    Write-Host "[1] IP client terdeteksi: $TargetIp (dari 'who')"
} else {
    Write-Host "[1] IP client: $TargetIp"
}

# 2. Baseline
Write-Host "[2] Baseline konektivitas..."
Write-Host "    ping : $(if (Test-Connection $Server -Count 2 -Quiet) {'OK'} else {'GAGAL'})"
$c = curl.exe -sI -m 10 $Domain 2>$null
Write-Host "    https: $(if ($LASTEXITCODE -eq 0) {'OK'} else {"GAGAL (exit $LASTEXITCODE)"})"

# 3-4. Upload + trigger + jadwalkan bukti
Write-Host "[3] Upload script & trigger active response untuk $TargetIp ..."
& $Pscp -pw $Pass "deploy\test-active-response.sh" "$User@$Server:/home/wazuh/test-active-response.sh" | Out-Null
& $Pscp -pw $Pass "deploy\ar-proof-job.sh" "$User@$Server:/home/wazuh/ar-proof-job.sh" | Out-Null
Invoke-Ssh "echo '$Pass' | sudo -S bash /home/wazuh/test-active-response.sh $TargetIp"
Invoke-Ssh "echo '$Pass' | sudo -S bash -c 'nohup bash /home/wazuh/ar-proof-job.sh $TargetIp >/dev/null 2>&1 & echo proof-job-scheduled'"

# 5. Verifikasi blokir (tunggu rule aktif ~18 detik)
Write-Host "[4] Tunggu rule aktif... (blokir akan memutus koneksi SSH Anda)"
Start-Sleep -Seconds 18

Write-Host "    ping : $(if (Test-Connection $Server -Count 2 -Quiet) {'MASIH OK (blokir GAGAL)'} else {'GAGAL -> TERBLOKIR'})"
$c = curl.exe -sI -m 8 $Domain 2>$null
Write-Host "    https: $(if ($LASTEXITCODE -eq 0) {'MASIH OK (blokir GAGAL)'} else {"timeout -> TERBLOKIR (exit $LASTEXITCODE)"})"

$sshJob = Start-Job -ScriptBlock {
    param($p, $u, $s, $pw)
    & $p -ssh "$u@$s" -pw $pw -batch "echo ok"
} -ArgumentList $Plink, $User, $Server, $Pass
if (-not (Wait-Job $sshJob -Timeout 15)) {
    Stop-Job $sshJob; Remove-Job $sshJob -Force
    Write-Host "    ssh  : TIMEOUT -> TERBLOKIR"
} else {
    Remove-Job $sshJob -Force
    Write-Host "    ssh  : MASIH TERHUBUNG (blokir GAGAL)"
}

# 6. Tunggu auto-unblock lalu verifikasi pemulihan
Write-Host "[5] Tunggu auto-unblock (${LockoutSec}s)... IP $TargetIp tidak bisa akses server selama ini."
Start-Sleep -Seconds ($LockoutSec + 10)

$recovered = $false
for ($try = 1; $try -le 5 -and -not $recovered; $try++) {
    try {
        Invoke-Ssh "echo '=== auto-unblock ==='; echo '$Pass' | sudo -S tail -5 /var/ossec/logs/active-responses.log; echo '---'; echo '$Pass' | sudo -S iptables -S | grep '$TargetIp' || echo '(rule iptables sudah hilang)'; echo '---'; cat /home/wazuh/ar-proof.txt" 90
        $recovered = $true
    } catch {
        Write-Host "    percobaan $try belum pulih, tunggu 15s..."; Start-Sleep -Seconds 15
    }
}

if (-not $recovered) { throw "Koneksi tidak pulih setelah auto-unblock!" }
Write-Host "[6] PULIH: SSH kembali normal, lihat output di atas untuk bukti add/delete & rule firewall."
