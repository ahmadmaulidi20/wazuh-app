const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

/** Waktu sekarang sebagai WIB (disimpan sebagai UTC-equivalent di DB) */
export function wibNow(): Date {
  return new Date(Date.now() + WIB_OFFSET_MS);
}

/** Parse timestamp Wazuh → simpan sebagai WIB */
export function parseWazuhTimestamp(value?: string): Date {
  if (!value) return wibNow();
  const trimmed = value.trim();
  const hasTimezone = /(Z|[+-]\d{2}:?\d{2})$/.test(trimmed);
  let utcDate: Date;
  if (hasTimezone) {
    utcDate = new Date(trimmed);
  } else {
    utcDate = new Date(`${trimmed}Z`);
  }
  return new Date(utcDate.getTime() + WIB_OFFSET_MS);
}

/** Mulai hari ini dalam WIB (untuk query "alerts today") */
export function wibTodayStart(): Date {
  const now = new Date();
  const wibNow = new Date(now.getTime() + WIB_OFFSET_MS);
  const year = wibNow.getUTCFullYear();
  const month = wibNow.getUTCMonth();
  const day = wibNow.getUTCDate();
  return new Date(Date.UTC(year, month, day));
}
