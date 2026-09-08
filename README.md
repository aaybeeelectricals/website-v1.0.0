# AAY BEE ELECTRICALS & CONSTRUCTION Attendance System v2

## Features
- Two account roles: Admin and User
- Login has Email, Password, Login as, and Open dropdowns
- Attendance Dashboard and Employee Data pages
- Site-name filter in attendance
- User can mark attendance once per day and cannot edit after saving
- Admin can read, write and change attendance
- Every admin attendance change is logged with who changed it
- Excel attendance export
- Employee data page
- User employee submissions remain pending until admin approval
- Optional Aadhaar upload stored in a private Supabase Storage bucket
- Admin can add, edit and delete employee records

## Setup
1. Create a Supabase project.
2. Run `supabase/schema.sql` in Supabase SQL Editor.
3. Create Authentication users.
4. Insert their matching rows into `employees` with role `admin` or `user`.
5. Put Supabase URL and publishable/anon key into `js/config.js`.
6. Run locally with `python -m http.server 8000` and open `http://localhost:8000`.
7. Deploy the folder to GitHub Pages.

## Important Aadhaar security note
Aadhaar is highly sensitive personal data. Keep the Storage bucket private, use signed URLs only for authorized admins, restrict access, and follow applicable Indian privacy/data-protection requirements. Do not expose Aadhaar files through a public bucket or commit them to GitHub.
