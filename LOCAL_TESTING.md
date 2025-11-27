# Local Testing without Docker

The automated tests expect MQTT brokers to be running on the standard ports defined in the bundled Mosquitto configurations. If Docker is unavailable, you can run the brokers directly with the system `mosquitto` binary.

## Prerequisites
- Install Mosquitto and the client tools:
  ```bash
  sudo apt-get update
  sudo apt-get install -y mosquitto mosquitto-clients
  ```
- Generate the self-signed certificates required for TLS endpoints:
  ```bash
  ./mosquitto/certs/generate.sh
  ```
- Ensure the Mosquitto user can read the generated certificate and password files:
  ```bash
  sudo chown mosquitto:mosquitto mosquitto/certs/* mosquitto/mosquitto-authenticated-passwd
  sudo chmod 600 mosquitto/certs/ca.key mosquitto/certs/server.key mosquitto/mosquitto-authenticated-passwd
  ```

## Starting the brokers
Start one Mosquitto instance for each provided configuration (plain/TLS/websocket, authenticated, and limited profile):
```bash
mosquitto -c mosquitto/mosquitto-default.conf -d
mosquitto -c mosquitto/mosquitto-authenticated.conf -d
mosquitto -c mosquitto/mosquitto-limited.conf -d
```

## Running the tests
With the brokers running, execute:
```bash
swift test
```
