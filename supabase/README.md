# Supabase setup

1. Create a Supabase project controlled by the product owner.
2. Enable PostGIS.
3. Link local project with Supabase CLI.
4. Commit every schema change as a migration.
5. Configure Auth email settings.
6. Create Storage buckets and policies through migrations or documented scripts.
7. Configure Flutter with project URL and public anon/publishable key only.
8. Keep service-role credentials in trusted server environments only.
9. Run RLS tests before exposing public clients.

Never commit .env files, service-role keys, database passwords or access tokens. See docs/DATABASE.md and docs/SECURITY_AND_PRIVACY.md.
