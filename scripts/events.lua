require "util"

local player_lib = require "scripts/player"
local definesevents = defines.events
local definesbutton = defines.mouse_button_type

local script_data = {
    players = {},
    player_table = {},
    player_lookup = {},
    index = 1,
    todo = {},
    finished_todo = {},
    all_todo = {},
    unfinished_todo = {}
}

local function remove_last(str)
    return (string.gsub(str, ",?[%w_]+%s*=%s*[%w_]+$", ""))
end

local function update_player_flow(force, assigned, namestring)
    local player_table = script_data.player_table[force]

    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]

        if playermeta.frame and playermeta.players[namestring] then
            playermeta:add_assigned_data(assigned, playermeta.players[namestring], player_table, namestring)
        end
    end
end

local function update_subtask_flow(force, subtasks, parentnamestring)
    local todo = script_data.todo[force]
    local player_table = script_data.player_table[force]

    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]

        if playermeta.frame and playermeta.subtaskflows[parentnamestring] then
            playermeta.toggles[parentnamestring].number = #subtasks
            playermeta:add_subtasks(subtasks, todo, player_table, parentnamestring)
        end
    end
end

local function update_scrollpane(force, all)
    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]

        if playermeta.frame and (all == "all" or (playermeta.switch_state == "left" and (all == "left-right" or all == "none-left" or all == "left")) or (playermeta.switch_state == "none" and (all == "none-right" or all == "none-left" or all == "none")) or playermeta.switch_state == "right" and (all == "left-right" or all == "none-right" or all == "right")) then
            playermeta:build_scrollpane(script_data)
            playermeta.button.number = #script_data.unfinished_todo[force]
        end
    end
end

local function update_checkboxes(force, state, namestring)
    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]

        if playermeta.frame and playermeta.checkboxes[namestring] then
            playermeta.checkboxes[namestring].state = state

            if playermeta.reference_checkboxes[namestring] then
                playermeta.reference_checkboxes[namestring].state = state
            end
        end
    end
end

local function check_texts(force, playermeta)
    local todo = script_data.todo[force]
    local player_lookup = script_data.player_lookup[force]
    local enddata = {}
    local length = 0

    for namestring, title in pairs(playermeta.titles) do
        local description = playermeta.descriptions[namestring]

        playermeta.edit_titles[namestring] = nil
        playermeta.edit_descriptions[namestring] = nil

        if title.style.font == "default-bold" or description.style.font == "default-bold" then
            local data = todo[namestring]
            data.title = title.text
            data.description = description.text

            enddata[namestring] = {title = title.text, description = description.text}
            length = length + 1
        end
    end

    if length > 0 then
        for _, player_id in pairs(player_lookup) do
            local secondplayermeta = script_data.players[player_id]

            if secondplayermeta.frame or next(secondplayermeta.reference_titles) then
                for namestring, data in pairs(enddata) do
                    if secondplayermeta.frame and secondplayermeta.titles[namestring] then
                        if secondplayermeta.edit_mode then
                            secondplayermeta.titles[namestring].text = data.title
                            secondplayermeta.descriptions[namestring].text = data.description
                        else
                            secondplayermeta.titles[namestring].caption = data.title
                            secondplayermeta.descriptions[namestring].caption = data.description
                        end
                    end

                    if secondplayermeta.reference_titles[namestring] then
                        secondplayermeta.reference_titles[namestring].caption = data.title
                        secondplayermeta.reference_descriptions[namestring].caption = data.description
                    end
                end
            end
        end
    end
end

local function update_references(force, id_string)
    local todo = script_data.todo[force]

    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]
        local namestring = playermeta.reference_namestrings[id_string]

        if namestring then
            playermeta:reference_internal(todo[namestring], todo, namestring)
        end
    end
end

local remove_data = {}
local import_subtasks = {}

remove_data = function(force, todo, parentnamestring)
    for _, player_id in pairs(script_data.player_lookup[force]) do
        local playermeta = script_data.players[player_id]

        playermeta.sub_open[parentnamestring] = nil

        if playermeta.frame then
            playermeta.checkboxes[parentnamestring] = nil
            playermeta.titles[parentnamestring] = nil
            playermeta.descriptions[parentnamestring] = nil
            playermeta.players[parentnamestring] = nil
            playermeta.toggles[parentnamestring] = nil
        end
    end

    local data = todo[parentnamestring]

    if data.level < 5 then
        for _, namestring in pairs(data.subtasks) do
            remove_data(force, todo, namestring)

            todo[namestring] = nil
        end
    end
end

import_subtasks = function(task, todo, importtask, importtasks, namestring)
    local newlevel = task.level + 1
    local newnamestringpart = namestring .. ",L" .. newlevel .. "="

    for _, importnamestring in pairs(importtask.subtasks) do
        local importdata = importtasks[importnamestring]
        local newnamestring = newnamestringpart .. task.index

        todo[newnamestring] = {
            title = importdata.title or "",
            description = importdata.description or "",
            id_string = task.id_string,
            parent_string = namestring,
            state = importdata.state or false,
            level = newlevel,
            parentindex = #task.subtasks + 1,
            index = (newlevel < 5 and 1) or nil,
            assigned = {},
            location = (type(importdata.location) == "table" and type(importdata.location.x) == "number" and type(importdata.location.y) == "number" and {x = importdata.location.x, y = importdata.location.y}) or {},
            subtasks = (newlevel < 5 and {}) or nil
        }

        task.index = task.index + 1

        table.insert(task.subtasks, newnamestring)

        if newlevel < 5 and type(importdata.subtasks) == "table" and importdata.subtasks[1] then
            import_subtasks(todo[newnamestring], todo, importdata, importtasks, newnamestring)
        end
    end
end

local function add_forces()
    for _, force in pairs(game.forces) do
        local id = tostring(force.index)

        if not script_data.todo[id] then
            script_data.todo[id] = {}
            script_data.finished_todo[id] = {}
            script_data.all_todo[id] = {}
            script_data.unfinished_todo[id] = {}
            script_data.player_table[id] = {}
            script_data.player_lookup[id] = {}
        end
    end
end

local function playerstart(player_index)
    if not script_data.players[tostring(player_index)] then
        local player = player_lib.new(game.players[player_index], #script_data.unfinished_todo[tostring(game.players[player_index].force.index)])
        local id = player.force

        script_data.players[player.index] = player
        script_data.player_table[id][player.index] = player.player.name
        script_data.player_lookup[id][player.player.name] = player.index
    end
end

local function playerload()
    for _, player in pairs(game.players) do
        playerstart(player.index)
    end
end

return {
    on_init = function()
        global.NET = global.NET or script_data

        add_forces()
        playerload()
    end,
    on_load = function()
        script_data = global.NET or script_data
        for _, player in pairs(script_data.players) do
            setmetatable(player, player_lib.metatable)
        end
    end,
    on_configuration_changed = function(event)
        global.NET = global.NET or script_data

        add_forces()
        playerload()

        local changes = event.mod_changes and event.mod_changes["Not_Enough_Todo"] or {}

        if next(changes) then
            local oldchanges = changes.old_version

            if oldchanges and changes.new_version then
                if oldchanges == "0.0.2" then
                    local old_script_data = global.script_data
                    local todo = script_data.todo["1"]
                    local finished_todo = script_data.finished_todo["1"]
                    local all_todo = script_data.all_todo["1"]
                    local unfinished_todo = script_data.unfinished_todo["1"]

                    for _, playermeta in pairs(old_script_data.players) do
                        playermeta.button.destroy()

                        if playermeta.frame then
                            playermeta.frame.destroy()
                        end

                        for _, frame in pairs(playermeta.reference_frames) do
                            frame.destroy()
                        end
                    end

                    for _, data in pairs(old_script_data.todo) do
                        local newnamestring = "id=" .. script_data.index

                        todo[newnamestring] = {
                            title = data.title,
                            description = data.description,
                            id_string = newnamestring,
                            state = data.state,
                            level = 0,
                            all_index = #all_todo + 1,
                            finished_index = (data.state and #finished_todo + 1) or nil,
                            unfinished_index = (not data.state and #unfinished_todo + 1) or nil,
                            index = 1,
                            assigned = {},
                            location = data.location,
                            subtasks = {}
                        }

                        script_data.index = script_data.index + 1

                        table.insert(all_todo, newnamestring)

                        if data.state then
                            table.insert(finished_todo, newnamestring)
                        else
                            table.insert(unfinished_todo, newnamestring)
                        end

                        for _, subtaskdata in pairs(data.subtasks) do
                            local newnamestring2 = newnamestring .. "L1=" .. todo[newnamestring].index

                            todo[newnamestring2] = {
                                title = subtaskdata.title,
                                description = "",
                                id_string = newnamestring,
                                parent_string = newnamestring,
                                state = subtaskdata.state,
                                level = 1,
                                parentindex = #todo[newnamestring].subtasks + 1,
                                index = 1,
                                assigned = {},
                                location = subtaskdata.location,
                                subtasks = {}
                            }

                            todo[newnamestring].index = todo[newnamestring].index + 1

                            table.insert(todo[newnamestring].subtasks, newnamestring2)
                        end
                    end

                    global.script_data = nil
                end
            end
        end
    end,
    events = {
        [definesevents.on_force_created] = function(event)
            local id = tostring(event.force.index)

            script_data.todo[id] = {}
            script_data.finished_todo[id] = {}
            script_data.all_todo[id] = {}
            script_data.unfinished_todo[id] = {}
            script_data.player_table[id] = {}
            script_data.player_lookup[id] = {}
        end,
        [definesevents.on_forces_merging] = function(event)
            local oldid = tostring(event.source.index)
            local newid = tostring(event.destination.index)
            local todo = script_data.todo[newid]
            local finished_todo = script_data.finished_todo[newid]
            local all_todo = script_data.all_todo[newid]
            local unfinished_todo = script_data.unfinished_todo[newid]

            todo = util.merge({todo, script_data.todo[oldid]})

            for _, namestring in pairs(script_data.finished_todo[oldid]) do
                table.insert(finished_todo, namestring)

                todo[namestring].finished_index = #finished_todo
            end

            for _, namestring in pairs(script_data.all_todo[oldid]) do
                table.insert(all_todo, namestring)

                todo[namestring].all_index = #all_todo
            end

            for _, namestring in pairs(script_data.unfinished_todo[oldid]) do
                table.insert(unfinished_todo, namestring)

                todo[namestring].unfinished_index = #unfinished_todo
            end

            update_scrollpane(newid, "all")

            script_data.todo[oldid] = nil
            script_data.finished_todo[oldid] = nil
            script_data.all_todo[oldid] = nil
            script_data.unfinished_todo[oldid] = nil
            script_data.player_table[oldid] = nil
            script_data.player_lookup[oldid] = nil
        end,
        [definesevents.on_gui_checked_state_changed] = function(event)
            local element = event.element
            local name = element.name

            if name:sub(1, 10) == "TODO_CHECK" then
                local player_id = event.player_index
                local player_index = tostring(player_id)
                local player = game.players[player_id]
                local playermeta = script_data.players[player_index]
                local settings = playermeta.settings
                local force = playermeta.force
                local state = element.state
                local number = name:sub(11, 12)
                local namestring = name:sub(14)
                local todo = script_data.todo[force]

                if number == "01" then
                    local task = todo[namestring]

                    if state then
                        task.state = state

                        table.remove(script_data.unfinished_todo[force], task.unfinished_index)
                        table.insert(script_data.finished_todo[force], namestring)

                        task.unfinished_index = nil
                        task.finished_index = #script_data.finished_todo[force]

                        for i, namestring2 in pairs(script_data.unfinished_todo[force]) do
                            todo[namestring2].unfinished_index = i
                        end

                        update_scrollpane(force, "all")
                        update_checkboxes(force, state, namestring)
                    else
                        if settings.unfinish_tasks or not game.is_multiplayer() then
                            task.state = state

                            table.remove(script_data.finished_todo[force], task.finished_index)
                            table.insert(script_data.unfinished_todo[force], namestring)

                            task.finished_index = nil
                            task.unfinished_index = #script_data.unfinished_todo[force]

                            for i, namestring2 in pairs(script_data.finished_todo[force]) do
                                todo[namestring2].finished_index = i
                            end

                            update_scrollpane(force, "all")
                            update_checkboxes(force, state, namestring)
                        else
                            player.print({"TodoRights.Unfinish"})

                            element.state = not state
                        end
                    end
                elseif number == "02" then
                    local task = todo[namestring]

                    if state then
                        task.state = state

                        update_checkboxes(force, state, namestring)
                    else
                        if settings.unfinish_tasks or not game.is_multiplayer() then
                            task.state = state

                            update_checkboxes(force, state, namestring)
                        else
                            player.print({"TodoRights.Unfinish"})

                            element.state = not state
                        end
                    end
                elseif number == "03" then
                    local second_playermeta = script_data.players[namestring:match("%d+")]

                    second_playermeta.settings.changed = true
                    second_playermeta.settings[namestring:match("[%w_]+$")] = state

                    if second_playermeta.frame then
                        second_playermeta:clear()
                    end

                    second_playermeta:gui(script_data)
                end
            end
        end,
        [definesevents.on_gui_click] = function(event)
            local element = event.element
            local name = element.name

            if name:sub(1, 10) == "TODO_CLICK" then
                local player_index = event.player_index
                local player_id = tostring(player_index)
                local player = game.players[player_index]
                local playermeta = script_data.players[player_id]
                local settings = playermeta.settings
                local force = playermeta.force
                local switch_state = playermeta.switch_state
                local button = event.button
                local number = name:sub(11, 12)
                local namestring = name:sub(14)
                local todo = script_data.todo[force]

                if number == "01" then
                    if playermeta.frame then
                        if playermeta.edit_mode then
                            check_texts(force, playermeta)
                        end

                        playermeta:clear()
                    else
                        playermeta.button.number = #script_data.unfinished_todo[force]
                        playermeta:gui(script_data)
                    end
                elseif number == "02" then
                    playermeta.edit_mode = not playermeta.edit_mode
                    playermeta.sort.visible = playermeta.edit_mode

                    if playermeta.edit_mode then
                        playermeta.edit_button.style = "todoframeactionselected"
                    else
                        check_texts(force, playermeta)

                        playermeta.edit_button.style = "frame_action_button"
                    end

                    playermeta:build_scrollpane(script_data)
                elseif number == "03" then
                    if playermeta.import_frame then
                        playermeta.import_button.style = "frame_action_button"
                        playermeta:clear_import()
                    else
                        playermeta.import_button.style = "todoframeactionselected"
                        playermeta:import_gui()
                    end
                elseif number == "04" then
                    if playermeta.export_frame then
                        playermeta.export_button.style = "frame_action_button"
                        playermeta:clear_export()
                    else
                        playermeta.export_button.style = "todoframeactionselected"
                        playermeta:export_gui(game.encode_string(game.table_to_json(todo)))
                    end
                elseif number == "05" then
                    if playermeta.settings_frame then
                        playermeta.settings_button.style = "frame_action_button"
                        playermeta:clear_settings()
                    else
                        playermeta.settings_button.style = "todoframeactionselected"
                        playermeta:settings_gui(script_data.player_table[force])
                    end
                elseif number == "06" then
                    if playermeta.edit_mode then
                        check_texts(force, playermeta)
                    end

                    playermeta:clear()
                elseif number == "07" then
                    local newnamestring = remove_last(namestring)
                    local data = todo[newnamestring]

                    data.assigned[namestring:match("%d+$")] = nil

                    update_player_flow(force, data.assigned, newnamestring)
                elseif number == "08" then
                    local data = todo[namestring]

                    data.assigned[player_id] = player.name

                    update_player_flow(force, data.assigned, namestring)
                elseif number == "09" then
                    local task = todo[namestring]

                    if task.parent_string then
                        local parenttask = todo[task.parent_string]

                        table.remove(parenttask.subtasks, task.parentindex)

                        if button == definesbutton.left then
                            table.insert(parenttask.subtasks, task.parentindex - 1, namestring)
                        else
                            table.insert(parenttask.subtasks, 1, namestring)
                        end

                        for i, namestring2 in pairs(parenttask.subtasks) do
                            todo[namestring2].parentindex = i
                        end

                        update_subtask_flow(force, parenttask.subtasks, task.parent_string)
                    else
                        local lookup = script_data.unfinished_todo[force]
                        local change = "unfinished_index"

                        if switch_state == "left" then
                            lookup = script_data.finished_todo[force]
                            change = "finished_index"
                        elseif switch_state == "none" then
                            lookup = script_data.all_todo[force]
                            change = "all_index"
                        end

                        table.remove(lookup, task[change])

                        if button == definesbutton.left then
                            table.insert(lookup, task[change] - 1, namestring)
                        else
                            table.insert(lookup, 1, namestring)
                        end

                        for i, namestring2 in pairs(lookup) do
                            todo[namestring2][change] = i
                        end

                        update_scrollpane(force, switch_state)
                    end

                    update_references(force, task.id_string)
                elseif number == "10" then
                    local task = todo[namestring]

                    if task.parent_string then
                        local parenttask = todo[task.parent_string]

                        table.remove(parenttask.subtasks, task.parentindex)

                        if button == definesbutton.left then
                            table.insert(parenttask.subtasks, task.parentindex + 1, namestring)
                        else
                            table.insert(parenttask.subtasks, namestring)
                        end

                        for i, namestring2 in pairs(parenttask.subtasks) do
                            todo[namestring2].parentindex = i
                        end

                        update_subtask_flow(force, parenttask.subtasks, task.parent_string)
                    else
                        local lookup = script_data.unfinished_todo[force]
                        local change = "unfinished_index"

                        if switch_state == "left" then
                            lookup = script_data.finished_todo[force]
                            change = "finished_index"
                        elseif switch_state == "none" then
                            lookup = script_data.all_todo[force]
                            change = "all_index"
                        end

                        table.remove(lookup, task[change])

                        if button == definesbutton.left then
                            table.insert(lookup, task[change] + 1, namestring)
                        else
                            table.insert(lookup, namestring)
                        end

                        for i, namestring2 in pairs(lookup) do
                            todo[namestring2][change] = i
                        end

                        update_scrollpane(force, switch_state)
                    end

                    update_references(force, task.id_string)
                elseif number == "11" then
                    playermeta.sub_open[namestring] = not playermeta.sub_open[namestring]
                    playermeta.subtaskflows[namestring].visible = playermeta.sub_open[namestring]

                    if playermeta.sub_open[namestring] then
                        playermeta.toggles[namestring].sprite = "utility/speed_up"
                    else
                        playermeta.toggles[namestring].sprite = "utility/speed_down"
                    end
                elseif number == "12" then
                    local task = todo[namestring]

                    if button == definesbutton.left then
                        if next(task.location) then
                            player.open_map(task.location, 1)
                        else
                            player.print({"TodoError.NoMapData"})
                        end
                    else
                        if settings.set_location or not game.is_multiplayer() then
                            if #task.title > 0 then
                                task.location = player.position

                                player.force.add_chart_tag(player.surface, {position = player.position, text = task.title})
                            else
                                player.print({"TodoError.NoTitle"})
                            end
                        else
                            player.print({"TodoRights.SetLocation"})
                        end
                    end
                elseif number == "13" then
                    local id_string = namestring:match("^([%w_]+=%d+)")
                    local task = todo[namestring]

                    if playermeta.reference_frames[id_string] then
                        if playermeta.reference_namestrings[id_string] == namestring then
                            playermeta:clear_reference(id_string)
                        else
                            playermeta:reference_internal(task, todo, namestring)
                        end
                    else
                        playermeta:reference_gui(todo, namestring)
                    end
                elseif number == "14" then
                    local task = todo[namestring]

                    remove_data(force, todo, namestring)

                    todo[namestring] = nil

                    if task.parent_string then
                        local id_string = task.id_string
                        local parenttask = todo[task.parent_string]

                        table.remove(parenttask.subtasks, task.parentindex)

                        for i, namestring2 in pairs(parenttask.subtasks) do
                            todo[namestring2].parentindex = i
                        end

                        update_subtask_flow(force, parenttask.subtasks, task.parent_string)

                        for _, player_id2 in pairs(script_data.player_lookup[force]) do
                            local playermeta2 = script_data.players[player_id2]

                            if playermeta2.reference_frames[id_string] then
                                local namestring2 = playermeta2.reference_namestrings[id_string]

                                if namestring2 == namestring then
                                    playermeta2:clear_reference(id_string)
                                else
                                    playermeta2:reference_internal(todo[namestring2], todo, namestring2)
                                end
                            end
                        end
                    else
                        table.remove(script_data.all_todo[force], task.all_index)

                        for i, namestring2 in pairs(script_data.all_todo[force]) do
                            todo[namestring2].all_index = i
                        end

                        if task.state then
                            table.remove(script_data.finished_todo[force], task.finished_index)

                            for i, namestring2 in pairs(script_data.finished_todo[force]) do
                                todo[namestring2].finished_index = i
                            end
                        else
                            table.remove(script_data.unfinished_todo[force], task.unfinished_index)

                            for i, namestring2 in pairs(script_data.unfinished_todo[force]) do
                                todo[namestring2].unfinished_index = i
                            end
                        end

                        update_scrollpane(force, "none-" .. (task.state and "left" or "right"))

                        for _, player_id2 in pairs(script_data.player_lookup[force]) do
                            local playermeta2 = script_data.players[player_id2]

                            if playermeta2.reference_frames[namestring] then
                                playermeta2:clear_reference(namestring)
                            end
                        end
                    end
                elseif number == "15" then
                    if #namestring > 0 then
                        local data = todo[namestring]
                        local newlevel = data.level + 1
                        local newnamestring = namestring .. ",L" .. newlevel .. "=" .. data.index

                        todo[newnamestring] = {
                            title = "",
                            description = "",
                            id_string = data.id_string,
                            parent_string = namestring,
                            state = false,
                            level = newlevel,
                            parentindex = #data.subtasks + 1,
                            index = (newlevel < 5 and 1) or nil,
                            assigned = {},
                            location = {},
                            subtasks = (newlevel < 5 and {}) or nil
                        }

                        data.index = data.index + 1

                        table.insert(data.subtasks, newnamestring)

                        update_subtask_flow(force, data.subtasks, namestring)
                        update_references(force, data.id_string)
                    else
                        local newnamestring = "id=" .. script_data.index

                        todo[newnamestring] = {
                            title = "",
                            description = "",
                            id_string = newnamestring,
                            state = false,
                            level = 0,
                            all_index = #script_data.all_todo[force] + 1,
                            unfinished_index = #script_data.unfinished_todo[force] + 1,
                            index = 1,
                            assigned = {},
                            location = {},
                            subtasks = {}
                        }

                        script_data.index = script_data.index + 1

                        table.insert(script_data.all_todo[force], newnamestring)
                        table.insert(script_data.unfinished_todo[force], newnamestring)

                        update_scrollpane(force, "none-right")
                    end
                elseif number == "16" then
                    playermeta.import_button.style = "frame_action_button"
                    playermeta:clear_import()
                elseif number == "17" then
                    if #playermeta.import_textbox.text > 0 then
                        local tasks = game.json_to_table(game.decode_string(playermeta.import_textbox.text))

                        if tasks and table_size(tasks) > 0 then
                            local finished_todo = script_data.finished_todo[force]
                            local all_todo = script_data.all_todo[force]
                            local unfinished_todo = script_data.unfinished_todo[force]

                            for _, task in pairs(tasks) do
                                if not task.parent_string then
                                    local newnamestring = "id=" .. script_data.index

                                    todo[newnamestring] = {
                                        title = task.title or "",
                                        description = task.description or "",
                                        id_string = newnamestring,
                                        state = task.state or false,
                                        all_index = #all_todo + 1,
                                        finished_index = (task.state and #finished_todo + 1) or nil,
                                        unfinished_todo = (not task.state and #unfinished_todo + 1) or nil,
                                        level = 0,
                                        index = 1,
                                        assigned = {},
                                        location = (type(task.location) == "table" and type(task.location.x) == "number" and type(task.location.y) == "number" and {x = task.location.x, y = task.location.y}) or {},
                                        subtasks = {}
                                    }

                                    script_data.index = script_data.index + 1

                                    table.insert(all_todo, newnamestring)

                                    if todo[newnamestring].state then
                                        table.insert(finished_todo, newnamestring)
                                    else
                                        table.insert(unfinished_todo, newnamestring)
                                    end

                                    if type(task.subtasks) == "table" and task.subtasks[1] then
                                        import_subtasks(todo[newnamestring], todo, task, tasks, newnamestring)
                                    end
                                end
                            end

                            playermeta.import_button.style = "frame_action_button"
                            playermeta:clear_import()

                            update_scrollpane(force, "all")
                        else
                            player.print({"TodoError.NoImportTable"})
                        end
                    else
                        player.print({"TodoError.NoImportText"})
                    end
                elseif number == "18" then
                    playermeta.export_button.style = "frame_action_button"
                    playermeta:clear_export()
                elseif number == "19" then
                    playermeta.export_textbox.focus()
                    playermeta.export_textbox.select_all()
                elseif number == "20" then
                    playermeta:clear_reference(namestring)
                elseif number == "21" then
                    playermeta.reference_open[namestring] = not playermeta.reference_open[namestring]
                    playermeta.reference_subtaskflows[namestring].visible = playermeta.reference_open[namestring]

                    if playermeta.reference_open[namestring] then
                        playermeta.reference_toggles[namestring].sprite = "utility/speed_up"
                    else
                        playermeta.reference_toggles[namestring].sprite = "utility/speed_down"
                    end
                end
            end
        end,
        [definesevents.on_gui_location_changed] = function(event)
            local playermeta = script_data.players[tostring(event.player_index)]
            local element = event.element

            if playermeta.frame and playermeta.frame.index == element.index then
                playermeta.location = element.location
            elseif playermeta.import_frame and playermeta.import_frame.index == element.index then
                playermeta.import_location = element.location
            elseif playermeta.export_frame and playermeta.export_frame.index == element.index then
                playermeta.export_location = element.location
            end
        end,
        [definesevents.on_gui_selection_state_changed] = function(event)
            local element = event.element
            local name = element.name

            if name:sub(1, 9) == "TODO_DROP" then
                local player_id = event.player_index
                local player_index = tostring(player_id)
                local player = game.players[player_id]
                local playermeta = script_data.players[player_index]
                local force = playermeta.force
                local number = name:sub(10, 11)
                local namestring = name:sub(13)
                local player_name = element.get_item(element.selected_index)
                local second_player_id = script_data.player_lookup[force][player_name]

                if number == "01" then
                    local task = script_data.todo[force][namestring]

                    if task.assigned[second_player_id] then
                        player.print({"TodoError.CantAssign"})
                    else
                        task.assigned[second_player_id] = player_name

                        update_player_flow(force, task.assigned, namestring)
                    end
                elseif number == "02" then
                    if second_player_id ~= player_index then
                        playermeta:settings_player_gui(script_data.players[second_player_id].settings, second_player_id)
                    else
                        player.print({"TodoError.CantEditYourself"})

                        element.selected_index = 0
                    end
                end
            end
        end,
        [definesevents.on_gui_switch_state_changed] = function(event)
            local element = event.element
            local name = element.name

            if name:sub(1, 11) == "TODO_SWITCH" then
                local playermeta = script_data.players[tostring(event.player_index)]
                local number = name:sub(12, 13)

                if number == "01" then
                    playermeta.switch_state = element.switch_state
                    playermeta:build_scrollpane(script_data)
                end
            end
        end,
        [definesevents.on_gui_text_changed] = function(event)
            local element = event.element
            local name = element.name

            if name:sub(1, 12) == "TODO_CHANGED" then
                local playermeta = script_data.players[tostring(event.player_index)]
                local number = name:sub(13, 14)
                local namestring = name:sub(16)

                if number == "01" then
                    playermeta.edit_titles[namestring] = element.text
                elseif number == "02" then
                    playermeta.edit_descriptions[namestring] = element.text
                end

                element.style.font = "default-bold"
                element.style.font_color  = {r = 75, g = 75, b = 75}
            end
        end,
        [definesevents.on_player_changed_force] = function(event)
            local player_id = tostring(event.player_index)
            local player = game.players[event.player_index]
            local playermeta = script_data.players[player_id]
            local oldid = tostring(event.force.index)
            local newid = tostring(player.force.index)

            if script_data.todo[oldid] then
                for namestring, task in pairs(script_data.todo[oldid]) do
                    task.assigned[player_id] = nil

                    update_player_flow(oldid, task.assigned, namestring)
                end

                script_data.player_table[oldid][player_id] = nil
                script_data.player_lookup[oldid][player.name] = nil
            end

            script_data.player_table[newid][player_id] = player.name
            script_data.player_lookup[newid][player.name] = player_id

            if playermeta.frame then
                playermeta:clear()

                for id_string, _ in pairs(playermeta.reference_frames) do
                    playermeta:clear_reference(id_string)
                end
            end

            playermeta.sub_open = {}
            playermeta.force = newid
            playermeta.button.number = #script_data.unfinished_todo[newid]
        end,
        [definesevents.on_player_created] = function(event)
            playerstart(event.player_index)
        end,
        [definesevents.on_player_demoted] = function(event)
            local settings = script_data.players[tostring(event.player_index)].settings

            if not settings.changed then
                for setting, _ in pairs(settings) do
                    if setting ~= "changed" then
                        settings[setting] = false
                    end
                end
            end
        end,
        [definesevents.on_player_promoted] = function(event)
            local playermeta = script_data.players[tostring(event.player_index)]

            if playermeta then
                local settings = playermeta.settings

                if not settings.changed then
                    for setting, _ in pairs(settings) do
                        if setting ~= "changed" then
                            settings[setting] = true
                        end
                    end
                end
            end
        end,
        [definesevents.on_pre_player_removed] = function(event)
            local player_index = event.player_index
            local player_id = tostring(player_index)
            local player = game.players[player_index]
            local force = tostring(game.players[player_index].force.index)

            for namestring, task in pairs(script_data.todo[force]) do
                task.assigned[player_id] = nil

                update_player_flow(force, task.assigned, namestring)
            end

            script_data.player_table[force][player_id] = nil
            script_data.player_lookup[force][player.name] = nil
            script_data.players[player_id] = nil
        end
    }
}