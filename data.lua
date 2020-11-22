local MODNAME = "__Not_Enough_Todo__"
local s = data.raw["gui-style"].default

--Flows
s["todoverticalflow"] = {
    type = "vertical_flow_style",
    padding = 0,
    vertical_spacing = 0
}

s["todohorizontalflow"] = {
    type = "horizontal_flow_style",
    padding = 0,
    horizontal_spacing = 0
}

s["todoswitchflow"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    width = 100,
    horizontal_align = "center"
}

s["todotaskflow"] = {
    type = "vertical_flow_style",
    parent = "todoverticalflow",
    padding = 8
}

s["todohorizontalflow8top"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    top_padding = 8
}

s["todocheckboxflow"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    width = 30,
    top_padding = 4
}

s["todoverticalflow8right"] = {
    type = "vertical_flow_style",
    parent = "todoverticalflow",
    right_padding = 8
}

s["todohorizonalflow8right2spacing"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    right_padding = 8,
    horizontal_spacing = 2
}

s["todohorizonalflow8left2spacing"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    left_padding = 8,
    horizontal_spacing = 2
}

s["todohorizonalflow2spacing"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    horizontal_spacing = 2
}

s["todosettingsflow"] = {
    type = "horizontal_flow_style",
    parent = "todohorizontalflow",
    top_padding = 4,
    right_padding = 8,
    left_padding = 8
}

--Widgets
s["tododragwidget"] = {
    type = "empty_widget_style",
    parent = "draggable_space_header",
    horizontally_stretchable = "on",
    natural_height = 24,
    minimal_width = 24
}

s["todowidget"] = {
    type = "empty_widget_style",
    horizontally_stretchable = "on",
    minimal_width = 0
}

s["todoplaceholderwidget"] = {
    type = "empty_widget_style",
    width = 28
}

--Scrollpanes
s["todoscrollpane"] = {
    type = "scroll_pane_style",
    minimal_height = 100,
    horizontal_scroll_policy = "off",
    vertical_flow_style = {
        type = "vertical_flow_style",
        parent = "todoverticalflow"
    }
}

s["todoreferencescrollpane"] = {
    type = "scroll_pane_style",
    horizontal_scroll_policy = "off",
    vertical_flow_style = {
        type = "vertical_flow_style",
        parent = "todoverticalflow",
        left_padding = 4,
        right_padding = 4
    }
}

--Buttons
s["todochooseelem28"] = {
    type = "button_style",
    parent = "slot_button_in_shallow_frame",
    size = 28
}

s["todoframeactionselected"] = {
    type = "button_style",
    parent = "frame_action_button",
    default_graphical_set = {
        base = {position = {272, 169}, corner_size = 8},
        shadow = {position = {440, 24}, corner_size = 8, draw_type = "outer"}
    },
    hovered_graphical_set = {
        base = {position = {369, 17}, corner_size = 8},
        shadow = default_dirt
    },
    clicked_graphical_set = {
        base = {position = {352, 17}, corner_size = 8},
        shadow = default_dirt
    }
}

s["todoassignedbutton"] = {
    type = "button_style",
    width = 150
}

--Labels
s["todotasklabel"] = {
    type = "label_style",
    width = 400
}

s["todoassignedlabel"] = {
    type = "label_style",
    width = 150
}

s["todosortlabel"] = {
    type = "label_style",
    width = (28 * 2) + 2
}

s["todotasklabeldata"] = {
    type = "label_style",
    width = 250
}

s["todotaskdescription"] = {
    type = "label_style",
    width = 250,
    single_line = false
}

s["tododescriptionlabel"] = {
    type = "label_style",
    width = 200,
    single_line = false
}

s["todoassignedlabeldata"] = {
    type = "label_style",
    width = 150
}

s["todoassignedlabelclickabledata"] = {
    type = "label_style",
    parent = "clickable_label",
    width = 150
}

--Tables
s["todomaintable"] = {
    type = "table_style",
    vertical_line_color = {r = 255, g = 255, b = 255},
    horizontal_line_color =  {r = 255, g = 255, b = 255}
}

--Textfields/Boxes
s["todotasktextfield"] = {
    type = "textbox_style",
    width = 250,
    height = 28
}

s["todotasktextbox"] = {
    type = "textbox_style",
    width = 250,
    height = 56
}

--Dropdowns
s["todoassigneddropdown"] = {
    type = "dropdown_style",
    width = 150
}

--Lines
s["todotaskline"] = {
    type = "line_style",
    horizontally_stretchable = "on",
    top_padding = 4
}

--Frames
s["todosubheaderframe"] = {
    type = "frame_style",
    parent = "subheader_frame",
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        vertical_align = "center",
        horizontal_spacing = 8,
        horizontally_stretchable = "on"
    }
}

s["todoreferencesubheader"] = {
    type = "frame_style",
    parent = "subheader_frame",
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        left_padding = 4,
        right_padding = 4,
        vertical_align = "center",
        horizontally_stretchable = "on"
    }
}

data:extend{
    {
        type = "sprite",
        name = "todo",
        filename = MODNAME .. "/graphics/todo.png",
        flags = {"gui-icon"},
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-edit",
        filename = MODNAME .. "/graphics/edit.png",
        flags = {"gui-icon"},
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-import",
        filename = MODNAME .. "/graphics/import.png",
        flags = {"gui-icon"},
        size = 32,
        scale = 0.5,
        mipmap_count = 2
    },
    {
        type = "sprite",
        name = "todo-export",
        filename = MODNAME .. "/graphics/export.png",
        flags = {"gui-icon"},
        size = 32,
        scale = 0.5,
        mipmap_count = 2
    },
    {
        type = "sprite",
        name = "todo-settings",
        filename = MODNAME .. "/graphics/frame-action-icons.png",
        flags = {"gui-icon"},
        position = {32, 96},
        size = 32
    },
    {
        type = "sprite",
        name = "todo-finished",
        filename = MODNAME .. "/graphics/finished.png",
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-unfinished",
        filename = MODNAME .. "/graphics/unfinished.png",
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-up",
        filename = MODNAME .. "/graphics/up.png",
        flags = {"gui-icon"},
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-down",
        filename = MODNAME .. "/graphics/down.png",
        flags = {"gui-icon"},
        size = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-clipboard",
        filename = MODNAME .. "/graphics/tool-icons.png",
        flags = {"gui-icon"},
        position = {0, 32},
        size = 32,
        mipmap_count = 2
    }
}