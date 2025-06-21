# Promise Keeper - Electron App

A simple, elegant promise tracking application with Supabase integration and system tray support.

## Features

- 🔐 Secure authentication with Supabase
- 📝 Add, view, and delete promises
- 📷 Upload screenshots to extract promises using AI
- 🖥️ System tray integration - stays in your taskbar
- 💾 Persistent storage with Supabase database
- 🎨 Modern, clean UI
- ⌨️ Keyboard shortcuts (Enter to add promises)
- 🔧 Configurable API endpoints for development

## Setup

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- A Supabase account and project

### Supabase Configuration

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to your project settings and copy your project URL and anon key
3. Update the Supabase configuration in `renderer/app.js`:
   ```javascript
   const SUPABASE_URL = 'YOUR_SUPABASE_URL';
   const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```

### Database Setup

Run this SQL in your Supabase SQL editor to create the promises table:

```sql
CREATE TABLE public.promises (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  content text NOT NULL,
  owner_id uuid NOT NULL,
  CONSTRAINT promises_pkey PRIMARY KEY (id)
);

-- Enable Row Level Security
ALTER TABLE public.promises ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to only see their own promises
CREATE POLICY "Users can only see their own promises" ON public.promises
  FOR ALL USING (auth.uid() = owner_id);
```

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the TypeScript:
   ```bash
   npm run build
   ```

3. Start the application:
   ```bash
   npm start
   ```

### API Configuration

The app connects to the Promise Keeper API for screenshot processing. By default, it uses the production API at `https://promise-keeper-api-red-sunset-2072.fly.dev`.

#### Local Development with Backend API

If you're running the backend API locally, create a `.env.local` file in the electron directory:

```bash
# .env.local
API_BASE_URL_OVERRIDE=http://localhost:8000
```

This will override the production API URL and use your local backend at `http://localhost:8000` instead.

**Important**: Make sure your local backend is running before starting the Electron app with this configuration.

## Development

### Scripts

- `npm run build` - Compile TypeScript
- `npm run start` - Build and start the app
- `npm run dev` - Start in development mode with DevTools
- `npm run watch` - Watch TypeScript files for changes
- `npm run package` - Package the app for distribution

### Development Mode

To run in development mode with DevTools:

```bash
npm run dev
```

### Building for Distribution

To package the app:

```bash
npm run package
```

## Usage

1. **Authentication**: Sign up or sign in with your email and password
2. **Add Promises**: Type your promise in the text area and press Enter or click "Add Promise"
3. **Upload Screenshots**: Click "Upload Screenshot" to select an image file and extract promises using AI
4. **View Promises**: All your promises are displayed in chronological order
5. **Delete Promises**: Click the delete button on any promise to remove it
6. **System Tray**: 
   - Click the tray icon to show/hide the window
   - Right-click for context menu with options
   - The app stays running in the system tray when closed

## Keyboard Shortcuts

- `Enter` - Add a new promise (when focused on input)
- `Shift + Enter` - New line in promise input
- `Enter` - Sign in (when focused on password field)

## System Tray Features

- **Left Click**: Toggle window visibility
- **Right Click Menu**:
  - Show Promise Keeper
  - Add Promise (opens window and focuses input)
  - Quit

## Architecture

- **Main Process** (`src/main.ts`): Handles window management, system tray, and IPC
- **Preload Script** (`src/preload.ts`): Safely exposes Electron APIs to renderer
- **Renderer Process** (`renderer/`): The web-based UI with Supabase integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details 