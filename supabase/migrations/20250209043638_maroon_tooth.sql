/*
  # Fix User Creation Trigger

  1. Changes
    - Improve error handling in trigger function
    - Add proper NULL handling for metadata fields
    - Ensure all required fields have default values
    - Fix transaction handling

  2. Security
    - Maintain existing RLS policies
*/

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_user_profile();

-- Create updated function with better error handling
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user profile first
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
    COALESCE((NEW.raw_user_meta_data->>'userType')::user_type, 'customer'::user_type),
    NULLIF(TRIM(COALESCE((NEW.raw_user_meta_data->>'phone')::text, '')), ''),
    NOW(),
    NOW()
  );

  -- Get user type after insertion
  DECLARE
    v_user_type user_type;
  BEGIN
    SELECT user_type INTO v_user_type FROM user_profiles WHERE id = NEW.id;

    CASE v_user_type
      WHEN 'wholesaler' THEN
        INSERT INTO wholesalers (
          id,
          company_name,
          industry_type,
          business_address
        ) VALUES (
          NEW.id,
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'companyName')::text), ''), 'Pending'),
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'industryType')::text), ''), 'Other'),
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'address')::text), ''), 'Pending')
        );
      
      WHEN 'retailer' THEN
        INSERT INTO retailers (
          id,
          business_name,
          business_type,
          business_address
        ) VALUES (
          NEW.id,
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'businessName')::text), ''), 'Pending'),
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'businessType')::text), ''), 'retail_store'),
          COALESCE(NULLIF(TRIM((NEW.raw_user_meta_data->>'businessAddress')::text), ''), 'Pending')
        );
      
      WHEN 'customer' THEN
        INSERT INTO customers (
          id,
          default_shipping_address
        ) VALUES (
          NEW.id,
          NULLIF(TRIM(COALESCE((NEW.raw_user_meta_data->>'address')::text, '')), '')
        );
      
      ELSE
        -- Default to customer if type is invalid
        INSERT INTO customers (id) VALUES (NEW.id);
    END CASE;

    EXCEPTION
      WHEN OTHERS THEN
        -- If specific profile creation fails, still keep the user_profile
        RAISE WARNING 'Failed to create specific profile for user %: %', NEW.id, SQLERRM;
    END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_user_profile();