import type { LoaderFunctionArgs, MetaFunction } from "@remix-run/node";
import { useLoaderData, Link, useParams } from "@remix-run/react";
import { useEffect, useState } from "react";

import { InviteCard, InviteExpiryCountdown } from "~/components/invite-card";
import { Logo } from "~/components/logo";
import { AppStoreButton, GooglePlayButton } from "~/components/store-buttons";
import { INVITE_TRANSLATIONS, getWeekday, type Lang } from "~/i18n/invite";

const SUPABASE_URL = process.env.SUPABASE_URL ?? "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? "";
const SITE_URL = "https://www.bemyday.app";

const SUPPORTED_LANGS = ["en", "ko"] as const;

function resolveLang(lang: string | undefined): Lang {
  if (lang && SUPPORTED_LANGS.includes(lang as Lang)) return lang as Lang;
  return "en";
}

function getLangFromRequest(
  request: Request,
  pathLang: string | undefined,
): Lang {
  const pathResolved = resolveLang(pathLang);
  if (pathResolved !== "en") return pathResolved;
  try {
    const url = new URL(request.url);
    const host = url.hostname.toLowerCase();
    if (host.startsWith("ko.")) return "ko";
  } catch {
    // ignore
  }
  return pathResolved;
}

export async function loader({ params, request }: LoaderFunctionArgs) {
  const token = params.token;
  if (!token) return { invitation: null, lang: "en" as Lang };

  const lang = getLangFromRequest(request, params.lang);

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error("[invitation] SUPABASE_URL or SUPABASE_ANON_KEY is missing");
    return { invitation: null, lang };
  }

  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/get_invitation_by_token`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({ invite_token: token }),
      },
    );
    const data = await res.json();

    if (
      !res.ok ||
      (data &&
        typeof data === "object" &&
        ("code" in data || "message" in data))
    ) {
      if (!res.ok) {
        console.error("[invitation] Supabase RPC error:", res.status, data);
      }
      return { invitation: null, lang };
    }

    if (data == null) return { invitation: null, lang };

    return { invitation: data, lang };
  } catch (err) {
    console.error("[invitation] Fetch error:", err);
    return { invitation: null, lang };
  }
}

const HEIGHT_THRESHOLD = 667; // iPhone SE 기준 (스토어 버튼)
const LOGO_HEIGHT_THRESHOLD = 600; // 로고 표시 여부

const STORE_BUTTON_CLASS =
  "border border-[rgba(13,13,13,0.05)] flex items-center justify-center rounded-4xl h-[44px] w-[240px] cursor-pointer hover:opacity-90 transition-opacity text-sm font-bold";

function AppOpenButton({
  appOpenUrl,
  isIOS,
  label,
}: {
  appOpenUrl: string;
  isIOS: boolean;
  label: string;
}) {
  const handleClick = () => {
    if (isIOS) {
      const timer = setTimeout(() => {
        window.location.href = "https://apps.apple.com/app/bemyday";
      }, 2000);
      const onVisibilityChange = () => {
        if (document.visibilityState === "visible") return;
        clearTimeout(timer);
        document.removeEventListener("visibilitychange", onVisibilityChange);
      };
      document.addEventListener("visibilitychange", onVisibilityChange);
    }
    window.location.href = appOpenUrl;
  };
  return (
    <button
      type="button"
      onClick={handleClick}
      className={`${STORE_BUTTON_CLASS} bg-black text-white`}
    >
      {label}
    </button>
  );
}

export const meta: MetaFunction<typeof loader> = ({ data, params }) => {
  const inv = data?.invitation;
  const lang = data?.lang ?? "en";
  const token = params.token ?? "";
  const weekdayName = inv ? getWeekday(lang, inv.weekday ?? 1) : "";
  const t = INVITE_TRANSLATIONS[lang];

  const title = inv
    ? `Would you be my ${weekdayName}?`
    : "Invitation - Be My Day";
  const description = inv
    ? `${inv.inviter_nickname} invited you to Be My Day.`
    : "Be My Day invitation";

  const canonicalLang = lang === "en" ? "" : `/${lang}`;
  const canonicalUrl = `${SITE_URL}${canonicalLang}/invitation/${token}`;
  const ogImage = inv
    ? `${SITE_URL}/og/invitation/${token}`
    : `${SITE_URL}/images/app_icon.png`;

  return [
    { title },
    { name: "description", content: description },
    { name: "theme-color", content: "#ffffff" },
    { tagName: "link", rel: "canonical", href: canonicalUrl },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
    { property: "og:url", content: canonicalUrl },
    { property: "og:type", content: "website" },
    { property: "og:image", content: ogImage },
    { property: "og:image:width", content: "1200" },
    { property: "og:image:height", content: "630" },
    { property: "og:site_name", content: "Be My Day" },
    { property: "og:locale", content: lang === "ko" ? "ko_KR" : "en_US" },
    { name: "twitter:card", content: "summary_large_image" },
    { name: "twitter:title", content: title },
    { name: "twitter:description", content: description },
    { name: "twitter:image", content: ogImage },
  ];
};

export default function InviteToken() {
  const { invitation, lang } = useLoaderData<typeof loader>();
  const t = INVITE_TRANSLATIONS[lang];
  const { token } = useParams<{ token: string; lang?: string }>();

  const [viewportHeight, setViewportHeight] = useState(() =>
    typeof window !== "undefined" ? window.innerHeight : 800,
  );
  useEffect(() => {
    const check = () => setViewportHeight(window.innerHeight);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);
  const showLogo = viewportHeight >= LOGO_HEIGHT_THRESHOLD;

  useEffect(() => {
    document.documentElement.style.background = "transparent";
    document.body.style.background = "transparent";
    return () => {
      document.documentElement.style.background = "";
      document.body.style.background = "";
    };
  }, []);

  if (!invitation) {
    return (
      <div className="h-screen flex flex-col justify-between overflow-hidden">
        {showLogo && (
          <header className="fixed top-6 bg-transparent">
            <Logo size={48} />
          </header>
        )}
        <section className="flex-1 min-h-0 flex flex-col items-center justify-center p-8 text-center overflow-hidden">
          <h1 className="font-display text-xl text-black">{t.invalidTitle}</h1>
          <Link
            to="/"
            className="mt-3 text-black text-sm hover:opacity-100 opacity-50"
          >
            {t.backToHome}
          </Link>
        </section>
      </div>
    );
  }

  const weekdayName = getWeekday(lang, invitation.weekday ?? 1);
  const expiresAt = invitation.expires_at
    ? new Date(invitation.expires_at)
    : null;
  const cardWidth = 280;
  const cardHeight = cardWidth * (3 / 2); // 2:3 aspect ratio

  const isAndroid =
    typeof navigator !== "undefined" && /Android/i.test(navigator.userAgent);
  const isIOS =
    typeof navigator !== "undefined" &&
    /iPhone|iPad|iPod/i.test(navigator.userAgent);

  const hasSufficientHeight = viewportHeight >= HEIGHT_THRESHOLD;
  const appOpenUrl = isAndroid
    ? `intent://bemyday.app/invitation/${
        token ?? ""
      }#Intent;scheme=https;package=com.bemyday;S.browser_fallback_url=https://play.google.com/store/apps/details?id=com.bemyday;end`
    : isIOS
    ? `com.bemyday://invitation/${token ?? ""}`
    : `https://bemyday.app/invitation/${token ?? ""}`;

  return (
    <div className="h-screen flex flex-col justify-between overflow-hidden">
      {/* 1. 최상단: 앱 로고 (높이 600px 미만이면 숨김) */}
      {showLogo && (
        <header className="shrink-0 flex justify-center mt-6 bg-transparent">
          <Logo size={48} />
        </header>
      )}

      {/* 2. 중앙: 초대장, 만료 여부 (vh 기준 %로 화면에 맞춰 스케일, 잘리지 않음) */}
      <section className="flex-1 min-h-0 flex flex-col items-center justify-center p-4 text-center overflow-hidden">
        <div className="flex flex-col items-center justify-center gap-4 h-full w-full">
          <div
            className="shrink-0 max-w-[min(280px,85vw)]"
            style={{
              height: "min(45vh, 100%)",
              minHeight: 240,
              aspectRatio: "2/3",
              width: "auto",
            }}
          >
            <InviteCard
              weekdayName={weekdayName}
              inviterNickname={invitation.inviter_nickname ?? "?"}
              inviterAvatarUrl={invitation.inviter_avatar_url}
              gradientColors={invitation.gradient_colors}
              width={cardWidth}
              height={cardHeight}
              fillContainer
            />
          </div>
          {expiresAt && (
            <InviteExpiryCountdown
              expiresAt={expiresAt}
              expiresInLabel={t.expiresIn}
              expiredLabel={t.expired}
            />
          )}
        </div>
      </section>

      {/* 3. 최하단: 액션 버튼 */}
      <footer className="shrink-0 flex flex-col items-center gap-4 pb-6 bg-transparent">
        <div className="flex flex-col items-center gap-3">
          {(isAndroid || isIOS) && (
            <AppOpenButton
              appOpenUrl={appOpenUrl}
              isIOS={isIOS}
              label={t.openInApp}
            />
          )}
          {hasSufficientHeight ? (
            <>
              <AppStoreButton />
              <GooglePlayButton />
            </>
          ) : isIOS ? (
            <AppStoreButton />
          ) : isAndroid ? (
            <GooglePlayButton />
          ) : (
            <>
              <AppStoreButton />
              <GooglePlayButton />
            </>
          )}
        </div>
      </footer>
    </div>
  );
}
