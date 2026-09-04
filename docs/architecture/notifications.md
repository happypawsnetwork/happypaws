# Notifications architecture

This document defines the full notifications strategy for Happy Paws. It covers delivery channels, notification types, which triggers apply per user role, in-app settings structure, and backend dispatch rules.

---

## 1. Channels

Happy Paws uses two delivery channels.

| Channel | Technology | When it fires |
|---|---|---|
| **Push notification** | Firebase Cloud Messaging (FCM) | User is outside the app or the screen is backgrounded |
| **In-app notification** | SignalR real-time hub | User is active inside the app — delivered directly to the notification bell/screen without a device-level push |

Both channels share the same notification record in the database. The backend marks a notification as delivered via SignalR if the user has an active hub connection at dispatch time, and falls back to FCM otherwise. This prevents double-alerting.

---

## 2. Notification type catalog

Each notification has a `type` that drives deep-link routing on the client.

| Type key | Plain description | Deep-link target | Status |
|---|---|---|:---:|
| `new_message` | A new private chat message arrived | Messages thread | ✅ |
| `rescue_reported_nearby` | A new rescue case was posted within the user's alert radius | Rescue post | ❌ |
| `rescue_application_received` | Someone applied to take care of a rescue the user posted | Rescue post → applicants tab | ❌ |
| `rescue_application_approved` | The user's application to a rescue was approved | My Rescues | ❌ |
| `rescue_application_rejected` | The user's application to a rescue was rejected | Rescue post | ❌ |
| `rescue_case_reverted` | An admin reverted a fostered rescue back to active | Rescue post | ❌ |
| `rescue_case_completed` | A rescue case the user is involved in was closed | Rescue post | ❌ |
| `transport_requested_nearby` | A new transport request was posted within the user's alert radius | Transport post | ❌ |
| `transport_offer_received` | A transporter submitted an offer on the user's transport request | Transport post → offers tab | ❌ |
| `transport_offer_accepted` | The user's transport offer was accepted by the requester | My Transports | ❌ |
| `transport_offer_rejected` | The user's transport offer was rejected | Transport post | ❌ |
| `transport_status_updated` | A transport task the user is involved in changed status | My Transports | ❌ |
| `delivery_confirmed` | The recipient confirmed delivery of an animal the user transported or sent | My Transports | ❌ |
| `adoption_application_received` | Someone applied to adopt a listing the user posted | Find Home post → applicants tab | ❌ |
| `adoption_application_status_changed` | The status of the user's adoption application changed (accepted or declined) | Adoption Applications | ❌ |
| `sponsorship_request_approved` | An admin approved a sponsorship request the user posted | Sponsor post | ❌ |
| `sponsorship_request_rejected` | An admin rejected a sponsorship request the user posted | My Content | ❌ |
| `sponsorship_pledge_received` | A sponsor pledged support against the user's sponsorship request | Sponsor post | ❌ |
| `sponsorship_case_updated` | A case the user sponsors posted a progress update | Sponsor post | ❌ |
| `sponsorship_funded` | The poster of a sponsored case marked it as funded | Sponsor post | ❌ |
| `medical_alert_nearby` | A critical or moderate rescue case within the alert radius needs medical attention | Rescue post | ❌ |
| `triage_override` | A vet or admin overrode the AI urgency classification on a rescue the user reported | Rescue post | ❌ |
| `kyc_approved` | The user's KYC or professional document was approved by an admin | Profile → Get Verified | ❌ |
| `kyc_rejected` | The user's KYC or professional document was rejected by an admin | Profile → Get Verified | ❌ |
| `reputation_updated` | The user gained reputation points or a new trust badge | My Profile | ❌ |
| `post_moderated` | An admin soft-deleted one of the user's community posts | My Content | ❌ |

---

## 3. Notifications per role

### 3.1 All users (base role: adopter)

Every registered user receives these regardless of additional roles.

| Trigger | Type key | Channel |
|---|---|---|
| New private message in any thread | `new_message` | Push + in-app |
| Own KYC document approved | `kyc_approved` | Push + in-app |
| Own KYC document rejected | `kyc_rejected` | Push + in-app |
| Reputation points or badge awarded | `reputation_updated` | In-app |
| A community post they made was moderated | `post_moderated` | Push + in-app |
| Someone applied to adopt a Find Home listing they posted | `adoption_application_received` | Push + in-app |
| Someone applied to take over a rescue they reported | `rescue_application_received` | Push + in-app |
| AI urgency was overridden on a rescue they reported | `triage_override` | Push + in-app |

### 3.2 Adopter-specific

These apply when a user acts in the adopter capacity.

| Trigger | Type key | Channel |
|---|---|---|
| An adoption application they submitted changed status | `adoption_application_status_changed` | Push + in-app |
| Their rescue application was approved | `rescue_application_approved` | Push + in-app |
| Their rescue application was rejected | `rescue_application_rejected` | In-app |
| A transporter confirmed delivery of an animal to them | `delivery_confirmed` | Push + in-app |
| A transport task linked to their rescue confirmation changed status | `transport_status_updated` | In-app |
| A sponsorship request they posted was approved by an admin | `sponsorship_request_approved` | Push + in-app |
| A sponsorship request they posted was rejected by an admin | `sponsorship_request_rejected` | Push + in-app |
| A sponsor pledged support against their sponsorship request | `sponsorship_pledge_received` | Push + in-app |

### 3.3 Foster-specific

These fire for users who hold the Foster role, on top of the base alerts above.

| Trigger | Type key | Channel | Notes |
|---|---|---|---|
| New rescue case posted within their geo alert radius | `rescue_reported_nearby` | Push | Only fires if the user has completed KYC and enabled foster alerts |
| Their rescue application was approved | `rescue_application_approved` | Push + in-app | Same type key as adopter; the deep link goes to My Foster Cases |
| Their rescue application was rejected | `rescue_application_rejected` | In-app | |
| An admin reverted a fostered rescue they are assigned to back to active | `rescue_case_reverted` | Push + in-app | |
| A transport task linked to one of their active cases changed status | `transport_status_updated` | In-app | |
| A transporter confirmed delivery to them | `delivery_confirmed` | Push + in-app | |
| A sponsorship request they posted was approved | `sponsorship_request_approved` | Push + in-app | |
| A sponsorship request they posted was rejected | `sponsorship_request_rejected` | Push + in-app | |
| A sponsor pledged support against their sponsorship request | `sponsorship_pledge_received` | Push + in-app | |
| A transport offer was received on a transport request they posted | `transport_offer_received` | Push + in-app | |

### 3.4 Transporter-specific

These fire for users who hold the Transporter role.

| Trigger | Type key | Channel | Notes |
|---|---|---|---|
| New transport request posted within their geo alert radius | `transport_requested_nearby` | Push | Only fires if KYC is complete and transporter alerts are enabled |
| Their transport offer was accepted | `transport_offer_accepted` | Push + in-app | Time-sensitive — always push |
| Their transport offer was rejected | `transport_offer_rejected` | In-app | |
| A transport task they are assigned to changed status | `transport_status_updated` | In-app | Keeps their task view in sync |
| The recipient confirmed delivery on a task they completed | `delivery_confirmed` | In-app | Closes the task on their end |

### 3.5 Sponsor-specific

These fire for users who hold the Sponsor role.

| Trigger | Type key | Channel | Notes |
|---|---|---|---|
| A case or animal they pledged support to posted a progress update | `sponsorship_case_updated` | Push + in-app | |
| The poster of a case they sponsor marked it as funded | `sponsorship_funded` | Push + in-app | Final closure signal for the sponsor |

### 3.6 Veterinarian-specific

These fire for users who hold the Veterinarian role.

| Trigger | Type key | Channel | Notes |
|---|---|---|---|
| A critical or moderate rescue case was posted within their geo alert radius | `medical_alert_nearby` | Push | Only fires if professional license is approved and vet alerts are enabled |
| A rescue case they reviewed had its triage classification overridden by an admin | `triage_override` | In-app | Informational — no action required |

### 3.7 Administrator-specific

Administrators operate primarily from the web dashboard, not the mobile app. Their alerts are delivered through the web dashboard's notification panel and, where time-sensitive, via email (Resend). FCM push to mobile is not in scope for admin users.

| Trigger | Type key | Channel | Notes |
|---|---|---|---|
| A new KYC or professional license document is submitted for review | `kyc_pending_review` | Web dashboard + email | Batched — one digest per hour if multiple submissions arrive |
| A new sponsorship request is awaiting approval | `sponsorship_pending_review` | Web dashboard | Listed in the Sponsorships tab |
| A rescue case has been open and unassigned beyond a threshold (e.g., 2 hours) | `rescue_unassigned_alert` | Web dashboard + email | Threshold is configurable |
| A user account is reported by another user | `user_reported` | Web dashboard | |
| A community post is reported for moderation | `post_reported` | Web dashboard | |

---

## 4. Geo-targeted alert rules

Three notification types are geo-targeted: `rescue_reported_nearby`, `transport_requested_nearby`, and `medical_alert_nearby`. These all follow the same dispatch logic.

1. When the triggering post is saved, the API reads its GPS coordinates.
2. The API queries the `UserAlertSettings` table for all users who have the relevant role, have passed KYC, and have the relevant alert type enabled.
3. Each candidate user's stored `alert_radius_km` is compared against the Haversine distance between the post coordinates and the user's last known location.
4. FCM push notifications are dispatched only to users within radius.
5. The reporter of the rescue is never included in the geo-targeted dispatch for their own report.

### Alert radius defaults

| Role | Alert type | Default radius | Min | Max |
|---|---|---|---|---|
| Foster | `rescue_reported_nearby` | 10 km | 1 km | 50 km |
| Transporter | `transport_requested_nearby` | 15 km | 1 km | 100 km |
| Veterinarian | `medical_alert_nearby` | 10 km | 1 km | 50 km |

Users adjust their radius from the Notifications screen inside the app.

---

## 5. In-app notification settings

The Notifications screen is a single screen accessed from the profile tab. It surfaces general and role-specific sections based on the user's active roles.

```
General
  ├─ New messages                  (toggle, default: on)
  ├─ Application status changes    (toggle, default: on)
  ├─ Post moderation alerts        (toggle, default: on)
  └─ Reputation updates            (toggle, default: on)

Foster alerts                      ← visible only if user holds Foster role
  ├─ Nearby rescue alerts          (toggle, default: on)
  └─ Alert radius                  (slider: 1–50 km, default: 10 km)

Transporter alerts                 ← visible only if user holds Transporter role
  ├─ Nearby transport requests     (toggle, default: on)
  └─ Alert radius                  (slider: 1–100 km, default: 15 km)

Veterinarian alerts                ← visible only if user holds Veterinarian role
  ├─ Nearby medical cases          (toggle, default: on)
  └─ Alert radius                  (slider: 1–50 km, default: 10 km)
```

If a user holds both Foster and Veterinarian roles, both sections appear independently with their own radius sliders, because the two alert types can legitimately have different radii.

---

## 6. Backend dispatch architecture

```
Domain event raised
        │
        ▼
NotificationDispatchHandler (MediatR pipeline)
        │
        ├─ Resolve recipients from domain context
        │   (e.g., all verified fosters within radius, or a specific user)
        │
        ├─ Persist Notification record(s) to DB
        │   (id, recipient_user_id, type, payload JSON, is_read, created_at)
        │
        ├─ Attempt SignalR delivery to connected users
        │   └─ Mark notification.delivered_via = SignalR
        │
        └─ For each user NOT reached via SignalR:
            └─ Enqueue FCM push via INotificationService
                └─ Mark notification.delivered_via = FCM
```

The `INotificationService` abstraction lives in the Application layer. The FCM implementation lives in Infrastructure. This keeps the domain and application layers free of FCM SDK dependencies.

---

## 7. Data model

```sql
-- One record per recipient per event.
-- A single event (e.g., a rescue post) may produce many rows,
-- one per nearby foster.
CREATE TABLE notifications (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type              TEXT NOT NULL,           -- matches type key catalog above
    title             TEXT NOT NULL,           -- short display title
    body              TEXT NOT NULL,           -- full display body
    payload           JSONB,                   -- deep-link data (post_id, case_id, etc.)
    is_read           BOOLEAN NOT NULL DEFAULT FALSE,
    delivered_via     TEXT,                    -- 'SignalR' | 'FCM' | NULL (pending)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ix_notifications_recipient_unread
    ON notifications (recipient_user_id, is_read, created_at DESC);

-- Per-user alert preferences, including geo-radius settings.
CREATE TABLE user_alert_settings (
    user_id                      UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    messages_enabled             BOOLEAN NOT NULL DEFAULT TRUE,
    app_status_enabled           BOOLEAN NOT NULL DEFAULT TRUE,
    reputation_enabled           BOOLEAN NOT NULL DEFAULT TRUE,
    -- Foster
    foster_alerts_enabled        BOOLEAN NOT NULL DEFAULT TRUE,
    foster_alert_radius_km       SMALLINT NOT NULL DEFAULT 10,
    -- Transporter
    transport_alerts_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    transport_alert_radius_km    SMALLINT NOT NULL DEFAULT 15,
    -- Veterinarian
    vet_alerts_enabled           BOOLEAN NOT NULL DEFAULT TRUE,
    vet_alert_radius_km          SMALLINT NOT NULL DEFAULT 10,
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

---

## 8. FCM payload structure

All FCM messages follow a consistent payload shape so the Flutter client can route any incoming notification without special casing.

```json
{
  "notification": {
    "title": "New rescue nearby",
    "body": "A critical case was reported 3 km from you."
  },
  "data": {
    "notification_id": "uuid",
    "type": "rescue_reported_nearby",
    "post_id": "uuid",
    "urgency": "Critical"
  },
  "android": {
    "priority": "high"
  },
  "apns": {
    "headers": { "apns-priority": "10" }
  }
}
```

The `data` block always includes `notification_id` and `type`. The rest of the keys in `data` vary by type and match the `payload` column in the `notifications` table.

---

## 9. Open items (post-MVP)

| Item | Notes |
|---|---|
| Email fallback for offline users | Send a Resend email digest for unread push notifications older than 24 hours |
| Notification grouping | Group multiple `rescue_reported_nearby` alerts into a single push if several fire within a short window |
| Admin mobile push | Decide if administrators should receive time-critical push alerts on mobile for unassigned rescues |
| Quiet hours | Allow users to set a do-not-disturb window. Geo alerts are the only type that bypass it |
