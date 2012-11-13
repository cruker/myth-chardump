local myJSON = json.json

CHDMP = CHDMP or {}
local private = {}

function private.GetGlobalInfo()
	local retTbl = {}
	retTbl.locale = GetLocale();
	retTbl.realm = GetRealmName();
	retTbl.realmlist = GetCVar("realmList");
	local version, build, date, tocversion = GetBuildInfo();
	retTbl.clientbuild = build;
	return retTbl;
end

function private.GetUnitInfo()
	local retTbl = {}
	retTbl.name = UnitName("player");
	retTbl.guid = tostring(UnitGUID("player"));
	local _, class = UnitClass("player");
	retTbl.class=class;
	retTbl.level=UnitLevel("player");
	local _,race = UnitRace("player");
	retTbl.race=race;
	retTbl.gender=UnitSex("player");
	retTbl.gender=retTbl.gender-2;
	local honorableKills = GetPVPLifetimeStats()
	retTbl.kills = honorableKills;
	retTbl.money = GetMoney();
	retTbl.specs = GetNumTalentGroups();

	retTbl.titles = {}
	for i=1,GetNumTitles() do
		if IsTitleKnown(i) == 1 then
			retTbl.titles[i] = true;
		end
	end

	return retTbl;
end

-- Inventory Unitslots +bags +bankbags +bank
function private.GetInvData()
	local retTbl = {}
	for i=1,74 do 
		itemLink = GetInventoryItemLink("player", i) 
		if itemLink then 
			count = GetInventoryItemCount("player",i) 
			--durability,durabilitymax = GetInventoryItemDurability("player",i);
			--print(i,itemLink,count--[[,durability.."/"..durabilitymax]]) 
			for entry,chant,gem1,gem2,gem3,unk1,unk2,unk3,lvl1 in string.gmatch(itemLink,".-Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+).*") do 
				--                                                                                                      entry^ chant^  gem^  gem^  gem^  unk^  unk^  unk^  lvl^
				retTbl[i]= {["slot"]=i,["entry"]=entry,["chant"]=chant,["gem1"]=gem1,["gem2"]=gem2,["gem3"]=gem3,["unk1"]=unk1,["unk2"]=unk2,["unk3"]=unk3,["lvl"]=lvl1,["count"]=count};
			end
		end 
	end 
	return retTbl;
end

-- Bag Items
function private.GetBagData()
	local retTbl = {}
	for bag=0,11 do 
		for slot = 1,GetContainerNumSlots(bag) do 
			ItemLink = GetContainerItemLink(bag, slot) 
			if ItemLink then 
				local texture, itemCount,locked,quality,readable = GetContainerItemInfo(bag,slot); 
				local Tbag = bag+1000;
				for entry,chant,gem1,gem2,gem3,unk1,unk2,unk3,lvl1 in string.gmatch(ItemLink,".-Hitem:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+).*") do 
					--                                                                             entry^ chant^  gem^  gem^  gem^  unk^  unk^  unk^  lvl^
					retTbl[Tbag..":"..slot]= {["bag"]=Tbag,["slot"]=slot,["entry"]=entry,["chant"]=chant,["gem1"]=gem1,["gem2"]=gem2,["gem3"]=gem3,["unk1"]=unk1,["unk2"]=unk2,["unk3"]=unk3,["lvl"]=lvl1,["count"]=itemCount};
				end
			end 
		end 
	end 
	return retTbl;
end