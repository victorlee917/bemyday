import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Be My Day - Pals who make my day" },
  {
    name: "description",
    content: "Be My Day - Pals who make my day",
  },
];

export default function Index() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      <h1 className="text-4xl mb-2">Be My Day</h1>
      <p className="opacity-70 mb-8">Pals who make my day</p>
      <nav className="flex gap-4 flex-wrap justify-center">
        <Link to="/privacy" className="text-gray-500 underline hover:text-gray-700">
          Privacy Policy
        </Link>
        <Link to="/terms" className="text-gray-500 underline hover:text-gray-700">
          Terms of Service
        </Link>
      </nav>
    </main>
  );
}
