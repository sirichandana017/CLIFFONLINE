-- Add industry_type to retailers table
ALTER TABLE retailers 
ADD COLUMN IF NOT EXISTS industry_type text NOT NULL DEFAULT 'Other';

-- Create index for better industry matching
CREATE INDEX IF NOT EXISTS idx_retailers_industry_type 
ON retailers(industry_type);

-- Update RLS policies
DROP POLICY IF EXISTS "Retailers can manage their profile" ON retailers;
CREATE POLICY "Retailers can manage their profile"
  ON retailers FOR ALL
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());