---
name: postgresql-optimization
description: PostgreSQL performance optimization, indexing strategies (B-Tree, GIN, GiST, BRIN), PostGIS spatial queries, JSONB indexing, and query execution plan tuning.
---

# PostgreSQL Optimization and Performance Guide

Comprehensive performance engineering guide for PostgreSQL databases, focusing on indexing strategies, PostGIS spatial queries, full-text search, and execution plan optimization.

## Indexing Strategies

### 1. Multi-Column (Composite) Indexes
Composite indexes are evaluated based on the leftmost prefix rule. Place equality-filtered columns first, followed by range-filtered or sorting columns.

```sql
-- For queries: WHERE status = 'OPEN' AND created_at >= '2026-01-01' ORDER BY created_at DESC
CREATE INDEX idx_rescue_cases_status_created 
ON rescue_cases (status, created_at DESC);
```

### 2. Partial Indexes for Hot Subsets
Avoid indexing entire tables when queries only target active, non-archived, or specific status subsets. Partial indexes drastically reduce storage overhead and index write amplification.

```sql
-- For querying only active rescue cases
CREATE INDEX idx_rescue_cases_active_urgency 
ON rescue_cases (urgency_level, created_at DESC) 
WHERE is_deleted = false AND status IN ('REPORTED', 'ASSIGNED', 'IN_TRANSIT');

-- For looking up unread notifications
CREATE INDEX idx_notifications_unread_user 
ON notifications (user_id, created_at DESC) 
WHERE is_read = false;
```

### 3. Covering Indexes (Index-Only Scans)
Use the `INCLUDE` clause to append non-key payload columns to a B-tree index. This allows PostgreSQL to perform an Index-Only Scan without reading the heap table pages.

```sql
-- Index on user lookup that also fetches reputation points without a table scan
CREATE INDEX idx_users_email_covering 
ON users (email) 
INCLUDE (id, reputation_points, is_verified);
```

### 4. Expression and Functional Indexes
When filtering on transformed values (such as lowercase email lookups), index the exact expression.

```sql
CREATE UNIQUE INDEX idx_users_lower_email 
ON users (LOWER(email));
```

---

## Spatial Optimization with PostGIS

### 1. Spatial Columns and GiST Indexing
Store geographic coordinates using `geography(Point, 4326)` for distance calculations across the globe without coordinate projection distortions. Always create a `GiST` index on spatial columns.

```sql
ALTER TABLE rescue_cases ADD COLUMN location geography(Point, 4326);

CREATE INDEX idx_rescue_cases_location_gist 
ON rescue_cases USING GIST (location);
```

### 2. Fast Proximity Searches (`ST_DWithin`)
Use `ST_DWithin` instead of `ST_Distance` inside `WHERE` clauses so PostgreSQL can use the GiST index.

```sql
-- Find all rescue cases within 5000 meters of a responder location
SELECT id, title, ST_Distance(location, ST_MakePoint(79.8612, 6.9271)::geography) AS distance_meters
FROM rescue_cases
WHERE ST_DWithin(location, ST_MakePoint(79.8612, 6.9271)::geography, 5000)
  AND is_deleted = false
ORDER BY distance_meters ASC;
```

---

## JSONB Indexing and Query Tuning

### 1. GIN Containment Indexes
When querying nested JSONB attributes for existence or containment (`@>`), index using GIN.

```sql
-- Standard GIN index for keys and paths
CREATE INDEX idx_animals_attributes_gin 
ON animals USING GIN (attributes);

-- Faster containment-only GIN index (smaller footprint)
CREATE INDEX idx_animals_attributes_path_ops 
ON animals USING GIN (attributes jsonb_path_ops);
```

### 2. Generated Stored Columns for Frequent JSONB Fields
If a scalar field within JSONB is frequently filtered or joined, extract it to a generated stored column and place a standard B-tree index on it.

```sql
ALTER TABLE user_profiles 
ADD COLUMN home_size_sqft INT GENERATED ALWAYS AS ((lifestyle_data->>'home_size_sqft')::INT) STORED;

CREATE INDEX idx_user_profiles_home_size 
ON user_profiles (home_size_sqft);
```

---

## Full-Text Search Optimization

### 1. Stored `tsvector` with GIN Index
Avoid computing `to_tsvector` dynamically on every query. Store the pre-computed document vector in a generated column with a GIN index.

```sql
ALTER TABLE animals 
ADD COLUMN search_vector tsvector 
GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(breed, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(description, '')), 'C')
) STORED;

CREATE INDEX idx_animals_search_vector 
ON animals USING GIN (search_vector);
```

### 2. Search Execution with Ranking
Query using `to_tsquery` or `plainto_tsquery` and order by `ts_rank` for relevant results.

```sql
SELECT id, name, breed, ts_rank(search_vector, query) AS rank
FROM animals, plainto_tsquery('english', 'golden retriever friendly') query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```

---

## Query Plan Diagnostics (`EXPLAIN ANALYZE`)

### 1. Interpreting `EXPLAIN (ANALYZE, BUFFERS)`
Always analyze slow queries with `BUFFERS` enabled to understand cache hit ratios and disk I/O.

```sql
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, FORMAT TEXT)
SELECT r.id, r.urgency_level, u.name
FROM rescue_cases r
JOIN users u ON r.reporter_id = u.id
WHERE r.status = 'REPORTED' AND r.is_deleted = false;
```

### 2. Red Flags in Execution Plans
- **Seq Scan on Large Tables**: Indicates a missing index or low predicate selectivity.
- **High `shared_blks_read`**: Indicates the query is fetching data from physical disk rather than the shared buffer cache.
- **Sort Method: external merge Disk**: Indicates `work_mem` is insufficient for the sort, forcing PostgreSQL to spill temporary files to disk. Increase `work_mem` for the query or session.
- **Nested Loop with High Rows**: Can cause catastrophic quadratic execution times if the inner table has no index on the join key.

---

## Connection and Lock Management

### 1. Foreign Key Lock Contention
PostgreSQL locks parent rows during referential checks. Always create explicit indexes on referencing foreign key columns to prevent table-level share locks during deletes and updates.

```sql
CREATE INDEX idx_adoption_applications_animal_id 
ON adoption_applications (animal_id);

CREATE INDEX idx_adoption_applications_adopter_id 
ON adoption_applications (adopter_id);
```

### 2. Safe DDL Operations
- Use `CREATE INDEX CONCURRENTLY` in production migrations to avoid locking write traffic.
- Set a low `lock_timeout` before executing schema migrations (e.g. `SET lock_timeout = '2s';`) so migration attempts do not queue behind long-running queries and stall the entire application.
