#!/bin/bash

### ======== Settings ======== ###

sshd_conf=/etc/ssh/sshd_config

passwd_conf="/etc/passwd"

install_apt_packages="nano micro mc curl wget jq tar unzip fontconfig sudo"

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

# Function that receives input from the user
function read_user_input {
    declare -n result=$2
    text=$1
    read -p "$text" result
}

# Function that receives the password from the user
function read_pass {
    declare -n result=$2
    text=$1
    unset result
    prompt="$text"
    while IFS= read -p "$prompt" -r -s -n 1 char
    do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    result+="$char"
    done
    echo
}

function message_at_the_end {
    # Get all users with the /bin/bash shell
    users_with_shell=$(cat /etc/passwd | grep /bin/bash)

    # Print message to console
    clear
    echo
    echo "User Created: $user_name" 
    echo "SSH port changed to: $ssh_port"
    echo
    echo Users with the correct shell:
    echo
    echo $users_with_shell
    echo

    # Check the user groups and output the result to the console
    groups_to_check=("sudo" "docker")

    for group in "${groups_to_check[@]}"; do
        if id -nG "$user_name" | grep -qw "$group"; then
            echo "$user_name is a member of group $group"
        else
            echo "Error: $user_name is NOT a member of group $group"
        fi
    done

    # Print message to console
    echo
    echo String for connection:
    echo
    echo ssh $user_name@$servIp -p $ssh_port
    echo
}

### -------- Functions -------- ###

# Find out the public ip address of the server and pass it to the variable
pub_ipv4=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
servIp=$(echo "$pub_ipv4" | tr -d '"')

clear

# Getting new user name
read_user_input "New user -> login: " "user_name"

# Getting new user password
read_pass "New user -> password: " "user_pass"

# Installing system updates
apt update && apt upgrade -y

# Install the packages specified in the settings
apt install -y $install_apt_packages

# Add a user
adduser --disabled-password --comment "" $user_name

# Set a password for the created user
echo "$user_name:$user_pass" | chpasswd

# Add the created user to the sudo group
usermod -aG sudo $user_name

# Set a password for the created user
echo "$user_name:$user_pass" | chpasswd

# Set the password for the root user
echo "root:$user_pass" | chpasswd

# Deny root user ssh login
find_and_replace $sshd_conf "PermitRootLogin yes" "PermitRootLogin no"

# Restart the service to apply the changes
systemctl restart ssh

# Generate the port number for ssh and save it to a file
ssh_port=$(shuf -i 50321-65535 -n 1)
echo $ssh_port > /home/$user_name/ssh-port.txt

# Change the ssh port to a non-standard one
find_and_replace $sshd_conf "#Port 22" "Port ${ssh_port}"

# Restart the service to apply the changes
systemctl restart ssh

# Configure the firewall
apt install -y ufw
ufw allow $ssh_port/tcp
ufw allow http
ufw allow https
ufw reload

# Installing docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $user_name

# Print message to console
message_at_the_end

read -p "Press Enter to continue..."

# Enabling the firewall
systemctl start ufw
ufw --force enable

# Disable the root account
passwd -l root

# Change the root shell
find_and_replace $passwd_conf "root:x:0:0:root:\x2Froot:\x2Fbin\x2Fbash" "root:x:0:0:root:\x2Froot:\x2Fsbin\x2Fnologin"

# Print message to console
message_at_the_end
