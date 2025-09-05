# Pro-Organizer

A secure, personalized to-do and notes Flutter application with Supabase authentication and backend.

## 🚀 Features

### Authentication
- 🔐 Secure user authentication with Supabase
- 📝 Account creation and management
- 🔑 Password reset functionality

### Task Management
- ✅ Create, edit, and delete tasks
- 📅 Set due dates and priorities
- 🏷️ Organize tasks with categories
- ✓ Track task completion
- 🔍 Filter and sort tasks by various criteria
- 🔄 Recurring task support (daily, weekly, monthly, yearly)

### Notes
- 📝 Create, edit, and delete notes
- 📄 Rich text formatting
- ⭐ Favorite important notes
- 🏷️ Organize with tags
- 📲 Share notes with other users

### Notifications & Reminders
- ⏰ Due date reminders
- � Recurring notifications
- � Custom alarms
- 📲 Notification management

### Customization & Settings
- 🎨 Custom color theme (Dark Olive, Sage Green, Beige/Sand, Off-White)
- � Dark and light mode support
- �️ Personalized view options
- 🌍 Language settings
- � Data synchronization controls
- � Backup and restore functionality

### Technical Features
- 📱 Flutter UI framework
- 🏗️ Provider for state management
- ☁️ Supabase for authentication and cloud storage
- 🗄️ Hive for local offline database
- 🔔 Local notifications with timezone support
- 💉 get_it for dependency injection
- 🌍 Environment variables with .env
- 🛡️ Error handling and validation

## 📋 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Android SDK or iOS development setup

## 🛠️ Installation and Setup

### 1. Clone or Setup Project

If you haven't already, create a new Flutter project and replace the contents with this code:

```bash
flutter create todo_app
cd todo_app
```

### 2. Install Dependencies

Copy the `pubspec.yaml` file provided and run:

```bash
flutter pub get
```

### 3. Generate Hive Adapters

This step is **CRUCIAL** for the app to work. Run:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

If you make changes to model files later, re-run this command.

### 4. Setup Environment Variables

The `.env` file is already created with default values. You can modify it for your needs:

```env
# App Configuration
APP_NAME=Flutter Todo App
APP_VERSION=1.0.0

# Feature Flags
ENABLE_NOTIFICATIONS=true
ENABLE_DARK_THEME=true

# Database Configuration
HIVE_BOX_NAME=todos
CATEGORIES_BOX_NAME=categories
SETTINGS_BOX_NAME=settings
```

### 5. Run the Application

```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models
│   ├── todo.dart                     # Todo model with Hive annotations
│   ├── category.dart                 # Category model
│   └── app_settings.dart             # Settings model
├── providers/                         # State management
│   ├── todo_provider.dart            # Todo business logic
│   ├── category_provider.dart        # Category management
│   └── settings_provider.dart        # App settings
├── services/                          # External services
│   ├── notification_service.dart     # Local notifications
│   └── backup_service.dart           # Backup/restore functionality
├── screens/                           # UI screens
│   ├── home_screen.dart              # Main todo list screen
│   ├── add_edit_todo_screen.dart     # Add/edit todo form
│   ├── settings_screen.dart          # Settings management
│   └── categories_screen.dart        # Category management
└── widgets/                           # Reusable UI components
    ├── todo_list_tile.dart           # Individual todo item
    ├── search_bar_widget.dart        # Search functionality
    ├── filter_chip_widget.dart       # Filter chips
    └── statistics_card.dart          # Statistics display
```

## 🎯 Usage Guide

### Adding Your First Todo

1. Tap the **"Add Todo"** floating action button
2. Fill in the title (required)
3. Optionally add description, set priority, category, and due date
4. Enable notifications if you want reminders
5. Add tags for better organization
6. Tap **"Add Todo"** to save

### Managing Categories

1. Open the drawer menu and tap **"Categories"**
2. View default categories or create custom ones
3. Tap **"Add New Category"** to create a custom category
4. Choose a name, color, and icon
5. Use categories when creating todos for better organization

### Customizing Settings

1. Open the drawer menu and tap **"Settings"**
2. Configure theme (Light/Dark/System)
3. Set default priority and category
4. Configure notification preferences
5. Manage date/time formats
6. Enable auto-backup

### Search and Filtering

1. Tap the search icon in the app bar
2. Type to search in todo titles, descriptions, and tags
3. Use the filter menu to show only active, completed, or overdue todos
4. Filter by specific categories
5. Use tabs to quickly switch between todo states

## 🔧 Environment Configuration

The app uses environment variables for configuration. Key settings in `.env`:

### App Settings
- `APP_NAME`: Application name
- `APP_VERSION`: Version number
- `ENVIRONMENT`: development/production

### Feature Flags
- `ENABLE_NOTIFICATIONS`: Enable/disable notifications
- `ENABLE_DARK_THEME`: Enable dark theme support
- `ENABLE_CATEGORIES`: Enable category functionality

### Database Settings
- `HIVE_BOX_NAME`: Name for todos storage
- `CATEGORIES_BOX_NAME`: Name for categories storage
- `SETTINGS_BOX_NAME`: Name for settings storage

### Notification Settings
- `NOTIFICATION_CHANNEL_ID`: Android notification channel
- `NOTIFICATION_CHANNEL_NAME`: Channel display name

## 🚨 Troubleshooting

### Common Issues

1. **"Target of URI hasn't been generated" errors**
   - Run the build_runner command: `flutter packages pub run build_runner build --delete-conflicting-outputs`

2. **App crashes on startup**
   - Ensure all dependencies are installed: `flutter pub get`
   - Check that the .env file exists in the project root

3. **Notifications not working**
   - Check that `ENABLE_NOTIFICATIONS=true` in .env
   - Ensure app has notification permissions on device

4. **Data not persisting**
   - Verify Hive adapters are generated correctly
   - Check device storage permissions

### Development Mode

Set `DEBUG_MODE=true` in `.env` to enable:
- Detailed error messages
- Console logging
- Development-only features

## 🔮 Future Enhancements

Planned features for future versions:

- [ ] Cloud synchronization
- [ ] Collaborative todos
- [ ] Recurring todos
- [ ] Custom themes
- [ ] Widget support
- [ ] Voice input
- [ ] OCR for quick todo creation
- [ ] Integration with calendar apps
- [ ] Export to different formats

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure code quality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the troubleshooting section above
2. Review the environment configuration
3. Ensure all dependencies are properly installed
4. Check that Hive adapters are generated

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Hive for excellent local storage
- Provider for state management
- Flutter community for inspiration and support

---

**Happy Todo Management! 📝✨**
