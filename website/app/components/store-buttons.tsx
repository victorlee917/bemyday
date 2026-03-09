const BORDER_CLASS = "border border-[rgba(13,13,13,0.05)]";

export function AppStoreButton() {
  return (
    <a
      href="https://apps.apple.com/app/bemyday"
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
      href="https://play.google.com/store/apps/details?id=com.bemyday"
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
