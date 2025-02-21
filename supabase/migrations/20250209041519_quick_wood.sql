/*
  # Update verification codes table

  1. Changes
    - Safely create verification_codes table if it doesn't exist
    - Add policies if they don't exist
  
  2. Security
    - Enable RLS
    - Allow creation by anyone
    - Allow reading only by the code owner
*/

DO $$ 
BEGIN
  -- Create table if it doesn't exist
  CREATE TABLE IF NOT EXISTS verification_codes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL,
    code text NOT NULL,
    created_at timestamptz DEFAULT now(),
    expires_at timestamptz NOT NULL,
    used boolean DEFAULT false
  );

  -- Enable RLS if not already enabled
  ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

  -- Create policies if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'verification_codes' 
    AND policyname = 'Anyone can create verification codes'
  ) THEN
    CREATE POLICY "Anyone can create verification codes"
      ON verification_codes
      FOR INSERT
      TO authenticated, anon
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'verification_codes' 
    AND policyname = 'Users can read their own verification codes'
  ) THEN
    CREATE POLICY "Users can read their own verification codes"
      ON verification_codes
      FOR SELECT
      TO authenticated, anon
      USING (email = current_user);
  END IF;
END $$;