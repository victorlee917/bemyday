import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

import { Logo } from "~/components/logo";
import { AppStoreButton, GooglePlayButton } from "~/components/store-buttons";

export const meta: MetaFunction = () => [
  { title: "Be My Day" },
  {
    name: "description",
    content: "Besties who make my day",
  },
];

export default function Index() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center text-center select-none">
      <div className="mb-6">
        <Logo size={64} />
      </div>
      <h1 className="font-display text-4xl mb-4">Be My Day</h1>
      <h2 className="font-display text-md opacity-50 mb-8">
        Besties who make my day
      </h2>
      <div className="flex flex-col items-center gap-4">
        <AppStoreButton />
        <GooglePlayButton />
      </div>
      <div className="fixed bottom-0 mb-6">
        <nav className="flex gap-6 flex-wrap justify-center text-xs">
          <Link
            to="/privacy"
            className="text-black underline hover:opacity-100 opacity-50"
          >
            Privacy Policy
          </Link>
          <Link
            to="/terms"
            className="text-black underline hover:opacity-100 opacity-50"
          >
            Terms of Service
          </Link>
        </nav>
      </div>
    </main>
  );
}
