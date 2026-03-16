import type { LoaderFunctionArgs } from "@remix-run/node";
import { redirect } from "@remix-run/node";
import { ImageResponse } from "@vercel/og";

const SUPABASE_URL = process.env.SUPABASE_URL ?? "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? "";
const SITE_URL = "https://www.bemyday.app";
const DEFAULT_OG_IMAGE = `${SITE_URL}/ogImg.png`;

function parseGradientColors(value: unknown): string[] | null {
  if (!value || !Array.isArray(value)) return null;
  const colors: string[] = [];
  for (const item of value) {
    if (typeof item === "string" && item.startsWith("#") && item.length === 7) {
      colors.push(item);
    }
  }
  return colors.length >= 3 ? colors : null;
}

export async function loader({ params }: LoaderFunctionArgs) {
  const token = params.token;
  if (!token) {
    return new Response("Not found", { status: 404 });
  }

  let invitation: {
    inviter_avatar_url?: string | null;
    inviter_nickname?: string | null;
    gradient_colors?: unknown;
  } | null = null;

  if (SUPABASE_URL && SUPABASE_ANON_KEY) {
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
        }
      );
      const data = await res.json();
      if (res.ok && data != null && !("code" in data)) {
        invitation = data;
      }
    } catch (err) {
      console.error("[og.invitation] Fetch error:", err);
    }
  }

  const colors = invitation
    ? parseGradientColors(invitation.gradient_colors)
    : null;
  const hasGradient = colors && colors.length >= 3;

  if (!invitation || !hasGradient) {
    return redirect(DEFAULT_OG_IMAGE);
  }

  const avatarUrl = invitation.inviter_avatar_url;
  const nickname = invitation.inviter_nickname ?? "";
  const initial = nickname ? nickname[0].toUpperCase() : "?";

  const gradientStyle = {
    background: `linear-gradient(to bottom right, ${colors
      .map((c) => `${c}da`)
      .join(", ")})`,
  };

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          ...gradientStyle,
        }}
      >
        {avatarUrl ? (
          <img
            src={avatarUrl}
            alt=""
            width={280}
            height={280}
            style={{
              borderRadius: 9999,
              objectFit: "cover",
            }}
          />
        ) : (
          <div
            style={{
              width: 280,
              height: 280,
              borderRadius: 9999,
              backgroundColor: "rgba(255,255,255,0.3)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 112,
              color: "white",
              fontWeight: 600,
            }}
          >
            {initial}
          </div>
        )}
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
