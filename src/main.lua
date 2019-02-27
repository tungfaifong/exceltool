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
	local file = io.open(path .. "\\" .. file_name .. ".lua", "w")
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

for file_name in winfile.dir(EXCEL_PATH) do
	if file_name ~= "." and file_name ~= ".." and string.sub(file_name, 1, 2) ~= "~$" then
		local config = generate(EXCEL_PATH.."\\"..file_name)
		createFile(config, OUT_PATH, file_name)
	end
end

if not is_opening_excel then
	excel.Application:Quit()
end