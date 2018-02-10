local acutil = require('acutil');

_G['ADDONS'] = _G['ADDONS'] or {};
TooltipHelper = _G["ADDONS"]["TOOLTIPHELPER"] or {};

TooltipHelper.configFile = '../addons/tooltiphelper/tooltiphelper.json'
TooltipHelper.recipeFile = "../addons/tooltiphelper/recipe_puzzle.xml";

TooltipHelper.config = {
    showCollectionCustomTooltips = true,
    showCompletedCollections	 = true,
    showRecipeCustomTooltips	 = true,
    showRecipeHaveNeedCount		 = true,
    showTranscendence			 = true,
    showIdentification			 = true,
    showMagnumOpus				 = true,
    showJournalStats			 = true,
	showItemDrop				 = true
}

TooltipHelper.config = (
	function ()
		local file, err = acutil.loadJSON(TooltipHelper.configFile, TooltipHelper.config);
		if err then 
		    acutil.saveJSON(TooltipHelper.configFile, TooltipHelper.config);
		else 
		    TooltipHelper.config = file; 
		end
		
		return TooltipHelper.config
	end
)()

TooltipHelper.indexTbl = {};

local function MAGNUM_OPUS_RECIPE_LOADER()
	local status, xml = pcall(require, "xmlSimple");
	if not status then
		acutil.log("Unable to load xmlSimple")
		return
	end

	local recipeXml = xml.newParser():loadFile(TooltipHelper.recipeFile);

	if recipeXml == nil then
		acutil.log("Magnum Opus recipe file not found");
		return
	end
	
	TooltipHelper.magnumOpusRecipes = {};
	local recipes = recipeXml["Recipe_Puzzle"]:children();

	for i=1,#recipes do
		local recipe = recipes[i];
		local targetItemClassName = recipe["@TargetItem"];
		local ingredients = recipe:children();
		TooltipHelper.magnumOpusRecipes[targetItemClassName] = {};
		for j=1,#ingredients do
			local ingredient = ingredients[j];
			local ingredientItemClassName = ingredient["@Name"];
			local row = ingredient["@Row"];
			local column = ingredient["@Col"];
			table.insert(TooltipHelper.magnumOpusRecipes[targetItemClassName], {name = ingredientItemClassName,
			                                                                    row = tonumber(row),
			                                                                    col = tonumber(column)});
		end
	end
end

if not TooltipHelper.magnumOpusRecipes then
	MAGNUM_OPUS_RECIPE_LOADER();
end

function TOOLTIPHELPER_ON_INIT(addon, frame)
	TooltipHelper.addon = addon;
	TooltipHelper.frame = frame;
	
	TOOLTIPHELPER_INIT();
end

local function contains(table, val)
    for k, v in ipairs(table) do
        if v == val then
            return true
        end
    end
    return false
end

local function compare(a, b)
    if a.grade < b.grade then
        return true
    elseif a.grade > b.grade then
        return false
    else
        return a.resultItemName < b.resultItemName
    end
end

local labelColor = "9D8C70"
local completeColor = "00FF00"
local commonColor = "FFFFFF"
local npcColor = "FF4040"
local squireColor = "40FF40"
local unregisteredColor = "7B7B7B"
local collectionIcon = "icon_item_box"
local starIcon = "star_mark"

local function toIMCTemplate(text, colorHex)
	if colorHex == nil then colorHex = labelColor end;
    return "{ol}{ds}{#" .. colorHex .. "}".. text .. "{/}{/}{/}"    
end

local function addIcon(text, iconName)
	return "{img " .. iconName .. " 24 24}" .. text .. "{/}"
end

local function manuallyCount(cls, invItem)
    local count = 0;
    for i = 1 , 9 do
        local item = GetClass("Item", cls["ItemName_" .. i]);
            
        if item == "None" or item == nil then
            break;
        end
                
        if item.ClassName == invItem.ClassName then
            count = count + 1;
        end
    end
    return count;
end

local function TOOLTIPHELPER_BUILD_COLLECTION_LIST()
	TooltipHelper.indexTbl["Collection"] = {};
	local typeTbl = TooltipHelper.indexTbl["Collection"];
	local clsList, cnt = GetClassList("Collection");
	for i = 0 , cnt - 1 do
		local cls = GetClassByIndexFromList(clsList, i);
		local countingTbl = {};
		local j = 0;
		while true do
			j = j + 1;
			local itemName = TryGetProp(cls,"ItemName_" .. j);

			if itemName == nil or itemName == "None" then
				break
			end

			if typeTbl[itemName] == nil then
				typeTbl[itemName] = {};
			end

			if not contains(countingTbl, itemName) then
				table.insert(countingTbl, itemName);
				table.insert(typeTbl[itemName], {idx = i});
			end
		end
	end
end

local function TOOLTIPHELPER_BUILD_RECIPE_LIST()
	TooltipHelper.indexTbl["Recipe"] = {types = {"Recipe", "Recipe_ItemCraft", "ItemTradeShop"}};
	local typeTbl = TooltipHelper.indexTbl["Recipe"];
	for _, classType in ipairs(typeTbl["types"]) do
		local clsList, cnt = GetClassList(classType);
		for i = 0 , cnt - 1 do
			local cls = GetClassByIndexFromList(clsList, i);
			local resultItem = GetClass("Item", cls.TargetItem);
			if resultItem ~= nil and resultItem.NotExist ~= 'YES' and resultItem.ItemType ~= 'Unused' then
				local countingTbl = {};
				for j = 1, 5 do
					local item = GetClass("Item", cls["Item_" .. j .. "_1"]);

					if item == "None" or item == nil or item.NotExist == 'YES' or item.ItemType == 'Unused' or item.GroupName == 'Unused' then
						break;
					end

					local itemName = item.ClassName;

					if typeTbl[itemName] == nil then
						typeTbl[itemName] = {};
					end

					if not contains(countingTbl, itemName) then
						local grade = resultItem.ItemGrade;
						if grade == 'None' or grade == nil then
							grade = 0;
						end
						table.insert(countingTbl, itemName);
						table.insert(typeTbl[itemName], {idx = i,
						                                 pos = j,
						                                 grade = grade,
						                                 classType = classType,
						                                 resultItemName = dictionary.ReplaceDicIDInCompStr(resultItem.Name)
						                                 });
					end
				end
			end
		end
	end
	for k, t in pairs(typeTbl) do
		if k ~= "types" then
			table.sort(t, compare);
		end
	end
end

local function TOOLTIPHELPER_BUILD_DROP_LIST()
	local function chanceCompare(a, b)
		if a.chnc ~= b.chnc then
			return a.chnc > b.chnc
		else
			return a.name < b.name
		end
	end

	TooltipHelper.indexTbl["Drops"] = {};
	local typeTbl = TooltipHelper.indexTbl["Drops"];
	local clsList, cnt = GetClassList("Monster");
	for i = 0 , cnt - 1 do
		local cls = GetClassByIndexFromList(clsList, i);
		if cls.GroupName ~= "Item" then
			local dropID = cls.DropItemList;
			if dropID ~= nil and dropID ~= "None" then
				dropID = "MonsterDropItemList_" .. dropID;
				local monName = dictionary.ReplaceDicIDInCompStr(cls.Name);
				for j = 0, GetClassCount(dropID) - 1 do
					local dropIES = GetClassByIndex(dropID, j)
					local itemName = dropIES.ItemClassName;
					local chnc = dropIES.DropRatio;
					local newMob = true;

					if typeTbl[itemName] == nil then
						typeTbl[itemName] = {};
					end

					for k = 1, #typeTbl[itemName] do
						if typeTbl[itemName][k]["name"] == monName and typeTbl[itemName][k]["chnc"] == chnc then
							newMob = false;
							break
						end
					end

					if newMob then
						table.insert(typeTbl[itemName], {name = monName, chnc = chnc})
					end
				end
			end
		end
	end
	for _, t in pairs(typeTbl) do
		table.sort(t, chanceCompare);
	end
end

function ITEM_TOOLTIP_BOSSCARD_HOOKED(tooltipFrame, invItem, strArg)
    _G["ITEM_TOOLTIP_BOSSCARD_OLD"](tooltipFrame, invItem, strArg);
    
    local mainFrameName = 'bosscard'
    
    return _CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg);
end

function ITEM_TOOLTIP_EQUIP_HOOKED(tooltipFrame, invItem, strArg, useSubFrame)
    _G["ITEM_TOOLTIP_EQUIP_OLD"](tooltipFrame, invItem, strArg, useSubFrame);
    
    local mainFrameName = 'equip_main'
    
    if useSubFrame == "usesubframe" or useSubFrame == "usesubframe_recipe" then 
        mainFrameName = 'equip_sub'
    end
    
    return _CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame);
end

function ITEM_TOOLTIP_ETC_HOOKED(tooltipFrame, invItem, strArg, useSubFrame)
    _G["ITEM_TOOLTIP_ETC_OLD"](tooltipFrame, invItem, strArg, useSubFrame);
    
    local mainFrameName = 'etc'
    
    if useSubFrame == "usesubframe" or useSubFrame == "usesubframe_recipe" then
        mainFrameName = "etc_sub"
    end
    
    return _CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame);  
end

function ITEM_TOOLTIP_GEM_HOOKED(tooltipFrame, invItem, strArg)
    _G["ITEM_TOOLTIP_GEM_OLD"](tooltipFrame, invItem, strArg);
    
    local mainFrameName = 'gem'
    
    return _CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg);
end

function _CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame)
	if useSubFrame == nil then useSubFrame = "" end
		
	if marktioneerex ~= nil then
		CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame);
		return marktioneerex.addMarketPrice(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame);
    else
 	    return CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame);  
    end
end

function JOURNAL_STATS(invItem)
	local text = ""
	local color = labelColor;
	if invItem.Journal then
		local curScore, maxScore, curLv, curPoint, maxPoint = 0, 0, 0, 0, 0;
		local itemObtainCount = GetItemObtainCount(GetMyPCObject(), invItem.ClassID);
		curScore, maxScore = _GET_ADVENTURE_BOOK_POINT_ITEM(invItem.ItemType == 'Equip', itemObtainCount);
		curLv, curPoint, maxPoint = GET_ADVENTURE_BOOK_ITEM_OBTAIN_COUNT_INFO(invItem.ItemType == 'Equip', itemObtainCount);
		
		if curScore == 0 then
			text = "Not registered!{nl}"			
			color = labelColor;
		elseif curScore == maxScore then
			text = "Max Points Acquired!{nl}";
			color = completeColor;
		else
			text = "Journal Points Acquired: (" .. curScore .. "/" .. maxScore .. "){nl}";
			text = text .. "Progress for Max Points: (" .. curPoint .. "/" .. maxPoint .. "){nl}";
			color = commonColor;
		end 
	end
    return toIMCTemplate(text, color)
end

function COLLECTION_SECTION(invItem)
	if TooltipHelper.indexTbl["Collection"] == nil then
		TOOLTIPHELPER_BUILD_COLLECTION_LIST();
	end

	local subTbl = TooltipHelper.indexTbl["Collection"][invItem.ClassName];
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
		local neededCount = manuallyCount(cls, item);
		local collCount = 0;
		local collName = string.gsub(dictionary.ReplaceDicIDInCompStr(cls.Name), "Collection: ", "")

		if hasRegisteredCollection then
			local info = geCollectionTable.Get(cls.ClassID);
			collCount = coll:GetItemCountByType(item.ClassID);
			neededCount = info:GetNeedItemCount(item.ClassID);
		end

		text = addIcon(collName .. " " .. collCount .. "/" .. neededCount .. " ", collectionIcon)

		if isCompleted then
			if TooltipHelper.config.showCompletedCollections then
				text = toIMCTemplate(text, completeColor)
			else 
				text = ""
			end
		elseif hasRegisteredCollection then
			text = toIMCTemplate(text, commonColor)
		else
			text = toIMCTemplate(text, unregisteredColor)
		end

		if not contains(partOfCollections, text) then
			table.insert(partOfCollections, text);
		end
	end

	return table.concat(partOfCollections,"{nl}")
end

function RECIPE_SECTION(invItem)
	if TooltipHelper.indexTbl["Recipe"] == nil then
		TOOLTIPHELPER_BUILD_RECIPE_LIST()
	end

	local subTbl = TooltipHelper.indexTbl["Recipe"][invItem.ClassName];
	if subTbl == nil then
		return ""
	end

	local partOfRecipe = {};
	local superClsList = {};

	for _, classType in ipairs(TooltipHelper.indexTbl["Recipe"]["types"]) do
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
		local color = commonColor;

		if TooltipHelper.config.showRecipeHaveNeedCount then
			materialCountText = haveCount .. "/" .. needCount;
			local color = unregisteredColor;
			if not isRegistered then
				color = unregisteredColor;
			elseif (invItem.ItemType ~= "Recipe") and (haveCount >= needCount) then
				color = completeColor;
			end
			materialCountText = toIMCTemplate(materialCountText, color)
		end

		itemName = addIcon(itemName, recipeIcon);
		text = toIMCTemplate(itemName, acutil.getItemRarityColor(resultItem))

		if isCrafted then
			text = text .. addIcon("", resultItem.Icon)
		elseif not isRegistered then
			text = toIMCTemplate(itemName, unregisteredColor)
		end

		text = text .. " " .. materialCountText

		if marktioneerex ~= nil then
			local recipeData = marktioneerex.getMinimumData(recipeClassID);
			local newLine = "{nl}    ";
			if (recipeData) then 
				text = text .. newLine .. addIcon("", recipeIcon) .. " ".. toIMCTemplate(GetCommaedText(recipeData.price), labelColor);
			end
			local resultItemData = marktioneerex.getMinimumData(resultItem.ClassID);
			if (resultItemData) then 
				local resultPrice = " " .. addIcon("", resultItem.Icon) .. " ".. toIMCTemplate(GetCommaedText(resultItemData.price), labelColor);
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
				text = toIMCTemplate(quantity .. "x" .. addIcon(itemName, item.Icon), labelColor) .. newLine
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
		text = toIMCTemplate("Transmuted From:{nl} ", labelColor) .. text
	end
	
	return text;
end

function MAGNUM_OPUS_TRANSMUTES_INTO(invItem)
	local text = ""
	
	local targetItems = {}
	local invItemClassName = invItem.ClassName
	
	for k, v in pairs(TooltipHelper.magnumOpusRecipes) do
		local targetItemClassName = k;
		local items = v
		
		for i = 1, #items do
			local itemClass = items[i]["name"]
			
			if itemClass == invItemClassName then
				if targetItems[targetItemClassName] == nil then
					targetItems[targetItemClassName] = 1
				else
					local oldVal = targetItems[targetItemClassName]
					targetItems[targetItemClassName] = oldVal + 1
				end
			end
		end
	end
	
	
	for k, v in pairs(targetItems) do
		local className = k
		local qty = v
		local result = GetClass("Item", className)
		local itemName = dictionary.ReplaceDicIDInCompStr(result.Name)
		text = text .. toIMCTemplate("  " .. qty .. "x", labelColor) 
					.. toIMCTemplate(addIcon("= 1 ", invItem.Icon), labelColor) 
					.. toIMCTemplate(addIcon(itemName, result.Icon) .. "{nl}", labelColor)
	end
	
	if text ~= "" then
		text = toIMCTemplate("Magnum Opus{nl} Transmutes Into:{nl}", labelColor) .. text .. "{nl}";
	end
	
	return text;
end

function MAGNUM_OPUS_SECTION(invItem)
	local transmuteInto = MAGNUM_OPUS_TRANSMUTES_INTO(invItem);
	local transmuteFrom = MAGNUM_OPUS_TRANSMUTED_FROM(invItem);
	return transmuteInto .. transmuteFrom; 
end

function ITEM_DROP_SECTION(invItem)
	if TooltipHelper.indexTbl["Drops"] == nil then
		TOOLTIPHELPER_BUILD_DROP_LIST();
	end

	local subTbl = TooltipHelper.indexTbl["Drops"][invItem.ClassName];
	if subTbl == nil then
		return ""
	end

	local text = "Drops From:";
	for i = 1, #subTbl do
		local dropRate = subTbl[i]["chnc"]/100;
		if dropRate ~= 0 then
			text = text .. string.format("{nl}%s: %.2f%%", subTbl[i]["name"], dropRate);
		end
	end

	return toIMCTemplate(text, labelColor)
end

function ITEM_LEVEL(invItem)
	if invItem.ItemType ~= "Equip" then
	    return ""
end

	if invItem.ItemStar > 0 then
		return toIMCTemplate(invItem.ItemStar .. addIcon("", "star_mark"), acutil.getItemRarityColor(invItem))
    end
end

function REIDENTIFICATION(invItem)
    if invItem.ItemType ~= "Equip" then
	    return ""
	end
	
	local itemCls = GetClassByType('Item', invItem.ClassID)

	if itemCls.NeedRandomOption ~= 1 then
		return "";
	end

	if IS_NEED_APPRAISED_ITEM(invItem) == true or IS_NEED_RANDOM_OPTION_ITEM(invItem) == true then 
		return "";
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
	
    local reIdentification = toIMCTemplate("Re-identify: ", labelColor)
	
	local materialItemSlot = itemRandomResetMaterial.MaterialItemSlot;
	for i = 1, materialItemSlot do
		local materialItemIndex = "MaterialItem_" ..i
		local materialItemCount = 0
		local materialItemCls = itemRandomResetMaterial[materialItemIndex]
		local materialItem = GetClass("Item", materialItemCls)
		local materialCountScp = itemRandomResetMaterial[materialItemIndex .."_SCP"]
		if materialCountScp ~= "None" then
			materialCountScp = _G[materialCountScp];
			materialItemCount = materialCountScp(invItem);
			reIdentification = reIdentification .. " " .. toIMCTemplate(addIcon(materialItemCount, materialItem.Icon), acutil.getItemRarityColor(materialItem))
		else
			return
		end
	end
	
    return "{nl}" .. reIdentification
end

function TRANSCENDENCE(invItem)
	if invItem.ItemType ~= "Equip" then
	    return ""
	end
	
	if IS_TRANSCEND_ABLE_ITEM(invItem) == 0 then
	    return ""
	end
	
	if IS_NEED_APPRAISED_ITEM(invItem) == true or IS_NEED_RANDOM_OPTION_ITEM(invItem) == true then
		return ""
	end
	
	local text = toIMCTemplate("Upgrade: ") .. toIMCTemplate(GET_TRANSCEND_MAXCOUNT(invItem), commonColor) .. addIcon("", "icon_item_transcendence_Stone")
	
	if IS_TRANSCEND_ITEM(invItem) == 1 then
		text = text .. " " .. toIMCTemplate("Extract: ") .. toIMCTemplate(tostring(GET_TRANSCEND_BREAK_ITEM_COUNT(invItem) * 10), commonColor) .. addIcon("", "icon_item_gem_elemental1"); 
	end
	
	return "{nl}" .. toIMCTemplate("Transcendence - ") .. text
end

function CUBE_REROLL_PRICE(invItem)
	if invItem.GroupName == "Cube" then
		local rerollPrice = TryGet(invItem, "NumberArg1")
		if rerollPrice > 0 then
			return addIcon("", invItem.Icon) .. toIMCTemplate("Reroll Price: " .. GetCommaedText(rerollPrice), acutil.getItemRarityColor(invItem))
		end
	end
end

function CUSTOM_TOOLTIP_PROPS(tooltipFrame, mainFrameName, invItem, strArg, useSubFrame)
	local function render(fn, config, buffer, invItem, text)
		if config and fn ~= nil then
			text = fn(invItem);
			if text ~= "" then
				table.insert(buffer,text);
			end
		end
	end
	
	local function renderLabel(fn, config, invItem)
		if config and fn ~= nil then
			return fn(invItem) or "";
		end
	end

    local gBox = GET_CHILD(tooltipFrame, mainFrameName,'ui::CGroupBox');
    
    local yPos = gBox:GetY() + gBox:GetHeight();
    
    local leftTextCtrl = gBox:CreateOrGetControl("richtext", 'text', 0, yPos, 410, 30);
    tolua.cast(leftTextCtrl, "ui::CRichText");
    
	local main_addinfo = tooltipFrame:GetChild("equip_main_addinfo");
	main_addinfo:SetOffset(main_addinfo:GetX(),tooltipFrame:GetHeight()/2);
	local sub_addinfo = tooltipFrame:GetChild("equip_sub_addinfo");
	sub_addinfo:SetOffset(sub_addinfo:GetX(),tooltipFrame:GetHeight()/2);

    local buffer = {};
    local text = "";
    
    --Reroll Price
    render(CUBE_REROLL_PRICE, true, buffer, invItem, text);
    
    --Journal stats
    local journalStatsLabel = renderLabel(JOURNAL_STATS, TooltipHelper.config.showJournalStats, invItem);
    
    --Transcendence
    local transcendLabel = renderLabel(TRANSCENDENCE, TooltipHelper.config.showTranscendence, invItem);
    
    --Re-identification
	local reIdentificationLabel = renderLabel(REIDENTIFICATION, TooltipHelper.config.showIdentification, invItem);
	
    local headText = journalStatsLabel .. itemLevelLabel .. repairRecommendationLabel .. transcendLabel .. reIdentificationLabel;
    
    table.insert(buffer,headText);
    
    --Collection
    render(COLLECTION_SECTION, TooltipHelper.config.showCollectionCustomTooltips, buffer, invItem, text)
      
    --Recipe
    render(RECIPE_SECTION, TooltipHelper.config.showRecipeCustomTooltips, buffer, invItem, text)
   
    local rightText = ""
    local rightBuffer = {}
    --Magnum Opus
    render(MAGNUM_OPUS_SECTION, TooltipHelper.config.showMagnumOpus, rightBuffer, invItem, rightText)
    
	--Item Drop
	render(ITEM_DROP_SECTION, TooltipHelper.config.showItemDrop, rightBuffer, invItem, rightText);

    if #buffer == 1 and invItem.ItemType == "Equip" then
        text = headText
    else
        text = table.concat(buffer,"{nl}")
        rightText = table.concat(rightBuffer,"{nl}")
    end
        
    leftTextCtrl:SetText(text);
	leftTextCtrl:SetMargin(20,gBox:GetHeight(),0,0);
    leftTextCtrl:SetGravity(ui.LEFT, ui.TOP)
    
    if rightText ~= "" then
    	local rightTextCtrl = gBox:CreateOrGetControl("richtext", 'text2', math.max(leftTextCtrl:GetWidth()+30,200), yPos, 410, 30);
	    tolua.cast(rightTextCtrl, "ui::CRichText");
	    rightTextCtrl:SetText(rightText)
		--rightTextCtrl:SetMargin(0, gBox:GetHeight(),20,0)
	    --rightTextCtrl:SetGravity(ui.RIGHT, ui.TOP)
	    
    	local width = leftTextCtrl:GetWidth() + rightTextCtrl:GetWidth() + 50;
		width = math.max(width, gBox:GetWidth());
	    if leftTextCtrl:GetHeight() > rightTextCtrl:GetHeight() then
			gBox:Resize(width, gBox:GetHeight() + leftTextCtrl:GetHeight() + 10)
	    else 
			gBox:Resize(width, gBox:GetHeight() + rightTextCtrl:GetHeight() + 10)
	    end
	    
	    local etcCommonTooltip = GET_CHILD(gBox, 'tooltip_etc_common');
	    if etcCommonTooltip ~= nil then
		    etcCommonTooltip:Resize(width, etcCommonTooltip:GetHeight())
	    end
	    
    	local etcDescTooltip = GET_CHILD(gBox, 'tooltip_etc_desc');
		if etcDescTooltip ~= nil then
		    etcDescTooltip:Resize(width, etcDescTooltip:GetHeight())
	    end	
		if string.sub(mainFrameName, #mainFrameName - 3) == "_sub" then
			local widthdif = gBox:GetWidth() - gBox:GetOriginalWidth();
			gBox:SetOffset(gBox:GetX() - widthdif, gBox:GetY());
		end
    else
	    gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + leftTextCtrl:GetHeight() + 10)
    end
    
    buffer = {}
    text = ""
    return leftTextCtrl:GetHeight() + leftTextCtrl:GetY();
end

function TOOLTIPHELPER_INIT()
	if not TooltipHelper.isLoaded then
		TOOLTIPHELPER_BUILD_COLLECTION_LIST();
		TOOLTIPHELPER_BUILD_RECIPE_LIST();
		TOOLTIPHELPER_BUILD_DROP_LIST();
		acutil.setupHook(ITEM_TOOLTIP_EQUIP_HOOKED, "ITEM_TOOLTIP_EQUIP");
		acutil.setupHook(ITEM_TOOLTIP_ETC_HOOKED, "ITEM_TOOLTIP_ETC");
		acutil.setupHook(ITEM_TOOLTIP_BOSSCARD_HOOKED, "ITEM_TOOLTIP_BOSSCARD");
		acutil.setupHook(ITEM_TOOLTIP_GEM_HOOKED, "ITEM_TOOLTIP_GEM");
		
		TooltipHelper.isLoaded = true
		
		acutil.log("Tooltip helper loaded!")
	end
end
