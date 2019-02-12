require("config")
require("util")

local excel = luacom.GetObject('Excel.Application')
local is_opening_excel = true

if not excel then
	excel = luacom.CreateObject('Excel.Application')
	is_opening_excel = false
end

local ID_INDEX = 1
local TYPE_INDEX = 2
local COMMENT_INDEX = 3
local DATA_START_INDEX = 4

local function generate(path)
	local book = excel.Workbooks:Open(path, nil, true)
	local config = {}
	for i = 1, book.Sheets.Count do
		local sheet = book.Sheets(i)
		local row = sheet.usedrange.rows.count
		local col = sheet.usedrange.columns.count
		local sheet_data = sheet:Range(sheet.Cells(2, 1), sheet.Cells(row, col)).Value2

		local obj_array_flag = false
		local obj_array_prefix = nil
		local obj_array_offset = 0
		
		for k, v in pairs(sheet_data) do
			local id = v[ID_INDEX]
			if id and string.sub(id, 1, 1) ~= '#' then
				local id_list = stringSplit(id, ':')
				local key = id_list[1]

				local type_list = stringSplit(v[TYPE_INDEX], ':')
				local type = type_list[1]
				local key_child = id_list[2]

				if not key_child then
					obj_array_flag = false
					obj_array_prefix = nil
					obj_array_offset = 0
				end

				if string.find(type, "%[%]") then
					config[key] = config[key] or {}

					local target_config = config[key]

					local is_multi_array = false

					if type_list[2] then
						local index_list = string.sub(type_list[2], 2, #type_list[2] - 1)
						index_list = string.gsub(index_list, '%]%[', ':')
						index_list = stringSplit(index_list, ':')

						local code = "function create_array(config)\n"
						local config_code =  "config"
						for _, index in pairs(index_list) do
							config_code = config_code .. "[" .. index .. "]"
							code = code .. config_code .. " = " .. config_code .. " or {}\n"
						end
						code = code .. "return " .. config_code .. "\n"
						code = code .. "end"

						loadstring(code)()

						is_multi_array = true
					end

					if string.find(type, "obj") then
						obj_array_flag = true
						obj_array_prefix = is_multi_array and create_array(config[key]) or config[key]
						obj_array_offset = #obj_array_prefix
					else
						if obj_array_flag then
							target_config = {}
							for i = DATA_START_INDEX, #v do
								local index = i - DATA_START_INDEX + 1 + obj_array_offset
								obj_array_prefix[index] = obj_array_prefix[index] or {}

								obj_array_prefix[index][key_child] = obj_array_prefix[index][key_child] or {}
								target_config[index] = obj_array_prefix[index][key_child]
							end
						else
							if key_child then
								config[key][key_child] = config[key][key_child] or {}
								target_config = config[key][key_child]
							end
						end

						if is_multi_array then
							if obj_array_flag then
								for i = DATA_START_INDEX, #v do
									local index = i - DATA_START_INDEX + 1 + obj_array_offset
									target_config[index] = create_array(target_config[index])
								end
							else
								target_config = create_array(target_config)
							end
						end

						if key_child then
							if obj_array_flag then
								for i = DATA_START_INDEX, #v do
									local index = i - DATA_START_INDEX + 1 + obj_array_offset
									if string.find(type, "int") then
										table.insert(target_config[index], tonumber(v[i]))
									elseif string.find(type, "string") then 
										table.insert(target_config[index], tostring(v[i]))
									end
								end
							else
								if string.find(type, "int") then
									table.insert(target_config, tonumber(v[DATA_START_INDEX]))
								elseif string.find(type, "string") then 
									table.insert(target_config, tostring(v[DATA_START_INDEX]))
								end
							end
						else
							if string.find(type, "int") then
								for i = DATA_START_INDEX, #v do
									table.insert(target_config, tonumber(v[i]))
								end
							elseif string.find(type, "string") then 
								for i = DATA_START_INDEX, #v do
									table.insert(target_config, tostring(v[i]))
								end
							end
						end
					end					
				else
					local value = {}

					if obj_array_flag then
						for i = DATA_START_INDEX, #v do
							if type == "int" then
								value = tonumber(v[i])
							elseif type == "string" then
								value = tostring(v[i])
							end	

							local index = i - DATA_START_INDEX + 1 + obj_array_offset
							obj_array_prefix[index] = obj_array_prefix[index] or {}
							obj_array_prefix[index][key_child] = value
						end
					else
						if type == "int" then
							value = tonumber(v[DATA_START_INDEX])
						elseif type == "string" then
							value = tostring(v[DATA_START_INDEX])
						end	

						if key_child then
							config[key][key_child] = value
						else
							config[key] = value
						end
					end
				end
			end
		end
	end

	book:Close()

	return config
end

function createFile(config, path, file_name)
	file_name = getFileName(file_name)
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

for file_name in lfs.dir(EXCEL_PATH) do
	if file_name ~= "." and file_name ~= ".." and string.sub(file_name, 1, 2) ~= "~$" then
		local config = generate(EXCEL_PATH.."\\"..file_name)
		createFile(config, OUT_PATH, file_name)
	end
end

if not is_opening_excel then
	excel.Application:Quit()
end