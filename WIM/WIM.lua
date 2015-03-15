-----------------------------------------------------------------------------------------------
-- Client Lua Script for WIM
-- Copyright (c) NCsoft. All rights reserved
-- Author TimeWalk aka Joahua Klarich
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
require "ChatSystemLib"
require "ChatChannelLib"
require "GroupLib"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- WIM Module Definition
-----------------------------------------------------------------------------------------------
local WIM = {} 
WIM.options = {}
WIM.msgBox = {}

local hMsgBox = {}
local hMessage = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WIM:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function WIM:Init()
    Apollo.RegisterAddon(self)
	
end
 

-----------------------------------------------------------------------------------------------
-- WIM OnLoad
-----------------------------------------------------------------------------------------------
function WIM:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("WIM", "OnWIMOn", self)

	Apollo.RegisterEventHandler("ChatMessage", 					"OnChatMessage", self)
	Apollo.RegisterEventHandler("ChatTellFailed", 				"OnChatTellFailed", self)
	
	Apollo.RegisterEventHandler("Event_EngageWhisper", 					"OnEvent_EngageWhisper", self)
	Apollo.RegisterEventHandler("GenericEvent_ChatLogWhisper", 			"OnGenericEvent_ChatLogWhisper", self)
	Apollo.RegisterEventHandler("Event_EngageAccountWhisper",			"OnEvent_EngageAccountWhisper", self)
	
    -- load our forms
    self.wndOptions = Apollo.LoadForm("WIM.xml", "Options", nil, self)

	-- colors
	self.options.colors.self = ApolloColor.new("ChatAdvice")
	self.options.colors.guild = ApolloColor.new("ChatGuild")
	self.options.colors.tell = ApolloColor.new("ChatWhisper")
	self.options.colors.party = ApolloColor.new("ChatWhisper")
	self.options.colors.system = ApolloColor.new("ChatSystem")
	self.options.colors.zone = ApolloColor.new("ChatWhisper")
	self.options.colors.raid = ApolloColor.new("ChatWhisper")
end


-----------------------------------------------------------------------------------------------
-- WIM Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/WIM"
function WIM:OnWIMOn()
	self.wndOptions:FindChild("TimeStamp"):SetCheck(self.options.TimeStamp)
	self.wndOptions:FindChild("GuildChat"):SetCheck(self.options.GuildChat)
	self.wndOptions:FindChild("PartyChat"):SetCheck(self.options.PartyChat)
	self.wndOptions:FindChild("ZoneChat"):SetCheck(self.options.ZoneChat)
	self.wndOptions:FindChild("RaidChat"):SetCheck(self.options.RaidChat)

	self.wndOptions:Show(true) -- show the window
end

-- Save Function
function WIM:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end

    return self.options
end

-- Restore Function
function WIM:OnRestore(eType, tData)
	testSave = eType
	if tData ~= nil then
    	self.options = tData
	end
end

-----------------------------------------------------------------------------------------------
-- WIM Helper Functions
-----------------------------------------------------------------------------------------------

function WIM:ParseChat(systemMsg)
	local msgMessage = ""
	for idx, chat in pairs(systemMsg) do
		msgMessage = msgMessage .. chat.strText
	end
	return msgMessage
end

function WIM:GenerateMessage(systemMsg, idx)
	local tMessage = WIM:ParseChat(systemMsg)
	if tMessage == "Unhandled Event Log Type: 0" then 
		return
	end
	
	if self.msgBox[idx] == nil then
		self.msgBox[idx] = Apollo.LoadForm("WIM.xml", "WIMForm", nil, self)
		self.msgBox[idx]:FindChild("Title"):SetText(idx)
		self.msgBox[idx]:FindChild("Title"):SetColor(self.options.colors.guild)
	end	
	
	self.time = ""
	tMessage = "[" .. self.Message.Tag .. "]" .. self.time .. ": " .. tMessage
	local tChatLine = Apollo.LoadForm("WIM.xml", "ChatLine", self.msgBox[idx]:FindChild("ChatBox"), self)
	
	if self.Message.Tag == self.Message.Guild then	
		tChatLine:SetTextColor(self.options.colors.system)
	elseif self.Message.Tag == GameLib.GetPlayerUnit():GetName()
		tChatLine:SetTextColor(self.options.colors.self)
	else
		tChatLine:SetTextColor(self.options.colors.guild)
	end
		
	tChatLine:SetText(msgMessage)
	tChatLine:SetHeightToContentHeight()
	-- Arrange the messages
	self.msgBox[idx]:FindChild("ChatBox"):ArrangeChildrenVert()		
	self.msgBox[idx]:Show(true)
	self.msgBox[idx]:FindChild("ChatBox"):SetVScrollPos(hMsgBox[idx]:FindChild("ChatBox"):GetVScrollRange())
	
end

-----------------------------------------------------------------------------------------------
-- WIM EVENT Functions
-----------------------------------------------------------------------------------------------

function WIM:OnChatMessage(channelCurrent, bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction)
	self.Message.Sender = strSender
	
	-- Get the name of the Message Sender, if account whisper add the realm name for easy responces
	if strRealmName:len() > 0 then
		self.Message.Sender = self.Message.Sender .. "@" .. strRealmName		
	end
	
	-- Check if sender id the player set the nameTag to the players name, if not the senders name
	self.Message.Tag = bSelf and GameLib.GetPlayerUnit():GetName() or self.Message.Sender

	-- Guild Message
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Guild and self.options.GuildChat == true then
		self.Message.GuildName = channelCurrent:GetName()
		if self.Message.Tag == "" then
			self.Message.Tag = self.Message.GuildName
		end
		WIM:GenerateMessage(arMessageSegments, self.Message.Sender)
	end
	
	-- Whisper Message
	if msgChannelType == ChatSystemLib.ChatChannel_Whisper then
		--local msgMessage = WIM:ParseChat(arMessageSegments)
		WIM:GenerateMessage(arMessageSegments, self.Message.Sender)
		
		-- Check if new sender
		if hMsgBox[msgSenderAndRealm] == nil then
			-- Craete new Message window
			hMsgBox[msgSenderAndRealm] = Apollo.LoadForm("WIM.xml", "WIMForm", nil, self)
			-- Set the Window Title to the name of the sender
			hMsgBox[msgSenderAndRealm]:FindChild("Title"):SetText(msgSenderAndRealm)
		end

		-- Format the message line and create a new line
		--    TODO!!! Set the time stap information
		msgMessage = "[" .. msgNameTag .. "]: " .. msgMessage		
		local tChatLine = Apollo.LoadForm("WIM.xml", "ChatLine", hMsgBox[msgSenderAndRealm]:FindChild("ChatBox"), self)
		
		-- Format the color of the message line
		if msgNameTag == GameLib.GetPlayerUnit():GetName() then
			msgColor = ApolloColor.new("ChatAdvice")
		else
			msgColor = ApolloColor.new("ChatWhisper")
		end
		-- Set the Color and Text 
		
		tChatLine:SetTextColor(msgColor)
		tChatLine:SetText(msgMessage)
		tChatLine:SetHeightToContentHeight()
		-- Arrange the messages
		hMsgBox[msgSenderAndRealm]:FindChild("ChatBox"):ArrangeChildrenVert()
		
		-- Show the message box 		
		hMsgBox[msgSenderAndRealm]:Show(true)
		hMsgBox[msgSenderAndRealm]:FindChild("ChatBox"):SetVScrollPos(hMsgBox[msgSenderAndRealm]:FindChild("ChatBox"):GetVScrollRange())	
	end
end

-----------------------------------------------------------------------------------------------
-- WIMForm Functions
-----------------------------------------------------------------------------------------------
-- Close Btn
function WIM:OnBtnDown( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end
--Chat Input 
function WIM:OnChat( wndHandler, wndControl, strText )
	local channel  = wndControl:GetParent():FindChild("Title"):GetText()
	if channel == self.gGuildName then
		ChatSystemLib.Command("/g ".. strText)
	else
	ChatSystemLib.Command("/tell " .. channel .. " " .. strText)
	end
	wndControl:SetText("")
end
-- Ignore Btn
function WIM:BtnIgnoreCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Ignore " .. sender)
end
-- Party Invite Btn
function WIM:BtnPartyCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Invite " .. sender)
end
-- Guild Invite Btn
function WIM:BtnGuildCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/gInvite " .. sender)
end
-- Friend Invite Btn
function WIM:BtnFriendCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Friend " .. sender)
end

function WIM:wndMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	wndHandler:FindChild("Title")
	hMsgBox[wndHandler:FindChild("Title"):GetText()]:ToFront()
end

---------------------------------------------------------------------------------------------------
-- Options Functions
---------------------------------------------------------------------------------------------------

function WIM:BtnOpenAll( wndHandler, wndControl, eMouseButton )
	for idx, frame in pairs(hMsgBox) do
		frame:Show(true)
	end
end

function WIM:btnClose( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end

function WIM:opOnMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	wndControl:GetParent():ToFront()
end

function WIM:OnTimeStamp( wndHandler, wndControl, eMouseButton )
	self.options.TimeStamp = wndControl:IsChecked()
end

function WIM:OnGuildChat( wndHandler, wndControl, eMouseButton )
	self.options.GuildChat = wndControl:IsChecked()
end

function WIM:OnPartyChat( wndHandler, wndControl, eMouseButton )
	self.options.PartyChat = wndControl:IsChecked()
end

function WIM:OnZoneChat( wndHandler, wndControl, eMouseButton )
	self.options.ZoneChat = wndControl:IsChecked()
end

function WIM:OnRaidChat( wndHandler, wndControl, eMouseButton )
	self.options.RaidChat = wndControl:IsChecked()
end

function WIM:OnClose( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end

function WIM:OnExpand( wndHandler, wndControl, eMouseButton )
	local nLeft, nTop, nRight, nBottom = wndControl:GetParent():GetAnchorOffsets()
	if (nBottom - nTop) > 200 then	
	wndControl:GetParent():SetAnchorOffsets(nLeft, nTop, nRight, nBottom - 135)
	wndControl:GetParent():FindChild("ExpandIcon"):SetSprite("CRB_ChatLogSprites:btnCL_ExpandPressedFlyby")
	wndControl:GetParent():FindChild("TimeStamp"):Show(false)
	else
	wndControl:GetParent():SetAnchorOffsets(nLeft, nTop, nRight, nBottom + 135)
	wndControl:GetParent():FindChild("ExpandIcon"):SetSprite("CRB_ChatLogSprites:btnCL_ExpandFlyby")
	wndControl:GetParent():FindChild("TimeStamp"):Show(true)
	end
end

---------------------------------------------------------------------------------------------------
-- Player List Functions
---------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------
-- WIM Instance
-----------------------------------------------------------------------------------------------
local WIMInst = WIM:new()
WIMInst:Init()
