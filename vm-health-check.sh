#!/bin/bash

# Threshold value
THRESHOLD=60
STATE="Healthy"
EXPLAIN=false

# Check if the --explain argument is passed
if [[ "$1" == "--explain" ]]; then
  EXPLAIN=true
fi

# -------- CPU Usage --------
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
CPU_USAGE=$(echo "100 - $CPU_IDLE" | bc)
CPU_USAGE_INT=${CPU_USAGE%.*}

# -------- Memory Usage --------
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_USAGE=$(echo "scale=2; $MEM_USED*100/$MEM_TOTAL" | bc)
MEM_USAGE_INT=${MEM_USAGE%.*}

# -------- Disk Usage --------
DISK_USAGE=$(df / | grep / | awk '{print $5}' | sed 's/%//')

# -------- Health Check --------
REASONS=()

if [ "$CPU_USAGE_INT" -gt "$THRESHOLD" ]; then
  STATE="Not Healthy"
  REASONS+=("CPU usage is ${CPU_USAGE_INT}% (above ${THRESHOLD}%)")
fi

if [ "$MEM_USAGE_INT" -gt "$THRESHOLD" ]; then
  STATE="Not Healthy"
  REASONS+=("Memory usage is ${MEM_USAGE_INT}% (above ${THRESHOLD}%)")
fi

if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
  STATE="Not Healthy"
  REASONS+=("Disk usage is ${DISK_USAGE}% (above ${THRESHOLD}%)")
fi

# -------- Output --------
echo "VM Health Status: $STATE"

if $EXPLAIN; then
  echo "Detailed Usage:"
  echo "  CPU Usage   : ${CPU_USAGE_INT}%"
  echo "  Memory Usage: ${MEM_USAGE_INT}%"
  echo "  Disk Usage  : ${DISK_USAGE}%"
  echo ""

  if [ "$STATE" = "Healthy" ]; then
    echo "All resource usages are within safe limits (≤ ${THRESHOLD}%)."
  else
    echo "Reason(s):"
    for reason in "${REASONS[@]}"; do
      echo "  - $reason"
    done
  fi
fi
