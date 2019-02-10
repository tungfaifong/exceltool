function stringSplit(str, splitter)
    local start_index = 1
    local str_list = {}
    while true do
        local index = string.find(str, splitter, start_index)
        if not index then
            table.insert(str_list, string.sub(str, start_index, string.len(str)))
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
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szPrefix = string.rep("    ", indent)
        string = string .. szPrefix .. "[" .. k .. "]" .." = "
        if type(v) == "table" then
            string = string .. "{\n"
            string = string .. serializeLua(v, indent + 1) .. "\n"
            string = string .. szPrefix .. "}," .. "\n"
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            string = string .. szValue
            if k ~= #lua_table then
                string = string .. "," .. "\n"
            end
        end
    end
    return string
end

function table2Lua(lua_table)
    local string = "local Config = Config or {}\n"
    string = string .. "Config = {\n"
    string = string .. serializeLua(lua_table, 1) .. "\n"
    string = string .. "}\n"
    string = string .. "return Config"
    return string
end

function table2Json(lua_table)
    local json = require("dkjson")
    return json.encode( lua_table , {indent = true} )
end

printt = function(lua_table, indent)
    if type(lua_table) ~= "table" then
        print(lua_table)
        return
    end
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        local szSuffix = ""
        if type(v) == "table" then
            szSuffix = "{"
        end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix
        if type(v) == "table" then
            print(formatting)
            printt(v, indent + 1)
            print(szPrefix .. "},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ",")
        end
    end
end