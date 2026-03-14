/**
 * Daily Reminder - 매일 오후 10시 정기 알림
 *
 * Cron(예: 13:00 UTC = 22:00 KST)으로 호출.
 * alarm_daily_reminder=true, push_enabled=true 인 유저에게 notification_queue에 삽입.
 * (타임존별 22:00 맞추기는 추후 구현)
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: users } = await supabase
      .from("profiles")
      .select("id")
      .eq("push_enabled", true)
      .eq("alarm_daily_reminder", true)
      .is("deleted_at", null);

    if (!users || users.length === 0) {
      return new Response(
        JSON.stringify({ enqueued: 0 }),
        { status: 200, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
      );
    }

    const rows = users.map((u) => ({
      recipient_user_id: u.id,
      notification_type: "daily_reminder",
      payload: {},
    }));

    const { error } = await supabase.from("notification_queue").insert(rows);

    if (error) {
      console.error(error);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ enqueued: rows.length }),
      { status: 200, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error(err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders(), "Content-Type": "application/json" } }
    );
  }
});

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
  };
}
