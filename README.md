# AAY BEE Electricals & Construction
## Founder + Manager website with one shared Supabase database

This package includes the GitHub Pages website, Supabase browser configuration, database setup SQL, and installation instructions.

## A. Upload to GitHub Pages

Upload/replace these six files in the ROOT of your repository:

1. `index.html` — login page and GitHub Pages home page
2. `login.html` — login page direct link
3. `admin.html` — Founder dashboard
4. `user.html` — Manager dashboard
5. `supabase-config.js` — Supabase connection
6. `README.md` — optional documentation

Repository: https://github.com/aaybeeelectricals/website-v1.0.0

Keep the HTML files and `supabase-config.js` together in the same root folder. Commit the changes and wait for GitHub Pages to deploy.

Website: https://aaybeeelectricals.github.io/website-v1.0.0/

## B. Supabase Auth URL settings

In Supabase → Authentication → URL Configuration:

Site URL:
`https://aaybeeelectricals.github.io/website-v1.0.0/`

Redirect URL:
`https://aaybeeelectricals.github.io/website-v1.0.0/**`

Save the settings.

## C. Run the correct SQL file

Choose ONE of these paths:

### Fresh Supabase project
If you have not installed the AAY BEE database schema yet:
1. Open Supabase → SQL Editor → New query.
2. Copy all of `supabase_setup_all.sql`.
3. Run it once.

### Existing AAY BEE Supabase project
If you already ran `supabase_schema.sql` and `live_collaboration.sql`, run only the updated `founder_manager_shared_database.sql`.

If you have only run `supabase_schema.sql`, run `live_collaboration.sql` first and then `founder_manager_shared_database.sql`.

Do not run the combined fresh-install SQL on top of an existing live database. Back up the database before applying migrations.

## D. Create the one Founder account

1. Supabase → Authentication → Users → Add user.
2. Create the Founder email/password account.
3. Copy the Auth user's UUID.
4. Run this SQL, replacing the values:

```sql
insert into public.profiles (id, full_name, role, active)
values ('FOUNDER-AUTH-UUID', 'Founder Full Name', 'admin', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'admin',
    active = true;
```

Only one active profile should have role `admin`.

## E. Add Manager accounts

1. Supabase → Authentication → Users → Add user.
2. Create the Manager email/password account.
3. The database trigger creates a profile with role `user` automatically.
4. The Founder dashboard refreshes the Manager list and makes the new Manager available for task assignment.

If a Manager Auth account existed before the profile trigger was installed, create their profile manually:

```sql
insert into public.profiles (id, full_name, role, active)
values ('MANAGER-AUTH-UUID', 'Manager Full Name', 'user', true)
on conflict (id) do update
set full_name = excluded.full_name,
    role = 'user',
    active = true;
```

Set the Manager's `full_name` metadata when creating the Auth account. If missing, the trigger uses the email prefix.

## F. Set up Site and Designation first

Sign in as Founder. Open **Site & Designation** and add the sites and designations your company uses. The Add Employee forms on both Founder and Manager pages fetch these options from Supabase automatically.

## G. How employee approval works

- Founder can add an employee directly from the separate **Add Employee** page.
- Manager submits a new employee record from their separate **Add Employee** page.
- A Manager submission is stored in `employee_requests`, not in the live employee directory.
- Founder reviews it in **Approvals**.
- Only when Founder approves it, the database function inserts the record into the shared `employees` table.
- Rejected or pending requests do not appear in the shared Employee Data list.
- The Manager receives a notification when the request is approved or rejected.

Age is calculated automatically from date of birth on the form. Phone numbers must contain exactly ten digits.

## H. Website features

- One Supabase database shared by Founder and Managers.
- Real English/Odia switch on both dashboards. Language choice is saved in the browser.
- Messages section removed from both dashboards.
- Employee Data and Add Employee are separate pages.
- Founder can terminate an employee from Employee Data by entering a reason and typing `TERMINATE` to confirm.
- Site and designation dropdowns load from shared Supabase tables.
- Manager attendance is recorded against the selected employee, not against the Manager login.
- Founder assigns tasks to a specific Manager.
- Only the assigned Manager sees that task.
- Notification bell shows unread notifications. New employee requests, task assignments, task updates and approval decisions generate notifications.
- Row Level Security and database functions enforce the permissions.

## I. Test after deployment

Use one Founder and one Manager account:

1. Confirm the Founder can sign in and Manager appears in the Manager list.
2. Add one Site and one Designation as Founder.
3. Submit an employee request as Manager. Confirm it does not appear in Employee List yet.
4. Approve it as Founder. Confirm it appears in both Founder Employee Data and Manager Employee List.
5. Punch attendance for that employee as Manager. Confirm Founder sees the attendance.
6. Assign a task as Founder. Confirm only the selected Manager sees it.
7. Submit a task update and an approval request as Manager. Confirm Founder sees both.
8. Check notifications on both dashboards.
9. Switch English to Odia and back on both dashboards.
10. Terminate a test employee as Founder and verify the reason is saved.

## Security

- The `supabase-config.js` file contains the project URL and publishable key supplied for this site. Publishable keys are intended for browser use.
- Never put a Supabase `service_role` or secret key in GitHub or browser JavaScript.
- RLS is the security boundary. Do not disable it to make a page work.

## Testing note

Inline JavaScript syntax was checked for the four HTML pages. This does not replace testing against the live Supabase project after SQL and GitHub deployment.


## Current website bug-fix SQL

The current website build uses the Supabase project URL configured in `supabase-config.js`.

For a brand-new Supabase project, `supabase_setup_all.sql` already includes the latest fixes.

If you already ran the complete setup SQL before receiving this update, run `website_bug_fixes.sql` once in Supabase SQL Editor. It fixes employee-based attendance, permits present/absent/half-day attendance, and supports in-progress task updates.

Do not run the complete fresh-install SQL again over an existing database.
