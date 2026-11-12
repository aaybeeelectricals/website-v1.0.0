# AAY BEE Electricals & Construction
## GitHub Pages + one shared Supabase database

This package contains the complete website files and SQL for the Founder and Manager workspaces.

### Website files to upload to the ROOT of your GitHub repository

Upload/replace these six files together in the same folder:

- `index.html` — sign-in page and GitHub Pages entry point
- `login.html` — same sign-in page, for direct login links
- `admin.html` — Founder workspace
- `user.html` — Manager workspace
- `supabase-config.js` — connection to your Supabase project
- `README.md` — these instructions (optional on the public site)

Keep the HTML files and `supabase-config.js` side by side. Do not put them in different folders unless you also update their relative script paths.

### Your Supabase project

The included `supabase-config.js` is already set to the Supabase project and publishable key you supplied. The publishable key is designed for browser use. Never put a Supabase `service_role` or secret key in GitHub or in an HTML/JavaScript file.

## 1. Configure GitHub Pages

1. Open your GitHub repository: `aaybeeelectricals/website-v1.0.0`.
2. Upload the six website files listed above to the repository root.
3. Choose to replace existing files when GitHub asks.
4. Commit the changes.
5. In Settings → Pages, make sure GitHub Pages is publishing the correct branch and root folder.
6. Wait for deployment, then open:
   `https://aaybeeelectricals.github.io/website-v1.0.0/`

The sign-in page is `index.html`. After sign-in, the website sends the Founder to `admin.html` and Managers to `user.html` based on the role stored in Supabase.

## 2. Set Supabase Auth URL configuration

In Supabase:
1. Open Authentication → URL Configuration.
2. Set Site URL to:
   `https://aaybeeelectricals.github.io/website-v1.0.0/`
3. Add this to Redirect URLs:
   `https://aaybeeelectricals.github.io/website-v1.0.0/**`
4. Save.

The current login flow uses email and password. It does not create accounts from the public login page.

## 3. Apply the database SQL

Choose ONE path:

### Option A — Fresh Supabase database only

If this Supabase project has not had the AAY BEE schema installed yet:
1. Open Supabase → SQL Editor → New query.
2. Open `supabase_setup_all.sql`.
3. Copy the entire file into SQL Editor.
4. Run it once.

This combined SQL installs the base schema, task/message collaboration, attendance for employee records, approval inbox, Manager profile auto-creation, and the single Founder lookup function. It creates no sample employees, tasks, attendance, sites, designations, or messages.

### Option B — Existing AAY BEE database

If you already ran `supabase_schema.sql` and `live_collaboration.sql` previously:
1. Run `founder_manager_shared_database.sql` only.
2. Do not run `supabase_setup_all.sql` on top of the existing database.

If you have only run `supabase_schema.sql`, run `live_collaboration.sql` first, then `founder_manager_shared_database.sql`.

If you already ran the Founder/Manager migration, do not rerun the full base schema just to update the HTML.

## 4. Set up the one Founder account

The Founder must be the only profile with role `admin`.

1. Supabase → Authentication → Users → Add user.
2. Create the Founder login using the Founder email and password.
3. Copy the user's UUID from the Auth Users list.
4. In SQL Editor, run this after replacing the sample values:

```sql
insert into public.profiles (id, full_name, role, active)
values ('PASTE-FOUNDER-AUTH-UUID', 'Founder Full Name', 'admin', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'admin',
    active = true;
```

If the Founder profile already exists, this changes its role to `admin`. The database has a one-Founder constraint, so only one active Admin profile is allowed by the existing schema's unique index.

## 5. Add Manager accounts

After the SQL migration is installed:

1. Go to Supabase → Authentication → Users → Add user.
2. Enter the Manager's email and password.
3. The database trigger automatically creates a profile with role `user`.
4. The Founder dashboard discovers active Manager profiles and refreshes the list every five seconds.
5. The Founder can then assign tasks to the correct Manager.

For the Manager's display name, set Auth user metadata `full_name` when creating the account. If no full name is supplied, the trigger uses the email prefix.

If a Manager Auth account existed before the trigger was installed, create its profile manually:

```sql
insert into public.profiles (id, full_name, role, active)
values ('PASTE-MANAGER-AUTH-UUID', 'Manager Full Name', 'user', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'user',
    active = true;
```

To deactivate without deleting the Auth account:

```sql
update public.profiles
set active = false
where id = 'PASTE-MANAGER-AUTH-UUID';
```

To permanently remove an account, delete it from Authentication → Users. Related profile and assigned task/message records follow their foreign-key delete rules. Employee records created by that Manager are retained.

## 6. How the shared website works

- There is one Supabase project and one shared set of tables.
- Founder (`admin`) and Managers (`user`) do not have separate databases.
- Managers and Founder see the same employee directory.
- Managers can add employee records to the shared directory.
- Managers punch attendance for a selected employee, not for their own login.
- Attendance is unique per employee per date.
- Founder assigns a task to one Manager account. Only that Manager sees the task.
- Managers submit task progress through the secure `update_my_task` database function.
- Managers send approval submissions to the Founder approval inbox.
- Founder and Managers can exchange private messages.
- Row Level Security (RLS) is enabled to enforce access rules in the database, not only in the webpage.

## 7. First live test

After deployment, test with one Founder and one Manager account:

1. Sign in as Founder. Confirm the Manager appears under Managers.
2. Add one employee. Sign in as Manager and confirm the same employee appears in Employee List.
3. As Manager, punch attendance for that employee. Sign in as Founder and confirm the same attendance entry appears.
4. As Founder, assign a task to that Manager. Confirm it appears in that Manager's My Tasks.
5. As Manager, update task progress. Confirm the task status changes in Founder Task Assigner.
6. As Manager, submit an approval. Confirm it appears in Founder Approvals.
7. Send a message from each side and confirm both sides see the same conversation.

## Important notes

- This is a static GitHub Pages website connected directly to Supabase using the publishable key. Supabase RLS is the security boundary.
- Never publish a `service_role` key.
- The package's JavaScript syntax was checked, but the live site and database still need the first end-to-end test after SQL is applied and files are deployed.
- The language selector is currently a visual control; the redesigned pages are English-first. The login page retains its existing English/Odia language support.
