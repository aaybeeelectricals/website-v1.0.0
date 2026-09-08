import { supabase } from './config.js';

const form = document.getElementById('loginForm');
const message = document.getElementById('message');

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  message.textContent = 'Signing in...';

  const email = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;
  const destination = document.getElementById('destination').value;

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (error) {
    message.textContent = error.message;
    return;
  }

  // The user's role is checked from the database.
  // The login page does not ask the user to choose Admin/User.
  const { data: employee, error: profileError } = await supabase
    .from('employees')
    .select('role, active')
    .eq('auth_user_id', data.user.id)
    .single();

  if (profileError || !employee || !employee.active) {
    await supabase.auth.signOut();
    message.textContent = 'Your account is not active or is not linked to an employee profile.';
    return;
  }

  // Role is determined by the database, not by the login form.
  // The selected page only decides where to go after successful login.
  if (destination === 'attendance') {
    window.location.href = 'attendance.html';
  } else {
    window.location.href = 'employee-data.html';
  }
});
