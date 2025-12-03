#!/bin/bash

# Размонтирование зашифрованного EncFS каталога и удаление точки монтирования.
# Параметр ${1} - имя каталога, к которому примотирован зашифрованный каталог.

function encfs_umount() {
    dlog "check" "Ресурс смотирован. Размонтирую..."
    if ! fusermount -u "${1}"; then
        dlog "stop:error" "Ошибка!. Возможно ресурс занят."
        return 10
    fi
    dlog "status:ok" "Успешно."
    dlog "check" "Удаляю точку монтирования..."
    if ! rmdir "${1}"; then
        dlog "stop:error" "Ошибка. Возможно ресурс занят..."
        return 11
    fi
    dlog "status:ok" "Успешно."
    return 0
}

function all_encfs_umount() {
    while IFS= read -r MOUNT_POINT; do
        dlog "status:info" "${MOUNT_POINT}"
        encfs_umount "$(echo -e "${MOUNT_POINT}")"
    done < <(grep encfs /proc/mounts | cut -d' ' -f2)
    sleep 1
}
