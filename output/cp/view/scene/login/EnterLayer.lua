local BLayer = require "cp.view.ui.base.BLayer"
local EnterLayer = class("EnterLayer",BLayer)

function EnterLayer:create()
	local layer = EnterLayer.new()
	return layer
end

function EnterLayer:initListEvent()
	self.listListeners = {
	}

end

function EnterLayer:onInitView(openInfo)
	self.rootView = cc.CSLoader:createNode("uicsb/uicsb_login/enter.csb") 
	self:addChild(self.rootView)

	local childConfig = {
		["Panel_root"] = {name = "Panel_root"},
		["Panel_root.Panel_1"] = {name = "Panel_1"},
		["Panel_root.Image_logo"] = {name = "Image_logo"},
		["Panel_root.Panel_1.Button_lastserver"] = {name = "Button_lastserver", click = "onLastserverClick"},
		["Panel_root.Panel_1.Button_lastserver.Image_serverstatus"] = {name = "Image_serverstatus"},
		["Panel_root.Panel_1.Button_lastserver.Image_status"] = {name = "Image_status"},
		["Panel_root.Panel_1.Button_lastserver.Text_serverindex"] = {name = "Text_serverindex"},  
		["Panel_root.Panel_1.Button_lastserver.Text_servername"] = {name = "Text_servername"},
		["Panel_root.Panel_1.Button_enter"] = {name = "Button_enter", click = "onEnterClick"},
	}
	cp.getManager("ViewManager").setCSNodeBinding(self,self.rootView,childConfig)

	self.rootView:setContentSize(display.size)
	cp.getManager("ViewManager").addModalByDefaultImage(self)
	ccui.Helper:doLayout(self["rootView"])
	cp.getManager("ViewManager").setCSNodeTextClear(self.rootView)
	self.Image_logo:ignoreContentAdaptWithSize(true)
	self.enterServerInfo = nil
end

function EnterLayer:onEnterClick()
	
	local strArr = string.split(self.enterServerInfo.ip,":")
	cp.getGameData("GameNet"):setValue("ip",strArr[1])
	cp.getGameData("GameNet"):setValue("port",tonumber(strArr[2]))

	cp.getManager("SocketManager"):doDisConnect()
	cp.getManager("SocketManager"):doConnectGame()

	local token = cp.getUserData("UserLogin"):getValue("user_token")
	local req = {}
	req.token = token
	req.cutover = 0
	req.zoneid = self.enterServerInfo.id
	local lastServerInfo = cp.getUserData("UserLogin"):getValue("lastServerInfo")
	if lastServerInfo ~= nil and next(lastServerInfo) ~= nil then
		if lastServerInfo.id ~= self.enterServerInfo.id then
			req.cutover = 1
		end
	end
	self:doSendSocket(cp.getConst("ProtoConst").EnterGameReq, req)
	
end

function EnterLayer:onEnterScene()
	local lastServerInfo = cp.getUserData("UserLogin"):getValue("lastServerInfo")
	if lastServerInfo ~= nil and next(lastServerInfo) ~= nil then
		self:initLastSelectServerInfo(lastServerInfo)
	end
end

function EnterLayer:initLastSelectServerInfo(servrInfo)
	self.enterServerInfo = servrInfo
	self["Text_serverindex"]:setString("伺服器" .. tostring(servrInfo.id))
	self["Text_servername"]:setString(servrInfo.name)
	self:initServerStatus(servrInfo.status)
	dump(servrInfo)
	cp.getGameData("GameLogin"):setValue("selectServerInfo",servrInfo)
end

function EnterLayer:initServerStatus(status)
	self["Image_serverstatus"]:loadTexture( filename, ccui.TextureResType.plistType)
		local filename = "ui_login_module01_log_zbiaoqian.png"
		if status == 1 then
			filename = "ui_login_jian.png"
		elseif status == 2 then
			filename = "ui_login_xin.png"
		elseif status == 3 then
			filename = "ui_login_re.png"
		elseif status == 4 then
			filename = "ui_login_man.png"
		end
		self["Image_status"]:loadTexture(filename, ccui.TextureResType.plistType)
end

function EnterLayer:setLastserverClickCallBack(cb)
	self.onClickLastServerCallBack = cb
end

function EnterLayer:onLastserverClick(sender)
	if self.onClickLastServerCallBack ~= nil then
		self.onClickLastServerCallBack()
	end
end

--[[
function EnterLayer:setEnterGameCallBack(cb)
	self.enterGameCallBack = cb
end
]]

return EnterLayer
