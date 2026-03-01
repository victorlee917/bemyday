import type { LoaderFunctionArgs, MetaFunction } from "@remix-run/node";
import { useLoaderData, Link } from "@remix-run/react";

const SUPABASE_URL = process.env.SUPABASE_URL ?? "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? "";

export async function loader({ params }: LoaderFunctionArgs) {
  const token = params.token;
  if (!token) return { invitation: null };

  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_invitation_by_token`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      },
      body: JSON.stringify({ invite_token: token }),
    });
    const data = await res.json();
    return { invitation: data };
  } catch {
    return { invitation: null };
  }
}

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export const meta: MetaFunction<typeof loader> = ({ data }) => {
  const inv = data?.invitation;
  const weekdayName = inv ? WEEKDAYS[(inv.weekday ?? 1) - 1] : "";
  const title = inv
    ? `${inv.inviter_nickname} invited you - Be My Day`
    : "Invitation - Be My Day";
  const description = inv
    ? `Would you be my ${weekdayName}? ${inv.inviter_nickname} invited you to Be My Day.`
    : "Be My Day invitation";
  return [
    { title },
    { name: "description", content: description },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
  ];
};

export default function InviteToken() {
  const { invitation } = useLoaderData<typeof loader>();

  if (!invitation) {
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
        <h1>Invalid or expired invitation</h1>
        <Link to="/" style={{ marginTop: "1rem", color: "#666" }}>
          Back to home
        </Link>
      </main>
    );
  }

  const weekdayName = WEEKDAYS[(invitation.weekday ?? 1) - 1];

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
      <h1 style={{ fontSize: "1.5rem", marginBottom: "0.5rem" }}>
        {invitation.inviter_nickname} invited you
      </h1>
      <p style={{ fontSize: "1.25rem", marginBottom: "2rem" }}>
        Would You Be My {weekdayName}?
      </p>
      <p style={{ color: "#666", marginBottom: "2rem" }}>
        Install the app to accept the invitation
      </p>
      <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
        <a
          href="https://apps.apple.com/app/bemyday"
          target="_blank"
          rel="noopener noreferrer"
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#000",
            color: "#fff",
            textDecoration: "none",
            borderRadius: "8px",
          }}
        >
          App Store
        </a>
        <a
          href="https://play.google.com/store/apps/details?id=com.bemyday"
          target="_blank"
          rel="noopener noreferrer"
          style={{
            padding: "0.75rem 1.5rem",
            backgroundColor: "#000",
            color: "#fff",
            textDecoration: "none",
            borderRadius: "8px",
          }}
        >
          Google Play
        </a>
      </div>
      <Link to="/" style={{ marginTop: "2rem", color: "#666" }}>
        Back to home
      </Link>
    </main>
  );
}
