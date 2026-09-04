# Internal Messaging Service Specification

## Overview
The Happy Paws platform requires a fully functional, real-time internal messaging service between users. This enables direct peer-to-peer communication outside the context of specific rescue cases or adoption applications, while providing robust privacy, blocking, and location-sharing features.

## 1. Direct Messaging & Public Profile Integration
- **Public Profile Message Button**: Users can visit another user's public profile and initiate a direct message. Clicking the "Message" button opens a new chat thread in the messaging tab.
- **Direct Threads**: Unlike existing contextual threads (tied to rescues/adoptions), these are standalone P2P threads between two users.

## 2. Privacy & `can_message` Rules
A user's inbox is protected by a combination of global settings and explicit user-to-user overrides.

### Global Settings
- **Receive Messages**: By default, users have `receive_messages = true` in their profile. If disabled, no other user can initiate a new conversation with them.

### The `can_message` Table
This table explicitly defines pairwise communication permissions (`from_user`, `to_user`, `is_allowed`).
- **Implicit Whitelisting**: If User A has disabled `receive_messages`, but User A initiates a message to User B, a record is automatically created in `can_message` (`user_id = A`, `target_user_id = B`, `is_allowed = true`). This ensures User B can reply to User A.
- **Blocking**: Users can explicitly block others. Blocking creates/updates a `can_message` record with `is_allowed = false`. A block record strictly prioritizes over any whitelist record.
- **Unblocking**: Unblocking removes the blocking record, reverting to the default global `receive_messages` logic.

## 3. Location Sharing
Users can share physical locations seamlessly within a chat to coordinate rescues or meetups.
- **Current Location**: Share accurate real-time GPS coordinates directly from the chat UI.
- **Home Location**: Users can configure a "Home Location" in their profile settings. If set, they have a quick-action button in the chat to share this specific location.
- **Map Integration**: Tapping a location message opens the native map application (e.g., Google Maps, Apple Maps) on the user's device with a pin dropped at the exact coordinates.

## 4. Message Features
- **Delivery & Read Receipts**: Messages track `sent_at`, `delivered_at`, and `seen_at` timestamps.
- **Message Management**: Users can delete individual messages or entirely delete/archive conversations.
- **Rich Media (Suggested)**: Support for image sharing (e.g., sharing photos of an animal in distress directly in a P2P chat) using the `happypaws-private` bucket for P2P privacy.

## 5. UI/UX Design
- **WhatsApp-like Experience**: The chat interface will feel familiar, featuring message bubbles, inline timestamps, and checkmarks (single for sent, double for delivered, blue for seen).
- **Avatars & Branding**: Beautifully rendered user avatars, adhering to Happy Paws visual branding (colors, rounded corners, soft shadows).
- **Location Bubbles**: A rich preview bubble for location messages, showing a static map snippet or a clear location icon, enhancing the visual appeal.
