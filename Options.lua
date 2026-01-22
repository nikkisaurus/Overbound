local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceGUI = LibStub("AceGUI-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

function private:ClearNewKeybinding()
	private.status.newInput = nil
	private.status.newKeybind = nil
	private.status.newType = nil
end

function private:CreateDataObject()
	local dataObject = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(addonName, {
		type = "launcher",
		icon = 1499566,
		label = addonName,
		OnTooltipShow = function(self)
			self:AddLine(addonName)
			self:AddLine(private.db.profile.enabled and L["Enabled"] or L["Disabled"], 1, 1, 1, 1)
			self:AddLine(L["Left-click to configure global keybinds."], 1, 1, 1, 1)
			self:AddLine(L["Right-click to configure character keybinds."], 1, 1, 1, 1)
			self:AddLine(L["Alt+right-click to enable/disable keybinds."], 1, 1, 1, 1)
		end,
		OnClick = function(_, button)
			if IsAltKeyDown() and button == "RightButton" then
				if private.db.profile.enabled then
					private.db.profile.enabled = false
				else
					private.db.profile.enabled = true
				end

				addon:SetEnabledState(private.db.profile.enabled)
				if private.db.profile.enabled then
					addon:Enable()
				else
					addon:Disable()
				end
			elseif button == "LeftButton" then
				private:LoadFrame("global")
			elseif button == "RightButton" then
				private:LoadFrame("char")
			end
		end,
	})
end

function private:GetBindingOptions(Type)
	local options = {
		new = {
			order = 1,
			type = "group",
			inline = true,
			name = NEW,
			args = {
				input = {
					order = 1,
					type = "input",
					width = "full",
					multiline = true,
					name = L["Input"],
					get = function()
						return private.status.newInput or ""
					end,
					set = function(_, value)
						private.status.newInput = value
					end,
				},
				type = {
					order = 2,
					type = "select",
					name = L["Type"],
					values = {
						macrotext = L["Macrotext"],
						action = L["Action"],
						func = L["Function"],
					},
					get = function()
						return private.status.newType or "macrotext"
					end,
					set = function(_, value)
						private.status.newType = value
					end,
				},
				keybind = {
					order = 3,
					type = "keybinding",
					name = "",
					get = function()
						return private.status.newKeybind
					end,
					set = function(_, value)
						private.status.newKeybind = value
					end,
				},
				save = {
					order = 4,
					type = "execute",
					name = SAVE,
					func = function()
						if
							private:ValidateKeybinding(
								Type,
								private.status.newInput,
								private.status.newType,
								private.status.newKeybind
							)
						then
							local keybinding = private.defaults.keybind
							tinsert(private.db[Type].keybinds, {
								input = private.status.newInput,
								keybind = private.status.newKeybind,
								type = private.status.newType or "macrotext",
							})
							private:ClearNewKeybinding()
							private:SetBindings()
							private:RefreshOptions()
						end
					end,
				},
				invalid = {
					order = 5,
					type = "description",
					name = function()
						return "\n" .. (private.status.newError or "")
					end,
				},
			},
		},
	}

	for key, info in pairs(private.db[Type].keybinds) do
		options[tostring(key)] = {
			type = "group",
			name = info.keybind or "",
			args = {
				invalid = {
					order = 1,
					type = "description",
					name = function()
						local validated = private:ValidateBinding(info)

						return validated and ""
							or format(L['Invalid keybinding (%s): %s "%s"'], info.keybind, info.type, info.input)
					end,
				},
				input = {
					order = 2,
					type = "input",
					width = "full",
					multiline = 15,
					name = L["Input"],
					get = function()
						return info.input
					end,
					set = function(_, value)
						private.db[Type].keybinds[key].input = value or ""
						private:SetBindings()
						private:RefreshOptions()
					end,
				},
				type = {
					order = 3,
					type = "select",
					name = L["Type"],
					values = {
						macrotext = L["Macrotext"],
						action = L["Action"],
						func = L["Function"],
					},
					get = function()
						return info.type
					end,
					set = function(_, value)
						private.db[Type].keybinds[key].type = value or "macrotext"
						private:SetBindings()
						private:RefreshOptions()
					end,
				},
				keybind = {
					order = 4,
					type = "keybinding",
					name = "",
					get = function()
						return info.keybind
					end,
					set = function(_, value)
						private.db[Type].keybinds[key].keybind = value or ""
						private:SetBindings()
						private:RefreshOptions()
					end,
				},
				delete = {
					order = 5,
					type = "execute",
					name = DELETE,
					func = function()
						tremove(private.db[Type].keybinds, key)
						private:SetBindings()
						private:RefreshOptions()
					end,
					confirm = function()
						return format(L["Are you sure you want to delete the keybinding for %s?"], info.keybind)
					end,
				},
			},
		}
	end

	return options
end

function private:GetOptions()
	local options = {
		type = "group",
		name = addonName,
		childGroups = "tab",
		args = private:GetOptionsArgs(),
	}

	return options
end

function private:GetOptionsArgs()
	local options = {
		enable = {
			order = 1,
			type = "toggle",
			name = L["Enable"],
			get = function()
				return private.db.profile.enabled
			end,
			set = function(_, value)
				private.db.profile.enabled = value and true or false
				addon:SetEnabledState(private.db.profile.enabled)
				if value then
					addon:Enable()
				else
					addon:Disable()
				end
			end,
		},
		global = {
			order = 2,
			type = "group",
			name = L["Global"],
			args = private:GetBindingOptions("profile"),
		},
		char = {
			order = 3,
			type = "group",
			name = L["Character"],
			args = private:GetBindingOptions("char"),
		},
		-- settings = {
		-- 	order = 4,
		-- 	type = "group",
		-- 	name = L["Settings"],
		-- 	args = {},
		-- },
		profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(private.db),
	}

	return options
end

function private:InitializeFrame()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, private:GetOptions())
	private.options = ACR:GetOptionsTable(addonName, "dialog", addonName .. "-1.0")
	ACD:SetDefaultSize(addonName, 600, 700)

	private.frame = AceGUI:Create("Frame")
	_G["OverboundFrame"] = private.frame.frame
	tinsert(UISpecialFrames, "OverboundFrame")
	private.frame:Hide()
end

function private:KeybindingExists(db, keybind)
	for _, info in pairs(private.db[db].keybinds) do
		if info.keybind == keybind then
			return true
		end
	end
end

function private:LoadFrame(...)
	ACD:SelectGroup(addonName, ...)
	ACD:Open(addonName, private.frame)
end

function private:RefreshOptions(...)
	private.options.args = private:GetOptionsArgs()

	if ... then
		ACD:SelectGroup(addonName, ...)
	end

	ACD:Open(addonName, private.frame)
end

function private:ValidateKeybinding(db, input, Type, keybind)
	if not keybind then
		private.status.newError = L["Invalid keybinding"]
		return
	elseif private:KeybindingExists(db, keybind) then
		private.status.newError = L["Keybinding already exists"]
		return
	end

	private.status.newError = ""
	return true
end
