require("config")
require("util")
require("generate")

excel = luacom.GetObject('Excel.Application') or luacom.GetObject('Ket.Application')
local is_opening_excel = true

if not excel then
	excel = luacom.CreateObject('Excel.Application') or luacom.CreateObject('Ket.Application')
	is_opening_excel = false
end

FileType = 
{
	LUA = 1,
	JSON = 2,
}

function createFile(file_type, config, path, file_name)
	file_name = stringSplit(getFileName(file_name), "#")[1]

	local file_table
	local file
	if file_type == FileType.LUA then
		file_table = table2Lua(config)
		file = io.open(path .. "\\" .. "config_" .. file_name .. ".lua", "w")
	elseif file_type == FileType.JSON then
		file_table = table2Json(config)
		file = io.open(path .. "\\" .. file_name .. ".json", "w")
	else
		return
	end

	io.output(file)
	io.write(file_table)
	io.close(file)
end

function createPath(Path, OutPath)
	for file_name in winfile.dir(Path) do
		if file_name ~= "." and file_name ~= ".." and string.sub(file_name, 1, 2) ~= "~$" then
			local path = Path.."\\"..file_name
			local out_path = OutPath.."\\"..file_name
			local attr = winfile.attributes(path)
			if attr.mode == "file" then
				local lua_config = generate(path, "lua")
				createFile(FileType.LUA, lua_config, OutPath, file_name)
				local json_config = generate(path, "json")
				createFile(FileType.JSON, json_config, OutPath, file_name)
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