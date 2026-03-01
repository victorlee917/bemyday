import type { MetaFunction } from "@remix-run/node";
import { useEffect } from "react";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Signing in - Be My Day" },
  { name: "robots", content: "noindex" },
];

const APP_SCHEME = "com.bemyday://login-callback";

export default function AuthCallback() {
  useEffect(() => {
    if (typeof window === "undefined") return;

    const hash = window.location.hash;
    const search = window.location.search;

    // Implicit flow: tokens in hash (#access_token=...)
    const hasHashTokens =
      hash && hash.includes("access_token") && !hash.includes("error=");
    // PKCE flow: code in query (?code=...)
    const hasCode = search && search.includes("code=") && !search.includes("error=");

    if (hasHashTokens) {
      window.location.replace(`${APP_SCHEME}${hash}`);
    } else if (hasCode) {
      window.location.replace(`${APP_SCHEME}${search}`);
    }
  }, []);

  const hash = typeof window !== "undefined" ? window.location.hash : "";
  const search = typeof window !== "undefined" ? window.location.search : "";
  const hasHashTokens = hash.includes("access_token") && !hash.includes("error=");
  const hasCode = search.includes("code=") && !search.includes("error=");
  const hasAuthData = hasHashTokens || hasCode;

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      {hasAuthData ? (
        <>
          <p className="text-lg mb-4">Opening Be My Day...</p>
          <p className="text-gray-500 text-sm mb-8">
            If the app doesn't open,{" "}
            <a
              href={`${APP_SCHEME}${hasHashTokens ? hash : search}`}
              className="text-blue-600 underline"
            >
              tap here
            </a>
          </p>
        </>
      ) : (
        <>
          <p className="text-lg mb-4">No sign-in data received.</p>
          <Link to="/" className="text-blue-600 underline">
            Back to home
          </Link>
        </>
      )}
    </main>
  );
}
