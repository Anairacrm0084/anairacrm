-- OTP challenge rows are server-only. Explicitly deny direct anon/authenticated table access.
DROP POLICY IF EXISTS "deny_direct_otp_access" ON public.anaira_guest_otp_challenges;
CREATE POLICY "deny_direct_otp_access"
ON public.anaira_guest_otp_challenges
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);
