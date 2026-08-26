const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

export function parseWazuhTimestamp(value?: string): Date {
  if (!value) return new Date();
  const trimmed = value.trim();
  const hasTimezone = /(Z|[+-]\d{2}:?\d{2})$/.test(trimmed);
  if (hasTimezone) {
    return new Date(trimmed);
  }
  return new Date(new Date(`${trimmed}Z`).getTime() - WIB_OFFSET_MS);
}

export function wibTodayStart(): Date {
  const now = new Date();
  const wibNow = new Date(now.getTime() + WIB_OFFSET_MS);
  const year = wibNow.getUTCFullYear();
  const month = wibNow.getUTCMonth();
  const day = wibNow.getUTCDate();
  return new Date(Date.UTC(year, month, day) - WIB_OFFSET_MS);
}
