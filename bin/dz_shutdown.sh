#!/bin/bash

# Скрипт производит действия, необходимые при выключении компьютера.
# Размонтирует файловые системы encfs, выключает компьютер.
# Вызывается при остановке пользовательского сервиса dz_project.service
# Q. Для чего вызову функции encfs_umount аргумент передаётся через echo -e?
# A. Для корректной обработки путей с пробелами. В файле /proc/mounts
# пробелы в путях заменены escape последовательностью \040. В таком виде
# encfs_umount путь обработать не может, его нужно заменить на пробел.
# echo -e как раз обрабатывает escape последовательности и с этим справляется.

PROJECT_NAME="Di0Zone"
APP_NAME="dz_shutdown"

. "${HOME}/.local/share/${PROJECT_NAME}/lib/dz_log_lib.sh"
. "${HOME}/.local/share/${PROJECT_NAME}/lib/dz_encfs_lib.sh"

dz_sync.sh

dlog "wait" "<R>-перезагрузка, <Q>-выход, <Enter> - выключить..."
read -rsn 1 -p "Нажмите клавишу..." KEY 2>&1
case "${KEY}" in
    "R"|"r"|"К"|"к")
        all_encfs_umount
        systemctl reboot
        ;;
    "Q"|"q"|"Й"|"й")
        exit 0
        ;;
    *)
        all_encfs_umount
        systemctl poweroff
        ;;
esac

exit 0
