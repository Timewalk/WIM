-----------------------------------------------------------------------------------------------
-- Client Lua Script for WIM
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
require "ChatSystemLib"
require "ChatChannelLib"
 
-----------------------------------------------------------------------------------------------
-- WIM Module Definition
-----------------------------------------------------------------------------------------------
local WIM = {} 
local hMsgBox = {}
local hMessage = {}
local hButton = {}
local hChatLog = {}
local hSavedData = {} 
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
	local chatOptions = {}
	chatOptions.Green = Apollo.LoadForm("WIM.xml", "ChatLine", self.wndOptions:FindChild("sendColor"), self)
	chatOptions.Green:SetText("Green")
	chatOptions.Green:SetTextColor("Green")
	chatOptions.Green:ArrangeChildrenVert()
	chatOptions.Green:Show(false)
    self.wndOptions:Show(false)
	
    
end


-----------------------------------------------------------------------------------------------
-- WIM Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/WIM"
function WIM:OnWIMOn()
	self.wndOptions:Show(true) -- show the window
end

-----------------------------------------------------------------------------------------------
-- WIM EVENT Functions
-----------------------------------------------------------------------------------------------

function WIM:OnChatMessage(channelCurrent, bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction)
	local msgChannelType = channelCurrent:GetType()
	local msgSenderAndRealm = strSender
	local tMsgBox
	local msgColor
	
	if strRealmName:len() > 0 then
		msgSenderAndRealm = msgSenderAndRealm .. "@" .. strRealmName
	end
	local msgNameTag = bSelf and GameLib.GetPlayerUnit():GetName() or msgSenderAndRealm
		
	if msgChannelType == ChatSystemLib.ChatChannel_Whisper then
		local msgMessage = ""
		for idx, chat in pairs(arMessageSegments) do
			msgMessage = msgMessage .. chat.strText
		end
		
		if hMsgBox[msgSenderAndRealm] == nil then
			hMsgBox[msgSenderAndRealm] = Apollo.LoadForm("WIM.xml", "WIMForm", nil, self)
			hMsgBox[msgSenderAndRealm]:FindChild("Title"):SetText(msgSenderAndRealm)
			local tChatData = {}
			tChatData.wndForm = hMsgBox[msgSenderAndRealm]
			tChatData.tChildren = {}
			tChatData.tChildren.nFirst = 0
			tChatData.tChildren.nLast = -1	
			hMsgBox[msgSenderAndRealm]:SetData(tChatData)
		end
		
		msgMessage = "[" .. msgNameTag .. "]: " .. msgMessage		
		local tChatLine = Apollo.LoadForm("WIM.xml", "ChatLine", hMsgBox[msgSenderAndRealm]:FindChild("ChatBox"), self)
		
		if msgNameTag == GameLib.GetPlayerUnit():GetName() then
			msgColor = ApolloColor.new("ChatAdvice")
		else
			msgColor = ApolloColor.new("ChatWhisper")
		end
		tChatLine:SetTextColor(msgColor)
		tChatLine:SetText(msgMessage)
		
		
		tMsgBox = hMsgBox[msgSenderAndRealm]:GetData()
		local tChatBox = hMsgBox[msgSenderAndRealm]:FindChild("ChatBox")
		
		local nLast = tMsgBox.tChildren.nLast + 1
		tMsgBox.tChildren.nLast = nLast
		tMsgBox.tChildren[nLast] = tChatLine
		
		for idx = tMsgBox.tChildren.nFirst, tMsgBox.tChildren.nLast do
			tMsgBox.tChildren[idx]:SetHeightToContentHeight()
		end	
		
		tChatBox:ArrangeChildrenVert()
				
		hMsgBox[msgSenderAndRealm]:Show(true)
		tChatBox:SetVScrollPos(tChatBox:GetVScrollRange())	

	end
end

-----------------------------------------------------------------------------------------------
-- WIMForm Functions
-----------------------------------------------------------------------------------------------
-- Close Btn
function WIM:onBtnDown( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end
--Chat Input 
function WIM:OnChat( wndHandler, wndControl, strText )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/tell" .. " " .. sender .. " " .. strText)
	wndControl:SetText("")
end
-- Ignore Btn
function WIM:BtnIgnoreCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Ignore" .. " " .. sender)
end
-- Party Invite Btn
function WIM:BtnPartyCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Invite" .. " " .. sender)
end
-- Guild Invite Btn
function WIM:BtnGuildCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/gInvite" .. " " .. sender)
end
-- Friend Invite Btn
function WIM:BtnFriendCheck( wndHandler, wndControl, eMouseButton )
	local sender = wndControl:GetParent():FindChild("Title"):GetText()
	ChatSystemLib.Command("/Friend" .. " " .. sender)
end

function WIM:wndMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	wndHandler:FindChild("Title")
	hMsgBox[wndHandler:FindChild("Title"):GetText()]:ToFront()

	--wndControl:FindChild("Title"):GetText()
	--ToFront()
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

function WIM:btnExpand( wndHandler, wndControl, eMouseButton )
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

function WIM:onEditBoxReturn( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("SaveTest"):SetText(strText)
	hSavedData.SaveTest = strText
end

-----------------------------------------------------------------------------------------------
-- WIM Instance
-----------------------------------------------------------------------------------------------
local WIMInst = WIM:new()
WIMInst:Init()
