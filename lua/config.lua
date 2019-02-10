require("luacom")
require("lfs")

--初始化下lua代码路径
ROOT_PATH = lfs.currentdir()
SRC_PATH = ROOT_PATH .. "\\src"
EXCEL_PATH = ROOT_PATH .. "\\excel"
OUT_PATH = ROOT_PATH .. "\\out"

package.path = package.path .. ";" .. SRC_PATH .."\\?.lua"