@echo off

setlocal enabledelayedexpansion

echo 开始生成配置

lua\lua src\main.lua

echo 生成配置完成

set out_path=out\
set json_path=E:\w7\trunk\config\server\gameworld\globaljsonconfig\
rem set json_path=E:\w7\trunk\config\server\gameworld\globaljsonconfig\fblogic\
rem set json_path=E:\w7\trunk\config\server\globalserver\configjson
set lua_path=E:\w7\trunk\src\mobile\3dscripts\lua_source\config\configlogic\

xcopy %out_path%*.json %json_path% /e /c /y /h /r
xcopy %out_path%*.lua %lua_path% /e /c /y /h /r

PAUSE