PROJECT_NAME := Di0Zone
PROJECT_FILES := dz_*

#MAKEFLAGS += --quiet

# Каталоги, в которые производится установка файлов проекта
SHARE_DIR := ${HOME}/.local/share/${PROJECT_NAME}
CONFIG_DIR := ${HOME}/.config/${PROJECT_NAME}
AUTOSTART_DIR := ${HOME}/.config/autostart
STATE_DIR := ${HOME}/.local/state/${PROJECT_NAME}
APPLICATIONS_DIR := ${HOME}/.local/share/applications
SYSTEMD_DIR := ${HOME}/.local/share/systemd/user
BIN_DIR := ${HOME}/.local/bin
ICON_DIR := ${HOME}/.local/share/icons

# Списки исходных файлов проекта
SRC_BIN_FILES := $(wildcard bin/*.sh)
SRC_LIB_FILES := $(wildcard lib/*.sh)
SRC_CFG_FILES := $(wildcard config/*)
SRC_ICON_FILES := $(wildcard icons/48x48/*)
SRC_ICON_DIR := icons
SRC_APPLICATIONS_FILES := $(wildcard applications/*.desktop)
SRC_SYSTEMD_TIMERS := $(wildcard systemd/*.timer)
SRC_SYSTEMD_SERVICES := $(wildcard systemd/*.service)

AUTOSTART_APPLICATIONS := dz_sync.desktop

# Список сторонних каталогов, в которые устанавливаются файлы проекта,
# но которые не являются частью проекта и которые, при удалении проекта
# нужно чистить от файлов проекта, не затрагивая другие файлы.
FOREIGN_DIRS := $(BIN_DIR) $(APPLICATIONS_DIR) $(SYSTEMD_DIR) $(AUTOSTART_DIR)

# Список файлов, которые не являются частью проекта, но которые устанавливаются
# вместе с ним и нужны для его работы.в
FOREIGN_FILES := $(APPLICATIONS_DIR)/xfce4-session-logout.desktop

# Список требуемых для работы проекта утилит.
REQUIRED = ssh systemctl rsync update-desktop-database install xterm alacritty

.PHONY: test clean install reinstall purge config

.SILENT: install clean

# Установка основных компонентов проекта.
install:
	$(info Цель $@...)
	install --mode=0640 -Dt $(CONFIG_DIR) $(SRC_CFG_FILES)
	install --mode=0750 -Dt $(SHARE_DIR)/bin $(SRC_BIN_FILES)
	install --mode=0750 -Dt $(SHARE_DIR)/lib $(SRC_LIB_FILES)
	install --mode=0640 -Dt $(APPLICATIONS_DIR) $(SRC_APPLICATIONS_FILES)
	install --mode=0640 -Dt $(SYSTEMD_DIR) $(SRC_SYSTEMD_TIMERS)
	install --mode=0640 -Dt $(SYSTEMD_DIR) $(SRC_SYSTEMD_SERVICES)
	install --mode=0640 -Dt $(ICON_DIR) $(SRC_ICON_FILES)
	#cp -r --update $(SRC_ICON_DIR)/* $(ICON_DIR)
	ln -srft $(BIN_DIR) $(addprefix $(SHARE_DIR)/,$(SRC_BIN_FILES))
	# Донастройка компонента DZ_SYNC
	ln -sfr $(SHARE_DIR)/bin/dz_sync.sh $(BIN_DIR)/dz_sync_pull.sh
	ln -sfr $(SHARE_DIR)/bin/dz_sync.sh $(BIN_DIR)/dz_sync_push.sh
	ln -sfrt $(AUTOSTART_DIR) \
		$(addprefix $(APPLICATIONS_DIR)/,$(AUTOSTART_APPLICATIONS))
	# Завершающие действия установки
	#update-mime-database $(HOME)/.local/share/mime
	update-desktop-database $(APPLICATIONS_DIR)
	#systemctl --user daemon-reload
	#systemctl --user enable dz_project.timer

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
	-systemctl --user stop $(notdir $(SRC_SYSTEMD_SERVICES))
	-systemctl --user stop $(notdir $(SRC_SYSTEMD_TIMERS))
	-systemctl --user disable $(notdir $(SRC_SYSTEMD_TIMERS))
	-systemctl --user disable $(notdir $(SRC_SYSTEMD_SERVICES))
	rm -f $(addsuffix /$(PROJECT_FILES),$(FOREIGN_DIRS))
	rm -f $(FOREIGN_FILES)
	rm -fr $(SHARE_DIR)
	update-desktop-database $(APPLICATIONS_DIR)
	systemctl --user daemon-reload

# Полное удаление проекта, включая каталоги с конфигурациями и логами.
purge: clean
	$(info Цель $@...)
	rm -fr $(CONFIG_DIR)
	rm -fr $(STATE_DIR)


reinstall: clean install


config:
	sed -i s/^base_color=\.\*/"base_color=selected=black,cyan:markselect=yellow,cyan"/ ${HOME}/.config/mc/ini
	sed -i s/^timeformat_recent=\.\*/"timeformat_recent=%F %R"/ ${HOME}/.config/mc/ini
	sed -i s/^timeformat_old=\.\*/"timeformat_old=%F %R"/ ${HOME}/.config/mc/ini


# минус в начале команды позволяет игнорировать возможную ошибку и не
# прерывать из-за неё скрипт.
