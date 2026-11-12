# AAY BEE Founder + Manager shared workspace

## Roles
- `admin` = the one Founder account.
- `user` = Manager accounts.
- Employee records are separate from login accounts. A Manager login is not an employee record.

## Shared database
All pages use the one Supabase project configured in `supabase-config.js`. No local demo records or sample employees/managers/tasks are inserted. The Founder and Managers read/write the same Supabase tables, subject to Row Level Security.

## Apply the SQL
1. In Supabase SQL Editor, confirm the original schema and earlier `live_collaboration.sql` have been run.
2. Run `founder_manager_shared_database.sql`.
3. The migration checks whether the attendance employee foreign key already exists, so that part can be rerun safely.

## Add/remove Manager accounts
1. Create the Manager login in Supabase Authentication > Users.
2. The migration installs a database trigger that automatically creates a `public.profiles` row with role `user` for each newly created Auth account. The Founder page discovers it and refreshes the Manager list every five seconds. No manual profile insert is needed for newly created Managers.
3. For the profile display name, set Auth user metadata `full_name` when creating the account. If it is not supplied, the email prefix is used.
4. To remove a Manager from the website, delete that login in Supabase Authentication > Users. Its profile is removed by the existing cascade. Or set `active=false` in `profiles` to deactivate without deleting the Auth account. The Founder page stops showing inactive/deleted accounts after refresh.
5. A deleted Manager's assigned tasks and messages are deleted by their account relationship. Employee records they created remain.

## Founder account
Create one Auth user, then assign the matching profile role `admin`. The existing unique index permits only one Admin profile. The Founder is not selected from a role dropdown on the website.

## Upload to GitHub Pages
Replace these files in the root of `aaybeeelectricals/website-v1.0.0`:
- `index.html`
- `login.html`
- `admin.html`
- `user.html`
- `supabase-config.js`

Keep the SQL and README files outside the public website if preferred. The publishable key is browser-safe; never put a service_role/secret key in GitHub.

## New behavior
- Founder sees active Manager profiles dynamically and assigns tasks by Manager UUID.
- Each Manager sees only tasks assigned to their own login.
- Manager records attendance for a selected employee, not for themselves.
- Attendance is keyed by employee + date, so one employee cannot be punched twice for the same date.
- Managers can add employee records to the shared directory; Founder and other Managers see those same records.
- Manager approval submissions go to the Founder approval inbox.
- Founder and Manager can message each other.
- Pages refresh shared records every five seconds.
- No dummy data is inserted.

## Verification
The HTML JavaScript syntax was checked locally. A live end-to-end test still needs to be done after applying the SQL and uploading files, using one Founder account and at least one Manager account.
