# Database Setup Guide

## Quick Setup Steps

### 1. Deploy Database Schema
1. Go to your Supabase Dashboard: https://app.supabase.com/
2. Select your project: `eispzohrybkiaczvzhrx`
3. Navigate to **SQL Editor** (left sidebar)
4. Open the file `supabase_complete_schema.sql` from your project
5. Copy all the SQL code
6. Paste it into the SQL Editor
7. Click **Run** to execute

### 2. Enable Authentication Providers
1. Go to **Authentication** → **Providers** in Supabase Dashboard
2. Enable **Email** provider (should be enabled by default)
3. For Google OAuth:
   - Enable **Google** provider
   - Add your Client ID: `951387755919-u4bfdqoitnn8fbn580n0h01d4iui6m7p.apps.googleusercontent.com`
   - Add your Client Secret (you'll need to get this from Google Console)

### 3. Test the App
After deploying the schema:
1. Run your Flutter app: `flutter run`
2. Try creating a new account
3. The "Database error saving new user" should be resolved

## What the Schema Creates
- ✅ User profiles table
- ✅ Categories and tasks tables  
- ✅ Alarms and notifications tables
- ✅ Row Level Security (RLS) policies
- ✅ Real-time subscriptions
- ✅ Database triggers for automatic timestamps

## Troubleshooting
If you still get errors after deploying the schema:
1. Check the SQL Editor for any error messages
2. Verify RLS policies are enabled
3. Make sure your Supabase URL and keys are correct in `.env`