/*
  # Fix Advertisements Table

  1. Changes
    - Drop and recreate advertisements table with proper foreign key relationships
    - Add RLS policies for advertisements
    - Add indexes for better performance

  2. Security
    - Enable RLS
    - Add policies for CRUD operations
*/

-- Drop existing advertisements table if it exists
DROP TABLE IF EXISTS advertisements;

-- Create advertisements table with proper relationships
CREATE TABLE advertisements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES user_profiles(id) NOT NULL,
  product_id uuid REFERENCES products(id) NOT NULL,
  discount decimal(5,2) NOT NULL CHECK (discount > 0 AND discount <= 100),
  promotion_details text,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL CHECK (end_date > start_date),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- Enable RLS
ALTER TABLE advertisements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view advertisements in their industry"
  ON advertisements FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      JOIN wholesalers w ON w.id = up.id
      WHERE up.id = advertisements.user_id
      AND w.industry_type = (
        SELECT w2.industry_type 
        FROM user_profiles up2
        JOIN wholesalers w2 ON w2.id = up2.id
        WHERE up2.id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can manage their own advertisements"
  ON advertisements FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create indexes
CREATE INDEX idx_advertisements_user ON advertisements(user_id);
CREATE INDEX idx_advertisements_product ON advertisements(product_id);
CREATE INDEX idx_advertisements_dates ON advertisements(start_date, end_date);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_advertisement_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_advertisement_timestamp
  BEFORE UPDATE ON advertisements
  FOR EACH ROW
  EXECUTE FUNCTION update_advertisement_timestamp();