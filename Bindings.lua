local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local utils = LibStub("LibAddonUtils-1.0")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:DeleteBinding(bind)
    self.db[self.frame.scrollFrame.scope].binds[bind] = nil

    if UnitAffectingCombat("player") then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    else
        self:SetBindings()
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:LoadStartupBindings()
    for k, v in pairs(self.db.global) do

    end

    for k, v in pairs(self.db.char) do

    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:SetBinding(bind, data)
    self.numMacros = self.numMacros or 0
    if data.bindType == "MACROTEXT" or data.bindType == "FUNCTION" then
        self.numMacros = self.numMacros + 1
        local macroFrame = CreateFrame("Button", string.format("%sMacroFrame%s", addonName, self.numMacros), UIParent, "SecureActionButtonTemplate")
        macroFrame:Hide()
        macroFrame:EnableMouse(true)
        macroFrame:RegisterForClicks("AnyUp")

        macroFrame:SetAttribute("type1", nil)
        macroFrame:SetAttribute("macrotext", nil)

        if data.bindType == "FUNCTION" then
            macroFrame:SetScript("PostClick", function()
                assert(loadstring("local f = " .. data.command .. "; f()"))()
            end)
            macroFrame:SetAttribute("type1", "click")
        else
            macroFrame:SetAttribute("type1", "macro")
            macroFrame:SetAttribute("macrotext", data.command)
        end

        SetOverrideBindingClick(self.frame, true, bind, macroFrame:GetName())
    elseif data.bindType == "SPELL" then
            if not (select(1, GetSpellInfo(data.command))) then return end
        SetOverrideBindingSpell(self.frame, true, bind, (select(1, GetSpellInfo(data.command))))
    elseif data.bindType == "ITEM" then
        utils.CacheItem(data.command, function(self, bind, itemID)
            if not (select(1, GetItemInfo(itemID))) then return end
            SetOverrideBindingItem(self.frame, true, bind, (select(1, GetItemInfo(itemID))))
        end, self, bind, data.command)
    elseif data.bindType == "MACRO" then
        SetOverrideBindingMacro(self.frame, true, bind, data.command)
    elseif data.bindType == "CLICK" then
        SetOverrideBindingClick(self.frame, true, bind, data.command)
    elseif data.bindType == "ACTION" then
        SetOverrideBinding(self.frame, true, bind, data.command)
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:SetBindings()
    ClearOverrideBindings(self.frame)

    if self.db.global.enabled then
        for bind, data in pairs(self.db.global.binds) do
            self:SetBinding(bind, data)
        end

        for bind, data in pairs(self.db.char.binds) do
            self:SetBinding(bind, data)
        end
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:ValidateBindings(bindType, command)
    local error
    if bindType == "ACTION" then
        if not _G["BINDING_NAME_" .. strupper(command)] then
            error = L.ValidationErrors("invalidAction")
        end
    elseif bindType == "CLICK" then
        if not _G[command] then
            error = L.ValidationErrors("invalidFrame")
        elseif not _G[command]:HasScript("OnClick") then
            error = L.ValidationErrors("invalidOnClick")
        end
    elseif bindType == "ITEM" then
        if not GetItemInfoInstant(command) then
            error = L.ValidationErrors("invalidItem")
        end
    elseif bindType == "MACRO" then
        if not GetMacroInfo(command) then
            error = L.ValidationErrors("invalidMacro")
        end
    elseif bindType == "SPELL" then
        if not GetSpellInfo(command) then
            error = L.ValidationErrors("invalidSpell")
        end
    end

    if error then
        return false, error
    else
        return true
    end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

StaticPopupDialogs["OVERBOUND_CONFIRM_OVERWRITE"] = {
    text = L.OverwriteConfirmation(),
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(_, editor, bindData)
        addon:DeleteBinding(editor.bind)
        editor:SaveBind(utils.unpack(bindData))
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

StaticPopupDialogs["OVERBOUND_CONFIRM_DELETE"] = {
    text = L.DeleteConfirmation(),
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(_, editor)
        -- add confirmation here
        addon:DeleteBinding(editor.bind)
        addon.frame.scrollFrame:LoadBinds(addon.frame.scrollFrame.scope)
        editor:ClearEditor()
        editor:Hide()
        -- addon:DeleteBinding(editor.bind)
        -- editor:SaveBind(utils.unpack(bindData))
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}