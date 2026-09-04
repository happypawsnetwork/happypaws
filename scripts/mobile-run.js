const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function resolveDefaultAndroidDevice() {
  const flutterCmd = process.platform === 'win32' ? 'flutter.bat' : 'flutter';

  // 1. Check for active connected Android devices or running emulators via ADB
  try {
    const adbOutput = execSync('adb devices', { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'ignore'] });
    const lines = adbOutput.trim().split('\n').slice(1);
    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length >= 2 && parts[1] === 'device') {
        return parts[0];
      }
    }
  } catch {
    // ADB check failed or not installed
  }

  // 2. Check for available Android emulators to auto-launch
  try {
    const emulatorOutput = execSync(`${flutterCmd} emulators`, { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'ignore'] });
    const lines = emulatorOutput.split('\n');
    for (const line of lines) {
      if (line.includes('•') && line.toLowerCase().includes('android')) {
        const parts = line.split('•').map(s => s.trim());
        if (parts[0] && !parts[0].toLowerCase().includes('id')) {
          return parts[0];
        }
      }
    }
  } catch {
    // Flutter emulators check failed
  }

  // 3. Fallback default
  return 'android';
}

const args = ['run'];

if (fs.existsSync(path.resolve(process.cwd(), '.env'))) {
  args.push('--dart-define-from-file=.env');
} else if (fs.existsSync(path.resolve(__dirname, '../apps/mobile/.env'))) {
  args.push(`--dart-define-from-file=${path.resolve(__dirname, '../apps/mobile/.env')}`);
}

const deviceArgs = process.argv.slice(2);

const hasDeviceFlag = deviceArgs.some(
  arg => arg === '-d' || arg === '--device' || arg.startsWith('-d=') || arg.startsWith('--device=')
);

if (!hasDeviceFlag) {
  const target = resolveDefaultAndroidDevice();
  console.log(`Targeting Android device: ${target}`);
  args.push('-d', target);
}

args.push(...deviceArgs);

const child = spawn(process.platform === 'win32' ? 'flutter.bat' : 'flutter', args, { 
  stdio: 'inherit',
  shell: true
});

child.on('close', (code) => {
  process.exit(code ?? 0);
});
