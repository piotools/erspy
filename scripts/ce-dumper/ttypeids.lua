local ENTRY_PATTERN = "48 8D 05 ?? ?? ?? ?? C3"

local function toConstantCase(str)
    local s = string.gsub(str, "(%l)(%u)", "%1_%2")
    return string.upper(s)
end

local function getTTypeIdTableStart()
    local results = AOBScan(ENTRY_PATTERN, "+X")
    if not results or results.Count == 0 then return nil end

    local target = "Void"
    local foundAddr = nil

    for i = 0, results.Count - 1 do
        local address = getAddress(results[i])
        local offset = readInteger(address + 3)

        if offset then
            local stringAddr = address + offset + 7
            if readString(stringAddr, #target) == target then
                foundAddr = address
                break
            end
        end
    end

    results.destroy()
    return foundAddr
end

local function getTTypeIds()
    local current = getTTypeIdTableStart()
    if not current then return nil end

    local result = {}
    local instrSize = 8

    while readByte(current) ~= 0x90 do
        local offset = readInteger(current + 3)

        if offset then
            local stringAddr = current + offset + 7
            local typeName = readString(stringAddr, 32)
            typeName = string.match(typeName or "", "^%w+")

            if typeName then
                table.insert(result, toConstantCase(typeName))
            end
        end

        current = current + instrSize
    end

    return result
end

local function dumpTTypeIds()
    local ids = getTTypeIds()
    if ids then
        local header = "enum TTypeId { "
        local footer = " }"

        local body = table.concat(ids, ", ")

        print(header .. body .. footer)
    else
        print("Failed to find TTypeIds.")
    end
end

dumpTTypeIds()
