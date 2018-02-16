local acutil = require('acutil')
local util = dofile('../data/addon_d/tooltiphelper/tooltiphelper_util.lua')

function ADJUST_POTENTIAL_CSET(parentCtrl, invItem)
	local cnt = parentCtrl:GetChildCount()
	local needAppraisal = TryGetProp(invItem, "NeedAppraisal")
	local needRandomOption = TryGetProp(invItem, "NeedRandomOption")
	local isUnidentified = (needAppraisal == 1 or needRandomOption == 1) and true or false;
	
	for i = 0, cnt - 1 do repeat
		local ctrl = parentCtrl:GetChildByIndex(i);
		local ctrlName = ctrl:GetName()
		local margin = ctrl:GetMargin()
		
		if ctrl == nil then break end
		
		if ctrlName == 'labelline' then
			ctrl:ShowWindow(0)
			break;
		end
		
		if ctrlName:find("_text") ~= nil then
			ctrl:SetMargin(margin.left+70,margin.top,20,margin.bottom)
			ctrl:ShowWindow(isUnidentified == false and 1 or 0)
			break;
		end

		if ctrlName:find("_gauge") ~= nil then 
			ctrl:SetMargin(margin.left+35,margin.top,margin.right,margin.bottom)
			ctrl:Resize(ctrl:GetWidth()/2, ctrl:GetHeight());
			ctrl:ShowWindow(isUnidentified == false and 1 or 0)			
			break;
		end
		
		if ctrlName:find("appraisalPic") ~= nil then
			ctrl:SetMargin(margin.left+90,5,0,0)
			ctrl:Resize(ctrl:GetWidth()/1.80, ctrl:GetHeight());
			ctrl:ShowWindow(isUnidentified == true and 1 or 0)
			break;
		end
	until true end
end

function DRAW_EQUIP_PR_N_DUR_HOOKED(tooltipFrame, invItem, yPos, mainFrameName)
	local itemClass = GetClassByType("Item", invItem.ClassID);
	if invItem.GroupName ~= "Armor" and invItem.GroupName ~= "Weapon" then 
	    if invItem.BasicTooltipProp == "None" then
    		return yPos;
		end
	end

	local classtype = TryGetProp(invItem, "ClassType"); 
	if classtype ~= nil then
		if (classtype == "Outer") 
		or (classtype == "Hat") 
		or (classtype == "Hair") 
		or ((itemClass.PR == 0) and (invItem.MaxDur <= 0)) then
			return yPos;
		end
		
		local isHaveLifeTime = TryGetProp(invItem, "LifeTime");	
		if isHaveLifeTime ~= nil then
			if ((isHaveLifeTime > 0) and (invItem.MaxDur <= 0))  then
				return yPos;
			end;
		end
	end
	
	local mainFrame = GET_CHILD(tooltipFrame, mainFrameName,'ui::CGroupBox')
	local equipTypeNWeightCSet = GET_CHILD(mainFrame, 'tooltip_equip_type_n_weight');
	_G["DRAW_EQUIP_PR_N_DUR_OLD"](tooltipFrame, invItem, equipTypeNWeightCSet:GetY(), mainFrameName)
	
	local targetYPos = equipTypeNWeightCSet:GetY()+equipTypeNWeightCSet:GetHeight()/2
	local needAppraisal = TryGetProp(invItem, "NeedAppraisal")
	local needRandomOption = TryGetProp(invItem, "NeedRandomOption")
	local maxSocket = SCR_GET_MAX_SOKET(invItem);
	local socketText = (needAppraisal ~= 1 and maxSocket > 0) and "Sockets: "..maxSocket or "Unsocketable"
	
	local prNDurCSet = mainFrame:CreateOrGetControlSet('tooltip_pr_n_dur', 'tooltip_pr_n_dur', 0, targetYPos);
	ADJUST_POTENTIAL_CSET(prNDurCSet, invItem);
	prNDurCSet:SetMargin(0,equipTypeNWeightCSet:GetY()+35,0,0)
	prNDurCSet:Resize(prNDurCSet:GetOriginalWidth(), equipTypeNWeightCSet:GetHeight())
	
	local weightSocket = prNDurCSet:CreateOrGetControl('richtext', 'tth_weight_text', 0,0,prNDurCSet:GetX()+10,prNDurCSet:GetY())
	weightSocket:SetText("{s16}Weight: "..invItem.Weight.."{nl}"..socketText.."{/}");
	weightSocket:SetFontName("brown_16")
	weightSocket:SetGravity(ui.RIGHT, ui.TOP)
	weightSocket:SetMargin(15,5,0,0)
	weightSocket:ShowWindow(1);
	
	return yPos
end

function DRAW_EQUIP_ONLY_PR_HOOKED(tooltipFrame, invItem, yPos, mainFrameName)
	local itemClass = GetClassByType("Item", invItem.ClassID);

	local classtype = TryGetProp(invItem, "ClassType");
		
	if classtype ~= nil then
		if (classtype ~= "Hat" and invItem.BasicTooltipProp ~= "None")
		or (itemClass.PR == 0) 
		or (classtype == "Outer")
		or (itemClass.ItemGrade == 0 and classtype == "Hair") then
			return yPos;
		end;
	end

	local mainFrame = GET_CHILD(tooltipFrame, mainFrameName,'ui::CGroupBox')
	local equipTypeNWeightCSet = GET_CHILD(mainFrame, 'tooltip_equip_type_n_weight');
	_G["DRAW_EQUIP_ONLY_PR_OLD"](tooltipFrame, invItem, equipTypeNWeightCSet:GetY(), mainFrameName)
	
	local prOnlyCSet = mainFrame:CreateOrGetControlSet('tooltip_only_pr', 'tooltip_only_pr', 0, equipTypeNWeightCSet:GetY()+equipTypeNWeightCSet:GetHeight()/2);
	ADJUST_POTENTIAL_CSET(prOnlyCSet)
	prOnlyCSet:SetMargin(0,equipTypeNWeightCSet:GetY()+35,50,0)
	prOnlyCSet:Resize(prOnlyCSet:GetOriginalWidth(), equipTypeNWeightCSet:GetHeight())
	
	local weightSocket = prOnlyCSet:CreateOrGetControl('richtext', 'tth_weight_text', 0,0,prOnlyCSet:GetX()+10,prOnlyCSet:GetY())
	weightSocket:SetText("{s16}Weight: "..invItem.Weight.."{nl}Unsocketable{/}");
	weightSocket:SetFontName("brown_16")
	weightSocket:SetGravity(ui.RIGHT, ui.TOP)
	weightSocket:SetMargin(15,5,0,0)
	weightSocket:ShowWindow(1);
	
	return yPos
end

function DRAW_EQUIP_COMMON_TOOLTIP_HOOKED(tooltipFrame, invItem, mainFrameName, isForgery)
	local yPos = _G["DRAW_EQUIP_COMMON_TOOLTIP_OLD"](tooltipFrame, invItem, mainFrameName, isForgery);
    local mainFrame = GET_CHILD(tooltipFrame, mainFrameName);
    
	local equipCommonCSet = mainFrame:CreateOrGetControlSet('tooltip_equip_common', 'equip_common_cset',0,0);
    equipCommonCSet:SetMargin(0,0,0,0)
	equipCommonCSet:Resize(equipCommonCSet:GetWidth()/3, equipCommonCSet:GetHeight()/1.25)
	
	local nowEquipGBox = GET_CHILD(equipCommonCSet, 'nowequip')
	nowEquipGBox:Resize(30,30)
	nowEquipGBox:SetMargin(10,40,0,0)
	
	local nowEquipText = GET_CHILD(nowEquipGBox, 'nowequip_text')
	if nowEquipText:IsVisible() == 1 then
		nowEquipText:SetText("{img equip_inven 55 55}{/}")
		nowEquipText:SetMargin(5,15,0,0)
	end
	
	local itemBg = GET_CHILD(equipCommonCSet, 'item_bg', 'ui::CPicture')
	itemBg:SetOffset(-20 ,itemBg:GetY())
	itemBg:Resize(80, 80)
	itemBg:SetEnableStretch(1)

	local itemPic = GET_CHILD(equipCommonCSet, 'itempic')
	itemPic:SetMargin(-20,55,0,0)
	itemPic:Resize(65,65)

	local cantReinforcePic = GET_CHILD(equipCommonCSet, 'cantreinforce')
	cantReinforcePic:Resize(20,20)
	cantReinforcePic:SetOffset(itemBg:GetX()+40, itemBg:GetY()+itemBg:GetHeight()-20)
	local cantReinforceText = GET_CHILD(equipCommonCSet, 'cantrf_text')
	cantReinforceText:ShowWindow(0)
	
	local origNameCtrl = equipCommonCSet:CreateOrGetControl('richtext', 'name', 0,0,0,0)
	origNameCtrl:ShowWindow(0)
	
	local itemNameGbox = mainFrame:CreateOrGetControl('groupbox', 'tth_gbox_equip_name', 0, 0, equipCommonCSet:GetOriginalWidth(), 0);
    tolua.cast(itemNameGbox, "ui::CGroupBox");
    itemNameGbox:SetMargin(0,10,0,10)
    itemNameGbox:SetSkinName("")
    itemNameGbox:SetGravity(ui.LEFT, ui.TOP)
    
	local itemNameTemplate = "{s22}{ol}{#%s}%s{/}"
	local text = string.format(itemNameTemplate, acutil.getItemRarityColor(invItem), GET_FULL_NAME(invItem, true, 0))
    
    local itemNameCtrl = itemNameGbox:CreateOrGetControl('richtext','tth_text_equip_name',0,0,0,0)
    tolua.cast(itemNameCtrl, "ui::CRichText")
    itemNameCtrl:SetText(text)
	itemNameCtrl:SetGravity(ui.CENTER_HORZ, ui.TOP)
	itemNameCtrl:Resize(itemNameGbox:GetWidth(), itemNameCtrl:GetHeight())
	EXTEND_BY_CHILD(itemNameGbox, itemNameCtrl)
    
	return itemNameGbox:GetHeight()+5;
end

function DRAW_ITEM_TYPE_N_WEIGHT_HOOKED(tooltipFrame, invItem, yPos, mainFrameName)
	local mainFrame = GET_CHILD(tooltipFrame, mainFrameName,'ui::CGroupBox');
	mainFrame:RemoveChild('tooltip_equip_type_n_weight')
	
	local equipCommonCSet = GET_CHILD(mainFrame, 'equip_common_cset');
	local itemBg = GET_CHILD(equipCommonCSet, 'item_bg') 
	
	local equipTypeNWeightCSet = mainFrame:CreateOrGetControlSet('tooltip_equip_type_n_weight', 'tooltip_equip_type_n_weight', 0, yPos+5);
	equipTypeNWeightCSet:ShowWindow(1)
	
	local newWidth = equipTypeNWeightCSet:GetOriginalWidth()/1.25;
	local newHeight = equipTypeNWeightCSet:GetHeight()/1.75;
	local typeChild = GET_CHILD(equipTypeNWeightCSet,'type','ui::CRichText');
	local reqLv = (invItem.UseLv > 1) and "Lv"..invItem.UseLv or "Lv1"
	typeChild:SetText("{s16}"..reqLv.." "..GET_REQ_TOOLTIP(invItem).."{/}");
	typeChild:SetGravity(ui.RIGHT, ui.TOP)
	typeChild:Resize(newWidth-10,newHeight)
	typeChild:ShowWindow(1);
	
	local oldWeightSocket = GET_CHILD(equipTypeNWeightCSet,'weight','ui::CRichText');
	oldWeightSocket:ShowWindow(0)
	
	local classTable = {}
	
	local usableJobs = {}
	local prop = geItemTable.GetProp(invItem.ClassID);
	local cnt = prop:GetUseJobCount();
	if cnt ~= nil and cnt ~= 0 then
		for i = 0, cnt - 1 do repeat 
			local jobCls = GetClassByType("Job", prop:GetUseJob(i));
			local job = (jobCls.CtrlType == 'Warrior') and 'Swordsman' or jobCls.CtrlType
			if util.contains(usableJobs, job) then break end
			table.insert(usableJobs, job)
		until true end
	end
	
	local jobText = (#usableJobs > 0) and table.concat(usableJobs,",") or 'Any Class'
	local useJob = equipTypeNWeightCSet:CreateOrGetControl('richtext', 'tth_use_job', 0, 0,0,typeChild:GetY()+typeChild:GetHeight())
	useJob:SetText("{s16}"..jobText.."{/}")
	useJob:SetMargin(90, typeChild:GetHeight()-10,0,0)
	useJob:SetFontName("brown_18_b")
	useJob:SetGravity(ui.LEFT, ui.TOP)
	
	if invItem.BasicTooltipProp ~= 'None' then
		return yPos+equipTypeNWeightCSet:GetHeight()*1.45;
	else
		return itemBg:GetY()+itemBg:GetHeight()+5;
	end	
end

function DRAW_EQUIP_ATK_N_DEF_HOOKED(tooltipFrame, invItem, yPos, mainFrameName, strArg, basicProp)
	local yPos = _G["DRAW_EQUIP_ATK_N_DEF_OLD"](tooltipFrame, invItem, yPos, mainFrameName, strArg, basicProp)
	local atkNDefGBox = GET_CHILD(tooltipFrame, mainFrameName)
	local equipAtkNDefCSet = atkNDefGBox:CreateOrGetControlSet('tooltip_equip_atk_n_def', 'tooltip_equip_atk_n_def'..basicProp, 0, yPos+10);
	equipAtkNDefCSet:SetOffset(equipAtkNDefCSet:GetX(), equipAtkNDefCSet:GetY()-equipAtkNDefCSet:GetHeight())
	return equipAtkNDefCSet:GetY()+30
end

function DRAW_AVAILABLE_PROPERTY_HOOKED(tooltipFrame, invItem, yPos, mainFrameName)
	return yPos
end

function GET_USEJOB_TOOLTIP_HOOKED(invItem)
	local result = _G["GET_USEJOB_TOOLTIP_OLD"](invItem);
	local replace = string.gsub(result,",","{nl}");
	return result
end

function DRAW_SELL_PRICE_HOOKED(tooltipFrame, invItem, yPos, mainFrameName)
	return yPos
end
