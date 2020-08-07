require "util"
require "mod-gui"

local player_lib = require "scripts/player"
local definesevents = defines.events
local definesbutton = defines.mouse_button_type
local table_deepcopy = util.table.deepcopy

local script_data = {
    index = 1,
    players = {},
    todo = {},
    finished_todo = {},
    all_todo = {},
    unfinished_todo = {},
    player_table = {},
    player_lookup = {}
}

local build_scrollpane_1 = function(switch_state)
    for _, playermeta in pairs(script_data.players) do
        if playermeta.frame and playermeta.switch_state == switch_state then
            playermeta:build_scrollpane()

            if playermeta.edit_frame then
                playermeta:clear_edit()
            end
        end
    end
end

local build_scrollpane_2 = function(switch_state)
    for _, playermeta in pairs(script_data.players) do
        if playermeta.frame and (playermeta.switch_state == "none" or playermeta.switch_state == switch_state) then
            playermeta:build_scrollpane()

            if playermeta.edit_frame then
                playermeta:clear_edit()
            end
        end
    end
end

local build_scrollpane_3 = function()
    for _, playermeta in pairs(script_data.players) do
        if playermeta.frame and (playermeta.switch_state == "left" or playermeta.switch_state == "right") then
            playermeta:build_scrollpane()

            if playermeta.edit_frame then
                playermeta:clear_edit()
            end
        end
    end
end

local build_reference = function(id)
    for _, playermeta in pairs(script_data.players) do
        local reference_frame = playermeta.reference_frames[id]

        if reference_frame then
            playermeta:reference_subtasks_gui(id)
        end
    end
end

local playerstart = function(player_index)
    if 	not script_data.players[tostring(player_index)] then
        local player = player_lib.new(game.players[player_index], script_data)

        script_data.players[player.index] = player
        script_data.player_table[player.index] = player.player.name
        script_data.player_lookup[player.player.name] = player.index
    end
end

local playerload = function()
    for _, player in pairs(game.players) do
        playerstart(player.index)
    end
end

--Events

local on_gui_checked_state_changed = function(event)
    local element = event.element
    local name = element.name

    if name:sub(1, 10) == "TODO_CHECK" then
        local player_id = event.player_index
        local player = game.players[player_id]
        local playermeta = script_data.players[tostring(player_id)]
        local state = element.state
        local number = name:sub(11, 12)
        local index = name:sub(14)

        if (number == "01" or number == "03") then
            local data = script_data.todo[index]

            if state then
                data.state = true

                for _, subdata in pairs(data.subtasks) do
                    subdata.state = true
                end

                for index_number, id2 in pairs(script_data.unfinished_todo) do
                    if id2 == index then
                        table.remove(script_data.unfinished_todo, index_number)
                        table.insert(script_data.finished_todo, index)

                        build_scrollpane_3()

                        break
                    end
                end

                for _, playermeta2 in pairs(script_data.players) do
                    local maincheckbox = playermeta2.maincheckboxes and playermeta2.maincheckboxes[index]
                    local reference_maincheckbox = playermeta2.reference_maincheckboxes[index]

                    if maincheckbox then
                        maincheckbox.state = true

                        local subcheckboxes = playermeta2.subcheckboxes[index]
                        
                        for index_number, subdata in pairs(data.subtasks) do
                            subcheckboxes[index_number].state = true
                        end
                    end

                    if reference_maincheckbox then
                        reference_maincheckbox.state = true

                        local reference_subcheckboxes = playermeta2.reference_subcheckboxes[index]

                        for index_number, subdata in pairs(data.subtasks) do
                            reference_subcheckboxes[index_number].state = true
                        end
                    end
                end
            else
                if player.admin then
                    data.state = false

                    for index_number, id2 in pairs(script_data.finished_todo) do
                        if id2 == index then
                            table.remove(script_data.finished_todo, index_number)
                            table.insert(script_data.unfinished_todo, index)

                            build_scrollpane_3()

                            break
                        end
                    end

                    for _, playermeta2 in pairs(script_data.players) do
                        local maincheckbox = playermeta2.maincheckboxes and playermeta2.maincheckboxes[index]
                        local reference_maincheckbox = playermeta2.reference_maincheckboxes[index]

                        if maincheckbox then
                            maincheckbox.state = false
                        end

                        if reference_maincheckbox then
                            reference_maincheckbox.state = false
                        end
                    end
                else
                    element.state = true

                    player.print({"Todo.NotAdminCheckbox"})
                end
            end
        elseif (number == "02" or number == "04") then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            local index_number = tonumber(name:sub(endnumber + 1))
            local subtask = script_data.todo[id].subtasks[index_number]

            if state then
                subtask.state = true

                for _, playermeta2 in pairs(script_data.players) do
                    local subcheckboxes = playermeta2.subcheckboxes and playermeta2.subcheckboxes[id]
                    local reference_subcheckboxes = playermeta2.reference_subcheckboxes and playermeta2.reference_subcheckboxes[id]

                    if subcheckboxes and subcheckboxes[index_number] then
                        subcheckboxes[index_number].state = true
                    end

                    if reference_subcheckboxes and reference_subcheckboxes[index_number] then
                        reference_subcheckboxes[index_number].state = true
                    end
                end
            else
                if player.admin then
                    subtask.state = false

                    for _, playermeta2 in pairs(script_data.players) do
                        local subcheckboxes = playermeta2.subcheckboxes and playermeta2.subcheckboxes[id]
                        local reference_subcheckboxes = playermeta2.reference_subcheckboxes and playermeta2.reference_subcheckboxes[id]

                        if subcheckboxes and subcheckboxes[index_number] then
                            subcheckboxes[index_number].state = false
                        end

                        if reference_subcheckboxes and reference_subcheckboxes[index_number] then
                            reference_subcheckboxes[index_number].state = false
                        end
                    end
                else
                    element.state = true

                    player.print({"Todo.NotAdminCheckbox"})
                end
            end
        elseif number == "05" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.add_tasks = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "06" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.delete_assigned_players = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "07" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.assign_players = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "08" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.sort_tasks = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "09" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.set_location = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "10" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.edit_tasks = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "11" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.delete_tasks = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        elseif number == "12" then
            playermeta = script_data.players[tostring(index)]
            playermeta.settings.changed = true
            playermeta.settings.add_subtasks = state

            if playermeta.frame then
                playermeta:clear()
                playermeta:gui()
            end
        end
    end
end

local on_gui_click = function(event)
    local element = event.element
    local name = element.name

    if name:sub(1, 10) == "TODO_CLICK" then
        local player_id = event.player_index
        local player = game.players[player_id]
        local playermeta = script_data.players[tostring(player_id)]
        local switch_state = playermeta.switch_state
        local button = event.button
        local number = name:sub(11, 12)

        if number == "01" then
            if playermeta.frame then
                playermeta:clear()
            else
                playermeta:gui()
            end
        elseif number == "02" then
            if playermeta.add_frame then
                playermeta:clear_add()
                element.style = "frame_action_button"
            else
                playermeta:add_gui()
                element.style = "todoframeactionselected"
            end
        elseif number == "03" then
            if playermeta.import_frame then
                playermeta:clear_import()
                element.style = "frame_action_button"
            else
                playermeta:import_gui()
                element.style = "todoframeactionselected"
            end
        elseif number == "04" then
            if playermeta.export_frame then
                playermeta:clear_export()
                element.style = "frame_action_button"
            else
                local todo = script_data.todo
                local data = {}

                if switch_state == "left" then
                    local t = {}

                    for _, id in pairs(script_data.finished_todo) do
                        table.insert(t, todo[id])
                    end

                    data = {state = switch_state, data = t}
                elseif switch_state == "none" then
                    local t = {}

                    for _, id in pairs(script_data.all_todo) do
                        table.insert(t, todo[id])
                    end

                    data = {state = switch_state, data = t}
                elseif switch_state == "right" then
                    local t = {}

                    for _, id in pairs(script_data.unfinished_todo) do
                        table.insert(t, todo[id])
                    end

                    data = {state = switch_state, data = t}
                end

                playermeta:export_gui(game.encode_string(game.table_to_json(data)))
                element.style = "todoframeactionselected"
            end
        elseif number == "05" then
            if playermeta.settings_frame then
                playermeta:clear_settings()
                element.style = "frame_action_button"
            else
                playermeta:settings_gui()
                element.style = "todoframeactionselected"
            end
        elseif number == "06" then
            playermeta:clear()
        elseif number == "07" then
            local _, endnumber, id = name:find("_(%d+)_", 13)

            script_data.todo[id].assigned[name:sub(endnumber + 1)] = nil

            build_scrollpane_2(switch_state)
        elseif number == "08" then
            script_data.todo[name:sub(14)].assigned[tostring(player_id)] = player.name

            build_scrollpane_2(switch_state)
        elseif number == "09" then
            local index = tonumber(name:sub(14))
            local lookup = {}

            if switch_state == "left" then
                lookup = script_data.finished_todo
            elseif switch_state == "none" then
                lookup = script_data.all_todo
            elseif switch_state == "right" then
                lookup = script_data.unfinished_todo
            end

            local t = table_deepcopy(lookup[index])
            table.remove(lookup, index)

            if button == definesbutton.left then
                table.insert(lookup, index - 1, t)
            elseif button == definesbutton.right then
                table.insert(lookup, 1, t)
            else
                table.insert(lookup, index, t)
            end

            build_scrollpane_1(switch_state)
        elseif number == "10" then
            local index = tonumber(name:sub(14))
            local lookup = {}

            if switch_state == "left" then
                lookup = script_data.finished_todo
            elseif switch_state == "none" then
                lookup = script_data.all_todo
            elseif switch_state == "right" then
                lookup = script_data.unfinished_todo
            end

            local t = table_deepcopy(lookup[index])
            table.remove(lookup, index)

            if button == definesbutton.left then
                table.insert(lookup, index + 1, t)
            elseif button == definesbutton.right then
                table.insert(lookup, t)
            else
                table.insert(lookup, index, t)
            end

            build_scrollpane_1(switch_state)
        elseif number == "11" then
            local id = name:sub(14)
            local flow = playermeta.mastersubtaskflows[id]
            local visible = flow.visible

            if visible then
                playermeta.togglebutton[id].sprite = "utility/speed_down"
                flow.visible = false
                playermeta.sub_open[id] = false
            else
                playermeta.togglebutton[id].sprite = "utility/speed_up"
                flow.visible = true
                playermeta.sub_open[id] = true
            end
        elseif (number == "12" or number == "29") then
            local task = script_data.todo[name:sub(14)]

            if button == definesbutton.left then
                if next(task.location) then
                    player.open_map(task.location)
                else
                    player.print({"Todo.NoLocation"})
                end
            elseif button == definesbutton.right then
                if playermeta.settings.set_location then
                    local position = player.position

                    task.location = position
                    player.force.add_chart_tag(player.surface, {position = position, text = task.title})
                else
                    player.print({"Todo.NoRights"})
                end
            end
        elseif number == "13" then
            local id = name:sub(14)

            if playermeta.reference_frames[id] then
                playermeta:clear_reference(id)
            else
                playermeta:reference_gui(id)
            end
        elseif number == "14" then
            if playermeta.edit_frame then
                playermeta:clear_edit()
            else
                playermeta:edit_gui(name:sub(14))
            end
        elseif number == "15" then
            local _, endnumber, index = name:find("_(%d+)_", 13)
            local id = name:sub(endnumber + 1)
            local state = script_data.todo[id].state

            if state then
                table.remove(script_data.finished_todo, tonumber(index))
                table.remove(script_data.all_todo, tonumber(index))
            else
                table.remove(script_data.all_todo, tonumber(index))
                table.remove(script_data.unfinished_todo, tonumber(index))
            end

            script_data.todo[id] = nil

            for _, playermeta2 in pairs(script_data.players) do
                local reference_frame = playermeta2.reference_frames[id]

                if reference_frame then
                    playermeta:clear_reference(id)
                end

                playermeta2.sub_open[id] = nil
            end

            build_scrollpane_2(switch_state)
        elseif number == "16" then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            local _, endnumber2, index_number = name:find("_(%d+)_", endnumber)

            script_data.todo[id].subtasks[tonumber(index_number)].assigned[name:sub(endnumber2 + 1)] = nil

            build_scrollpane_2(switch_state)
        elseif number == "17" then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            script_data.todo[id].subtasks[tonumber(name:sub(endnumber + 1))].assigned[tostring(player_id)] = player.name

            build_scrollpane_2(switch_state)
        elseif number == "18" then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            local index_number = tonumber(name:sub(endnumber + 1))
            local subtasks = script_data.todo[id].subtasks

            local t = table_deepcopy(subtasks[index_number])
            table.remove(subtasks, index_number)

            if button == definesbutton.left then
                table.insert(subtasks, index_number - 1, t)
            elseif button == definesbutton.right then
                table.insert(subtasks, 1, t)
            else
                table.insert(subtasks, index_number, t)
            end

            build_scrollpane_2(switch_state)
            build_reference(id)
        elseif number == "19" then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            local index_number = tonumber(name:sub(endnumber + 1))
            local subtasks = script_data.todo[id].subtasks

            local t = table_deepcopy(subtasks[index_number])
            table.remove(subtasks, index_number)

            if button == definesbutton.left then
                table.insert(subtasks, index_number + 1, t)
            elseif button == definesbutton.right then
                table.insert(subtasks, t)
            else
                table.insert(subtasks, index_number, t)
            end

            build_scrollpane_2(switch_state)
            build_reference(id)
        elseif (number == "20" or number == "30") then
            local _, endnumber, id = name:find("_(%d+)_", 13)
            local subtask = script_data.todo[id].subtasks[tonumber(name:sub(endnumber + 1))]

            if button == definesbutton.left then
                if next(subtask.location) then
                    player.open_map(subtask.location)
                else
                    player.print({"Todo.NoLocation"})
                end
            elseif button == definesbutton.right then
                if playermeta.settings.set_location then
                    local position = player.position

                    subtask.location = position
                    player.force.add_chart_tag(player.surface, {position = position, text = subtask.title})
                else
                    player.print({"Todo.NoRights"})
                end
            end
        elseif number == "21" then
            local _, endnumber, id = name:find("_(%d+)_", 13)

            table.remove(script_data.todo[id].subtasks, tonumber(name:sub(endnumber + 1)))

            build_scrollpane_2(switch_state)
            build_reference(id)
        elseif number == "22" then
            playermeta:clear_add()
            playermeta.add_button.style = "frame_action_button"
        elseif number == "23" then
            local text = playermeta.add_titletextfield.text

            if #text > 0 then
                local data = {
                    title = text,
                    description = playermeta.add_descriptiontextbox.text,
                    state = false,
                    assigned = {},
                    location = {},
                    subtasks = {}
                }

                local index = tostring(script_data.index)

                script_data.todo[index] = data
                script_data.index = script_data.index + 1

                if playermeta.add_checkbox.state then
                    table.insert(script_data.all_todo, 1, index)
                    table.insert(script_data.unfinished_todo, 1, index)
                else
                    table.insert(script_data.all_todo, index)
                    table.insert(script_data.unfinished_todo, index)
                end

                build_scrollpane_2("right")

                playermeta:clear_add()
                playermeta.add_button.style = "frame_action_button"
            else
                player.print({"Todo.NoTitle"})
            end
        elseif number == "24" then
            playermeta:clear_import()
            playermeta.import_button.style = "frame_action_button"
        elseif number == "25" then
        elseif number == "26" then
            playermeta:clear_export()
            playermeta.export_button.style = "frame_action_button"
        elseif number == "27" then
        elseif number == "28" then
            playermeta:clear_reference(name:sub(14))
        elseif number == "31" then
            playermeta:clear_edit()
        elseif number == "32" then
            local text = playermeta.edit_titletextfield.text

            if #text > 0 then
                local edit_subtasktextfields = playermeta.edit_subtasktextfields
                local boolean = true

                for _, element2 in pairs(edit_subtasktextfields) do
                    if #element2.text == 0 then
                        boolean = false

                        break
                    end
                end

                if boolean then
                    local id = name:sub(14)
                    local data = script_data.todo[id]
                    local description = playermeta.edit_descriptiontextbox.text

                    data.title = text
                    data.description = description

                    for index, subdata in pairs(data.subtasks) do
                        subdata.title = edit_subtasktextfields[index].text
                    end

                    for _, playermeta2 in pairs(script_data.players) do
                        local reference_frame = playermeta2.reference_frames[id]

                        if reference_frame then
                            playermeta2.reference_titles[id].caption = text
                            playermeta2.reference_descriptions[id].caption = description

                            local subtitles = playermeta2.reference_subtitles[id]

                            for index, element2 in pairs(subtitles) do
                                element2.caption = edit_subtasktextfields[index].text
                            end
                        end
                    end

                    build_scrollpane_2(switch_state)
                else
                    player.print({"Todo.NoTitleSubEdit"})
                end
            else
                player.print({"Todo.NoTitleEdit"})
            end
        end
    end
end

local on_gui_confirmed = function(event)
    local element = event.element
    local name = element.name

    if name:sub(1, 14) == "TODO_CONFIRMED" then
        local text = element.text

        if #text > 0 then
            local id = name:sub(18)

            table.insert(script_data.todo[id].subtasks, {
                title = text,
                state = false,
                assigned = {},
                location = {}
            })

            build_scrollpane_2(script_data.players[tostring(event.player_index)].switch_state)
            build_reference(id)
        else
            player.print({"NoTitle"})
        end
    end
end

local on_gui_location_changed = function(event)
    local playermeta = script_data.players[tostring(event.player_index)]
    local element = event.element

    if playermeta.frame and element.index == playermeta.frame.index then
        playermeta.location = element.location
    elseif playermeta.add_frame and element.index == playermeta.add_frame.index then
        playermeta.addgui_location = element.location
    elseif playermeta.edit_frame and element.index == playermeta.edit_frame.index then
        playermeta.editgui_location = element.location
    end
end

local on_gui_selection_state_changed = function(event)
    local element = event.element
    local name = element.name

    if name:sub(1, 9) == "TODO_DROP" then
        local player_id = event.player_index
        local player = game.players[player_id]
        local playermeta = script_data.players[tostring(player_id)]
        local player_name = element.get_item(element.selected_index)
        local player_index = script_data.player_lookup[player_name]
        local switch_state = playermeta.switch_state
        local number = name:sub(10, 11)

        if number == "01" then
            local assigned = script_data.todo[name:sub(13)].assigned

            if assigned[player_index] then
                element.selected_index = 0

                player.print({"Todo.AlreadyAssigned"})
            else
                assigned[player_index] = player_name

                build_scrollpane_2(switch_state)
            end
        elseif number == "02" then
            local _, endnumber, id = name:find("_(%d+)_", 12)
            local assigned = script_data.todo[id].subtasks[tonumber(name:sub(endnumber + 1))].assigned

            if assigned[player_index] then
                element.selected_index = 0

                player.print({"Todo.AlreadyAssigned"})
            else
                assigned[player_index] = player_name

                build_scrollpane_2(switch_state)
            end
        elseif number == "03" then
            if player_index ~= playermeta.index then
                playermeta:settings_player_gui(player_index)
            else
                element.selected_index = 0

                player.print({"Todo.CantEdit"})
            end
        end
    end
end

local on_gui_switch_state_changed = function(event)
    local element = event.element
    local name = element.name

    if name:sub(1, 11) == "TODO_SWITCH" then
        local playermeta = script_data.players[tostring(event.player_index)]
        playermeta.switch_state = element.switch_state
        playermeta:build_scrollpane()
    end
end

local on_player_created = function(event)
    playerstart(event.player_index)
end

local on_player_demoted = function(event)
    local settings = script_data.players[tostring(event.player_index)].settings

    if not settings.changed then
        for setting, _ in pairs(settings) do
            if setting ~= "changed" then
                settings[setting] = false
            end
        end
    end
end

local on_player_promoted = function(event)
    local player = script_data.players[tostring(event.player_index)]

    if player then
        local settings = player.settings

        if not settings.changed then
            for setting, _ in pairs(settings) do
                if setting ~= "changed" then
                    settings[setting] = true
                end
            end
        end
    end
end

local on_player_removed = function(event)
    local player_id = event.player_index

    script_data.players[tostring(player_id)] = nil
    script_data.player_table[tostring(player_id)] = nil
    script_data.player_lookup[game.players[player_id].name] = nil
end

local lib = {}

lib.events = {
    [definesevents.on_gui_checked_state_changed] = on_gui_checked_state_changed,
    [definesevents.on_gui_click] = on_gui_click,
    [definesevents.on_gui_confirmed] = on_gui_confirmed,
    [definesevents.on_gui_location_changed] = on_gui_location_changed,
    [definesevents.on_gui_selection_state_changed] = on_gui_selection_state_changed,
    [definesevents.on_gui_switch_state_changed] = on_gui_switch_state_changed,
    [definesevents.on_player_created] = on_player_created,
    [definesevents.on_player_demoted] = on_player_demoted,
    [definesevents.on_player_promoted] = on_player_promoted,
    [definesevents.on_player_removed] = on_player_removed
}

lib.on_init = function()
    global.script_data = global.script_data or script_data

    playerload()
end

lib.on_load = function()
	script_data = global.script_data or script_data

	for _, player in pairs(script_data.players) do
		setmetatable(player, player_lib.metatable)
    end
end

lib.on_configuration_changed = function()
    global.script_data = global.script_data or script_data

    playerload()
end

return lib