#!/bin/bash
set -euo pipefail

LOGFILE="/root/setup_disk_setup.log"
exec >"$LOGFILE" 2>&1
echo "🔧 Starting filesystem + swap setup..."

# Map fixed devices to mount points (from your Packer HCL)
declare -A DEVICE_MAP=(
  ["/var"]="/dev/xvdb"
  ["/tmp"]="/dev/xvdc"
  ["/var/log"]="/dev/xvdd"
  ["/var/tmp"]="/dev/xvde"
  ["/usr"]="/dev/xvdf"
  ["/var/log/audit"]="/dev/xvdg"
  ["/home"]="/dev/xvdh"
  ["swap"]="/dev/xvdi"
)

# Secure mount options
declare -A MOUNT_OPTIONS=(
  ["/home"]="nodev,nosuid"
  ["/var"]="nodev,nosuid"
  ["/tmp"]="nodev,nosuid,noexec"
  ["/var/tmp"]="nodev,nosuid,noexec"
  ["/var/log"]="nodev,nosuid"
  ["/var/log/audit"]="nodev,nosuid"
  ["/usr"]="nodev"
)

# Ensure /var/log/audit exists
mkdir -p /var/log/audit

# Loop through all device mappings
for dir in "${!DEVICE_MAP[@]}"; do
  device="${DEVICE_MAP[$dir]}"
  label_name=$(echo "$dir" | sed 's|/|_|g; s|^_||')
  temp_mount="/mnt/$label_name"

  if [[ "$dir" == "swap" ]]; then
    echo "🌀 Setting up swap on $device"

    # Format swap if not already
    if ! blkid "$device" | grep -q "swap"; then
      mkswap -L "$label_name" "$device"
    fi

    # Enable swap immediately
    swapon "$device" || true

    # Add to fstab if not exists
    uuid=$(blkid -s UUID -o value "$device")
    if ! grep -q "UUID=$uuid" /etc/fstab; then
      echo "UUID=$uuid none swap sw,nofail 0 2" >> /etc/fstab
    fi

    # Set swappiness to 40
    sysctl -w vm.swappiness=40
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
      echo "vm.swappiness=40" >> /etc/sysctl.conf
    else
      sed -i 's/^vm.swappiness=.*/vm.swappiness=40/' /etc/sysctl.conf
    fi

    continue
  fi

  echo "📁 Setting up $dir on $device (label: $label_name)"

  mount_opts="${MOUNT_OPTIONS[$dir]:-defaults}"

  # Format if no filesystem exists
  if ! blkid "$device" >/dev/null 2>&1; then
    echo "🌀 Formatting $device as ext4"
    mkfs.ext4 -L "$label_name" "$device"
  else
    echo "🔖 Relabeling existing filesystem as $label_name"
    e2label "$device" "$label_name" || true
  fi

  mkdir -p "$temp_mount"
  mount "$device" "$temp_mount"

  echo "📦 Copying data from $dir → $temp_mount"
  rsync -aHAX "$dir/" "$temp_mount/"

  umount "$temp_mount"
  mkdir -p "$dir"
  mount -o "$mount_opts" "$device" "$dir"

  uuid=$(blkid -s UUID -o value "$device")
  if ! grep -q "UUID=$uuid" /etc/fstab; then
    echo "UUID=$uuid $dir ext4 $mount_opts 0 2" >> /etc/fstab
  fi
done

echo "✅ Filesystem + swap setup complete."
echo "🔁 Reboot recommended to fully apply all persistent mounts."
