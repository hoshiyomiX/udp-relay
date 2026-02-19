# Running UDP Relay on Termux (Android)

This guide explains how to run the UDP Relay server on an Android device using Termux.

## Compatibility Matrix

### Termux Environment

| Component | Status | Notes |
|-----------|--------|-------|
| **Python 3.x** | ✅ Fully Supported | Install via `pkg install python` |
| **socket module** | ✅ Fully Supported | Standard library, no issues |
| **threading module** | ✅ Fully Supported | Standard library, no issues |
| **argparse module** | ✅ Fully Supported | Standard library, no issues |
| **TCP Sockets** | ✅ Fully Supported | No external dependencies |
| **UDP Sockets** | ✅ Fully Supported | No external dependencies |
| **IPv4 Networking** | ✅ Fully Supported | Works on WiFi and mobile data |
| **IPv6 Networking** | ⚠️ Partial | May require specific configuration |

### Port Restrictions

| Port Range | Root Required | Notes |
|------------|---------------|-------|
| 1 - 1023 | ✅ Yes | Privileged ports |
| 1024 - 65535 | ❌ No | Default port 7300 is safe |

### Android Version Compatibility

| Android Version | Status | Notes |
|-----------------|--------|-------|
| Android 7+ | ✅ Fully Supported | Recommended |
| Android 10+ | ✅ Supported | May need battery optimization settings |
| Android 11+ | ⚠️ Partial | Stricter background process limits |
| Android 12+ | ⚠️ Partial | Additional permission requirements |

## Prerequisites

### 1. Install Termux

**⚠️ IMPORTANT: Do NOT use the Play Store version!** It's outdated and has known issues.

**Recommended sources:**
- **F-Droid**: https://f-droid.org/packages/com.termux/
- **GitHub Releases**: https://github.com/termux/termux/releases

Download the appropriate APK for your device architecture:
- `arm64-v8a` - Most modern phones (64-bit ARM)
- `armeabi-v7a` - Older phones (32-bit ARM)
- `x86_64` - Emulators/Chromebooks (64-bit Intel)

### 2. Enable Storage Permission (Optional)

```bash
termux-setup-storage
```

This allows Termux to access shared storage (useful for saving logs externally).

## Quick Install

### One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/install.sh | bash
```

This will automatically install Python, clone the repository, and set up all scripts.

### Manual Install

```bash
# 1. Update Termux packages
pkg update && pkg upgrade -y

# 2. Install git
pkg install git -y

# 3. Clone the repository
git clone https://github.com/hoshiyomiX/udp-relay.git
cd udp-relay

# 4. Run the installer
chmod +x install-termux.sh
./install-termux.sh
```

## Manual Setup

If you prefer manual installation:

```bash
# Update packages
pkg update && pkg upgrade -y

# Install Python
pkg install python -y

# Verify installation
python --version
python -c "import socket; import threading; import argparse; print('All modules OK!')"
```

## Usage

### Start the Relay Server

```bash
# Using default port (7300)
./termux/start-relay.sh

# Using custom port
./termux/start-relay.sh 8080

# Run directly in foreground
python main.py --port 7300
```

### Stop the Relay Server

```bash
./termux/stop-relay.sh
```

### View Logs

```bash
# View full log
cat relay.log

# Follow log in real-time
tail -f relay.log

# View last 50 lines
tail -50 relay.log
```

## Background Operation

The relay server runs in the background, but Android may kill background processes. Use one of these methods for persistent operation:

### Option 1: tmux (Recommended)

```bash
# Install tmux
pkg install tmux -y

# Create new session
tmux new -s relay

# Start the relay
python main.py --port 7300

# Detach: Press Ctrl+B then D
# Reattach: tmux attach -t relay
# List sessions: tmux ls
```

### Option 2: nohup (Already used by start-relay.sh)

The `start-relay.sh` script already uses nohup for background execution.

### Option 3: Termux:Boot (Auto-start on boot)

1. Install Termux:Boot from F-Droid or GitHub
2. Create boot script:
   ```bash
   mkdir -p ~/.termux/boot
   cat > ~/.termux/boot/relay.sh << 'EOF'
   #!/data/data/com.termux/files/usr/bin/sh
   cd ~/udp-relay
   ./termux/start-relay.sh
   EOF
   chmod +x ~/.termux/boot/relay.sh
   ```
3. Open Termux:Boot app once to initialize
4. Reboot to test

## Battery Optimization

Android may kill background processes to save battery. To prevent this:

### Method 1: Disable Battery Optimization

1. Go to: Settings → Apps → Termux
2. Tap: Battery
3. Select: Unrestricted (or "Don't optimize")

### Method 2: Use Wake Lock

```bash
# Install termux-api
pkg install termux-api -y

# Acquire wake lock
termux-wake-lock

# Release wake lock when done
termux-wake-unlock
```

**Note:** Wake lock prevents the device from sleeping, which uses more battery.

### Method 3: Keep Termux in Foreground

Split-screen mode or keeping Termux visible prevents it from being killed.

## Network Configuration

### Find Your Android IP Address

```bash
# Method 1: Using ifconfig
ifconfig wlan0

# Method 2: Using ip command
ip addr show wlan0

# Quick IP extraction
ifconfig wlan0 | grep "inet " | awk '{print $2}'
```

### Port Forwarding (External Access)

To access the relay from outside your local network:

1. **Router Port Forwarding:**
   - Access router admin panel (usually 192.168.1.1)
   - Find "Port Forwarding" or "NAT" settings
   - Forward port 7300 (TCP) to your Android device IP

2. **Mobile Hotspot:**
   - If using mobile hotspot, devices connect directly
   - Find your hotspot IP (usually 192.168.43.1)

### Firewall Considerations

Termux doesn't have a built-in firewall. If you have:
- **VPN apps**: May block incoming connections
- **Firewall apps**: Allow port 7300

## Testing the Relay

### Local Test (Same Device)

```bash
# Terminal 1: Start the relay
python main.py --port 7300

# Terminal 2: Run test client
python test_relay.py

# Or run example client
python client_example.py
```

### Remote Test (Another Device)

From a PC or another phone on the same network:

```bash
# Replace ANDROID_IP with your device's IP address
python client_example.py --relay-host ANDROID_IP --relay-port 7300
```

### Using netcat (nc)

```bash
# Simple TCP test
echo "udp:8.8.8.8:53|<dns_query>" | nc ANDROID_IP 7300
```

## Troubleshooting

### Python not found

```bash
pkg install python -y
```

### Permission denied

```bash
chmod +x termux/*.sh
chmod +x install-termux.sh
```

### Port already in use

```bash
# Find process using port
netstat -tulpn | grep 7300

# Or using ss
ss -tulpn | grep 7300

# Kill the process
kill <PID>

# Or use stop script
./termux/stop-relay.sh
```

### Cannot bind to port below 1024

On non-rooted Android, ports below 1024 are restricted. Use ports ≥ 1024:
- Default: 7300 (recommended)
- Alternative: 8080, 8888, 9000

### Server stops when screen turns off

See the [Battery Optimization](#battery-optimization) section above.

### Network changes (WiFi reconnect)

After network changes, restart the server:

```bash
./termux/stop-relay.sh
./termux/start-relay.sh
```

### Connection refused from other devices

1. **Check firewall/VPN apps** - Disable them temporarily
2. **Verify IP address** - Make sure you're using the correct IP
3. **Check WiFi isolation** - Some networks block device-to-device communication
4. **Test locally first** - Run client on the same device

### Module import errors

If standard library modules fail to import:

```bash
# Reinstall Python
pkg uninstall python
pkg install python

# Or try python3
python3 main.py --port 7300
```

## Performance Considerations

### Resource Usage

The relay server is lightweight:
- **Memory**: ~10-20 MB idle
- **CPU**: Minimal when idle
- **Battery**: Low impact (unless very active)

### Optimization Tips

1. **Use stable WiFi** for best performance
2. **Close unnecessary apps** to free memory
3. **Monitor with htop**:
   ```bash
   pkg install htop -y
   htop
   ```

### Connection Limits

Android may have limits on:
- Maximum file descriptors
- Concurrent connections
- Network buffer sizes

For heavy use, consider a dedicated server instead.

## Known Limitations

1. **No IPv6 support** - Only IPv4 addresses supported in protocol format
2. **No SSL/TLS** - Connections are unencrypted
3. **No authentication** - Anyone can connect (use firewall for access control)
4. **Single-threaded main loop** - High connection counts may impact performance
5. **No hot-reload** - Must restart for config changes

## File Locations

| File | Path |
|------|------|
| Main script | `~/udp-relay/main.py` |
| PID file | `~/udp-relay/.relay.pid` |
| Log file | `~/udp-relay/relay.log` |
| Termux scripts | `~/udp-relay/termux/` |
| Boot script | `~/.termux/boot/relay.sh` |

## Uninstallation

**One-line uninstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/uninstall.sh | bash
```

**Manual uninstall:**
```bash
# Stop the server
./termux/stop-relay.sh

# Remove the directory
cd ~
rm -rf udp-relay

# Remove boot script (if created)
rm -f ~/.termux/boot/relay.sh
```

## Additional Resources

- [Termux Wiki](https://wiki.termux.com/)
- [Termux Python Package Info](https://wiki.termux.com/wiki/Python)
- [Termux Remote Access](https://wiki.termux.com/wiki/Remote_Access)
- [Android Network Security Config](https://developer.android.com/training/articles/security-config)

## Support

If you encounter issues:

1. Check this documentation first
2. Search [Termux issues](https://github.com/termux/termux-packages/issues)
3. Check [project issues](https://github.com/hoshiyomiX/udp-relay/issues)
4. Open a new issue with:
   - Device model and Android version
   - Termux version (`echo $TERMUX_VERSION`)
   - Python version (`python --version`)
   - Error message or log output
