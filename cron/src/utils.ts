// AWS bucket constants
const { AWS_SOURCE_PREFIX } = process.env;

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

// Get the directory name for the given csv object
// Example csvName is indir/2023-ter-timecheese/test.csv
export function getOrCreateDirectoryName(csvName: string) {
    // Remove the SOURCE_PREFIX from the string.
    // After removal we expect to have two strings, one for the directory (2023-ter-timecheese)
    // and the other for the actual file name (test.csv). At least, the file name is guaranteed.
    const csvObjectTokens = csvName.replace(`${AWS_SOURCE_PREFIX}/`, "").split("/");

    // If there are 2 or more tokens, return the first one as the root directory name
    if (csvObjectTokens.length >= 2) {
        return csvObjectTokens[0];
    }

    // If for some reason there is only a single token (ie just the file name)
    // create a random string for the directory name
    const today = new Date();
    const year = today.getFullYear();
    return `${year}-${generateRandomString(10)}`;
}

// Generate a random alphanumeric string with a given length
function generateRandomString(length: number) {
    let result = "";
    const characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    const charactersLength = characters.length;
    for (let i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}
