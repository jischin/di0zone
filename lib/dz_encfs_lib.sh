#!/bin/bash

# Размонтирование зашифрованного EncFS каталога и удаление точки монтирования.
# Параметр - имя каталога, в который смотирован зашифрованный каталог.

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
