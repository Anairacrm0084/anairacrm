# Login Password Visibility Fix — 2026-10-06

## Change
The `/login` page now includes an accessible password visibility toggle.

- Default state remains masked (`type="password"`).
- Eye button switches the field to plain text while pressed.
- Button switches back to masked mode.
- `aria-label`, `aria-pressed`, and `title` update with the state.
- Existing Supabase authentication flow is unchanged.
- No password value is sent anywhere other than the existing Supabase `signInWithPassword` call.

## Files
- `app/login/page.js`
- `app/globals.css`
