-- Pro-Organizer Supabase Complete Database Schema
-- This script contains all necessary table definitions, RLS policies, triggers, and indexes
-- Version: 1.0.0 (September 6, 2025)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  email TEXT UNIQUE,
  bio TEXT,
  phone TEXT,
  
  CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT NOT NULL,
  icon TEXT,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tasks Table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT false,
  due_date TIMESTAMP WITH TIME ZONE,
  notification_time TIMESTAMP WITH TIME ZONE,
  completed_date TIMESTAMP WITH TIME ZONE,
  priority INTEGER DEFAULT 2,
  recurrence TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Notes Table
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  is_favorite BOOLEAN DEFAULT false,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Note Shares Table
CREATE TABLE IF NOT EXISTS note_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  shared_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_note_share UNIQUE (note_id, user_id)
);

-- Settings Table
CREATE TABLE IF NOT EXISTS settings (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  theme_mode TEXT DEFAULT 'system',
  sort_order TEXT DEFAULT 'due_date_asc',
  filter_option TEXT DEFAULT 'all',
  notifications_enabled BOOLEAN DEFAULT true,
  auto_backup BOOLEAN DEFAULT true,
  default_priority INTEGER DEFAULT 2,
  show_completed_tasks BOOLEAN DEFAULT true,
  date_format TEXT DEFAULT 'MM/dd/yyyy',
  time_format TEXT DEFAULT '12h',
  confirm_before_delete BOOLEAN DEFAULT true,
  reminder_minutes_before INTEGER DEFAULT 60,
  group_by_category BOOLEAN DEFAULT true,
  default_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  default_view TEXT DEFAULT 'tasks',
  language_code TEXT DEFAULT 'en',
  enable_sound_effects BOOLEAN DEFAULT true,
  enable_data_sync BOOLEAN DEFAULT true,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Backups Table
CREATE TABLE IF NOT EXISTS backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb,
  data JSONB NOT NULL
);

-- Function to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at field
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tasks_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_settings_updated_at
BEFORE UPDATE ON settings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Create function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    split_part(NEW.email, '@', 1),
    split_part(NEW.email, '@', 1)
  );
  
  -- Create default settings for new user
  INSERT INTO public.settings (user_id)
  VALUES (NEW.id);
  
  -- Create default categories for the new user
  INSERT INTO public.categories (user_id, name, color, icon, is_default)
  VALUES
    (NEW.id, 'Work', '#FF5733', 'work', true),
    (NEW.id, 'Personal', '#33A8FF', 'person', false),
    (NEW.id, 'Shopping', '#33FF57', 'shopping_cart', false),
    (NEW.id, 'Health', '#FF33A8', 'favorite', false),
    (NEW.id, 'Education', '#A833FF', 'school', false);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user sign up
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;

-- Profiles RLS Policies
CREATE POLICY "Public profiles are viewable by everyone" 
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Tasks RLS Policies
CREATE POLICY "Users can CRUD their own tasks"
  ON tasks FOR ALL USING (auth.uid() = user_id);

-- Notes RLS Policies
CREATE POLICY "Users can CRUD their own notes"
  ON notes FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view notes shared with them"
  ON notes FOR SELECT USING (
    id IN (
      SELECT note_id FROM note_shares WHERE user_id = auth.uid()
    )
  );

-- Note Shares RLS Policies
CREATE POLICY "Note owners can manage shares"
  ON note_shares FOR ALL USING (
    EXISTS (
      SELECT 1 FROM notes 
      WHERE notes.id = note_shares.note_id 
      AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their shares"
  ON note_shares FOR SELECT USING (user_id = auth.uid());

-- Categories RLS Policies
CREATE POLICY "Users can CRUD their own categories"
  ON categories FOR ALL USING (auth.uid() = user_id);

-- Settings RLS Policies
CREATE POLICY "Users can CRUD their own settings"
  ON settings FOR ALL USING (auth.uid() = user_id);

-- Backups RLS Policies
CREATE POLICY "Users can CRUD their own backups"
  ON backups FOR ALL USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS tasks_user_id_idx ON tasks(user_id);
CREATE INDEX IF NOT EXISTS tasks_category_id_idx ON tasks(category_id);
CREATE INDEX IF NOT EXISTS tasks_due_date_idx ON tasks(due_date);
CREATE INDEX IF NOT EXISTS tasks_is_completed_idx ON tasks(is_completed);

CREATE INDEX IF NOT EXISTS notes_user_id_idx ON notes(user_id);
CREATE INDEX IF NOT EXISTS notes_is_favorite_idx ON notes(is_favorite);

CREATE INDEX IF NOT EXISTS note_shares_note_id_idx ON note_shares(note_id);
CREATE INDEX IF NOT EXISTS note_shares_user_id_idx ON note_shares(user_id);

CREATE INDEX IF NOT EXISTS categories_user_id_idx ON categories(user_id);

-- Create a storage bucket for avatars if it doesn't exist
-- Note: This might need to be done from the Supabase dashboard as storage is not directly manageable via SQL
-- INSERT INTO storage.buckets (id, name) VALUES ('avatars', 'User Avatars')
-- ON CONFLICT DO NOTHING;

-- Create or update storage policies for the avatars bucket
-- These policies must be created in the Storage section of the Supabase dashboard
