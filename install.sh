#!/bin/bash

# Default values (can be overridden by environment variables)
ROTATION_DISTANCE_DEFAULT=${ROTATION_DISTANCE:-40}
DRIVER_SGTHRS_DEFAULT=${DRIVER_SGTHRS:-100}

cp -r /usr/data/pfc/pfc /usr/data/printer_data/config/
cp -r /usr/data/pfc/display /usr/share/klipper/klippy/extras/

# Copy filament sensor modules
if [ -f "/usr/data/pfc/filament_motion_sensor.py" ]; then
    cp /usr/data/pfc/filament_motion_sensor.py /usr/share/klipper/klippy/extras/
    echo "Copied filament_motion_sensor.py"
else
    echo "Warning: filament_motion_sensor.py not found, skipping"
fi

if [ -f "/usr/data/pfc/filament_switch_sensor.py" ]; then
    cp /usr/data/pfc/filament_switch_sensor.py /usr/share/klipper/klippy/extras/
    echo "Copied filament_switch_sensor.py"
else
    echo "Warning: filament_switch_sensor.py not found, skipping"
fi

CONFIG_FILE="/usr/data/printer_data/config/printer.cfg"
INCLUDE_STRING_PFC="[include pfc/pfc.cfg]"

# Create backup of config file before any modifications
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Created backup: $BACKUP_FILE"
else
    echo "Warning: Config file $CONFIG_FILE not found. Skipping backup and modifications."
fi

if [ -f "$CONFIG_FILE" ] && ! grep -q '\[include pfc/pfc.cfg\]' "$CONFIG_FILE"; then
    sed -i '/\[include printer_params.cfg\]/a [include pfc/pfc.cfg]' "$CONFIG_FILE"
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Warning: Config file $CONFIG_FILE not found. Skipping parameter updates."
else
    # Update rotation_distance for stepper_x
    if grep -q '^\[stepper_x\]' "$CONFIG_FILE"; then
        if grep -A 15 '^\[stepper_x\]' "$CONFIG_FILE" | grep -q 'rotation_distance:'; then
            sed -i '/^\[stepper_x\]/,/^\[/{s/^[[:space:]]*rotation_distance:[[:space:]]*.*/rotation_distance: '"$ROTATION_DISTANCE_DEFAULT"'/}' "$CONFIG_FILE"
        else
            # Find microsteps line and add after it (only first occurrence in section)
            awk -v rd="$ROTATION_DISTANCE_DEFAULT" '
                /^\[stepper_x\]/ {in_section=1; added=0}
                /^\[/ && !/^\[stepper_x\]/ && in_section {in_section=0}
                in_section && /^[[:space:]]*microsteps:/ && !added {
                    print; print "rotation_distance: " rd; added=1; next
                }
                {print}
            ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi

    # Update rotation_distance for stepper_y
    if grep -q '^\[stepper_y\]' "$CONFIG_FILE"; then
        if grep -A 15 '^\[stepper_y\]' "$CONFIG_FILE" | grep -q 'rotation_distance:'; then
            sed -i '/^\[stepper_y\]/,/^\[/{s/^[[:space:]]*rotation_distance:[[:space:]]*.*/rotation_distance: '"$ROTATION_DISTANCE_DEFAULT"'/}' "$CONFIG_FILE"
        else
            # Find microsteps line and add after it (only first occurrence in section)
            awk -v rd="$ROTATION_DISTANCE_DEFAULT" '
                /^\[stepper_y\]/ {in_section=1; added=0}
                /^\[/ && !/^\[stepper_y\]/ && in_section {in_section=0}
                in_section && /^[[:space:]]*microsteps:/ && !added {
                    print; print "rotation_distance: " rd; added=1; next
                }
                {print}
            ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi

    # Update driver_SGTHRS for tmc2209 stepper_x
    if grep -q '^\[tmc2209 stepper_x\]' "$CONFIG_FILE"; then
        if grep -A 20 '^\[tmc2209 stepper_x\]' "$CONFIG_FILE" | grep -q 'driver_SGTHRS:'; then
            sed -i '/^\[tmc2209 stepper_x\]/,/^\[/{s/^[[:space:]]*driver_SGTHRS:[[:space:]]*.*/driver_SGTHRS: '"$DRIVER_SGTHRS_DEFAULT"'/}' "$CONFIG_FILE"
        else
            # Find diag_pin line and add after it (only first occurrence in section)
            awk -v sgthrs="$DRIVER_SGTHRS_DEFAULT" '
                /^\[tmc2209 stepper_x\]/ {in_section=1; added=0}
                /^\[/ && !/^\[tmc2209 stepper_x\]/ && in_section {in_section=0}
                in_section && /^[[:space:]]*diag_pin:/ && !added {
                    print; print "driver_SGTHRS: " sgthrs; added=1; next
                }
                {print}
            ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi

    # Update driver_SGTHRS for tmc2209 stepper_y
    if grep -q '^\[tmc2209 stepper_y\]' "$CONFIG_FILE"; then
        if grep -A 20 '^\[tmc2209 stepper_y\]' "$CONFIG_FILE" | grep -q 'driver_SGTHRS:'; then
            sed -i '/^\[tmc2209 stepper_y\]/,/^\[/{s/^[[:space:]]*driver_SGTHRS:[[:space:]]*.*/driver_SGTHRS: '"$DRIVER_SGTHRS_DEFAULT"'/}' "$CONFIG_FILE"
        else
            # Find diag_pin line and add after it (only first occurrence in section)
            awk -v sgthrs="$DRIVER_SGTHRS_DEFAULT" '
                /^\[tmc2209 stepper_y\]/ {in_section=1; added=0}
                /^\[/ && !/^\[tmc2209 stepper_y\]/ && in_section {in_section=0}
                in_section && /^[[:space:]]*diag_pin:/ && !added {
                    print; print "driver_SGTHRS: " sgthrs; added=1; next
                }
                {print}
            ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        fi
    fi
fi

echo "Done"
echo "Set rotation_distance to $ROTATION_DISTANCE_DEFAULT for stepper_x and stepper_y"
echo "Set driver_SGTHRS to $DRIVER_SGTHRS_DEFAULT for tmc2209 stepper_x and stepper_y"
echo "To customize, set ROTATION_DISTANCE and/or DRIVER_SGTHRS environment variables before running this script"
