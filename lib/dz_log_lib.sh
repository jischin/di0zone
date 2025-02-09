#!/bin/bash

declare -rA LEVELS=(
    ["OK"]="\e[2;92mOK\e[0m"
    ["SUCCESS"]="\e[2;92mSUCCESS:\e[0m"
    ["INFO"]="\e[2;92mINFO:\e[0m"
    ["WARNING"]="\e[2;93mWARNING!\e[0m"
    ["ERROR"]="\e[0;91mERROR:\e[0m"
    ["FATAL"]="\e[5;91m!FATAL!\e[0m"
    ["CRASH"]="\e[5;91m!CRASH!\e[0m"
    ["CHECK"]="\e[2;92mCHECK\e[0m"
    ["TEST"]="\e[2;92mTEST:\e[0m"
    ["SYNC"]="\e[2;92mSYNC:\e[0m"
    ["PUSH"]="\e[2;92mPUSH:\e[0m"
    ["PULL"]="\e[2;92mPULL:\e[0m"
    ["PUXX"]="\e[0;91mPULL:\e[0m"
)

: "${LOG_FILE:="/tmp/dz_project.log"}"
[ -d "${LOG_FILE%/*}" ] || mkdir -p "${LOG_FILE%/*}"
exec 3>>"${LOG_FILE}" 2>&3

function dlog() {
    local STATUS
    IFS=':' read -ra STATUS <<< "$1"
    local -u ACTION="${STATUS[0]}"
    local -u LEVEL="${STATUS[1]:-"OK"}"
    local -u ARG="${STATUS[2]:-"NONE"}"
    local MESSAGE="${2}"
    local -rA ACTIONS=(
        ["OK"]="\e[2;92m${ACTION}\e[0m"
        ["WARNING"]="\e[2;93m${ACTION}\e[0m"
        ["ERROR"]="\e[0;91m${ACTION}\e[0m"
        ["FATAL"]="\e[5;91m${ACTION}\e[0m"
    )
    case "${ACTION}" in
        "CHECK"|"TEST"|"SYNC"|"PULL"|"PUSH")
            echo -en "${ACTIONS[${LEVEL}]} ${MESSAGE}\e[2m "
            ;;
        "STATUS"|"INFO")
            echo -e "${LEVELS[${LEVEL}]} ${MESSAGE}\e[2m"
            ;;
        "PAUSE"|"STOP"|"EXIT")
            echo -e "${ACTIONS[${LEVEL}]} ${MESSAGE}\e[2m"
            if [[ "${ARG}" =~ ^[[:digit:]]+$ ]]; then
                read -rsn 1 -t "${ARG}" \
                -p "Для продолжения нажмите <Enter> (${ARG} секунд)..." 2>&1
            else
                read -rsn 1 -p "Для продолжения нажмите <Enter>..." 2>&1
            fi
            echo -e "\e[0m"
            ;;
        *)
            echo -e "${ACTIONS[${LEVEL}]} ${MESSAGE}\e[2m "
            ;;
    esac
    echo "$(date +%r) ${ACTION}:${LEVEL}: ${MESSAGE}" >&3
    return 0
}
