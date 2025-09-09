-- Pro-Organizer Todo App - Complete Database Setup
-- This SQL file creates the complete database schema for the Todo Application

-- Enable UUID extension (required for Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===========================
-- PROFILES TABLE
-- ===========================
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

-- Set up Row Level Security (RLS) for profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Create policies for profiles
CREATE POLICY "Public profiles are viewable by everyone" 
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ===========================
-- CATEGORIES TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  color TEXT NOT NULL DEFAULT '#2196F3',
  icon TEXT DEFAULT 'work',
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_user_category_name UNIQUE (user_id, name)
);

-- Set up Row Level Security (RLS) for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can CRUD their own categories" ON categories;

-- Create policies for categories
CREATE POLICY "Users can CRUD their own categories"
  ON categories FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- TASKS TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  is_completed BOOLEAN DEFAULT false,
  due_date TIMESTAMP WITH TIME ZONE,
  notification_time TIMESTAMP WITH TIME ZONE,
  completed_date TIMESTAMP WITH TIME ZONE,
  priority INTEGER DEFAULT 2 CHECK (priority >= 1 AND priority <= 5),
  recurrence TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Set up Row Level Security (RLS) for tasks
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can CRUD their own tasks" ON tasks;

-- Create policies for tasks
CREATE POLICY "Users can CRUD their own tasks"
  ON tasks FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- NOTES TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  is_favorite BOOLEAN DEFAULT false,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Set up Row Level Security (RLS) for notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can CRUD their own notes" ON notes;
DROP POLICY IF EXISTS "Users can view notes shared with them" ON notes;

-- Create policies for notes
CREATE POLICY "Users can CRUD their own notes"
  ON notes FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- NOTE SHARES TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS note_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  shared_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_note_share UNIQUE (note_id, user_id)
);

-- Set up Row Level Security (RLS) for note_shares
ALTER TABLE note_shares ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Note owners can manage shares" ON note_shares;
DROP POLICY IF EXISTS "Users can view their shares" ON note_shares;

-- Create policies for note_shares
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

-- ===========================
-- SETTINGS TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS settings (
  user_id UUID REFERENCES auth.users(id) PRIMARY KEY,
  theme_mode TEXT DEFAULT 'system' CHECK (theme_mode IN ('light', 'dark', 'system')),
  sort_order TEXT DEFAULT 'due_date_asc',
  filter_option TEXT DEFAULT 'all',
  notifications_enabled BOOLEAN DEFAULT true,
  auto_backup BOOLEAN DEFAULT true,
  default_priority INTEGER DEFAULT 2 CHECK (default_priority >= 1 AND default_priority <= 5),
  show_completed_tasks BOOLEAN DEFAULT true,
  date_format TEXT DEFAULT 'MM/dd/yyyy',
  time_format TEXT DEFAULT '12h' CHECK (time_format IN ('12h', '24h')),
  confirm_before_delete BOOLEAN DEFAULT true,
  reminder_minutes_before INTEGER DEFAULT 60,
  group_by_category BOOLEAN DEFAULT true,
  default_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  default_view TEXT DEFAULT 'tasks' CHECK (default_view IN ('tasks', 'notes', 'categories')),
  language_code TEXT DEFAULT 'en',
  enable_sound_effects BOOLEAN DEFAULT true,
  enable_data_sync BOOLEAN DEFAULT true,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Set up Row Level Security (RLS) for settings
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can CRUD their own settings" ON settings;

-- Create policies for settings
CREATE POLICY "Users can CRUD their own settings"
  ON settings FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- BACKUPS TABLE
-- ===========================
CREATE TABLE IF NOT EXISTS backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb,
  data JSONB NOT NULL
);

-- Set up Row Level Security (RLS) for backups
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can CRUD their own backups" ON backups;

-- Create policies for backups
CREATE POLICY "Users can CRUD their own backups"
  ON backups FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- TRIGGERS
-- ===========================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
DROP TRIGGER IF EXISTS update_settings_updated_at ON settings;

-- Apply triggers to update timestamps
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

-- ===========================
-- INDEXES FOR PERFORMANCE
-- ===========================

-- Tasks indexes
CREATE INDEX IF NOT EXISTS tasks_user_id_idx ON tasks(user_id);
CREATE INDEX IF NOT EXISTS tasks_category_id_idx ON tasks(category_id);
CREATE INDEX IF NOT EXISTS tasks_due_date_idx ON tasks(due_date);
CREATE INDEX IF NOT EXISTS tasks_is_completed_idx ON tasks(is_completed);
CREATE INDEX IF NOT EXISTS tasks_priority_idx ON tasks(priority);
CREATE INDEX IF NOT EXISTS tasks_created_at_idx ON tasks(created_at);

-- Notes indexes
CREATE INDEX IF NOT EXISTS notes_user_id_idx ON notes(user_id);
CREATE INDEX IF NOT EXISTS notes_is_favorite_idx ON notes(is_favorite);
CREATE INDEX IF NOT EXISTS notes_title_idx ON notes USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS notes_content_idx ON notes USING gin(to_tsvector('english', content));

-- Categories indexes
CREATE INDEX IF NOT EXISTS categories_user_id_idx ON categories(user_id);
CREATE INDEX IF NOT EXISTS categories_is_default_idx ON categories(is_default);

-- Note shares indexes
CREATE INDEX IF NOT EXISTS note_shares_note_id_idx ON note_shares(note_id);
CREATE INDEX IF NOT EXISTS note_shares_user_id_idx ON note_shares(user_id);

-- ===========================
-- DEFAULT DATA INSERTION
-- ===========================

-- Function to insert default categories for new users
CREATE OR REPLACE FUNCTION insert_default_categories_for_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
  -- Insert default categories only if they don't exist
  INSERT INTO categories (user_id, name, description, color, icon, is_default)
  SELECT user_uuid, name, description, color, icon, true
  FROM (VALUES
    ('Work', 'Work-related tasks and projects', '#2196F3', 'work'),
    ('Personal', 'Personal tasks and activities', '#4CAF50', 'home'),
    ('Shopping', 'Shopping lists and errands', '#FF9800', 'shopping_cart'),
    ('Health', 'Health and fitness activities', '#F44336', 'local_hospital'),
    ('Education', 'Learning and educational tasks', '#9C27B0', 'school')
  ) AS default_cats(name, description, color, icon)
  WHERE NOT EXISTS (
    SELECT 1 FROM categories 
    WHERE user_id = user_uuid AND name = default_cats.name
  );
END;
$$ LANGUAGE plpgsql;

-- Function to insert default settings for new users
CREATE OR REPLACE FUNCTION insert_default_settings_for_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
  INSERT INTO settings (user_id)
  VALUES (user_uuid)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to automatically create default data for new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert default categories
  PERFORM insert_default_categories_for_user(NEW.id);
  
  -- Insert default settings
  PERFORM insert_default_settings_for_user(NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===========================
-- USEFUL VIEWS
-- ===========================

-- View for task statistics
CREATE OR REPLACE VIEW task_statistics AS
SELECT 
  user_id,
  COUNT(*) as total_tasks,
  COUNT(*) FILTER (WHERE is_completed = true) as completed_tasks,
  COUNT(*) FILTER (WHERE is_completed = false) as active_tasks,
  COUNT(*) FILTER (WHERE due_date < now() AND is_completed = false) as overdue_tasks,
  COUNT(*) FILTER (WHERE date_trunc('day', due_date) = date_trunc('day', now()) AND is_completed = false) as today_tasks
FROM tasks
GROUP BY user_id;

-- View for category task counts
CREATE OR REPLACE VIEW category_task_counts AS
SELECT 
  c.id as category_id,
  c.user_id,
  c.name as category_name,
  COALESCE(t.task_count, 0) as total_tasks,
  COALESCE(t.completed_count, 0) as completed_tasks,
  COALESCE(t.active_count, 0) as active_tasks
FROM categories c
LEFT JOIN (
  SELECT 
    category_id,
    COUNT(*) as task_count,
    COUNT(*) FILTER (WHERE is_completed = true) as completed_count,
    COUNT(*) FILTER (WHERE is_completed = false) as active_count
  FROM tasks
  WHERE category_id IS NOT NULL
  GROUP BY category_id
) t ON c.id = t.category_id;

-- ===========================
-- DATA CLEANUP FUNCTIONS
-- ===========================

-- Function to clean up old completed tasks (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_completed_tasks()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM tasks 
  WHERE is_completed = true 
    AND completed_date < now() - interval '30 days';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up old backups (keep only last 10 per user)
CREATE OR REPLACE FUNCTION cleanup_old_backups()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM backups
  WHERE id NOT IN (
    SELECT id FROM (
      SELECT id, 
             ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
      FROM backups
    ) ranked
    WHERE rn <= 10
  );
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ===========================
-- COMPLETION MESSAGE
-- ===========================

-- Insert a test record to verify everything is working
DO $$
BEGIN
  RAISE NOTICE 'Pro-Organizer Todo App Database Setup Complete!';
  RAISE NOTICE 'Tables created: profiles, categories, tasks, notes, note_shares, settings, backups';
  RAISE NOTICE 'Triggers configured for automatic timestamps and default data insertion';
  RAISE NOTICE 'RLS policies enabled for data security';
  RAISE NOTICE 'Performance indexes created';
  RAISE NOTICE 'Helper views and cleanup functions available';
END $$;
