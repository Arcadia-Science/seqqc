// Given an array of string that can be truth-y or false-y, filter the false-y
// ones, filter the strings that don't contain the "@" symbol and combine
// the rest with commas.
export function combineEmails(strings: (string | false | null | undefined)[]) {
    return strings
        .filter(Boolean)
        .filter((s: string) => s.includes("@"))
        .join(",");
}

// Returns the start datetime of yesterday in UTC timezone
export function startOfYesterdayUTC() {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 1));
}

// Returns the start datetime of today in UTC timezone
export function startOfTodayUTC() {
    const now = new Date();
    return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
}
