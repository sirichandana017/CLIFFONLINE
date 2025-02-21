/*
  # Complete Database Rebuild
  
  1. New Tables
    - users (main user table with role-based access)
    - admins (platform administrators)
    - verification_codes (email verification)
    - products (product catalog)
    - orders (transaction records)
    - order_items (order details)
    - advertisements (promotional content)
    - payments (payment transactions)
    - inventory_updates (stock management)
    - data_visualization (analytics)

  2. Security
    - Role-based access control
    - Row Level Security policies
    - Secure payment handling
    
  3. Changes
    - Complete schema rebuild
    - Enhanced security model
    - Improved data relationships
*/

-- Drop existing tables if they exist
DROP TABLE IF EXISTS data_visualization CASCADE;
DROP TABLE IF EXISTS inventory_updates CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS advertisements CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS verification_codes CASCADE;
DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create ENUM types
CREATE TYPE user_role AS ENUM ('wholesaler', 'retailer', 'shopper', 'admin');
CREATE TYPE payment_status AS ENUM ('Pending', 'Completed', 'Failed');
CREATE TYPE order_status AS ENUM ('Processing', 'Shipped', 'Delivered', 'Cancelled');
CREATE TYPE payment_method AS ENUM ('Credit Card', 'COD');
CREATE TYPE inventory_change AS ENUM ('Added', 'Removed', 'Updated');

-- Create Users table
CREATE TABLE users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone_number VARCHAR(15) UNIQUE NOT NULL,
  address TEXT,
  role user_role NOT NULL,
  industry_type VARCHAR(255),
  company_name VARCHAR(255),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Admins table
CREATE TABLE admins (
  admin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Verification Codes table
CREATE TABLE verification_codes (
  code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  verification_code VARCHAR(6) NOT NULL,
  expiration_time TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Products table
CREATE TABLE products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(255) NOT NULL,
  subcategory VARCHAR(255),
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INTEGER DEFAULT 0,
  shelf_location VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Orders table
CREATE TABLE orders (
  order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  seller_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  total_price DECIMAL(10,2) NOT NULL,
  payment_method payment_method NOT NULL,
  order_status order_status DEFAULT 'Processing',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Order Items table
CREATE TABLE order_items (
  order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Create Advertisements table
CREATE TABLE advertisements (
  ad_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
  discount DECIMAL(5,2),
  promotion_details TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Payments table
CREATE TABLE payments (
  payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  payment_status payment_status DEFAULT 'Pending',
  transaction_id VARCHAR(255) UNIQUE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Inventory Updates table
CREATE TABLE inventory_updates (
  update_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(product_id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  change_type inventory_change NOT NULL,
  change_amount INTEGER NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create Data Visualization table
CREATE TABLE data_visualization (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
  total_sales DECIMAL(10,2) DEFAULT 0,
  total_profit DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE advertisements ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_visualization ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies

-- Users policies
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid() = user_id);

-- Products policies
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  USING (true);

CREATE POLICY "Sellers can manage their products"
  ON products FOR ALL
  USING (auth.uid() = user_id);

-- Orders policies
CREATE POLICY "Users can view their orders"
  ON orders FOR SELECT
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Users can create orders"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

-- Advertisements policies
CREATE POLICY "Anyone can view advertisements"
  ON advertisements FOR SELECT
  USING (true);

CREATE POLICY "Users can manage their advertisements"
  ON advertisements FOR ALL
  USING (auth.uid() = user_id);

-- Payments policies
CREATE POLICY "Users can view their payments"
  ON payments FOR SELECT
  USING (auth.uid() = user_id);

-- Inventory policies
CREATE POLICY "Users can manage their inventory"
  ON inventory_updates FOR ALL
  USING (auth.uid() = user_id);

-- Analytics policies
CREATE POLICY "Users can view their analytics"
  ON data_visualization FOR SELECT
  USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_buyer ON orders(buyer_id);
CREATE INDEX idx_orders_seller ON orders(seller_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_inventory_product ON inventory_updates(product_id);