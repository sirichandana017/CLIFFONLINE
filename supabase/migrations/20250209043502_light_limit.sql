/*
  # Fix User Creation Flow and Policies

  1. Changes
    - Update user creation trigger with proper metadata handling
    - Add checks for existing policies before creation
    - Ensure proper error handling in trigger function

  2. Security
    - Maintain existing RLS policies
    - Add proper policy checks
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_user_profile();

-- Create updated function
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type user_type;
BEGIN
  -- Get user type from metadata
  v_user_type := COALESCE(
    (NEW.raw_user_meta_data->>'userType')::user_type,
    'customer'::user_type
  );

  -- Create user profile
  INSERT INTO user_profiles (
    id,
    email,
    user_type,
    phone,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    v_user_type,
    (NEW.raw_user_meta_data->>'phone')::text,
    NOW(),
    NOW()
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
        COALESCE((NEW.raw_user_meta_data->>'companyName')::text, ''),
        COALESCE((NEW.raw_user_meta_data->>'industryType')::text, ''),
        COALESCE((NEW.raw_user_meta_data->>'address')::text, '')
      );
    
    WHEN 'retailer' THEN
      INSERT INTO retailers (
        id,
        business_name,
        business_type,
        business_address
      ) VALUES (
        NEW.id,
        COALESCE((NEW.raw_user_meta_data->>'businessName')::text, ''),
        COALESCE((NEW.raw_user_meta_data->>'businessType')::text, ''),
        COALESCE((NEW.raw_user_meta_data->>'businessAddress')::text, '')
      );
    
    WHEN 'customer' THEN
      INSERT INTO customers (
        id,
        default_shipping_address
      ) VALUES (
        NEW.id,
        (NEW.raw_user_meta_data->>'address')::text
      );
    
    ELSE
      RAISE EXCEPTION 'Invalid user type: %', v_user_type;
  END CASE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();

-- Update RLS policies
DO $$ 
BEGIN
  -- Enable RLS on all tables
  ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE wholesalers ENABLE ROW LEVEL SECURITY;
  ALTER TABLE retailers ENABLE ROW LEVEL SECURITY;
  ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
  DROP POLICY IF EXISTS "Wholesalers can manage their profile" ON wholesalers;
  DROP POLICY IF EXISTS "Retailers can manage their profile" ON retailers;
  DROP POLICY IF EXISTS "Customers can manage their profile" ON customers;

  -- Create new policies
  CREATE POLICY "Users can view their own profile"
    ON user_profiles FOR SELECT
    TO authenticated
    USING (id = auth.uid());

  CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid());

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
END $$;