/*
  # E-commerce Platform Schema

  1. New Tables
    - `user_profiles`
      - Stores additional user information for all user types
      - Links to Supabase auth.users
    - `wholesalers`
      - Stores wholesaler-specific information
      - Requires admin approval
    - `retailers`
      - Stores retailer-specific information
    - `customers`
      - Stores everyday shopper information
    - `categories`
      - Product categories hierarchy
    - `products`
      - Product listings from wholesalers
    - `inventory`
      - Stock management
    - `orders`
      - Order tracking
    
  2. Security
    - RLS policies for each table
    - Role-based access control
*/

-- Enum for user types
CREATE TYPE user_type AS ENUM ('wholesaler', 'retailer', 'customer', 'admin');

-- Enum for account status
CREATE TYPE account_status AS ENUM ('pending', 'approved', 'rejected');

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  user_type user_type NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Wholesaler profiles
CREATE TABLE IF NOT EXISTS wholesalers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  company_name text NOT NULL,
  industry_type text NOT NULL,
  business_address text NOT NULL,
  registration_number text,
  tax_id text,
  verification_status account_status DEFAULT 'pending',
  verification_notes text,
  verified_at timestamptz,
  verified_by uuid REFERENCES user_profiles(id)
);

-- Retailer profiles
CREATE TABLE IF NOT EXISTS retailers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  business_name text NOT NULL,
  business_type text NOT NULL,
  business_address text NOT NULL,
  tax_id text
);

-- Customer profiles
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  default_shipping_address text
);

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  parent_id uuid REFERENCES categories(id),
  created_by uuid REFERENCES user_profiles(id),
  created_at timestamptz DEFAULT now(),
  UNIQUE (name, parent_id)
);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES user_profiles(id),
  category_id uuid NOT NULL REFERENCES categories(id),
  name text NOT NULL,
  description text,
  base_price decimal(10,2) NOT NULL,
  minimum_order_quantity integer DEFAULT 1,
  images text[],
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Inventory
CREATE TABLE IF NOT EXISTS inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id),
  quantity integer NOT NULL DEFAULT 0,
  shelf_location text,
  last_restock_date timestamptz DEFAULT now(),
  UNIQUE (product_id)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL REFERENCES user_profiles(id),
  seller_id uuid NOT NULL REFERENCES user_profiles(id),
  status text NOT NULL DEFAULT 'pending',
  total_amount decimal(10,2) NOT NULL,
  payment_method text NOT NULL,
  shipping_address text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Order items
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id),
  product_id uuid NOT NULL REFERENCES products(id),
  quantity integer NOT NULL,
  unit_price decimal(10,2) NOT NULL,
  total_price decimal(10,2) NOT NULL
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wholesalers ENABLE ROW LEVEL SECURITY;
ALTER TABLE retailers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can read their own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON user_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_type = 'admin'
    )
  );

-- Wholesaler policies
CREATE POLICY "Wholesalers can read their own profile"
  ON wholesalers FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can manage wholesaler profiles"
  ON wholesalers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_type = 'admin'
    )
  );

-- Product policies
CREATE POLICY "Anyone can view active products"
  ON products FOR SELECT
  USING (is_active = true);

CREATE POLICY "Sellers can manage their products"
  ON products FOR ALL
  USING (seller_id = auth.uid());

-- Inventory policies
CREATE POLICY "Sellers can manage their inventory"
  ON inventory FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM products
      WHERE products.id = inventory.product_id
      AND products.seller_id = auth.uid()
    )
  );

-- Order policies
CREATE POLICY "Users can view their orders"
  ON orders FOR SELECT
  USING (buyer_id = auth.uid() OR seller_id = auth.uid());

CREATE POLICY "Buyers can create orders"
  ON orders FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

-- Functions for user management
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_profiles (id, email, user_type)
  VALUES (NEW.id, NEW.email, 'customer');
  
  INSERT INTO customers (id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();