#!/usr/bin/env bash

set -e

###############################################################################
readonly LOGGER_TAG="ethminer_watchdog"
###############################################################################
# nvidia flags
# kind of optimal for 1060 6GB
readonly POWER_LIMIT="${POWER_LIMIT:-78}"
readonly POWER_MIN="${POWER_MIN:-35}"
readonly FAN_SPEED="${FAN_SPEED:-58}"
readonly MEMORY_OFFSET="${MEMORY_OFFSET:-845}"
readonly CLOCK_OFFSET="${CLOCK_OFFSET:-80}"
###############################################################################
# nvidia-settings flags
readonly FLAGS="DISPLAY=:0 XAUTHORITY=/run/user/$(id --user gdm)/gdm/Xauthority"
readonly GPU="[gpu:0]"
# Old flags when using lightdm
#readonly FLAGS="DISPLAY=:1 XAUTHORITY=/var/run/lightdm/root/:0"
###############################################################################
# ethminer flags
readonly ETHMINER="${ETHMINER:-ethminer}"
readonly ETHMINER_POOL_URL="${ETHMINER_POOL_URL}"
readonly ETHMINER_OPTS="--farm-recheck 200 --cuda -P ${ETHMINER_POOL_URL}"
readonly ETHMINER_CMD="${ETHMINER} ${ETHMINER_OPTS}"
###############################################################################

print_usage(){
  echo "Run a watchdog on top of your ethminer."
  echo "Usage:"
  echo
  echo "  ./ethminer_watchdog.sh"
  echo
  echo "Required environment variables to set:"
  echo " * ETHMINER - path to ethminer binary; default: ethminer"
  echo " * ETHMINER_POOL_URL - pool URL to use"
}

die(){
  echo "ERROR: ${@}"
  exit 1
}

die_and_run(){
  echo "ERROR: ${@}"
  shift
  "${@}"
  exit 1
}

check_nvidia_smi(){
  nvidia-smi >/dev/null 2>&1 || \
    die_and_run "nvidia-smi not found or installed incorrectly" nvidia-smi
}

check_nvidia_settings(){
  nvidia-settings --help >/dev/null 2>&1 || \
    die_and_run "nvidia-settings not found or installed incorrectly" nvidia-settings --help
}

check_ethminer(){
  if [[ -z "${ETHMINER}" ]]; then
    die 'ETHMINER unset'
  fi
  "${ETHMINER}" --help >/dev/null 2>&1 || \
    die "ethminer not found or installed incorrectly"
}

check_envs(){
  for e in ETHMINER_POOL_URL; do
    if [[ -z "${!e}" ]]; then
      die "${e} is unset"
    fi
  done
}

set_memory_offset(){
  local offset
  readonly offset="${1}"
  sudo ${FLAGS} nvidia-settings -a "${GPU}/GPUMemoryTransferRateOffset[3]=${offset}"
}

set_clock_offset(){
  local offset
  readonly offset="${1}"
  sudo ${FLAGS} nvidia-settings -a "${GPU}/GPUGraphicsClockOffset[3]=${offset}"
}

set_fan_speed(){
  local speed
  readonly speed="${1}"
  sudo ${FLAGS} nvidia-settings -a "${GPU}/GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=${speed}"
}

turn_off_fan_control(){
  sudo ${FLAGS} nvidia-settings -a "${GPU}/GPUFanControlState=0"
}

set_power_limit() {
  local power
  readonly power="${1}"
  sudo nvidia-smi -i 0 --persistence-mode=1
  sudo nvidia-smi -i 0 -pl ${power}
}

get_current_power_usage() {
  for i in {1..5}
  do
    power=$(nvidia-smi -q -d POWER | grep 'Power Draw' | sed 's/[^0-9,.]*//g' | cut -d . -f 1)

    # If above the required limit then just return
    if (( ${power} > ${POWER_MIN} )); then
      echo ${power}
      return
    fi

    logger -t "${LOGGER_TAG}" \
      "`date`: Current power usage ${power} below the limit $POWER_MIN. Sleeping..."

    # Otherwise allow couple of times to recheck power draw
    sleep 3
  done

  echo ${power}
}

if [[ ${#} -eq 1 && "${1}" == "--help" ]]; then
  print_usage
  exit 0
fi

check_envs
check_ethminer
check_nvidia_smi
check_nvidia_settings
trap 'set_memory_offset 600; set_clock_offset 0; turn_off_fan_control; set_power_limit 120; exit' SIGTERM SIGINT

set_clock_offset "${CLOCK_OFFSET}"
set_memory_offset "${MEMORY_OFFSET}"
set_fan_speed "${FAN_SPEED}"
set_power_limit "${POWER_LIMIT}"

# start the miner...
${ETHMINER_CMD} & disown
sleep 5

# loop and check if it didn't hang
while :
do
  power_usage=$(get_current_power_usage)
  echo "Current power usage is ${power_usage}"

  # (( )) for arithmetic context
  # https://stackoverflow.com/a/18668580/675100

  if (( ${power_usage} < ${POWER_MIN} )); then
    logger -s -t "${LOGGER_TAG}" \
      "$(date): Current power usage is ${power_usage} < $POWER_MIN killing miner"

    # if ethminer is launched then kill it and sleep
    if [[ -n "$(ps -ef | grep ethminer | grep -v grep)" ]] ; then
      logger -s -t "${LOGGER_TAG}" "$(date): ethminer is running (but hung) - killing it..."
      killall ethminer
      sleep 4;
    fi

    ${ETHMINER_CMD} & disown
    sleep 20
  fi

  sleep 5;
done
