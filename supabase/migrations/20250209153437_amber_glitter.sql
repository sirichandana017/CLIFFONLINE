/*
  # Fix Verification Codes Table Structure
  
  1. Changes
    - Drop and recreate verification_codes table with correct structure
    - Add proper RLS policies
    - Add indexes for performance
*/

-- Drop existing verification_codes table
DROP TABLE IF EXISTS verification_codes CASCADE;

-- Create Verification Codes table with correct structure
CREATE TABLE verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Anyone can create verification codes"
  ON verification_codes FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

CREATE POLICY "Users can read their own verification codes"
  ON verification_codes FOR SELECT
  TO authenticated, anon
  USING (email = current_user);

-- Create index for faster lookups
CREATE INDEX idx_verification_codes_email ON verification_codes(email);
CREATE INDEX idx_verification_codes_code ON verification_codes(code);
CREATE INDEX idx_verification_codes_expires ON verification_codes(expires_at);