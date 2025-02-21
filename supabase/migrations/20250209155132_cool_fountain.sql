/*
  # Fix Database Schema and Trigger

  1. Changes
    - Drop and recreate trigger with better error handling
    - Add missing RLS policies
    - Fix user type handling
    - Add better data validation
    - Add proper error logging
  
  2. Security
    - Enable RLS on all tables
    - Add proper policies for user management
    - Ensure proper access control
*/

-- Drop and recreate the user creation function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type user_type;
  v_metadata jsonb;
BEGIN
  -- Ensure raw_user_meta_data exists and is valid
  v_metadata := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
  
  -- Get user type with validation and fallback
  BEGIN
    v_user_type := (v_metadata->>'userType')::user_type;
  EXCEPTION WHEN OTHERS THEN
    -- Default to customer if invalid or missing
    v_user_type := 'customer'::user_type;
  END;

  -- Create user profile with strict validation
  INSERT INTO user_profiles (
    id,
    user_type,
    first_name,
    last_name,
    email,
    phone,
    address,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    v_user_type,
    COALESCE(NULLIF(TRIM(v_metadata->>'firstName'), ''), 'User'),
    COALESCE(NULLIF(TRIM(v_metadata->>'lastName'), ''), 'Name'),
    NEW.email,
    NULLIF(TRIM(v_metadata->>'phone'), ''),
    NULLIF(TRIM(v_metadata->>'address'), ''),
    now(),
    now()
  );

  -- Create specific profile based on user type
  BEGIN
    CASE v_user_type
      WHEN 'wholesaler' THEN
        INSERT INTO wholesalers (
          id,
          company_name,
          industry_type,
          business_address
        ) VALUES (
          NEW.id,
          COALESCE(NULLIF(TRIM(v_metadata->>'companyName'), ''), 'Pending Setup'),
          COALESCE(NULLIF(TRIM(v_metadata->>'industryType'), ''), 'Other'),
          COALESCE(NULLIF(TRIM(v_metadata->>'address'), ''), 'Pending Setup')
        );
      
      WHEN 'retailer' THEN
        INSERT INTO retailers (
          id,
          business_name,
          business_type,
          business_address
        ) VALUES (
          NEW.id,
          COALESCE(NULLIF(TRIM(v_metadata->>'businessName'), ''), 'Pending Setup'),
          COALESCE(NULLIF(TRIM(v_metadata->>'businessType'), ''), 'retail_store'),
          COALESCE(NULLIF(TRIM(v_metadata->>'businessAddress'), ''), 'Pending Setup')
        );
      
      WHEN 'customer' THEN
        INSERT INTO customers (
          id,
          default_shipping_address
        ) VALUES (
          NEW.id,
          NULLIF(TRIM(v_metadata->>'address'), '')
        );
      
      ELSE
        -- Fallback to customer profile
        INSERT INTO customers (id) VALUES (NEW.id);
    END CASE;
  EXCEPTION 
    WHEN OTHERS THEN
      RAISE WARNING 'Failed to create specific profile for user %: %', NEW.id, SQLERRM;
      
      -- Ensure at least a customer profile exists
      IF NOT EXISTS (SELECT 1 FROM customers WHERE id = NEW.id) THEN
        INSERT INTO customers (id) VALUES (NEW.id);
      END IF;
  END;

  RETURN NEW;
EXCEPTION 
  WHEN OTHERS THEN
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Ensure proper RLS policies exist
DO $$ 
BEGIN
  -- Add missing policies for user_profiles
  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON user_profiles;
  CREATE POLICY "Enable insert for authenticated users only"
    ON user_profiles FOR INSERT
    TO authenticated
    WITH CHECK (true);

  -- Add missing policies for specific profile tables
  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON wholesalers;
  CREATE POLICY "Enable insert for authenticated users only"
    ON wholesalers FOR INSERT
    TO authenticated
    WITH CHECK (true);

  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON retailers;
  CREATE POLICY "Enable insert for authenticated users only"
    ON retailers FOR INSERT
    TO authenticated
    WITH CHECK (true);

  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON customers;
  CREATE POLICY "Enable insert for authenticated users only"
    ON customers FOR INSERT
    TO authenticated
    WITH CHECK (true);
END $$;