local acutil = require('acutil');
local tthUtil = dofile('../addons/devloader/tooltiphelper_util.lua');
local tthDefaultMO = dofile('../addons/devloader/tooltiphelper_magnumopus.lua');

if not TooltipHelper then
	TooltipHelper = _G["ADDONS"]["TOOLTIPHELPER"] or {}
	TooltipHelper.indexTbl = {}
end

local tooltiphelper_cache = {
	configureData = function(filePath, dataTable, latestVersion, fnArg)
		local file, err = acutil.loadJSON(filePath, dataTable);
		if fnArg == nil and (err or (not file.version or (file.version ~= latestVersion))) then
			acutil.saveJSON(filePath, dataTable);
		elseif err then
			dataTable = fnArg()			
			acutil.saveJSON(filePath, dataTable);
		else
		    dataTable = file; 
		end
		
		return dataTable
	end,
	
	loadMagnumOpus = function ()
		local status, xml = pcall(require, "xmlSimple");
		local magnumOpusRecipes = {}
		if not status then
			acutil.log("Unable to load xmlSimple, using default recipes")
			return tthDefaultMO
		end
		
		local magnumOpusXML = "../addons/tooltiphelper/recipe_puzzle.xml";
		local recipeXml = xml.newParser():loadFile(magnumOpusXML);
		
		if recipeXml == nil then
			acutil.log("Magnum Opus recipe file not found, using default recipes");
			return tthDefaultMO
		end
		
		local recipes = recipeXml["Recipe_Puzzle"]:children();
	
		for i=1,#recipes do
			local recipe = recipes[i];
			local targetItemClassName = recipe["@TargetItem"];
			local ingredients = recipe:children();
			magnumOpusRecipes[targetItemClassName] = {};
			for j=1,#ingredients do
				local ingredient = ingredients[j];
				local ingredientItemClassName = ingredient["@Name"];
				local row = ingredient["@Row"];
				local column = ingredient["@Col"];
				table.insert(magnumOpusRecipes[targetItemClassName], {name = ingredientItemClassName,
				                                                                    row = tonumber(row),
				                                                                    col = tonumber(column)});
			end
		end
		return magnumOpusRecipes
	end,
	
	recipeList = function()
		TooltipHelper.indexTbl["Recipe"] = {types = {"Recipe", "Recipe_ItemCraft", "ItemTradeShop"}};
		local typeTbl = TooltipHelper.indexTbl["Recipe"];
		
		for _, classType in ipairs(typeTbl["types"]) do
			local clsList, cnt = GetClassList(classType);
			for i = 0 , cnt - 1 do repeat 
				local cls = GetClassByIndexFromList(clsList, i);
				local resultItem = GetClass("Item", cls.TargetItem);
				if resultItem == nil or resultItem.NotExist == 'YES' or resultItem.ItemType == 'Unused' then
					break;
				end
				
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

					if tthUtil.contains(countingTbl, itemName) then break end

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
			until true end
		end
		for k, t in pairs(typeTbl) do repeat
			if k == "types" then break end;
			table.sort(t, tthUtil.compare);
		until true end
	end,
	
	dropList = function()
		TooltipHelper.indexTbl["Drops"] = {};
		local typeTbl = TooltipHelper.indexTbl["Drops"];
		local clsList, cnt = GetClassList("Monster");
		for i = 0 , cnt - 1 do repeat
			local cls = GetClassByIndexFromList(clsList, i);
			local monClassID = cls.ClassID
			if cls.GroupName == "Item" then break end
			
			local dropID = cls.DropItemList;
			if dropID == nil or dropID == "None" then break end
			
			dropID = "MonsterDropItemList_" .. dropID;
			local monName = dictionary.ReplaceDicIDInCompStr(cls.Name);
			for j = 0, GetClassCount(dropID) - 1 do repeat
				local dropIES = GetClassByIndex(dropID, j)
				local itemName = dropIES.ItemClassName;
				local chnc = dropIES.DropRatio;
				local mapName = ""
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
				
				if not newMob then break end
				
				local monGenMapIDList = GetMonGenTypeList(monClassID);
				if #monGenMapIDList == nil and #monGenMapIDList == 0 then break end
				
				for i=1, #monGenMapIDList do repeat 
					local mapCls = GetClassByType('Map', monGenMapIDList[i]);
					if mapCls.Name == nil then break end
					mapName = dictionary.ReplaceDicIDInCompStr(mapCls.Name)
				until true end
				table.insert(typeTbl[itemName], {name = monName, chnc = chnc, map = mapName})
			until true end
		until true end
		for _, t in pairs(typeTbl) do
			table.sort(t, tthUtil.chanceCompare);
		end
	end,
	
	collectionList = function()
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
	
				if tthUtil.contains(countingTbl, itemName) then break end
				table.insert(countingTbl, itemName);
				table.insert(typeTbl[itemName], {idx = i});
			end
		end
	end,
	
	tpItems = function()
		TooltipHelper.indexTbl["Premium"] = {};
		local typeTbl = TooltipHelper.indexTbl["Premium"];
		local clsList, cnt = GetClassList("recycle_shop");
		for i = 0 , cnt - 1 do repeat
			local cls = GetClassByIndexFromList(clsList, i);
			local sellPrice = cls.SellPrice
			if sellPrice == nil or sellPrice == 0 then break end;
			local countingTbl = {};
			
			local itemName = cls.ClassName;
			if typeTbl[itemName] == nil then
				typeTbl[itemName] = {};
			end
			
			if tthUtil.contains(countingTbl, itemName) then break end
			table.insert(countingTbl, itemName);
			table.insert(typeTbl[itemName], {idx = i, name = itemName, sellPrice = sellPrice} );
		until true end
	end
}

return tooltiphelper_cache;