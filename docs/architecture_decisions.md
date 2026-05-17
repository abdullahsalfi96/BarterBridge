Architecture Decisions — BarterBridge

Decision 1: Why One Backend API for All Four Platforms

Decision: All platforms (mobile, web, website, desktop)
connect to the same single Node.js backend API.

Reason: One backend means one place to update business logic.
If we change how trades work, we change it once — not four times.

Alternative considered: Separate backend per platform.
Why rejected: Four times the maintenance, four times the bugs,
four times the deployment complexity.

---

Decision 2: Why a Separate Python Service for AI

Decision: AI matching and analytics run in Python,
not inside the Node.js backend.

Reason: Python has the best libraries for machine learning
(scikit-learn, pandas, numpy). Node.js does not.
Also, if the AI service crashes, the main API keeps working.

Alternative considered: Running Python code inside Node.js
using child processes.
Why rejected: Messy, slow, hard to scale independently.

---

Decision 3: Why PostgreSQL as Main Database

Decision: PostgreSQL is the primary database.

Reason: BarterBridge needs structured relational data —
users, listings, trades all have strict relationships.
PostgreSQL supports this reliably, handles complex queries,
and has geospatial support for location-based filtering.

Alternative considered: MongoDB (NoSQL).
Why rejected: Trade data is highly relational. A listing belongs
to a user, a trade connects two listings and two users.
Forcing this into documents creates unnecessary complexity.

---

Decision 4: Why Redis

Decision: Redis is used for caching and session storage.

Reason: Frequently accessed data like category lists,
popular listings, and user sessions should not hit
PostgreSQL on every request. Redis keeps this data
in memory for near-instant access.

Alternative considered: Storing sessions in PostgreSQL.
Why rejected: Database session lookups on every API request
add unnecessary load. Redis is built for this exact use case.

---

Decision 5: Why UUID Instead of Integer IDs

Decision: All primary keys use UUID (Universally Unique Identifier),
not auto-incrementing integers.

Reason: Integer IDs expose business information.
If your first trade has id=1 and your competitor's has id=50000,
that tells the world about your scale.
UUIDs also allow records to be created across multiple servers
without ID collision — critical for horizontal scaling.

Alternative considered: Auto-increment integers.
Why rejected: Easy to enumerate (attacker guesses user IDs sequentially),
reveals data volume, breaks in distributed systems.

---


Decision 6: Why a Separate Location Table

Decision: Location is its own table, not embedded in Listing.

Reason: Multiple listings can share the same city.
Storing "Lahore, Punjab, Pakistan" as text in every listing
wastes space and makes location-based queries slow.
One Location row is referenced by many Listings — normalized data.

Alternative considered: Store city/country as plain text in Listing.
Why rejected: Breaks normalization. Makes geospatial queries harder.
Duplicate data causes inconsistency when a city name needs updating.