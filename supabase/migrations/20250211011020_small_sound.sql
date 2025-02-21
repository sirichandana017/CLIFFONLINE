/*
  # Add Images to Products Table

  1. Changes
    - Add images array column to products table
    - Add is_visible column for product visibility control
*/

-- Add images and is_visible columns to products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS images text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_visible boolean DEFAULT false;

-- Create index for visibility filtering
CREATE INDEX IF NOT EXISTS idx_products_visibility ON products(is_visible);