import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Terms of Service - Be My Day" },
  {
    name: "description",
    content: "Be My Day Terms of Service",
  },
];

export default function Terms() {
  return (
    <main className="max-w-[720px] mx-auto p-8 leading-relaxed">
      <h1 className="text-2xl font-bold mb-4">Terms of Service</h1>
      <p className="text-gray-500 mb-8">
        These are the terms of service for Be My Day (the "Service").
      </p>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">Article 1 (Purpose)</h2>
        <p>
          These terms define the conditions and procedures for using the Be My
          Day service, and the rights and obligations between users and the
          service provider.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">Article 2 (Service Provision)</h2>
        <p>
          The Service provides various features including weekday-based group
          activities and post sharing.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">Article 3 (User Obligations)</h2>
        <p>
          Users must comply with applicable laws and these terms when using the
          Service.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">Article 4 (Contact)</h2>
        <p>
          If you have any questions regarding these terms, please contact us.
        </p>
      </section>

      <Link to="/" className="text-gray-500 hover:text-gray-700">
        ← Back to home
      </Link>
    </main>
  );
}
