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
    const hash = window.location.hash;
    if (hash && hash.includes("access_token") && !hash.includes("error=")) {
      // Redirect to app with tokens; app will recover session
      window.location.replace(`${APP_SCHEME}${hash}`);
    }
  }, []);

  const hash = typeof window !== "undefined" ? window.location.hash : "";
  const hasTokens = hash.includes("access_token") && !hash.includes("error=");

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      {hasTokens ? (
        <>
          <p className="text-lg mb-4">Opening Be My Day...</p>
          <p className="text-gray-500 text-sm mb-8">
            If the app doesn't open,{" "}
            <a
              href={`${APP_SCHEME}${hash}`}
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
