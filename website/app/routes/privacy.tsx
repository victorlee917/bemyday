import type { MetaFunction } from "@remix-run/node";
import { Link } from "@remix-run/react";

export const meta: MetaFunction = () => [
  { title: "Privacy Policy - Be My Day" },
  {
    name: "description",
    content:
      "Be My Day privacy policy. Operator: Tapas Maker. https://bemyday.app",
  },
];

export default function Privacy() {
  return (
    <main className="max-w-[720px] mx-auto p-8 leading-relaxed">
      <h1 className="text-2xl font-bold mb-4">Privacy Policy</h1>
      <p className="text-gray-500 mb-8">
        Last updated: March 24, 2026. Be My Day (the &quot;Service&quot;) is
        operated by <strong>Tapas Maker</strong>. Official website:{" "}
        <a
          href="https://bemyday.app"
          className="text-gray-700 underline hover:text-gray-900"
        >
          bemyday.app
        </a>
        . This policy explains what information we collect and how we use it when
        you use our mobile application and related services.
      </p>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">1. Data controller</h2>
        <p>
          The controller responsible for personal information under this policy
          is <strong>Tapas Maker</strong>, which operates the Service. The
          Service is provided through the Be My Day mobile app and information
          made available at{" "}
          <a
            href="https://bemyday.app"
            className="text-gray-700 underline hover:text-gray-900"
          >
            https://bemyday.app
          </a>
          . We use Supabase (hosted database, authentication, file storage, and
          real-time features) as our primary backend infrastructure.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          2. Information we collect
        </h2>
        <p className="mb-3">
          We collect information you provide directly, information generated
          when you use the Service, and limited technical data from your device
          as described below.
        </p>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            <strong>Account and authentication.</strong> When you sign in with
            Apple, Google, or Kakao, we receive identifiers and session data
            processed by Supabase Auth (for example, user ID, email when
            provided by the provider, and sign-in provider type). Apple sign-in
            may share name fields on first sign-in only, as allowed by Apple.
          </li>
          <li>
            <strong>Profile.</strong> Nickname, optional profile photo (stored
            in our avatars storage), email when linked to your account,
            timezone for week boundaries and scheduling, sign-in provider label,
            notification preferences (such as whether you want reminders or
            alerts for new posts, comments, or likes), and account timestamps.
          </li>
          <li>
            <strong>Social and group features.</strong> Group memberships,
            group names, weekday assignment, streaks and related metadata,
            invitations (including invite tokens and optional metadata used for
            sharing links), posts (photos stored in our posts storage, captions,
            week index), likes on posts and comments, and comments on posts.
          </li>
          <li>
            <strong>Push notifications.</strong> If you grant permission, we
            register a device token (Firebase Cloud Messaging) with your account
            and store the token and platform (e.g. iOS or Android) so we can
            send push notifications. Local notifications may also be scheduled
            on your device (for example, daily reminders) using your device
            timezone where applicable.
          </li>
          <li>
            <strong>Device permissions.</strong> The app may request access to
            your photo library when you choose photos to post, and notification
            permission for alerts. We do not read your entire photo library
            beyond what you select, except as needed by the operating system to
            show the picker.
          </li>
          <li>
            <strong>Real-time and logs.</strong> We use WebSocket subscriptions
            to keep the app in sync. Our providers may generate server and
            security logs (for example access logs, error logs) in line with
            their standard practices.
          </li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          3. How we use information
        </h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>To create and maintain your account and profile.</li>
          <li>
            To provide core features: weekday-based groups with friends, photo
            posts, comments, likes, invitations, streaks, and related in-app
            activity.
          </li>
          <li>
            To send push or local notifications according to your settings and
            device permissions.
          </li>
          <li>To secure the Service, prevent abuse, and troubleshoot issues.</li>
          <li>To comply with legal obligations when required.</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          4. Legal bases (where applicable)
        </h2>
        <p>
          Depending on your region, we rely on performance of a contract,
          legitimate interests (such as security and product improvement), and
          consent where required (for example, notifications or optional
          processing). For users in the Republic of Korea, we process personal
          information in accordance with the Personal Information Protection Act
          and other applicable laws.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          5. Sharing and processors
        </h2>
        <p className="mb-3">
          We do not sell your personal information. We share data with service
          providers who help us run the Service, including:
        </p>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            <strong>Supabase</strong> for authentication, database, storage,
            edge functions, and real-time delivery.
          </li>
          <li>
            <strong>Google Firebase (Cloud Messaging)</strong> for delivering
            push notifications to your device.
          </li>
          <li>
            <strong>Sign-in providers</strong> (Apple, Google, Kakao) for
            authentication according to their terms and privacy policies.
          </li>
        </ul>
        <p className="mt-3">
          These providers may process data in countries where they operate. We
          use contractual and technical safeguards appropriate to the nature of
          the data.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">6. Retention</h2>
        <p>
          We keep information for as long as your account is active and as
          needed to provide the Service. If you delete your account, we run an
          automated deletion flow that removes or anonymizes your data in line
          with our backend configuration (including profile-related data,
          tokens, and stored content tied to your account). Some information may
          persist for a short period in backups or logs before rotation.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">7. Security</h2>
        <p>
          We use industry-standard measures such as encrypted transport (HTTPS),
          access controls including row-level security on the database, and
          limited access to production systems. No method of transmission or
          storage is completely secure.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">8. Your choices</h2>
        <ul className="list-disc pl-6 space-y-2">
          <li>
            You can update profile and notification-related settings in the app
            where available.
          </li>
          <li>
            You can revoke notification or photo permissions in your device
            settings; some features may not work without them.
          </li>
          <li>
            You can request account deletion from within the app, subject to
            completion of our deletion process.
          </li>
          <li>
            Users in the Republic of Korea may have rights under the Personal
            Information Protection Act (including access, correction, deletion,
            and suspension of processing in certain cases). Contact us at the
            email below to exercise those rights.
          </li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">
          9. Children&apos;s privacy
        </h2>
        <p>
          The Service is not directed at children under 14 years of age without
          parental consent where required under the Republic of Korea law. If
          you believe we have collected such information, please contact us so we
          can delete it.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">10. Changes</h2>
        <p>
          We may update this policy from time to time. We will post the updated
          version on{" "}
          <a
            href="https://bemyday.app/privacy"
            className="text-gray-700 underline hover:text-gray-900"
          >
            bemyday.app/privacy
          </a>{" "}
          and, where appropriate, notify you through the app or other reasonable
          means.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold mb-2">11. Contact</h2>
        <p className="mb-2">
          For questions about this Privacy Policy or our data practices:
        </p>
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
