/**
 * notification_queue를 읽어 FCM으로 푸시 발송
 *
 * Cron(예: 매분) 또는 Database Webhook으로 호출.
 * FIREBASE_SERVICE_ACCOUNT 시크릿에 서비스 계정 JSON 전체 저장.
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

const MESSAGES: Record<
  string,
  (p: Record<string, unknown>) => { title: string; body: string }
> = {
  daily_reminder: (p) => ({
    title: "Be My Day",
    body: `${p.weekday_name ?? "Your day"} Unlocked! Make your besties' day.`,
  }),
  new_post: (p) => ({
    title: "Be My Day",
    body: `${p.author_nickname ?? "Someone"} has a new update`,
  }),
  new_comment: (p) => ({
    title: "Be My Day",
    body: `${p.author_nickname ?? "Someone"} commented on your post`,
  }),
  new_like: (p) => ({
    title: "Be My Day",
    body: `${p.liker_nickname ?? "Someone"} liked your post`,
  }),
  new_member: (p) => ({
    title: "Be My Day",
    body: `${p.invitee_nickname ?? "Someone"} is your ${p.weekday_name ?? "day"}`,
  }),
  comment_mention: (p) => ({
    title: "Be My Day",
    body: `${p.mentioner_nickname ?? "Someone"} mentioned you!`,
  }),
};

async function getFcmAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const jwt = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const tokens = await jwt.authorize();
  return tokens!.access_token!;
}

/** 수신자가 행위자 본인인 알림은 발송하지 않음 (큐 오염·구 payload 대비) */
function shouldSkipSelfNotification(
  notificationType: string,
  recipientUserId: string,
  payload: Record<string, unknown> | null,
): boolean {
  if (!payload) return false;
  const r = String(recipientUserId);
  const id = (k: string): string | null => {
    const v = payload[k];
    if (v == null) return null;
    return String(v);
  };
  switch (notificationType) {
    case "new_post": {
      const actor = id("author_id");
      return actor != null && actor === r;
    }
    case "new_comment": {
      const commentAuthor = id("comment_author_id");
      return commentAuthor != null && commentAuthor === r;
    }
    case "new_like": {
      const liker = id("liker_user_id");
      return liker != null && liker === r;
    }
    case "comment_mention": {
      const mentioner = id("mentioner_user_id");
      return mentioner != null && mentioner === r;
    }
    default:
      return false;
  }
}

async function sendFcm(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: data ?? {},
        },
      }),
    },
  );
  if (!res.ok) {
    const err = await res.text();
    console.error("FCM error:", res.status, err);
    return false;
  }
  return true;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  try {
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT secret not set");
    }
    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const accessToken = await getFcmAccessToken(serviceAccount);

    const { data: pending } = await supabase
      .from("notification_queue")
      .select("id, recipient_user_id, notification_type, payload")
      .is("sent_at", null)
      .order("created_at", { ascending: true })
      .limit(100);

    if (!pending || pending.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      });
    }

    let sent = 0;
    let skippedSelf = 0;
    for (const row of pending) {
      const payload = (row.payload as Record<string, unknown>) ?? null;
      if (
        shouldSkipSelfNotification(
          row.notification_type,
          row.recipient_user_id,
          payload,
        )
      ) {
        await supabase
          .from("notification_queue")
          .update({ sent_at: new Date().toISOString() })
          .eq("id", row.id);
        skippedSelf++;
        continue;
      }

      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token")
        .eq("user_id", row.recipient_user_id);

      const builder = MESSAGES[row.notification_type];
      const { title, body } = builder
        ? builder(payload ?? {})
        : { title: "Be My Day", body: "You have a new notification" };

      if (tokens && tokens.length > 0) {
        for (const { token } of tokens) {
          const ok = await sendFcm(accessToken, projectId, token, title, body, {
            notification_type: row.notification_type,
          });
          if (ok) sent++;
        }
      }

      await supabase
        .from("notification_queue")
        .update({ sent_at: new Date().toISOString() })
        .eq("id", row.id);
    }

    return new Response(
      JSON.stringify({
        sent,
        processed: pending.length,
        skipped_self: skippedSelf,
      }),
      {
        status: 200,
        headers: { ...corsHeaders(), "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders(), "Content-Type": "application/json" },
    });
  }
});

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}
