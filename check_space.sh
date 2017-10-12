#!/bin/bash
REQUIRED_SPACE_GB=15
AVAILABLE_SPACE_GB=`df -B 1G / | tail -n 1 | awk '{ print $4 }'`

if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
    echo "Insufficient space.";
    echo "$REQUIRED_SPACE_GB required, but only $AVAILABLE_SPACE_GB available.";
    exit 1;
fi
