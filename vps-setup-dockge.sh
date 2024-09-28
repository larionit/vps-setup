#!/bin/bash

### ======== Settings ======== ###

dockge_compose=compose.yaml
dockge_compose_url="https://dockge.kuma.pet/compose.yaml?port=5001&stacksPath=%2Fopt%2Fstacks"

# Link to this script (needed in case of privilege escalation via sudo)
script_url=https://raw.githubusercontent.com/larionit/vps-setup/refs/heads/main/vps-setup-dockge.sh

### ======== Settings ======== ###

### -------- Functions -------- ###

# Privilege escalation function
function elevate {
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run with superuser privileges. Trying to elevate privileges with sudo."
        exec sudo bash "$0" "$@"
        exit 1
    fi
}

# Privilege escalation function (if the script is run with a command like: "bash <(curl https://domain.name/script.sh)")
function elevate_curl {
    if [[ "$EUID" -ne 0 ]]; then
        echo "[Started using curl] This script must be run with superuser privileges. Trying to elevate privileges with sudo."
        temp_script=$(mktemp)
        curl -fsSL "$script_url" -o "$temp_script"
        exec sudo bash "$temp_script" "$@"
        exit 1
    fi
}

# Find and replace function
function find_and_replace {
    target=$1
    find=$2
    replace=$3
    time=$(date +%G_%m_%d-%H_%M_%S)
    cp $target $target.bk_$time
    sed -i "s/${find}/${replace}/g" $target
}

### -------- Functions -------- ###

### -------- Preparation -------- ###

# Define the directory where this script is located
script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Define the name of this script
script_name=$(basename "$0")

# Defining the directory name and script name if the script is launched via a symbolic link located in /usr/local/bin
if [[ "$script_dir" == *"/usr/local/bin"* ]]; then
    real_script_path=$(readlink ${0})
    script_dir="$( cd -- "$(dirname "$real_script_path")" >/dev/null 2>&1 ; pwd -P )"
    script_name=$(basename "$real_script_path")
fi

# Path to this script
script_path="${script_dir}/${script_name}"

# Path to this script with escaped slashes (for sed)
script_path_sed=$(echo "$script_path" | sed 's/\//\\\//g')

# Path to log file
logfile_path="${script_dir}/${script_name%%.*}.log"

# For console output
echo_tab='     '
show_ip=$(hostname -I)

# Set the flag file name and location
flag_file_resume_after_reboot="${script_dir}/resume-after-reboot-${script_name%%.*}"

# Get user name
script_was_started_by=$(logname)

# Path to .bashrc
bashrc_file="/home/${script_was_started_by}/.bashrc"

# Privilege escalation
if [[ "$script_dir" = *"/proc"* ]]; then
    elevate_curl
else
    elevate
fi

### -------- Preparation -------- ###

# Creating directories
mkdir -p /opt/stacks /opt/dockge 

# Navigate to the working directory
cd /opt/dockge

curl "$dockge_compose_url" --output compose.yaml

# Start the panel on localhost
find_and_replace $dockge_compose "5001:5001" "127.0.0.1:5001:5001"

# Copy the edited file to the working directory
cp ~/compose.yaml /opt/dockge

# Let's go
docker compose up -d

# Print message to console
docker ps