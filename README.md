# Promise Keeper 🌟

<div align="center">
  <img src="mac-app/PromiseKeeper/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" alt="Promise Keeper Icon" width="128" height="128" />
  
  <h3>Stay True to Your Word</h3>
  <p>A powerful promise tracking app that helps you keep commitments across all your digital conversations.</p>
</div>

## ✨ Features

### 🎯 Core Promise Management
- **Smart Promise Detection**: Automatically extract promises from screenshots and conversations
- **Cross-Platform Tracking**: Support for 15+ communication platforms including:
  - 💬 Messages, Discord, Slack
  - 📧 Gmail, Outlook, Email
  - 📱 WhatsApp, Telegram, Signal
  - 👥 Teams, Messenger, Instagram
  - 🔗 LinkedIn, Twitter/X
  - 📹 Zoom, Google Meet
  - 📅 Calendar apps and more

### 📱 Native Apps
- **macOS App**: Full-featured SwiftUI application with menu bar integration
- **iOS Widget**: Keep track of promises directly from your home screen
- **Electron App**: Cross-platform desktop application with system tray support

### 🤖 AI-Powered Features
- **Promise Extraction**: AI automatically identifies promises from screenshots
- **Context Understanding**: Intelligently categorizes promises by person, platform, and due date
- **Smart Notifications**: Reminds you about pending promises at the right time

### 🔄 Synchronization
- **Real-time Sync**: Seamless data synchronization across all devices
- **Cloud Storage**: Secure promise storage with Supabase integration
- **Offline Support**: Continue using the app even without internet connection

### 🎨 User Experience
- **Always-on-Top Mode**: Keep promises visible while working
- **Dark/Light Mode**: Adapts to your system preferences
- **Drag & Drop**: Easy screenshot integration
- **Accessibility**: Full accessibility support for all users

## 🚀 Quick Start

### Prerequisites
- macOS 12.0+ (for Mac app)
- Node.js 18+ (for Electron app)
- Xcode 14+ (for development)

### Running the macOS App

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/promise-keeper.git
   cd promise-keeper
   ```

2. **Open the Xcode project**:
   ```bash
   open mac-app/PromiseKeeper.xcodeproj
   ```

3. **Build and run**:
   - Select your target device
   - Press `Cmd+R` to build and run

### Running the Electron App

1. **Navigate to the electron directory**:
   ```bash
   cd electron
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the development server**:
   ```bash
   npm run dev
   ```

4. **Build for production**:
   ```bash
   npm run build
   npm start
   ```

## 🏗️ Project Structure

```
promise-keeper/
├── mac-app/                    # macOS SwiftUI Application
│   ├── PromiseKeeper/         # Main app target
│   ├── PromiseWidget/         # iOS Widget extension
│   └── PromiseKeeperShared/   # Shared data models
├── electron/                   # Cross-platform Electron app
│   ├── src/                   # TypeScript source files
│   ├── renderer/              # Frontend HTML/JS/CSS
│   └── dist/                  # Compiled JavaScript
├── backend/                    # Python backend API
│   ├── baml_src/              # AI model configurations
│   └── baml_client/           # Generated AI client
└── releases/                   # Built application packages
```

## 🔧 Configuration

### Backend Setup

1. **Set up Supabase**:
   - Create a new Supabase project
   - Configure authentication and database tables
   - Set environment variables in `backend/.env`

2. **Configure AI Models**:
   - Update `backend/baml_src/` with your AI provider settings
   - Run `baml generate` to update the client

### App Configuration

Update configuration files:
- `mac-app/PromiseKeeper/Auth/SupabaseConfig.swift` - Supabase settings
- `electron/renderer/config.js` - Electron app configuration

## 📋 Database Schema

The app uses the following main tables:
- **promises**: Core promise data with metadata
- **users**: User authentication and profiles
- **screenshots**: Screenshot storage and processing

Key promise fields:
- `content`: The promise text
- `person`: Who the promise is made to
- `platform`: Where the promise was made
- `due_date`: When the promise should be fulfilled
- `resolved`: Whether the promise has been kept

## 🧪 Testing

### macOS App Testing
```bash
cd mac-app
xcodebuild test -scheme PromiseKeeper -destination 'platform=macOS'
```

### Electron App Testing
```bash
cd electron
npm test
```

## 📦 Building Releases

### macOS Release
```bash
cd mac-app
./build_release.sh
```

### Electron Release
```bash
cd electron
npm run package
```

The built applications will be available in the `releases/` directory.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Sparkle**: Automatic updates for macOS
- **Supabase**: Backend and authentication
- **BAML**: AI model integration
- **Electron**: Cross-platform desktop apps

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-username/promise-keeper/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/your-username/promise-keeper/discussions)
- 📧 **Email**: support@promisekeeper.app

---

<div align="center">
  <p>Made with ❤️ for keeping promises</p>
  <p>⭐ Star this repo if Promise Keeper helps you stay accountable!</p>
</div>