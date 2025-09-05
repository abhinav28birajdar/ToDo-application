# Supabase Database Schema for Pro-Organizer

This document outlines the database schema design for the Pro-Organizer application's Supabase tables.

## Tables

### users (Managed by Supabase Auth)

Generated automatically by Supabase Auth. The following public profile information is stored in the `profiles` table.

### profiles

```sql
CREATE TABLE profiles (
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

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone" 
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE USING (auth.uid() = id);
```

### tasks

```sql
CREATE TABLE tasks (
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

-- Set up Row Level Security (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can CRUD their own tasks"
  ON tasks FOR ALL USING (auth.uid() = user_id);
```

### notes

```sql
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  is_favorite BOOLEAN DEFAULT false,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Set up Row Level Security (RLS)
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can CRUD their own notes"
  ON notes FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view notes shared with them"
  ON notes FOR SELECT USING (
    id IN (
      SELECT note_id FROM note_shares WHERE user_id = auth.uid()
    )
  );
```

### note_shares

```sql
CREATE TABLE note_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES notes(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  shared_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  
  CONSTRAINT unique_note_share UNIQUE (note_id, user_id)
);

-- Set up Row Level Security (RLS)
ALTER TABLE note_shares ENABLE ROW LEVEL SECURITY;

-- Create policies
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
```

### categories

```sql
CREATE TABLE categories (
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

-- Set up Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can CRUD their own categories"
  ON categories FOR ALL USING (auth.uid() = user_id);
```

### settings

```sql
CREATE TABLE settings (
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

-- Set up Row Level Security (RLS)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can CRUD their own settings"
  ON settings FOR ALL USING (auth.uid() = user_id);
```

### backups

```sql
CREATE TABLE backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  metadata JSONB DEFAULT '{}'::jsonb,
  data JSONB NOT NULL
);

-- Set up Row Level Security (RLS)
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can CRUD their own backups"
  ON backups FOR ALL USING (auth.uid() = user_id);
```

## Triggers

### Update Timestamps Trigger

```sql
-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tasks table
CREATE TRIGGER update_tasks_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Apply to notes table
CREATE TRIGGER update_notes_updated_at
BEFORE UPDATE ON notes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Apply to categories table
CREATE TRIGGER update_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Apply to settings table
CREATE TRIGGER update_settings_updated_at
BEFORE UPDATE ON settings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();
```

## Indexes

```sql
-- Tasks
CREATE INDEX tasks_user_id_idx ON tasks(user_id);
CREATE INDEX tasks_category_id_idx ON tasks(category_id);
CREATE INDEX tasks_due_date_idx ON tasks(due_date);

-- Notes
CREATE INDEX notes_user_id_idx ON notes(user_id);
CREATE INDEX notes_is_favorite_idx ON notes(is_favorite);

-- Note Shares
CREATE INDEX note_shares_note_id_idx ON note_shares(note_id);
CREATE INDEX note_shares_user_id_idx ON note_shares(user_id);

-- Categories
CREATE INDEX categories_user_id_idx ON categories(user_id);
```
