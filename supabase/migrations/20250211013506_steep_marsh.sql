-- Add minimum_order_quantity column and update products table structure
ALTER TABLE products
ADD COLUMN IF NOT EXISTS minimum_order_quantity integer DEFAULT 1,
ADD COLUMN IF NOT EXISTS images text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_visible boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS subcategory text,
ADD COLUMN IF NOT EXISTS shelf_location text,
ADD CONSTRAINT minimum_order_quantity_check CHECK (minimum_order_quantity >= 1);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_visibility ON products(is_visible);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_subcategory ON products(subcategory);

-- Update RLS policies
DROP POLICY IF EXISTS "Anyone can view products" ON products;
CREATE POLICY "Anyone can view visible products"
  ON products FOR SELECT
  USING (is_visible = true OR seller_id = auth.uid());

DROP POLICY IF EXISTS "Sellers can manage their products" ON products;
CREATE POLICY "Sellers can manage their products"
  ON products FOR ALL
  USING (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());