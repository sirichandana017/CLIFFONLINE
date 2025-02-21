-- Drop existing foreign key if it exists
ALTER TABLE IF EXISTS products
DROP CONSTRAINT IF EXISTS products_seller_id_fkey;

-- Add proper foreign key constraint
ALTER TABLE products
ADD CONSTRAINT products_seller_id_fkey
FOREIGN KEY (seller_id)
REFERENCES user_profiles(id)
ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_products_seller_id
ON products(seller_id);

-- Update RLS policies
DROP POLICY IF EXISTS "Anyone can view visible products" ON products;
CREATE POLICY "Anyone can view visible products"
  ON products FOR SELECT
  USING (is_visible = true OR seller_id = auth.uid());

DROP POLICY IF EXISTS "Sellers can manage their products" ON products;
CREATE POLICY "Sellers can manage their products"
  ON products FOR ALL
  USING (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());