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

# Copy extruder_stepper module
if [ -f "/usr/data/pfc/extruder_stepper.py" ]; then
    cp /usr/data/pfc/extruder_stepper.py /usr/share/klipper/klippy/extras/
    echo "Copied extruder_stepper.py"
else
    echo "Warning: extruder_stepper.py not found, skipping"
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
    # Ask if user wants to update rotation_distance
    echo ""
    read -p "Do you want to install/update ROTATION_DISTANCE_DEFAULT (current value: $ROTATION_DISTANCE_DEFAULT)? [y/N]: " UPDATE_ROTATION_DISTANCE
    UPDATE_ROTATION_DISTANCE=${UPDATE_ROTATION_DISTANCE:-N}
    
    # Ask if user wants to update driver_SGTHRS
    echo ""
    read -p "Do you want to install/update DRIVER_SGTHRS_DEFAULT (current value: $DRIVER_SGTHRS_DEFAULT)? [y/N]: " UPDATE_DRIVER_SGTHRS
    UPDATE_DRIVER_SGTHRS=${UPDATE_DRIVER_SGTHRS:-N}
    
    # Update rotation_distance for stepper_x
    if [ "$UPDATE_ROTATION_DISTANCE" = "y" ] || [ "$UPDATE_ROTATION_DISTANCE" = "Y" ]; then
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
        echo "Updated rotation_distance to $ROTATION_DISTANCE_DEFAULT for stepper_x and stepper_y"
    else
        echo "Skipped rotation_distance update"
    fi

    # Update driver_SGTHRS for tmc2209 stepper_x
    if [ "$UPDATE_DRIVER_SGTHRS" = "y" ] || [ "$UPDATE_DRIVER_SGTHRS" = "Y" ]; then
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
        echo "Updated driver_SGTHRS to $DRIVER_SGTHRS_DEFAULT for tmc2209 stepper_x and stepper_y"
    else
        echo "Skipped driver_SGTHRS update"
    fi
fi

echo ""
echo "Done"
if [ "$UPDATE_ROTATION_DISTANCE" = "y" ] || [ "$UPDATE_ROTATION_DISTANCE" = "Y" ]; then
    echo "Set rotation_distance to $ROTATION_DISTANCE_DEFAULT for stepper_x and stepper_y"
fi
if [ "$UPDATE_DRIVER_SGTHRS" = "y" ] || [ "$UPDATE_DRIVER_SGTHRS" = "Y" ]; then
    echo "Set driver_SGTHRS to $DRIVER_SGTHRS_DEFAULT for tmc2209 stepper_x and stepper_y"
fi
echo "To customize, set ROTATION_DISTANCE and/or DRIVER_SGTHRS environment variables before running this script"
