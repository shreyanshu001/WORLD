-- Spatial types and functions for Worlds (docs/DATABASE.md).
-- Installed into the extensions schema, as Supabase recommends, so its
-- tables and functions stay out of the public API schema.
create extension if not exists postgis with schema extensions;
