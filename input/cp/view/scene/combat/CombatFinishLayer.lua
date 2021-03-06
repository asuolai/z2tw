local BLayer = require "cp.view.ui.base.BLayer"
local CombatFinishLayer = class("CombatFinishLayer", BLayer)
local CombatConst = cp.getConst("CombatConst")
function CombatFinishLayer:create(openInfo)
    local scene = CombatFinishLayer.new()
    return scene
end

function CombatFinishLayer:initListEvent()
    self.listListeners = {
		[cp.getConst("EventConst").EnterStoryLevelRsp] = function(data)
			if data.result == 0 then
				cp.getManager("ViewManager"):changeScene(cp.getConst("SceneConst").SCENE_COMBAT)
			elseif data.result == 2 then
				self:fightTimesNotEnough(data.id) --困難本每天有挑戰次數限制
			end
		end,
		["FightTowerFloorRsp"] = function(data)
            local combatReward = {
                currency_list = {},
                item_list = data.item_list
            }
            cp.getUserData("UserCombat"):setValue("Floor", data.floor)
			cp.getUserData("UserCombat"):setCombatReward(combatReward)
			local fightInfo = {floor = data.floor}
            cp.getUserData("UserCombat"):resetFightInfo()
			cp.getUserData("UserCombat"):updateFightInfo(fightInfo)
			cp.getManager("ViewManager"):changeScene(cp.getConst("SceneConst").SCENE_COMBAT)
		end,
		[cp.getConst("EventConst").StartMijingRsp] = function(data)
			local rewardList = {} 
			rewardList.item_list = {}
			rewardList.currency_list = {}
			table.insert(rewardList.currency_list, {type=cp.getConst("GameConst").VirtualItemType.exp, num = data.exp})
			if data.items ~= nil and next(data.items) ~= nil then
				for i=1,table.nums(data.items) do
					table.insert(rewardList.item_list,{item_id = data.items[i].id,item_num = data.items[i].num})
				end
			end
			if data.exItems ~= nil and next(data.exItems) ~= nil then
				for i=1,table.nums(data.exItems) do
					table.insert(rewardList.item_list,{item_id = data.exItems[i].id,item_num = data.exItems[i].num, isActive = true})
				end
			end
		
			cp.getUserData("UserCombat"):setCombatReward(rewardList)
			cp.getManager("ViewManager"):changeScene(cp.getConst("SceneConst").SCENE_COMBAT)
		end,

		[cp.getConst("EventConst").UpdateCurrencyRsp] = function(evt)
			self:onUpdateCurrencyRsp()
		end,
    }
end

--初始化界面，以及設定界面元素標籤
function CombatFinishLayer:onInitView()
    self.rootView = cc.CSLoader:createNode("uicsb/uicsb_combat/uicsb_combat_finish.csb")
	self.rootView:setPosition(cc.p(0,0))
    self:addChild(self.rootView, 1)
    self.rootView:setContentSize(display.size)

    local childConfig = {
		["Panel_Finish"] = {name = "Panel_Finish"},
		["Panel_Finish.Node_Root"] = {name = "Node_Root"},
		["Panel_Finish.Node_Root.Image_Result"] = {name = "Image_Result"},
		["Panel_Finish.Node_Root.Node_Win"] = {name = "Node_Win"},
		["Panel_Finish.Node_Root.Node_Win.Panel_virtual_item"] = {name = "Panel_virtual_item"},
		["Panel_Finish.Node_Root.Node_Win.ScrollView_1"] = {name = "ScrollView_1"},
		
		["Panel_Finish.Node_Root.Node_Lose"] = {name = "Node_Lose"},
		["Panel_Finish.Node_Root.Node_Lose.Button_Equip"] = {name = "Button_Equip", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Lose.Button_SkillLevelUp"] = {name = "Button_LevelUp", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Lose.Button_GainSkill"] = {name = "Button_GainSkill", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Public"] = {name = "Node_Public"},
		["Panel_Finish.Node_Root.Node_Public.Button_OK"] = {name = "Button_OK", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Public.Button_Again"] = {name = "Button_Again", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Public.Image_Title.Text_Title"] = {name = "Text_Title"},
		
		["Panel_Finish.Node_Root.Node_Public.Image_Physical"] = {name = "Image_Physical"},
		["Panel_Finish.Node_Root.Node_Public.Image_Physical.Image_icon"] = {name = "Image_icon"},
		["Panel_Finish.Node_Root.Node_Public.Image_Physical.Text_Physical"] = {name = "Text_Physical"},
		["Panel_Finish.Node_Root.Node_Public.Image_Physical.Button_AddPhysical"] = {name = "Button_AddPhysical", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Public.Panel_exp"] = {name="Panel_exp"}, 
		["Panel_Finish.Node_Root.Node_Public.Panel_exp.LoadingBar_Exp"] = {name = "LoadingBar_Exp"},
		["Panel_Finish.Node_Root.Node_Public.Panel_exp.Text_Exp"] = {name = "Text_LevelupExp"},
		["Panel_Finish.Node_Root.Node_Public.Button_Record"] = {name = "Button_Record", click="onBtnClick"},
		["Panel_Finish.Node_Root.Node_Public.Button_Share"] = {name = "Button_Share", click="onBtnClick"},
	}

	cp.getManager("ViewManager").setCSNodeBinding(self, self.rootView, childConfig)
	cp.getManager("ViewManager").setCSNodeTextClear(self.rootView)
	self.Node_Root:setPosition(display.width/2, display.height/2)

	ccui.Helper:doLayout(self.rootView)

	self.Button_Equip:setTouchEnabled(false)
	self.Button_LevelUp:setTouchEnabled(false)
	self.Button_GainSkill:setTouchEnabled(false)
	self.Button_Share:setVisible(false)

end

function CombatFinishLayer:onBtnClick(btn)
    local nodeName = btn:getName()
    if nodeName == "Button_OK" then
		cp.getManager("ViewManager"):popScene()
		cp.getUserData("UserCombat"):setCombatReward(nil)
		cp.getUserData("UserRole"):setValue("major_roleAtt_old", nil)
	elseif nodeName == "Button_Again" then
		local combat_type = cp.getUserData("UserCombat"):getCombatType()
		if combat_type == CombatConst.CombatType_Tower then
			local towerConfig = cp.getUtils("DataUtils").split(cp.getManager("ConfigManager").getItemByKey("Common", 1):getValue("TowerConfig"), ";")
			local towerData = cp.getUserData("UserTower"):getTowerData()
			if towerData.floor == towerConfig[7] then
				cp.getManager("ViewManager").gameTip("已通關修羅塔，可重置層數快速爬塔獲取獎勵")
			else
				self:doSendSocket(cp.getConst("ProtoConst").FightTowerFloorReq, {})
			end
		elseif combat_type == CombatConst.CombatType_Mijing then
			local fight_id = cp.getUserData("UserMijing"):getValue("fight_id")
			local req = {}
			req.id = fight_id
			self:doSendSocket(cp.getConst("ProtoConst").StartMijingReq, req)
			cp.getManager("GDataManager"):setFightDelay(true)
		else
			local req = {}
			req.id = cp.getUserData("UserCombat"):getID()
			req.combat_type = combat_type
			req.difficulty = cp.getUserData("UserCombat"):getCombatDifficulty()
			self:doSendSocket(cp.getConst("ProtoConst").EnterStoryLevelReq, req) 
			cp.getManager("GDataManager"):setFightDelay(true)
			cp.getUserData("UserRole"):setValue("major_roleAtt_old", nil)
		end
	elseif nodeName == "Button_Record" then
        cp.getUserData("UserCombat"):setValue("Mode", 1)
		cp.getManager("ViewManager"):changeScene(cp.getConst("SceneConst").SCENE_COMBAT)
	elseif nodeName == "Button_AddPhysical" then
		cp.getManager("ViewManager").showBuyPhysicalUI()
	elseif nodeName == "Button_Equip" then
	elseif nodeName == "Button_SkillLevelUp" then
	elseif nodeName == "Button_GainSkill" then
	elseif nodeName == "Button_Share" then
		self:shareToChatChannel()
	end
end


function CombatFinishLayer:showView(result, combatReward)
	local majorRole = cp.getUserData("UserRole"):getValue("major_roleAtt")
	local roleAttr = cp.getManager("ConfigManager").getItemByKey("RoleAttribute", majorRole.level)
	self.Text_Title:setString(roleAttr:getValue("Realm"))
	self.Text_LevelupExp:setString(string.format("%d/%d", majorRole.exp, roleAttr:getValue("ExpMax")))
	local roleMaxLv = cp.getManager("GDataManager"):getRoleMaxLevel()
	if majorRole.level >= roleMaxLv then
		self.LoadingBar_Exp:setPercent(100)
		self.Text_LevelupExp:setString(string.format("%d/%d", roleAttr:getValue("ExpMax"), roleAttr:getValue("ExpMax")))
	else
		self.LoadingBar_Exp:setPercent(100*majorRole.exp/roleAttr:getValue("ExpMax"))
		self.Text_LevelupExp:setString(string.format("%d/%d", majorRole.exp, roleAttr:getValue("ExpMax")))
	end

	self.Text_Physical:setString(string.format("%d/%d", majorRole.physical, majorRole.physicalMax))
	local shaderName = nil
	local combat_type = cp.getUserData("UserCombat"):getCombatType()
	if combat_type == CombatConst.CombatType_Story then
		cp.getManager("ViewManager").setEnabled(self.Button_Again, true)
	elseif combat_type == CombatConst.CombatType_Tower then
		cp.getManager("ViewManager").setEnabled(self.Button_Again, true)
		if result == CombatConst.CombatRoundResult_Left then
			self.Button_Again:getChildByName("Text"):setString("挑戰下一層")
		else
			self.Button_Again:getChildByName("Text"):setString("再次挑戰")
		end
	elseif combat_type == CombatConst.CombatType_Mijing then
		cp.getManager("ViewManager").setEnabled(self.Button_Again, true)
	else
		cp.getManager("ViewManager").setEnabled(self.Button_Again, false)
    end

	if combat_type == CombatConst.CombatType_HeroChallenge then
		local Config = cp.getManager("ConfigManager").getItemByKey("Other", "init_vigor")
		local init_vigor = Config:getValue("IntValue")
		self.Text_Physical:setString(string.format("%d/%d", majorRole.vigor, init_vigor))
		self.Button_AddPhysical:setVisible(false)
		self.Image_icon:loadTexture("",ccui.TextureResType.plistType)
	end

	local Mode = cp.getUserData("UserCombat"):getValue("Mode")
	if Mode == 0 then
		if combat_type == CombatConst.CombatType_Story or
			combat_type == CombatConst.CombatType_Shane or
			combat_type == CombatConst.CombatType_Friend or
			combat_type == CombatConst.CombatType_Arena or
			combat_type == CombatConst.CombatType_InviteHero or
			combat_type == CombatConst.CombatType_MenPai or
			combat_type == CombatConst.CombatType_Van or
			combat_type == CombatConst.CombatType_GuildWanted or
			combat_type == CombatConst.CombatType_HeroChallenge or
			combat_type == CombatConst.CombatType_Tower then
			self.Button_Share:setVisible(true)
			self.fight_shared = false
		end
	end


	if result ~= CombatConst.CombatRoundResult_Left then
		self.Node_Lose:setVisible(true)
		self.Node_Public:setPosition(0, 0)
		self.Node_Win:setVisible(false)
		self.Image_Result:loadTexture("ui_combat_finish_module03_jiesuan_shibai.png", ccui.TextureResType.plistType)
		cp.getManager("AudioManager"):playMusic(cp.getManualConfig("AudioConfig").bg_fight_fail,false)
		return
	end

	cp.getManager("AudioManager"):playMusic(cp.getManualConfig("AudioConfig").bg_fight_success,false)

	self.Node_Lose:setVisible(false)
	self.Image_Result:loadTexture("ui_combat_finish_module03_jiesuan_shengli.png", ccui.TextureResType.plistType)

	self.Node_Public:setPosition(0, -50)
	self.Panel_virtual_item:removeAllChildren()
	local totalW = self.Panel_virtual_item:getContentSize().width
	combatReward.currency_list = combatReward.currency_list or {}
	local beginPosX = 0 --起始X座標
	local space = 0
	local totalNum = table.nums(combatReward.currency_list)
	if totalNum == 1 then
		beginPosX = 200
		space = 0
	elseif totalNum == 2 then
		beginPosX = 125
		space = 110
	elseif totalNum == 3 then
		beginPosX = 70
		space = 50
	elseif totalNum == 4 then
		beginPosX = 10
		space = 30
	end

	local distance = 0
	for i=1, totalNum do
		local item = require("cp.view.ui.item.HuobiItem"):create(combatReward.currency_list[i].type,combatReward.currency_list[i].num,true)
		self.Panel_virtual_item:addChild(item)
		item:setPosition(beginPosX+50,0)
		beginPosX = beginPosX + item:getTotalWidth() + space
	end

	self.ScrollView_1:removeAllChildren()
	if combatReward.item_list ~= nil and next(combatReward.item_list) ~= nil then
		self:initItemList(combatReward.item_list)
	end

	local expPool = 0
	if combatReward.currency_list and next(combatReward.currency_list) then
		for i=1,table.nums(combatReward.currency_list) do
			if combatReward.currency_list[i].type == cp.getConst("GameConst").VirtualItemType.exp then
				expPool = combatReward.currency_list[i].num
				break
			end
		end
	end

	local oldAttr = cp.getUserData("UserRole"):getValue("major_roleAtt_old")
	if expPool and expPool > 0 and oldAttr then
		self:addExp(expPool, oldAttr.level, oldAttr.exp)
	end

	--修改關卡進度與挑戰次數
	if combat_type == CombatConst.CombatType_Story then
		local current_id = cp.getGameData("GameChallenge"):getValue("current_id")
		local hard_level = cp.getGameData("GameChallenge"):getValue("hard_level")
		cp.getUserData("UserCombat"):updateChapterPartInfo("fight", current_id, hard_level, 1)

		local listStr = cp.getUserData("UserRole"):getValue("newplayerguider")
		if not string.find(listStr.finished,"equip")  then
			cp.getManager("ViewManager").setEnabled(self.Button_Again, false)
			cp.getManager("ViewManager").setEnabled(self.Button_Share, false)
			cp.getManager("ViewManager").setEnabled(self.Button_Record, false)
		end
		
	end

end



function CombatFinishLayer:initItemList(itemList)
	if itemList == nil or #itemList == 0 then
		return
	end
	
	local newList = {} --顯示的物品列表
	local isHavePrimeval = false
	for i=1,table.nums(itemList) do
		local id = itemList[i].item_id
		local cfgItem = cp.getManager("ConfigManager").getItemByKey("GameItem", id)
		if cfgItem ~= nil then
			local Type = cfgItem:getValue("Type")
			local SubType = cfgItem:getValue("SubType")
			if not (Type == 8 and SubType == 20) then
				table.insert(newList,itemList[i])
			else
				isHavePrimeval = true  --當前結算界面有混元需要顯示
			end
		end
	end


	self.Primeval_idx_list = {}
	if isHavePrimeval then
		local MetaInfoList = cp.getUserData("UserPrimeval"):getRecentAddMeta()
		if MetaInfoList and next(MetaInfoList) then  --當前有混元存在
			
			itemList = {}
			--先添加混元
			for i=1,table.nums(MetaInfoList) do
				if MetaInfoList[i] and MetaInfoList[i].id > 0 and MetaInfoList[i].color > 0 then
					local Config = cp.getManager("ConfigManager").getItemByMatch("GameItem", {Extra = tostring(MetaInfoList[i].id), Hierarchy = MetaInfoList[i].color,SubType=20,Type=8})
					if Config then
						local id = Config:getValue("ID")
						table.insert(itemList,{item_id = id, item_num=1})
					end
				end
			end
			
			for i=1,table.nums(newList) do
				table.insert(itemList,newList[i])
			end
		end
	end

	local scrollViewSize = self.ScrollView_1:getContentSize()
	

    local function createScrollItem(id,num,i,totalNum,isActive)
		local cfgItem = cp.getManager("ConfigManager").getItemByKey("GameItem", id)
        if cfgItem == nil then
            log("cfgItem is nil id = " .. tostring(id))
        end
		local itemInfo = {id = id, num = num, Name = cfgItem:getValue("Name") , Icon = cfgItem:getValue("Icon") , Colour = cfgItem:getValue("Hierarchy"),Type = cfgItem:getValue("Type"),SubType = cfgItem:getValue("SubType")}
		if itemInfo.Type == 8 and itemInfo.SubType == 20 then
			itemInfo.scale = 0.85 --混元要縮放
			table.insert(self.Primeval_idx_list,i)
		end
        --itemInfo.shopModel = true  --控制物品icon數量的顯示規則
        local item = require("cp.view.ui.icon.ItemIcon"):create(itemInfo)
		item:setScale(0.9)
		local current_id = cp.getGameData("GameChallenge"):getValue("current_id")
		local hard_level = cp.getGameData("GameChallenge"):getValue("hard_level")
		local isFirst = false
		if hard_level == 0 and current_id > cp.getUserData("UserCombat"):getValue("normal_chapter_part_id") then
			isFirst = true
		elseif hard_level == 1 and current_id > cp.getUserData("UserCombat"):getValue("hard_chapter_part_id")then
			isFirst = true
		end

		if isFirst then
			item:addFlag("shoutong")
		end
		if isActive then
			item:addFlag("huodong")
		end
		item:setItemClickCallBack(function(info)
			if info.Type == 8 and info.SubType == 20 then
				local MetaInfoList = cp.getUserData("UserPrimeval"):getRecentAddMeta()
				local idx = table.arrIndexOf(self.Primeval_idx_list,i)
				if idx ~= -1 and MetaInfoList[idx] ~= nil then
					local layer = require("cp.view.scene.primeval.PrimevalMetaLayer"):create(MetaInfoList[idx].pos, true)
					self:addChild(layer, 100)
				end
			else
				local layer = require("cp.view.scene.skill.SkillMatiralLayer"):create(cfgItem)
				self:addChild(layer, 100)
				layer:hidePlaceAndButtons()
			end
		end)
        self.ScrollView_1:addChild(item)
        
		local space = 0
		local sz = item:getContentSize()
        if totalNum <= 4 then --只有1行
            if totalNum == 1 then
                space = 0
            elseif totalNum == 2 then
                space = 90
            elseif totalNum == 3 then
                space = 60
            elseif totalNum == 4 then
                space = 35
            end
            local startX = scrollViewSize.width/2 - totalNum/2 * sz.width - (totalNum-1)*space/2
            startX = startX < 0 and 0 or startX
            local x = startX + (i-1)*sz.width + (i-1)*space
            item:setPosition(cc.p(x+sz.width/2,scrollViewSize.height - sz.height/2-20))

        else
            scrollViewSize = self.ScrollView_1:getInnerContainerSize()
            --每行4列
            local y = math.floor((i-1)/4)  -- 0開始
            local x = math.floor((i-1)%4)  -- 0,1,2,3
            item:setPosition(cc.p((sz.width+30)*x+sz.width,scrollViewSize.height - y*(sz.height+40 ) - (sz.height/2+20)))
        end
        item:setVisible(true)
    end
        
    local totalNum = #itemList
	local newHeight = 150
	local sz = cc.size(110,110) --一個物品框的大小
	if totalNum > 4 then
		local row = math.floor(totalNum / 4) + 1
		local newHeight = row * (sz.height+40)
		self.ScrollView_1:setInnerContainerSize(cc.size(scrollViewSize.width, newHeight))
	end
	for i=1,totalNum do
		local id = itemList[i].item_id
		local num = itemList[i].item_num

		createScrollItem(id,num,i,totalNum, itemList[i].isActive)
	end
	ccui.Helper:doLayout(self.rootView)
end

function CombatFinishLayer:addExp(expPool, level, fromExp)
	local roleConfig = cp.getManager("ConfigManager").getItemByKey("RoleAttribute", level)
	local maxExp = roleConfig:getValue("ExpMax")
	self.LoadingBar_Exp:setPercent(100*fromExp/maxExp)
	self.Text_LevelupExp:setString(string.format("%d/%d", fromExp, maxExp))
	if not expPool or expPool == 0 then
		return
	end

	local exp = fromExp
	local deltaExp = expPool/20
	local toExp = fromExp + expPool
	local levelup = false
	if toExp >= maxExp then
		toExp = maxExp
		levelup = true
	end

	self.LoadingBar_Exp:runAction(cc.RepeatForever:create(
		cc.Sequence:create(cc.DelayTime:create(1/60), cc.CallFunc:create(function()
			exp = exp + deltaExp
			expPool = expPool - deltaExp
			if exp >= toExp then
				if exp >= maxExp then
					exp = 0
					local newAttr = cp.getUserData("UserRole"):getValue("major_roleAtt")
					maxExp = cp.getManager("ConfigManager").getItemByKey("RoleAttribute", newAttr.level):getValue("ExpMax")
					toExp = newAttr.exp
					expPool = newAttr.exp
					cp.getManager("ViewManager").showRoleLevelUpView(level,newAttr.level)
				else
					self.LoadingBar_Exp:stopAllActions()
					self.LoadingBar_Exp:setPercent(100*toExp/maxExp)
					self.Text_LevelupExp:setString(string.format("%d/%d", toExp, maxExp))
				end
			end

			self.LoadingBar_Exp:setPercent(100*exp/maxExp)
			self.Text_LevelupExp:setString(string.format("%d/%d", exp, maxExp))
	end))))
	if level == 50 then
		self.LoadingBar_Exp:stopAllActions()
		self.LoadingBar_Exp:setPercent(100)
		self.Text_LevelupExp:setString(string.format("%d/%d", maxExp, maxExp))
	end
end

function CombatFinishLayer:onEnterScene()

end

function CombatFinishLayer:onExitScene()
    self:unscheduleUpdate()
end

function CombatFinishLayer:shareToChatChannel()
	
	if self.fight_shared then
		cp.getManager("ViewManager").gameTip("已成功分享過了。")
		return
	end
	
	local combat_type = cp.getUserData("UserCombat"):getCombatType()

	local combat_result = cp.getUserData("UserCombat"):getCombatData().combat_result
	local combat_iD = combat_result.combat_iD
	local isWin = combat_result.result
	
	local enemy_info = cp.getUserData("UserCombat"):getValue("fight_enemy_info")
	local name = enemy_info.name or "none"
	local partID = 0 	    --劇情章節id
	local difficut = 0  		--劇情困難度
	local career = -1 		    --門派
	-- local guild_name = "" 	--幫派名字
	local rank = 0  		    --對方門派排行
	local place = "none"  		--伏擊鏢車地點
	local floor = 0  		    --修羅塔層數
	local hierarchy = 0
	
	if combat_type == CombatConst.CombatType_Tower then --修羅塔
		local towerData = cp.getUserData("UserTower"):getTowerData()
		floor = towerData and towerData.floor or 0
		floor = floor or 0
	elseif combat_type == CombatConst.CombatType_MenPai then --門派地位戰和門派進階戰
		rank = enemy_info.rank or 0
		hierarchy = enemy_info.hierarchy or 0
		career = enemy_info.career or -1
	elseif combat_type == CombatConst.CombatType_Van then --伏擊鏢車
		place = enemy_info.place or "none"
	elseif combat_type == CombatConst.CombatType_Story then --劇情關卡
		partID = enemy_info.partID or 0
		difficut = enemy_info.difficut or 0
	end

	local content = {}
	local msg = "<fight=("
	msg = msg .. "combat_id=" .. tostring(combat_iD)
	msg = msg .. ",combat_type=" .. tostring(combat_type)
	msg = msg .. ",result=" .. tostring(isWin)
	msg = msg .. ",name=" .. name

	msg = msg .. ",rank=" .. tostring(rank)
	msg = msg .. ",place=" .. tostring(place)
	msg = msg .. ",floor=" .. tostring(floor)
	msg = msg .. ",partID=" .. tostring(partID)
	msg = msg .. ",difficut=" .. tostring(difficut)
	msg = msg .. ",career=" .. tostring(career)
	msg = msg .. ",hierarchy=" .. tostring(hierarchy)
	msg = msg .. ")>"
	log(msg)
	table.insert(content,msg)

	local req = {}
	req.channel = 1  --發送消息頻道(1世界 2門派 3幫派 4私聊)
	req.roleID = 0
	req.zoneID = 0
	req.content = content
	self:doSendSocket(cp.getConst("ProtoConst").ChatShareReq, req)
	self.fight_shared = true
	
end

function CombatFinishLayer:fightTimesNotEnough(id)
	local BuyTiaoZhanCost = cp.getManager("ConfigManager").getItemByKey("Common", 1):getValue("BuyTiaoZhanCost")

	local function comfirmFunc()
		--檢測是否元寶足夠
		if cp.getManager("ViewManager").checkGoldEnough(BuyTiaoZhanCost) then
			local req = {mode = 1, story_id=id}
			self:doSendSocket(cp.getConst("ProtoConst").ResetStoryReq, req) --重置挑戰次數
		end
	end
	
	local contentTable = {
		{type="ttf", fontName="fonts/msyh.ttf", fontSize=24, text="當前關卡挑戰次數不足，是否花費", textColor=cc.c4b(255,255,255,255), outLineColor=cc.c4b(0,0,0,255), outLineSize=2},
		{type="ttf", fontName="fonts/msyh.ttf",fontSize=24, text=tostring(BuyTiaoZhanCost), textColor=cc.c4b(0,255,0,255), outLineColor=cc.c4b(0,0,0,255), outLineSize=2},
		{type="image",filePath="ui_common_yuanbao.png",textureType=ccui.TextureResType.plistType,verticalAlign="bottom"},
		{type="ttf",  fontName="fonts/msyh.ttf", fontSize=24, text="，購買3次挑戰次數？", textColor=cc.c4b(255,255,255,255), outLineColor=cc.c4b(0,0,0,255), outLineSize=2},
	}
	cp.getManager("ViewManager").showGameMessageBox("系統消息",contentTable,2,comfirmFunc,nil)
end

function CombatFinishLayer:onUpdateCurrencyRsp()
	local majorRole = cp.getUserData("UserRole"):getValue("major_roleAtt")
	self.Text_Physical:setString(string.format("%d/%d", majorRole.physical, majorRole.physicalMax))
end

return CombatFinishLayer
