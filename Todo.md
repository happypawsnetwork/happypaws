# Feature implementation checklist

This document outlines the missing and partially implemented features in the mobile and admin applications. Completing these items ensures full coverage of the project user stories.

## Mobile application

### Adopter features
- **Adoption applications**: Connect the static `AdoptionApplicationsScreen` to the backend API. Users must be able to submit applications and track their approval status.
- **Rescue tracking**: Add data fetching to the `MyRescuesScreen` so users can monitor the emergency cases they report.
- **Delivery confirmation**: Build the user interface and network logic for adopters to confirm they have received an animal. This closes the chain of custody.
- **Push notifications**: Integrate Firebase Cloud Messaging. Users rely on local and push notifications to receive critical platform alerts.

### Foster features
- **Case management**: Add state controllers to the `FosterCareScreen`. Fosters need to accept placements, update animal conditions, and transition animals to public adoption listings.
- **Case resolution**: Build functionality for fosters to log self-collection, confirm delivery, and resolve cases.
- **Geo-targeted alerts**: Add push notification handlers for nearby rescue alerts so fosters can respond to local emergencies rapidly.

### Sponsor features
- **Pledge tracking**: Update the static `SponsorshipsScreen` to process pledges and display case progress. Sponsors need visibility into how their funds help individual animals.

### Transporter features
- **Task management**: Connect the `AnimalTransportsScreen` to the API. Transporters must be able to claim requests, submit offers, and update transit statuses (picked up, in transit, and delivered).
- **Transport alerts**: Implement push notifications for geo-targeted transport requests and offer acceptances.

### Veterinarian features
- **Medical review**: Add logic to the `CaseReviewsScreen`. Veterinarians need to fetch cases, override AI urgency scores, and submit professional medical guidance.

### Cross-role features
- **Contextual messaging**: Add interface entry points to start chats directly from specific tasks. For example, a transporter needs a quick way to coordinate with a foster directly from a transport task screen.
- **Reputation badges**: Implement the logic to award trust badges for specialized role actions, such as verified transport runs or expert medical reviews.

## Admin application

### Content moderation
- **Global message moderation**: Build a global moderation view in the messages tab. Administrators need to review and remove user-to-user messages that violate platform rules or raise fraud concerns.

### Dashboard and reporting
- **Pending verifications widget**: Add a summary widget for pending identity verifications to the main dashboard. Administrators need to see verification backlogs at a glance without navigating to the specific tab.
- **Open cases widget**: Add a summary widget for active rescue cases to the main dashboard overview page to highlight immediate platform load.
