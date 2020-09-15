local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local utils = LibStub("LibAddonUtils-1.0")
local GUI = LibStub("LibAddonGUI-1.0"):GetAddon(addonName)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:CreateDataObject()
    local dataObject = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(addonName, {
        type = "launcher",
        icon = 1499566,
        label = addonName,
        OnTooltipShow = function(self)
            self:AddLine(addonName)
            self:AddLine(addon.db.global.enabled and "Enabled" or "Disabled", 1, 1, 1, 1)
            self:AddLine(L.Tooltips("global"), 1, 1, 1, 1)
            self:AddLine(L.Tooltips("char"), 1, 1, 1, 1)
            self:AddLine(L.Tooltips("enable"), 1, 1, 1, 1)
        end,
        OnClick = function(_, button)
            if IsAltKeyDown() and button == "RightButton" then
                if addon.db.global.enabled then
                    addon.db.global.enabled = false
                else
                    addon.db.global.enabled = true
                end

                if UnitAffectingCombat("player") then
                    addon:RegisterEvent("PLAYER_REGEN_ENABLED")
                else
                    addon:SetBindings()
                end
            elseif button == "LeftButton" then
                addon.frame.scrollFrame:LoadBinds("global")
                addon.frame:Show()
            elseif button == "RightButton" then
                addon.frame.scrollFrame:LoadBinds("char")
                addon.frame:Show()
            end
        end,
    })
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:DrawEditorFrame()

    local frame = self.frame

    local editor = GUI:CreateFrame(frame, {name = addonName.."EditorFrame", title = L["Editor"]})
    frame.editor = editor
    editor:SetPoint("TOPLEFT", frame, "TOPRIGHT", -1, 0)
    editor:SetSize(frame:GetWidth(), frame:GetHeight())
    editor:Hide()

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local typeLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    typeLabel:SetText(L["Type"])
    typeLabel:SetPoint("LEFT", 15, 0)
    typeLabel:SetPoint("TOP", editor.title, "BOTTOM", 0, -20)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local commandPreviewIcon, commandPreviewIcon, commandEditBox
    local typeDropDown = GUI:CreateDropDown(editor, {
        width = 150,
        SetValue = function(self, selected)
            editor:UpdateCommandPreviews(selected, commandEditBox:GetText())
        end,
        menu = {
            ACTION = {
                text = L["Action"],
            },
            CLICK = {
                text = L["Click"],
            },
            FUNCTION = {
                text = L["Function"],
            },
            ITEM = {
                text = L["Item"],
            },
            MACRO = {
                text = L["Macro"],
            },
            MACROTEXT = {
                text = L["Macrotext"],
                default = true,
            },
            SPELL = {
                text = L["Spell"],
            },
        },
    })

    typeDropDown:SetPoint("LEFT", typeLabel, "RIGHT", 10, 0)
    typeDropDown.Button:Disable()

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local keybindButton = GUI:CreateKeybind(editor, {statusText = L["Recording"].."..."})
    keybindButton:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, -20)
    keybindButton:SetSize(150, 25)
    keybindButton:Disable()

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    commandPreviewIcon = GUI:CreateIcon(editor, {})
    commandPreviewIcon:SetPoint("TOPLEFT", keybindButton, "BOTTOMLEFT", 0, -10)
    commandPreviewIcon:SetSize(15, 15)

    commandPreviewLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    commandPreviewLabel:SetPoint("LEFT", commandPreviewIcon, "RIGHT", 5, 0)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local commandEditBoxFrame = GUI:CreateEditBox(editor, {
        name = editor:GetName().."CommandEditBox",
        width = editor:GetWidth() - 50,
        height = 100,
        multiLine = true,
        tabSpaces = true,
        onTextChanged = function(self)
            editor:UpdateCommandPreviews(typeDropDown.selected, self:GetText())
        end,
    })
    commandEditBoxFrame:SetPoint("TOPLEFT", commandPreviewIcon, "BOTTOMLEFT", 0, -10)
    commandEditBox = commandEditBoxFrame.EditBox
    commandEditBox:Disable()

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local cancelButton
    local saveButton = GUI:CreateButton(editor, {
        onClick = function(self)
            if editor.bind and editor.isEditing then
                local success = editor:ValidateBind()

                if success then
                    editor:DisableEditing()
                    self:SetText(L["Edit"])
                    cancelButton:SetText(L["Delete"])
                end
            elseif editor.bind then
                editor:EnableEditing()
                self:SetText(L["Update"])
                cancelButton:SetText(L["Cancel"])
            else
                editor:ValidateBind()
            end
        end,
    })
    saveButton:SetPoint("TOPLEFT", commandEditBoxFrame, "BOTTOMLEFT", 0, -10)
    saveButton:SetSize(150, 25)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    cancelButton = GUI:CreateButton(editor, {
        onClick = function()
            if editor.bind and editor.isEditing then
                editor:LoadBind(editor.bind)
            elseif editor.bind then
                local dialog = StaticPopup_Show("OVERBOUND_CONFIRM_DELETE", frame.scrollFrame.scope, editor.bind)
                if dialog then
                    dialog.data = editor
                    dialog.data2 = {editor.bind}
                end
            else
                editor:ClearEditor()
            end
        end,
    })
    cancelButton:SetPoint("LEFT", saveButton, "RIGHT", 10, 0)
    cancelButton:SetSize(150, 25)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:ClearEditor()
        self.bind = false
        typeDropDown:SetValue(typeDropDown.default)
        keybindButton.isRecording = false
        keybindButton:EnableKeyboard(false)
        keybindButton:SetText(L["Not Bound"])
        commandPreviewIcon:SetNormalTexture("")
        commandPreviewLabel:SetText("")
        commandEditBox:SetText("")
        saveButton:SetText(L["Create"])
        cancelButton:SetText(L["Clear"])
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:DisableEditing()
        self.isEditing = false
        typeDropDown.Button:Disable()
        keybindButton:Disable()
        commandEditBox:Disable()
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:EnableEditing()
        self.isEditing = true
        typeDropDown.Button:Enable()
        keybindButton:Enable()
        commandEditBox:Enable()
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:LoadBind(bind)
        self:DisableEditing()
        self:ClearEditor()
        self:Show()

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        local bindData = addon.db[frame.scrollFrame.scope].binds[bind]
        self.bind = bind

        typeDropDown:SetValue(bindData.bindType)
        keybindButton:SetText(bind)

        editor:UpdateCommandPreviews(bindData.bindType, bindData.command)

        commandEditBox:SetText(bindData.command)
        saveButton:SetText(L["Edit"])
        cancelButton:SetText(L["Delete"])
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:NewBind()
        self:EnableEditing()
        self:ClearEditor()
        self:Show()
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:SaveBind(bind, bindType, command)
        addon.db[frame.scrollFrame.scope].binds[bind] = {
            bindType = bindType,
            command = command,
        }

        frame.scrollFrame:LoadBinds(frame.scrollFrame.scope)
        self:LoadBind(bind)

        if UnitAffectingCombat("player") then
            addon:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        else
            addon:SetBindings()
        end
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:ValidateBind()
        local bind = keybindButton:GetText()
        if bind == L["Not Bound"] or bind == L["Recording"].."..." then
            commandPreviewIcon:SetNormalTexture("")
            commandPreviewLabel:SetText(L.ValidationErrors("notBound"))
            return
        end

        local bindType = typeDropDown.selected
        local command = commandEditBox:GetText()

        local valid, err = addon:ValidateBindings(bindType, command)

        if valid then
            if self.bind ~= bind then
                if addon.db[frame.scrollFrame.scope].binds[bind] then
                    local dialog = StaticPopup_Show("OVERBOUND_CONFIRM_OVERWRITE", bind)
                    if dialog then
                        dialog.data = editor
                        dialog.data2 = {bind, bindType, command}
                    end
                    return
                else
                    addon:DeleteBinding(self.bind)
                end
            end

            editor:SaveBind(bind, bindType, command)

            return true
        else
            commandPreviewIcon:SetNormalTexture("")
            commandPreviewLabel:SetText(err)
            return
        end
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    function editor:UpdateCommandPreviews(bindType, command)
        if bindType == "ITEM" then
            utils.CacheItem(command, function(commandPreviewIcon, commandPreviewLabel, command)
                commandPreviewIcon:SetNormalTexture((select(10, GetItemInfo(command))))
                commandPreviewLabel:SetText((select(1, GetItemInfo(command))))
            end, commandPreviewIcon, commandPreviewLabel, command)
        elseif bindType == "MACRO" then
            commandPreviewIcon:SetNormalTexture((select(2, GetMacroInfo(command))))
            commandPreviewLabel:SetText((select(1, GetMacroInfo(command))))
        elseif bindType == "SPELL" then
            commandPreviewIcon:SetNormalTexture((select(3, GetSpellInfo(command))))
            commandPreviewLabel:SetText((select(1, GetSpellInfo(command))))
        else
            commandPreviewIcon:SetNormalTexture("")
            commandPreviewLabel:SetText("")
        end
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:DrawFrame()
    local frame = GUI:CreateFrame(UIParent, {
        name = addonName.."Frame",
        draggable = true,
        title = addonName,
    })
    frame:SetSize(400, 450)
    frame:SetPoint("CENTER", 0, 100)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local newKeyButton = GUI:CreateButton(frame, {
        onClick = function()
            frame.editor:NewBind()
        end,
    })
    newKeyButton:SetSize(150, 25)
    newKeyButton:SetText(L["New Keybind"])
    newKeyButton:SetPoint("LEFT", 15, 0)
    newKeyButton:SetPoint("TOP", frame.title, "BOTTOM", 0, -20)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local scrollFrame
    local globalButton = GUI:CreateButton(frame, {
        onClick = function()
            scrollFrame:LoadBinds("global")
        end,
    })
    globalButton:SetSize(150, 25)
    globalButton:SetText(L["Global"])
    globalButton:SetPoint("TOPLEFT", newKeyButton, "BOTTOMLEFT", 0, -20)


    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    local charButton = GUI:CreateButton(frame, {
        onClick = function()
            scrollFrame:LoadBinds("char")
        end,
    })
    charButton:SetSize(150, 25)
    charButton:SetText(L["Character"])
    charButton:SetPoint("LEFT", globalButton, "RIGHT", 15, 0)

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    scrollFrame = GUI:CreateScrollingButtonGrid(frame, {
        name = frame:GetName() .. "Keybinds",
        columns = 2,
    })
    scrollFrame:SetPoint("TOPLEFT", globalButton, "BOTTOMLEFT", 0, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 15)

    function scrollFrame:LoadBinds(scope)
        scrollFrame:Clear()
        frame.editor:Hide()

        for bind, bindData in utils.pairs(addon.db[scope].binds) do
            local icon = scrollFrame:AddButton({
                text = bind,
                onClick = function(_, button)
                    if frame.editor.bind == bind then
                        frame.editor:DisableEditing()
                        frame.editor:ClearEditor()
                        frame.editor:Hide()
                    else
                        frame.editor:LoadBind(bind)
                    end
                end,
                tooltip = function()
                    GameTooltip:AddLine(bind)
                    GameTooltip:AddLine(bindData.bindType, 1, 1, 1)
                end,
            })
        end

        GUI:ReSkinAddOn()

        scrollFrame.scope = scope
        if scope == "global" then
            globalButton:GetFontString():SetTextColor(1, .82, 0, 1)
            charButton:GetFontString():SetTextColor(1, 1, 1, 1)
        elseif scope == "char" then
            charButton:GetFontString():SetTextColor(1, .82, 0, 1)
            globalButton:GetFontString():SetTextColor(1, 1, 1, 1)
        end

        frame.editor.bind = false
    end

    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    self.frame = frame
    frame.scrollFrame = scrollFrame

    self:DrawEditorFrame()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- local actions = {}
-- for k, v in utils.pairs(_G) do
--     if strfind(k, "^BINDING_NAME_", 1) then
--         local action = (string.gsub(k, "^BINDING_NAME_", ""))
--         actions[action] = action
--     end
-- end

-- for k, v in utils.pairs(actions) do print(k, v) end