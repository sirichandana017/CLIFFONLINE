/*
  # Clear User Data

  1. Changes
    - Safely removes all user data while preserving table structure
    - Clears verification codes
    - Clears user profiles and related tables
    - Preserves database structure and policies
*/

-- Clear verification codes
TRUNCATE verification_codes CASCADE;

-- Clear user-related tables in correct order
TRUNCATE customers CASCADE;
TRUNCATE retailers CASCADE;
TRUNCATE wholesalers CASCADE;
TRUNCATE user_profiles CASCADE;

-- Clear auth.users (requires superuser privileges, handled by Supabase)
DELETE FROM auth.users;