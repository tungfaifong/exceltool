require("config")
require("util")
require("generate")

excel = luacom.GetObject('Excel.Application')
local is_opening_excel = true

if not excel then
	excel = luacom.CreateObject('Excel.Application')
	is_opening_excel = false
end

function createFile(config, path, file_name)
	file_name = stringSplit(getFileName(file_name), "#")[1]

	--to lua 
	local lua = table2Lua(config)
	local file = io.open(path .. "\\" .. "config_" .. file_name .. ".lua", "w")
	io.output(file)
	io.write(lua)
	io.close(file)

	--to json
	local json = table2Json(config)
	local file = io.open(path .. "\\" .. file_name .. ".json", "w")
	io.output(file)
	io.write(json)
	io.close(file)
end

function createPath(Path, OutPath)
	for file_name in winfile.dir(Path) do
		if file_name ~= "." and file_name ~= ".." and string.sub(file_name, 1, 2) ~= "~$" then
			local path = Path.."\\"..file_name
			local out_path = OutPath.."\\"..file_name
			local attr = winfile.attributes(path)
			if attr.mode == "file" then
				local config = generate(path)
				createFile(config, OutPath, file_name)
			elseif attr.mode == "directory" then
				createPath(path.."\\", out_path.."\\")
			end
		end
	end
end

createPath(EXCEL_PATH, OUT_PATH)

if not is_opening_excel then
	excel.Application:Quit()
end