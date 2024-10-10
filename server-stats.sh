#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
DarkGray='\033[1;30m'     # DarkGray

cpu_utilization() {
    total_percentage=$(ps -e -o pcpu --no-headers | awk '{s+=$1} END {print s}');

    cpu_count=$(grep -c ^processor /proc/cpuinfo)

    percentage=$(awk "BEGIN {printf \"%.2f\", $total_percentage / $cpu_count}")

    printf " ${Cyan}CPU${Color_Off}"
    echo_progress_bar "$percentage"
    printf "\n"
}

mem_utilization() {
    percentage=$(ps -e -o pmem --no-headers | awk '{s+=$1} END {print s}')

    available=$(awk '/MemAvailable/ {print $2"K"}' /proc/meminfo | numfmt --from=iec --to=iec-i)
    total=$(awk '/MemTotal/ {print $2"K"}' /proc/meminfo | numfmt --from=iec --to=iec-i)

    printf " ${Cyan}RAM${Color_Off}"
    echo_progress_bar "$percentage"
    printf " ${Cyan}Available $White$available ${Cyan}Total $White$total$Color_Off"
    printf "\n"
}

disk_usage() {
    available=$(df -h / --output=avail | tail -n 1)
    percentage=$(df -h / --output=pcent | tail -n 1 | sed 's/%//g')
    used=$(df -h / --output=used | tail -n 1)
    printf "${Cyan}DISK${Color_Off}"
    echo_progress_bar "$percentage"
    printf " ${Cyan}Available $White$available ${Cyan}Used $White$used$Color_Off"
    printf "\n"
}

top_5_process_cpu() {
    ps -e -o pcpu,comm --sort=-pcpu | head -n 6 | tail -n 5
}

top_5_process_mem() {
    ps -e -o pmem,comm --sort=-pmem | head -n 6 | tail -n 5
}

echo_top_5_process_cpu() {
    printf "${Cyan}%-36s${Color_Off}\n" "Top 5 CPU Processes"
    awk '{ printf "%-7s %-29s\n", " "$1"%", $2 }' <(top_5_process_cpu)
}

echo_top_5_process_mem() {
    printf "${Cyan}%-36s${Color_Off}\n" "Top 5 RAM Processes"
    awk '{ printf "%-7s %-29s\n", " "$1"%", $2 }' <(top_5_process_mem)
}

echo_top_5_process_side_by_side() {
    printf "${Cyan}%-36s %-36s${Color_Off}\n" "Top 5 CPU Processes" "Top 5 RAM Processes"
    paste <(top_5_process_cpu) <(top_5_process_mem) | awk '{ printf "%-7s %-29s %-6s %-30s\n", " "$1"%", $2, $3"%", $4 }'
}

echo_current_users() {
    users=$(who | wc -l)
    printf "${Cyan}%-36s${Color_Off}\n" "Current Users"
    printf "%-7s %-29s\n" " $users", "$(who | awk '{print $1}' | sort | uniq)"
}

echo_progress_bar() {
    percentage=$(printf '%.0f\n' $1)
    bar_count=$((percentage / 2))

    if [ $bar_count -lt 35 ]; then
        color=$Green
    elif [ $bar_count -lt 45 ]; then
        color=$Yellow
    else
        color=$Red
    fi

    printf "$White[$color"
    printf '%*s' "$bar_count" '' | tr ' ' '|'
    printf '%*s' $((50 - bar_count)) ' '
    printf "$DarkGray$percentage%%$White]$Color_Off"
}

usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, --cpu       Show CPU utilization"
    echo "  -m, --mem       Show memory utilization"
    echo "  -d, --disk      Show disk usage"
    echo "  -t, --top       Show top 5 processes by CPU and memory usage side by side"
    echo "  --top_ram       Show top 5 processes by memory usage"
    echo "  --top_cpu       Show top 5 processes by CPU usage"
    echo "  -u, --users     Show current users"
    echo "  -h, --help      Show this help message"
}

if [ $# -eq 0 ]; then
    cpu_utilization
    mem_utilization
    disk_usage
    printf "\n"
    echo_top_5_process_side_by_side
    echo_current_users
fi

while [ $# -gt 0 ]; do
    case $1 in
        -c|--cpu)
            cpu_utilization
            ;;
        -m|--mem)
            mem_utilization
            ;;
        -d|--disk)
            disk_usage
            ;;
        -t|--top)
            echo_top_5_process_side_by_side
            ;;
        --top_ram)
            echo_top_5_process_mem
            ;;
        --top_cpu)
            echo_top_5_process_cpu
            ;;
        -u|--users)
            echo_current_users
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Invalid argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

exit 0