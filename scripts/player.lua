local player_data = {}

player_data.metatable = {__index = player_data}

function player_data.new(player, script_data)
    local admin = player.admin

    local module = {
        player = player,
        index = tostring(player.index),
        solid_location = {x = 5, y = 85 * player.display_scale},
        location = {x = 5, y = 85 * player.display_scale},
        addgui_location = {x = 5, y = 85 * player.display_scale},
        editgui_location = {x = 5, y = 85 * player.display_scale},
        button = mod_gui.get_button_flow(player).add{type = "sprite-button", name = "TODO_CLICK01", sprite = "todo", style = mod_gui.button_style},
        switch_state = "none",
        players = script_data.players,
        todo = script_data.todo,
        finished_todo = script_data.finished_todo,
        all_todo = script_data.all_todo,
        unfinished_todo = script_data.unfinished_todo,
        player_table = script_data.player_table,
        player_lookup = script_data.player_lookup,
        sub_open = {},
        reference_frames = {},
        reference_maincheckboxes = {},
        reference_titles = {},
        reference_descriptions = {},
        reference_vertical = {},
        reference_subcheckboxes = {},
        reference_subtitles = {},
        settings = {
            changed = false,
            add_tasks = admin,
            delete_assigned_players = admin,
            assign_players = admin,
            sort_tasks = admin,
            set_location = admin,
            edit_tasks = admin,
            delete_tasks = admin,
            add_subtasks = admin
        }
    }

    setmetatable(module, player_data.metatable)

    return module
end

function player_data:gui()
    local frame = self.player.gui.screen.add{type = "frame", style = "outer_frame"}
    frame.location = self.location
    self.frame = frame
    local mainframe = frame.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    local titleflow = mainframe.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.GuiTitle"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame

    if self.settings.add_tasks then
        self.add_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK02", tooltip = {"Todo.TooltipAdd"}, sprite = "todo-add", style = "frame_action_button"}
    end

    --self.import_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK03", tooltip = {"Todo.TooltipImport"}, sprite = "utility/import_slot", style = "frame_action_button"}
    --self.export_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK04", tooltip = {"Todo.TooltipExport"}, sprite = "utility/export_slot", style = "frame_action_button"}

    if self.player.admin then
        self.settings_button = titleflow.add{type ="sprite-button", name = "TODO_CLICK05", tooltip = {"Todo.TooltipSettings"}, sprite = "todo-settings", style = "frame_action_button"}
    end
    titleflow.add{type = "sprite-button", name = "TODO_CLICK06", sprite = "utility/close_white", style = "frame_action_button"}
    local inside_frame = mainframe.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "todosubheaderframe"}
    subheader_frame.add{type = "switch", name = "TODO_SWITCH01", tooltip = {"Todo.TooltipSwitch"}, switch_state = self.switch_state, allow_none_state = true, left_label_caption = "[img=todo-finished]", right_label_caption = "[img=todo-unfinished]"}
    subheader_frame.add{type = "label", caption = {"Todo.Task"}, style = "todomainlabel"}
    subheader_frame.add{type = "label", caption = {"Todo.Assigned"}, style = "todoassignedlabel"}
    subheader_frame.add{type = "label", caption = {"Todo.Sort"}, style = "todosortlabel"}
    subheader_frame.add{type = "label", caption = {"Todo.Options"}, style = "todooptionslabel"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    self.scrollpane = inside_frame.add{type = "scroll-pane", style = "todoscrollpane"}

    self:build_scrollpane()
end

function player_data:build_scrollpane()
    local todo = self.todo
    local tasks_lookup = {}
    local admin = self.player.admin
    local settings = self.settings
    local switch_state = self.switch_state

    if switch_state == "left" then
        tasks_lookup = self.finished_todo
    elseif switch_state == "none" then
        tasks_lookup = self.all_todo
    elseif switch_state == "right" then
        tasks_lookup = self.unfinished_todo
    end

    local task_amount = #tasks_lookup

    self.maincheckboxes = {}
    self.togglebutton = {}
    self.mastersubtaskflows = {}
    self.subcheckboxes = {}
    self.scrollpane.clear()

    for index, id in pairs(tasks_lookup) do
        local data = todo[id]
        local subtask_amount = #data.subtasks

        local mainflow = self.scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}
        self.maincheckboxes[id] = mainflow.add{type = "flow", direction = "horizontal", style = "todocheckboxflow"}.add{type = "checkbox", name = "TODO_CHECK01_" .. id, state = data.state}
        local mastertaskflow = mainflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
        local maintaskflow = mastertaskflow.add{type = "flow", direction = "horizontal", style = "todosecondflow"}

        if index == 1 then
            maintaskflow.style.top_padding = 0
        end

        maintaskflow.add{type = "label", caption = data.title, style = "todomainlabel"}
        local mainplayerflow = maintaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflowspacing"}

        for player_index, player_name in pairs(data.assigned) do
            if settings.delete_assigned_players or player_index == self.index then
                mainplayerflow.add{type = "label", name = "TODO_CLICK07_" .. id .. "_" .. player_index, tooltip = {"Todo.TooltipDeletePlayer"}, caption = player_name, style = "todoassignedlabelclickable"}
            else
                mainplayerflow.add{type = "label", caption = player_name, style = "todoassignedlabel"}
            end
        end

        if not data.assigned[self.index] then
            mainplayerflow.add{type = "button",name  = "TODO_CLICK08_" .. id, caption = {"Todo.Take"}}.style.width = 150
        end

        if settings.assign_players then
            mainplayerflow.add{type = "drop-down", name = "TODO_DROP01_" .. id, items = self.player_table}.style.width = 150
        end

        local mainsortflow = maintaskflow.add{type = "flow", direction = "horizontal", style = "todoflow5"}

        if settings.sort_tasks then
            if index == 1 then
                mainsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            else
                mainsortflow.add{type = "sprite-button", name = "TODO_CLICK09_" .. index, tooltip = {"Todo.TooltipSortUp"},  sprite = "todo-up", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
            end

            if index == task_amount then
                mainsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            else
                mainsortflow.add{type = "sprite-button", name = "TODO_CLICK10_" .. index, tooltip = {"Todo.TooltipSortDown"},  sprite = "todo-down", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
            end
        else
            mainsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            mainsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
        end

        local mainoptionflow = maintaskflow.add{type = "flow", direction = "horizontal", style = "todoflow5"}

        if self.sub_open[id] then
            self.togglebutton[id] = mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK11_" .. id, tooltip = {"Todo.TooltipOpen"}, sprite = "utility/speed_up", style = "tool_button"}
        else
            self.togglebutton[id] = mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK11_" .. id, tooltip = {"Todo.TooltipOpen"}, sprite = "utility/speed_down", style = "tool_button"}
        end
        mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK12_" .. id, tooltip = {"Todo.TooltipMap"}, sprite = "utility/map", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
        mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK13_" .. id, tooltip = {"Todo.TooltipReference"}, sprite = "todo-clipboard", style = "tool_button"}

        if settings.edit_tasks then
            mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK14_" .. id, tooltip = {"Todo.TooltipEdit"}, sprite = "utility/change_recipe", style = "tool_button"}
        else
            mainoptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
        end

        if settings.delete_tasks then
            mainoptionflow.add{type = "sprite-button", name = "TODO_CLICK15_" .. index .. "_" .. id, tooltip = {"Todo.TooltipDelete"}, sprite = "utility/trash", style = "tool_button_red"}
        else
            mainoptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
        end

        local mastersubtaskflow = mastertaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
        mastersubtaskflow.add{type = "flow", direction = "horizontal", style = "todosecondflow"}.add{type = "label", caption = data.description, style = "todomainlabel"}

        if not self.sub_open[id] then
            mastersubtaskflow.visible = false
        end

        self.mastersubtaskflows[id] = mastersubtaskflow
        self.subcheckboxes[id] = {}

        for index_number, subdata in pairs(data.subtasks) do
            local mainsubtaskflow = mastersubtaskflow.add{type = "flow", direction = "horizontal", style = "todosecondflow"}
            local mainsubtasklabelflow = mainsubtaskflow.add{type = "flow", direction = "horizontal", style = "todoflow5align"}
            self.subcheckboxes[id][index_number] = mainsubtasklabelflow.add{type = "checkbox", name = "TODO_CHECK02_" .. id .. "_" .. index_number, state = subdata.state}
            mainsubtasklabelflow.add{type = "label", caption = subdata.title, style = "todosubtasklabel"}
            local mainsubplayerflow = mainsubtaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflowspacing"}

            for player_index, player_name in pairs(subdata.assigned) do
                if settings.delete_assigned_players or index_number == self.index then
                    mainsubplayerflow.add{type = "label", name = "TODO_CLICK16_" .. id .. "_" .. index_number .. "_" .. player_index, caption = player_name, style = "todoassignedlabelclickable"}
                else
                    mainsubplayerflow.add{type = "label", caption = player_name, style = "todoassignedlabel"}
                end
            end

            if not subdata.assigned[self.index] then
                mainsubplayerflow.add{type = "button",name  = "TODO_CLICK17_" .. id .. "_" .. index_number, caption = {"Todo.Take"}}.style.width = 150
            end

            if settings.assign_players then
                mainsubplayerflow.add{type = "drop-down", name = "TODO_DROP02_" .. id .. "_" .. index_number, items = self.player_table}.style.width = 150
            end

            local mainsubsortflow = mainsubtaskflow.add{type = "flow", direction = "horizontal", style = "todoflow5"}

            if settings.sort_tasks then
                if index_number == 1 then
                    mainsubsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
                else
                    mainsubsortflow.add{type = "sprite-button", name = "TODO_CLICK18_" .. id .. "_" .. index_number, tooltip = {"Todo.TooltipSortUp"}, sprite = "todo-up", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
                end

                if index_number == subtask_amount then
                    mainsubsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
                else
                    mainsubsortflow.add{type = "sprite-button", name = "TODO_CLICK19_" .. id .. "_" .. index_number, tooltip = {"Todo.TooltipSortDown"}, sprite = "todo-down", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
                end
            else
                mainsubsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
                mainsubsortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            end

            local mainsuboptionflow = mainsubtaskflow.add{type = "flow", direction = "horizontal", style = "todoflow5"}

            mainsuboptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            mainsuboptionflow.add{type = "sprite-button", name = "TODO_CLICK20_" .. id .. "_" .. index_number, tooltip = {"Todo.TooltipMap"}, sprite = "utility/map", style = "tool_button"}
            mainsuboptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            mainsuboptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}

            if settings.delete_tasks then
                mainsuboptionflow.add{type = "sprite-button", name = "TODO_CLICK21_" .. id .. "_" .. index_number, tooltip = {"Todo.TooltipDelete"}, sprite = "utility/trash", style = "tool_button_red"}
            else
                mainsuboptionflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            end
        end

        if settings.add_subtasks then
            mastersubtaskflow.add{type = "flow", direction = "horizontal", style = "todosecondflow"}.add{type = "textfield", name = "TODO_CONFIRMED01_" .. id, tooltip = {"Todo.TooltipAddSubtask"}, style = "todoaddtitletextfield"}
        end

        if task_amount > 1 and index ~= task_amount then
            self.scrollpane.add{type = "line", style = "todoline"}
        end
    end
end

function player_data:add_gui()
    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.addgui_location
    self.add_frame = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.AddGui"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK22", sprite = "utility/close_white", style = "frame_action_button"}
    local inside_frame = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "subheader_frame"}
    subheader_frame.add{type = "label", caption = {"Todo.AddGuiCaption"}, style = "subheader_caption_label"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    local todotitleflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    todotitleflow.add{type = "label", caption = {"Todo.Title"}, style = "todoaddlabel"}
    self.add_titletextfield = todotitleflow.add{type = "textfield", style = "todoaddtitletextfield"}
    local tododescriptionflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    tododescriptionflow.add{type = "label", caption = {"Todo.Description"}, style = "todoaddlabel"}
    self.add_descriptiontextbox = tododescriptionflow.add{type = "text-box", style = "todoadddescriptiontextbox"}
    local checkboxflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    checkboxflow.style.bottom_padding = 10
    self.add_checkbox = checkboxflow.add{type = "checkbox", caption = {"Todo.AddTop"}, state = false}
    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "empty-widget", style = "todowidget"}
    flow.add{type = "button", name = "TODO_CLICK23", caption = {"Todo.AddTask"}, style = "confirm_button"}
end

function player_data:import_gui()
    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.force_auto_center()
    self.import_frame = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Import"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK24", sprite = "utility/close_white", style = "frame_action_button"}
    local textbox = frame.add{type = "text-box"}
    textbox.style.width = 400
    textbox.style.height = 250
    self.import_textbox = textbox
    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "empty-widget", style = "todowidget"}
    flow.add{type = "button", name = "TODO_CLICK25", caption = {"gui-permissions.import"}, style = "dialog_button"}
end

function player_data:export_gui(text)
    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.force_auto_center()
    self.export_frame = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Export"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK26", sprite = "utility/close_white", style = "frame_action_button"}
    local textbox = frame.add{type = "text-box", text = text}
    textbox.style.width = 400
    textbox.style.height = 250
    self.export_textbox = textbox
    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "button", name = "TODO_CLICK27", caption = {"Todo.SelectAll"}, style = "dialog_button"}
    flow.add{type = "empty-widget", style = "todowidget"}
end

function player_data:reference_gui(id)
    local data = self.todo[id]

    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.solid_location
    self.reference_frames[id] = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Task"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK28_" .. id, sprite = "utility/close_white", style = "frame_action_button"}
    local inside_frame = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "todorefenrecesubheaderframe"}
    self.reference_maincheckboxes[id] = subheader_frame.add{type = "checkbox", name = "TODO_CHECK03_" .. id, state = data.state}
    self.reference_titles[id] = subheader_frame.add{type = "label", caption = data.title, style = "todoreferencetitle"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    subheader_frame.add{type = "sprite-button", name = "TODO_CLICK29_" .. id, tooltip = {"Todo.TooltipMap"}, sprite = "utility/map", style = "tool_button"}
    local scrollpane = inside_frame.add{type = "scroll-pane", style = "todoreferencescrollpane"}
    local tododescriptionflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    tododescriptionflow.add{type = "label", caption = {"Todo.Description"}, style = "todoaddlabel"}
    self.reference_descriptions[id] = tododescriptionflow.add{type = "label", caption = data.description, style = "todoreferencedescriptionlabel"}
    local todosubtaskflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    todosubtaskflow.style.bottom_padding = 10
    todosubtaskflow.add{type = "label", caption = {"Todo.Subtasks"}, style = "todoaddlabel"}
    self.reference_vertical[id] = todosubtaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
    self:reference_subtasks_gui(id)
end

function player_data:reference_subtasks_gui(id)
    local subtasks = self.todo[id].subtasks
    local flow = self.reference_vertical[id]
    flow.clear()

    self.reference_subcheckboxes[id] = {}
    self.reference_subtitles[id] = {}

    for index, subdata in pairs(subtasks) do
        local horizontal = flow.add{type = "flow", direction = "horizontal", style = "todoflow5align"}
        self.reference_subcheckboxes[id][index] = horizontal.add{type = "checkbox", name = "TODO_CHECK04_" .. id .. "_" .. index, state = subdata.state}
        self.reference_subtitles[id][index] = horizontal.add{type = "label", caption = subdata.title, style = "todosubtasklabel"}
        horizontal.add{type = "sprite-button", name = "TODO_CLICK30_" .. id .. "_" .. index, tooltip = {"Todo.TooltipMap"}, sprite = "utility/map", style = "tool_button"}
    end
end

function player_data:edit_gui(id)
    local data = self.todo[id]

    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.editgui_location
    self.edit_frame = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.EditGui"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK31", sprite = "utility/close_white", style = "frame_action_button"}
    local inside_frame = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "subheader_frame"}
    subheader_frame.add{type = "label", caption = {"Todo.EditGuiCaption"}, style = "subheader_caption_label"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    local todotitleflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    todotitleflow.add{type = "label", caption = {"Todo.Title"}, style = "todoaddlabel"}
    self.edit_titletextfield = todotitleflow.add{type = "textfield", text = data.title, style = "todoaddtitletextfield"}
    local tododescriptionflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    tododescriptionflow.add{type = "label", caption = {"Todo.Description"}, style = "todoaddlabel"}
    self.edit_descriptiontextbox = tododescriptionflow.add{type = "text-box", text = data.description, style = "todoadddescriptiontextbox"}
    local todosubtaskflow = inside_frame.add{type = "flow", direction = "horizontal", style = "todoaddflow"}
    todosubtaskflow.add{type = "label", caption = {"Todo.Subtasks"}, style = "todoaddlabel"}
    local verticalflow = todosubtaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}

    self.edit_subtasktextfields = {}

    for index, subdata in pairs(data.subtasks) do
        self.edit_subtasktextfields[index] = verticalflow.add{type = "textfield", text = subdata.title, style = "todoaddtitletextfield"}
    end

    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "empty-widget", style = "todowidget"}
    flow.add{type = "button", name = "TODO_CLICK32_" .. id, caption = {"Todo.ApplyEdit"}, style = "confirm_button"}
end

function player_data:settings_gui()
    local frame = self.frame.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    self.settings_frame = frame
    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.SettingsTitle"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = self.frame
    local inside_frame = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "subheader_frame"}
    subheader_frame.add{type = "label", caption = {"Todo.SettingsCaption"}, style = "subheader_caption_label"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    subheader_frame.add{type = "drop-down", name = "TODO_DROP03", items = self.player_table}
    self.settings_scrollpane = inside_frame.add{type = "scroll-pane", style = "todoscrollpane"}
end

function player_data:settings_player_gui(player_index)
    self.settings_scrollpane.clear()

    local scrollpane = self.settings_scrollpane
    local settings = self.players[player_index].settings

    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK05_" .. player_index, caption ={"Todo.SettingsAddTask"}, state = settings.add_tasks}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK06_" .. player_index, caption ={"Todo.SettingsDeletePlayer"}, state = settings.delete_assigned_players}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK07_" .. player_index, caption ={"Todo.SettingsAssignPlayer"}, state = settings.assign_players}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK08_" .. player_index, caption ={"Todo.SettingsSortTask"}, state = settings.sort_tasks}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK09_" .. player_index, caption ={"Todo.SettingsSetLocation"}, state = settings.set_location}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK10_" .. player_index, caption ={"Todo.SettingsEditTask"}, state = settings.edit_tasks}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK11_" .. player_index, caption ={"Todo.SettingsDeleteTask"}, state = settings.delete_tasks}
    scrollpane.add{type = "flow", direction = "horizontal", style = "todomainflow"}.add{type = "checkbox", name = "TODO_CHECK12_" .. player_index, caption ={"Todo.SettingsAddSubtask"}, state = settings.add_subtasks}
end

function player_data:clear()
    self.frame.destroy()
    self.frame = nil
    self.add_button = nil
    self.import_button = nil
    self.export_button = nil
    self.settings_button = nil
    self.scrollpane = nil
    self.togglebutton = nil
    self.mastersubtaskflows = nil
    self.subcheckboxes = nil

    if self.add_frame then
        self:clear_add()
    end

    if self.import_frame then
        self:clear_import()
    end

    if self.export_frame then
        self:clear_export()
    end

    if self.edit_frame then
        self:clear_edit()
    end

    if self.settings_frame then
        self:clear_settings()
    end
end

function player_data:clear_add()
    self.add_frame.destroy()
    self.add_frame = nil
    self.add_titletextfield = nil
    self.add_descriptiontextbox = nil
    self.add_checkbox = nil
end

function player_data:clear_import()
    self.import_frame.destroy()
    self.import_frame = nil
    self.import_textbox = nil
end

function player_data:clear_export()
    self.export_frame.destroy()
    self.export_frame = nil
    self.export_textbox = nil
end

function player_data:clear_reference(id)
    self.reference_frames[id].destroy()
    self.reference_frames[id] = nil
    self.reference_maincheckboxes[id] = nil
    self.reference_titles[id] = nil
    self.reference_descriptions[id] = nil
    self.reference_vertical[id] = nil
    self.reference_subcheckboxes[id] = nil
    self.reference_subtitles[id] = nil
end

function player_data:clear_edit()
    self.edit_frame.destroy()
    self.edit_frame = nil
    self.edit_titletextfield = nil
    self.edit_descriptiontextbox = nil
    self.edit_subtasktextfields = nil
end

function player_data:clear_settings()
    self.settings_frame.destroy()
    self.settings_frame = nil
    self.settings_scrollpane = nil
end

return player_data