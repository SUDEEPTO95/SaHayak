-- SaHayak PostgreSQL/PostGIS foundation.
-- Apply explicitly after reviewing secrets and retention policy.
-- The current middleware snapshot store remains compatible with this schema.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS sahayak;

CREATE TABLE IF NOT EXISTS sahayak.tenants (
    id text PRIMARY KEY,
    name text NOT NULL,
    logo_url text,
    brand_color text,
    subtitle text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.users (
    id text PRIMARY KEY,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    email text,
    phone text,
    display_name text,
    role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'owner', 'tenant_admin')),
    language text NOT NULL DEFAULT 'en',
    is_frozen boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, email),
    UNIQUE (tenant_id, phone)
);

CREATE TABLE IF NOT EXISTS sahayak.donors (
    user_id text PRIMARY KEY REFERENCES sahayak.users(id) ON DELETE CASCADE,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    blood_group text NOT NULL CHECK (blood_group IN ('O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+')),
    component_ok text NOT NULL DEFAULT 'whole',
    available boolean NOT NULL DEFAULT true,
    self_hold boolean NOT NULL DEFAULT false,
    fasting_hold boolean NOT NULL DEFAULT false,
    fever_hold boolean NOT NULL DEFAULT false,
    verified_group boolean NOT NULL DEFAULT false,
    woman boolean NOT NULL DEFAULT false,
    city text,
    last_donation_at timestamptz,
    location geography(Point, 4326),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.blood_requests (
    id text PRIMARY KEY,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    seeker_id text NOT NULL REFERENCES sahayak.users(id),
    recipient_group text NOT NULL CHECK (recipient_group IN ('O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+')),
    component text NOT NULL DEFAULT 'whole',
    units_needed integer NOT NULL CHECK (units_needed BETWEEN 1 AND 20),
    units_accepted integer NOT NULL DEFAULT 0 CHECK (units_accepted >= 0),
    remaining_lock integer NOT NULL CHECK (remaining_lock >= 0),
    hospital_name text NOT NULL,
    ward text,
    bed text,
    urgency text NOT NULL DEFAULT 'critical',
    status text NOT NULL DEFAULT 'open',
    patient_is_minor boolean NOT NULL DEFAULT false,
    location geography(Point, 4326),
    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.directory_entries (
    id text PRIMARY KEY,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    kind text NOT NULL,
    name text NOT NULL,
    state text,
    district text,
    phone text,
    hours text,
    location geography(Point, 4326),
    verified_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.inventory (
    id text PRIMARY KEY,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    blood_group text NOT NULL CHECK (blood_group IN ('O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+')),
    component text NOT NULL DEFAULT 'whole',
    units integer NOT NULL DEFAULT 0 CHECK (units >= 0),
    location_name text,
    state text,
    district text,
    verified_at timestamptz,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.audit_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    actor_user_id text REFERENCES sahayak.users(id),
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id text,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.auth_sessions (
    token_hash text PRIMARY KEY,
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz,
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.otp_challenges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    identifier_hash text NOT NULL,
    channel text NOT NULL CHECK (channel IN ('email', 'mobile')),
    code_hash text NOT NULL,
    attempts integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    expires_at timestamptz NOT NULL,
    consumed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    target_user_id text REFERENCES sahayak.users(id) ON DELETE SET NULL,
    request_id text REFERENCES sahayak.blood_requests(id) ON DELETE SET NULL,
    kind text NOT NULL,
    channel text NOT NULL CHECK (channel IN ('inbox', 'fcm', 'whatsapp', 'email')),
    status text NOT NULL DEFAULT 'queued',
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    available_at timestamptz NOT NULL DEFAULT now(),
    sent_at timestamptz,
    failed_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.consents (
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    purpose text NOT NULL,
    granted_at timestamptz,
    revoked_at timestamptz,
    source text,
    PRIMARY KEY (user_id, purpose)
);

CREATE TABLE IF NOT EXISTS sahayak.family_rings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    name text NOT NULL DEFAULT 'Family Ring',
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.family_ring_members (
    ring_id uuid NOT NULL REFERENCES sahayak.family_rings(id) ON DELETE CASCADE,
    member_user_id text,
    member_label text,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (ring_id, member_user_id, member_label)
);

CREATE TABLE IF NOT EXISTS sahayak.help_offers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    request_id text REFERENCES sahayak.blood_requests(id) ON DELETE SET NULL,
    kind text NOT NULL,
    hospital_name text,
    location geography(Point, 4326),
    expires_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.checkins (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    request_id text REFERENCES sahayak.blood_requests(id) ON DELETE SET NULL,
    eta_minutes integer CHECK (eta_minutes IS NULL OR eta_minutes BETWEEN 0 AND 1440),
    location geography(Point, 4326),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.camps (
    id text PRIMARY KEY,
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    name text NOT NULL,
    status text NOT NULL DEFAULT 'open',
    starts_at timestamptz,
    ends_at timestamptz,
    location geography(Point, 4326),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.camp_rsvps (
    camp_id text NOT NULL REFERENCES sahayak.camps(id) ON DELETE CASCADE,
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (camp_id, user_id)
);

CREATE TABLE IF NOT EXISTS sahayak.ai_memory (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text NOT NULL REFERENCES sahayak.tenants(id),
    user_id text NOT NULL REFERENCES sahayak.users(id) ON DELETE CASCADE,
    topic text,
    intent text,
    language text NOT NULL DEFAULT 'en',
    outcome text,
    expires_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sahayak.ai_traces (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id text REFERENCES sahayak.tenants(id),
    user_id text REFERENCES sahayak.users(id) ON DELETE SET NULL,
    kind text NOT NULL,
    status text NOT NULL,
    provider text,
    model text,
    latency_ms integer,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS donors_tenant_group_available_idx
    ON sahayak.donors (tenant_id, blood_group, available)
    WHERE available = true AND self_hold = false AND fasting_hold = false AND fever_hold = false;
CREATE INDEX IF NOT EXISTS donors_location_gist_idx ON sahayak.donors USING gist (location);
CREATE INDEX IF NOT EXISTS requests_tenant_status_created_idx
    ON sahayak.blood_requests (tenant_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS requests_location_gist_idx ON sahayak.blood_requests USING gist (location);
CREATE INDEX IF NOT EXISTS directory_location_gist_idx ON sahayak.directory_entries USING gist (location);
CREATE INDEX IF NOT EXISTS directory_tenant_kind_idx ON sahayak.directory_entries (tenant_id, kind);
CREATE INDEX IF NOT EXISTS inventory_tenant_group_component_idx
    ON sahayak.inventory (tenant_id, blood_group, component);
CREATE INDEX IF NOT EXISTS audit_tenant_created_idx
    ON sahayak.audit_events (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS audit_metadata_gin_idx
    ON sahayak.audit_events USING gin (metadata);
CREATE INDEX IF NOT EXISTS sessions_user_expiry_idx
    ON sahayak.auth_sessions (user_id, expires_at)
    WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS otp_identifier_expiry_idx
    ON sahayak.otp_challenges (identifier_hash, expires_at)
    WHERE consumed_at IS NULL;
CREATE INDEX IF NOT EXISTS notifications_queue_idx
    ON sahayak.notifications (status, available_at, created_at)
    WHERE status IN ('queued', 'retry');
CREATE INDEX IF NOT EXISTS notifications_target_created_idx
    ON sahayak.notifications (target_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS consents_user_purpose_idx
    ON sahayak.consents (user_id, purpose);
CREATE INDEX IF NOT EXISTS help_offers_location_gist_idx ON sahayak.help_offers USING gist (location);
CREATE INDEX IF NOT EXISTS help_offers_expiry_idx ON sahayak.help_offers (expires_at);
CREATE INDEX IF NOT EXISTS checkins_user_created_idx ON sahayak.checkins (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS camps_location_gist_idx ON sahayak.camps USING gist (location);
CREATE INDEX IF NOT EXISTS camps_status_start_idx ON sahayak.camps (status, starts_at);
CREATE INDEX IF NOT EXISTS ai_memory_user_created_idx ON sahayak.ai_memory (tenant_id, user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS ai_traces_created_idx ON sahayak.ai_traces (tenant_id, created_at DESC);

INSERT INTO sahayak.tenants (id, name, brand_color, subtitle)
VALUES ('public', 'Public India', '#C42B4A', 'blood help nearby')
ON CONFLICT (id) DO NOTHING;
