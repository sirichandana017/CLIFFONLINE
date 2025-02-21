/*
  # Email Verification System

  1. New Tables
    - `verification_codes`
      - `id` (uuid, primary key)
      - `email` (text, not null)
      - `code` (text, not null)
      - `created_at` (timestamp with time zone)
      - `expires_at` (timestamp with time zone)
      - `used` (boolean)

  2. Security
    - Enable RLS on `verification_codes` table
    - Add policy for inserting verification codes
    - Add policy for reading verification codes
*/

CREATE TABLE IF NOT EXISTS verification_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  code text NOT NULL,
  created_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL,
  used boolean DEFAULT false
);

ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can create verification codes"
  ON verification_codes
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

CREATE POLICY "Users can read their own verification codes"
  ON verification_codes
  FOR SELECT
  TO authenticated, anon
  USING (email = current_user);