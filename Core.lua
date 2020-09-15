local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local utils = LibStub("LibAddonUtils-1.0")
local GUI = LibStub("LibAddonGUI-1.0"):RegisterAddon(addonName)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:OnInitialize()
    local defaults = {
        global = {
            enabled = true,
            binds = {},
        },
        char = {
            binds = {},
        }
    }

    self.db = LibStub("AceDB-3.0"):New(addonName .. "DB", defaults, true)

    addon:DrawFrame()
    GUI:RegisterAddOnSkin()
    self:CreateDataObject()

    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    addon:RegisterChatCommand("obind", function(input)
        if not input or input:trim() == "" then
            addon.frame:Show()
            addon.frame.scrollFrame:LoadBinds("global")
        end
    end)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:PLAYER_ENTERING_WORLD(event)
    if UnitAffectingCombat("player") then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self:SetBindings()
    self:LoadStartupBindings()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function addon:PLAYER_REGEN_ENABLED(event)
    self:SetBindings()
    self:LoadStartupBindings()
    self:UnregisterEvent(event)
end