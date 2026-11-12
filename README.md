# AAY BEE Live Collaboration Update

## What this update changes
- Uses the same Supabase database for the one Admin and all User accounts.
- Admin assigns tasks to an existing active User account.
- Assigned tasks appear in that User's workspace.
- Users can submit Pending, In progress, or Completed updates with a note.
- Admin can see every task update and the latest task status.
- Users can message the single Admin. Admin can select an employee and reply.
- Employee directory and attendance are read from the same Supabase database.
- User attendance punches are stored in Supabase and visible to Admin.
- Data refreshes automatically about every 5 seconds.
- No demo/sample records are inserted by this update.

## Important: run SQL in the correct order
1. In Supabase SQL Editor, run your original `supabase_schema.sql` first, if you have not already run it.
2. Then run the complete `live_collaboration.sql` file from this package.
3. Make sure there is exactly one active profile with role `admin`.
4. Make sure every employee has an Auth account and a matching active row in `public.profiles` with role `user`.

## Upload to GitHub
Upload and overwrite these files in the ROOT of `aaybeeelectricals/website-v1.0.0`:
- `index.html`
- `admin.html`
- `user.html`
- `login.html`
- `supabase-config.js`

Also upload `live_collaboration.sql` for reference (it does not need to be hosted by GitHub Pages).
Keep `supabase-config.js` in the repository root, next to the HTML pages.

## Test
1. Open `https://aaybeeelectricals.github.io/website-v1.0.0/`.
2. Sign in as the Admin.
3. Assign a task to an active User.
4. Open a private/incognito window or another browser and sign in as that User.
5. The task should appear in My Tasks within about 5 seconds.
6. Change the status and submit a progress note.
7. Return to Admin. The status and note should appear in Latest User Updates within about 5 seconds.
8. Send a message from User to Admin, then reply from Admin.

## Important security notes
- Browser code uses only the Supabase Project URL and Publishable Key.
- Never put the Supabase service_role or secret key in GitHub or HTML.
- Supabase Row Level Security is the authority. The UI is not the security boundary.
- This update uses database tables and RPC functions. It does not create Auth users from the browser. Create employee Auth accounts in Supabase Authentication and assign their profile UUIDs as before.
- Do not use live company data until you have run both SQL scripts and completed the two-account test above.

## Website verification limitation
The GitHub repository source can be inspected, but GitHub Pages pages did not return readable page content to the web inspection tool in this session. Therefore the deployed browser experience cannot be confirmed from here. The included test sequence is required after uploading.
