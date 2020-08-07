local s = data.raw["gui-style"].default
local MODNAME = "__Not_Enough_Todo__"

--Flows
s["todoverticalflow"] = {
    type = "vertical_flow_style",
    padding = 0,
    vertical_spacing = 0
}

s["todoverticalflowspacing"] = {
    type = "vertical_flow_style",
    padding = 0
}

s["todohorizontalflow"] = {
    type = "horizontal_flow_style",
    padding = 0,
    horizontal_spacing = 0
}

s["todomainflow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 10,
    padding = 0,
    top_padding = 10,
    right_padding = 8,
    left_padding = 8
}

s["todocheckboxflow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_align = "center",
    padding = 0,
    width = 88
}

s["todosecondflow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 10,
    padding = 0,
    top_padding = 10
}

s["todoflow5align"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 5,
    padding = 0
}

s["todoflow5"] = {
    type = "horizontal_flow_style",
    padding = 0,
    horizontal_spacing = 5
}

s["todoaddflow"] = {
    type = "horizontal_flow_style",
    padding = 0,
    top_padding = 10,
    right_padding = 8,
    left_padding = 8,
    horizontal_spacing = 10
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
    vertically_stretchable = "on",
    horizontal_scroll_policy = "off",
    minimal_height = 600,
    vertical_flow_style = {
        type = "vertical_flow_style",
        parent = "todoverticalflow"
    }
}

s["todoreferencescrollpane"] = {
    type = "scroll_pane_style",
    vertically_stretchable = "on",
    horizontal_scroll_policy = "off",
    maximal_height = 300,
    vertical_flow_style = {
        type = "vertical_flow_style",
        parent = "todoverticalflow"
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

--Labels
s["todomainlabel"] = {
    type = "label_style",
    width = 250,
    single_line = false
}

s["todosubtasklabel"] = {
    type = "label_style",
    width = 231,
    single_line = false
}

s["todoassignedlabel"] = {
    type = "label_style",
    width = 150
}

s["todoassignedlabelclickable"] = {
    type = "label_style",
    parent = "clickable_label",
    width = 150
}

s["todosortlabel"] = {
    type = "label_style",
    width = (28 * 2) + 5
}

s["todooptionslabel"] = {
    type = "label_style",
    width = (28 * 5) + (4 * 5) - 10
}

s["todoaddlabel"] = {
    type = "label_style",
    width = 100
}

s["todoreferencetitle"] = {
    type = "label_style",
    parent = "subheader_caption_label",
    width = 311
}

s["todoreferencedescriptionlabel"] = {
    type = "label_style",
    width = 283,
    single_line = false
}

--Lines
s["todoline"] = {
    type = "line_style",
    top_padding = 10
}

--Textboxs
s["todoaddtitletextfield"] = {
    type = "textbox_style",
    padding = 0,
    width = 250
}

s["todoadddescriptiontextbox"] = {
    type = "textbox_style",
    padding = 0,
    width = 250,
    height = 100
}

--Frames
s["todosubheaderframe"] = {
    type = "frame_style",
    parent = "frame",
    left_padding = 0,
    right_padding = 0,
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        parent = "todomainflow",
        horizontally_stretchable = "on",
        top_padding = 0
    }
}

s["todorefenrecesubheaderframe"] = {
    type = "frame_style",
    parent = "frame",
    left_padding = 0,
    right_padding = 0,
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        vertical_align = "center",
        parent = "todoaddflow"
    }
}

data:extend{
    {
        type = "sprite",
        name = "todo",
        filename = MODNAME .. "/graphics/todo.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-finished",
        filename = MODNAME .. "/graphics/finished.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-unfinished",
        filename = MODNAME .. "/graphics/unfinished.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-up",
        filename = MODNAME .. "/graphics/up.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-down",
        filename = MODNAME .. "/graphics/down.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-add",
        filename = MODNAME .. "/graphics/add.png",
        width = 64,
        height = 64,
        scale = 1
    },
    {
        type = "sprite",
        name = "todo-clipboard",
        filename = MODNAME .. "/graphics/tool-icons.png",
        position = {0, 32},
        size = 32,
        mipmap_count = 2
    },
    {
        type = "sprite",
        name = "todo-settings",
        filename = MODNAME .. "/graphics/frame-action-icons.png",
        position = {32, 96},
        size = 32
    }
}