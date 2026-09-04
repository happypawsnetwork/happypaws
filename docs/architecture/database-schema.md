# Happy Paws PostgreSQL Schema

This document details the highly scalable, production-ready PostgreSQL database schema for the Happy Paws platform. It rigorously implements the Domain-Driven Design (DDD) requirements, PostgreSQL optimization guidelines, and Entity Framework Core 10 conventions.

## Core Principles Applied
- **Normalization (3NF)**: Strict adherence to 3NF. No transitive dependencies.
- **Data Types**: `BIGINT GENERATED ALWAYS AS IDENTITY` for PKs, `TIMESTAMPTZ` for dates, `JSONB` for flexible attributes, `TSVECTOR` for full-text search, `NUMERIC` for monetary pledges, and PostGIS `geography(Point, 4326)` for spatial proximity calculations.
- **Indexing Strategy**: 
  - **Foreign Keys**: Explicit B-Tree indexes on *every single* foreign key column to prevent table-level share locks during parent deletes/updates.
  - **JSONB**: GIN indexes for containment/existence queries.
  - **Full-Text**: GIN index on generated `TSVECTOR` columns.
  - **Spatial**: GiST indexes on all `geography` columns to power `ST_DWithin` queries.
  - **Partial**: Partial indexes (e.g. `WHERE is_deleted = false`) on highly queried subsets to minimize index bloat.
  - **Generated Columns**: Example included in `animals` where a frequently filtered JSONB attribute (`gender`) is extracted into a stored generated column and B-Tree indexed.
- **Constraints**: Enums handled via `CHECK` constraints on `TEXT` columns to allow safe transactional schema evolution.
- **Audit & Soft Deletes**: Every mutable table includes `created_at` and `updated_at`. Core aggregates use `is_deleted` to support global query filters in EF Core.
- **Concurrency**: Handled via EF Core mapping to PostgreSQL's native `xmin` system column.

---

## 1. Identity and Access Context

### `users`
Base aggregate for all users.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **email** `TEXT NOT NULL UNIQUE`
* **password_hash** `TEXT NOT NULL`
* **first_name** `TEXT NOT NULL`
* **last_name** `TEXT NOT NULL`
* **phone_number** `TEXT` - Encrypted at rest.
* **avatar_url** `TEXT` - Public bucket URL.
* **reputation_points** `INT NOT NULL DEFAULT 0`
* **is_active** `BOOLEAN NOT NULL DEFAULT TRUE`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE UNIQUE INDEX idx_users_lower_email ON users (LOWER(email));`

### `user_roles`
Tracks assigned roles per user (Adopter is default, others explicitly assigned).
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **role_name** `TEXT NOT NULL CHECK (role_name IN ('ADOPTER', 'FOSTER', 'TRANSPORTER', 'VETERINARIAN', 'SPONSOR', 'ADMINISTRATOR'))`
* **PRIMARY KEY (user_id, role_name)**
* **Indexes**: 
  - `CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);`

### `user_badges`
Tracks trust badges earned by users.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **badge_type** `TEXT NOT NULL CHECK (badge_type IN ('WELCOME_HOME', 'GROWING_FAMILY', 'UNCONDITIONAL_LOVE', 'HEALING_HANDS', 'ENDLESS_LOVE', 'URGENT_EXPRESS', 'PAW_PATROL', 'ALWAYS_THERE', 'EMERGENCY_FUNDER'))`
* **awarded_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);`
  - `CREATE UNIQUE INDEX idx_user_badges_user_type ON user_badges(user_id, badge_type);`

### `kyc_verifications`
Identity verification documents submitted for role approvals.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **role_requested** `TEXT NOT NULL CHECK (role_requested IN ('FOSTER', 'TRANSPORTER', 'VETERINARIAN', 'SPONSOR', 'ADMINISTRATOR'))`
* **document_url** `TEXT NOT NULL` - Secured in `happypaws-private` bucket.
* **status** `TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))`
* **reviewed_by** `BIGINT REFERENCES users(id) ON DELETE SET NULL`
* **reviewed_at** `TIMESTAMPTZ`
* **rejection_reason** `TEXT`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_kyc_user_id ON kyc_verifications(user_id);`
  - `CREATE INDEX idx_kyc_reviewed_by ON kyc_verifications(reviewed_by);`
  - `CREATE INDEX idx_kyc_status ON kyc_verifications(status);`

### `user_devices`
Stores Firebase Cloud Messaging (FCM) tokens for geo-targeted push notifications.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **fcm_token** `TEXT NOT NULL UNIQUE`
* **device_type** `TEXT CHECK (device_type IN ('ANDROID', 'IOS', 'WEB'))`
* **last_active_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);`

### `can_message`
Handles inbound message permissions and explicit user blocking.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **target_user_id** `BIGINT REFERENCES users(id) ON DELETE CASCADE` - NULL implies a global rule.
* **is_allowed** `BOOLEAN NOT NULL DEFAULT FALSE` - Represents whether the target can message the user.
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_can_message_user_id ON can_message(user_id);`
  - `CREATE INDEX idx_can_message_target_id ON can_message(target_user_id);`
  - `CREATE UNIQUE INDEX idx_can_message_unique ON can_message(user_id, target_user_id);`

---

## 2. Adoption and Animal Context

### `animals`
Core aggregate for all animals (stray, fostered, or adoptable).
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **owner_id** `BIGINT REFERENCES users(id) ON DELETE SET NULL`
* **name** `TEXT`
* **species** `TEXT NOT NULL`
* **breed** `TEXT`
* **description** `TEXT`
* **status** `TEXT NOT NULL DEFAULT 'NEEDS_RESCUE' CHECK (status IN ('NEEDS_RESCUE', 'FOSTERED', 'ADOPTABLE', 'ADOPTED', 'OWNED'))`
* **attributes** `JSONB NOT NULL DEFAULT '{}'` - Stores dynamic tags, colors, age, etc.
* **gender** `TEXT GENERATED ALWAYS AS (attributes->>'gender') STORED` - Extracted for fast B-Tree scalar indexing.
* **search_vector** `TSVECTOR GENERATED ALWAYS AS (...) STORED` - Uses `setweight` and `to_tsvector('english')` on name, breed, species, and description.
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_animals_owner_id ON animals(owner_id);`
  - `CREATE INDEX idx_animals_gender ON animals(gender);`
  - `CREATE INDEX idx_animals_attributes_gin ON animals USING GIN (attributes);`
  - `CREATE INDEX idx_animals_search_vector ON animals USING GIN (search_vector);`
  - `CREATE INDEX idx_animals_adoptable ON animals(status, created_at DESC) WHERE is_deleted = false AND status = 'ADOPTABLE';`

### `animal_media`
Multiple photos or media for an animal.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **animal_id** `BIGINT NOT NULL REFERENCES animals(id) ON DELETE CASCADE`
* **media_url** `TEXT NOT NULL`
* **media_type** `TEXT NOT NULL DEFAULT 'IMAGE' CHECK (media_type IN ('IMAGE', 'VIDEO'))`
* **is_primary** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_animal_media_animal_id ON animal_media(animal_id);`

### `lifestyle_profiles`
Bundled with adoption applications to match pets with adopters.
* **user_id** `BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE`
* **home_size_sqft** `INT`
* **activity_level** `TEXT CHECK (activity_level IN ('LOW', 'MODERATE', 'HIGH'))`
* **has_existing_pets** `BOOLEAN NOT NULL DEFAULT FALSE`
* **lifestyle_data** `JSONB NOT NULL DEFAULT '{}'`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_lifestyle_data_gin ON lifestyle_profiles USING GIN (lifestyle_data);`

### `adoption_listings`
Animals officially listed for adoption.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **animal_id** `BIGINT NOT NULL REFERENCES animals(id) ON DELETE RESTRICT`
* **lister_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **description** `TEXT NOT NULL`
* **location** `geography(Point, 4326) NOT NULL`
* **status** `TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PUBLISHED', 'ADOPTED', 'CANCELLED'))`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_adoption_listings_animal_id ON adoption_listings(animal_id);`
  - `CREATE INDEX idx_adoption_listings_lister_id ON adoption_listings(lister_id);`
  - `CREATE INDEX idx_adoption_listings_location_gist ON adoption_listings USING GIST (location);`
  - `CREATE INDEX idx_adoption_listings_published ON adoption_listings(status, created_at DESC) WHERE is_deleted = false AND status = 'PUBLISHED';`

### `adoption_applications`
Applications submitted by adopters against listings.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **adoption_listing_id** `BIGINT NOT NULL REFERENCES adoption_listings(id) ON DELETE CASCADE`
* **adopter_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **message** `TEXT`
* **status** `TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED'))`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_adoption_applications_listing_id ON adoption_applications(adoption_listing_id);`
  - `CREATE INDEX idx_adoption_applications_adopter_id ON adoption_applications(adopter_id);`
  - `CREATE UNIQUE INDEX idx_adoption_applications_unique ON adoption_applications(adoption_listing_id, adopter_id);`

---

## 3. Rescue and Field Operations Context

### `rescue_cases`
A report of an animal in distress. The central domain aggregate for triage.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **animal_id** `BIGINT NOT NULL REFERENCES animals(id) ON DELETE RESTRICT`
* **reporter_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **title** `TEXT NOT NULL`
* **description** `TEXT NOT NULL`
* **photo_url** `TEXT NOT NULL` - Public bucket URL for AI/Vet triage.
* **location** `geography(Point, 4326) NOT NULL`
* **ai_urgency_level** `TEXT NOT NULL CHECK (ai_urgency_level IN ('CRITICAL', 'MODERATE', 'LOW'))`
* **vet_urgency_level** `TEXT CHECK (vet_urgency_level IN ('CRITICAL', 'MODERATE', 'LOW'))`
* **status** `TEXT NOT NULL DEFAULT 'REPORTED' CHECK (status IN ('REPORTED', 'ASSIGNED', 'IN_TRANSIT', 'FOSTERED', 'RESOLVED'))`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_rescue_cases_animal_id ON rescue_cases(animal_id);`
  - `CREATE INDEX idx_rescue_cases_reporter_id ON rescue_cases(reporter_id);`
  - `CREATE INDEX idx_rescue_cases_location_gist ON rescue_cases USING GIST (location);`
  - `CREATE INDEX idx_rescue_cases_active ON rescue_cases(status, created_at DESC) WHERE is_deleted = false AND status IN ('REPORTED', 'ASSIGNED', 'IN_TRANSIT');`

### `rescue_updates`
Immutable timeline updates for a rescue case.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **rescue_case_id** `BIGINT NOT NULL REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **update_text** `TEXT NOT NULL`
* **photo_url** `TEXT`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_rescue_updates_case_id ON rescue_updates(rescue_case_id);`
  - `CREATE INDEX idx_rescue_updates_user_id ON rescue_updates(user_id);`

### `transport_requests`
Logistics for moving an animal between locations.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **rescue_case_id** `BIGINT NOT NULL REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **transporter_id** `BIGINT REFERENCES users(id) ON DELETE SET NULL`
* **pickup_location** `geography(Point, 4326) NOT NULL`
* **dropoff_location** `geography(Point, 4326) NOT NULL`
* **status** `TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'ASSIGNED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'))`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_transport_requests_case_id ON transport_requests(rescue_case_id);`
  - `CREATE INDEX idx_transport_requests_transporter_id ON transport_requests(transporter_id);`
  - `CREATE INDEX idx_transport_requests_pickup_gist ON transport_requests USING GIST (pickup_location);`
  - `CREATE INDEX idx_transport_requests_dropoff_gist ON transport_requests USING GIST (dropoff_location);`

### `foster_placements`
Records active or completed foster assignments.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **animal_id** `BIGINT NOT NULL REFERENCES animals(id) ON DELETE RESTRICT`
* **foster_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **start_date** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **end_date** `TIMESTAMPTZ`
* **status** `TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_foster_placements_animal_id ON foster_placements(animal_id);`
  - `CREATE INDEX idx_foster_placements_foster_id ON foster_placements(foster_id);`

### `vet_reviews`
Professional veterinary analysis overriding or confirming AI triage.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **rescue_case_id** `BIGINT NOT NULL REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **vet_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **urgency_override** `TEXT CHECK (urgency_override IN ('CRITICAL', 'MODERATE', 'LOW'))`
* **guidance_notes** `TEXT NOT NULL`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_vet_reviews_case_id ON vet_reviews(rescue_case_id);`
  - `CREATE INDEX idx_vet_reviews_vet_id ON vet_reviews(vet_id);`

---

## 4. Sponsorship Context

### `sponsorships`
Financial pledges supporting rescue cases or animals.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **sponsor_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **rescue_case_id** `BIGINT REFERENCES rescue_cases(id) ON DELETE SET NULL`
* **animal_id** `BIGINT REFERENCES animals(id) ON DELETE SET NULL`
* **amount** `NUMERIC(10,2) NOT NULL CHECK (amount > 0)`
* **status** `TEXT NOT NULL DEFAULT 'PLEDGED' CHECK (status IN ('PLEDGED', 'FULFILLED'))`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Constraints**: 
  - `CHECK (rescue_case_id IS NOT NULL OR animal_id IS NOT NULL)`
* **Indexes**: 
  - `CREATE INDEX idx_sponsorships_sponsor_id ON sponsorships(sponsor_id);`
  - `CREATE INDEX idx_sponsorships_case_id ON sponsorships(rescue_case_id);`
  - `CREATE INDEX idx_sponsorships_animal_id ON sponsorships(animal_id);`

---

## 5. Community Context

### `posts`
Community posts, success stories, and general updates.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **author_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **post_type** `TEXT NOT NULL CHECK (post_type IN ('GENERAL', 'RESCUE_ALERT', 'FOSTER_UPDATE', 'SUCCESS_STORY', 'ADOPTION_LISTING'))`
* **content** `TEXT NOT NULL`
* **location** `geography(Point, 4326)`
* **rescue_case_id** `BIGINT REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **adoption_listing_id** `BIGINT REFERENCES adoption_listings(id) ON DELETE CASCADE`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_posts_author_id ON posts(author_id);`
  - `CREATE INDEX idx_posts_case_id ON posts(rescue_case_id);`
  - `CREATE INDEX idx_posts_listing_id ON posts(adoption_listing_id);`
  - `CREATE INDEX idx_posts_location_gist ON posts USING GIST (location);`
  - `CREATE INDEX idx_posts_feed ON posts(post_type, created_at DESC) WHERE is_deleted = false;`

### `post_media`
Multiple photos or media for a community post.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **post_id** `BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE`
* **media_url** `TEXT NOT NULL`
* **media_type** `TEXT NOT NULL DEFAULT 'IMAGE' CHECK (media_type IN ('IMAGE', 'VIDEO'))`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Indexes**: 
  - `CREATE INDEX idx_post_media_post_id ON post_media(post_id);`

### `post_likes`
Likes and engagement tracking.
* **post_id** `BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **PRIMARY KEY (post_id, user_id)**
* **Indexes**: 
  - `CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);`

---

## 6. Communication Context

### `chat_threads`
SignalR encrypted peer-to-peer message groups tied to domain aggregates.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **rescue_case_id** `BIGINT REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **adoption_application_id** `BIGINT REFERENCES adoption_applications(id) ON DELETE CASCADE`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **updated_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Constraints**: 
  - `CHECK ((rescue_case_id IS NOT NULL AND adoption_application_id IS NULL) OR (rescue_case_id IS NULL AND adoption_application_id IS NOT NULL))`
* **Indexes**: 
  - `CREATE INDEX idx_chat_threads_case_id ON chat_threads(rescue_case_id);`
  - `CREATE INDEX idx_chat_threads_app_id ON chat_threads(adoption_application_id);`

### `chat_participants`
* **thread_id** `BIGINT NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **last_read_at** `TIMESTAMPTZ`
* **PRIMARY KEY (thread_id, user_id)**
* **Indexes**: 
  - `CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);`

### `messages`
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **thread_id** `BIGINT NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE`
* **sender_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT`
* **content** `TEXT NOT NULL`
* **sent_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **delivered_at** `TIMESTAMPTZ`
* **seen_at** `TIMESTAMPTZ`
* **is_deleted** `BOOLEAN NOT NULL DEFAULT FALSE`
* **Indexes**: 
  - `CREATE INDEX idx_messages_thread_id ON messages(thread_id);`
  - `CREATE INDEX idx_messages_sender_id ON messages(sender_id);`
  - `CREATE INDEX idx_messages_thread_sent ON messages(thread_id, sent_at DESC) WHERE is_deleted = false;`

### `notifications`
System events, alerts, and offline message cues.
* **id** `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
* **user_id** `BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE`
* **type** `TEXT NOT NULL CHECK (type IN ('NEW_MESSAGE', 'RESCUE_ALERT', 'TRANSPORT_REQUEST', 'CASE_UPDATE', 'SYSTEM'))`
* **title** `TEXT NOT NULL`
* **content** `TEXT NOT NULL`
* **message_id** `BIGINT REFERENCES messages(id) ON DELETE CASCADE`
* **rescue_case_id** `BIGINT REFERENCES rescue_cases(id) ON DELETE CASCADE`
* **transport_request_id** `BIGINT REFERENCES transport_requests(id) ON DELETE CASCADE`
* **read_at** `TIMESTAMPTZ`
* **created_at** `TIMESTAMPTZ NOT NULL DEFAULT now()`
* **Constraints**: 
  - `CHECK ((type = 'NEW_MESSAGE' AND message_id IS NOT NULL) OR (type IN ('RESCUE_ALERT', 'CASE_UPDATE') AND rescue_case_id IS NOT NULL) OR (type = 'TRANSPORT_REQUEST' AND transport_request_id IS NOT NULL) OR (type = 'SYSTEM'))`
* **Indexes**: 
  - `CREATE INDEX idx_notifications_user_id ON notifications(user_id);`
  - `CREATE INDEX idx_notifications_message_id ON notifications(message_id);`
  - `CREATE INDEX idx_notifications_case_id ON notifications(rescue_case_id);`
  - `CREATE INDEX idx_notifications_transport_id ON notifications(transport_request_id);`
  - `CREATE INDEX idx_notifications_unread ON notifications(user_id, created_at DESC) WHERE read_at IS NULL;`
