#!/bin/bash

cp -r /usr/data/temp/pfc /usr/data/printer_data/config/
cp -r /usr/data/temp/display /usr/share/klipper/klippy/extras/

# Файл конфигурации
CONFIG_FILE="/usr/data/printer_data/config/printer.cfg"
INCLUDE_STRING_PFC="[include pfc/pfc.cfg]"

if ! grep -q '\[include pfc/pfc.cfg\]' /usr/data/printer_data/config/printer.cfg; then
    sed -i '/\[include printer_params.cfg\]/a [include pfc/pfc.cfg]' /usr/data/printer_data/config/printer.cfg
fi

echo "Done"
