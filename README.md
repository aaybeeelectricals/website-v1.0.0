# AAY BEE GitHub Pages + Supabase starter

## Files to upload
Upload every file in this folder to the ROOT of your GitHub repository `aaybeeelectricals/website-v1.0.0`. Keep the filenames unchanged.

- `index.html` is the login page and default website entry.
- `login.html` is the login page.
- `admin.html` is the Admin workspace.
- `user.html` is the User workspace.
- `supabase-config.js` contains your Supabase Project URL and Publishable Key. The Publishable Key is intended for browser use. Never put a `service_role` or secret key here.
- `supabase_schema.sql` creates the database tables and Row Level Security policies.

## Before testing login
1. In Supabase, open SQL Editor and run the complete `supabase_schema.sql` file.
2. In Authentication > Users, create the Admin and employee accounts. Disable public sign-ups for this private portal.
3. For each Auth user, create a matching row in `public.profiles` using that Auth user's UUID. Example for the Admin:

```sql
insert into public.profiles (id, full_name, role)
values ('AUTH-USER-UUID', 'Admin Name', 'admin');
```

For employee accounts use role `user`. The UUID must match the ID in Authentication > Users. The SQL enforces one Admin profile.

4. In Authentication > URL Configuration set Site URL to:
`https://aaybeeelectricals.github.io/website-v1.0.0/`

5. Add this Redirect URL:
`https://aaybeeelectricals.github.io/website-v1.0.0/**`

6. Commit and push all files to the `main` branch. In GitHub Settings > Pages, publish from `main` and `/(root)`.

## Important current scope
This package connects email/password login, checks the signed-in user's active profile and role, routes Admin and User to separate pages, blocks the wrong role from opening a workspace, and adds sign-out. The existing dashboard content still contains preview/sample data and its create/edit/attendance/task/termination actions are NOT yet wired to Supabase. Do not use it for live employee records until those operations are connected and tested. The database schema already includes RLS policies as the security foundation.

## Account creation from the website
Do not create Auth users from browser JavaScript using the service-role API. For in-app account creation, a Supabase Edge Function or trusted server is required. Until that is built, create accounts in Supabase Authentication > Users and add their matching profiles.
