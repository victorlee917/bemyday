export type Lang = "en" | "ko";

export const INVITE_TRANSLATIONS = {
  en: {
    invalidTitle: "Invalid or expired invitation",
    backToHome: "Back to home",
    wouldYouBeMy: (weekday: string) => `Would You Be My ${weekday}?`,
    openInApp: "Open in Be My Day",
    appStore: "App Store",
    googlePlay: "Google Play",
    downloadApp: "Download Be My Day",
    expiresIn: "Expires in",
    expired: "Expired",
  },
  ko: {
    invalidTitle: "Invalid or expired invitation",
    backToHome: "Back to home",
    wouldYouBeMy: (weekday: string) => `Would You Be My ${weekday}?`,
    openInApp: "Open in Be My Day",
    appStore: "App Store",
    googlePlay: "Google Play",
    downloadApp: "Download Be My Day",
    expiresIn: "Expires in",
    expired: "Expired",
  },
} as const;

const WEEKDAYS: Record<Lang, string[]> = {
  en: [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday ",
  ],
  ko: [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday ",
  ],
};

export function getWeekday(lang: Lang, weekdayIndex: number): string {
  return WEEKDAYS[lang][(weekdayIndex ?? 1) - 1] ?? WEEKDAYS.en[0];
}
