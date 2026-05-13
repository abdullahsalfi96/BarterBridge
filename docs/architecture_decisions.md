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