-- Merges two tables indexed by numbers together into one longer table (original tables are untouched)
local function merge(a, b)
    local result = { unpack(a) }
    for i = 1, #b do
        result[#a+i] = b[i]
    end
    return result
end

-- Combines unfinished and finished todos into one combined list based on current script data and a force
function all_todo(script_data, force)
    return merge(script_data.unfinished_todo[force], script_data.finished_todo[force])
end