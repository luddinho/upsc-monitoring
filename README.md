# UPS Monitoring Script

**[🇩🇪 Deutsche Version](README_DE.md)** | **[🇬🇧 English Version](#english-version)**

---

## English Version

A bash script for monitoring Uninterruptible Power Supply (UPS) devices and sending metrics to InfluxDB for real-time monitoring and visualization.

### Features

- **Real-time UPS Monitoring**: Collects comprehensive UPS metrics via Network UPS Tools (NUT)
- **InfluxDB Integration**: Stores time-series data in InfluxDB 2.x for visualization with Grafana
- **Flexible Configuration**: Supports configuration via file or command-line arguments
- **Secure Authentication**: Token-based authentication with support for token files
- **Comprehensive Metrics**: Monitors battery, input/output voltage, frequency, load, power, and more
- **Error Handling**: Robust error checking and validation

### Prerequisites

- **Network UPS Tools (NUT)**: The `upsc` command must be available
  - Install on Debian/Ubuntu: `sudo apt-get install nut-client`
  - Install on macOS: `brew install nut` (Note: upsc tool may not be available via Homebrew on macOS)
  - Install on RHEL/CentOS: `sudo yum install nut-client`
- **curl**: For sending data to InfluxDB
- **InfluxDB 2.x**: A running InfluxDB instance
- **Bash**: Version 4.0 or higher

### Installation

1. Clone or download this repository:
   ```bash
   git clone <repository-url>
   cd upsc-data
   ```

2. Make the script executable:
   ```bash
   chmod +x upsc-monitoring.sh
   ```

3. Copy the example configuration file and adjust it to your needs:
   ```bash
   cp config/config.conf config/my-ups.conf
   ```

4. Edit the configuration file with your settings (see Configuration section below)

### Configuration

Create a configuration file based on the example in `config/config.conf`:

```bash
# InfluxDB connection settings (REQUIRED)
influx_server=http://192.168.1.100
influx_port=8086
influx_bucket=ups-monitoring
influx_org=home-network

# InfluxDB authentication (use either influx_token or influx_token_file)
influx_token=your-influxdb-token-here
# influx_token_file=/path/to/token.txt

# UPS monitoring settings
ups_host=192.168.1.50
ups_port=3493
ups_name=ups
```

#### Configuration Parameters

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `influx_server` | InfluxDB server URL | Yes | - |
| `influx_port` | InfluxDB server port | Yes | - |
| `influx_bucket` | InfluxDB bucket name | Yes | - |
| `influx_org` | InfluxDB organization | Yes | - |
| `influx_token` | InfluxDB authentication token | Yes* | - |
| `influx_token_file` | Path to file containing token | Yes* | - |
| `ups_host` | UPS host IP address | Yes | - |
| `ups_port` | UPS NUT server port | Yes | - |
| `ups_name` | UPS device name | Yes | - |

*Either `influx_token` or `influx_token_file` must be provided.

### Usage

Run the script with a configuration file:

```bash
./upsc-monitoring.sh -c config/my-ups.conf
```

Or display help:

```bash
./upsc-monitoring.sh -h
```

### Monitored Metrics

The script collects the following UPS metrics:

| Metric | Description | Type |
|--------|-------------|------|
| `battery_charge` | Battery charge percentage | Numeric |
| `battery_charge_low` | Low battery threshold | Numeric |
| `battery_runtime` | Estimated battery runtime (seconds) | Numeric |
| `input_frequency` | Input line frequency (Hz) | Numeric |
| `input_transfer_high` | High voltage transfer point | Numeric |
| `input_transfer_low` | Low voltage transfer point | Numeric |
| `input_voltage` | Input voltage (V) | Numeric |
| `input_voltage_extended` | Extended input voltage information | String |
| `output_frequency` | Output frequency (Hz) | Numeric |
| `output_frequency_nominal` | Nominal output frequency | Numeric |
| `output_voltage` | Output voltage (V) | Numeric |
| `output_voltage_nominal` | Nominal output voltage | Numeric |
| `ups_beeper_status` | Beeper status | String |
| `ups_delay_shutdown` | Shutdown delay (seconds) | Numeric |
| `ups_delay_start` | Startup delay (seconds) | Numeric |
| `ups_load` | UPS load percentage | Numeric |
| `ups_power` | Apparent power (VA) | Numeric |
| `ups_power_nominal` | Nominal power rating | Numeric |
| `ups_realpower` | Real power (W) | Numeric |
| `ups_status` | UPS status (e.g., OL, OB) | String |
| `ups_timer_shutdown` | Shutdown timer value | Numeric |
| `ups_timer_start` | Startup timer value | Numeric |

All metrics are stored in the InfluxDB measurement `ups_status` with a `host` tag.

### Automation with Cron

To automatically collect UPS data at regular intervals, add a cron job:

```bash
# Edit crontab
crontab -e

# Add entry to run every 5 minutes
*/5 * * * * /path/to/upsc-monitoring.sh -c /path/to/config.conf
```

### Grafana Dashboard

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="upsc-monitoring-grafana-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="upsc-monitoring-grafana-bright.png">
  <img alt="UPS Monitoring Dashboard" src="upsc-monitoring-grafana-bright.png">
</picture>

The `config` folder contains example Grafana dashboard JSON files that can be imported to visualize your UPS metrics:

1. Open Grafana
2. Go to Dashboards → Import
3. Upload one of the JSON files from the `config` folder
4. Select your InfluxDB data source
5. Adjust the dashboard as needed

### Troubleshooting

**Script reports "No data received from UPS":**
- Verify the UPS is reachable: `ping <ups_host>`
- Check NUT is running on the UPS: `upsc <ups_name>@<ups_host>:<ups_port>`
- Verify firewall rules allow port 3493

**InfluxDB write fails (HTTP status code != 204):**
- Verify InfluxDB is running and reachable
- Check your authentication token is valid
- Ensure the bucket and organization exist
- Verify network connectivity to InfluxDB server

**Command not found: upsc:**
- Install Network UPS Tools: see Prerequisites section
- Verify `upsc` is in your PATH: `which upsc`

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Author

- **Author**: luddinho
- **Version**: 1.0.0
