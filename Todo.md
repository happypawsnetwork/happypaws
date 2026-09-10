# Administrator stories

## administrator-07: Reputation and dispute handling
- **Current status**: Partial
- **Existing files**: `apps/web/app/(admin)/admin/(dashboard)/users/[id]/page.tsx`, `apps/web/actions/users.ts`
- **Backend requirements**: Needs a `POST /api/admin/users/{id}/reputation` endpoint and an `AdjustUserReputation` CQRS command to handle adjustments safely.
- **Client requirements**: The web frontend UI and server actions exist and need to connect to the new endpoint.
- **Step-by-step implementation tasks**:
  1. Create the `AdjustUserReputation` CQRS command.
  2. Map the POST endpoint in `AdminUserEndpoints`.
  3. Inject `ReputationService` to adjust points.
  4. Connect the Next.js server action to the new API endpoint.
- **Verification criteria**: Test that an administrator can manually deduct or add points and ensure trust badges update correctly.

# Adopter stories

## adopter-02: Role assignment
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/public_profile_screen.dart`, `apps/mobile/lib/verification_role_selection_screen.dart`, `apps/api/Endpoints/ProfileEndpoints.cs`
- **Backend requirements**: The `PUT /api/profile/roles/visibility` endpoint exists and functions.
- **Client requirements**: The UI needs functional callbacks and state management for users to toggle and apply for new roles.
- **Step-by-step implementation tasks**:
  1. Add working callbacks in `verification_role_selection_screen.dart`.
  2. Bind the screen to a dedicated controller for role updates.
  3. Ensure loading and error states are handled gracefully during API submission.
- **Verification criteria**: Test the role selection submission and ensure the dashboard updates upon success.

## adopter-03: Login and authentication
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/login_screen.dart`, `apps/mobile/lib/login_controller.dart`, `apps/api/Endpoints/AuthEndpoints.cs`
- **Backend requirements**: The backend endpoints exist and function.
- **Client requirements**: The web application lacks a public-facing login screen and role-based routing for non-admin users.
- **Step-by-step implementation tasks**:
  1. Create a public login page at `apps/web/app/(public)/login/page.tsx`.
  2. Implement a server action for the login endpoint.
  3. Set up session cookies for non-admin users.
  4. Create dashboard shells for non-admin roles to prevent missing page errors after login.
- **Verification criteria**: A user logs in via the web application and is securely routed to their dashboard without gaining admin privileges.

## adopter-04: Identity verification (KYC)
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/verification_screen.dart`, `apps/mobile/lib/verification_upload_screen.dart`, `apps/mobile/lib/verification_success_screen.dart`, `apps/mobile/lib/verification_controller.dart`, `apps/api/Endpoints/VerificationEndpoints.cs`
- **Backend requirements**: Endpoints exist and function.
- **Client requirements**: The mobile application needs to handle edge cases for ID upload failures and unhandled lifecycle transitions.
- **Step-by-step implementation tasks**:
  1. Handle edge cases for upload failures by adding error states in the controller.
  2. Map unhandled lifecycle transitions when returning from the camera.
- **Verification criteria**: Upload a mock ID on a mobile device and verify the UI reflects a pending approval status.

## adopter-05: Lifestyle profile and matching
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/lifestyle_profile_screen.dart`, `apps/mobile/lib/lifestyle_profile_controller.dart`, `apps/api/Endpoints/ProfileEndpoints.cs`
- **Backend requirements**: Endpoints exist and function.
- **Client requirements**: Refine the questionnaire form validation and ensure matched results correctly display loading indicators on mobile.
- **Step-by-step implementation tasks**:
  1. Improve the questionnaire form validation rules.
  2. Add loading indicators while fetching matched results.
- **Verification criteria**: Complete a profile and verify the recommended pets list updates correctly.

## adopter-06: Browse and search adoption listings
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/community_screen.dart`, `apps/mobile/lib/search_feed_controller.dart`, `apps/api/Endpoints/PostEndpoints.cs`
- **Backend requirements**: Search and nearby endpoints exist.
- **Client requirements**: Connect the UI filters to the state controller and remove hardcoded mock data.
- **Step-by-step implementation tasks**:
  1. Connect UI filters to `search_feed_controller.dart`.
  2. Remove all hardcoded mock data in the feed UI and bind it to the API response.
- **Verification criteria**: Search by keyword and verify debounced results load properly from the API.

## adopter-07 and adopter-09: Adoption listing and Rescue reporting
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/create_post_screen.dart`, `apps/mobile/lib/create_post_controller.dart`, `apps/api/Endpoints/PostEndpoints.cs`, `apps/api/Endpoints/RescueTriageEndpoints.cs`
- **Backend requirements**: Endpoints exist and function.
- **Client requirements**: Fix empty button callbacks and implement state management for location fetching.
- **Step-by-step implementation tasks**:
  1. Fix the empty button callbacks in the create post screen.
  2. Implement proper state management and loading indicators for GPS location fetching.
- **Verification criteria**: Create a post with photos and verify the exact API payload is sent.

## adopter-08 and adopter-14: Track adoption apps and My rescues
- **Current status**: Missing
- **Existing files**: `apps/mobile/lib/adoption_applications_screen.dart`, `apps/mobile/lib/my_rescues_screen.dart`, `apps/api/Endpoints/RescueApplicationEndpoints.cs`
- **Backend requirements**: Endpoints exist and function.
- **Client requirements**: Convert stateless stub screens to stateful widgets and fetch data.
- **Step-by-step implementation tasks**:
  1. Convert the screens to stateful or consumer widgets.
  2. Create `AdoptionAppController` and `MyRescuesController`.
  3. Fetch and display list data with proper error and loading states.
- **Verification criteria**: Navigate to these screens and ensure data loads correctly from the API.

## adopter-10: Private in-app messaging
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/chat_list_screen.dart`, `apps/mobile/lib/chat_thread_screen.dart`, `apps/mobile/lib/chat_controller.dart`, `apps/api/Endpoints/MessagingEndpoints.cs`
- **Backend requirements**: Endpoints and SignalR hub exist.
- **Client requirements**: Handle socket disconnection states and add error overlays on mobile.
- **Step-by-step implementation tasks**:
  1. Add error overlays and reconnect logic for socket disconnection states.
- **Verification criteria**: Disconnect the network, verify the error overlay appears, reconnect, and verify messages send successfully.

## adopter-12: Notifications
- **Current status**: Missing
- **Existing files**: `apps/mobile/lib/notifications_screen.dart`
- **Backend requirements**: Needs a `POST /api/notifications/device-tokens` endpoint, Firebase Admin SDK integration, a `DeviceTokens` database table, and a push notification dispatcher.
- **Client requirements**: Implement FCM token registration and build a list UI with read and unread visual states.
- **Step-by-step implementation tasks**:
  1. Add the Firebase Admin SDK to the backend project.
  2. Create a `DeviceTokens` database table and migration.
  3. Add a push notification dispatcher for messages and application updates.
  4. Implement FCM token registration in the mobile application.
  5. Build the list UI with read and unread visual states.
- **Verification criteria**: Trigger a notification on the backend and verify its arrival in the mobile application.

# Foster stories

## foster-01: Login and authentication
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/login_screen.dart`, `apps/api/Endpoints/AuthEndpoints.cs`
- **Backend requirements**: The backend endpoints exist and function.
- **Client requirements**: The web application lacks a public-facing login screen for fosters.
- **Step-by-step implementation tasks**:
  1. Create a public login page at `apps/web/app/(public)/login/page.tsx`.
  2. Implement a server action for the login endpoint.
  3. Set up session cookies for non-admin users.
  4. Create dashboard shells for non-admin roles.
- **Verification criteria**: A foster logs in via the web application and is securely routed to their dashboard.

## foster-03: Geo-targeted alerts
- **Current status**: Disconnected
- **Existing files**: `apps/api/Endpoints/PostEndpoints.cs`
- **Backend requirements**: Needs a background worker and PostGIS spatial radius queries to trigger alerts.
- **Client requirements**: Handled by the FCM registration task.
- **Step-by-step implementation tasks**:
  1. Create a background job that listens for new critical rescues.
  2. Query users within a specific radius who hold the Foster role.
  3. Fire FCM push notifications to those users.
- **Verification criteria**: Create a critical case and ensure nearby fosters receive push alerts.

## foster-05: Foster placement acceptance
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/foster_care_screen.dart`, `apps/api/Endpoints/RescueApplicationEndpoints.cs`
- **Backend requirements**: Needs explicit handover complete logic beyond transports.
- **Client requirements**: Needs a dedicated dashboard, case management UI, and medical update forms.
- **Step-by-step implementation tasks**:
  1. Create a `FosterController` on mobile.
  2. Build out the case management UI and medical update forms.
  3. Add backend logic to mark a foster handover as complete.
- **Verification criteria**: Accept a foster placement and complete the handover flow successfully.

## foster-06: Transition to adoption
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs a `POST /api/v1/community/rescues/{postId}/transition-to-adoption` endpoint and a CQRS command that clones the rescue post into an adoption post.
- **Client requirements**: Needs a UI button and confirmation flow in the foster dashboard.
- **Step-by-step implementation tasks**:
  1. Implement a CQRS command that clones the rescue post and marks the original as resolved.
  2. Map the new endpoint to trigger the transition.
  3. Add a UI button and confirmation dialog on mobile.
- **Verification criteria**: Transition a rescue case to adoption and verify the new post is created correctly.

## foster-09: Notifications
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs notification endpoints and dispatcher logic.
- **Client requirements**: Needs push token registration and UI on mobile.
- **Step-by-step implementation tasks**:
  1. Implement the tasks outlined in the adopter notifications story.
- **Verification criteria**: Verify foster-specific notifications arrive in the mobile application.

## foster-15: Case resolution
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs a manual case close endpoint.
- **Client requirements**: Needs a UI button in the foster dashboard to close a case.
- **Step-by-step implementation tasks**:
  1. Add a case close endpoint on the backend.
  2. Add a UI button and confirmation dialog on mobile.
- **Verification criteria**: Close a case and verify the status is updated to resolved.

# Transporter stories

## transporter-01: Login and authentication
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/login_screen.dart`, `apps/api/Endpoints/AuthEndpoints.cs`
- **Backend requirements**: Endpoints exist.
- **Client requirements**: The web application lacks a public-facing login screen for transporters.
- **Step-by-step implementation tasks**:
  1. Follow the web login creation tasks outlined previously.
- **Verification criteria**: A transporter logs in via the web application and is securely routed to their dashboard.

## transporter-03: Geo-targeted alerts
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs a background worker and radius queries.
- **Client requirements**: Handled by FCM registration.
- **Step-by-step implementation tasks**:
  1. Implement the background worker and query logic from the foster alerts task.
- **Verification criteria**: Verify nearby transporters receive push alerts for new transport tasks.

## transporter-04, 05, 08, 09, 10, 12: Dashboard and workflow
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/animal_transports_screen.dart`, `apps/mobile/lib/transport_controller.dart`, `apps/api/Endpoints/TransportEndpoints.cs`
- **Backend requirements**: Needs a mark pickup endpoint in `TransportEndpoints.cs`.
- **Client requirements**: Bind the controller, add active transit tracking maps, and handover confirmation buttons.
- **Step-by-step implementation tasks**:
  1. Bind `transport_controller` to the `animal_transports_screen`.
  2. Add active transit tracking maps and handover confirmation buttons.
  3. Implement the mark pickup endpoint on the backend.
- **Verification criteria**: Accept a transport task and complete the full delivery workflow.

## transporter-06: Route optimization
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs Google Maps Routing API integration for optimized waypoint navigation.
- **Client requirements**: Display the optimized route on mobile.
- **Step-by-step implementation tasks**:
  1. Integrate the Google Maps Routing API on the backend.
  2. Provide an endpoint to fetch the optimized route.
  3. Fetch and display the route on the mobile transit tracking map.
- **Verification criteria**: Verify that navigating multiple waypoints returns an optimized route.

## transporter-11: Notifications
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs notification endpoints and dispatcher logic.
- **Client requirements**: Needs push token registration and UI on mobile.
- **Step-by-step implementation tasks**:
  1. Implement the tasks outlined in the adopter notifications story.
- **Verification criteria**: Verify transporter-specific notifications arrive in the mobile application.

# Sponsor stories

## sponsor-01: Login and authentication
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/login_screen.dart`, `apps/api/Endpoints/AuthEndpoints.cs`
- **Backend requirements**: Endpoints exist.
- **Client requirements**: The web application lacks a public-facing login screen for sponsors.
- **Step-by-step implementation tasks**:
  1. Follow the web login creation tasks outlined previously.
- **Verification criteria**: A sponsor logs in via the web application and is securely routed to their dashboard.

## sponsor-04: Pledge support
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/sponsorships_screen.dart`, `apps/mobile/lib/sponsorship_controller.dart`, `apps/api/Endpoints/SponsorshipEndpoints.cs`
- **Backend requirements**: Needs a Stripe Checkout endpoint and Stripe Webhooks integration to flip the status to funded.
- **Client requirements**: Build the UI for viewing sponsorship campaigns and submitting pledges.
- **Step-by-step implementation tasks**:
  1. Build the UI for viewing sponsorship campaigns and submitting pledges on mobile.
  2. Add a Stripe Checkout endpoint.
  3. Handle Stripe Webhooks to update the funded status.
- **Verification criteria**: Complete a pledge and verify the webhook updates the backend status correctly.

## sponsor-06: Direct item donation
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs an inventory and item pledge entity in the database, and endpoints to track shipped items.
- **Client requirements**: Needs a UI on mobile to pledge items.
- **Step-by-step implementation tasks**:
  1. Create an inventory and item pledge entity in the database.
  2. Create endpoints to track shipped items.
  3. Add a UI on mobile for users to pledge items.
- **Verification criteria**: Pledge an item and verify it appears in the backend tracking system.

## sponsor-08: Notifications
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs notification endpoints and dispatcher logic.
- **Client requirements**: Needs push token registration and UI on mobile.
- **Step-by-step implementation tasks**:
  1. Implement the tasks outlined in the adopter notifications story.
- **Verification criteria**: Verify sponsor-specific notifications arrive in the mobile application.

# Veterinarian stories

## veterinarian-01: Login and authentication
- **Current status**: Partial
- **Existing files**: `apps/mobile/lib/login_screen.dart`, `apps/api/Endpoints/AuthEndpoints.cs`
- **Backend requirements**: Endpoints exist.
- **Client requirements**: The web application lacks a public-facing login screen for veterinarians.
- **Step-by-step implementation tasks**:
  1. Follow the web login creation tasks outlined previously.
- **Verification criteria**: A veterinarian logs in via the web application and is securely routed to their dashboard.

## veterinarian-03: Alerts
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs a background worker and radius queries.
- **Client requirements**: Handled by FCM registration.
- **Step-by-step implementation tasks**:
  1. Implement the background worker and query logic from the foster alerts task.
- **Verification criteria**: Verify nearby veterinarians receive push alerts for new critical cases.

## veterinarian-All: Dashboard and review queues
- **Current status**: Missing
- **Existing files**: `apps/mobile/lib/case_reviews_screen.dart`
- **Backend requirements**: Endpoints exist or are covered in other stories.
- **Client requirements**: Needs triage queues and interactive lists.
- **Step-by-step implementation tasks**:
  1. Create a `VeterinarianController`.
  2. Build interactive lists for case reviews on mobile.
- **Verification criteria**: Open the dashboard and verify triage queues load correctly.

## veterinarian-04: Review AI triage and confirm urgency
- **Current status**: Missing
- **Existing files**: `apps/api/Endpoints/AdminRescueEndpoints.cs`
- **Backend requirements**: Needs a `PATCH /api/v1/community/rescues/{postId}/vet-urgency` endpoint, a vet-scoped urgency override command, and logic to assign trust badge points.
- **Client requirements**: Needs a UI to override urgency.
- **Step-by-step implementation tasks**:
  1. Create a vet-scoped urgency override command.
  2. Assign trust badge points to the veterinarian upon override.
  3. Add a UI on mobile to submit the urgency override.
- **Verification criteria**: Log in as a veterinarian and override a medium urgency to critical.

## veterinarian-05: Provide medical guidance
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs a `POST /api/v1/community/rescues/{postId}/medical-advice` endpoint and a Medical Advice entity.
- **Client requirements**: Needs a UI to submit medical guidance.
- **Step-by-step implementation tasks**:
  1. Add a Medical Advice entity to log professional treatment directives.
  2. Create an endpoint to submit medical advice.
  3. Add a UI on mobile to submit the advice.
- **Verification criteria**: Submit medical advice and verify it is visible on the case.

## veterinarian-08: Notifications
- **Current status**: Missing
- **Existing files**: None
- **Backend requirements**: Needs notification endpoints and dispatcher logic.
- **Client requirements**: Needs push token registration and UI on mobile.
- **Step-by-step implementation tasks**:
  1. Implement the tasks outlined in the adopter notifications story.
- **Verification criteria**: Verify veterinarian-specific notifications arrive in the mobile application.
