local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = private.L
LibStub("LibAddonUtils-1.0"):Embed(addon)

function addon:OnEnable()
	private:SetBindings()
end

function addon:OnDisable()
	ClearOverrideBindings(private.frame.frame)
end

function addon:OnInitialize()
	private:InitializeDatabase()
	private:InitializeSlashCommands()
	private:InitializeFrame()
	private:CreateDataObject()

	if private.db.global.debug then
		addon:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end

local bindTypes = {
	ACTION = "action",
	MACROTEXT = "macrotext",
	FUNCTION = "func",
}

function private:InitializeDatabase()
	local backup
	if OverboundDB then
		if not OverboundDB.global or not OverboundDB.global.version or OverboundDB.global.version < 2 then
			backup = addon.CloneTable(OverboundDB)
		end
	end

	private.db = LibStub("AceDB-3.0"):New(addonName .. "DB", private.defaultSettings, true)
	addon:SetEnabledState(private.db.profile.enabled)

	private.db.global.version = 2

	if backup then
		for char, db in pairs(backup.char) do
			OverboundDB.char[char].keybinds = {}
			for keybind, info in pairs(db.binds) do
				tinsert(OverboundDB.char[char].keybinds, {
					type = bindTypes[info.bindType],
					input = info.command,
					keybind = keybind,
				})
			end
		end

		for keybind, info in pairs(backup.global.binds) do
			tinsert(private.db.profile.keybinds, {
				type = bindTypes[info.bindType],
				input = info.command,
				keybind = keybind,
			})
		end
	end
end

function private:InitializeSlashCommands()
	addon:RegisterChatCommand("obind", "SlashCommandFunc")
	addon:RegisterChatCommand("obound", "SlashCommandFunc")
	addon:RegisterChatCommand("overbound", "SlashCommandFunc")
end

function addon:PLAYER_ENTERING_WORLD()
	private:LoadFrame()
end

function addon:SlashCommandFunc()
	private:LoadFrame()
end

private.defaults = {
	keybind = {
		keybind = "",
		type = "macrotext",
		input = "",
	},
}

private.defaultSettings = {
	char = {
		keybinds = {},
	},
	global = {
		-- debug = true,
	},
	profile = {
		enabled = true,
		keybinds = {},
	},
}

private.status = {}
