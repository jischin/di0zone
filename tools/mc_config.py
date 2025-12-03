#!/usr/bin/python3

from configparser import ConfigParser
from os import environ, makedirs, path

ini = ConfigParser()
ini_panels = ConfigParser()

mc_dir = path.expanduser("~") + "/.config/mc"
tool_dir = path.dirname(__file__)
mc_ini_file = mc_dir + "/ini"
mc_panels_ini_file = mc_dir + "/panels.ini"

files = [
    mc_ini_file,
    tool_dir + "/mc.ini",
]

if environ.get("USER") == "root":
    files.append(tool_dir + "/mc_root.ini")

if not path.isdir(mc_dir):
    makedirs(mc_dir)

ini.read(files)

with open(mc_ini_file, "w") as ini_file:
    ini.write(ini_file, space_around_delimiters=False)

ini_panels.read(tool_dir + "/mc_panels.ini")

with open(mc_dir + "/panels.ini", "w") as ini_file:
    ini_panels.write(ini_file, space_around_delimiters=False)

exit(0)
