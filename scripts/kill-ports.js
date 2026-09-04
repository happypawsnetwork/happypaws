#!/usr/bin/env node

const { execSync, spawnSync } = require('child_process');

const DEFAULT_DEV_PORTS = [3000, 5197, 7255];
const INFRA_PORTS = [5432, 6379, 9000, 9001];

function parseArguments() {
  const args = process.argv.slice(2);
  const ports = new Set();
  let includeInfra = false;

  for (const arg of args) {
    if (arg === '--infra') {
      includeInfra = true;
    } else if (arg === '--all') {
      includeInfra = true;
      DEFAULT_DEV_PORTS.forEach((p) => ports.add(p));
    } else if (arg === '--help' || arg === '-h') {
      console.log(`
Usage: pnpm kill-port [ports...] [options]

Options:
  --infra       Include Docker infrastructure ports (5432, 6379, 9000, 9001)
  --all         Include all dev ports and infrastructure ports
  -h, --help    Show this help message

Examples:
  pnpm kill-port              Kill default dev ports (3000, 5197, 7255)
  pnpm kill-port 8080 8081    Kill specified ports
  pnpm kill-port --infra      Kill dev ports plus infrastructure ports
`);
      process.exit(0);
    } else {
      const port = parseInt(arg, 10);
      if (!isNaN(port) && port > 0 && port <= 65535) {
        ports.add(port);
      } else {
        console.warn(`Warning: Ignoring invalid port argument "${arg}".`);
      }
    }
  }

  if (ports.size === 0) {
    DEFAULT_DEV_PORTS.forEach((p) => ports.add(p));
  }

  if (includeInfra) {
    INFRA_PORTS.forEach((p) => ports.add(p));
  }

  return Array.from(ports);
}

function findPidsOnWindows(ports) {
  const pidsByPort = new Map();
  try {
    const output = execSync('netstat -ano -p tcp', {
      encoding: 'utf-8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });

    const lines = output.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith('TCP')) continue;

      const parts = trimmed.split(/\s+/);
      if (parts.length < 5) continue;

      const localAddress = parts[1];
      const state = parts[3];
      const pid = parseInt(parts[4], 10);

      if (state !== 'LISTENING' || isNaN(pid) || pid <= 4) {
        continue;
      }

      const lastColonIndex = localAddress.lastIndexOf(':');
      if (lastColonIndex === -1) continue;

      const port = parseInt(localAddress.substring(lastColonIndex + 1), 10);
      if (ports.includes(port)) {
        if (!pidsByPort.has(port)) {
          pidsByPort.set(port, new Set());
        }
        pidsByPort.get(port).add(pid);
      }
    }
  } catch (error) {
    console.error('Error querying netstat:', error.message);
  }

  return pidsByPort;
}

function findPidsOnPosix(ports) {
  const pidsByPort = new Map();
  for (const port of ports) {
    try {
      const output = execSync(`lsof -ti :${port}`, {
        encoding: 'utf-8',
        stdio: ['ignore', 'pipe', 'ignore'],
      });
      const pids = output
        .trim()
        .split('\n')
        .map((line) => parseInt(line.trim(), 10))
        .filter((pid) => !isNaN(pid) && pid > 1);

      if (pids.length > 0) {
        pidsByPort.set(port, new Set(pids));
      }
    } catch {
      // Port is not in use
    }
  }
  return pidsByPort;
}

function killWindowsPid(pid) {
  try {
    execSync(`taskkill /F /PID ${pid}`, {
      stdio: ['ignore', 'ignore', 'pipe'],
      encoding: 'utf-8',
    });
    return { success: true };
  } catch (error) {
    const errorMsg = error.stderr ? error.stderr.toString() : error.message;
    const isAccessDenied =
      errorMsg.includes('Access is denied') ||
      errorMsg.includes('requires elevation') ||
      error.status === 1;
    return { success: false, accessDenied: isAccessDenied, error: errorMsg.trim() };
  }
}

function elevateAndKillWindowsPids(pids) {
  console.log('\nRequesting administrator privileges to terminate protected processes...');
  const pidList = Array.from(pids).join(',');
  const psCommand = `Start-Process powershell -ArgumentList '-NoProfile -Command Stop-Process -Id ${pidList} -Force' -Verb RunAs -Wait`;

  const result = spawnSync('powershell', ['-NoProfile', '-Command', psCommand], {
    stdio: 'inherit',
  });

  return result.status === 0;
}

function main() {
  const targetPorts = parseArguments();
  const isWindows = process.platform === 'win32';

  console.log(`Checking target ports: ${targetPorts.join(', ')}...`);

  const pidsByPort = isWindows
    ? findPidsOnWindows(targetPorts)
    : findPidsOnPosix(targetPorts);

  if (pidsByPort.size === 0) {
    console.log('No active processes found on target ports.');
    return;
  }

  const pidsNeedingElevation = new Set();
  const allKilledPids = new Set();

  for (const [port, pids] of pidsByPort.entries()) {
    for (const pid of pids) {
      if (allKilledPids.has(pid)) continue;

      if (isWindows) {
        process.stdout.write(`Terminating process on port ${port} (PID: ${pid})... `);
        const result = killWindowsPid(pid);
        if (result.success) {
          allKilledPids.add(pid);
          console.log('Done.');
        } else if (result.accessDenied) {
          console.log('Access denied.');
          pidsNeedingElevation.add(pid);
        } else {
          console.log(`Failed (${result.error}).`);
        }
      } else {
        try {
          process.kill(pid, 'SIGKILL');
          allKilledPids.add(pid);
          console.log(`Terminated process on port ${port} (PID: ${pid}).`);
        } catch (err) {
          console.error(`Failed to terminate PID ${pid}:`, err.message);
        }
      }
    }
  }

  if (pidsNeedingElevation.size > 0 && isWindows) {
    const elevatedSuccess = elevateAndKillWindowsPids(pidsNeedingElevation);
    if (elevatedSuccess) {
      console.log('Successfully terminated remaining processes with administrator privileges.');
    } else {
      console.error('Failed to terminate remaining processes even with elevation.');
      process.exit(1);
    }
  } else {
    console.log('Completed port cleanup.');
  }
}

main();
