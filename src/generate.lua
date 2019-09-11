ID_INDEX = 1
TYPE_INDEX = 2
OUT_TYPE_INDEX = 3
COMMENT_INDEX = 4
DATA_START_INDEX = 5

FLOAT_FIX = 0.0000000000005

function get_value(data_type, value)
	if string.find(data_type, "bool") then
		return tonumber(value) > 0
	elseif string.find(data_type, "int") then
		return math.floor(tonumber(value) + FLOAT_FIX)
	elseif string.find(data_type, "float") then
		return tonumber(value)
	elseif string.find(data_type, "string") then 
		return tostring(value)
	elseif string.find(data_type, "obj") then 
		return {}
	end
end

function generate(path, type)
	local book = excel.Workbooks:Open(path, nil, true)
	local config = {}
	config["#sort#"] = {}
	local sort_mark = 1

	for i = 1, book.Sheets.Count do
		local sheet = book.Sheets(i)
		local row = sheet.usedrange.rows.count
		local col = sheet.usedrange.columns.count
		local sheet_data = sheet:Range(sheet.Cells(2, 1), sheet.Cells(row, col)).Value2
		
		-- 转置表
		if string.sub(sheet.Cells(1, 1).Value2, 1, 1) == '~' then
			sheet_data = excel.WorksheetFunction:Transpose(sheet:Range(sheet.Cells(1, 1), sheet.Cells(row, col)))
			table.remove(sheet_data, 1)
		end

		local obj_array_flag = false
		local obj_array_prefix = nil
		local obj_array_offset = 0
		
		for k, v in pairs(sheet_data) do
			local id = v[ID_INDEX]
			local out_type = v[OUT_TYPE_INDEX]
			if id and string.sub(id, 1, 1) ~= '#' and (out_type == nil or out_type == type) then
				local id_list = stringSplit(id, ':')
				local key = id_list[1]

				if key and not config["#sort#"][key] then
					config["#sort#"][key] = sort_mark
					sort_mark = sort_mark + 1
				end

				local type_list = stringSplit(v[TYPE_INDEX], ':')
				local data_type = type_list[1]
				local key_child = id_list[2]

				if not key_child then
					obj_array_flag = false
					obj_array_prefix = nil
					obj_array_offset = 0
				end

				if string.find(data_type, "%[%]") then
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

					if string.find(data_type, "obj") then
						obj_array_flag = true
						obj_array_prefix = is_multi_array and create_array(config[key]) or config[key]
						obj_array_offset = #obj_array_prefix
					else
						if obj_array_flag then
							target_config = {}
							for i = DATA_START_INDEX, table.maxn(v) do
								local index = i - DATA_START_INDEX + 1 + obj_array_offset
								obj_array_prefix[index] = obj_array_prefix[index] or {}
								obj_array_prefix[index]["#sort#"] = obj_array_prefix[index]["#sort#"] or {}

								obj_array_prefix[index][key_child] = obj_array_prefix[index][key_child] or {}
								target_config[index] = obj_array_prefix[index][key_child]

								if not obj_array_prefix[index]["#sort#"][key_child] then
									obj_array_prefix[index]["#sort#"][key_child] = sort_mark
									sort_mark = sort_mark + 1
								end
							end
						else
							if key_child then
								config[key]["#sort#"] = config[key]["#sort#"] or {}
								config[key][key_child] = config[key][key_child] or {}
								target_config = config[key][key_child]

								if not config[key]["#sort#"][key_child] then
									config[key]["#sort#"][key_child] = sort_mark
									sort_mark = sort_mark + 1
								end
							end
						end

						if is_multi_array then
							if obj_array_flag then
								for i = DATA_START_INDEX, table.maxn(v) do
									local index = i - DATA_START_INDEX + 1 + obj_array_offset
									target_config[index] = create_array(target_config[index])
								end
							else
								target_config = create_array(target_config)
							end
						end

						if key_child then
							if obj_array_flag then
								for i = DATA_START_INDEX, table.maxn(v) do
									if v[i] then
										local index = i - DATA_START_INDEX + 1 + obj_array_offset
										table.insert(target_config[index], get_value(data_type, v[i]))
									end
								end
							else
								if v[DATA_START_INDEX] then
									table.insert(target_config, get_value(data_type, v[DATA_START_INDEX]))
								end
							end
						else
							for i = DATA_START_INDEX, table.maxn(v) do
								if v[i] then
									table.insert(target_config, get_value(data_type, v[i]))
								end
							end
						end
					end					
				else
					if obj_array_flag then
						for i = DATA_START_INDEX, table.maxn(v) do
							if v[i] or string.find(data_type, "obj") then
								local value = get_value(data_type, v[i])

								local index = i - DATA_START_INDEX + 1 + obj_array_offset
								obj_array_prefix[index] = obj_array_prefix[index] or {}
								obj_array_prefix[index]["#sort#"] = obj_array_prefix[index]["#sort#"] or {}
								obj_array_prefix[index][key_child] = value

								if not obj_array_prefix[index]["#sort#"][key_child] then
									obj_array_prefix[index]["#sort#"][key_child] = sort_mark
									sort_mark = sort_mark + 1
								end
							end
						end
					else
						if v[DATA_START_INDEX] or string.find(data_type, "obj") then
							local value = get_value(data_type, v[DATA_START_INDEX])

							if key_child then
								config[key]["#sort#"] = config[key]["#sort#"] or {}
								config[key][key_child] = value

								if not config[key]["#sort#"][key_child] then
									config[key]["#sort#"][key_child] = sort_mark
									sort_mark = sort_mark + 1
								end
							else
								config[key] = value
							end
						end
					end
				end
			end
		end
	end

	book:Close()

	return config
end