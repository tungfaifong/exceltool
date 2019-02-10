require("config")
require("util")

local excel = luacom.GetObject('Excel.Application') or luacom.CreateObject('Excel.Application')

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
			local id = v[1]
			if id and string.sub(id, 1, 1) ~= '#' then
				local id_list = string_split(id, ':')
				local key = id_list[1]

				local type_list = string_split(v[2], ':')
				local type = type_list[1]
				local key_child = id_list[2]

				if string.find(type, "%[%]") then
					config[key] = config[key] or {}

					local target_config = config[key]

					if string.find(type, "obj") then
						obj_array_flag = true
					end

					if key_child then
						config[key][key_child] = config[key][key_child] or {}
						target_config = config[key][key_child]
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
						target_config = create_array(target_config)
					end

					if key_child then
						if string.find(type, "int") then
							table.insert(target_config, tonumber(v[4]))
						elseif string.find(type, "string") then 
							table.insert(target_config, tostring(v[4]))
						end
					else
						if string.find(type, "int") then
							for i = 4, #v do
								table.insert(target_config, tonumber(v[i]))
							end
						elseif string.find(type, "string") then 
							for i = 4, #v do
								table.insert(target_config, tostring(v[i]))
							end
						end

						obj_array_flag = false
					end
				else
					local value = {}

					if type == "int" then
						value = tonumber(v[4])
					elseif type == "string" then
						value = tostring(v[4])
					end	

					if key_child then
						config[key][key_child] = value
					else
						config[key] = value

						obj_array_flag = false
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