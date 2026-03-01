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
      <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
        <h1 className="text-xl font-semibold">Invalid or expired invitation</h1>
        <Link to="/" className="mt-4 text-gray-500 hover:text-gray-700">
          Back to home
        </Link>
      </main>
    );
  }

  const weekdayName = WEEKDAYS[(invitation.weekday ?? 1) - 1];

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      <h1 className="text-2xl mb-2">{invitation.inviter_nickname} invited you</h1>
      <p className="text-xl mb-8">Would You Be My {weekdayName}?</p>
      <p className="text-gray-500 mb-8">Install the app to accept the invitation</p>
      <div className="flex gap-4 flex-wrap justify-center">
        <a
          href="https://apps.apple.com/app/bemyday"
          target="_blank"
          rel="noopener noreferrer"
          className="px-6 py-3 bg-black text-white no-underline rounded-lg hover:bg-gray-800 transition-colors"
        >
          App Store
        </a>
        <a
          href="https://play.google.com/store/apps/details?id=com.bemyday"
          target="_blank"
          rel="noopener noreferrer"
          className="px-6 py-3 bg-black text-white no-underline rounded-lg hover:bg-gray-800 transition-colors"
        >
          Google Play
        </a>
      </div>
      <Link to="/" className="mt-8 text-gray-500 hover:text-gray-700">
        Back to home
      </Link>
    </main>
  );
}
