#!/bin/bash

if [ ! -n "${SCHEDULED_TIME}" ]; then
    echo "No time schedule selected - proceeding with a instant run..."
    /bin/bash update.sh
    exit 0
fi

# Scheduler loop
while true
do
    # Check if any error occurs during date test conversion
    date -d "${SCHEDULED_TIME}" "+%Y-%m-%d" >/dev/null 2>&1
	if [ ! $? -eq 0 ]; then
        echo "Error: Time-schedule is invalid"
        exit 1
    fi

    # Compare both dates in seconds
    difference=$(($(date -d "${SCHEDULED_TIME}" +%s) - $(date +%s)))
    # Check if timestamp is past 24h - if so, add 
    if [ $difference -lt 0 ]; then
        difference=$((difference + 86400))  # Add 24h -> schedule for tomorrow
    fi

    # Check if difference is valid (in the future) now  -> "difference >= 0"
    if [ $difference -ge 0 ]; then
        seconds=$((difference + $(date +%s)))
        echo "Waiting for next schedule on: $(date -d @$seconds +"%Y-%m-%d %H:%M:%S")"
        
        sleep $((difference))   # Sleep until timestamp matches
        echo "Starting scheduled update at ${date}"
        /bin/bash update.sh
    else
        echo "Error: Time-schedule cant be read as future timestamp"
        exit 1
    fi
done

