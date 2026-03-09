export function Logo({
  size = 80,
  className,
}: {
  size?: number;
  className?: string;
}) {
  return (
    <div
      className={[
        "shadow-lg rounded-xl border border-gray-100 overflow-hidden shrink-0",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      style={{ width: size, height: size }}
    >
      <img
        src="/images/app_icon.png"
        alt="Be My Day"
        width={size}
        height={size}
        className="w-full h-full object-cover"
      />
    </div>
  );
}
