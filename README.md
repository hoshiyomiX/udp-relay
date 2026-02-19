# TCP/UDP Relay Docker

This project runs a TCP/UDP relay server. The server listens for TCP connections on a specified port, reads a target address and protocol, and relays TCP or UDP packets to that target.

## How to Run with Docker (Recommended)

The easiest way to run the relay server is using the pre-built Docker image from Docker Hub:

```bash
docker pull kelvinzer0/udp-relay
docker run -p <host_port>:7300 --name udp-relay-server kelvinzer0/udp-relay
```

*   `<host_port>`: The port on your local machine to expose the relay service.

Example:
```bash
# Map port 7300 on the host to port 7300 in the container
docker run -p 7300:7300 --name udp-relay-server kelvinzer0/udp-relay

# Map port 8080 on the host to port 7300 in the container
docker run -p 8080:7300 --name udp-relay-server kelvinzer0/udp-relay
```

### Running on Termux (Android)

Run the relay on your Android phone/tablet using Termux.

> ✅ **Works on NON-ROOTED phones** - No root access required!

**One-line installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/install.sh | bash
```

**One-line uninstall:**
```bash
curl -fsSL https://raw.githubusercontent.com/hoshiyomiX/udp-relay/main/uninstall.sh | bash
```

**Manual installation:**
```bash
# Install Termux from F-Droid (NOT Play Store)
# https://f-droid.org/packages/com.termux/

pkg install git -y
git clone https://github.com/hoshiyomiX/udp-relay.git
cd udp-relay
chmod +x install-termux.sh && ./install-termux.sh
```

**Usage:**
```bash
./termux/start-relay.sh        # Start server (port 7300)
./termux/start-relay.sh 8080   # Start on custom port (must be >= 1024)
./termux/stop-relay.sh         # Stop server
cat relay.log                  # View logs
```

See [docs/TERMUX.md](docs/TERMUX.md) for detailed setup, auto-start, and troubleshooting.

### Running from Source (Alternative)

1.  **Prerequisites:**
    *   Python 3.6+

2.  **Running the server:**

    ```bash
    python main.py [--port <port_number>]
    ```

    *   `--port <port_number>`: (Optional) The port for the server to listen on. Defaults to `7300`.
    *   **Note:** Ports below 1024 require root privileges (run with `sudo`).

    Example:
    ```bash
    # Run on the default port 7300
    python main.py

    # Run on port 8080
    python main.py --port 8080
    ```

## Example Usage

This server expects data in a specific format over a TCP connection: `protocol:target_ip:target_port|actual_data`.

Here is a simple Python client example that sends a message to a target server through the relay.

```python
import socket
import argparse

def send_via_relay(relay_host, relay_port, protocol, target_ip, target_port, data):
    """
    Connects to the TCP relay server and sends a packet to the target.
    """
    try:
        # Create a TCP socket to connect to the relay
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as tcp_sock:
            tcp_sock.connect((relay_host, relay_port))
            print(f"Connected to relay server at {relay_host}:{relay_port}")

            # Prepare the header and the payload
            header = f"{protocol}:{target_ip}:{target_port}".encode('utf-8')
            payload = data.encode('utf-8') if isinstance(data, str) else data
            
            # Format: "protocol:target_ip:target_port|actual_data"
            message = header + b'|' + payload

            # Send the formatted message
            tcp_sock.sendall(message)
            print(f"Sent {protocol.upper()} data to target {target_ip}:{target_port} via relay.")

            # Listen for a response from the target (relayed back by the server)
            print("Waiting for response from target...")
            response = tcp_sock.recv(4096)
            if response:
                print(f"Received response from target: {response.decode('utf-8', 'ignore')}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TCP/UDP Relay Client Example")
    parser.add_argument('--relay-host', type=str, default='127.0.0.1', help='Relay server host')
    parser.add_argument('--relay-port', type=int, default=7300, help='Relay server port')
    args = parser.parse_args()

    # --- UDP Example ---
    print("--- Sending UDP Packet ---")
    UDP_TARGET_IP = '1.1.1.1'  # Example public DNS
    UDP_TARGET_PORT = 53
    udp_message = b'\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00\x07example\x03com\x00\x00\x01\x00\x01' # DNS query for example.com
    send_via_relay(args.relay_host, args.relay_port, 'udp', UDP_TARGET_IP, UDP_TARGET_PORT, udp_message)
    print("\n" + "-"*26 + "\n")

    # --- TCP Example ---
    print("--- Sending TCP Packet ---")
    TCP_TARGET_IP = '93.184.216.34'  # Example IP for example.com
    TCP_TARGET_PORT = 80
    tcp_message = "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
    send_via_relay(args.relay_host, args.relay_port, 'tcp', TCP_TARGET_IP, TCP_TARGET_PORT, tcp_message)
```

### How to run the example:

1.  Make sure the relay server is running (either from Docker or source).
2.  Save the code above as `client_example.py`.
3.  Run the client:

    ```bash
    python client_example.py [--relay-host <host>] [--relay-port <port>]
    ```

    Example:
    ```bash
    # Connect to the relay on localhost:7300 (default)
    python client_example.py

    # Connect to the relay on a different host and port
    python client_example.py --relay-host my-relay.example.com --relay-port 8080
    ```

### Public Relay List

If you are running a **TCP/UDP Relay** instance and would like to share your relay with the community, please **fork this repository**, edit the table below by adding your relay information, and submit a **pull request**. I'll be happy to review and approve it.

| No | Relay IP / Host         | Port TCP | Date Start Active |
| -- | ----------------------- | -------- | ----------------- |
| 1  | `udp-relay.hobihaus.space` | 80     | 2025-09-12        |
---
