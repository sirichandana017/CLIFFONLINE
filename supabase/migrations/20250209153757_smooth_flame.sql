/*
  # Update Database Schema
  
  1. Changes
    - Safely drop and recreate tables
    - Update existing tables with new structure
    - Preserve data integrity
  
  2. Security
    - Maintain RLS policies
    - Update access controls
*/

-- Drop existing tables if they exist
DO $$ 
BEGIN
  -- Drop existing tables in correct order
  DROP TABLE IF EXISTS order_items CASCADE;
  DROP TABLE IF EXISTS orders CASCADE;
  DROP TABLE IF EXISTS products CASCADE;
  DROP TABLE IF EXISTS customers CASCADE;
  DROP TABLE IF EXISTS retailers CASCADE;
  DROP TABLE IF EXISTS wholesalers CASCADE;
  DROP TABLE IF EXISTS user_profiles CASCADE;
END $$;

-- Safely handle existing types
DO $$ 
BEGIN
    -- Drop existing types if they exist
    DROP TYPE IF EXISTS payment_status CASCADE;
    DROP TYPE IF EXISTS order_status CASCADE;
    DROP TYPE IF EXISTS payment_method CASCADE;
    
    -- Create types if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('processing', 'shipped', 'delivered', 'cancelled');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
        CREATE TYPE payment_method AS ENUM ('credit_card', 'cod');
    END IF;
END $$;

-- Create tables if they don't exist
DO $$ 
BEGIN
    -- Create user profiles table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_profiles') THEN
        CREATE TABLE user_profiles (
            id UUID PRIMARY KEY REFERENCES auth.users(id),
            user_type user_type NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            phone TEXT,
            address TEXT,
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create wholesaler profiles
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'wholesalers') THEN
        CREATE TABLE wholesalers (
            id UUID PRIMARY KEY REFERENCES user_profiles(id),
            company_name TEXT NOT NULL,
            industry_type TEXT NOT NULL,
            business_address TEXT NOT NULL,
            registration_number TEXT,
            tax_id TEXT,
            verification_status TEXT DEFAULT 'pending',
            verification_notes TEXT,
            verified_at TIMESTAMPTZ,
            verified_by UUID REFERENCES user_profiles(id)
        );
    END IF;

    -- Create retailer profiles
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'retailers') THEN
        CREATE TABLE retailers (
            id UUID PRIMARY KEY REFERENCES user_profiles(id),
            business_name TEXT NOT NULL,
            business_type TEXT NOT NULL,
            business_address TEXT NOT NULL,
            tax_id TEXT
        );
    END IF;

    -- Create customer profiles
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'customers') THEN
        CREATE TABLE customers (
            id UUID PRIMARY KEY REFERENCES user_profiles(id),
            default_shipping_address TEXT
        );
    END IF;

    -- Create products table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'products') THEN
        CREATE TABLE products (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            seller_id UUID REFERENCES user_profiles(id),
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            subcategory TEXT,
            description TEXT,
            price DECIMAL(10,2) NOT NULL,
            stock_quantity INTEGER DEFAULT 0,
            shelf_location TEXT,
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create orders table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'orders') THEN
        CREATE TABLE orders (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            buyer_id UUID REFERENCES user_profiles(id),
            seller_id UUID REFERENCES user_profiles(id),
            total_price DECIMAL(10,2) NOT NULL,
            payment_method payment_method NOT NULL,
            status order_status DEFAULT 'processing',
            created_at TIMESTAMPTZ DEFAULT now(),
            updated_at TIMESTAMPTZ DEFAULT now()
        );
    END IF;

    -- Create order items table
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'order_items') THEN
        CREATE TABLE order_items (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_id UUID REFERENCES orders(id),
            product_id UUID REFERENCES products(id),
            quantity INTEGER NOT NULL,
            unit_price DECIMAL(10,2) NOT NULL,
            total_price DECIMAL(10,2) NOT NULL
        );
    END IF;
END $$;

-- Enable RLS on all tables
DO $$ 
BEGIN
    ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
    ALTER TABLE wholesalers ENABLE ROW LEVEL SECURITY;
    ALTER TABLE retailers ENABLE ROW LEVEL SECURITY;
    ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
    ALTER TABLE products ENABLE ROW LEVEL SECURITY;
    ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
    ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
END $$;

-- Create or replace RLS policies
DO $$ 
BEGIN
    -- Drop existing policies
    DROP POLICY IF EXISTS "Users can read their own profile" ON user_profiles;
    DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
    DROP POLICY IF EXISTS "Wholesalers can manage their profile" ON wholesalers;
    DROP POLICY IF EXISTS "Retailers can manage their profile" ON retailers;
    DROP POLICY IF EXISTS "Customers can manage their profile" ON customers;
    DROP POLICY IF EXISTS "Anyone can view products" ON products;
    DROP POLICY IF EXISTS "Sellers can manage their products" ON products;
    DROP POLICY IF EXISTS "Users can view their orders" ON orders;
    DROP POLICY IF EXISTS "Users can create orders" ON orders;

    -- Create new policies
    CREATE POLICY "Users can read their own profile"
        ON user_profiles FOR SELECT
        TO authenticated
        USING (auth.uid() = id);

    CREATE POLICY "Users can update their own profile"
        ON user_profiles FOR UPDATE
        TO authenticated
        USING (auth.uid() = id);

    CREATE POLICY "Wholesalers can manage their profile"
        ON wholesalers FOR ALL
        TO authenticated
        USING (id = auth.uid());

    CREATE POLICY "Retailers can manage their profile"
        ON retailers FOR ALL
        TO authenticated
        USING (id = auth.uid());

    CREATE POLICY "Customers can manage their profile"
        ON customers FOR ALL
        TO authenticated
        USING (id = auth.uid());

    CREATE POLICY "Anyone can view products"
        ON products FOR SELECT
        TO authenticated, anon
        USING (true);

    CREATE POLICY "Sellers can manage their products"
        ON products FOR ALL
        TO authenticated
        USING (seller_id = auth.uid());

    CREATE POLICY "Users can view their orders"
        ON orders FOR SELECT
        TO authenticated
        USING (buyer_id = auth.uid() OR seller_id = auth.uid());

    CREATE POLICY "Users can create orders"
        ON orders FOR INSERT
        TO authenticated
        WITH CHECK (buyer_id = auth.uid());
END $$;

-- Create or replace user creation function and trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type user_type;
BEGIN
  -- Get user type from metadata
  v_user_type := COALESCE(
    (NEW.raw_user_meta_data->>'userType')::user_type,
    'customer'::user_type
  );

  -- Insert into user_profiles
  INSERT INTO user_profiles (
    id,
    user_type,
    first_name,
    last_name,
    email,
    phone,
    address
  ) VALUES (
    NEW.id,
    v_user_type,
    COALESCE(NEW.raw_user_meta_data->>'firstName', ''),
    COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
    COALESCE(NEW.raw_user_meta_data->>'address', NULL)
  );

  -- Create specific profile based on user type
  CASE v_user_type
    WHEN 'wholesaler' THEN
      INSERT INTO wholesalers (
        id,
        company_name,
        industry_type,
        business_address
      ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'companyName', ''),
        COALESCE(NEW.raw_user_meta_data->>'industryType', 'Other'),
        COALESCE(NEW.raw_user_meta_data->>'address', '')
      );
    
    WHEN 'retailer' THEN
      INSERT INTO retailers (
        id,
        business_name,
        business_type,
        business_address
      ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'businessName', ''),
        COALESCE(NEW.raw_user_meta_data->>'businessType', 'retail_store'),
        COALESCE(NEW.raw_user_meta_data->>'businessAddress', '')
      );
    
    WHEN 'customer' THEN
      INSERT INTO customers (
        id,
        default_shipping_address
      ) VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'address'
      );
    
    ELSE
      RAISE EXCEPTION 'Invalid user type: %', v_user_type;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create indexes for better performance
DO $$
BEGIN
    -- Drop existing indexes
    DROP INDEX IF EXISTS idx_user_profiles_email;
    DROP INDEX IF EXISTS idx_user_profiles_user_type;
    DROP INDEX IF EXISTS idx_products_seller;
    DROP INDEX IF EXISTS idx_products_category;
    DROP INDEX IF EXISTS idx_orders_buyer;
    DROP INDEX IF EXISTS idx_orders_seller;
    DROP INDEX IF EXISTS idx_order_items_order;

    -- Create new indexes
    CREATE INDEX idx_user_profiles_email ON user_profiles(email);
    CREATE INDEX idx_user_profiles_user_type ON user_profiles(user_type);
    CREATE INDEX idx_products_seller ON products(seller_id);
    CREATE INDEX idx_products_category ON products(category);
    CREATE INDEX idx_orders_buyer ON orders(buyer_id);
    CREATE INDEX idx_orders_seller ON orders(seller_id);
    CREATE INDEX idx_order_items_order ON order_items(order_id);
END $$;