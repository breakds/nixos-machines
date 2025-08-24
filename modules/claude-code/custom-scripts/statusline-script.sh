#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract basic session info
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // pwd')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# Initialize token counts
total_tokens=0
compaction_threshold=200000
percentage=0

# If transcript path exists, analyze it for token consumption
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    # Get file size as rough proxy for tokens (approximate 4 chars per token)
    file_size=$(wc -c < "$transcript_path" 2>/dev/null || echo "0")
    total_tokens=$((file_size / 4))
    
    # Calculate percentage toward compaction threshold
    if [[ $compaction_threshold -gt 0 ]]; then
        percentage=$(( (total_tokens * 100) / compaction_threshold ))
        if [[ $percentage -gt 100 ]]; then
            percentage=100
        fi
    fi
fi

# Format tokens with K/M suffixes
if [[ $total_tokens -ge 1000000 ]]; then
    token_display=$(printf "%.1fM" $(echo "scale=1; $total_tokens / 1000000" | bc -l))
elif [[ $total_tokens -ge 1000 ]]; then
    token_display=$(printf "%.1fK" $(echo "scale=1; $total_tokens / 1000" | bc -l))
else
    token_display="${total_tokens}"
fi

# Color coding based on compaction percentage
if [[ $percentage -ge 90 ]]; then
    color="\033[31m"  # Red
elif [[ $percentage -ge 70 ]]; then
    color="\033[33m"  # Yellow
else
    color="\033[32m"  # Green
fi
reset="\033[0m"

# Get current directory basename
dir_name=$(basename "$current_dir")

# Build status line
printf "${color}${model_name}${reset} ${dir_name} | ${token_display} tokens (${percentage}%% to compact)"
