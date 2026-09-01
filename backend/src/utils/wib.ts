const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

/** Waktu sekarang sebagai WIB-as-UTC (disimpan di DB) */
export function wibNow(): Date {
  return new Date(Date.now() + WIB_OFFSET_MS);
}

/**
 * Parse timestamp Wazuh → simpan sebagai WIB-as-UTC di DB.
 *
 * Aturan:
 *  - Jika timestamp punya zona waktu (Z, +07:00, dst) → gunakan nilai UTC-nya langsung.
 *  - Jika TANPA zona waktu → asumsikan Wazuh mengirim waktu UTC, tambah +7h (WIB).
 *    (Wazuh default mengirim UTC tanpa suffix zona waktu.)
 */
export function parseWazuhTimestamp(value?: string): Date {
  if (!value) return wibNow();
  const trimmed = value.trim();
  const hasTimezone = /(Z|[+-]\d{2}:?\d{2})$/.test(trimmed);
  let utcMs: number;
  if (hasTimezone) {
    utcMs = new Date(trimmed).getTime();
  } else {
    utcMs = new Date(`${trimmed}Z`).getTime();
  }
  return new Date(utcMs + WIB_OFFSET_MS);
}

/** Mulai hari ini dalam WIB-as-UTC (untuk query "alerts today") */
export function wibTodayStart(): Date {
  const now = new Date();
  const wibMs = now.getTime() + WIB_OFFSET_MS;
  const d = new Date(wibMs);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}
