-- Defines all event identifiers for easier referencing across files & functions. Makes for more readable code!
local EventIdentifier = {
    -- Switches
    ToggleTaskTypes = "01",

    -- Dropdowns
    ChooseAssignee = "01",
    PickPlayer = "02",

    -- Text field changes
    ChangeTitle = "01",
    ChangeDescription = "02",

    -- Checkboxes
    ToggleCompleteWhileEditing = "01",
    ToggleComplete = "02",
    AssignUser = "03",

    -- GUI clicks
    OpenMainWindow = "01",
    ToggleEditMode = "02",
    ToggleImport = "03",
    ToggleExport = "04",
    ToggleSettings = "05",
    CloseMainWindow = "06",
    DeletePlayer = "07",
    AssignMe = "08",
    SortUp = "09",
    SortDown = "10",
    ToggleSubtasks = "11",
    InteractWithMap = "12",
    ToggleReference = "13",
    DeleteTask = "14",
    AddTask = "15",
    CloseImportWindow = "16",
    ImportTasks = "17",
    CloseExportWindow = "18",
    SelectAll = "19",
    CloseReferenceWindow = "20",
    ToggleSubtaskReference = "21",
}

return EventIdentifier