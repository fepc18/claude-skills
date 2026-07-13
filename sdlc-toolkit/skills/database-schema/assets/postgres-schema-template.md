# Database Schema: [Project/Feature Name]

## 1. Entity Relationship Diagram

ASCII representation of all entities and their relationships:

```
User (1) ──────┬──── (N) UserProfile
              │
              ├──── (N) Team (join via user_teams)
              │
              ├──── (N) Order
              │
              └──── (N) Review

Product (1) ──── (N) OrderItem
            │
            └──── (N) Review

Team (1) ──┬──── (N) User (join via user_teams)
           │
           └──── (N) TeamMember (derived from user_teams)

Order (1) ────┬──── (N) OrderItem
              │
              └──── (1) Payment

Payment (1) ──── (1) Order
```

**Cardinality Legend:**
- `(1) ──── (1)` — One-to-One relationship
- `(1) ──── (N)` — One-to-Many relationship
- `(N) ──── (N)` — Many-to-Many relationship (join table required)

---

## 2. Table Definitions

Complete DDL for all entities.

### users Table

```sql
-- internal/domain/user.go + internal/infrastructure/repository/postgres

CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  role user_role NOT NULL DEFAULT 'user',
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE users IS 'Core user accounts for the system';
COMMENT ON COLUMN users.id IS 'UUID primary key, auto-generated';
COMMENT ON COLUMN users.email IS 'Unique email address, used for login';
COMMENT ON COLUMN users.role IS 'User role: admin (full access), user (standard), guest (limited)';
COMMENT ON COLUMN users.is_active IS 'Soft delete flag; false = user cannot login';
```

### user_profiles Table

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  avatar_url VARCHAR(1024),
  phone_number VARCHAR(20),
  location VARCHAR(255),
  website_url VARCHAR(1024),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE user_profiles IS 'Extended user profile information';
COMMENT ON COLUMN user_profiles.user_id IS 'Foreign key to users.id; UNIQUE for one-to-one relationship';
COMMENT ON COLUMN user_profiles.avatar_url IS 'S3 or CDN URL to user avatar image';
```

### teams Table

```sql
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE teams IS 'Teams/organizations for grouping users and managing permissions';
COMMENT ON COLUMN teams.owner_id IS 'User ID of team creator/owner; ON DELETE RESTRICT prevents deleting team if user deleted';
COMMENT ON COLUMN teams.slug IS 'URL-friendly identifier; must be unique';
```

### user_teams Table (N:M Join)

```sql
CREATE TABLE user_teams (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, team_id)
);

COMMENT ON TABLE user_teams IS 'Junction table for many-to-many User-Team relationship';
COMMENT ON COLUMN user_teams.role IS 'Role within the team: member, moderator, owner';
COMMENT ON COLUMN user_teams.joined_at IS 'When user joined the team';
```

### products Table

```sql
CREATE TYPE product_status AS ENUM ('draft', 'active', 'archived');

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price_cents INTEGER NOT NULL,
  status product_status NOT NULL DEFAULT 'draft',
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE products IS 'Product catalog';
COMMENT ON COLUMN products.price_cents IS 'Price in cents (integer) to avoid floating-point issues';
COMMENT ON COLUMN products.stock_quantity IS 'Current inventory level';
```

### orders Table

```sql
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) NOT NULL UNIQUE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status order_status NOT NULL DEFAULT 'pending',
  total_cents INTEGER NOT NULL,
  tax_cents INTEGER NOT NULL DEFAULT 0,
  shipping_address TEXT NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE orders IS 'Customer orders';
COMMENT ON COLUMN orders.deleted_at IS 'Soft-delete timestamp; NULL = active, non-NULL = deleted';
COMMENT ON COLUMN orders.total_cents IS 'Total amount in cents (before tax)';
```

### order_items Table

```sql
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price_cents INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE order_items IS 'Line items in an order';
COMMENT ON COLUMN order_items.unit_price_cents IS 'Price at time of order (product price may have changed)';
```

### payments Table

```sql
CREATE TYPE payment_status AS ENUM ('pending', 'processed', 'failed', 'refunded');

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  status payment_status NOT NULL DEFAULT 'pending',
  amount_cents INTEGER NOT NULL,
  provider VARCHAR(50),
  provider_transaction_id VARCHAR(255),
  failed_reason TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE payments IS 'Payment records for orders';
COMMENT ON COLUMN payments.order_id IS 'One-to-one relationship with orders; UNIQUE constraint';
COMMENT ON COLUMN payments.provider IS 'Payment provider: stripe, paypal, square, etc.';
```

### reviews Table

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  comment TEXT,
  is_verified_purchase BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE reviews IS 'Product reviews by users';
COMMENT ON COLUMN reviews.is_verified_purchase IS 'True if reviewer actually purchased the product';
COMMENT ON COLUMN reviews.deleted_at IS 'Soft-delete for user-initiated review removal';
```

---

## 3. Foreign Key Relationships

All foreign keys, their strategies, and rationale:

| Table | FK Column | References | Strategy | Rationale |
|-------|-----------|-----------|----------|-----------|
| user_profiles | user_id | users.id | CASCADE | Profile exists only with user; delete user → delete profile |
| teams | owner_id | users.id | RESTRICT | Prevent deleting user if they own a team (must reassign first) |
| user_teams | user_id | users.id | CASCADE | When user deleted, remove all team memberships |
| user_teams | team_id | teams.id | CASCADE | When team deleted, remove all user memberships |
| products | created_by | users.id | RESTRICT | Preserve audit trail of who created product |
| orders | user_id | users.id | RESTRICT | Cannot delete user with active orders (business logic) |
| order_items | order_id | orders.id | CASCADE | Delete items when order deleted |
| order_items | product_id | products.id | RESTRICT | Cannot delete product if it's in any order |
| payments | order_id | orders.id | CASCADE | Delete payment when order deleted |
| reviews | product_id | products.id | CASCADE | Delete reviews when product deleted |
| reviews | user_id | users.id | CASCADE | Delete reviews when user deleted (cleanup) |

---

## 4. Index Strategy

Indexes to support common queries and business logic.

### Search & Lookup Indexes

```sql
-- User lookups
CREATE INDEX idx_users_email ON users(email);
  -- RATIONALE: Users often queried by email (login, password reset)
  -- EXPECTED CARDINALITY: Low (UNIQUE, but index helps EXPLAIN plans)

CREATE INDEX idx_users_is_active ON users(is_active);
  -- RATIONALE: Filter users by active status (admins checking banned users)
  -- EXPECTED CARDINALITY: Medium (most users active, some inactive)

-- Product lookups
CREATE INDEX idx_products_sku ON products(sku);
  -- RATIONALE: SKU is a unique identifier used to look up products
  -- EXPECTED CARDINALITY: Low (UNIQUE)

CREATE INDEX idx_products_status ON products(status);
  -- RATIONALE: Filter products by status (show only 'active' in storefront)
  -- EXPECTED CARDINALITY: Medium (most active, some draft/archived)

-- Order lookups
CREATE INDEX idx_orders_user_id ON orders(user_id);
  -- RATIONALE: "Show all orders for this user" — common customer page query
  -- EXPECTED CARDINALITY: High (many orders per user)

CREATE INDEX idx_orders_status ON orders(status);
  -- RATIONALE: "Show pending orders" — common admin dashboard query
  -- EXPECTED CARDINALITY: High (many orders, various statuses)

-- Team lookups
CREATE INDEX idx_teams_owner_id ON teams(owner_id);
  -- RATIONALE: "Show all teams owned by this user"
  -- EXPECTED CARDINALITY: Medium

CREATE INDEX idx_teams_slug ON teams(slug);
  -- RATIONALE: URL-based team lookups (team.example.com/teams/[slug])
  -- EXPECTED CARDINALITY: Low (UNIQUE)
```

### Composite Indexes (Multi-column Queries)

```sql
-- Find active orders for a specific user
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
  -- RATIONALE: "SELECT * FROM orders WHERE user_id = $1 AND status = 'pending'"
  -- COLUMN ORDER: user_id first (higher selectivity), then status

-- Find all products in a specific status created by a user
CREATE INDEX idx_products_status_created ON products(status, created_by);
  -- RATIONALE: Admin listing products filtered by status
  -- COLUMN ORDER: status first (lower selectivity), created_by second
```

### Partial Indexes (Filtered Queries)

```sql
-- Find only active users
CREATE INDEX idx_users_active ON users(id) WHERE is_active = true;
  -- RATIONALE: "Show active users" — most queries filter by is_active = true
  -- BENEFIT: Smaller index, faster scans

-- Find only active products
CREATE INDEX idx_products_active ON products(id) WHERE status = 'active';
  -- RATIONALE: Storefront only shows active products
  -- BENEFIT: Smaller index dedicated to storefront queries

-- Find only non-deleted orders
CREATE INDEX idx_orders_not_deleted ON orders(user_id) WHERE deleted_at IS NULL;
  -- RATIONALE: Most queries exclude soft-deleted orders
  -- BENEFIT: Smaller index for active order queries
```

### Foreign Key Indexes (Automatic but Documented)

PostgreSQL automatically creates indexes on foreign key columns for referential integrity checks. These are implicitly indexed:
- `user_profiles.user_id` (auto-indexed by FK)
- `teams.owner_id` (auto-indexed by FK)
- `orders.user_id` (auto-indexed by FK)
- etc.

---

## 5. Migration Files

### 001_create_users_table.up.sql

```sql
BEGIN;

CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  role user_role NOT NULL DEFAULT 'user',
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_active ON users(id) WHERE is_active = true;

COMMIT;
```

### 001_create_users_table.down.sql

```sql
BEGIN;

DROP INDEX IF EXISTS idx_users_active;
DROP INDEX IF EXISTS idx_users_is_active;
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS user_role;

COMMIT;
```

### 002_create_teams_table.up.sql

```sql
BEGIN;

CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_teams_owner_id ON teams(owner_id);
CREATE INDEX idx_teams_slug ON teams(slug);

COMMIT;
```

### 002_create_teams_table.down.sql

```sql
BEGIN;

DROP INDEX IF EXISTS idx_teams_slug;
DROP INDEX IF EXISTS idx_teams_owner_id;
DROP TABLE IF EXISTS teams;

COMMIT;
```

### 003_create_user_teams_table.up.sql

```sql
BEGIN;

CREATE TABLE user_teams (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, team_id)
);

CREATE INDEX idx_user_teams_team_id ON user_teams(team_id);

COMMIT;
```

### 003_create_user_teams_table.down.sql

```sql
BEGIN;

DROP INDEX IF EXISTS idx_user_teams_team_id;
DROP TABLE IF EXISTS user_teams;

COMMIT;
```

### 004_create_products_table.up.sql

```sql
BEGIN;

CREATE TYPE product_status AS ENUM ('draft', 'active', 'archived');

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price_cents INTEGER NOT NULL,
  status product_status NOT NULL DEFAULT 'draft',
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_active ON products(id) WHERE status = 'active';
CREATE INDEX idx_products_status_created ON products(status, created_by);

COMMIT;
```

### 004_products_table.down.sql

```sql
BEGIN;

DROP INDEX IF EXISTS idx_products_status_created;
DROP INDEX IF EXISTS idx_products_active;
DROP INDEX IF EXISTS idx_products_status;
DROP INDEX IF EXISTS idx_products_sku;
DROP TABLE IF EXISTS products;
DROP TYPE IF EXISTS product_status;

COMMIT;
```

---

## 6. Seed Data (Development/Testing)

```sql
-- Development fixture data for testing and local development

BEGIN;

INSERT INTO users (id, email, name, role, password_hash, is_active) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'admin@example.com', 'Admin User', 'admin', 'hashed_password_here', true),
  ('550e8400-e29b-41d4-a716-446655440002', 'john@example.com', 'John Doe', 'user', 'hashed_password_here', true),
  ('550e8400-e29b-41d4-a716-446655440003', 'jane@example.com', 'Jane Smith', 'user', 'hashed_password_here', true),
  ('550e8400-e29b-41d4-a716-446655440004', 'guest@example.com', 'Guest User', 'guest', 'hashed_password_here', false);

INSERT INTO user_profiles (user_id, bio, avatar_url, location) VALUES
  ('550e8400-e29b-41d4-a716-446655440002', 'Software engineer from NY', 'https://..., 'New York');

INSERT INTO teams (id, name, slug, owner_id, is_active) VALUES
  ('650e8400-e29b-41d4-a716-446655440001', 'Engineering', 'engineering', '550e8400-e29b-41d4-a716-446655440001', true),
  ('650e8400-e29b-41d4-a716-446655440002', 'Marketing', 'marketing', '550e8400-e29b-41d4-a716-446655440001', true);

INSERT INTO user_teams (user_id, team_id, role) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', '650e8400-e29b-41d4-a716-446655440001', 'owner'),
  ('550e8400-e29b-41d4-a716-446655440002', '650e8400-e29b-41d4-a716-446655440001', 'member'),
  ('550e8400-e29b-41d4-a716-446655440003', '650e8400-e29b-41d4-a716-446655440002', 'member');

INSERT INTO products (sku, name, description, price_cents, status, stock_quantity, created_by) VALUES
  ('PROD-001', 'Widget A', 'Premium quality widget', 9999, 'active', 100, '550e8400-e29b-41d4-a716-446655440001'),
  ('PROD-002', 'Widget B', 'Budget widget', 4999, 'active', 250, '550e8400-e29b-41d4-a716-446655440001'),
  ('PROD-003', 'Prototype X', 'Work in progress', 0, 'draft', 0, '550e8400-e29b-41d4-a716-446655440001');

COMMIT;
```

---

## 7. Repository Interface Stub (Go)

```go
// internal/domain/user_repository.go

package domain

import (
	"context"
	"time"
)

// User represents a user entity
type User struct {
	ID           string
	Email        string
	Name         string
	Role         string // 'admin', 'user', 'guest'
	PasswordHash string
	IsActive     bool
	LastLoginAt  *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

// UserRepository defines the contract for user data access
type UserRepository interface {
	// Save creates or updates a user
	Save(ctx context.Context, user *User) error

	// FindByID retrieves a user by ID
	FindByID(ctx context.Context, id string) (*User, error)

	// FindByEmail retrieves a user by email
	FindByEmail(ctx context.Context, email string) (*User, error)

	// FindAll retrieves all active users with pagination
	FindAll(ctx context.Context, offset, limit int) ([]*User, error)

	// Update updates an existing user
	Update(ctx context.Context, user *User) error

	// Delete soft-deletes a user (sets is_active = false)
	Delete(ctx context.Context, id string) error
}
```

---

## 8. Database Checklist

Use this checklist before declaring the schema complete:

**Schema Design:**
- [ ] All tables have UUID PRIMARY KEY (never serial/integer)
- [ ] All tables have created_at and updated_at (TIMESTAMP WITH TIME ZONE)
- [ ] All ENUMs are defined correctly and referenced in tables
- [ ] All NOT NULL constraints are intentional (default values where appropriate)
- [ ] UNIQUE constraints on business keys (email, SKU, slug, etc.)
- [ ] Foreign keys are explicit with ON DELETE strategy

**Relationships:**
- [ ] All one-to-many relationships have explicit FKs
- [ ] All many-to-many relationships have join tables
- [ ] Join tables have composite PRIMARY KEY (user_id, team_id)
- [ ] FK referential integrity is documented in comments

**Indexes:**
- [ ] Single-column indexes on frequently searched columns (email, status, created_by)
- [ ] Composite indexes on common multi-column queries (user_id + status)
- [ ] Partial indexes on filtered queries (WHERE is_active = true)
- [ ] Index naming follows pattern idx_{table}_{column}
- [ ] All indexes documented with RATIONALE comments

**Migrations:**
- [ ] Migrations numbered sequentially (001_, 002_, etc.)
- [ ] Up migrations create tables, indexes, ENUMs
- [ ] Down migrations drop in reverse order (indexes first, then tables, then types)
- [ ] Both up and down are wrapped in BEGIN; ... COMMIT;
- [ ] Forward-only migration rule documented: "Never rollback in production"

**Soft Deletes:**
- [ ] Tables using soft deletes have deleted_at column (TIMESTAMP WITH TIME ZONE, nullable)
- [ ] Partial indexes exclude soft-deleted records WHERE deleted_at IS NULL
- [ ] FK strategy on soft-deleted tables is RESTRICT (prevent orphans)

**Seed Data:**
- [ ] Seed data uses realistic values (not "test", "xxx", "1111")
- [ ] Foreign key IDs in seed data match actual inserted IDs
- [ ] Seed data is wrapped in BEGIN; ... COMMIT;
- [ ] No hardcoded passwords in production seed data

**Repository Interface:**
- [ ] Interface defined in internal/domain/{entity}_repository.go
- [ ] All methods accept context.Context as first argument
- [ ] Methods return domain entities, not database models
- [ ] Not-found errors are domain-specific (ErrUserNotFound, not sql.ErrNoRows)

**Production Safety:**
- [ ] Comments document each table and column purpose
- [ ] Forward-only migration rule is understood and followed
- [ ] Rollback procedures documented: "If migration fails, create new migration to fix"
- [ ] No rollback of migrations attempted in production
