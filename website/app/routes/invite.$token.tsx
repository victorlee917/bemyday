import type { LoaderFunctionArgs, MetaFunction } from "@remix-run/node";
import { useLoaderData, Link, useParams } from "@remix-run/react";

const SUPABASE_URL = process.env.SUPABASE_URL ?? "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? "";

export async function loader({ params }: LoaderFunctionArgs) {
  const token = params.token;
  if (!token) return { invitation: null };

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error("[invite] SUPABASE_URL or SUPABASE_ANON_KEY is missing");
    return { invitation: null };
  }

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_invitation_by_token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify({ invite_token: token }),
    });
    const data = await res.json();

    // Supabase 에러 응답 또는 유효하지 않은 응답
    if (!res.ok || (data && typeof data === "object" && ("code" in data || "message" in data))) {
      if (!res.ok) {
        console.error("[invite] Supabase RPC error:", res.status, data);
      }
      return { invitation: null };
    }

    // RPC가 null 반환 (토큰 없음/만료/그룹 삭제)
    if (data == null) return { invitation: null };

    return { invitation: data };
  } catch (err) {
    console.error("[invite] Fetch error:", err);
    return { invitation: null };
  }
}

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function AppOpenButton({ appOpenUrl, isIOS }: { appOpenUrl: string; isIOS: boolean }) {
  const handleClick = () => {
    if (isIOS) {
      // iOS: 앱 미설치 시 2초 후 App Store로
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
      className="px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors w-full max-w-xs border-0 cursor-pointer font-inherit text-base"
    >
      앱에서 열기
    </button>
  );
}

export const meta: MetaFunction<typeof loader> = ({ data }) => {
  const inv = data?.invitation;
  const weekdayName = inv ? WEEKDAYS[(inv.weekday ?? 1) - 1] : "";
  const title = inv
    ? `${inv.inviter_nickname} invited you - Be My Day`
    : "Invitation - Be My Day";
  const description = inv
    ? `Would you be my ${weekdayName}? ${inv.inviter_nickname} invited you to Be My Day.`
    : "Be My Day invitation";
  return [
    { title },
    { name: "description", content: description },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
  ];
};

export default function InviteToken() {
  const { invitation } = useLoaderData<typeof loader>();

  if (!invitation) {
    return (
      <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
        <h1 className="text-xl font-semibold">Invalid or expired invitation</h1>
        <Link to="/" className="mt-4 text-gray-500 hover:text-gray-700">
          Back to home
        </Link>
      </main>
    );
  }

  const weekdayName = WEEKDAYS[(invitation.weekday ?? 1) - 1];
  const { token } = useParams<{ token: string }>();

  // 카카오톡 등 인앱 브라우저: Intent URL(Android) / 커스텀 스킴(iOS)
  const isAndroid = typeof navigator !== "undefined" && /Android/i.test(navigator.userAgent);
  const isIOS = typeof navigator !== "undefined" && /iPhone|iPad|iPod/i.test(navigator.userAgent);
  const appOpenUrl = isAndroid
    ? `intent://bemyday.app/invite/${token ?? ""}#Intent;scheme=https;package=com.bemyday;S.browser_fallback_url=https://play.google.com/store/apps/details?id=com.bemyday;end`
    : isIOS
      ? `com.bemyday://invite/${token ?? ""}`
      : `https://bemyday.app/invite/${token ?? ""}`;

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      <h1 className="text-2xl mb-2">{invitation.inviter_nickname} invited you</h1>
      <p className="text-xl mb-8">Would You Be My {weekdayName}?</p>
      <p className="text-gray-500 mb-8">Install the app to accept the invitation</p>
      <div className="flex flex-col gap-4 items-center">
        {(isAndroid || isIOS) && (
          <AppOpenButton
            appOpenUrl={appOpenUrl}
            isIOS={isIOS}
          />
        )}
        <div className="flex gap-4 flex-wrap justify-center">
          <a
            href="https://apps.apple.com/app/bemyday"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3 bg-black text-white no-underline rounded-lg hover:bg-gray-800 transition-colors"
          >
            App Store
          </a>
          <a
            href="https://play.google.com/store/apps/details?id=com.bemyday"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3 bg-black text-white no-underline rounded-lg hover:bg-gray-800 transition-colors"
          >
            Google Play
          </a>
        </div>
      </div>
      <Link to="/" className="mt-8 text-gray-500 hover:text-gray-700">
        Back to home
      </Link>
    </main>
  );
}
