require("config")
require("util")

local excel = luacom.GetObject('Excel.Application') or luacom.CreateObject('Excel.Application')

local ID_INDEX = 1
local TYPE_INDEX = 2
local COMMENT_INDEX = 3
local DATA_START_INDEX = 4

local function generate(path)
	local book = excel.Workbooks:Open(path, nil, true)
	local config = {}
	for i = 1, book.Sheets.Count do
		local sheet = book.Sheets(i)
		local row = sheet.Cells(1, 3).Value2
		local col = sheet.Cells(1, 5).Value2
		local sheet_data = sheet:Range("A3:" .. col .. row).Value2

		local obj_array_flag = false
		
		for k, v in pairs(sheet_data) do
			local id = v[ID_INDEX]
			if id and string.sub(id, 1, 1) ~= '#' then
				local id_list = string_split(id, ':')
				local key = id_list[1]

				local type_list = string_split(v[TYPE_INDEX], ':')
				local type = type_list[1]
				local key_child = id_list[2]

				if not key_child then
					obj_array_flag = false
				end

				if string.find(type, "%[%]") then
					config[key] = config[key] or {}

					local target_config = config[key]

					if string.find(type, "obj") then
						obj_array_flag = true
					else
						if obj_array_flag then
							target_config = {}
							for i = DATA_START_INDEX, #v do
								local index = i - DATA_START_INDEX + 1
								config[key][index] = config[key][index] or {}

								if key_child then
									config[key][index][key_child] = config[key][index][key_child] or {}
									target_config[index] = config[key][index][key_child]
								end
							end
						else
							if key_child then
								config[key][key_child] = config[key][key_child] or {}
								target_config = config[key][key_child]
							end
						end

						if type_list[2] then
							local index_list = string.sub(type_list[2], 2, #type_list[2] - 1)
							index_list = string.gsub(index_list, '%]%[', ':')
							index_list = string_split(index_list, ':')

							local code = "function create_array(config)\n"
							local config_code =  "config"
							for _, index in pairs(index_list) do
								config_code = config_code .. "[" .. index .. "]"
								code = code .. config_code .. " = " .. config_code .. " or {}\n"
							end
							code = code .. "return " .. config_code .. "\n"
							code = code .. "end"

							loadstring(code)()

							if obj_array_flag then
								for i = DATA_START_INDEX, #v do
									local index = i - DATA_START_INDEX + 1
									target_config[index] = create_array(target_config[index])
								end
							else
								target_config = create_array(target_config)
							end
						end

						if key_child then
							if obj_array_flag then
								for i = DATA_START_INDEX, #v do
									local index = i - DATA_START_INDEX + 1
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

							local index = i - DATA_START_INDEX + 1
							config[key][index] = config[key][index] or {}
							config[key][index][key_child] = value
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

		printt(config)
	end

	book:Close()
end

for file_name in lfs.dir(EXCEL_PATH) do
	if file_name ~= "." and file_name ~= ".." then
		generate(EXCEL_PATH.."\\"..file_name)
	end
end

excel.Application:Quit()