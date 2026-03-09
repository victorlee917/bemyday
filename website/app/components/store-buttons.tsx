const BORDER_CLASS = "border border-[rgba(13,13,13,0.05)]";
const CLICKABLE_AREA_LIGHT = "#f2f2f2"; // CustomColors.clickableAreaLight

const APP_STORE_URL = "https://apps.apple.com/app/bemyday";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.bemyday";

export function StoreDownloadButton({
  label,
  isIOS,
  isAndroid,
}: {
  label: string;
  isIOS: boolean;
  isAndroid: boolean;
}) {
  const href = isIOS ? APP_STORE_URL : isAndroid ? PLAY_STORE_URL : null;
  if (!href) return null;

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      className={`${BORDER_CLASS} flex items-center justify-center rounded-4xl h-[44px] w-[240px] cursor-pointer no-underline hover:opacity-90 transition-opacity text-sm font-bold text-black`}
      style={{ backgroundColor: CLICKABLE_AREA_LIGHT }}
    >
      {label}
    </a>
  );
}

export function AppStoreButton() {
  return (
    <a
      href={APP_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className={`${BORDER_CLASS} relative flex flex-row items-center justify-center bg-black text-white rounded-4xl h-[44px] overflow-hidden w-[240px] cursor-pointer no-underline hover:opacity-90 transition-opacity`}
    >
      <img
        src="/images/app_store.png"
        alt="App Store"
        width={44}
        height={44}
        className="absolute left-0 top-0"
      />
      <span className="text-sm z-10 font-bold">App Store</span>
    </a>
  );
}

export function GooglePlayButton() {
  return (
    <a
      href={PLAY_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      className={`${BORDER_CLASS} relative flex flex-row items-center justify-center bg-[#f2f2f2] text-black rounded-4xl h-[44px] overflow-hidden w-[240px] cursor-pointer no-underline hover:opacity-90 transition-opacity`}
    >
      <img
        src="/images/google_play.png"
        alt="Google Play"
        width={44}
        height={44}
        className="absolute left-0 top-0"
      />
      <span className="text-sm z-10 font-bold">Google Play</span>
    </a>
  );
}
