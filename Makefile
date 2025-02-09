PROJECT_NAME := Di0Zone
PROJECT_FILES := dz_*

# Каталоги, в которые производится установка файлов проекта
SHARE_DIR := ${HOME}/.local/share/${PROJECT_NAME}
CONFIG_DIR := ${HOME}/.config/${PROJECT_NAME}
AUTOSTART_DIR := ${HOME}/.config/autostart
STATE_DIR := ${HOME}/.local/state/${PROJECT_NAME}
DESKTOP_DIR := ${HOME}/.local/share/applications
SYSTEMD_DIR := ${HOME}/.local/share/systemd/user
BIN_DIR := ${HOME}/.local/bin
ICON_DIR := ${HOME}/.local/share/icons

# Исходные файлы проекта
SRC_BIN_FILES := $(wildcard bin/*.sh)
SRC_LIB_FILES := $(wildcard lib/*.sh)
SRC_CFG_FILES := $(wildcard config/*)
SRC_ICON_FILES := $(wildcard icons/48x48/*)
SRC_ICON_DIR := icons
SRC_DESKTOP_FILES := $(wildcard applications/*.desktop)
SRC_SYSTEMD_FILES := $(wildcard systemd/*)

# Список сторонних каталогов, в которые устанавливаются файлы проекта,
# но которые не являются частью проекта и которые, при удалении проекта
# нужно чистить от файлов проекта, не затрагивая другие файлы.
FOREIGN_DIRS := $(BIN_DIR) $(DESKTOP_DIR) $(SYSTEMD_DIR) $(AUTOSTART_DIR)

# Список файлов, которые не являются частью проекта, но которые устанавливаются
# вместе с ним и нужны для его работы.в
FOREIGN_FILES := $(DESKTOP_DIR)/xfce4-session-logout.desktop

# Список требуемых для работы проекта утилит.
REQUIRED = ssh systemctl rsync update-desktop-database install xterm

.PHONY: test clean install reinstall purge


# Установка основных компонентов проекта.
install:
	$(info Цель $@...)
	install --mode=0640 -Dt $(CONFIG_DIR) $(SRC_CFG_FILES)
	install --mode=0750 -Dt $(SHARE_DIR)/bin $(SRC_BIN_FILES)
	install --mode=0750 -Dt $(SHARE_DIR)/lib $(SRC_LIB_FILES)
	install --mode=0640 -Dt $(DESKTOP_DIR) $(SRC_DESKTOP_FILES)
	install --mode=0640 -Dt $(SYSTEMD_DIR) $(SRC_SYSTEMD_FILES)
	install --mode=0640 -Dt $(ICON_DIR) $(SRC_ICON_FILES)
	#cp -r --update $(SRC_ICON_DIR)/* $(ICON_DIR)
	ln -srft $(BIN_DIR) $(addprefix $(SHARE_DIR)/,$(SRC_BIN_FILES))
	# Донастройка компонента DZ_SYNC
	ln -sfr $(SHARE_DIR)/bin/dz_sync.sh $(BIN_DIR)/dz_sync_pull.sh
	ln -sfr $(SHARE_DIR)/bin/dz_sync.sh $(BIN_DIR)/dz_sync_push.sh
	# Завершающие действия установки
	#update-mime-database $(HOME)/.local/share/mime
	update-desktop-database $(DESKTOP_DIR)
	systemctl --user enable dz_project.timer
	systemctl --user daemon-reload

# Проверка наличия необходимых для работы утилит.
test:
	$(foreach EXEC,$(REQUIRED), \
		$(if $(shell which $(EXEC) 2> /dev/null), \
			$(info Проверка наличия $(EXEC) ... OK), \
			$(error Отсутствует $(EXEC). Установите!. ... FAIL!)))

# Удаление проекта. При удалении каталоги с конфигурациями и логами
# сохраняются.
clean:
	$(info Цель $@...)
	systemctl --user disable $(notdir $(SRC_SYSTEMD_FILES))
	rm -f $(addsuffix /$(PROJECT_FILES),$(FOREIGN_DIRS))
	rm -f $(FOREIGN_FILES)
	rm -fr $(SHARE_DIR)
	update-desktop-database $(DESKTOP_DIR)
	systemctl --user daemon-reload

# Полное удаление проекта, включая каталоги с конфигурациями и логами.
purge: clean
	$(info Цель $@...)
	rm -fr $(CONFIG_DIR)
	rm -fr $(STATE_DIR)

# Переустановка проекта.
reinstall: clean install


# минус в начале команды позволяет игнорировать возможную ошибку и не
# прерывать из-за неё скрипт.
