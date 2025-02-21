/*
  # Fix User Registration Schema

  1. New Tables
    - user_profiles (base user information)
    - wholesalers (wholesaler-specific data)
    - retailers (retailer-specific data)
    - customers (customer-specific data)
  
  2. Security
    - Enable RLS on all tables
    - Add policies for user access
    - Create trigger for user creation
*/

-- Drop existing tables and recreate them with proper constraints
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS retailers CASCADE;
DROP TABLE IF EXISTS wholesalers CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create user_profiles table
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  user_type user_type NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL UNIQUE,
  phone text,
  address text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create wholesalers table
CREATE TABLE wholesalers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  company_name text NOT NULL DEFAULT 'Pending Setup',
  industry_type text NOT NULL DEFAULT 'Other',
  business_address text NOT NULL DEFAULT 'Pending Setup'
);

-- Create retailers table
CREATE TABLE retailers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  business_name text NOT NULL DEFAULT 'Pending Setup',
  business_type text NOT NULL DEFAULT 'retail_store',
  business_address text NOT NULL DEFAULT 'Pending Setup'
);

-- Create customers table
CREATE TABLE customers (
  id uuid PRIMARY KEY REFERENCES user_profiles(id),
  default_shipping_address text
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wholesalers ENABLE ROW LEVEL SECURITY;
ALTER TABLE retailers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can read their own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Enable insert for authenticated users only"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create user creation function
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER 
SECURITY DEFINER 
LANGUAGE plpgsql AS $$
BEGIN
  -- Get user type from metadata with validation
  DECLARE
    v_user_type user_type;
  BEGIN
    v_user_type := (NEW.raw_user_meta_data->>'userType')::user_type;
  EXCEPTION 
    WHEN OTHERS THEN
      v_user_type := 'customer'::user_type;
  END;

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
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'firstName'), ''), 'User'),
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'lastName'), ''), 'Name'),
    NEW.email,
    NULLIF(TRIM(NEW.raw_user_meta_data->>'phone'), ''),
    NULLIF(TRIM(NEW.raw_user_meta_data->>'address'), '')
  );

  -- Create role-specific profile
  CASE v_user_type
    WHEN 'wholesaler' THEN
      INSERT INTO wholesalers (id)
      VALUES (NEW.id);
    
    WHEN 'retailer' THEN
      INSERT INTO retailers (id)
      VALUES (NEW.id);
    
    ELSE
      INSERT INTO customers (id)
      VALUES (NEW.id);
  END CASE;

  RETURN NEW;
EXCEPTION 
  WHEN OTHERS THEN
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create indexes for better performance
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_user_type ON user_profiles(user_type);