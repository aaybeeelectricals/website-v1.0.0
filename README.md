# AAY BEE Electricals & Construction
## GitHub Pages + shared Supabase database

This package contains the sign-in page, Founder dashboard, Manager dashboard, Supabase configuration, SQL setup/migration files, and upload instructions.

## A. Upload to GitHub Pages

Upload these six files to the ROOT of `aaybeeelectricals/website-v1.0.0` and replace the old versions:

- `index.html` — sign-in page / website entry point
- `login.html` — sign-in page alias
- `admin.html` — Founder dashboard
- `user.html` — Manager dashboard
- `supabase-config.js` — Supabase project connection
- `README.md` — instructions (optional)

Keep all five website files in the same folder. The HTML pages load `./supabase-config.js`.

Website:
`https://aaybeeelectricals.github.io/website-v1.0.0/`

## B. Supabase URL settings

In Supabase → Authentication → URL Configuration:

- Site URL: `https://aaybeeelectricals.github.io/website-v1.0.0/`
- Redirect URL: `https://aaybeeelectricals.github.io/website-v1.0.0/**`

Save the changes.

The provided `supabase-config.js` contains the project URL and the publishable key supplied for this project. A publishable key is intended for browser use. Never put a `service_role` or secret key in any HTML, JavaScript, or GitHub file.

## C. Which SQL should I run?

### If this is a fresh Supabase project
Run `supabase_setup_all.sql` once in Supabase → SQL Editor. This installs the base schema, collaboration tables, attendance linked to employees, approval workflow, automatic Manager profiles, notification triggers, and access policies.

### If you already installed the earlier AAY BEE schema and migrations
Run the updated `founder_manager_shared_database.sql` in SQL Editor. It includes the new employee approval workflow, age/DOB and phone validation, site/designation access policies, and notification triggers. Do not run the full `supabase_setup_all.sql` over an existing live database.

If you are unsure what has already been run, do not run all SQL files one after another. Check Supabase Table Editor first or take a database backup before applying migrations.

Other SQL files are included as staged reference files:
- `supabase_schema.sql` — base tables and RLS
- `live_collaboration.sql` — task updates and messaging database support
- `founder_manager_shared_database.sql` — shared Founder/Manager migration and current fixes
- `supabase_setup_all.sql` — complete fresh-install script

## D. Create the one Founder account

1. Supabase → Authentication → Users → Add user.
2. Create the Founder email/password account.
3. Copy the Auth user's UUID.
4. Run this SQL after replacing the two sample values:

```sql
insert into public.profiles (id, full_name, role, active)
values ('PASTE-FOUNDER-AUTH-UUID', 'Founder Full Name', 'admin', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'admin',
    active = true;
```

Only one active Founder/Admin account is supported.

## E. Add Manager accounts

1. Supabase → Authentication → Users → Add user.
2. Create each Manager email/password account.
3. The database trigger automatically creates a profile with role `user`.
4. The Founder dashboard loads active Manager accounts from Supabase. The Founder can assign tasks to a specific Manager.

For a display name, set Auth user metadata `full_name` when creating the account. Otherwise the email prefix is used.

For Manager Auth accounts that existed before the trigger was installed, add the profile manually:

```sql
insert into public.profiles (id, full_name, role, active)
values ('PASTE-MANAGER-AUTH-UUID', 'Manager Full Name', 'user', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'user',
    active = true;
```

## F. How employee entry and approval now work

- Founder uses separate `Employee Data` and `Add Employee` pages.
- Founder can add employee records directly.
- Managers use `Add Employee` to submit a request.
- A Manager's request is stored in `employee_requests`, not in the live employee directory.
- The new employee appears in the shared `employees` table only after the Founder approves it.
- Founder can reject a request; the Manager sees the request status.
- Founder can terminate an employee from `Employee Data`. Termination requires a reason and typing `TERMINATE` to confirm.
- Age is calculated from date of birth. It is not manually entered.
- Site and designation dropdowns load from the shared `sites` and `designations` tables.
- Phone number must contain exactly 10 digits. The browser validates it and the database also enforces it for new records.

## G. Shared database behaviour

Founder and Managers use one Supabase project and the same tables.

- Employee directory: shared and visible to both roles.
- Attendance: Managers record attendance for a selected employee. One entry per employee per date.
- Tasks: Founder assigns a task to one Manager. Only that Manager sees it.
- Task progress: Managers submit progress updates; Founder can see the task status.
- Approvals: Manager requests are sent to Founder.
- Notifications: the bell displays unread Supabase notifications. Task assignment, employee requests, approvals, attendance and task progress generate notifications.
- Language: English/Odia switch is enabled on Founder and Manager pages. The login page retains its own language control.
- Messages UI has been removed from both workspaces. Existing database messaging tables are left untouched.

## H. Test after deployment

Use one Founder login and one Manager login:

1. Switch English/Odia on both dashboards.
2. Add a site and designation as Founder.
3. Submit an employee request as Manager. Confirm it does not appear in Employee List yet.
4. Approve it as Founder. Confirm it now appears in Employee Data and Manager Employee List.
5. Add an employee as Founder and confirm it appears for Manager.
6. Record attendance for that employee as Manager. Confirm Founder can see it.
7. Assign a task as Founder. Confirm only the assigned Manager sees it.
8. Check notification badges on both sides.
9. Terminate an employee as Founder using a reason and the exact confirmation word `TERMINATE`.

The HTML and JavaScript syntax is checked. The actual live Supabase workflow must still be tested after SQL is applied and the GitHub files are deployed.
