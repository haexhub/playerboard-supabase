-- NOTE: change to your own passwords for production environments
\set pgpass `echo "$POSTGRES_PASSWORD"`

ALTER USER authenticator WITH PASSWORD :'pgpass';
ALTER USER pgbouncer WITH PASSWORD :'pgpass';
ALTER USER supabase_auth_admin WITH PASSWORD :'pgpass';
ALTER USER supabase_functions_admin WITH PASSWORD :'pgpass';
ALTER USER supabase_storage_admin WITH PASSWORD :'pgpass';

-- The Supabase CLI's `db push` (used by the playerboard app to apply its
-- own migrations on container boot, see haexhub/playerboard#27) runs
-- migration statements as `postgres` — the role Supabase Cloud projects
-- use to own all of their objects. Self-hosted images keep `postgres`
-- deliberately non-superuser and put real admin rights on
-- `supabase_admin` instead, so a push that ALTERs an object created by
-- supabase_admin (e.g. the app's trigger functions) fails with "must be
-- owner". Membership lets `postgres` inherit ownership-equivalent
-- privileges on supabase_admin's objects without becoming superuser.
GRANT supabase_admin TO postgres;
