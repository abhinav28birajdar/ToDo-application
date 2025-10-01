-- ==================================================
-- Pro-Organizer Todo App - Complete Database Schema
-- ==================================================
-- 
-- This file contains the complete database setup for the Pro-Organizer Todo App
-- Run this in your Supabase SQL Editor to set up all tables and security policies
--
-- IMPORTANT: Run this entire script in your Supabase SQL Editor
-- Make sure to enable the required extensions first
--

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing policies and tables if they exist (for clean reinstall)
-- Note: We drop policies first, then triggers, then tables, then functions

-- Drop triggers first (since they depend on tables and functions)
DO $$ 
BEGIN
    -- Drop auth trigger (auth.users always exists)
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    
    -- Drop table triggers only if tables exist
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notes') THEN
        DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'settings') THEN
        DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'categories') THEN
        DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'profiles') THEN
        DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
    END IF;
END $$;

-- Drop policies (only if tables exist)
DO $$ 
BEGIN
    -- Drop policies for notes
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notes') THEN
        DROP POLICY IF EXISTS "Users can CRUD their own notes" ON notes;
    END IF;
    
    -- Drop policies for settings
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'settings') THEN
        DROP POLICY IF EXISTS "Users can delete their own settings" ON settings;
        DROP POLICY IF EXISTS "Users can update their own settings" ON settings;
        DROP POLICY IF EXISTS "Users can insert their own settings" ON settings;
        DROP POLICY IF EXISTS "Users can view their own settings" ON settings;
    END IF;
    
    -- Drop policies for tasks
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'tasks') THEN
        DROP POLICY IF EXISTS "Users can delete their own tasks" ON tasks;
        DROP POLICY IF EXISTS "Users can update their own tasks" ON tasks;
        DROP POLICY IF EXISTS "Users can create their own tasks" ON tasks;
        DROP POLICY IF EXISTS "Users can view their own tasks" ON tasks;
    END IF;
    
    -- Drop policies for categories
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'categories') THEN
        DROP POLICY IF EXISTS "Users can delete their own categories" ON categories;
        DROP POLICY IF EXISTS "Users can update their own categories" ON categories;
        DROP POLICY IF EXISTS "Users can create their own categories" ON categories;
        DROP POLICY IF EXISTS "Users can view their own categories" ON categories;
    END IF;
    
    -- Drop policies for profiles
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'profiles') THEN
        DROP POLICY IF EXISTS "Users can delete their own profile" ON profiles;
        DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
        DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
        DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
    END IF;
END $$;

-- Drop tables in correct order (tables with foreign keys first)
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS create_default_settings(UUID) CASCADE;
DROP FUNCTION IF EXISTS create_default_categories(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ===========================
-- PROFILES TABLE
-- ===========================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  email TEXT,
  bio TEXT,
  phone TEXT,
  is_verified BOOLEAN DEFAULT false NOT NULL,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ===========================
-- CATEGORIES TABLE
-- ===========================
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL CHECK (length(name) > 0),
  description TEXT DEFAULT '' NOT NULL,
  color TEXT NOT NULL DEFAULT '#8B5CF6',
  icon TEXT DEFAULT 'work' NOT NULL,
  is_default BOOLEAN DEFAULT false NOT NULL,
  sort_order INTEGER DEFAULT 0 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  
  -- Constraints
  UNIQUE(user_id, name)
);

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- ===========================
-- TASKS TABLE
-- ===========================
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL CHECK (length(title) > 0),
  description TEXT DEFAULT '' NOT NULL,
  is_completed BOOLEAN DEFAULT false NOT NULL,
  priority INTEGER DEFAULT 2 CHECK (priority >= 1 AND priority <= 5) NOT NULL,
  
  -- Dates and timing
  due_date TIMESTAMP WITH TIME ZONE,
  notification_time TIMESTAMP WITH TIME ZONE,
  completed_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  
  -- Relationships
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  
  -- Additional fields
  tags TEXT[] DEFAULT '{}' NOT NULL,
  has_notification BOOLEAN DEFAULT false NOT NULL,
  recurrence TEXT CHECK (recurrence IN ('daily', 'weekly', 'monthly', 'yearly')),
  notes TEXT DEFAULT '' NOT NULL,
  attachment_urls TEXT[] DEFAULT '{}' NOT NULL,
  estimated_duration INTEGER DEFAULT 0 NOT NULL,
  actual_duration INTEGER DEFAULT 0 NOT NULL
);

-- Enable Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- ===========================
-- SETTINGS TABLE
-- ===========================
CREATE TABLE settings (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- Theme and appearance
  theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')) NOT NULL,
  primary_color TEXT DEFAULT '#8B5CF6' NOT NULL,
  font_size TEXT DEFAULT 'medium' CHECK (font_size IN ('small', 'medium', 'large')) NOT NULL,
  
  -- Notifications
  notifications_enabled BOOLEAN DEFAULT true NOT NULL,
  reminder_minutes_before INTEGER DEFAULT 60 NOT NULL,
  notification_sound BOOLEAN DEFAULT true NOT NULL,
  vibration_enabled BOOLEAN DEFAULT true NOT NULL,
  
  -- Task management
  sort_order TEXT DEFAULT 'creation_date_desc' NOT NULL,
  filter_option TEXT DEFAULT 'all' NOT NULL,
  default_priority INTEGER DEFAULT 2 CHECK (default_priority >= 1 AND default_priority <= 5) NOT NULL,
  show_completed_tasks BOOLEAN DEFAULT true NOT NULL,
  group_by_category BOOLEAN DEFAULT true NOT NULL,
  default_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  
  -- Data and sync
  auto_backup BOOLEAN DEFAULT true NOT NULL,
  enable_data_sync BOOLEAN DEFAULT true NOT NULL,
  offline_mode BOOLEAN DEFAULT false NOT NULL,
  
  -- Date and time
  date_format TEXT DEFAULT 'MM/dd/yyyy' NOT NULL,
  time_format TEXT DEFAULT '12h' CHECK (time_format IN ('12h', '24h')) NOT NULL,
  first_day_of_week INTEGER DEFAULT 0 CHECK (first_day_of_week >= 0 AND first_day_of_week <= 6) NOT NULL,
  
  -- Behavior
  confirm_before_delete BOOLEAN DEFAULT true NOT NULL,
  enable_sound_effects BOOLEAN DEFAULT true NOT NULL,
  language_code TEXT DEFAULT 'en' NOT NULL,
  default_view TEXT DEFAULT 'tasks' CHECK (default_view IN ('tasks', 'calendar', 'categories')) NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- ===========================
-- NOTES TABLE
-- ===========================
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL CHECK (length(title) > 0),
  content TEXT DEFAULT '' NOT NULL,
  
  -- Organization
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  tags TEXT[] DEFAULT '{}' NOT NULL,
  
  -- Features
  is_pinned BOOLEAN DEFAULT false NOT NULL,
  is_archived BOOLEAN DEFAULT false NOT NULL,
  color TEXT DEFAULT '#8B5CF6' NOT NULL,
  
  -- Reminders
  reminder_time TIMESTAMP WITH TIME ZONE,
  has_reminder BOOLEAN DEFAULT false NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- ===========================
-- FUNCTIONS AND TRIGGERS
-- ===========================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile with better error handling
  INSERT INTO profiles (id, email, full_name, username, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    username = COALESCE(EXCLUDED.username, profiles.username),
    updated_at = now();
  
  -- Create default settings with conflict handling
  INSERT INTO settings (user_id, created_at, updated_at)
  VALUES (NEW.id, now(), now())
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create default categories with conflict handling
  INSERT INTO categories (user_id, name, description, color, icon, is_default, sort_order, created_at, updated_at) VALUES
    (NEW.id, 'Work', 'Work-related tasks and projects', '#2196F3', 'work', true, 1, now(), now()),
    (NEW.id, 'Personal', 'Personal tasks and errands', '#4CAF50', 'person', true, 2, now(), now()),
    (NEW.id, 'Shopping', 'Shopping lists and purchases', '#FF9800', 'shopping_cart', true, 3, now(), now()),
    (NEW.id, 'Health', 'Health and fitness related tasks', '#E91E63', 'favorite', true, 4, now(), now()),
    (NEW.id, 'Learning', 'Educational and learning activities', '#9C27B0', 'school', true, 5, now(), now())
  ON CONFLICT (user_id, name) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log the error but don't fail the user creation
    RAISE WARNING 'Error in handle_new_user trigger: %', SQLERRM;
    RETURN NEW;
END;
$$ language 'plpgsql' security definer;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===========================
-- ROW LEVEL SECURITY POLICIES
-- ===========================

-- RLS Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" 
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profile" 
  ON profiles FOR DELETE USING (auth.uid() = id);

-- RLS Policies for categories
CREATE POLICY "Users can view their own categories"
  ON categories FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own categories"
  ON categories FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own categories"
  ON categories FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own categories"
  ON categories FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for tasks
CREATE POLICY "Users can view their own tasks"
  ON tasks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own tasks"
  ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tasks"
  ON tasks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasks"
  ON tasks FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for settings
CREATE POLICY "Users can view their own settings"
  ON settings FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
  ON settings FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
  ON settings FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own settings"
  ON settings FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for notes
CREATE POLICY "Users can CRUD their own notes"
  ON notes FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- INDEXES FOR PERFORMANCE
-- ===========================

-- Indexes for tasks
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_category_id ON tasks(category_id) WHERE category_id IS NOT NULL;
CREATE INDEX idx_tasks_completed ON tasks(is_completed);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_user_completion ON tasks(user_id, is_completed);
CREATE INDEX idx_tasks_user_due_date ON tasks(user_id, due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tasks_notification_time ON tasks(notification_time) WHERE notification_time IS NOT NULL;

-- Indexes for categories
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_user_default ON categories(user_id, is_default);

-- Indexes for notes
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_category_id ON notes(category_id) WHERE category_id IS NOT NULL;
CREATE INDEX idx_notes_pinned ON notes(is_pinned);
CREATE INDEX idx_notes_archived ON notes(is_archived);

-- Indexes for profiles
CREATE INDEX idx_profiles_email ON profiles(email) WHERE email IS NOT NULL;
CREATE INDEX idx_profiles_username ON profiles(username) WHERE username IS NOT NULL;

-- ===========================
-- REAL-TIME SUBSCRIPTIONS
-- ===========================

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE settings;
ALTER PUBLICATION supabase_realtime ADD TABLE notes;

-- ===========================
-- SUCCESS MESSAGE
-- ===========================

SELECT 'Pro-Organizer Database Setup Completed Successfully! 🎉' as message,
       'You can now use your Flutter app with full real-time functionality.' as details,
       'Make sure to run this entire script in your Supabase SQL Editor.' as note;
