
sql
-- =========================================================
--  ENUM TYPES
-- =========================================================

CREATE TYPE institution_type AS ENUM ('university', 'company', 'other');

CREATE TYPE route_type AS ENUM ('DRIVER_ROUTE', 'GROUP_TAXI');
CREATE TYPE route_member_role AS ENUM ('DRIVER', 'PASSENGER');

CREATE TYPE trip_status AS ENUM ('SCHEDULED', 'CANCELED', 'COMPLETED');
CREATE TYPE trip_participant_status AS ENUM ('GOING', 'NOT_GOING', 'NO_SHOW');

CREATE TYPE payment_method_type AS ENUM ('CASH', 'CARD', 'E_WALLET');
CREATE TYPE payment_status AS ENUM ('PENDING', 'PAID', 'CANCELED');

CREATE TYPE notification_type AS ENUM (
    'TRIP_REMINDER',
    'NEW_ROUTE_MEMBER',
    'ROUTE_INVITE',
    'PAYMENT_STATUS',
    'SYSTEM'
);

CREATE TYPE support_ticket_status AS ENUM (
    'OPEN',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED'
);

-- =========================================================
--  CORE REFERENCE TABLES
-- =========================================================

-- 1. Institutions
CREATE TABLE institutions (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    type        institution_type NOT NULL DEFAULT 'other',
    city        TEXT
);

-- 2. Users
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    phone           TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    photo_url       TEXT,
    bio             TEXT,
    institution_id  BIGINT REFERENCES institutions(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Vehicle brands
CREATE TABLE vehicle_brands (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    country     TEXT
);

-- 4. Vehicle models
CREATE TABLE vehicle_models (
    id              BIGSERIAL PRIMARY KEY,
    brand_id        BIGINT NOT NULL REFERENCES vehicle_brands(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    body_type       TEXT,  -- e.g., 'sedan', 'hatchback'
    default_seats   INT,
    UNIQUE (brand_id, name)
);

-- 5. Locations
CREATE TABLE locations (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    type        TEXT, -- e.g., 'POINT', 'AREA'
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    description TEXT
);

-- =========================================================
--  ROUTES & SCHEDULE
-- =========================================================

-- 6. Routes
CREATE TABLE routes (
    id               BIGSERIAL PRIMARY KEY,
    creator_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    institution_id   BIGINT REFERENCES institutions(id) ON DELETE SET NULL,
    route_type       route_type NOT NULL,
    from_location    TEXT NOT NULL,
    to_location      TEXT NOT NULL,
    from_location_id BIGINT REFERENCES locations(id),
    to_location_id   BIGINT REFERENCES locations(id),
    departure_time   TIME NOT NULL,
    price_per_ride   NUMERIC(10, 2),
    price_per_week   NUMERIC(10, 2),
    seats            INT CHECK (seats IS NULL OR seats > 0),
    notes            TEXT,
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Route schedule days
CREATE TABLE route_schedule_days (
    route_id    BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    weekday     SMALLINT NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    PRIMARY KEY (route_id, weekday)
);

-- 8. Route members (M:N between users and routes)
CREATE TABLE route_members (
    route_id        BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_route   route_member_role NOT NULL,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (route_id, user_id)
);

-- One driver per route (if route uses a driver)
CREATE UNIQUE INDEX ux_route_driver
    ON route_members(route_id)
    WHERE role_in_route = 'DRIVER';

-- 9. Route stops (ordered list of stops)
CREATE TABLE route_stops (
    id                      BIGSERIAL PRIMARY KEY,
    route_id                BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    position_in_route       INT NOT NULL CHECK (position_in_route > 0),
    location_id             BIGINT REFERENCES locations(id) ON DELETE SET NULL,
    name                    TEXT NOT NULL,
    arrival_offset_minutes  INT,
    UNIQUE (route_id, position_in_route)
);

-- 10. Route invites
CREATE TABLE route_invites (
    id              BIGSERIAL PRIMARY KEY,
    route_id        BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    invited_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    invite_token    TEXT NOT NULL UNIQUE,
    status          TEXT NOT NULL DEFAULT 'PENDING', -- PENDING / ACCEPTED / DECLINED / EXPIRED
    expires_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
--  TRIPS & PARTICIPANTS
-- =========================================================

-- 11. Trips
CREATE TABLE trips (
    id          BIGSERIAL PRIMARY KEY,
    route_id    BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    trip_date   DATE NOT NULL,
    status      trip_status NOT NULL DEFAULT 'SCHEDULED',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_route_trip_date UNIQUE (route_id, trip_date)
);

-- 12. Trip participants (M:N between users and trips)
CREATE TABLE trip_participants (
    trip_id                 BIGINT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id                 BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status                  trip_participant_status NOT NULL DEFAULT 'GOING',
    rating_for_driver       INT CHECK (rating_for_driver BETWEEN 1 AND 5),
    rating_for_passenger    INT CHECK (rating_for_passenger BETWEEN 1 AND 5),
    comment                 TEXT,
    PRIMARY KEY (trip_id, user_id)
);

-- =========================================================
--  VEHICLES
-- =========================================================

-- 13. Vehicles (owned by users)
CREATE TABLE vehicles (
    id              BIGSERIAL PRIMARY KEY,
    owner_id        BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model_id        BIGINT REFERENCES vehicle_models(id) ON DELETE SET NULL,
    plate_number    TEXT NOT NULL UNIQUE,
    color           TEXT,
    year            INT CHECK (year IS NULL OR year >= 1980),
    seats           INT CHECK (seats IS NULL OR seats > 0),
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
--  PAYMENTS
-- =========================================================

-- 14. Payment methods
CREATE TABLE payment_methods (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method_type     payment_method_type NOT NULL,
    details_masked  TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 15. Payments
CREATE TABLE payments (
    id              BIGSERIAL PRIMARY KEY,
    trip_id         BIGINT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    payer_id        BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method_id       BIGINT REFERENCES payment_methods(id) ON DELETE SET NULL,
    amount          NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    status          payment_status NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
--  PROMO CODES
-- =========================================================

-- 16. Promo codes
CREATE TABLE promo_codes (
    id                  BIGSERIAL PRIMARY KEY,
    code                TEXT NOT NULL UNIQUE,
    description         TEXT,
    discount_percent    INT CHECK (discount_percent BETWEEN 1 AND 100),
    active_from         DATE,
    active_until        DATE,
    max_uses_total      INT,
    max_uses_per_user   INT,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE
);

-- 17. User promo code usage
CREATE TABLE user_promo_codes (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    promo_code_id   BIGINT NOT NULL REFERENCES promo_codes(id) ON DELETE CASCADE,
    used_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    trip_id         BIGINT REFERENCES trips(id) ON DELETE SET NULL,
    PRIMARY KEY (user_id, promo_code_id, used_at)
);

-- =========================================================
--  NOTIFICATIONS
-- =========================================================

-- 18. Notifications
CREATE TABLE notifications (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            notification_type NOT NULL,
    payload         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at         TIMESTAMPTZ
);

-- =========================================================
--  SUPPORT TICKETS
-- =========================================================

-- 19. Support tickets
CREATE TABLE support_tickets (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject         TEXT NOT NULL,
    description     TEXT NOT NULL,
    status          support_ticket_status NOT NULL DEFAULT 'OPEN',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
--  AUDIT LOGS
-- =========================================================

-- 20. Audit logs
CREATE TABLE audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action          TEXT NOT NULL,     -- e.g., 'CREATE_ROUTE', 'JOIN_TRIP'
    entity_type     TEXT NOT NULL,     -- e.g., 'route', 'trip', 'payment'
    entity_id       BIGINT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    meta            JSONB
);

-- =========================================================
--  INDEXES
-- =========================================================

-- Core
CREATE INDEX idx_users_institution_id      ON users(institution_id);
CREATE INDEX idx_routes_institution_id     ON routes(institution_id);
CREATE INDEX idx_routes_route_type         ON routes(route_type);
CREATE INDEX idx_trips_route_id_date       ON trips(route_id, trip_date);
CREATE INDEX idx_trip_participants_user    ON trip_participants(user_id);

-- Vehicles
CREATE INDEX idx_vehicles_owner            ON vehicles(owner_id);
CREATE INDEX idx_vehicle_models_brand      ON vehicle_models(brand_id);

-- Locations & stops
CREATE INDEX idx_locations_name            ON locations(name);
CREATE INDEX idx_route_stops_route_pos     ON route_stops(route_id, position_in_route);

-- Payments
CREATE INDEX idx_payments_trip             ON payments(trip_id);
CREATE INDEX idx_payments_payer            ON payments(payer_id);

-- Promo codes
CREATE INDEX idx_promo_codes_code          ON promo_codes(code);
CREATE INDEX idx_user_promo_codes_user     ON user_promo_codes(user_id);

-- Notifications
CREATE INDEX idx_notifications_user        ON notifications(user_id);
CREATE INDEX idx_notifications_type        ON notifications(type);

-- Support tickets
CREATE INDEX idx_support_tickets_user      ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status    ON support_tickets(status);

-- Audit logs
CREATE INDEX idx_audit_logs_user           ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity         ON audit_logs(entity_type, entity_id);
