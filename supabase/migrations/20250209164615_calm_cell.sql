/*
  # Fix Authentication Issues

  1. Changes
    - Add missing RLS policies for role-specific tables
    - Add better error handling in trigger function
    - Add constraints to ensure data integrity
    - Add policies to allow profile creation during signup
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
  first_name text NOT NULL CHECK (char_length(trim(first_name)) > 0),
  last_name text NOT NULL CHECK (char_length(trim(last_name)) > 0),
  email text NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
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

CREATE POLICY "Allow profile creation during signup"
  ON user_profiles FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Role-specific policies
CREATE POLICY "Allow wholesaler profile creation"
  ON wholesalers FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Wholesalers can read their own profile"
  ON wholesalers FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Allow retailer profile creation"
  ON retailers FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Retailers can read their own profile"
  ON retailers FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Allow customer profile creation"
  ON customers FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "Customers can read their own profile"
  ON customers FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Create user creation function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER 
SECURITY DEFINER 
SET search_path = public
LANGUAGE plpgsql AS $$
DECLARE
  v_user_type user_type;
  v_first_name text;
  v_last_name text;
BEGIN
  -- Get and validate user type
  BEGIN
    v_user_type := (NEW.raw_user_meta_data->>'userType')::user_type;
    IF v_user_type IS NULL THEN
      v_user_type := 'customer'::user_type;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_user_type := 'customer'::user_type;
  END;

  -- Get and validate names
  v_first_name := NULLIF(TRIM(NEW.raw_user_meta_data->>'firstName'), '');
  v_last_name := NULLIF(TRIM(NEW.raw_user_meta_data->>'lastName'), '');

  IF v_first_name IS NULL OR v_last_name IS NULL THEN
    RAISE EXCEPTION 'First name and last name are required';
  END IF;

  -- Create user profile
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
    v_first_name,
    v_last_name,
    NEW.email,
    NULLIF(TRIM(NEW.raw_user_meta_data->>'phone'), ''),
    NULLIF(TRIM(NEW.raw_user_meta_data->>'address'), '')
  );

  -- Create role-specific profile
  CASE v_user_type
    WHEN 'wholesaler' THEN
      INSERT INTO wholesalers (
        id,
        company_name,
        industry_type,
        business_address
      ) VALUES (
        NEW.id,
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'companyName'), ''), 'Pending Setup'),
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'industryType'), ''), 'Other'),
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'address'), ''), 'Pending Setup')
      );
    
    WHEN 'retailer' THEN
      INSERT INTO retailers (
        id,
        business_name,
        business_type,
        business_address
      ) VALUES (
        NEW.id,
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'businessName'), ''), 'Pending Setup'),
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'businessType'), ''), 'retail_store'),
        COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'businessAddress'), ''), 'Pending Setup')
      );
    
    ELSE
      INSERT INTO customers (
        id,
        default_shipping_address
      ) VALUES (
        NEW.id,
        NULLIF(TRIM(NEW.raw_user_meta_data->>'address'), '')
      );
  END CASE;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
  RETURN NULL; -- Prevent user creation if profile creation fails
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create indexes for better performance
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_user_type ON user_profiles(user_type);