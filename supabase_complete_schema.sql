-- ==================================================
-- Pro-Organizer Todo App - Complete Database Schema v2.0
-- ==================================================
-- 
-- This file contains the complete database setup for the Pro-Organizer Todo App
-- with enhanced features including alarms, notifications, and real-time functionality
-- Run this in your Supabase SQL Editor to set up all tables and security policies
--

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing tables and functions for fresh install
DROP TABLE IF EXISTS alarm_logs CASCADE;
DROP TABLE IF EXISTS notification_logs CASCADE;
DROP TABLE IF EXISTS alarms CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS task_notes CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS activity_logs CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS update_user_last_seen() CASCADE;
DROP FUNCTION IF EXISTS log_activity() CASCADE;
DROP FUNCTION IF EXISTS handle_task_completion() CASCADE;
DROP FUNCTION IF EXISTS create_task_reminders() CASCADE;

-- ===========================
-- USER PROFILES TABLE
-- ===========================
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    username TEXT UNIQUE,
    bio TEXT,
    phone_number TEXT,
    date_of_birth DATE,
    website TEXT,
    location TEXT,
    
    -- Social authentication
    google_id TEXT,
    facebook_id TEXT,
    
    -- Real-time status
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    member_since TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Preferences
    theme_preference TEXT DEFAULT 'system', -- 'light', 'dark', 'system'
    language_preference TEXT DEFAULT 'en',
    timezone TEXT DEFAULT 'UTC',
    notification_preferences JSONB DEFAULT '{
        "email": true,
        "push": true,
        "sound": true,
        "task_reminders": true,
        "task_completions": true,
        "alarm_notifications": true
    }'::JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- ===========================
-- CATEGORIES TABLE
-- ===========================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT DEFAULT '#007AFF', -- Hex color code
    icon TEXT DEFAULT 'folder', -- Icon name
    is_default BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, name)
);

-- Enable Row Level Security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- ===========================
-- TASKS TABLE
-- ===========================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    
    -- Basic task information
    title TEXT NOT NULL,
    description TEXT,
    rich_description JSONB, -- Quill delta format for rich text
    
    -- Status and priority
    is_completed BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 1, -- 1=Low, 2=Medium, 3=High, 4=Urgent
    status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'cancelled'
    
    -- Dates and timing
    due_date TIMESTAMP WITH TIME ZONE,
    start_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_duration INTEGER, -- in minutes
    actual_duration INTEGER, -- in minutes
    
    -- Organization
    tags TEXT[], -- Array of tag strings
    sort_order INTEGER DEFAULT 0,
    
    -- Attachments and media
    attachments JSONB DEFAULT '[]'::JSONB, -- Array of attachment objects
    
    -- Collaboration (future feature)
    shared_with UUID[], -- Array of user IDs
    assigned_to UUID REFERENCES user_profiles(id),
    
    -- Recurrence (future feature)
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern JSONB, -- Stores recurrence rules
    parent_task_id UUID REFERENCES tasks(id),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- ===========================
-- TASK NOTES TABLE
-- ===========================
CREATE TABLE task_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    content TEXT,
    rich_content JSONB, -- Quill delta format
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE task_notes ENABLE ROW LEVEL SECURITY;

-- ===========================
-- STANDALONE NOTES TABLE
-- ===========================
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    rich_content JSONB, -- Quill delta format
    
    -- Organization
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    tags TEXT[],
    
    -- Features
    is_pinned BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    color TEXT DEFAULT '#007AFF',
    
    -- Reminders
    reminder_time TIMESTAMP WITH TIME ZONE,
    has_reminder BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- ===========================
-- NOTIFICATIONS TABLE
-- ===========================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- Notification content
    title TEXT NOT NULL,
    body TEXT,
    type TEXT NOT NULL, -- 'task_reminder', 'task_completed', 'task_created', 'alarm', 'system'
    
    -- Related objects
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    alarm_id UUID,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Delivery preferences
    delivery_channels JSONB DEFAULT '["push", "in_app"]'::JSONB, -- Array of delivery methods
    
    -- Additional data
    metadata JSONB DEFAULT '{}'::JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ===========================
-- ALARMS TABLE
-- ===========================
CREATE TABLE alarms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    
    -- Alarm configuration
    title TEXT NOT NULL,
    description TEXT,
    
    -- Timing
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern JSONB, -- Stores recurrence rules
    
    -- Audio settings
    sound_path TEXT DEFAULT 'assets/sounds/alarm.mp3',
    volume DECIMAL(3,2) DEFAULT 1.0, -- 0.0 to 1.0
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_snoozed BOOLEAN DEFAULT FALSE,
    snooze_until TIMESTAMP WITH TIME ZONE,
    triggered_at TIMESTAMP WITH TIME ZONE,
    stopped_at TIMESTAMP WITH TIME ZONE,
    
    -- Snooze settings
    snooze_count INTEGER DEFAULT 0,
    max_snooze_count INTEGER DEFAULT 5,
    snooze_duration INTEGER DEFAULT 5, -- minutes
    
    -- Auto-stop settings
    auto_stop_duration INTEGER DEFAULT 60, -- seconds
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE alarms ENABLE ROW LEVEL SECURITY;

-- ===========================
-- ACTIVITY LOGS TABLE
-- ===========================
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- Activity details
    action TEXT NOT NULL, -- 'created', 'updated', 'deleted', 'completed', 'alarm_triggered'
    entity_type TEXT NOT NULL, -- 'task', 'category', 'alarm', 'notification'
    entity_id UUID,
    
    -- Changes tracking
    old_values JSONB,
    new_values JSONB,
    
    -- Context
    description TEXT,
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- ===========================
-- USER SESSIONS TABLE
-- ===========================
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- Session details
    device_info JSONB,
    platform TEXT, -- 'android', 'ios', 'web'
    app_version TEXT,
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    
    -- Location (optional)
    location_data JSONB
);

-- Enable Row Level Security
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

-- ===========================
-- SETTINGS TABLE
-- ===========================
CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    
    -- Setting key-value pairs
    setting_key TEXT NOT NULL,
    setting_value JSONB,
    
    -- Metadata
    description TEXT,
    is_user_configurable BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, setting_key)
);

-- Enable Row Level Security
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- ===========================
-- FUNCTIONS
-- ===========================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update user's last_seen
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE user_profiles 
    SET last_seen = NOW() 
    WHERE id = auth.uid();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to log activity
CREATE OR REPLACE FUNCTION log_activity()
RETURNS TRIGGER AS $$
DECLARE
    action_type TEXT;
    entity_type TEXT;
    entity_id UUID;
BEGIN
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        action_type := 'created';
        entity_id := NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        action_type := 'updated';
        entity_id := NEW.id;
    ELSIF TG_OP = 'DELETE' THEN
        action_type := 'deleted';
        entity_id := OLD.id;
    END IF;
    
    -- Determine entity type from table name
    entity_type := TG_TABLE_NAME;
    
    -- Insert activity log
    INSERT INTO activity_logs (
        user_id, 
        action, 
        entity_type, 
        entity_id, 
        old_values, 
        new_values
    ) VALUES (
        auth.uid(),
        action_type,
        entity_type,
        entity_id,
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) ELSE NULL END
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function to handle task completion
CREATE OR REPLACE FUNCTION handle_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- If task is being marked as completed
    IF NEW.is_completed = TRUE AND OLD.is_completed = FALSE THEN
        NEW.completed_at = NOW();
        NEW.status = 'completed';
        
        -- Create completion notification
        INSERT INTO notifications (
            user_id,
            title,
            body,
            type,
            task_id
        ) VALUES (
            NEW.user_id,
            'Task Completed! 🎉',
            'You completed: ' || NEW.title,
            'task_completed',
            NEW.id
        );
        
    -- If task is being marked as incomplete
    ELSIF NEW.is_completed = FALSE AND OLD.is_completed = TRUE THEN
        NEW.completed_at = NULL;
        NEW.status = 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create task reminders
CREATE OR REPLACE FUNCTION create_task_reminders()
RETURNS TRIGGER AS $$
BEGIN
    -- Create reminder notification if due date is set
    IF NEW.due_date IS NOT NULL THEN
        -- Reminder 1 hour before due date
        INSERT INTO notifications (
            user_id,
            title,
            body,
            type,
            task_id,
            scheduled_for
        ) VALUES (
            NEW.user_id,
            'Task Reminder ⏰',
            'Task "' || NEW.title || '" is due in 1 hour',
            'task_reminder',
            NEW.id,
            NEW.due_date - INTERVAL '1 hour'
        );
        
        -- Reminder 15 minutes before due date
        INSERT INTO notifications (
            user_id,
            title,
            body,
            type,
            task_id,
            scheduled_for
        ) VALUES (
            NEW.user_id,
            'Task Due Soon! ⚠️',
            'Task "' || NEW.title || '" is due in 15 minutes',
            'task_reminder',
            NEW.id,
            NEW.due_date - INTERVAL '15 minutes'
        );
        
        -- Create alarm if needed
        INSERT INTO alarms (
            user_id,
            task_id,
            title,
            description,
            scheduled_time
        ) VALUES (
            NEW.user_id,
            NEW.id,
            'Task Due: ' || NEW.title,
            'Your task "' || NEW.title || '" is now due!',
            NEW.due_date
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile
    INSERT INTO user_profiles (
        id,
        email,
        full_name,
        username,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NOW(),
        NOW()
    );
    
    -- Create default categories
    INSERT INTO categories (user_id, name, description, color, icon, is_default, sort_order) VALUES
    (NEW.id, 'Work', 'Work-related tasks and projects', '#2196F3', 'work', true, 1),
    (NEW.id, 'Personal', 'Personal tasks and errands', '#4CAF50', 'person', true, 2),
    (NEW.id, 'Shopping', 'Shopping lists and purchases', '#FF9800', 'shopping_cart', true, 3),
    (NEW.id, 'Health', 'Health and fitness related tasks', '#E91E63', 'favorite', true, 4),
    (NEW.id, 'Learning', 'Educational and learning activities', '#9C27B0', 'school', true, 5);
    
    -- Create default settings
    INSERT INTO settings (user_id, setting_key, setting_value) VALUES
    (NEW.id, 'theme', '"system"'::jsonb),
    (NEW.id, 'notifications_enabled', 'true'::jsonb),
    (NEW.id, 'sound_enabled', 'true'::jsonb),
    (NEW.id, 'default_reminder_time', '60'::jsonb),
    (NEW.id, 'auto_mark_overdue', 'true'::jsonb);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===========================
-- TRIGGERS
-- ===========================

-- Updated at triggers
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_notes_updated_at
    BEFORE UPDATE ON task_notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alarms_updated_at
    BEFORE UPDATE ON alarms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Activity logging triggers
CREATE TRIGGER log_task_activity
    AFTER INSERT OR UPDATE OR DELETE ON tasks
    FOR EACH ROW EXECUTE FUNCTION log_activity();

CREATE TRIGGER log_category_activity
    AFTER INSERT OR UPDATE OR DELETE ON categories
    FOR EACH ROW EXECUTE FUNCTION log_activity();

CREATE TRIGGER log_alarm_activity
    AFTER INSERT OR UPDATE OR DELETE ON alarms
    FOR EACH ROW EXECUTE FUNCTION log_activity();

-- Task completion trigger
CREATE TRIGGER handle_task_completion_trigger
    BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION handle_task_completion();

-- Task reminder creation trigger
CREATE TRIGGER create_task_reminders_trigger
    AFTER INSERT ON tasks
    FOR EACH ROW EXECUTE FUNCTION create_task_reminders();

-- User activity triggers (update last_seen)
CREATE TRIGGER update_user_activity_on_task_action
    AFTER INSERT OR UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_user_last_seen();

CREATE TRIGGER update_user_activity_on_notification_read
    AFTER UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_user_last_seen();

-- New user trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ===========================
-- ROW LEVEL SECURITY POLICIES
-- ===========================

-- User profiles policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories policies
CREATE POLICY "Users can manage their own categories" ON categories
    FOR ALL USING (auth.uid() = user_id);

-- Tasks policies
CREATE POLICY "Users can manage their own tasks" ON tasks
    FOR ALL USING (auth.uid() = user_id);

-- Task notes policies
CREATE POLICY "Users can manage their own task notes" ON task_notes
    FOR ALL USING (auth.uid() = user_id);

-- Notes policies
CREATE POLICY "Users can manage their own notes" ON notes
    FOR ALL USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can manage their own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);

-- Alarms policies
CREATE POLICY "Users can manage their own alarms" ON alarms
    FOR ALL USING (auth.uid() = user_id);

-- Activity log policies
CREATE POLICY "Users can view their own activity" ON activity_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert activity logs" ON activity_logs
    FOR INSERT WITH CHECK (true);

-- User sessions policies
CREATE POLICY "Users can manage their own sessions" ON user_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Settings policies
CREATE POLICY "Users can manage their own settings" ON settings
    FOR ALL USING (auth.uid() = user_id);

-- ===========================
-- INDEXES FOR PERFORMANCE
-- ===========================

-- User profiles indexes
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_user_profiles_online ON user_profiles(is_online);
CREATE INDEX idx_user_profiles_last_seen ON user_profiles(last_seen);

-- Tasks indexes
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_category_id ON tasks(category_id);
CREATE INDEX idx_tasks_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_completed ON tasks(user_id, is_completed);
CREATE INDEX idx_tasks_due_date ON tasks(user_id, due_date);
CREATE INDEX idx_tasks_priority ON tasks(user_id, priority);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(user_id, type);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for);

-- Alarms indexes
CREATE INDEX idx_alarms_user_id ON alarms(user_id);
CREATE INDEX idx_alarms_task_id ON alarms(task_id);
CREATE INDEX idx_alarms_scheduled_time ON alarms(scheduled_time);
CREATE INDEX idx_alarms_active ON alarms(user_id, is_active);

-- ===========================
-- REAL-TIME SUBSCRIPTIONS
-- ===========================

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE categories;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE task_notes;
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE alarms;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE user_sessions;

-- ===========================
-- UTILITY FUNCTIONS
-- ===========================

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_tasks', (SELECT COUNT(*) FROM tasks WHERE user_id = user_uuid),
        'completed_tasks', (SELECT COUNT(*) FROM tasks WHERE user_id = user_uuid AND is_completed = true),
        'pending_tasks', (SELECT COUNT(*) FROM tasks WHERE user_id = user_uuid AND is_completed = false),
        'overdue_tasks', (SELECT COUNT(*) FROM tasks WHERE user_id = user_uuid AND due_date < NOW() AND is_completed = false),
        'total_categories', (SELECT COUNT(*) FROM categories WHERE user_id = user_uuid),
        'active_alarms', (SELECT COUNT(*) FROM alarms WHERE user_id = user_uuid AND is_active = true),
        'unread_notifications', (SELECT COUNT(*) FROM notifications WHERE user_id = user_uuid AND is_read = false)
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Success message
SELECT 'Todo App Database Schema v2.0 - Setup Complete! 🎉' as message,
       'Enhanced with alarms, notifications, real-time features, and comprehensive user management' as features,
       'Your Flutter app is now ready for full functionality!' as status;