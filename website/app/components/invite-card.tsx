import * as React from "react";

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

function formatCountdown(ms: number): string {
  if (ms <= 0) return "0s";
  const totalSeconds = Math.floor(ms / 1000);
  const days = Math.floor(totalSeconds / 86400);
  const hours = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  const parts: string[] = [];
  if (days > 0) parts.push(`${days}d`);
  if (days > 0 || hours > 0) parts.push(`${hours}h`);
  if (days > 0 || hours > 0 || minutes > 0) parts.push(`${minutes}m`);
  parts.push(`${seconds}s`);
  return parts.join(" ");
}

function InviteAvatar({
  nickname,
  avatarUrl,
}: {
  nickname: string;
  avatarUrl?: string | null;
}) {
  const initial = nickname ? nickname[0].toUpperCase() : "?";
  const size = "clamp(24px, 15cqh, 64px)";

  if (avatarUrl) {
    return (
      <img
        src={avatarUrl}
        alt={nickname}
        className="rounded-full object-cover"
        style={{ width: size, height: size, minWidth: 24, minHeight: 24 } as React.CSSProperties}
      />
    );
  }
  return (
    <div
      className="rounded-full bg-white/30 flex items-center justify-center text-white font-semibold"
      style={{
        width: size,
        height: size,
        minWidth: 24,
        minHeight: 24,
        fontSize: "clamp(12px, 7.5cqh, 32px)",
      } as React.CSSProperties}
    >
      {initial}
    </div>
  );
}

export function InviteCard({
  weekdayName,
  inviterNickname,
  inviterAvatarUrl,
  gradientColors,
  width,
  height,
  fillContainer,
}: {
  weekdayName: string;
  inviterNickname: string;
  inviterAvatarUrl?: string | null;
  gradientColors?: unknown;
  width: number;
  height: number;
  fillContainer?: boolean;
}) {
  const colors = parseGradientColors(gradientColors);
  const hasGradient = colors && colors.length >= 3;
  const defaultBg = "#f5f5f5";
  const hasAvatar = !!inviterAvatarUrl;

  const overlayStyle = hasGradient
    ? {
        background: `linear-gradient(to bottom right, ${colors
          .map((c) => `${c}da`)
          .join(", ")})`,
      }
    : hasAvatar
      ? { backgroundColor: "rgba(0,0,0,0.3)" }
      : { backgroundColor: defaultBg };

  const sizeStyle = fillContainer
    ? { width: "100%", height: "100%" }
    : { width, height };

  return (
    <div
      className="rounded-3xl border overflow-hidden shrink-0 relative"
      style={{
        ...sizeStyle,
        containerType: "size",
        borderColor: "rgba(13,13,13,0.05)",
        boxShadow: "0 4px 8px rgba(0,0,0,0.1)",
      } as React.CSSProperties}
    >
      {/* Blurred avatar background (when avatar exists) */}
      {hasAvatar && (
        <div
          className="absolute inset-0"
          style={{ transform: "scale(1.15)" }}
        >
          <img
            src={inviterAvatarUrl!}
            alt=""
            className="w-full h-full object-cover blur-md"
          />
        </div>
      )}
      {/* Gradient or overlay */}
      <div className="absolute inset-0" style={overlayStyle} />
      {/* Content (cqh로 카드 높이에 맞춰 스케일) */}
      <div className="relative h-full flex flex-col justify-between p-[clamp(8px,3cqh,16px)]">
        <span
          className="text-white font-semibold shrink-0"
          style={{ fontSize: "clamp(10px, 2.8cqh, 12px)" } as React.CSSProperties}
        >
          Invitation
        </span>
        <div
          className="flex flex-col items-center justify-center shrink-0"
          style={{ gap: "clamp(8px, 5cqh, 24px)" } as React.CSSProperties}
        >
          <InviteAvatar
            nickname={inviterNickname}
            avatarUrl={inviterAvatarUrl}
          />
          <p
            className="font-display text-white font-bold text-center leading-tight"
            style={{ fontSize: "clamp(14px, 5.7cqh, 24px)" } as React.CSSProperties}
          >
            Would You Be
            <br />
            My {weekdayName}?
          </p>
        </div>
        <div className="text-center shrink-0">
          <p
            className="text-white/50"
            style={{ fontSize: "clamp(8px, 2.4cqh, 10px)" } as React.CSSProperties}
          >
            From.
          </p>
          <p
            className="text-white font-semibold mt-0.5"
            style={{ fontSize: "clamp(10px, 3.3cqh, 14px)" } as React.CSSProperties}
          >
            {inviterNickname}
          </p>
        </div>
      </div>
    </div>
  );
}

export function InviteExpiryCountdown({
  expiresAt,
  expiresInLabel,
  expiredLabel,
}: {
  expiresAt: Date;
  expiresInLabel: string;
  expiredLabel: string;
}) {
  const [remaining, setRemaining] = React.useState(() =>
    expiresAt.getTime() - Date.now()
  );

  React.useEffect(() => {
    const interval = setInterval(() => {
      setRemaining(expiresAt.getTime() - Date.now());
    }, 1000);
    return () => clearInterval(interval);
  }, [expiresAt]);

  const textColor = "rgb(55 65 81)"; // gray-700 for light mode

  if (remaining <= 0) {
    return (
      <div
        className="px-3 py-1 rounded-full border text-[10px] font-medium"
        style={{
          backgroundColor: "#f5f5f5",
          borderColor: "rgba(13,13,13,0.05)",
          color: textColor,
        }}
      >
        {expiredLabel}
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-1">
      <span
        className="text-[10px] font-medium opacity-70"
        style={{ color: textColor }}
      >
        {expiresInLabel}
      </span>
      <div
        className="px-3 py-1 rounded-full border text-xs font-bold tracking-wider"
        style={{
          backgroundColor: "#f5f5f5",
          borderColor: "rgba(13,13,13,0.05)",
          color: textColor,
        }}
      >
        {formatCountdown(remaining)}
      </div>
    </div>
  );
}
