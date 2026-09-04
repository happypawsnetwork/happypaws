# Real-time messaging

The messaging system uses SignalR to provide secure, real-time coordination between adopters, fosters, transporters, sponsors, and veterinarians. This allows coordination without requiring the exchange of personal phone numbers.

## Core features
- ✅ **Delivery status**: Messages track and display Delivered and Seen statuses.
- ✅ **Timestamps**: Accurate timestamps show for all sent and received messages.
- ✅ **Sorting**: Chat lists strictly sort by the latest message received.
- ✅ **Message management**: Users can delete or clear conversations.
- ✅ **Saved messages**: Users can message themselves to save notes, links, and reminders.

## Privacy and controls
- ✅ **Inbound message toggles**: A `CanMessage` table explicitly handles inbound message permissions. Users can toggle whether they accept new chat requests.
- ✅ **Explicit blocking**: Users can hard-block specific individuals to prevent any further communication or visibility in chats.