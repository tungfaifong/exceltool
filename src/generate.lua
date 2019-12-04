ID_INDEX = 1
TYPE_INDEX = 2
OUT_TYPE_INDEX = 3
COMMENT_INDEX = 4
DATA_START_INDEX = 5

FLOAT_FIX = 0.0000000000005

local function getValue(data_type, value)
	if string.find(data_type, "bool") then
		if type(value) == "boolean" then
			return value
		else
			return tonumber(value) > 0
		end
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

local function addSortMark(prefix, key, sort_mark)
	if not prefix or not key then
		return sort_mark
	end

	prefix["#sort#"] = prefix["#sort#"] or {}

	if prefix["#sort#"][key] then
		return sort_mark
	end

	prefix["#sort#"][key] = sort_mark
	return sort_mark + 1
end

local function getPrefix(config, id_list, id_index)
	if id_index + 1 > #id_list then
		return config, id_list[id_index]
	end

	local i = id_list[id_index]
	config[i] = config[i] or {}
	
	return getPrefix(config[i], id_list, id_index + 1)
end

local function getArray(config, index_list, index)
	if index > #index_list then
		return config
	end

	local i = tonumber(index_list[index])
	config[i] = config[i] or {}

	return getArray(config[i], index_list, index + 1)
end

function generate(path, type)
	local book = excel.Workbooks:Open(path, nil, true)
	local config = {}
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

		local obj_array_prefix = nil
		local obj_array_offset = 0
		
		for k, v in pairs(sheet_data) do
			local id = v[ID_INDEX]
			local out_type = v[OUT_TYPE_INDEX]
			if id and string.sub(id, 1, 1) ~= '#' and (out_type == nil or out_type == type) then
				local id_list = stringSplit(id, ':')
				if #id_list <= 1 then
					obj_array_prefix = nil
					obj_array_offset = 0
				end

				local prefix, key = getPrefix(config, id_list, 1)
				prefix = obj_array_prefix or prefix

				local type_list = stringSplit(v[TYPE_INDEX], ':')
				local data_type = type_list[1]

				if string.find(data_type, "%[%]") then
					local function getTargetArray(prefix, key, type_list)
						prefix[key] = prefix[key] or {}
						sort_mark = addSortMark(prefix, key, sort_mark)

						local target_array = prefix[key]

						if type_list[2] then
							local index_list = string.sub(type_list[2], 2, #type_list[2] - 1)
							index_list = string.gsub(index_list, '%]%[', ':')
							index_list = stringSplit(index_list, ':')

							target_array = getArray(prefix[key], index_list, 1)
						end

						return target_array
					end

					if obj_array_prefix then
						for i = DATA_START_INDEX, table.maxn(v) do
							local index = i - DATA_START_INDEX + 1 + obj_array_offset
							prefix[index] = prefix[index] or {}
							local target_array = getTargetArray(prefix[index], key, type_list)

							if v[i] then
								table.insert(target_array, getValue(data_type, v[i]))
							end
						end
					else
						local target_array = getTargetArray(prefix, key, type_list)

						if string.find(data_type, "obj") then
							obj_array_prefix = target_array
							obj_array_offset = #obj_array_prefix
						else
							for i = DATA_START_INDEX, table.maxn(v) do
								if v[i] then
									table.insert(target_array, getValue(data_type, v[i]))
								end
							end
						end
					end
				else
					local function addValue(prefix, key, data_type, value)
						prefix[key] = getValue(data_type, value)
						sort_mark = addSortMark(prefix, key, sort_mark)
					end

					if obj_array_prefix then
						for i = DATA_START_INDEX, table.maxn(v) do
							if v[i] then
								local index = i - DATA_START_INDEX + 1 + obj_array_offset
								prefix[index] = prefix[index] or {}
								addValue(prefix[index], key, data_type, v[i])
							end
						end
					else
						if v[DATA_START_INDEX] then
							addValue(prefix, key, data_type, v[DATA_START_INDEX])
						end
					end
				end
			end
		end
	end

	book:Close()

	return config
end