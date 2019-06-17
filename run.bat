@echo off

setlocal enabledelayedexpansion

echo 开始生成配置

lua\lua src\main.lua

echo 生成配置完成

set out_path=out\
set json_path=out\
set lua_path=out\

xcopy %out_path%*.json %json_path% /c /y /h /r

xcopy %out_path%*.lua %lua_path% /c /y /h /r

PAUSE