function string_split(str, splitter)
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

printt = function (lua_table, indent)
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
            formatting = szPrefix.."["..k.."]".." = "..szSuffix
            if type(v) == "table" then
                print(formatting)
                printt(v, indent + 1)
                print(szPrefix.."},")
            else
                local szValue = ""
                if type(v) == "string" then
                    szValue = string.format("%q", v)
                else
                    szValue = tostring(v)
                end
                print(formatting..szValue..",")
            end
        end
    end