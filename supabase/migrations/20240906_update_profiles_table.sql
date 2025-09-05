-- Update profiles table to add bio and phone fields if they don't exist

DO $$
BEGIN
    -- Check if bio column exists, if not add it
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'bio'
    ) THEN
        ALTER TABLE profiles ADD COLUMN bio TEXT;
    END IF;
    
    -- Check if phone column exists, if not add it
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'phone'
    ) THEN
        ALTER TABLE profiles ADD COLUMN phone TEXT;
    END IF;
    
    -- Check if created_at column exists, if not add it
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
    END IF;
    
END$$;
