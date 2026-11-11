#!/usr/bin/env bash
# Hypercube thermals reader, used by services/Thermals.qml.
#
# Reads hwmon sensors from sysfs (no root, no extra packages) and, when the
# NVIDIA driver is loaded, nvidia-smi. Prints one tab-separated record per line:
#
#   chip  <id> <category> <driver name> <title>       a sensor chip
#   temp  <id> <key> <label> <m°C> <max m°C> <crit m°C>  ("-" = not reported)
#   fan   <id> <label> <rpm>
#   stat  <id> <key> <value>                          load (%), power (W), fan (%), asleep
#
# `thermals.sh init` instead prints facts that don't change while running:
#
#   cpu    <model name>
#   board  <board vendor and name>
#   root   <nvme controller or block device the system runs from>
#   limit  <id> <target|max|crit> <m°C>               NVIDIA thermal limits
#
# Categories: cpu, gpu, storage, board, platform (battery, Wi-Fi, ACPI).

set -u

# Overridable for testing against a fake sysfs tree
SYS=${THERMALS_SYSFS:-/sys}

# Read the first line of a sysfs file into REPLY without forking.
# Fails (with REPLY empty) when the file is missing or the read errors,
# e.g. a GPU that is runtime-suspended.
rd() {
    REPLY=""
    [ -r "$1" ] || return 1
    read -r REPLY <"$1" 2>/dev/null || [ -n "$REPLY" ]
}

# NVIDIA GPUs that are runtime-suspended (hybrid laptops). Querying them with
# nvidia-smi would wake them up and drain the battery, so skip them.
nvidia_asleep() {
    local d found=0
    for d in "$SYS"/bus/pci/drivers/nvidia/0000:*; do
        [ -e "$d" ] || continue
        found=1
        rd "$d/power/runtime_status"
        [ "$REPLY" = "suspended" ] || return 1
    done
    [ "$found" = 1 ]
}

init() {
    local src disk

    if [ -r /proc/cpuinfo ]; then
        awk -F': *' '/^model name/ { print "cpu\t" $2; exit }' /proc/cpuinfo
    fi

    rd "$SYS"/class/dmi/id/board_vendor
    local vendor=$REPLY
    rd "$SYS"/class/dmi/id/board_name
    [ -n "$REPLY" ] && printf 'board\t%s\n' "${vendor:+$vendor }$REPLY"

    # bootc systems mount the real root filesystem at /sysroot
    src=$(findmnt -nvo SOURCE /sysroot 2>/dev/null || findmnt -nvo SOURCE / 2>/dev/null)
    if [ -n "$src" ]; then
        disk=$(lsblk -nsro NAME,TYPE "$src" 2>/dev/null | awk '$2 == "disk" { print $1; exit }')
        case "$disk" in
            nvme*n*) printf 'root\t%s\n' "${disk%n*}" ;;
            ?*) printf 'root\t%s\n' "$disk" ;;
        esac
    fi

    if command -v nvidia-smi >/dev/null 2>&1 && ! nvidia_asleep; then
        nvidia-smi -q -d TEMPERATURE 2>/dev/null | awk '
            /^GPU [0-9A-Fa-f]+:/ { gpu++ }
            function emit(kind, line,   v) {
                v = line; sub(/.*: */, "", v); sub(/ *C$/, "", v)
                if (v ~ /^[0-9]+$/) print "limit\tnvidia" (gpu - 1) "\t" kind "\t" v * 1000
            }
            /GPU Target Temperature/ { emit("target", $0) }
            /GPU Max Operating Temp/ { emit("max", $0) }
            /GPU Slowdown Temp/      { emit("crit", $0) }
        '
    fi
}

category() {
    case "$1" in
        k10temp | coretemp | zenpower | cpu_thermal | via_cputemp) CAT=cpu ;;
        amdgpu | radeon | nouveau | i915 | xe) CAT=gpu ;;
        nvme | drivetemp) CAT=storage ;;
        acpitz | BAT* | iwlwifi* | mt7* | ath1* | ath9* | rtw* | brcm* | r8169* | ucsi*) CAT=platform ;;
        *) CAT=board ;;
    esac
}

read_hwmon() {
    local c h hw id name title t base key label max crit f b blk
    declare -A nvme_of=()

    # nvme hwmon chips live under their controller: map hwmonN -> nvmeN
    for c in "$SYS"/class/nvme/nvme*; do
        [ -e "$c" ] || continue
        for h in "$c"/hwmon*; do
            [ -e "$h" ] && nvme_of[${h##*/}]=${c##*/}
        done
    done

    for hw in "$SYS"/class/hwmon/hwmon*; do
        rd "$hw/name" || continue
        name=$REPLY
        id=${hw##*/}
        category "$name"

        title=$name
        case "$name" in
            nvme)
                rd "$hw/device/model"
                title="${REPLY:-NVMe drive}"
                [ -n "${nvme_of[$id]:-}" ] && title="$title (${nvme_of[$id]})"
                ;;
            drivetemp)
                rd "$hw/device/model"
                title="${REPLY:-SATA drive}"
                blk=""
                for b in "$hw"/device/block/*; do
                    [ -e "$b" ] && blk=${b##*/}
                done
                [ -n "$blk" ] && title="$title ($blk)"
                ;;
            amdgpu)
                rd "$hw/device/product_name"
                title="${REPLY:-AMD GPU}"
                ;;
        esac
        printf 'chip\t%s\t%s\t%s\t%s\n' "$id" "$CAT" "$name" "$title"
        [ "$name" = nvme ] && [ -n "${nvme_of[$id]:-}" ] &&
            printf 'stat\t%s\tdevice\t%s\n' "$id" "${nvme_of[$id]}"
        [ -n "${blk:-}" ] && [ "$name" = drivetemp ] &&
            printf 'stat\t%s\tdevice\t%s\n' "$id" "$blk"

        for t in "$hw"/temp*_input; do
            [ -e "$t" ] || continue
            rd "$t" || continue
            base=${t%_input}
            key=${base##*/}
            local val=$REPLY
            rd "${base}_label"
            label=$REPLY
            rd "${base}_max"
            max=${REPLY:--}
            rd "${base}_crit"
            crit=${REPLY:--}
            printf 'temp\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$key" "$label" "$val" "$max" "$crit"
        done

        for f in "$hw"/fan*_input; do
            [ -e "$f" ] || continue
            rd "$f" || continue
            local rpm=$REPLY
            rd "${f%_input}_label"
            label=${REPLY:-}
            if [ -z "$label" ]; then
                key=${f##*/}
                key=${key%_input}
                label="Fan ${key#fan}"
            fi
            printf 'fan\t%s\t%s\t%s\n' "$id" "$label" "$rpm"
        done

        if [ "$name" = amdgpu ]; then
            rd "$hw/device/gpu_busy_percent" && printf 'stat\t%s\tload\t%s\n' "$id" "$REPLY"
            if rd "$hw/power1_average" || rd "$hw/power1_input"; then
                printf 'stat\t%s\tpower\t%s\n' "$id" "$((REPLY / 1000000))"
            fi
            if rd "$hw/pwm1" && [ -n "$REPLY" ]; then
                printf 'stat\t%s\tfan\t%s\n' "$id" "$((REPLY * 100 / 255))"
            fi
        fi
    done
}

read_nvidia() {
    command -v nvidia-smi >/dev/null 2>&1 || return 0

    if nvidia_asleep; then
        printf 'chip\tnvidia0\tgpu\tnvidia\tNVIDIA GPU\n'
        printf 'stat\tnvidia0\tasleep\t1\n'
        return 0
    fi

    local idx gname temp fan power load
    while IFS=',' read -r idx gname temp fan power load; do
        idx=${idx// /}
        [ -n "$idx" ] || continue
        gname=${gname# }
        temp=${temp// /}
        fan=${fan// /}
        power=${power// /}
        load=${load// /}
        printf 'chip\tnvidia%s\tgpu\tnvidia\t%s\n' "$idx" "$gname"
        [[ $temp =~ ^[0-9]+$ ]] &&
            printf 'temp\tnvidia%s\ttemp1\tGPU\t%s\t-\t-\n' "$idx" "$((temp * 1000))"
        [[ $load =~ ^[0-9]+$ ]] && printf 'stat\tnvidia%s\tload\t%s\n' "$idx" "$load"
        [[ $fan =~ ^[0-9]+$ ]] && printf 'stat\tnvidia%s\tfan\t%s\n' "$idx" "$fan"
        [[ $power =~ ^[0-9]+ ]] && printf 'stat\tnvidia%s\tpower\t%s\n' "$idx" "${power%%.*}"
    done < <(nvidia-smi --query-gpu=index,name,temperature.gpu,fan.speed,power.draw,utilization.gpu \
        --format=csv,noheader,nounits 2>/dev/null)
}

case "${1:-}" in
    init) init ;;
    *)
        read_hwmon
        read_nvidia
        ;;
esac
