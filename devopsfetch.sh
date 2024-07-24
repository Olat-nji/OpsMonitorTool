#!/bin/bash

# Directory containing logs
LOG_DIR="/var/log/devopsfetch" # Adjust this path as needed
Parameters="$@"

# Check if script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Please run again with sudo or as root user."
    exit 1
fi


# Function to get the log file path
get_log_file_path() {
    local service="$1"
    local log_dir="$LOG_DIR/$2"
    local log_file="$log_dir.log"

    # Create the directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    echo "$log_file"
}

# Function to execute a command and log its output
output_command() {
    local service_name=$1
    local command=$2
    local log_file_path=$3
    local service_full_name=$4

    local TEMP_FILE="/tmp/devopsfetch-$service_name.tmp"
    local PREVIOUS_OUTPUT="/tmp/devopsfetch-$service_name-previous_output.tmp"

    # Ensure temporary files exist
    if [ ! -f "$PREVIOUS_OUTPUT" ]; then
        touch "$PREVIOUS_OUTPUT"
    fi

    if [ ! -f "$TEMP_FILE" ]; then
        touch "$TEMP_FILE"
    fi

    # Execute the command and store its output in a temporary file
    eval "$command" >"$TEMP_FILE"
    echo "[$(date)] Running Commands..." >>"$log_file_path"

    # Check if the output has changed since the last execution
    if ! cmp -s "$TEMP_FILE" "$PREVIOUS_OUTPUT"; then
        # Log the new output
        echo "[$(date)] " >>"$log_file_path"
        echo "-------------------------------------------------" >>"$log_file_path"
        echo "$service_full_name" >>"$log_file_path"
        echo "-------------------------------------------------" >>"$log_file_path"
       sudo cat "$TEMP_FILE" >>"$log_file_path"
        echo "" >>"$log_file_path"
        echo "" >>"$log_file_path"

        # Update the previous output
        cp "$TEMP_FILE" "$PREVIOUS_OUTPUT"
    else
        echo "No Change Yet" >>"$log_file_path"
        echo "" >>"$log_file_path"
        echo "" >>"$log_file_path"
    fi

    # Print to screen
    echo "-------------------------------------------------"
    echo "$service_full_name"
    echo "-------------------------------------------------"
    cat "$TEMP_FILE"
}

# Function to handle the action when -p or --port is passed without a value
port_without_value() {
    local log_file_path=$(get_log_file_path "ports" "ports")
    local service_name="ports"

    local command=$(
        cat <<'EOF'
sudo lsof -i -P -n | grep LISTEN | awk '
BEGIN {
    print "+-----------------+-------------+----------------+------------------+-----------+---------+------------+"
    print "| Process Command | Process ID | Owner User      | File Descriptor  | Protocol  | Device  | Port       |"
    print "+-----------------+-------------+----------------+------------------+-----------+---------+------------+"
}
{
    printf "| %-15s | %-11s | %-14s | %-16s | %-9s | %-7s | %-10s |\n", $1, $2, $3, $4, $5, $8, $9
}
END {
    print "+-----------------+-------------+----------------+------------------+-----------+---------+------------+"
}'
EOF
    )

    output_command "$service_name" "$command" "$log_file_path" "Active Ports and Services"
}

# Function to handle the action when -p or --port is passed with a value
port_with_value() {
    local port_value=$1
    local service_name="port-$port_value"
    local log_file_path=$(get_log_file_path "ports" $service_name)

    # Validate port number
    if ! [[ "$port_value" =~ ^[0-9]+$ ]] || [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
        echo "Invalid port number '$port_value' passed"
        return 1
    fi

    # Command to execute
    local command=$(
        cat <<'EOF'
sudo lsof -i -P -n | grep LISTEN | grep ":$port_value" | awk '
BEGIN {
    print "+---------------+-------+----------------+------+-----------+---------+------------+"
    print "| Command       | PID   | User           | FD   | Type      | Device  | Port       |"
    print "+---------------+-------+----------------+------+-----------+---------+------------+"
}
{
    printf "| %-13s | %-5s | %-14s | %-4s | %-9s | %-7s | %-10s |\n", $1, $2, $3, $4, $5, $8, $9
}
END {
    print "+---------------+-------+----------------+------+-----------+---------+------------+"
}'
EOF
    )

    output_command "$service_name" "$command" "$log_file_path" "Information on Port $port_value"
}

# Function to handle the action when -d or --docker is passed without a value
docker_without_value() {
    local service_name="docker-images-and-containers"
    local log_file_path=$(get_log_file_path "docker" "docker")
    local command=""

    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed"
        return 1
    else
        command="
echo \"-------------------------------------------------\"    
echo \"Docker Containers:\"
echo \"-------------------------------------------------\"
docker ps -a
echo \"\"
echo \"-------------------------------------------------\"
echo \"-------------------------------------------------\"
echo \"\"
echo \"\"
"
    fi

    output_command "$service_name" "$command" "$log_file_path" "Docker Images & Containers"

}

docker_with_value() {
    local container_id_or_name=$1
    local service_name="$container_id_or_name-docker-container"
    local log_file_path=$(get_log_file_path "docker" $service_name)
    local command=""

    # Check if the specified container exists
    if ! docker inspect "$container_id_or_name" &>/dev/null; then
        echo "Container '$container_id_or_name' does not exist"
        return 1
    fi

    # Display detailed information about the specified container
    command="
# Fetch the container information
container_info=\$(docker inspect \"$container_id_or_name\" | jq '.[0]')

# Extract required fields
id=\$(echo \"\$container_info\" | jq -r '.Id')
name=\$(echo \"\$container_info\" | jq -r '.Name')
image=\$(echo \"\$container_info\" | jq -r '.Config.Image')
command=\$(echo \"\$container_info\" | jq -r '.Config.Cmd')
created=\$(echo \"\$container_info\" | jq -r '.Created')
state=\$(echo \"\$container_info\" | jq -r '.State | tojson')
ports=\$(echo \"\$container_info\" | jq -r '.NetworkSettings.Ports | tojson')

# Display the table
printf \"| %-10s | %-66s |\n\" \"Field\" \"Value\"
echo \"-------------------------------------------------\"
printf \"| %-10s | %-66s |\n\" \"ID\" \"\$id\"
printf \"| %-10s | %-66s |\n\" \"Name\" \"\$name\"
printf \"| %-10s | %-66s |\n\" \"Image\" \"\$image\"
printf \"| %-10s | %-66s |\n\" \"Command\" \"\$command\"
printf \"| %-10s | %-66s |\n\" \"Created\" \"\$created\"
printf \"| %-10s | %-66s |\n\" \"State\" \"\$state\"
printf \"| %-10s | %-66s |\n\" \"Ports\" \"\$ports\"
echo \"-------------------------------------------------\"
echo \"-------------------------------------------------\"
echo \"\"
echo \"\"
"

    # Capture and log command output
    output_command "$service_name" "$command" "$log_file_path" "Information on Docker Container -- $container_id_or_name"
}

# Function to handle the action when -n or --nginx is passed without a value
nginx_without_value() {
    local service_name="nginx"
    local log_file_path=$(get_log_file_path "nginx" "nginx")

    local command=""
    # Check if Nginx is installed
    if ! command -v nginx &>/dev/null; then
        echo "Nginx is not installed"
        return 1
    fi

    # Find all server blocks in the Nginx configuration
    command="
           
            sudo nginx -T 2>/dev/null | grep -E 'server_name|listen' | grep -vE '(#|syntax|successful|server_names_hash_bucket_size|server_name_in_redirect|SERVER_NAME)' | awk '
            /listen/ {
                port = \$2 ~ /[0-9]+/ ? \$2 : \$3 ~ /[0-9]+/ ? \$3 : \$2 ~ /\\[::\\]/ ? \$2 : \$3
            }
            /server_name/ {
                domain = \$2
                printf \"%-45s | %-5s\\n\", domain, port
            }' | sort | uniq | awk 'BEGIN {
                print \"Domains                                      | Ports\"
                print \"---------------------------------------------|-------\"
            }
            {print}'
            
            echo \"--------------------------------------------------\"
            echo \"--------------------------------------------------\"
            echo \"\"
            echo \"\"
            "

    output_command "$service_name" "$command" "$log_file_path" "Nginx Domains and their Ports"

}

# Function to handle the action when -n or --nginx is passed with a value
nginx_with_value() {
    local domain_name=$1
    local service_name="nginx-${domain_name}"
    local log_file_path=$(get_log_file_path "nginx" "$domain_name")
    local command=""

    # Check if Nginx is installed
    if ! command -v nginx &>/dev/null; then
        echo "Nginx is not installed"
        return 1
    fi

    # Capture the output of 'nginx -T'
    nginx_output=$(nginx -T 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Failed to retrieve Nginx configuration"
        return 1
    fi

    if echo "$nginx_output" | grep -q "$domain_name"; then
        command="
        
sudo nginx -T 2>&1 \
| grep -v 'nginx: the configuration file /etc/nginx/nginx.conf syntax is ok' \
| grep -v 'nginx: configuration file /etc/nginx/nginx.conf test is successful' \
| grep -Pzo '(?s)server\s*{[^{}]*(?:{[^{}]*}[^{}]*)*server_name\s+${domain_name};[^{}]*(?:{[^{}]*}[^{}]*)*}'

echo \"\"
echo \"--------------------------------------------------\"
echo \"--------------------------------------------------\"
echo \"\"
echo \"\"
"
    else
        command="echo \"Warning: Domain name '$domain_name' not found in nginx configuration.\""
    fi

    output_command "$service_name" "$command" "$log_file_path" "All Nginx configuration for $domain_name"

    # Add your action here
}

# Function to handle the action when -u or --users is passed without a value
users_without_value() {
    local service_name="users"
    local log_file_path=$(get_log_file_path "users" "users")

    local command=$(
        cat <<'EOF'
# Get a list of all real users, excluding system and service accounts
# Typically, real users have UID >= 1000
all_users=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 { print $1 }' | sort)

# Write the header to the log file
echo "Username        |          Last Login Time         |        Session Duration"
echo "----------------|----------------------------------|------------------------|"

# Loop through each user and get their login details
for user in $all_users; do
    # Check if the user has login records
    login_records=$(last -F $user | grep -v 'wtmp begins' | head -n 1)
    
    if [ -n "$login_records" ]; then
        last_login_time=$(echo "$login_records" | awk '{print $4, $5, $6, $7}')
        session_duration=$(echo "$login_records" | awk '{print $10}')
        if [ "$session_duration" == "logged" ]; then
            session_duration="Still logged in"
        fi
    else
        last_login_time="Never logged in"
        session_duration="N/A"
    fi
    
    printf "%-15s | %-30s | %-20s\n" "$user" "$last_login_time" "$session_duration"
done
EOF
    )

    # To execute the command
    output_command "$service_name" "$command" "$log_file_path" "User Login Information"

    # Add your action here
}

# Function to handle the action when -u or --users is passed with a value
users_with_value() {
    local user=$1
    local service_name="$user-information"
    local log_file_path=$(get_log_file_path "users" $service_name)

    command="(
    printf '%-20s %-30s\n' 'Field' 'Information'
    printf '%-20s %-30s\n' '-----' '-----------'

    # Username
    printf '%-20s %-30s\n' 'Username' '$user'

    # User ID
    uid=\$(id -u '$user')
    printf '%-20s %-30s\n' 'User ID (UID)' \$uid

    # All Groups
    groups=\$(id -Gn '$user' | tr ' ' ',')
    printf '%-20s %-30s\n' 'All Groups' \$groups

    # Home directory
    home_dir=\$(getent passwd '$user' | cut -d: -f6)
    printf '%-20s %-30s\n' 'Home Directory' \$home_dir

    # Shell
    shell=\$(getent passwd '$user' | cut -d: -f7)
    printf '%-20s %-30s\n' 'Shell' \$shell

    # Account creation date (on systems with chage)
    if command -v chage &>/dev/null; then
        # Get the account creation date for the user
        creation_date=\$(chage -l \"$user\" | grep 'Account created' | cut -d: -f2 | xargs)

        # Print the account creation date in a formatted manner
        printf '%-20s %-30s\n' 'Account Created' \"$creation_date\"

        # Last password change
        last_pass_change=\$(chage -l '$user' | grep 'Last password change' | cut -d: -f2 | xargs)
        printf '%-20s %-30s\n' 'Last Password Change' \"\$(echo \$last_pass_change | xargs)\"
    else
        printf '%-20s %-30s\n' 'Account Created' 'N/A'
        printf '%-20s %-30s\n' 'Last Password Change' 'N/A'
    fi

    # Last login time
    last_login=\$(last -F | awk -v user='$user' '\$1 == user {print \$4, \$5, \$6, \$7, \$8; exit}')
    if [ -n \"\$last_login\" ]; then
        formatted_date=\$(date -d \"\$last_login\" '+%Y-%m-%d %H:%M:%S')
        printf '%-20s %-30s\n' 'Last Login' \"\$formatted_date\"
    else
        printf '%-20s %-30s\n' 'Last Login' 'No data'
    fi
) || echo 'User $user does not exist.'



# Capture and log command output

"
    output_command "$service_name" "$command" "$log_file_path" "USER '$1' Information"

}

# Function to handle the action when -t or --time is passed with a value
time_with_value() {
    local START_DATE=$1
    local END_DATE=${2:-$START_DATE}

    # Validate date formats
    if ! date -d "$START_DATE" >/dev/null 2>&1; then
        echo "Invalid start date format. Please use YYYY-MM-DD."
        exit 1
    fi

    if ! date -d "$END_DATE" >/dev/null 2>&1; then
        echo "Invalid end date format. Please use YYYY-MM-DD."
        exit 1
    fi

    command=$(
        cat <<EOF
echo "-------------------------------------------------"
echo "Activities between $START_DATE 00:00:00 AND $END_DATE 23:59:59"
echo "-------------------------------------------------"
journalctl --since "$START_DATE 00:00:00" --until "$END_DATE 23:59:59"
EOF
    )
    eval "$command" | less
}

help() {
    echo "Usage: devopsfetch [options]"
    echo
    echo "Options:"
    echo "  -p, --port [port_number]        Display active ports and services, or information about a specific port."
    echo "  -d, --docker [container_id]     Display Docker images and containers, or detailed info about a specific container."
    echo "  -n, --nginx [domain_name]       Display Nginx server block configurations, or specific configuration for a domain."
    echo "  -u, --users [username]          Display user login times, or detailed information for a specific user."
    echo "  -t, --time start_date [end_date] Display all activities between the specified dates. End date defaults to start date."
    echo "  -h, --help                      Display this help message."

    echo
    echo "Examples:"
    echo "  devopsfetch --port                      # Display active ports and services."
    echo "  devopsfetch --port 8090                 # Display information about port 8090."
    echo "  devopsfetch --docker                    # Display Docker images and containers."
    echo "  devopsfetch --docker your_container     # Display information about the Docker container named 'your_container'."
    echo "  devopsfetch --nginx                     # Display Nginx server block configurations."
    echo "  devopsfetch --nginx domain.com          # Display Nginx configuration for 'domain.com'."
    echo "  devopsfetch --users                     # Display user login times."
    echo "  devopsfetch --users john_doe            # Display information for user 'Olatunji'."
    echo "  devopsfetch --time 2024-07-18           # Display all activities between the specified dates. End date defaults to start date."
    echo "  devopsfetch --time 2024-07-18 2024-07-22 # Display all activities between the specified dates. End date defaults to start date."
    echo "  devopsfetch --help                      # Display this help message."
}


# Check if any arguments are passed
if [ "$#" -eq 0 ]; then
    echo "Error: No options provided."
    exit 1
fi


# Function to prioritize the help argument
run_help_argument_as_a_priority() {
    for arg in "$@"; do
        case $arg in
        -h | --help)
            help
            exit 0
            ;;
        *) ;;
        esac
        shift
    done
}

# Function to process command-line arguments
run_help_argument_as_a_priority "$@"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -t | --time)
        if [[ -n $2 && $2 != -* ]]; then
            start_date="$2"
            if [[ -n $3 && $3 != -* ]]; then
                end_date="$3"
            else
                end_date="$start_date"
            fi
            time_with_value "$start_date" "$end_date"
            exit 0
        else
            echo "Please provide a start date and optionally an end date."
            exit 0
        fi
        ;;
    -p | --port)
        if [[ -n $2 && $2 != -* ]]; then
            port_with_value "$2"
            shift 2
        else
            port_without_value
            shift 1
        fi
        ;;
    -d | --docker)
        if [[ -n $2 && $2 != -* ]]; then
            docker_with_value "$2"
            shift 2
        else
            docker_without_value
            shift 1
        fi
        ;;
    -n | --nginx)
        if [[ -n $2 && $2 != -* ]]; then
            nginx_with_value "$2"
            shift 2
        else
            nginx_without_value
            shift 1
        fi
        ;;
    -u | --users)
        if [[ -n $2 && $2 != -* ]]; then
            users_with_value "$2"
            shift 2
        else
            users_without_value
            shift 1
        fi
        ;;
    *)
        echo "Unknown parameter passed: $1"
        help
        exit 1
        ;;
    esac
done

exit 0
