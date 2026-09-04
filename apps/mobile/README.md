# Happy Paws Mobile

The official mobile application for Happy Paws, built with Flutter.

## Getting started

1. **Install dependencies**
   Install the Flutter SDK. From this directory, fetch the required packages:
   ```bash
   flutter pub get
   ```

2. **Configure environment variables**
   Create a `.env` file in this directory with your local API URL:
   ```bash
   cp .env.example .env
   ```
   For an Android emulator connecting to a localhost API, use `10.0.2.2`:
   ```env
   API_BASE_URL=http://10.0.2.2:5197
   ```
   For an iOS simulator or a physical device, use the IP address of your development machine running the API.

3. **Run the application**
   Start an Android emulator or iOS simulator. From the repository root, start the mobile app using Turborepo:
   ```bash
   pnpm run dev:mobile
   ```
   Alternatively, run it directly from this directory using the Flutter CLI:
   ```bash
   flutter run
   ```
