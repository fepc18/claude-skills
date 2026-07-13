---
name: database-schema
description: Genera esquemas SQL production-ready, scripts de migración con golang-migrate, estrategia de índices y datos de seed. Sigue convenciones de clean-architecture con UUID como primary keys, timestamps en todas las tablas, y migrations forward-only para producción.
model_invoked: true
triggers:
  - database schema
  - esquema de base de datos
  - sql schema
  - migraciones
  - migrations
  - schema sql
  - diseño de base de datos
  - tablas de base de datos
  - relaciones entre entidades
  - entity relationships
  - seed data
  - datos de prueba de base de datos
  - índices de base de datos
  - database indexes
  - postgresql schema
  - postgres schema
  - crear tablas
  - create tables
---

# Database Schema Skill

## Purpose

Generate production-ready database schemas, migrations, indexing strategies, and seed data from data models defined in technical specifications. This skill produces:
- DDL SQL for all entities (PostgreSQL-specific)
- Migration pairs (001_*.up.sql + .down.sql) using golang-migrate format
- Foreign key relationships and join tables for N:M associations
- Index strategy based on query patterns
- Test/development seed data fixtures
- Repository interface stubs for Go domain layer
- Database and migration checklists

## Critical: Reference Standards

**Before generating schemas, ALWAYS review:**
1. `../../references/golang-standards.md` — UUID PKs, sqlx library, parameterized queries, index naming
2. `../../references/clean-architecture.md` — Repository pattern, domain interfaces, layering
3. `../../references/cloud-standards.md` — **Forward-only migration rule** (Section 7, Level 3)

All schemas MUST comply with these standards. **CRITICAL: Migrations in production are FORWARD-ONLY. Never rollback migrations. If a migration fails, create a new migration to fix the issue.**

## Workflow

### 1. Entity Identification

Ask the user:
- "What entities from your technical spec need database tables?"
- "Are there lookup tables (enums) or configurations to store?"
- "Which entities are most frequently queried?"

### 2. Relationship Mapping

Ask clarifying questions:
- "What is the cardinality between [Entity A] and [Entity B]?" (1:1, 1:N, N:M)
- "Should [Entity] soft-delete or hard-delete?" (affects schema)
- "Are there circular dependencies between entities?"

### 3. Query Patterns

Ask the user:
- "How will you most frequently query [entities]?" (by email? by status? by date range?)
- "Are there composite queries?" (e.g., find users by email AND status)
- "What are your critical query paths?" (for indexing)

### 4. Schema Generation

Generate DDL SQL following golang-standards.md conventions:
- UUID PRIMARY KEY (generated with gen_random_uuid())
- created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP on every table
- updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP on every table
- UNIQUE constraints where applicable
- Foreign keys with ON DELETE strategy (CASCADE, SET NULL, RESTRICT)
- ENUM types if applicable

### 5. Migration Files

Generate migration pairs:
- `001_create_[entity]s_table.up.sql` — DDL and schema creation
- `001_create_[entity]s_table.down.sql` — Rollback (for local/dev use only, NOT for production)

Number sequentially (001_, 002_, 003_, etc.) and follow naming convention: `{NNN}_{verb}_{entity}.up.sql`

### 6. Seed Data & Index Strategy

- Provide INSERT statements for test fixtures (dev/testing data)
- Define index strategy with rationale:
  - Indexes on frequently searched columns
  - Composite indexes for common filter combinations
  - Partial indexes for filtered queries (WHERE status = 'active', etc.)

### 7. Bridge to Implementation

After schema is approved, ask:
"Ready to generate the implementation scaffolding? This will create the project structure with Go packages, React components, and test setup."

Options:
- Yes → Invoke `implementation-scaffolding` skill
- No → Schema is complete. Save and exit.

## Template Structure

The asset template at `assets/postgres-schema-template.md` includes:

1. **Entity Relationship Diagram** — ASCII diagram showing all entities and their relationships
2. **Table Definitions** — Complete DDL with UUID PKs, timestamps, constraints, ENUM types
3. **Relationships & Foreign Keys** — Join tables for N:M, ON DELETE strategy for each FK
4. **Index Strategy** — Named indexes (idx_{table}_{column}) with rationale for each
5. **Migration Files** — Actual 001_*.up.sql and 001_*.down.sql content
6. **Seed Data** — INSERT fixtures for development/testing
7. **Repository Interface Stub** — Go interface in internal/domain/ for repository pattern
8. **Database Checklist** — Verification points before going to implementation

## Reference Standards Integration

### Schema Conventions

- ✅ UUID PRIMARY KEY on all tables (never serial/integer)
- ✅ created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP (never just TIMESTAMP)
- ✅ updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP on tables that are mutable
- ✅ UNIQUE constraints declared inline on columns
- ✅ Foreign keys explicitly declared with ON DELETE strategy
- ✅ Index naming: `idx_{table}_{column}` (never `idx_[entity]_[entity]_id`)
- ✅ Composite indexes for common multi-column queries
- ✅ Partial indexes for status/flag filtering

### Migration Safety

- ✅ Migrations are FORWARD-ONLY in production (cloud-standards.md Section 7)
- ✅ Never rollback migrations in production
- ✅ If a migration fails, create a new migration to fix (e.g., 002_fix_schema.up.sql)
- ✅ Down migrations are for local development and CI cleanup only
- ✅ Down migrations should never be run in production

### Repository Pattern

- ✅ Repository interface defined in internal/domain/ (no implementation)
- ✅ Interface methods accept context.Context as first argument
- ✅ Database implementation in internal/infrastructure/repository/
- ✅ Parameterized queries ($1, $2, etc.) — never format strings
- ✅ Not-found errors wrapped to domain errors (e.g., domain.ErrUserNotFound)

## Quality Checklist

Before returning the schema to the user:

- ✅ Entity Relationship Diagram is clear and shows all relationships
- ✅ All tables have UUID PRIMARY KEY
- ✅ All tables have created_at and updated_at (TIMESTAMP WITH TIME ZONE)
- ✅ Foreign keys are explicitly declared with ON DELETE strategy
- ✅ Indexes are named with pattern idx_{table}_{column}
- ✅ Composite indexes exist for common multi-column queries
- ✅ Migrations are numbered sequentially (001_, 002_, etc.)
- ✅ Migration up/down pairs are provided
- ✅ Seed data INSERT statements are realistic test data (not dummy values)
- ✅ Repository interface stub is provided in Go
- ✅ Forward-only migration rule is documented in comments
- ✅ All constraints, defaults, and ENUMs are documented

## Interaction Examples

### Example 1: User Management System

**User:** "I need a database schema for a user management system"

**From technical specs provided:**
- User entity: email (unique), name, role (enum: admin, user, guest)
- Team entity: name, owner (foreign key to User)
- Relationship: User can belong to multiple Teams, Teams have multiple Users (N:M)

**Schema Generated Includes:**
1. ERD showing User, Team, and user_teams join table
2. DDL:
   - `users` table: id (UUID), email (UNIQUE), name, role (ENUM), created_at, updated_at
   - `teams` table: id (UUID), name, owner_id (FK), created_at, updated_at
   - `user_teams` table: user_id (FK), team_id (FK), joined_at, with composite PK
3. Indexes:
   - `idx_users_email` (for login queries)
   - `idx_teams_owner_id` (for team listing by owner)
   - `idx_user_teams_team_id` (for finding users in a team)
4. Migrations:
   - 001_create_users_table.up.sql + .down.sql
   - 002_create_teams_table.up.sql + .down.sql
   - 003_create_user_teams_table.up.sql + .down.sql
5. Seed data with sample users and teams
6. Repository interface stub: UserRepository, TeamRepository

### Example 2: E-commerce Order System

**User:** "Database schema for an e-commerce platform"

**Entities:**
- Product, Order, OrderItem, Payment, Review

**Schema Generated Includes:**
1. ERD with all entities and relationships
2. DDL with soft-delete on orders (deleted_at field)
3. Indexes for common queries:
   - idx_products_sku (SKU lookup)
   - idx_orders_customer_id (customer's orders)
   - idx_orders_status (order status filtering)
   - idx_order_items_product_id (items by product)
   - Composite: idx_orders_customer_status (customer orders filtered by status)
4. 5 migration files (one per entity)
5. Seed data: sample products, orders, payments
6. Forward-only migration note emphasizing no rollback in production

## Refinement Workflow

If the user asks for adjustments:
- "Which part would you like to refine?" (relationships, indexes, migration strategy, seed data)
- Edit and re-display affected sections
- Ask: "Better? Ready to move to implementation scaffolding?"
- Offer to add performance analysis or additional indexes

## Dependencies & Context

**Used by:** Technical Specs (Stage 6) users who need detailed SQL, standalone for database-only projects
**Feeds into:** Implementation Scaffolding (generates Go repository stubs) or direct to developers for database setup
**References:**
- `../../references/golang-standards.md` (UUID, sqlx, parameterized queries, index naming)
- `../../references/clean-architecture.md` (repository pattern, domain interfaces)
- `../../references/cloud-standards.md` (forward-only migrations, Section 7)

**Output location:** `/sessions/[session-id]/mnt/outputs/[project-name]-database-schema.md`

---

**Model:** Claude (Opus, Sonnet, or Haiku)
**Invocation:** Model-invoked based on trigger keywords
**Output Format:** Markdown (.md) with embedded SQL, migration scripts, and Go interface stubs
