#!/bin/bash

# Date for backup suffix
now=$(date +%d%b%Y-%H%M)

DEVOPS_USER="devops"
DEVOPS_GROUP="devops"
password="today@1234"

exp() {
    expect <<EOF
    spawn passwd $DEVOPS_USER
    expect "Enter new UNIX password:"
    send "$password\r"
    expect "Retype new UNIX password:"
    send "$password\r"
    expect eof
EOF
    echo "Password for user $DEVOPS_USER updated successfully - adding to sudoers file now"
}

setup_pass() {
    os_type=$1

    case "$os_type" in
        sles)
            if ! command -v expect &>/dev/null; then
                zypper install -y expect
            fi
            ;;
        ubuntu)
            if ! command -v expect &>/dev/null; then
                apt-get update && apt-get install -y expect
            fi
            ;;
        amzn|centos)
            if ! command -v expect &>/dev/null; then
                yum install -y epel-release expect
            fi
            ;;
        *)
            echo "Unsupported OS type: $os_type"
            return 1
            ;;
    esac

    exp
}

update_conf() {
    local sudoers_file="/etc/sudoers"
    local sshd_config="/etc/ssh/sshd_config"

    # Backup and update sudoers file
    if [ -f "$sudoers_file" ]; then
        cp -p "$sudoers_file" "/home/backup/sudoers-$now"
        if ! grep -q "$DEVOPS_USER" "$sudoers_file"; then
            echo "$DEVOPS_USER ALL=(ALL) NOPASSWD: ALL" >> "$sudoers_file"
            echo "Added $DEVOPS_USER to sudoers file"
        else
            echo "$DEVOPS_USER already in sudoers file"
        fi
    else
        echo "Sudoers file not found"
    fi

    # Backup and update sshd_config
    if [ -f "$sshd_config" ]; then
        cp -p "$sshd_config" "/home/backup/sshd_config-$now"
        
        # Update ClientAliveInterval and PasswordAuthentication
        sed -i.bak '/^ClientAliveInterval/d' "$sshd_config"
        echo "ClientAliveInterval 240" >> "$sshd_config"
        
        sed -i.bak '/^PasswordAuthentication /d' "$sshd_config"
        echo "PasswordAuthentication yes" >> "$sshd_config"
        
        echo "Updated sshd_config and restarting SSH service"
        service sshd restart
    else
        echo "sshd_config not found"
    fi
}

############### MAIN ###################

# Determine OS name
if [ -f /etc/os-release ]; then
    osname=$(awk -F= '/^ID=/{print $2}' /etc/os-release | tr -d '"')
    echo "Operating System: $osname"
else
    echo "Cannot locate /etc/os-release - unable to determine OS"
    exit 8
fi

case "$osname" in
  sles|amzn|ubuntu|centos)
     userdel -r "$DEVOPS_USER" &>/dev/null
     groupdel "$DEVOPS_GROUP" &>/dev/null
     sleep 3
     groupadd "$DEVOPS_GROUP"
     useradd "$DEVOPS_USER" -m -d "/home/$DEVOPS_USER" -s /bin/bash -g "$DEVOPS_GROUP"
     setup_pass "$osname"
     update_conf
    ;;
  *)
    echo "Unsupported OS: $osname"
    ;;
esac

exit 0
