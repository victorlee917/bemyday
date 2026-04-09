/**
 * Sends an email alert to the developer when a content report is submitted.
 * Called by DB trigger (pg_net) on content_reports / user_blocks INSERT.
 * Requires RESEND_API_KEY secret.
 * Authenticated via service role key only (trigger-to-function).
 */

const ALERT_EMAIL = "tapas.maker@gmail.com";

/** HTML-escape user-supplied values to prevent XSS */
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

Deno.serve(async (req) => {
  try {
    // Verify service role key — only DB triggers should call this function
    const authHeader = req.headers.get("Authorization");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (
      !authHeader ||
      !serviceRoleKey ||
      authHeader !== `Bearer ${serviceRoleKey}`
    ) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) {
      throw new Error("RESEND_API_KEY secret not set");
    }

    const body = await req.json();
    const record = body.record ?? body;
    const targetType = escapeHtml(String(record.target_type ?? "unknown"));
    const targetId = escapeHtml(String(record.target_id ?? "unknown"));
    const reason = escapeHtml(String(record.reason ?? "unknown"));
    const description = escapeHtml(
      String(record.description ?? "").slice(0, 1000) || "\u2014"
    );
    const reporterId = escapeHtml(String(record.reporter_id ?? "unknown"));
    const createdAt = escapeHtml(
      String(record.created_at ?? new Date().toISOString())
    );

    const emailBody = [
      `<h2>New Content Report</h2>`,
      `<table style="border-collapse:collapse;">`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Type</td><td>${targetType}</td></tr>`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Target ID</td><td>${targetId}</td></tr>`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Reason</td><td>${reason}</td></tr>`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Description</td><td>${description}</td></tr>`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Reporter</td><td>${reporterId}</td></tr>`,
      `<tr><td style="padding:4px 12px 4px 0;font-weight:bold;">Time</td><td>${createdAt}</td></tr>`,
      `</table>`,
    ].join("\n");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendKey}`,
      },
      body: JSON.stringify({
        from: "Be My Day <onboarding@resend.dev>",
        to: [ALERT_EMAIL],
        subject: `[BMD Report] ${reason} — ${targetType} (${targetId.substring(0, 8)})`,
        html: emailBody,
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      console.error("Resend error:", res.status, err);
      return new Response(JSON.stringify({ error: "Email delivery failed" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const result = await res.json();
    return new Response(JSON.stringify({ success: true, id: result.id }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
