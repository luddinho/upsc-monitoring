#!/bin/bash
# Author: luddinho
VERSION="1.0.0"

# Initialize variables
dry_run=false

# --------------------------------------------------------------------------------
# Parse command-line arguments
# --------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            config_file="$2"
            shift 2
            ;;
        -n|--dry-run)
            dry_run=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-c|--config <config_file>] [-n|--dry-run]"
            echo ""
            echo "Options:"
            echo "  -c, --config <file>    Path to configuration file"
            echo "  -n, --dry-run          Print UPS values without sending to InfluxDB"
            echo "  -h, --help             Display this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done



# --------------------------------------------------------------------------------
# Load configuration from file if specified (overrides all command-line options)
# --------------------------------------------------------------------------------
if [ -n "$config_file" ]; then
    if [ ! -f "$config_file" ]; then
        echo "Error: Config file '$config_file' does not exist" >&2
        exit 1
    fi
    if [ ! -r "$config_file" ]; then
        echo "Error: Config file '$config_file' is not readable" >&2
        exit 1
    fi

    # Read config file and set variables
    # Format: key=value (one per line, # for comments)
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace from key and value
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Set variables based on key
        case "$key" in
            ups_host) ups_host="$value" ;;
            ups_port) ups_port="$value" ;;
            ups_name) ups_name="$value" ;;
            influx_server) influx_server="$value" ;;
            influx_port) influx_port="$value" ;;
            influx_bucket) influx_bucket="$value" ;;
            influx_org) influx_org="$value" ;;
            influx_token) influx_token="$value" ;;
            influx_token_file)
                if [ -f "$value" ] && [ -r "$value" ]; then
                    influx_token=$(cat "$value")
                else
                    echo "Error: Token file '$value' does not exist or is not readable" >&2
                    exit 1
                fi
                ;;
            *) echo "Warning: Unknown config key '$key' in config file, ignoring" >&2 ;;
        esac
    done < "$config_file"
fi

# -----------------------------------------------------------------------------
# Check if mandatory parameters are provided
# -----------------------------------------------------------------------------

# Skip InfluxDB validation in dry-run mode
if [ "$dry_run" = false ]; then
    # Check if InfluxDB server parameter is provided
    if [ -z "$influx_server" ]; then
        echo "Error: InfluxDB server URL (-s|--server) is required" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi

    # Check if InfluxDB port parameter is provided
    if [ -z "$influx_port" ]; then
        echo "Error: InfluxDB server port (-p|--port) is required" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi

    # Check if InfluxDB bucket name is provided
    if [ -z "$influx_bucket" ]; then
        echo "Error: InfluxDB bucket name (-b|--bucket) is required" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi

    # Check if InfluxDB organization name is provided
    if [ -z "$influx_org" ]; then
        echo "Error: InfluxDB organization name (-o|--org) is required" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi

    # Check if InfluxDB authentication token is provided (either directly or via file)
    if [ -z "$influx_token" ]; then
        echo "Error: InfluxDB authentication token (-a|--auth-token) or token file (-f|--auth-token-file) is required" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi
fi


# Collect data from upsc
DATA=$(upsc $ups_name@$ups_host:$ups_port 2>/dev/null)

# Parse relevant fields
battery_charge=$(echo "$DATA"           | grep "battery.charge:"            | grep -v "battery.charge.low" | awk '{print $2}')
battery_charge_low=$(echo "$DATA"       | grep "battery.charge.low:"        | awk '{print $2}')
battery_runtime=$(echo "$DATA"          | grep "battery.runtime:"           | awk '{print $2}')
input_frequency=$(echo "$DATA"          | grep "input.frequency:"           | awk '{print $2}')
input_transfer_high=$(echo "$DATA"      | grep "input.transfer.high:"       | awk '{print $2}')
input_transfer_low=$(echo "$DATA"       | grep "input.transfer.low:"        | awk '{print $2}')
input_voltage=$(echo "$DATA"            | grep "^input\.voltage:"           | awk '{print $2}')
input_voltage_extended=$(echo "$DATA"   | grep "input.voltage.extended:"    | awk '{print $2}')
output_frequency=$(echo "$DATA"         | grep "output.frequency:"          | grep -v "output.frequency.nominal" | awk '{print $2}')
output_frequency_nominal=$(echo "$DATA" | grep "output.frequency.nominal:"  | awk '{print $2}')
output_voltage=$(echo "$DATA"           | grep "output.voltage:"            | grep -v "output.voltage.nominal" | awk '{print $2}')
output_voltage_nominal=$(echo "$DATA"   | grep "output.voltage.nominal:"    | awk '{print $2}')
ups_beeper_status=$(echo "$DATA"        | grep "ups.beeper.status:"         | awk '{print $2}')
ups_delay_shutdown=$(echo "$DATA"       | grep "ups.delay.shutdown:"        | awk '{print $2}')
ups_delay_start=$(echo "$DATA"          | grep "ups.delay.start:"           | awk '{print $2}')
ups_load=$(echo "$DATA"                 | grep "ups.load:"                  | awk '{print $2}')
ups_power=$(echo "$DATA"                | grep "ups.power:"                 | grep -v "ups.power.nominal" | awk '{print $2}')
ups_power_nominal=$(echo "$DATA"        | grep "ups.power.nominal:"         | awk '{print $2}')
ups_realpower=$(echo "$DATA"            | grep "ups.realpower:"             | awk '{print $2}')
ups_status=$(echo "$DATA"               | grep "ups.status:"                | awk '{print $2}')
ups_timer_shutdown=$(echo "$DATA"       | grep "ups.timer.shutdown:"        | awk '{print $2}')
ups_timer_start=$(echo "$DATA"          | grep "ups.timer.start:"           | awk '{print $2}')


# -----------------------------------------------------------------------
# InfluxDB line protocol format:
# measurement,tag1=value1,tag2=value2 field1=value1,field2=value2 timestamp
# For our case:
# ups_status,host=hostname battery_charge=85,battery_charge_low=20,battery_runtime=120,input_frequency=50,input_transfer_high=240,input_transfer_low=200,input_voltage=230,output_frequency=50,output_frequency_nominal=50,output_voltage=230,output_voltage_nominal=230,ups_beeper_status="ON",ups_delay_shutdown=10,ups_delay_start=5,ups_load=50,ups_power=100,ups_power_nominal=120,ups_realpower=95,ups_status="OL",ups_timer_shutdown=30,ups_timer_start=15 1690000000000000000
# -----------------------------------------------------------------------
timestamp=$(date +%s%N) # Current time in nanoseconds
hostname=$(hostname)

# Build the fields string dynamically, skipping empty/missing fields and
# properly quoting string fields per InfluxDB line protocol spec.
fields=""
append_field() {
    local name="$1" value="$2" quoted="${3:-0}"
    [ -z "$value" ] && return
    [ -n "$fields" ] && fields="${fields},"
    if [ "$quoted" -eq 1 ]; then
        fields="${fields}${name}=\"${value}\""
    else
        fields="${fields}${name}=${value}"
    fi
}

append_field "battery_charge"           "$battery_charge"
append_field "battery_charge_low"       "$battery_charge_low"
append_field "battery_runtime"          "$battery_runtime"
append_field "input_frequency"          "$input_frequency"
append_field "input_transfer_high"      "$input_transfer_high"
append_field "input_transfer_low"       "$input_transfer_low"
append_field "input_voltage"            "$input_voltage"
append_field "input_voltage_extended"   "$input_voltage_extended"  1
append_field "output_frequency"         "$output_frequency"
append_field "output_frequency_nominal" "$output_frequency_nominal"
append_field "output_voltage"           "$output_voltage"
append_field "output_voltage_nominal"   "$output_voltage_nominal"
append_field "ups_beeper_status"        "$ups_beeper_status"       1
append_field "ups_delay_shutdown"       "$ups_delay_shutdown"
append_field "ups_delay_start"          "$ups_delay_start"
append_field "ups_load"                 "$ups_load"
append_field "ups_power"                "$ups_power"
append_field "ups_power_nominal"        "$ups_power_nominal"
append_field "ups_realpower"            "$ups_realpower"
append_field "ups_status"               "$ups_status"             1
append_field "ups_timer_shutdown"       "$ups_timer_shutdown"
append_field "ups_timer_start"          "$ups_timer_start"

if [ -z "$fields" ]; then
    echo "Error: No data received from UPS '${ups_name}@${ups_host}:${ups_port}'" >&2
    exit 1
fi

line="ups_status,host=$hostname $fields $timestamp"


# Send data to InfluxDB or print in dry-run mode
if [ "$dry_run" = true ]; then
    echo "=== DRY RUN MODE - No data sent to InfluxDB ==="
    echo ""
    echo "Hostname: $hostname"
    echo "Timestamp: $timestamp"
    echo ""
    echo "UPS Metrics:"
    echo "  Battery Charge: $battery_charge%"
    echo "  Battery Charge Low: $battery_charge_low%"
    echo "  Battery Runtime: $battery_runtime seconds"
    echo "  Input Frequency: $input_frequency Hz"
    echo "  Input Transfer High: $input_transfer_high V"
    echo "  Input Transfer Low: $input_transfer_low V"
    echo "  Input Voltage: $input_voltage V"
    echo "  Input Voltage Extended: $input_voltage_extended"
    echo "  Output Frequency: $output_frequency Hz"
    echo "  Output Frequency Nominal: $output_frequency_nominal Hz"
    echo "  Output Voltage: $output_voltage V"
    echo "  Output Voltage Nominal: $output_voltage_nominal V"
    echo "  UPS Beeper Status: $ups_beeper_status"
    echo "  UPS Delay Shutdown: $ups_delay_shutdown seconds"
    echo "  UPS Delay Start: $ups_delay_start seconds"
    echo "  UPS Load: $ups_load%"
    echo "  UPS Power: $ups_power VA"
    echo "  UPS Power Nominal: $ups_power_nominal VA"
    echo "  UPS Real Power: $ups_realpower W"
    echo "  UPS Status: $ups_status"
    echo "  UPS Timer Shutdown: $ups_timer_shutdown"
    echo "  UPS Timer Start: $ups_timer_start"
    echo ""
    echo "InfluxDB Line Protocol:"
    echo "$line"
else
    # Send data to InfluxDB using curl
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$influx_server:$influx_port/api/v2/write?org=$influx_org&bucket=$influx_bucket&precision=ns" \
        -H "Authorization: Token $influx_token" \
        -H "Content-Type: text/plain; charset=utf-8" \
        --data-binary "$line")
    if [ "$response" -ne 204 ]; then
        echo "Error: Failed to write data to InfluxDB (HTTP status code: $response)" >&2
        exit 1
    fi
fi
