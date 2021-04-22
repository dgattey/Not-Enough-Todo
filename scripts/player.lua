local mod_gui = require "mod-gui"
local player_data = {}
local filter = {"left"}

player_data.metatable = {__index = player_data}

function player_data.new(player, amount)
    local admin = player.admin

    local module = {
        player = player,
        index = tostring(player.index),
        force = tostring(player.force.index),
        location = {x = 5, y = 85 * player.display_scale},
        import_location = {x = 5, y = 85 * player.display_scale},
        export_location = {x = 5, y = 85 * player.display_scale},
        solid_location = {x = 5, y = 85 * player.display_scale},
        button = mod_gui.get_button_flow(player).add{type = "sprite-button", name = "TODO_CLICK01_", tooltip = {"TodoTooltip.MainButton"}, sprite = "todo", mouse_button_filter = filter, number = amount, style = mod_gui.button_style},
        switch_state = "none",
        sub_open = {},
        reference_frames = {},
        reference_internal_frames = {},
        reference_id_namestrings = {},
        reference_namestrings = {},
        reference_open = {},
        reference_checkboxes = {},
        reference_titles = {},
        reference_toggles = {},
        reference_descriptions = {},
        reference_subtaskflows = {},
        edit_mode = false,
        settings = {
            changed = false,
            add_subtasks = admin,
            add_tasks = admin,
            assign_players = admin,
            delete_assigned_players = admin,
            delete_tasks = admin,
            edit_tasks = admin,
            export_tasks = admin,
            import_tasks = admin,
            set_location = admin,
            sort_tasks = admin,
            unfinish_tasks = admin
        }
    }

    setmetatable(module, player_data.metatable)

    return module
end

function player_data:gui(script_data)
    local settings = self.settings
    local is_multiplayer = game.is_multiplayer()

    local frame = self.player.gui.screen.add{type = "frame", style = "outer_frame"}
    frame.location = self.location
    self.frame = frame

    local mainframe = frame.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}

    local titleflow = mainframe.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.GuiTitle"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame

    if settings.add_tasks or settings.delete_assigned_players or settings.assign_players or settings.sort_tasks or settings.edit_tasks or settings.delete_tasks or settings.add_subtasks then
        self.edit_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK02", tooltip = {"TodoTooltip.Edit"}, sprite = "todo-edit", mouse_button_filter = filter}

        if self.edit_mode then
            self.edit_button.style = "todoframeactionselected"
        else
            self.edit_button.style = "frame_action_button"
        end
    end

    if settings.import_tasks or not is_multiplayer then
        self.import_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK03", tooltip = {"TodoTooltip.Import"}, sprite = "todo-import", mouse_button_filter = filter, style = "frame_action_button"}
    end

    if settings.export_tasks or not is_multiplayer then
        self.export_button = titleflow.add{type = "sprite-button", name = "TODO_CLICK04", tooltip = {"TodoTooltip.Export"}, sprite = "todo-export", mouse_button_filter = filter, style = "frame_action_button"}
    end

    if self.player.admin and is_multiplayer then
        self.settings_button = titleflow.add{type ="sprite-button", name = "TODO_CLICK05", tooltip = {"TodoTooltip.Settings"}, sprite = "todo-settings", style = "frame_action_button"}
    end

    titleflow.add{type = "sprite-button", name = "TODO_CLICK06", sprite = "utility/close_white", mouse_button_filter = filter, style = "frame_action_button"}

    local inside_frame = mainframe.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}

    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "todosubheaderframe"}
    subheader_frame.add{type = "flow", direction = "horizontal", style = "todoswitchflow"}.add{type = "switch", name = "TODO_SWITCH01", tooltip = {"TodoTooltip.Switch"}, switch_state = self.switch_state, allow_none_state = true, left_label_caption = "[img=todo-finished]", right_label_caption = "[img=todo-unfinished]"}
    subheader_frame.add{type = "label", caption = {"Todo.Task"}, style = "todotasklabel"}
    subheader_frame.add{type = "label", caption = {"Todo.Assigned"}, style = "todoassignedlabel"}
    self.sort = subheader_frame.add{type = "label", caption = {"Todo.Sort"}, style = "todosortlabel"}
    self.sort.visible = self.edit_mode
    subheader_frame.add{type = "label", caption = {"Todo.Options"}}.style.right_padding = 4

    local scrollpane = inside_frame.add{type = "scroll-pane", style = "todoscrollpane"}
    scrollpane.style.maximal_height = self.player.display_resolution.height * 0.83 / self.player.display_scale

    self.table = scrollpane.add{type = "table", column_count = 2, draw_vertical_lines = true, draw_horizontal_lines = true, style = "todomaintable"}

    self:build_scrollpane(script_data)
end

function player_data:build_scrollpane(script_data)
    local switch_state = self.switch_state
    local table = self.table
    local force = self.force
    local lookup = (switch_state == "left" and script_data.finished_todo[force]) or (switch_state == "none" and script_data.all_todo[force]) or script_data.unfinished_todo[force]
    local task_amount = #lookup

    table.clear()

    self.checkboxes = {}
    self.subtaskflows = {}
    self.titles = {}
    self.descriptions = {}
    self.players = {}
    self.toggles = {}
    self.edit_titles = self.edit_titles or {}
    self.edit_descriptions = self.edit_descriptions or {}

    for i, namestring in pairs(lookup) do
        self:add_task(script_data.todo[force], script_data.player_table[force], namestring, task_amount, i)
    end

    if self.edit_mode and (self.settings.add_tasks or not game.is_multiplayer()) then
        table.add{type = "flow", direction = "horizontal", style = "todoswitchflow"}.add{type = "sprite-button", name = "TODO_CLICK15", tooltip = {"TodoTooltip.AddTask"}, sprite = "utility/add", mouse_button_filter = filter, style = "tool_button"}
    end
end

function player_data:add_task(todo, player_table, namestring, task_amount, index)
    local data = todo[namestring]

    self.sub_open[namestring] = (self.sub_open[namestring] == nil and true) or self.sub_open[namestring]
    self.checkboxes[namestring] = self.table.add{type = "flow", direction = "horizontal", style = "todoswitchflow"}.add{type = "checkbox", name = "TODO_CHECK01_" .. namestring, state = data.state}

    local taskflow = self.table.add{type = "flow", direction = "vertical", style = "todotaskflow"}
    local maintaskflow = taskflow.add{type = "flow", direction = "horizontal", style = "todohorizontalflow"}
    local subtaskflow = taskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
    subtaskflow.visible = self.sub_open[namestring]

    self.subtaskflows[namestring] = subtaskflow
    self:add_task_data(data, maintaskflow, player_table, namestring, task_amount, index, true)
    self:add_subtasks(data.subtasks, todo, player_table, namestring)
end

function player_data:add_subtasks(subtasks, todo, player_table, parentnamestring)
    local task_amount = #subtasks
    local flow = self.subtaskflows[parentnamestring]

    flow.clear()

    for i, namestring in pairs(subtasks) do
        local data = todo[namestring]

        self:add_subtask(data, flow, player_table, namestring, task_amount, i)

        if data.level < 5 then
            self:add_subtasks(data.subtasks, todo, player_table, namestring)

            if i ~= task_amount then
                flow.add{type = "line", style = "todotaskline"}
            end
        end
    end

    if self.edit_mode and (self.settings.add_subtasks or not game.is_multiplayer()) then
        flow.add{type = "sprite-button", name = "TODO_CLICK15_" .. parentnamestring, tooltip = {"TodoTooltip.AddSubtask"}, sprite = "utility/add", mouse_button_filter = filter, style = "tool_button"}
    end
end

function player_data:add_subtask(data, subtaskflow, player_table, namestring, task_amount, index)
    local flow = subtaskflow.add{type = "flow", direction = "horizontal", style = "todohorizontalflow8top"}

    self.sub_open[namestring] = (data.level < 5 and self.sub_open[namestring] == nil and true) or self.sub_open[namestring]
    self.checkboxes[namestring] = flow.add{type = "flow", direction = "horizontal", style = "todocheckboxflow"}.add{type = "checkbox", name = "TODO_CHECK02_" .. namestring, state = data.state}

    local taskflow = flow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
    local maintaskflow = taskflow.add{type = "flow", direction = "horizontal", style = "todohorizontalflow"}
    local newsubtaskflow = (data.level < 5 and taskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}) or nil

    self.subtaskflows[namestring] = newsubtaskflow

    if data.level < 5 then
        newsubtaskflow.visible = self.sub_open[namestring]
    end

    self:add_task_data(data, maintaskflow, player_table, namestring, task_amount, index, false)
end

function player_data:add_task_data(data, maintaskflow, player_table, namestring, task_amount, index, maintaskboolean)
    local is_multiplayer = game.is_multiplayer()
    local settings = self.settings
    local edit_mode = self.edit_mode
    local maintaskdescriptionflow = maintaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow8right"}
    local title = {}
    local description = {}

    if edit_mode and (settings.edit_tasks or not is_multiplayer) then
        title = maintaskdescriptionflow.add{type = "textfield", name = "TODO_CHANGED01_" .. namestring, text = data.title, clear_and_focus_on_right_click = true, style = "todotasktextfield"}

        if self.edit_titles[namestring] then
            title.text = self.edit_titles[namestring]
            title.style.font = "default-bold"
            title.style.font_color = {r = 75, g = 75, b = 75}
        end

        description = maintaskdescriptionflow.add{type = "text-box", name = "TODO_CHANGED02_" .. namestring, text = data.description, clear_and_focus_on_right_click = true, style = "todotasktextbox"}
        description.word_wrap = true

        if self.edit_descriptions[namestring] then
            description.text = self.edit_descriptions[namestring]
            description.style.font = "default-bold"
            description.style.font_color = {r = 75, g = 75, b = 75}
        end
    else
        title = maintaskdescriptionflow.add{type = "label", caption = data.title, style = "todotasklabeldata"}
        description = maintaskdescriptionflow.add{type = "label", caption = data.description, style = "todotaskdescription"}
    end

    if maintaskboolean then
        maintaskdescriptionflow.style.width = 408
    else
        maintaskflow.add{type = "empty-widget", style = "todowidget"}
    end

    local playerflow = maintaskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow8right"}

    if is_multiplayer then
        self:add_assigned_data(data.assigned, playerflow, player_table, namestring)
    else
        playerflow.add{type = "label", caption = self.player.name, style = "todoassignedlabeldata"}
    end

    if edit_mode then
        local sortflow = maintaskflow.add{type = "flow", direction = "horizontal", style = "todohorizonalflow8right2spacing"}

        if settings.sort_tasks or not is_multiplayer then
            if index == 1 then
                sortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            else
                sortflow.add{type = "sprite-button", name = "TODO_CLICK09_" .. namestring, tooltip = {"TodoTooltip.SortUp"}, sprite = "todo-up", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
            end

            if index == task_amount then
                sortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            else
                sortflow.add{type = "sprite-button", name = "TODO_CLICK10_" .. namestring, tooltip = {"TodoTooltip.SortDown"}, sprite = "todo-down", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
            end
        else
            sortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
            sortflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
        end
    end

    local optionsflow = maintaskflow.add{type = "flow", direction = "horizontal", style = "todohorizonalflow2spacing"}

    if data.level < 5 then
        local togglesbutton = {}

        togglesbutton = optionsflow.add{type = "sprite-button", name = "TODO_CLICK11_" .. namestring, tooltip = {"TodoTooltip.Toggle"}, sprite = (self.sub_open[namestring] and "utility/speed_up") or "utility/speed_down", mouse_button_filter = filter, number = #data.subtasks, style = "tool_button"}

        self.toggles[namestring] = togglesbutton
    else
        optionsflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
    end

    if not edit_mode then
        optionsflow.add{type = "sprite-button", name = "TODO_CLICK12_" .. namestring, tooltip = {"TodoTooltip.Map"}, sprite = "utility/map", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
        optionsflow.add{type = "sprite-button", name = "TODO_CLICK13_" .. namestring, tooltip = {"TodoTooltip.Reference"}, sprite = "todo-clipboard", style = "tool_button"}
    else
        optionsflow.add{type = "empty-widget", style = "todoplaceholderwidget"}

        if settings.delete_tasks or not is_multiplayer then
            optionsflow.add{type = "sprite-button", name = "TODO_CLICK14_" .. namestring, tooltip = {"TodoTooltip.Delete"}, sprite = "utility/trash", mouse_button_filter = filter, style = "tool_button_red"}
        else
            optionsflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
        end
    end

    self.titles[namestring] = title
    self.descriptions[namestring] = description
    self.players[namestring] = playerflow
end

function player_data:add_assigned_data(assigned, playerflow, player_table, namestring)
    local edit_mode = self.edit_mode
    local settings = self.settings

    playerflow.clear()

    for player_index, player_name in pairs(assigned) do
        if (edit_mode and settings.delete_assigned_players) or player_index == self.index then
            playerflow.add{type = "label", name = "TODO_CLICK07_" .. namestring .. ",player_index=" .. player_index, tooltip = {"TodoTooltip.DeletePlayer"}, caption = player_name, mouse_button_filter = filter, style = "todoassignedlabelclickabledata"}
        else
            playerflow.add{type = "label", caption = player_name, style = "todoassignedlabeldata"}
        end
    end

    if not assigned[self.index] then
        playerflow.add{type = "button", name = "TODO_CLICK08_" .. namestring, mouse_button_filter = filter, caption = {"Todo.AssignMe"}, style = "todoassignedbutton"}
    end

    if edit_mode and settings.assign_players then
        playerflow.add{type = "drop-down", name = "TODO_DROP01_" .. namestring, items = player_table, style = "todoassigneddropdown"}
    end
end

function player_data:import_gui()
    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.import_location

    self.import_frame = frame

    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Import"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK16", sprite = "utility/close_white", mouse_button_filter = filter, style = "frame_action_button"}

    local textbox = frame.add{type = "text-box", clear_and_focus_on_right_click = true}
    textbox.style.width = 400
    textbox.style.height = 250
    textbox.word_wrap = true

    self.import_textbox = textbox

    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "empty-widget", style = "todowidget"}
    flow.add{type = "button", name = "TODO_CLICK17", caption = {"gui-permissions.import"}, mouse_button_filter = filter, style = "dialog_button"}
end

function player_data:export_gui(text)
    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.export_location

    self.export_frame = frame

    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Export"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK18", sprite = "utility/close_white", mouse_button_filter = filter, style = "frame_action_button"}

    local textbox = frame.add{type = "text-box", text = text}
    textbox.style.width = 400
    textbox.style.height = 250
    textbox.read_only = true
    textbox.word_wrap = true

    self.export_textbox = textbox

    local flow = frame.add{type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"}
    flow.add{type = "button", name = "TODO_CLICK19", caption = {"Todo.SelectAll"}, mouse_button_filter = filter, style = "dialog_button"}
    flow.add{type = "empty-widget", style = "todowidget"}
end

function player_data:settings_gui(player_table)
    local frame = self.frame.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}

    self.settings_frame = frame

    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.SettingsTitle"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = self.frame

    local inside_frame = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}
    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "subheader_frame"}
    subheader_frame.add{type = "label", caption = {"Todo.SettingsCaption"}, style = "subheader_caption_label"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}
    subheader_frame.add{type = "drop-down", name = "TODO_DROP02", items = player_table}

    self.settings_scrollpane = inside_frame.add{type = "scroll-pane", style = "todoscrollpane"}
end

function player_data:settings_player_gui(settings, player_id)
    self.settings_scrollpane.clear()

    local scrollpane = self.settings_scrollpane

    for setting, boolean in pairs(settings) do
        if setting ~= "changed" then
            scrollpane.add{type = "flow", direction = "horizontal", style = "todosettingsflow"}.add{type = "checkbox", name = "TODO_CHECK03_player_id=" .. player_id .. ",setting=" .. setting, caption = {"TodoSettings." .. setting}, state = boolean}
        end
    end
end

function player_data:reference_gui(todo, namestring)
    local data = todo[namestring]
    local id_string = data.id_string

    local frame = self.player.gui.screen.add{type = "frame", direction = "vertical", style = "inner_frame_in_outer_frame"}
    frame.location = self.solid_location

    self.reference_frames[id_string] = frame

    local titleflow = frame.add{type = "flow", direction = "horizontal"}
    titleflow.add{type = "label", caption = {"Todo.Task"}, style = "frame_title"}
    titleflow.add{type = "empty-widget", style = "tododragwidget"}.drag_target = frame
    titleflow.add{type = "sprite-button", name = "TODO_CLICK20_" .. id_string, sprite = "utility/close_white", mouse_button_filter = filter, style = "frame_action_button"}

    self.reference_internal_frames[id_string] = frame.add{type = "frame", direction = "vertical", style = "inside_shallow_frame"}

    self:reference_internal(data, todo, namestring)
end

function player_data:reference_internal(data, todo, namestring)
    local inside_frame = self.reference_internal_frames[data.id_string]
    inside_frame.clear()

    if self.reference_id_namestrings[data.id_string] then
        self:clear_reference_namstrings(data.id_string)
    end

    self.reference_id_namestrings[data.id_string] = {namestring}
    self.reference_namestrings[data.id_string] = namestring
    self.reference_open[namestring] = (data.level < 5 and self.reference_open[namestring] == nil and true) or self.reference_open[namestring]

    local subheader_frame = inside_frame.add{type = "frame", direction = "horizontal", style = "todoreferencesubheader"}

    self.reference_checkboxes[namestring] = subheader_frame.add{type = "flow", direction = "horizontal", style = "todocheckboxflow"}.add{type = "checkbox", name = "TODO_CHECK" .. ((data.level == 0 and "01") or "02") .. "_" .. namestring, state = data.state}

    self.reference_titles[namestring] = subheader_frame.add{type = "label", caption = data.title, style = "todotasklabeldata"}
    subheader_frame.add{type = "empty-widget", style = "todowidget"}

    local buttonflow = subheader_frame.add{type = "flow", direction = "horizontal", style = "todohorizonalflow8left2spacing"}

    local scrollpane = inside_frame.add{type = "scroll-pane", style = "todoreferencescrollpane"}
    scrollpane.style.maximal_height = self.player.display_resolution.height * 0.3 / self.player.display_scale

    local horizontalflow = scrollpane.add{type = "flow", direction = "horizontal", style = "todohorizontalflow"}
    horizontalflow.style.top_padding = 4
    horizontalflow.add{type = "empty-widget"}.style.width = 30

    local verticalflow = scrollpane.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
    self.reference_descriptions[namestring] = verticalflow.add{type = "label", caption = data.description, style = "todotaskdescription"}

    local subtaskflow = (data.level < 5 and verticalflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}) or nil

    self.reference_subtaskflows[namestring] = subtaskflow

    if data.level < 5 then
        self.reference_toggles[namestring] = buttonflow.add{type = "sprite-button", name = "TODO_CLICK21_" .. namestring, tooltip = {"TodoTooltip.Toggle"}, sprite = (self.reference_open[namestring] and "utility/speed_up") or "utility/speed_down", mouse_button_filter = filter, number = #data.subtasks, style = "tool_button"}
        self:reference_subtasks(data.subtasks, todo, subtaskflow)

        subtaskflow.visible = self.reference_open[namestring]
    else
        buttonflow.add{type = "empty-widget", style = "todoplaceholderwidget"}
    end

    buttonflow.add{type = "sprite-button", name = "TODO_CLICK12_" .. namestring, tooltip = {"TodoTooltip.Map"}, sprite = "utility/map", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
end

function player_data:reference_subtasks(subtasks, todo, flow)
    for i, namestring in pairs(subtasks) do
        local data = todo[namestring]

        table.insert(self.reference_id_namestrings[data.id_string], namestring)

        self.reference_open[namestring] = (data.level < 5 and self.reference_open[namestring] == nil and true) or self.reference_open[namestring]

        local taskflow = flow.add{type = "flow", direction = "horizontal", style = "todohorizontalflow8top"}

        self.reference_checkboxes[namestring] = taskflow.add{type = "flow", direction = "horizontal", style = "todocheckboxflow"}.add{type = "checkbox", name = "TODO_CHECK02_" .. namestring, state = data.state}

        local verticalflow = taskflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}
        local horizontalflow = verticalflow.add{type = "flow", direction = "horizontal", style = "todohorizontalflow"}

        self.reference_titles[namestring] = horizontalflow.add{type = "label", caption = data.title, style = "todotasklabeldata"}

        horizontalflow.add{type = "empty-widget", style = "todowidget"}

        self.reference_descriptions[namestring] = verticalflow.add{type = "label", caption = data.description, style = "todotaskdescription"}
        local subtaskflow = (data.level < 5 and verticalflow.add{type = "flow", direction = "vertical", style = "todoverticalflow"}) or nil

        self.reference_subtaskflows[namestring] = subtaskflow

        local buttonflow = horizontalflow.add{type = "flow", direction = "horizontal", style = "todohorizonalflow8left2spacing"}

        if data.level < 5 then
            self.reference_toggles[namestring] = buttonflow.add{type = "sprite-button", name = "TODO_CLICK21_" .. namestring, tooltip = {"TodoTooltip.Toggle"}, sprite = (self.reference_open[namestring] and "utility/speed_up") or "utility/speed_down", mouse_button_filter = filter, number = #data.subtasks, style = "tool_button"}
            self:reference_subtasks(data.subtasks, todo, subtaskflow)

            subtaskflow.visible =  self.reference_open[namestring]
        else
            buttonflow.add{type = "empty-widget", style = "todoplaceholderwidget"}

            if i ~= #subtasks then
                flow.add{type = "line", style = "todotaskline"}
            end
        end

        buttonflow.add{type = "sprite-button", name = "TODO_CLICK12_" .. namestring, tooltip = {"TodoTooltip.Map"}, sprite = "utility/map", mouse_button_filter = {"left-and-right"}, style = "tool_button"}
    end
end

function player_data:clear()
    self.frame.destroy()
    self.frame = nil
    self.edit_button = nil
    self.import_button = nil
    self.export_button = nil
    self.settings_button = nil
    self.sort = nil
    self.table = nil
    self.checkboxes = nil
    self.subtaskflows = nil
    self.titles = nil
    self.descriptions = nil
    self.players = nil
    self.toggles = nil
    self.edit_titles = nil
    self.edit_descriptions = nil

    if self.export_frame then
        self:clear_export()
    end

    if self.settings_frame then
        self:clear_settings()
    end
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

function player_data:clear_settings()
    self.settings_frame.destroy()
    self.settings_frame = nil
    self.settings_scrollpane = nil
end

function player_data:clear_reference(id_string)
    self.reference_frames[id_string].destroy()
    self.reference_frames[id_string] = nil
    self.reference_internal_frames[id_string] = nil
    self.reference_namestrings[id_string] = nil
    self:clear_reference_namstrings(id_string)
    self.reference_id_namestrings[id_string] = nil
end

function player_data:clear_reference_namstrings(id_string)
    for _, namestring in pairs(self.reference_id_namestrings[id_string]) do
        self.reference_open[namestring] = nil
        self.reference_checkboxes[namestring] = nil
        self.reference_titles[namestring] = nil
        self.reference_toggles[namestring] = nil
        self.reference_descriptions[namestring] = nil
        self.reference_subtaskflows[namestring] = nil
    end
end

return player_data