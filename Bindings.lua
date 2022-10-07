local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function addon:PLAYER_REGEN_ENABLED()
	private:SetBindings()
	addon:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function private:BindButtonFrame(info, func)
	private.numButtons = private.numButtons or 1

	local button =
		CreateFrame("Button", "OverboundButtons" .. private.numButtons, UIParent, "SecureActionButtonTemplate")
	button:EnableMouse(true)
	button:RegisterForClicks("AnyDown")

	button:SetAttribute("type1", info.type == "func" and "click" or info.type == "macrotext" and "macro")
	if info.type == "func" then
		button:SetScript("PostClick", func)
	elseif info.type == "macrotext" then
		button:SetAttribute("macrotext", info.input)
	end
	SetOverrideBindingClick(private.frame.frame, true, info.keybind, button:GetName())

	private.numButtons = private.numButtons + 1
end

function private:SetBinding(info)
	local validated = private:ValidateBinding(info)

	if validated then
		if info.type == "action" then
			SetOverrideBinding(private.frame.frame, true, info.keybind, info.input)
		else
			private:BindButtonFrame(info, info.type == "func" and validated)
		end
	else
		private:BindButtonFrame({
			type = "func",
			keybind = info.keybind,
			func = "function() end",
		}, function()
			addon:Printf(L['Invalid keybinding (%s): %s "%s"'], info.keybind, info.type, info.input)
		end)
	end
end

function private:SetBindings()
	if UnitAffectingCombat("player") then
		addon:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	ClearOverrideBindings(private.frame.frame)

	for _, info in pairs(private.db.profile.keybinds) do
		private:SetBinding(info)
	end

	for _, info in pairs(private.db.char.keybinds) do
		private:SetBinding(info)
	end
end

function private:ValidateBinding(info)
	if info.type == "action" and not _G["BINDING_NAME_" .. strupper(info.input)] then
		return
	elseif info.type == "func" then
		local func = loadstring("return " .. info.input)
		if type(func) == "function" then
			local success, userFunc = pcall(func)
			if not success then
				return
			else
				return userFunc
			end
		else
			return
		end
	end

	return true
end
