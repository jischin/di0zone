#!/bin/bash

PROJECT_NAME="Di0Zone"
APP_NAME="dz_sync"
STATE_DIR="${HOME}/.local/state/${PROJECT_NAME}"
LOG_FILE="${STATE_DIR}/${APP_NAME}.log/$(date +%F).log"
LOCAL_TRASH_DIR="${STATE_DIR}/${APP_NAME}.trash"
LOCAL_BASE_DIR="${HOME}"
SERVER_BASE_DIR="/srv/${APP_NAME}/${USER}"
SERVER_TRASH_DIR="${SERVER_BASE_DIR}/_trash"
SYNC_TIME="$(date +%F_%T)"
declare DIRECTION=""
declare SERVER_URL=""

. "${HOME}/.config/${PROJECT_NAME}/${APP_NAME}.conf"
. "${HOME}/.local/share/${PROJECT_NAME}/lib/dz_log_lib.sh"

function local_check() {
    # Проверяется доступ к базовому каталогу на хосте. Он должен
    # существовать - в противном случае будет предпринята попытка его
    # создать, и доступен для записи.

    dlog "check" "Локальный базовый каталог..."
    if [ ! -d "${1}" ] && ! mkdir -p "${1}" || [ ! -w "${1}" ]; then
        dlog "status:fatal" "Не доступен!"
        return 2
    fi
    dlog "status:ok"
    return 0
}

function server_check() {
    # Проверяется доступность сервера по адресу, затем наличие
    # его базового каталога - при отсутствии будет попытка его создать.
    # Проверяется доступность базового каталога для записи.
    # Параметр ${1} - IP адрес или URL сервера, по которому
    # определяется его доступность.
    SERVER_URL="${1}"
    dlog "check" "Сервер ${SERVER_URL}..."
    if ! ssh -qo ConnectTimeout=3 "${SERVER_URL}" exit
    then
        dlog "status:fatal" "Не доступен!"
        return 2
    fi
    dlog "status:ok"
    dlog "check" "Базовый каталог на сервере..."
    if ssh -q "${SERVER_URL}" [ ! -d \""${SERVER_BASE_DIR}"\" ] '&&' \
    ! mkdir -p \""${SERVER_BASE_DIR}"\" '||' \
    [ ! -w \""${SERVER_BASE_DIR}"\" ]; then
        dlog "status:fatal" "Не доступен!"
        return 2
    fi
    dlog "status:ok"
    return 0
}

function direction_define() {
    # Функция определяет направление синхронизации PULL или PUSH.
    # Параметр: ${1} - путь синхронизируемого каталога, относительно
    # базового каталога, если размещён в нём, или абсолютный, если
    # размещён за его пределами.
    # Направление можно указать явно, используя ссылку на скрипт, в имя
    # которой включены суффиксы _pull или _push.
    # Автоматическое определение направления происходит исходя из
    # наличия или отсутствия каталогов локально или на сервере и по
    # меткам, размещённым на сервере в каждом каталоге и указывающие с
    # какого компьютера была проведена последняя синхронизация.
    # Внимание! Каталоги за пределами локальной базы, которые передаются
    # по абсолютному пути, можно только отправлять (PUSH) на сервер.

    if [[ "${0##*/}" != *_pull* ]] &&
    [ -d "${1}" ] && [ -r "${1}" ] && ([[ "${1}" == /* ]] ||
    [[ "${0##*/}" == *_push* ]] ||
    ssh < /dev/null -q "${SERVER_URL}" [ ! -f \""${STATUS_FILE}"\" ] '||' \
    [[ \"\$\(head -n 1 \""${STATUS_FILE}"\"\)\" == \""${HOSTNAME}"\" ]]); then
        DIRECTION="PUSH"
        SRC="${1}"
        DST="${SERVER_URL}:${SERVER_BASE_DIR}"
        [[ "${1}" == /* ]] && DST+="/_ext/${HOSTNAME}"
        return 0
    fi

    if [[ "${0##*/}" != *_push* ]] && [[ "${1}" != /* ]] &&
    ([[ "${0##*/}" == *_pull* ]] || [ ! -d "${1}" ] &&
    ssh < /dev/null "${SERVER_URL}" [ -d \""${SERVER_BASE_DIR}/${1}"\" ]) ||
    ssh < /dev/null "${SERVER_URL}" [ -f \""${STATUS_FILE}"\" ] '&&' \
    [ \"\$\(head -n 1 \""${STATUS_FILE}"\"\)\" != \""${HOSTNAME}"\" ]; then
        DIRECTION="PULL"
        SRC="${SERVER_URL}:${SERVER_BASE_DIR}/./${1#/}"
        DST="${LOCAL_BASE_DIR}"
        return 0
    fi
    return 100
}

function dir_sync() {
    # Синхронизация каталогов.

    if [ "${DIRECTION}" == "PULL" ]; then
        local TRASH_DIR="${LOCAL_TRASH_DIR}"
    else
        local TRASH_DIR="${SERVER_TRASH_DIR}"
    fi
    rsync \
    --archive --executability --hard-links --delete-after --recursive \
    --relative --update --ignore-errors --mkpath \
    --backup --backup-dir="${TRASH_DIR}/${SYNC_TIME}" \
    "${SYNC_FILTER[@]}" "${SYNC_PARAMETERS[@]}" "${SRC}" "${DST}" || return $?
    ssh < /dev/null -q "${SERVER_URL}" \
    echo -e \""${HOSTNAME}\n${SYNC_TIME}\n${DIRECTION}"\" \
    \> \""${STATUS_FILE}"\"
    return 0
}

function sweep_trash() {
    # Ротация логфайлов и каталогов TRASH_DIR, в которые складываются копии
    # удалённых (стёртых) файлов, что бы исключить их чрезмерное накопление.

    find "${LOCAL_TRASH_DIR}" -mindepth 1 -maxdepth 1 \
        -mtime +"${TRASH_AGE}" -exec rm -fr {} + &> /dev/null
    ssh "${SERVER_URL}" find \""${SERVER_TRASH_DIR}"\" -mindepth 1 \
        -maxdepth 1 -mtime +"${TRASH_AGE}" -exec rm -fr {} + &> /dev/null
    find "${LOG_FILE%/*}" -type f -name "*.log" \
        -mtime +"${TRASH_AGE}" -delete &> /dev/null
    return 0
}

# MAIN

if ! local_check "${LOCAL_BASE_DIR}"; then
    dlog "stop:fatal" "Критическая ошибка!"
    exit 7
fi

cd "${LOCAL_BASE_DIR}" || exit 7

if ! server_check "${SERVER_ADDRESS}"; then
    dlog "stop:fatal" "Критическая ошибка!"
    exit 5
fi

while IFS= read -r -d '' DIR; do
    [[ "${DIR}" == /* ]] &&
    STATUS_FILE="${SERVER_BASE_DIR}/_ext/${HOSTNAME}/${DIR#/}/.${APP_NAME}" ||
    STATUS_FILE="${SERVER_BASE_DIR}/${DIR#/}/.${APP_NAME}"
    dlog "sync" "${DIR}"
    if ! direction_define "${DIR}"; then
        dlog "status:error" "Не разрешено!"
        continue
    fi
    dlog "${DIRECTION}" "Синхронизирую..."
    if ! dir_sync "${DIR}"; then
        dlog "status:error" "Ошибка!"
        continue
    fi
    dlog "status:ok" "Успешно."
done < <(realpath -sqz --relative-base="${LOCAL_BASE_DIR}" \
--relative-to="${LOCAL_BASE_DIR}" "${@:-${SYNC_LIST[@]}}")

sweep_trash

dlog "exit" "Синхрнизация завершена."
exit 0
