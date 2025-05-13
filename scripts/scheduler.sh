#!/bin/sh

# Entrypoint.sh will run with root privileges!
# This is required to set up the scheduled execution of `update.sh`
# Switching back to the updater user at the end

# Check if a scheduled time is set
if [ -z "${SCHEDULED_TIME}" ]; then
    echo "No time schedule selected - proceeding with an instant run..."
    exec sh update.sh
    exit 0
fi

# Scheduler loop
while true
do
    # Check if scheduled time is valid
    if ! date -d "${SCHEDULED_TIME}" "+%Y-%m-%d" >/dev/null 2>&1; then
        echo "Error: Time-schedule is invalid"
        exit 1
    fi

    # Compare both dates in seconds
    CURRENT_TIME=$(date +%s)
    SCHEDULED_TIME_SECONDS=$(date -d "${SCHEDULED_TIME}" +%s)
    difference=$((SCHEDULED_TIME_SECONDS - CURRENT_TIME))

    # If timestamp is negative (past), schedule it for tomorrow
    if [ "$difference" -lt 0 ]; then
        difference=$((difference + 86400))  # Add 24 hours
    fi

    # Ensure difference is valid
    if [ "$difference" -ge 0 ]; then
        NEXT_RUN_TIME=$(date -d "@$((CURRENT_TIME + difference))" +"%Y-%m-%d %H:%M:%S")
        echo "Waiting for next schedule on: $NEXT_RUN_TIME"

        sleep "$difference"  # Sleep until scheduled time
        echo "Starting scheduled update at $(date)"
        exec sh update.sh
    else
        echo "Error: Time-schedule is not a valid future timestamp"
        exit 1
    fi
done
