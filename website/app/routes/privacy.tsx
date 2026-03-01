import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Privacy Policy - Be My Day" },
  {
    name: "description",
    content: "Be My Day Privacy Policy",
  },
];

export default function Privacy() {
  return (
    <main className="max-w-[720px] mx-auto p-8 leading-relaxed">
      <h1 className="text-2xl font-bold mb-4">Privacy Policy</h1>
      <p className="text-gray-500 mb-8">
        Be My Day (the "Service") values your privacy and complies with
        applicable laws and regulations.
      </p>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">1. Information We Collect</h2>
        <p>
          We may collect email, nickname, profile photo, and other necessary
          information during sign-up and service use.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">2. How We Use Your Information</h2>
        <p>
          Collected information is used only for the stated purposes, including
          service provision, account management, and customer support.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">3. Data Protection</h2>
        <p>
          We implement technical and administrative measures to protect your
          personal information.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">4. Contact</h2>
        <p>
          If you have any questions about our privacy practices, please contact
          us.
        </p>
      </section>

      <Link to="/" className="text-gray-500 hover:text-gray-700">
        ← Back to home
      </Link>
    </main>
  );
}
