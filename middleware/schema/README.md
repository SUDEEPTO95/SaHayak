# PostgreSQL/PostGIS foundation

`001_postgis_core.sql` is an explicit, reviewable schema foundation. It is not run automatically by the middleware.

## Activation order

1. Set `DATABASE_URL` in the environment. Example:
   `postgresql+psycopg://sahayak:password@127.0.0.1:5432/sahayak`
2. Start the PostGIS service from `infra/docker-compose.yml` or use an approved managed PostgreSQL/PostGIS service.
3. Apply `001_postgis_core.sql` with an operator account after reviewing passwords, network exposure, retention, and backups.
4. Keep the current SQLAlchemy snapshot store as the compatibility path while normalized repository writes are migrated table by table.

No application startup code runs this migration, and no credentials belong in Git.

## Store mapping

| Current `MemoryStore` collection | Normalized destination |
|---|---|
| `users`, `tokens` | `users`, `auth_sessions` |
| `otps`, `otp_hits` | `otp_challenges` |
| `donors` | `donors` |
| `requests` | `blood_requests` |
| `directory` | `directory_entries` |
| `inventory` | `inventory` |
| `family_rings` | `family_rings`, `family_ring_members` |
| `notice_log` | `notifications` |
| `help_offers` | `help_offers` |
| `checkins` | `checkins` |
| `camps`, `camp_rsvps` | `camps`, `camp_rsvps` |
| `ai_memory` | `ai_memory` |
| `ai_traces`, `reflection_log` | `ai_traces`, `audit_events` |

## Security decisions

- Store token and OTP hashes, never raw credentials.
- Keep phone/email access-controlled and out of public matching responses.
- Use tenant-scoped foreign keys and indexes on every operational table.
- Use PostGIS geography points for distance queries; do not expose exact donor coordinates to clients.
- Apply retention jobs for OTPs, sessions, notifications, AI traces, and location-bearing records.
- Add PostgreSQL row-level security when the application switches from snapshot writes to normalized repositories.
- Test backup restore before production launch.
