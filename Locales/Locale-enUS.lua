local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

L["Action"] = true
L["Cancel"] = true
L["Character"] = true
L["Clear"] = true
L["Click"] = true
L["Create"] = true
L["Delete"] = true
L["Edit"] = true
L["Editor"] = true
L["Function"] = true
L["Global"] = true
L["Item"] = true
L["Load on Startup"] = true
L["Macro"] = true
L["Macrotext"] = true
L["New"] = true
L["New Keybind"] = true
L["No"] = true
L["Not Bound"] = true
L["Recording"] = true
L["Save"] = true
L["Spell"] = true
L["Type"] = true
L["Update"] = true
L["Yes"] = true
L.OverwriteConfirmation = function()
    return "The bind \"%s\" already exists. Do you want to overwrite?"
end

L.Tooltips = function(tip)
    local tips = {
        char = "Right-click to edit character keybinds.",
        enable = "Alt+right-click to enable/disable all keybinds.",
        global = "Left-click to edit global keybinds.",
    }

    return tips[tip]
end

L.ValidationErrors = function(err)
    local errors = {
        invalidAction = "Action does not exist.",
        invalidFrame = "Frame does not exist.",
        invalidItem = "Item does not exit.",
        invalidMacro = "Macro does not exist.",
        invalidOnClick = "Frame does not have an OnClick script.",
        invalidSpell = "Spell does not exist.",
        notBound = "Binding not set.",
    }

    return errors[err]
end