# Community hub

## Overview

The community hub is the social layer of Happy Paws. It sits on top of the rescue, adoption, transport, and vet coordination features. It ties them together through a public feed of typed posts. Every major operational event produces one or more community posts. These posts keep the broader user community informed and engaged.

## Seven post types

The feed supports seven distinct post types.

- **🚨 Rescue**: The entry point for a new animal in distress. Any authenticated user can post. This triggers AI triage and geo-targeted alerts to nearby volunteers. It accepts rescue applications from fosters and adopters. It disappears from the feed once the case is resolved.
- **🐾 Update**: Progress reports on an active rescue case. Only the assigned rescuer (the approved applicant) can post these. Each update links back to its parent rescue post.
- **🏠 Find Home**: An adoption listing for a pet needing a new home. Any KYC verified user can post this for their own animal. It links into the existing adoption application system.
- **✨ Highlight**: A free-form community post. Anyone can post photos of their pet, happy moments, or stories. It requires at least one photo. There is no parent link or attached workflow.
- **🚐 Transport**: A request for a transporter to move an animal. The assigned rescuer or adopter on the linked parent rescue or vet request posts this. Transporters submit offers with pickup windows. The requester picks one offer. The transporter delivers the animal. The requester confirms delivery to complete the task.
- **💊 Treatment**: A request for a vet visit. Fosters or adopters post these. It has an optional link to a parent rescue. It can spawn a transport request for the vet run. It carries a reason for the visit, an optional clinic name, and an optional appointment date.
- **💛 Sponsor**: A funding request for an animal's care costs. Only KYC verified users can post. It requires private proof documents. An admin must approve it before it appears in the feed. Sponsors contact the poster via private chat. There are no direct payments. The poster marks it as funded when support is received.

## The feed

The mobile app community section has four tabs.

- **Community**: A global feed of all post types. It excludes completed rescues and unapproved sponsorships.
- **Nearby**: The same feed filtered to posts with a location point within the user's chosen radius. This uses radius filtering.
- **Chats**: Private messaging between any two users. Case-sensitive animal information is shared here.
- **Profile**: The user's own posts, their rescue list, and their transport list.

## Photo rules

All post types except highlights allow up to four photos. The minimum is zero. Highlights require at least one photo and allow up to eight. Each photo has a maximum size of 5 MB. Allowed formats are JPEG, PNG, WebP, and HEIC.

## Location and geo data

Rescue, find home, and transport posts carry a GPS location point and a human-readable location label. The nearby tab uses radius filtering on this point.

## Rescue lifecycle

Any user posts a rescue alert. Fosters and adopters submit applications. The original poster reviews applications and approves one. The post status changes to fostered. All other applications are rejected automatically. The assigned rescuer can now post updates linked to the rescue. When the animal is ready to move, the rescuer requests a transport or collects the animal themselves. The requester confirms delivery when the animal arrives. The rescuer marks the rescue case as completed. The post is hidden from the community feed.

## Admin override

An admin can revert a fostered rescue back to active. This allows the original poster to select a different applicant if needed. Both the original poster and the previously approved applicant receive notifications.

## Transport lifecycle

A requester posts a transport request. A transport task is created at the same time. Nearby transporters submit offers with proposed pickup windows. The requester reviews the offers and accepts one. All other offers are rejected. The transporter picks up the animal and updates the status to in transit. The transporter marks the animal as delivered at the destination. The requester confirms the delivery. The task is completed.

## Self-collection

If a requester has their own vehicle, they can self-collect the animal. An internal transport task is created for tracking. No public transport post is created. The requester marks the animal as collected. The task jumps directly to completed.

## Vet visit lifecycle

A foster or adopter posts a treatment request. They provide a reason, an optional clinic, and an optional date. They also specify if transport is needed. If transport is needed, a linked transport request and task are created. The transport follows the standard transport lifecycle.

## Sponsorship lifecycle

A KYC verified user creates a sponsor request. They provide a goal description and upload proof documents. The post remains hidden until an admin reviews it. If approved, the post appears in the feed. Sponsors contact the poster via private chat to arrange funds. The poster marks the request as funded once they receive the support.

## Sponsorship proof document access

Proof documents are stored privately. Admins can always access them. KYC verified users can access them only when the post status is active. Access is granted via a presigned URL that expires in 10 minutes.

## Post interactions

Users can like posts. A like increments a counter on the post. Users can also comment on posts.

## Role-based posting rules

| Post type | Who can post |
| --- | --- |
| Rescue | Any authenticated user |
| Update | Only the approved applicant for the linked rescue |
| Find Home | KYC verified users only |
| Highlight | Any authenticated user |
| Transport | The assigned rescuer or adopter on the linked parent post |
| Treatment | Fosters and adopters |
| Sponsor | KYC verified users only |

## Post status lifecycle

| Status | Used by | Trigger |
| --- | --- | --- |
| Active | All types | Post is created or approved |
| Fostered | Rescue | Original poster approves an applicant |
| Assigned | Transport | Requester accepts a transport offer |
| Completed | Rescue, Find Home, Transport, Treatment | Task is fully resolved |
| PendingApproval | Sponsor | Post is created and awaiting admin review |
| Funded | Sponsor | Poster marks the request as funded |
| Rejected | Sponsor | Admin rejects the request |
| Cancelled | Any | Poster or admin cancels the post |

## Admin dashboard tabs

Admins manage the community from a web dashboard.

- **Community**: All posts across all types. Admins can soft-delete any post for moderation.
- **Rescues**: All rescue cases with an approved applicant. Admins can override any case back to active.
- **Transports**: All transport tasks and their current statuses. This is a read-only monitoring view.
- **Sponsorships**: All sponsorship requests. Admins approve or reject them with optional notes. Admins can download proof documents to verify legitimacy.

## My Rescues

The user profile includes a rescues tab. This shows all approved rescue cases for the user.

## My Transports

The user profile includes a transports tab. This shows all active and completed transport tasks for a transporter.