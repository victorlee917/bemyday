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
    <main
      style={{
        maxWidth: "720px",
        margin: "0 auto",
        padding: "2rem",
        lineHeight: 1.7,
      }}
    >
      <h1>Privacy Policy</h1>
      <p style={{ color: "#666", marginBottom: "2rem" }}>
        Be My Day (the "Service") values your privacy and complies with
        applicable laws and regulations.
      </p>

      <section style={{ marginBottom: "2rem" }}>
        <h2>1. Information We Collect</h2>
        <p>
          We may collect email, nickname, profile photo, and other necessary
          information during sign-up and service use.
        </p>
      </section>

      <section style={{ marginBottom: "2rem" }}>
        <h2>2. How We Use Your Information</h2>
        <p>
          Collected information is used only for the stated purposes, including
          service provision, account management, and customer support.
        </p>
      </section>

      <section style={{ marginBottom: "2rem" }}>
        <h2>3. Data Protection</h2>
        <p>
          We implement technical and administrative measures to protect your
          personal information.
        </p>
      </section>

      <section style={{ marginBottom: "2rem" }}>
        <h2>4. Contact</h2>
        <p>
          If you have any questions about our privacy practices, please contact
          us.
        </p>
      </section>

      <Link to="/" style={{ color: "#666" }}>
        ← Back to home
      </Link>
    </main>
  );
}
