#!/bin/bash

source src/init.sh

for script in src/install/*.sh; do
  if [ -f "$script" ]; then
    echo "Executing $script..."
    bash "$script"
    if [ $? -ne 0 ]; then
      echo "Error executing $script"
      exit 1
    fi
  fi
done

echo "Installation complete"
