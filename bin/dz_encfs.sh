#!/bin/bash

PROJECT_NAME="Di0Zone"
APP_NAME="dz_encfs"

LOG_FILE="/dev/null"
. "${HOME}/.local/share/${PROJECT_NAME}/lib/dz_log_lib.sh"
. "${HOME}/.local/share/${PROJECT_NAME}/lib/dz_encfs_lib.sh"

DIR="$(realpath "${1}")"
MOUNT_POINT="${DIR%.*}"
ENCFS6_CONFIG="${HOME}/.ssh/encfs/${MOUNT_POINT##*/}.xml"

declare -i FAIL_COUNT=3

if mountpoint -q "${MOUNT_POINT}"; then
    encfs_umount "${MOUNT_POINT}"
    dlog "exit:ok" "Выполнено."
    exit 0
fi

if [ "${DIR##*.}" != "enc" ]; then
    dlog "stop:fatal" "Каталог указан не верно!"
    exit 12
fi

if [ ! -f "${ENCFS6_CONFIG}" ]; then
    dlog "stop:fatal" "Отсутствует конфигурационный файл!"
    exit 13
fi

dlog "check" "Проверка точки монтирования..."
if [ ! -d "${MOUNT_POINT}" ]; then
    dlog "status:warning" "Отсутствует!"
    dlog "check:warning"  "Пробую создать..."
    if ! mkdir "${MOUNT_POINT}"; then
        dlog "stop:fatal" "Ошибка!"
        exit 14
    fi
fi
dlog "status:ok"

dlog "info:check" "Подключение encFS..."
while [ "${FAIL_COUNT}" -gt 0 ]; do
    if ENCFS6_CONFIG="${ENCFS6_CONFIG}" encfs "${DIR}" "${MOUNT_POINT}"; then
        dlog "exit:ok" "Выполнено."
        exit 0
    fi
    ((FAIL_COUNT--))
    dlog "status:warning" "Осталось попыток: ${FAIL_COUNT}"
done
dlog "status:fatal" "Ошибка!"

dlog "check" "Удаляю точку монтирования..."
if rmdir "${MOUNT_POINT}"; then
    dlog "exit:ok" "Выполнено."
    exit 0
fi
dlog "stop:error" "Ошибка!"
exit 10
