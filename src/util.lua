function stringSplit(str, splitter)
    local start_index = 1
    local str_list = {}
    while true do
        local index = string.find(str, splitter, start_index)
        if not index then
            if start_index <= string.len(str) then
                table.insert(str_list, string.sub(str, start_index, string.len(str)))
            end
            break
        end
        table.insert(str_list, string.sub(str, start_index, index - 1))
        start_index = index + string.len(splitter)
    end

    return str_list
end

function getFileName(str)
    local idx = string.match(str, ".+()%.%w+$")
    if(idx) then
        return string.sub(str, 1, idx-1)
    else
        return str
    end
end

function serializeLua(lua_table, indent)
    if type(lua_table) ~= "table" then
        return tostring(lua_table)
    end
    indent = indent or 0
    string = ""
    for k, v in pairsByKeys(lua_table) do
        --加了一个插入排序 跳过该对象导出
        if k ~= "#sort#" then
            if type(k) == "string" then
                string = string .. k .. " = "
            end
            if type(v) == "table" then
                string = string .. "{"
                string = string .. serializeLua(v, indent + 1) .. ""
                string = string .. "},"
            else
                local szValue = ""
                if type(v) == "string" then
                    szValue = string.format("%q", v)
                else
                    szValue = tostring(v)
                end
                string = string .. szValue
                if k ~= #lua_table then
                    string = string .. "," .. ""
                end
            end
        end
    end
    return string
end

function table2Lua(lua_table)
    local string = "local Config = Config or {}\n"
    string = string .. "Config = {"
    string = string .. serializeLua(lua_table, 1) .. ""
    string = string .. "}\n"
    string = string .. "return Config"
    return string
end

function table2Json(lua_table)
    local json = require("dkjson")
    return json.encode( lua_table , {indent = true} )
end

function pairsByKeys(t)
    local a = {}

    for n, v in pairs(t) do
        if type(v) ~= "table" or next(v) ~= nil then 
            a[#a + 1] = n 
        end
    end

    local sort_function = nil

    if t["#sort#"] then
        sort_function = function(l, r)
            if t["#sort#"][l] and t["#sort#"][r] then
                return t["#sort#"][l] < t["#sort#"][r]
            end
            return l < r
        end
    end

    table.sort(a, sort_function)

    local i = 0
        
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end