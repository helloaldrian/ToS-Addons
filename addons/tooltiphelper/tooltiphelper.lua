local acutil = require('acutil');
local util = dofile('../data/addon_d/tooltiphelper/tooltiphelper_util.lua')
local magnum_opus = dofile('../data/addon_d/tooltiphelper/tooltiphelper_magnumopus.lua')
local cache = dofile('../data/addon_d/tooltiphelper/tooltiphelper_cache.lua')
local custom_equip = dofile('../data/addon_d/tooltiphelper/tooltiphelper_custom_equip.lua')


if not TooltipHelper then
	_G['ADDONS'] = _G['ADDONS'] or {};
	TooltipHelper = _G["ADDONS"]["TOOLTIPHELPER"] or {}
	TooltipHelper.indexTbl = {}
	TooltipHelper.magnumOpusRecipes = {}
end

TooltipHelper.version = "3.0.0"

TooltipHelper.configFile 	 = "../addons/tooltiphelper/tooltiphelper.json";

TooltipHelper.config = {
    showCollections 			 = true,
    showCompletedCollections	 = true,
    showRerollPrice				 = true,
    showRecipes	 				 = true,
    showRecipeHaveNeedCount		 = true,
    showAwakening				 = true,
    showTranscendence			 = true,
    showIdentification			 = true,
    showMagnumOpus				 = true,
    showJournalStats			 = true,
    showMedalExchange			 = true,
	showItemDrops				 = true,
	version						 = TooltipHelper.version
}

TooltipHelper.config = 
	cache.configureData(
		TooltipHelper.configFile, 
		TooltipHelper.config, 
		TooltipHelper.version)

function TOOLTIPHELPER_ON_INIT(addon, frame)
	TooltipHelper.addon = addon;
	TooltipHelper.frame = frame;
	
	TOOLTIPHELPER_INIT();
end

function ITEM_TOOLTIP_BOSSCARD_HOOKED(tooltipFrame, invItem, strArg)
    _G["ITEM_TOOLTIP_BOSSCARD_OLD"](tooltipFrame, invItem, strArg);
    
    local mainFrameName = 'bosscard'
    
    return DRAW_TTH_SECTION(tooltipFrame, invItem, strArg, nil, mainFrameName, true, MAKE_TTH_INV_ITEM_DATA(invItem))
end

function ITEM_TOOLTIP_EQUIP_HOOKED(tooltipFrame, invItem, strArg, useSubFrame)
    _G["ITEM_TOOLTIP_EQUIP_OLD"](tooltipFrame, invItem, strArg, useSubFrame);
    
    local mainFrameName = 'equip_main'
    
    if useSubFrame == "usesubframe" or useSubFrame == "usesubframe_recipe" then 
        mainFrameName = 'equip_sub'
    end
    
	local tthYPos = DRAW_TTH_SECTION(tooltipFrame, invItem, strArg, useSubFrame, mainFrameName, false, MAKE_TTH_INV_ITEM_DATA(invItem))
    
	return tooltipFrame:GetY();
end

function ITEM_TOOLTIP_ETC_HOOKED(tooltipFrame, invItem, strArg, useSubFrame)
    _G["ITEM_TOOLTIP_ETC_OLD"](tooltipFrame, invItem, strArg, useSubFrame);
    
    local mainFrameName = 'etc'
    
    if useSubFrame == "usesubframe" or useSubFrame == "usesubframe_recipe" then
        mainFrameName = "etc_sub"
    end
    
	local tthYPos = DRAW_TTH_SECTION(tooltipFrame, invItem, strArg, useSubFrame, mainFrameName, false, MAKE_TTH_INV_ITEM_DATA(invItem))
    
	return tooltipFrame:GetY(); 
end

function ITEM_TOOLTIP_GEM_HOOKED(tooltipFrame, invItem, strArg)
    _G["ITEM_TOOLTIP_GEM_OLD"](tooltipFrame, invItem, strArg);
    
    local mainFrameName = 'gem'
    
    return DRAW_TTH_SECTION(tooltipFrame, invItem, strArg, nil, mainFrameName, true, MAKE_TTH_INV_ITEM_DATA(invItem))
end

function TTH_DRAW_EQUIP_COMMON_TOOLTIP(tooltipFrame, invItem, mainFrameName, isForgery)
	return _G["DRAW_EQUIP_COMMON_TOOLTIP_OLD"](tooltipFrame, invItem, util.tthMainFrameName, isForgery);
end

function DRAW_TTH_SECTION(tooltipFrame, invItem, strArg, useSubFrame, mainFrameName, isTthSubFrame, text, rightText)
	if useSubFrame == nil then useSubFrame = "" end
	local mainFrameGBox = GET_CHILD(tooltipFrame, mainFrameName);
    
	local tthMainFrameName = util.tthMainFrameName
    local skinName = isTthSubFrame and "test_Item_tooltip_equip_sub" or ""
    local isCard = (mainFrameName == 'bosscard') and 100 or 0
    local offSetX = isTthSubFrame and mainFrameGBox:GetX() + mainFrameGBox:GetWidth() or 0 
    local offSetY = isTthSubFrame and isCard or mainFrameGBox:GetHeight()
    
    local marktioneerFrame = isTthSubFrame and tthMainFrameName or mainFrameName
    
	local tthTextGBox = nil;
	if isTthSubFrame then
		tthTextGBox = tooltipFrame:CreateOrGetControl('groupbox', tthMainFrameName, 0, 0, 0, 0);
	else
		tthTextGBox = mainFrameGBox:CreateOrGetControl('groupbox', tthMainFrameName, 0, 0, 0, 0);
	end
    tolua.cast(tthTextGBox, "ui::CGroupBox");
    tthTextGBox:SetSkinName(skinName);
    tthTextGBox:SetMargin(5,10,5,10);
    tthTextGBox:SetGravity(ui.LEFT, ui.TOP)
    tthTextGBox:SetOffset(offSetX, offSetY)

    local textSection = tthTextGBox:CreateOrGetControl("richtext", 'tth_text_content', 0, 0, 0, 0);
    tolua.cast(textSection, "ui::CRichText");
    textSection:SetText(text);
	textSection:SetMargin(10,10,15,20);
    
    local tthGboxWidth = textSection:GetWidth();
    local tthGboxHeight = textSection:GetHeight() + 10;
    
    if rightText ~= "" then
    	local rightTextCtrl = tthTextGBox:CreateOrGetControl("richtext", 'tth_text_content2', 0,0,0,0);
	    tolua.cast(rightTextCtrl, "ui::CRichText");
	    rightTextCtrl:SetText(rightText)
	    rightTextCtrl:SetMargin(10,10,15,20);
	    rightTextCtrl:SetGravity(ui.RIGHT, ui.TOP)
	    text, rightText = "", ""
	    
		tthGboxWidth = math.max(tthGboxWidth + rightTextCtrl:GetWidth()+50, rightTextCtrl:GetWidth()+50);
		tthGboxHeight = math.max(tthGboxHeight, rightTextCtrl:GetHeight())
    else
    	tthGboxWidth = mainFrameGBox:GetOriginalWidth()
    end
    
    tthTextGBox:Resize(tthGboxWidth, tthGboxHeight+20)
    
  	if not isTthSubFrame then
  		mainFrameGBox:Resize(math.max(410,tthGboxWidth), mainFrameGBox:GetHeight()+tthTextGBox:GetHeight())
  	end
		
	if marktioneerex ~= nil then
		marktioneerex.addMarketPrice(tooltipFrame, marktioneerFrame, invItem, strArg, useSubFrame);
    end
    
    return mainFrameGBox:GetHeight() + mainFrameGBox:GetY()
end

function JOURNAL_STATS(invItem)
	if not invItem.Journal then return "" end
	
	local curScore, maxScore, curLv, curPoint, maxPoint = 0, 0, 0, 0, 0;
	local itemObtainCount = GetItemObtainCount(GetMyPCObject(), invItem.ClassID);
	curScore, maxScore = _GET_ADVENTURE_BOOK_POINT_ITEM(invItem.ItemType == 'Equip', itemObtainCount);
	curLv, curPoint, maxPoint = GET_ADVENTURE_BOOK_ITEM_OBTAIN_COUNT_INFO(invItem.ItemType == 'Equip', itemObtainCount);
	local score = curScore.."/"..maxScore.."{nl}"
	local text = util.toIMCTemplate("Adventure Journal: ")
	if curScore == maxScore then 
		return text..util.toIMCTemplate(maxScore.." points", util.completeColor)
	else
		return text..util.toIMCTemplate(curScore.."/"..maxScore.." points", util.commonColor)
	end 
end

function COLLECTION_SECTION(invItem)
	local cachedCollections = TooltipHelper.indexTbl["Collection"]
	if cachedCollections == nil then
		cache.collectionList()
	end

	local subTbl = cachedCollections[invItem.ClassName];
	if subTbl == nil then
		return ""
	end

	local partOfCollections = {};
	local myColls = session.GetMySession():GetCollection();
	local clsList, cnt = GetClassList("Collection");
	local item = GetClass("Item", invItem.ClassName);

	for i = 1, #subTbl do
		local cls = GetClassByIndexFromList(clsList, subTbl[i]["idx"]);
		local coll = myColls:Get(cls.ClassID);
		local curCount, maxCount = -1 , 0;
		local isCompleted = false;
		local hasRegisteredCollection = false;

		if coll ~= nil then
			curCount, maxCount = GET_COLLECTION_COUNT(coll.type, coll);
			if curCount >= maxCount then
				isCompleted = true;
			end
			hasRegisteredCollection = true
		end

		local text = "";
		local neededCount = util.manuallyCount(cls, item);
		local collCount = 0;
		local collName = string.gsub(dictionary.ReplaceDicIDInCompStr(cls.Name), "Collection: ", "")

		if hasRegisteredCollection then
			local info = geCollectionTable.Get(cls.ClassID);
			collCount = coll:GetItemCountByType(item.ClassID);
			neededCount = info:GetNeedItemCount(item.ClassID);
		end

		text = util.addIcon(collName .. " " .. collCount .. "/" .. neededCount .. " ", util.collectionIcon)

		if isCompleted and TooltipHelper.config.showCompletedCollections then
			text = util.toIMCTemplate(text, util.completeColor)
		elseif hasRegisteredCollection then
			text = util.toIMCTemplate(text, util.commonColor)
		else
			text = util.toIMCTemplate(text, util.unregisteredColor)
		end

		if not util.contains(partOfCollections, text) then
			table.insert(partOfCollections, text);
		end
	end

	return table.concat(partOfCollections,"{nl}")
end

function RECIPE_SECTION(invItem)
	local cachedRecipes = TooltipHelper.indexTbl["Recipe"]
	if cachedRecipes == nil then
		cache.recipeList()
	end

	local subTbl = cachedRecipes[invItem.ClassName];
	if subTbl == nil then
		return ""
	end

	local partOfRecipe = {};
	local superClsList = {};

	for _, classType in ipairs(cachedRecipes["types"]) do
		superClsList[classType] = GetClassList(classType);
	end

	for _, recipeTbl in ipairs(subTbl) do
		local cls = GetClassByIndexFromList(superClsList[recipeTbl["classType"]], recipeTbl["idx"]);
		local resultItem = GetClass("Item", cls.TargetItem);
		local itemName = dictionary.ReplaceDicIDInCompStr(resultItem.Name);
		local recipeIcon = cls.Icon;

		local recipeItem = GetClass("Item", cls["Item_1_1"]);
		local recipeClassID = recipeItem.ClassID;
		local needCount, haveCount = 1, 0;

		if IS_RECIPE_ITEM(invItem) ~= 0 then
			needCount, haveCount = 1, 1;
		else
			needCount, haveCount = GET_RECIPE_MATERIAL_INFO(cls, recipeTbl["pos"]);
		end

		local isRegistered = false;
		local curScore, maxScore = _GET_ADVENTURE_BOOK_CRAFT_POINT(GetCraftCount(GetMyPCObject(), resultItem.ClassID));
		local isCrafted = (curScore >= maxScore);
		local text = "";
		local materialCountText = "";
		local color = util.commonColor;

		if TooltipHelper.config.showRecipeHaveNeedCount then
			materialCountText = haveCount .. "/" .. needCount;
			local color = util.unregisteredColor;
			if not isRegistered then
				color = util.unregisteredColor;
			elseif (invItem.ItemType ~= "Recipe") and (haveCount >= needCount) then
				color = util.completeColor;
			end
			materialCountText = util.toIMCTemplate(materialCountText, color)
		end

		itemName = util.addIcon(itemName, recipeIcon);
		text = util.toIMCTemplate(itemName, acutil.getItemRarityColor(resultItem))

		if isCrafted then
			text = text .. util.addIcon("", resultItem.TooltipImage or resultItem.Icon)
		elseif not isRegistered then
			text = util.toIMCTemplate(itemName, util.unregisteredColor)
		end

		text = text .. " " .. materialCountText

		if marktioneerex ~= nil then
			local recipeData = marktioneerex.getMinimumData(recipeClassID);
			local newLine = "{nl}    ";
			if (recipeData) then 
				text = text .. newLine .. util.addIcon("", recipeIcon) .. " ".. util.toIMCTemplate(GetCommaedText(recipeData.price));
			end
			local resultItemData = marktioneerex.getMinimumData(resultItem.ClassID);
			if (resultItemData) then 
				local resultPrice = " " .. util.addIcon("", resultItem.Icon) .. " ".. util.toIMCTemplate(GetCommaedText(resultItemData.price));
				if (recipeData) then
					text = text .. resultPrice
				else
					text = text .. newLine .. resultPrice
				end
			end
		end
		table.insert(partOfRecipe, text);
	end
	return table.concat(partOfRecipe, "{nl}")
end

function MAGNUM_OPUS_TRANSMUTED_FROM(invItem)
	local newLine = "{nl}"
	local text = ""
	
	local invItemClassName = invItem.ClassName
	
	for k, v in pairs(TooltipHelper.magnumOpusRecipes) do
		if k == invItemClassName then
			local items = v;
			local itemQty = #v
			
			local ingredients = {}
			
			for m = 1, #v do
				local item = v[m]["name"]
				
				if ingredients[item] == nil then
					ingredients[item] = 1
				else
					local oldVal = ingredients[item]
					ingredients[item] = oldVal + 1
				end
			end
			
			--Handle targetItems with multiple ingredients
			for className, quantity in pairs(ingredients) do
				local item = GetClass("Item", className)
				local itemName = dictionary.ReplaceDicIDInCompStr(item.Name)
				text = util.toIMCTemplate(quantity .. "x" .. util.addIcon(itemName, item.Icon)) .. newLine
			end
			
			text = text .. "  "
							
			local maxRow, maxCol = 0, 0;
			for i = 1, itemQty do
				maxRow = math.max(maxRow, items[i]["row"]);
				maxCol = math.max(maxCol, items[i]["col"]);
			end
			for x = 0, maxRow + 1 do
		        for y = 0, maxCol + 1 do
		        	local icon = "{img nomalitem_tooltip_bg 24 24}{/} ";
		        	local isItemFound = false
		        	
					if x <= maxRow then
						for j = 1, itemQty do
							local rowSlot = items[j]["row"]
							local colSlot = items[j]["col"]
							local name = items[j]["name"]
							
							if rowSlot == x and colSlot == y then
								isItemFound = true
							end
							
							if isItemFound == true then
								local prereqItem = GetClass("Item", name)
								local itemIcon = prereqItem.Icon
								icon = "{img " .. prereqItem.Icon .. " 24 24}{/} "
								text = text .. icon
								break;
							end
						end
					end
		        	
		        	if not isItemFound then
		        		text = text .. icon
		        	end
			    end
	        	text = text .. newLine .. "  "
			end
			break;
		end
	end
	
	if text ~= "" then
		text = util.toIMCTemplate("Transmuted From:{nl} ") .. text
	end
	
	return text;
end

function MAGNUM_OPUS_TRANSMUTES_INTO(invItem)
	local text = ""
	
	local results = {}
	local invItemClassName = invItem.ClassName
	
	for k, v in pairs(TooltipHelper.magnumOpusRecipes) do
		local resultItem = k;
		local items = v
		
		for i = 1, #items do repeat 
			local itemClass = items[i]["name"]
			if itemClass ~= invItemClassName then break end
			local oldVal = results[resultItem]
			results[resultItem] = (oldVal == nil) and 1 or oldVal + 1
		until true end
	end
	
	for k, v in pairs(results) do
		local className = k
		local qty = v
		local result = GetClass("Item", className)
		local itemName = dictionary.ReplaceDicIDInCompStr(result.Name)
		text = text .. util.toIMCTemplate("  " .. qty .. "x") 
					.. util.toIMCTemplate(util.addIcon("= 1 ", invItem.Icon)) 
					.. util.toIMCTemplate(util.addIcon(itemName, result.Icon) .. "{nl}")
	end
	
	if text ~= "" then
		text = util.toIMCTemplate("Magnum Opus{nl} Transmutes Into:{nl}") .. text .. "{nl}";
	end
	
	return text;
end

function MAGNUM_OPUS_SECTION(invItem)
	local transmuteInto = MAGNUM_OPUS_TRANSMUTES_INTO(invItem);
	local transmuteFrom = MAGNUM_OPUS_TRANSMUTED_FROM(invItem);
	return transmuteInto .. transmuteFrom; 
end

function ITEM_DROP_SECTION(invItem)
	local cachedDrops = TooltipHelper.indexTbl["Drops"]
	if cachedDrops == nil then
		cache.dropList();
	end
	
	local subTbl = cachedDrops[invItem.ClassName];
	if subTbl == nil then
		return ""
	end
	
	local mapHeader = "";
	local text = "Drops From:{nl}";
	local dropListDisplay = {}
	local mapName = ""
	for i = 1, #subTbl do
		if i == 6 then break end; --Display top 5 results
		mapName = subTbl[i]["map"];
		if mapName ~= nil and mapName ~= mapHeader then
			table.insert(dropListDisplay, string.format("%s", mapName))		
		end
		
		local dropRate = subTbl[i]["chnc"]/100;
		if dropRate ~= 0 then
			local template = string.format("    %s: %.2f%%", subTbl[i]["name"], dropRate);
			table.insert(dropListDisplay, template)
		end
	end
	
	if #dropListDisplay == 0 then
		text = ""
	else
		text = text .. table.concat(dropListDisplay, "{nl}")
	end

	return util.toIMCTemplate(text)
end

function ITEM_LEVEL(invItem)
	if invItem.ItemType ~= "Equip" then
	    return ""
end

	if invItem.ItemStar > 0 then
		return util.toIMCTemplate(invItem.ItemStar .. util.addIcon("", "star_mark"), acutil.getItemRarityColor(invItem))
    end
end

function TP_MEDAL_EXCHANGE(invItem)
	local cachedMedalItems = TooltipHelper.indexTbl["Premium"]
	if cachedMedalItems == nil then
		cache.tpItems();
	end
	
	local subTbl = cachedMedalItems[invItem.ClassName];
	if subTbl == nil then return ""	end
	
	local clsList, cnt = GetClassList("recycle_shop");
	for i = 1, #subTbl do
		if invItem.ClassName == subTbl[i]["name"] then
			return util.toIMCTemplate("TP Medal Exchange: ")..util.addIcon(util.toIMCTemplate(subTbl[i]["sellPrice"], acutil.getItemRarityColor(invItem)), 'icon_item_recyclemedal')
		end
	end
end

function REIDENTIFICATION(invItem)
	local itemCls = GetClassByType('Item', invItem.ClassID)
    if invItem.ItemType ~= "Equip" 
    or itemCls.NeedRandomOption ~= 1
    or IS_NEED_APPRAISED_ITEM(invItem) == true 
    or IS_NEED_RANDOM_OPTION_ITEM(invItem) == true then
	    return ""
	end
	
	local itemRandomResetMaterial = nil;
	local list, cnt = GetClassList("item_random_reset_material")
	
	if list == nil then
		return;
	end
					
	for i = 0, cnt - 1 do
		local cls = GetClassByIndexFromList(list, i);
		if cls == nil then
			return;
		end

		if invItem.ClassType == cls.ItemType and invItem.ItemGrade == cls.ItemGrade then
			itemRandomResetMaterial = cls
		end
	end

	if itemRandomResetMaterial == nil then
		return;
	end
	
    local reIdentification = util.toIMCTemplate("Re-identify: ")
	
	local materialItemSlot = itemRandomResetMaterial.MaterialItemSlot;
	for i = 1, materialItemSlot do
		local materialItemIndex = "MaterialItem_" ..i
		local materialItemCount = 0
		local materialItemCls = itemRandomResetMaterial[materialItemIndex]
		local materialItem = GetClass("Item", materialItemCls)
		local materialCountScp = itemRandomResetMaterial[materialItemIndex .."_SCP"]
		
		if materialCountScp == "None" then return end
		
		materialCountScp = _G[materialCountScp];
		materialItemCount = materialCountScp(invItem);
		reIdentification = reIdentification .. " " .. util.toIMCTemplate(util.addIcon(materialItemCount, materialItem.Icon), acutil.getItemRarityColor(materialItem))
	end
	
    return reIdentification
end

function AWAKENING(invItem)
	if invItem.ItemType ~= "Equip" or invItem.EqpType == "WING" or invItem.EqpType == "SPECIALCOSTUME" then return "" end
	
	local needItem, needCount = GET_ITEM_AWAKENING_PRICE(invItem)
	local itemCls = GetClass('Item', needItem);
	
	if needCount == 0 then return "" end 
	
	local awakening = util.toIMCTemplate("Awakening Costs: ") .. util.toIMCTemplate(util.addIcon(needCount,itemCls.Icon),util.commonColor) 
	return awakening
end

function NPC_SELL_PRICE(invItem)

	local itemProp = geItemTable.GetPropByName(invItem.ClassName);
    if itemProp ~= nil and itemProp:IsEnableShopTrade() == false then return "" end
	
	local sellPrice = geItemTable.GetSellPrice(itemProp)
	if not (sellPrice > 0) then return "" end
	return util.toIMCTemplate("NPC Sell Price: ") .. util.toIMCTemplate(util.addIcon(tostring(sellPrice), 'icon_item_silver'), util.commonColor)
end

function TRANSCENDENCE(invItem)
	if invItem.ItemType ~= "Equip"
	or IS_TRANSCEND_ABLE_ITEM(invItem) == 0
	or IS_NEED_APPRAISED_ITEM(invItem) == true 
	or IS_NEED_RANDOM_OPTION_ITEM(invItem) == true then
	    return ""
	end
	
	local text = util.toIMCTemplate(util.addIcon(GET_TRANSCEND_MAXCOUNT(invItem), "icon_item_transcendence_Stone") .. " to upgrade", util.commonColor)
	
	if IS_TRANSCEND_ITEM(invItem) == 1 then
		text = text .. util.toIMCTemplate(" / " .. util.addIcon(tostring(GET_TRANSCEND_BREAK_ITEM_COUNT(invItem) * 10) .. " extracted", "icon_item_gem_elemental1"), util.commonColor); 
	end
	
	return util.toIMCTemplate("Transcendence: ") .. text
end

function CUBE_REROLL_PRICE(invItem)
	if invItem.GroupName ~= "Cube" then return end
	
	local rerollPrice = TryGet(invItem, "NumberArg1")
	if rerollPrice > 0 then
		return util.addIcon("", invItem.Icon) .. util.toIMCTemplate("Reroll Price: " .. GetCommaedText(rerollPrice), acutil.getItemRarityColor(invItem))
	end
end

function MAKE_TTH_INV_ITEM_DATA(invItem)
	local buffer = {};
	local labels = {}

    local text = "";
    
    --NPC Sell Price
    util.renderLabel(NPC_SELL_PRICE, true, invItem, labels);
    
    --Reroll Price
    util.render(CUBE_REROLL_PRICE, TooltipHelper.config.showRerollPrice, buffer, invItem, text);
    
    --Journal stats
    util.renderLabel(JOURNAL_STATS, TooltipHelper.config.showJournalStats, invItem, labels);
    
    --Transcendence
    util.renderLabel(TRANSCENDENCE, TooltipHelper.config.showTranscendence, invItem, labels);
    
    --Re-identification
	util.renderLabel(REIDENTIFICATION, TooltipHelper.config.showIdentification, invItem, labels);
	
	--TP Exchange
	util.renderLabel(TP_MEDAL_EXCHANGE, TooltipHelper.config.showMedalExchange, invItem, labels);
	
	--Awakening
	util.renderLabel(AWAKENING, TooltipHelper.config.showAwakening, invItem, labels)
	
    local headText = table.concat(labels,"{nl}")
    
    table.insert(buffer,headText);
    
    --Collection
    util.render(COLLECTION_SECTION, TooltipHelper.config.showCollections, buffer, invItem, text)
      
    --Recipe
    util.render(RECIPE_SECTION, TooltipHelper.config.showRecipes, buffer, invItem, text)
   
    local rightText = ""
    local rightBuffer = {}
    
    --Magnum Opus
    util.render(MAGNUM_OPUS_SECTION, TooltipHelper.config.showMagnumOpus, rightBuffer, invItem, rightText)
    
	--Item Drop
	util.render(ITEM_DROP_SECTION, TooltipHelper.config.showItemDrops, rightBuffer, invItem, rightText);

    if #buffer == 1 and invItem.ItemType == "Equip" then
        text = headText
    else
        text = table.concat(buffer,"{nl}")
        rightText = table.concat(rightBuffer,"{nl}")
    end
        
    buffer = {}
    rightBuffer = {}
    
	return text, rightText
end

function TOOLTIPHELPER_INIT()
	if not TooltipHelper.isLoaded then
		if TooltipHelper.indexTbl["Drops"] == nil then
			cache.dropList();
		end
		
		if TooltipHelper.indexTbl["Collection"] == nil then
			cache.collectionList();
		end
		
		if TooltipHelper.indexTbl["Recipe"] == nil then
			cache.recipeList()
		end
		
		if TooltipHelper.indexTbl["Premium"] == nil then
			cache.tpItems();
		end
		
		TooltipHelper.magnumOpusRecipes = cache.loadMagnumOpus() or TooltipHelper.magnumOpusRecipes
		
		acutil.setupHook(DRAW_SELL_PRICE_HOOKED, "DRAW_SELL_PRICE");
		acutil.setupHook(GET_USEJOB_TOOLTIP_HOOKED, "GET_USEJOB_TOOLTIP");
		acutil.setupHook(DRAW_AVAILABLE_PROPERTY_HOOKED, "DRAW_AVAILABLE_PROPERTY")
		acutil.setupHook(DRAW_EQUIP_PR_N_DUR_HOOKED, "DRAW_EQUIP_PR_N_DUR")
		acutil.setupHook(DRAW_EQUIP_ONLY_PR_HOOKED, "DRAW_EQUIP_ONLY_PR")

		acutil.setupHook(DRAW_ITEM_TYPE_N_WEIGHT_HOOKED, "DRAW_ITEM_TYPE_N_WEIGHT");
		acutil.setupHook(DRAW_EQUIP_COMMON_TOOLTIP_HOOKED, "DRAW_EQUIP_COMMON_TOOLTIP");
		acutil.setupHook(DRAW_EQUIP_ATK_N_DEF_HOOKED, "DRAW_EQUIP_ATK_N_DEF");
		
		acutil.setupHook(ITEM_TOOLTIP_ETC_HOOKED, "ITEM_TOOLTIP_ETC");
		acutil.setupHook(ITEM_TOOLTIP_BOSSCARD_HOOKED, "ITEM_TOOLTIP_BOSSCARD");
		acutil.setupHook(ITEM_TOOLTIP_GEM_HOOKED, "ITEM_TOOLTIP_GEM");
		acutil.setupHook(ITEM_TOOLTIP_EQUIP_HOOKED, "ITEM_TOOLTIP_EQUIP");
		
		TooltipHelper.isLoaded = true
		acutil.log("Tooltip helper loaded!")
	end
end
