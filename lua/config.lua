luacom = require("luacom")
winfile = require("winfile")

--初始化下lua代码路径
ROOT_PATH = winfile.currentdir()

SRC_PATH = ROOT_PATH .. "\\src"
EXCEL_PATH = ROOT_PATH .. "\\excel"
OUT_PATH = ROOT_PATH .. "\\out"

package.path = package.path .. ";" .. SRC_PATH .."\\?.lua"