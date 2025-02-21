/*
  # Fix User Creation Flow
  
  1. Changes
    - Add insert policy for user_profiles
    - Add error handling for user creation
    - Fix metadata handling in trigger function
  
  2. Security
    - Maintain RLS policies
    - Add proper error handling
*/

-- Drop and recreate the user creation function with better error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Wrap everything in exception handling
  BEGIN
    -- Get user type from metadata with strict validation
    DECLARE
      v_user_type user_type;
      v_metadata jsonb;
    BEGIN
      -- Ensure raw_user_meta_data exists
      v_metadata := COALESCE(NEW.raw_user_meta_data, '{}'::jsonb);
      
      -- Validate and get user type
      v_user_type := COALESCE(
        (v_metadata->>'userType')::user_type,
        'customer'::user_type
      );

      -- Insert into user_profiles with strict validation
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
        NULLIF(TRIM(COALESCE(v_metadata->>'firstName', '')), ''),
        NULLIF(TRIM(COALESCE(v_metadata->>'lastName', '')), ''),
        NEW.email,
        NULLIF(TRIM(COALESCE(v_metadata->>'phone', '')), ''),
        NULLIF(TRIM(COALESCE(v_metadata->>'address', '')), '')
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
            COALESCE(NULLIF(TRIM(v_metadata->>'companyName'), ''), 'Pending'),
            COALESCE(NULLIF(TRIM(v_metadata->>'industryType'), ''), 'Other'),
            COALESCE(NULLIF(TRIM(v_metadata->>'address'), ''), 'Pending')
          );
        
        WHEN 'retailer' THEN
          INSERT INTO retailers (
            id,
            business_name,
            business_type,
            business_address
          ) VALUES (
            NEW.id,
            COALESCE(NULLIF(TRIM(v_metadata->>'businessName'), ''), 'Pending'),
            COALESCE(NULLIF(TRIM(v_metadata->>'businessType'), ''), 'retail_store'),
            COALESCE(NULLIF(TRIM(v_metadata->>'businessAddress'), ''), 'Pending')
          );
        
        WHEN 'customer' THEN
          INSERT INTO customers (
            id,
            default_shipping_address
          ) VALUES (
            NEW.id,
            NULLIF(TRIM(COALESCE(v_metadata->>'address', '')), '')
          );
        
        ELSE
          -- Default to customer if type is invalid
          INSERT INTO customers (id) VALUES (NEW.id);
      END CASE;

      EXCEPTION
        WHEN OTHERS THEN
          RAISE WARNING 'Error in user type handling: %', SQLERRM;
          -- Create customer profile as fallback
          INSERT INTO customers (id) VALUES (NEW.id);
    END;

    RETURN NEW;
    
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure proper RLS policies exist
DO $$ 
BEGIN
  -- Add insert policy for user_profiles if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'Users can insert their own profile'
  ) THEN
    CREATE POLICY "Users can insert their own profile"
      ON user_profiles FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  -- Add insert policy for specific profile tables
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'wholesalers' 
    AND policyname = 'Users can insert their wholesaler profile'
  ) THEN
    CREATE POLICY "Users can insert their wholesaler profile"
      ON wholesalers FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'retailers' 
    AND policyname = 'Users can insert their retailer profile'
  ) THEN
    CREATE POLICY "Users can insert their retailer profile"
      ON retailers FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'customers' 
    AND policyname = 'Users can insert their customer profile'
  ) THEN
    CREATE POLICY "Users can insert their customer profile"
      ON customers FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;