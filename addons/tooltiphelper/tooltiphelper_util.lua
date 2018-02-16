local tooltiphelper_util = {
	labelColor = "9D8C70",
	completeColor = "00FF00",
	commonColor = "FFFFFF",
	npcColor = "FF4040",
	squireColor = "40FF40",
	unregisteredColor = "7B7B7B",
	collectionIcon = "icon_item_box",
	starIcon = "star_mark",
	tab = "     ",
	tthMainFrameName = 'tth_parent_container'
}

function tooltiphelper_util.contains(table,val)
	for k, v in ipairs(table) do
        if v == val then
            return true
        end
    end
	return false
end
	
function tooltiphelper_util.compare(a, b)
    if a.grade < b.grade then
        return true
    elseif a.grade > b.grade then
        return false
    else
        return a.resultItemName < b.resultItemName
    end
end
	
function tooltiphelper_util.chanceCompare(a, b)
	if a.chnc ~= b.chnc then
		return a.chnc > b.chnc
	else
		return a.name < b.name
	end
end
	
function tooltiphelper_util.toIMCTemplate(text, colorHex)
	if colorHex == nil then colorHex = "9D8C70" end;
    return "{ol}{ds}{#" .. colorHex .. "}".. text .. "{/}{/}{/}"    
end
	
function tooltiphelper_util.addIcon(text, iconName)
	return "{img " .. iconName .. " 24 24}" .. text .. "{/}"
end
	
function tooltiphelper_util.manuallyCount(cls, invItem)
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
	
function tooltiphelper_util.render(fn, config, buffer, invItem, text)
	if config and fn ~= nil then
		text = fn(invItem);
		if text ~= "" then
			table.insert(buffer,text);
		end
	end
end
	
function tooltiphelper_util.renderLabel(fn, config, invItem, labels)
	if config and fn ~= nil then
		local label = fn(invItem) or ""; 
		table.insert(labels, label)
	end
end

return tooltiphelper_util;