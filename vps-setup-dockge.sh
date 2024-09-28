#!/bin/bash

### ======== Settings ======== ###

dockge_compose=compose.yaml
dockge_compose_url=https://dockge.kuma.pet/compose.yaml?port=5001&stacksPath=%2Fopt%2Fstacks

### ======== Settings ======== ###

### -------- Functions -------- ###

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

curl "$dockge_compose_url" --output compose.yaml

# Start the panel on localhost
find_and_replace $dockge_compose "5001:5001" "127.0.0.1:5001:5001"

# Creating directories
mkdir -p /opt/stacks /opt/dockge 

# Copy the edited file to the working directory
cp ~/compose.yaml /opt/dockge

# Navigate to the working directory
cd /opt/dockge

# Let's go
docker compose up -d

# Print message to console
clear
docker ps