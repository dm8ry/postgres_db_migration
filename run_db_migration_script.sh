#!/bin/sh

echo "Start"

export current_date_time="$(date +'%Y%m%d_%H%M%S')"

export output_trace="postgres_db_migration_traces/db_migration_${current_date_time}.trc"

nohup ./db_migration_script.sh > ./${output_trace} 2>&1 &

echo "End"
