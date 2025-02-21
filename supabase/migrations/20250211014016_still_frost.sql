-- Add product_code column for custom product identifiers
ALTER TABLE products
ADD COLUMN IF NOT EXISTS product_code text;

-- Create index for product code lookups
CREATE INDEX IF NOT EXISTS idx_products_code ON products(product_code);

-- Add unique constraint if needed (optional, commented out by default)
-- ALTER TABLE products ADD CONSTRAINT unique_product_code UNIQUE (product_code, seller_id);