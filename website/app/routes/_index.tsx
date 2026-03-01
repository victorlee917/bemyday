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
    <main
      style={{
        minHeight: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "2rem",
        textAlign: "center",
      }}
    >
      <h1 style={{ fontSize: "2.5rem", marginBottom: "0.5rem" }}>
        Be My Day
      </h1>
      <p style={{ opacity: 0.7, marginBottom: "2rem" }}>
        Pals who make my day
      </p>
      <nav style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
        <Link
          to="/privacy"
          style={{
            color: "#666",
            textDecoration: "underline",
          }}
        >
          Privacy Policy
        </Link>
        <Link
          to="/terms"
          style={{
            color: "#666",
            textDecoration: "underline",
          }}
        >
          Terms of Service
        </Link>
      </nav>
    </main>
  );
}
