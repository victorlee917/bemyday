import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Terms of Service - Be My Day" },
  {
    name: "description",
    content:
      "Be My Day terms of service. Operator: Tapas Maker. https://bemyday.app",
  },
];

export default function Terms() {
  return (
    <main className="max-w-[720px] mx-auto p-8 leading-relaxed">
      <h1 className="text-2xl font-bold mb-4">Terms of Service</h1>
      <p className="text-gray-500 mb-8">
        Last updated: March 24, 2026. These Terms of Service (&quot;Terms&quot;)
        govern your use of the Be My Day mobile application and related
        information and links published by <strong>Tapas Maker</strong> (the
        &quot;Operator&quot;) at{" "}
        <a
          href="https://bemyday.app"
          className="text-gray-700 underline hover:text-gray-900"
        >
          https://bemyday.app
        </a>{" "}
        (together with the app, the &quot;Service&quot;). By creating an account
        or using the Service, you agree to these Terms and our{" "}
        <a
          href="https://bemyday.app/privacy"
          className="text-gray-700 underline hover:text-gray-900"
        >
          Privacy Policy
        </a>
        .
      </p>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">1. What Be My Day is</h2>
        <p className="mb-3">
          Be My Day is a <strong>private, friends-first</strong> service: you
          create or join small groups tied to a <strong>weekday</strong>, share
          <strong>photo posts</strong> with your group for each week, see{" "}
          <strong>streaks</strong> and light stats, and interact through{" "}
          <strong>comments</strong> and <strong>likes</strong>. Groups grow
          through <strong>invitations</strong> (links or tokens)—it is not a
          public feed or open social network. Features may change as we improve
          the product.
        </p>
        <p>
          The Service is provided by the Operator using third-party
          infrastructure (including Supabase for data and authentication, OAuth
          providers for sign-in, and Firebase for push delivery). Your use of
          those services is also subject to their respective terms and privacy
          notices.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">2. Eligibility</h2>
        <p>
          You must be able to form a binding contract in your jurisdiction and
          meet any minimum age required under the laws of the Republic of Korea
          (including rules for minors and parental consent where applicable). If
          you use the Service on behalf of an organization, you represent that
          you are authorized to bind that organization.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">3. Accounts</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            You must provide accurate information and keep your sign-in method
            secure. You are responsible for activity under your account.
          </li>
          <li>
            You may sign in using Apple, Google, or Kakao where enabled and must
            comply with those providers&apos; rules.
          </li>
          <li>
            You may <strong>leave a group</strong> or <strong>delete your
            account</strong> from within the app where available. Account
            deletion triggers our server-side process to remove or disassociate
            your data as configured; some residual data may remain briefly in
            backups or logs.
          </li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">4. User content</h2>
        <p className="mb-3">
          You retain rights to content you upload (such as photos and text). You
          grant the Operator a worldwide, non-exclusive license to host, store,
          reproduce, display, and distribute that content solely to operate,
          secure, and improve the Service—including showing it to other members
          of the same groups and processing it for notifications you opt into.
        </p>
        <p>
          You represent that you have the rights to share your content and that
          it does not infringe third-party rights or violate law. You understand
          that other members in your groups can see posts and profile elements
          shown by the app within those groups.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">5. Acceptable use</h2>
        <p className="mb-2">You agree not to:</p>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            Harass, threaten, defame, or harm other users, or post unlawful,
            hateful, sexually exploitative, or violent content.
          </li>
          <li>
            Misuse invitations, impersonate others, or misrepresent your
            identity or affiliation.
          </li>
          <li>
            Upload malware, probe or bypass security, scrape or bulk-collect
            data, or interfere with the Service or other users&apos; enjoyment.
          </li>
          <li>
            Use the Service for unsolicited marketing, spam, or illegal
            gambling or other unlawful commercial activity.
          </li>
        </ul>
        <p className="mt-3">
          We may suspend or terminate access, remove content, or take other
          reasonable action for violations or risk to the Service or users,
          subject to applicable law.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          6. Notifications and device permissions
        </h2>
        <p>
          Push and local notifications (for example, reminders or alerts about
          group activity) depend on your device settings and in-app preferences.
          Photo access is requested when you choose images to post. You can
          change permissions in your device settings; some features may be
          unavailable if you decline.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          7. Service changes and availability
        </h2>
        <p>
          We may modify, suspend, or discontinue features or the Service (in
          whole or in part) with reasonable notice where practicable. We do not
          guarantee uninterrupted or error-free operation.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          8. Disclaimers and limitation of liability
        </h2>
        <p className="mb-3">
          THE SERVICE IS PROVIDED &quot;AS IS&quot; AND &quot;AS AVAILABLE&quot;
          WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, TO THE
          FULLEST EXTENT PERMITTED BY THE LAWS OF THE REPUBLIC OF KOREA,
          INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
          NON-INFRINGEMENT.
        </p>
        <p className="mb-3">
          TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW IN THE REPUBLIC OF
          KOREA (INCLUDING THE ACT ON THE REGULATION OF TERMS AND CONDITIONS AND
          CONSUMER PROTECTION RULES THAT MAY NOT BE WAIVED), THE OPERATOR AND
          ITS AFFILIATES SHALL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL,
          CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR LOSS OF PROFITS, DATA, OR
          GOODWILL, ARISING FROM YOUR USE OF THE SERVICE. WHERE LIABILITY CANNOT
          BE EXCLUDED, THE OPERATOR&apos;S TOTAL AGGREGATE LIABILITY FOR ANY
          CLAIM RELATING TO THE SERVICE SHALL NOT EXCEED THE GREATER OF (A) THE
          AMOUNTS YOU PAID THE OPERATOR FOR THE SERVICE IN THE TWELVE (12) MONTHS
          BEFORE THE CLAIM, OR (B) KRW 100,000, EXCEPT FOR LIABILITY ARISING
          FROM THE OPERATOR&apos;S WILLFUL MISCONDUCT OR GROSS NEGLIGENCE OR
          OTHER CASES WHERE LIMITATION IS NOT PERMITTED BY MANDATORY LAW.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">9. Indemnity</h2>
        <p>
          To the extent permitted by the laws of the Republic of Korea, you
          will defend and indemnify the Operator and its affiliates against
          third-party claims arising from your content, your use of the Service,
          or your violation of these Terms.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">10. Changes to the Terms</h2>
        <p>
          We may modify these Terms. We will post the updated Terms at{" "}
          <a
            href="https://bemyday.app/terms"
            className="text-gray-700 underline hover:text-gray-900"
          >
            bemyday.app/terms
          </a>{" "}
          and update the &quot;Last updated&quot; date. Where required by law,
          we will notify you by reasonable means (for example, in-app notice).
          Continued use after the effective date may constitute acceptance where
          permitted by law; if you do not agree, you must stop using the Service
          and may delete your account.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          11. Governing law and jurisdiction
        </h2>
        <p>
          These Terms are governed by the laws of the <strong>Republic of
          Korea</strong>, without regard to conflict-of-law principles that
          would require application of another jurisdiction&apos;s laws. Any
          dispute arising out of or relating to these Terms or the Service shall
          be subject to the exclusive jurisdiction of the courts of the
          Republic of Korea as determined under applicable procedural law, except
          where mandatory consumer protection rules require otherwise.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">12. Contact</h2>
        <p className="mb-2">Questions about these Terms:</p>
        <ul className="list-none space-y-1 pl-0">
          <li>
            <strong>Operator:</strong> Tapas Maker
          </li>
          <li>
            <strong>Contact person:</strong> Junwoo Lee
          </li>
          <li>
            <strong>Email:</strong>{" "}
            <a
              href="mailto:tapas.maker@gmail.com"
              className="text-gray-700 underline hover:text-gray-900"
            >
              tapas.maker@gmail.com
            </a>
          </li>
          <li>
            <strong>Website:</strong>{" "}
            <a
              href="https://bemyday.app"
              className="text-gray-700 underline hover:text-gray-900"
            >
              https://bemyday.app
            </a>
          </li>
        </ul>
      </section>

      <Link to="/" className="text-gray-500 hover:text-gray-700">
        ← Back to home
      </Link>
    </main>
  );
}
