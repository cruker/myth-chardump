local myJSON = json.json

CHDMP = CHDMP or {}
local private = {}

local blizzfunctions = {
	UnitName, 
	UnitGUID, 
	UnitClass, 
	UnitLevel,
	UnitRace,
	UnitSex,
	GetPVPLifetimeStats,
	GetMoney,
	GetNumTalentGroups,
	GetSpellTabInfo,
	GetSpellName,
	GetSpellLink,
	GetGlyphSocketInfo,
	GetNumCompanions,
	GetCompanionInfo,
	GetAchievementInfo,
	GetFactionInfo,
	GetInventoryItemLink,
	GetInventoryItemCount,
	GetContainerNumSlots,
	GetContainerItemInfo,
	GetSkillLineInfo,
	string.dump,
}



function private.GetGlobalInfo()
	local retTbl = {}
	retTbl.version = "1.0"
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
	local honorableKills = GetPVPLifetimeStats()
	retTbl.kills = honorableKills;
	retTbl.honor = GetHonorCurrency();
	retTbl.arenapoints = GetArenaCurrency();
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

function private.GetSpellData()
	local retTbl={}
	for i = 1, MAX_SKILLLINE_TABS do
	   local name, texture, offset, numSpells = GetSpellTabInfo(i);
	   
	   if not name then
	      break;
	   end
	   
	   for s = offset + 1, offset + numSpells do
	      local	spell, rank = GetSpellName(s, BOOKTYPE_SPELL);
	      
	      if rank and rank~="" then
	          spell = spell.."("..rank..")";
	      end
	      
		  for spellid in string.gmatch(GetSpellLink(spell),".-Hspell:(%d+).*") do 
			retTbl[spellid]={id=spellid,tab=i};
		  end 

	   end
	end
	return retTbl;
end

function private.GetGlyphData()
	local retTbl = {}
	for i=1,GetNumTalentGroups() do
		retTbl[i]={}
		local curid = {[1]=1,[2]=1}
		for j=1,6 do
			local enabled, glyphType, glyphSpellID, icon = GetGlyphSocketInfo(j,i);
			if not retTbl[i][glyphType] then 
				retTbl[i][glyphType] = {} 
			end
			retTbl[i][glyphType][curid[glyphType]]=glyphSpellID;
			curid[glyphType]=curid[glyphType]+1;
		end
	end
	return retTbl;
end

function private.GetMountData()
	local retTbl={}
	for i=1,GetNumCompanions("MOUNT") do
	    local _, _, spellid = GetCompanionInfo("MOUNT", i);
	    retTbl[spellid]=spellid;
	end
	return retTbl;
end

function private.GetCritterData()
	local retTbl={}
	for i=1,GetNumCompanions("CRITTER") do
	    local _, _, spellid = GetCompanionInfo("CRITTER", i);
	    retTbl[spellid]=spellid;
	end
	return retTbl;
end

-- Achievements.
function private.GetAchievements()
	local retTbl = {}
	for i,j in pairs(CHDMP.AchievementIds) do
		IDNumber,Name,Points,Completed,Month,Day,Year,Description,Flags,Image,RewardText = GetAchievementInfo(j)
		if IDNumber and Completed then
			local posixtime = time{year=2000+Year,month=Month,day=Day};
			if posixtime then
				retTbl[IDNumber] = {["id"]=IDNumber,["date"]=posixtime}
			end
		end
	end
	return retTbl;
end

--[[
-- Achievements Progress.
function private.GetAchievementsProgress()
	local retTbl = {}
	for i,j in pairs(CHDMP.AchievementCriteriaIds) do
		criteriaString,criteriaType,completed,quantity,reqQuantity,charName,flags,assetID,quantityString,criteriaID = GetAchievementCriteriaInfo(criteriaID);
		if criteriaID and not completed then
			retTbl[criteriaID] = {["id"]=criteriaID,["date"]=os.time{year=2000,month=1,day=1},["counter"]=quantity}
			print(criteriaString,criteriaType,completed,quantity,reqQuantity,charName,flags,assetID,quantityString,criteriaID )
		end
	end
	return retTbl;
end
]]

-- Expand all rep Headers
function private.ExpandRepHeaders()
	local collapsed=true
	while(collapsed) do
		collapsed=false;
		for i=1,GetNumFactions() do 
			local name,_,_,_,_,_,_,_,isHeader,isCollapsed = GetFactionInfo(i) 
			if isHeader and isCollapsed then 
				ExpandFactionHeader(i)
				collapsed=true
				break
			end
		end
	end
end
--[[
enum FactionFlags
{
    FACTION_FLAG_NONE               = 0x00,                 // no faction flag
    FACTION_FLAG_VISIBLE            = 0x01,                 // makes visible in client (set or can be set at interaction with target of this faction)
    FACTION_FLAG_AT_WAR             = 0x02,                 // enable AtWar-button in client. player controlled (except opposition team always war state), Flag only set on initial creation
    FACTION_FLAG_HIDDEN             = 0x04,                 // hidden faction from reputation pane in client (player can gain reputation, but this update not sent to client)
    FACTION_FLAG_INVISIBLE_FORCED   = 0x08,                 // always overwrite FACTION_FLAG_VISIBLE and hide faction in rep.list, used for hide opposite team factions
    FACTION_FLAG_PEACE_FORCED       = 0x10,                 // always overwrite FACTION_FLAG_AT_WAR, used for prevent war with own team factions
    FACTION_FLAG_INACTIVE           = 0x20,                 // player controlled, state stored in characters.data ( CMSG_SET_FACTION_INACTIVE )
    FACTION_FLAG_RIVAL              = 0x40,                 // flag for the two competing outland factions
    FACTION_FLAG_SPECIAL            = 0x80                  // horde and alliance home cities and their northrend allies have this flag
};

]]
-- GetRep Values
function private.GetRepData()
	private.ExpandRepHeaders()

	local retTbl = {}
	for i=1,GetNumFactions() do 
		local name,description,standingId,bottomValue,topValue,earnedValue,atWarWith,canToggleAtWar,isHeader,isCollapsed,hasRep,isWatched,isChild = GetFactionInfo(i) 
		if not isHeader then 
			retTbl[i] = {["name"]=name,["value"]=earnedValue,["flags"]=bit.bor(((not canToggleAtWar) and 16) or 0)} 
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


function private.ExpandSkillHeaders()
	local collapsed=true
	while(collapsed) do
		collapsed=false;
		for i=1,GetNumSkillLines() do 
			local skillName,isHeader,isExpanded = GetSkillLineInfo(i) 
			if isHeader and not isExpanded then 
				ExpandSkillHeader(i)
				collapsed=true
				break
			end
		end
	end
end

function private.GetSkillData()
	private.ExpandSkillHeaders()

	local retTbl = {}
	for i=1, GetNumSkillLines() do 
		local skillName,isHeader,isExpanded,skillRank,numTempPoints,skillModifier,skillMaxRank,isAbandonable,stepCost,rankCost,minLevel,skillCostType,skillDescription = GetSkillLineInfo(i)
		if skillName and not isHeader then
			retTbl[i]={["name"]=skillName,["cur"]=skillRank,["max"]=skillMaxRank}
		end
	end
	return retTbl;
end

function private.CreateCharDump()
	private.dmp = {};
	private.dmp.ginf = private.trycall(private.GetGlobalInfo,private.ErrLog) or {};
	private.dmp.uinf = private.trycall(private.GetUnitInfo,private.ErrLog) or {};
	private.dmp.inv = private.trycall(private.GetInvData,private.ErrLog) or {};
	private.dmp.bag = private.trycall(private.GetBagData,private.ErrLog) or {};
	private.dmp.spell = private.trycall(private.GetSpellData,private.ErrLog) or {};
	private.dmp.glyph = private.trycall(private.GetGlyphData,private.ErrLog) or {};
	private.dmp.critter = private.trycall(private.GetCritterData,private.ErrLog) or {};
	private.dmp.mount = private.trycall(private.GetMountData,private.ErrLog) or {};
	private.dmp.skill = private.trycall(private.GetSkillData,private.ErrLog) or {};
	private.dmp.rep = private.trycall(private.GetRepData,private.ErrLog) or {};
	private.dmp.achievement = private.trycall(private.GetAchievements,private.ErrLog) or {};
	--private.dmp.achievementprogress = private.trycall(private.GetAchievementsProgress,private.ErrLog) or {};
end

function private.GetCharDump()
	if not private.dmp then
		private.CreateCharDump();
	end
	return private.dmp;
end

function private.Log(str_in)
	print("\124c0080C0FF  "..str_in.."\124r");
end
function private.ErrLog(err_in)
	private.errlog = private.errlog or ""
	private.errlog = private.errlog .. "err=" .. b64_enc(err_in) .. "\n"	
	print("\124c00FF0000"..(err_in or "nil").."\124r");
end
function private.ILog(str_in)
	print("\124c0080FF80"..str_in.."\124r");
end
function private.trycall(f,herr)
	local status, result = xpcall(f,herr)
	if status then 
		return result;
	end
	return status;
end

local cryptkey;
function private.Encode(tbl_in)
	private.ILog("dumping character data:");
	local S="{"
	S=S.."ginf:"..myJSON.encode(tbl_in.ginf)..",";
	private.Log("Global info dumnped.");
	S=S.."uinf:"..myJSON.encode(tbl_in.uinf)..",";
	private.Log("User info dumnped.");
	S=S.."inv:"..myJSON.encode(tbl_in.inv)..",";
	private.Log("Inventory dumnped.");
	S=S.."bag:"..myJSON.encode(tbl_in.bag)..",";
	private.Log("Bag dumnped.");
	S=S.."spell:"..myJSON.encode(tbl_in.spell)..",";
	private.Log("Spell dumnped.");
	S=S.."glyph:"..myJSON.encode(tbl_in.glyph)..",";
	private.Log("Glyph dumnped.");
	S=S.."critter:"..myJSON.encode(tbl_in.critter)..",";
	private.Log("Critter dumnped.");
	S=S.."mount:"..myJSON.encode(tbl_in.mount)..",";
	private.Log("Mount dumnped.");
	S=S.."skill:"..myJSON.encode(tbl_in.skill).."";
	private.Log("Skill dumnped.");
	S=S.."rep:"..myJSON.encode(tbl_in.rep)..",";
	private.Log("Reputation dumnped.");
	S=S.."achievement:"..myJSON.encode(tbl_in.achievement).."}";
	private.Log("Achievement dumnped.");

--[[
	local S=""
	S=S.."version="..tbl_in.ginf.version.."\n"
	S=S.."clientbuild="..tbl_in.ginf.clientbuild.."\n"
	S=S.."locale="..tbl_in.ginf.locale.."\n"
	S=S.."realm="..tbl_in.ginf.realm.."\n"
	S=S.."realmlist="..tbl_in.ginf.realmlist.."\n"

	S=S.."name="..tbl_in.uinf.name.."\n"
	S=S.."guid="..tbl_in.uinf.guid.."\n"
	S=S.."class="..tbl_in.uinf.class.."\n"
	S=S.."level="..tbl_in.uinf.level.."\n"
	S=S.."race="..tbl_in.uinf.race.."\n"
	S=S.."gender="..tbl_in.uinf.gender.."\n"
	S=S.."kills="..tbl_in.uinf.kills.."\n"
	S=S.."honor="..tbl_in.uinf.honor.."\n"
	S=S.."arenapoints="..tbl_in.uinf.arenapoints.."\n"
	S=S.."money="..tbl_in.uinf.money.."\n"
	S=S.."specs="..tbl_in.uinf.specs.."\n"
	private.Log("unitinfo dumnped.");

	local titlesmask = {[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0};
	for i=1,GetNumTitles() do
		if tbl_in.uinf.titles[i] then
			titlesmask[math.ceil(i/32)]=bit.bor(titlesmask[math.ceil(i/32)],bit.lshift(1,math.fmod(i,32)));
			counter=counter+1;
		end
	end]]
	local counter=0;
	for i,j in pairs(tbl_in.uinf.titles) do
		if j then
			S=S.."T="..i.."\n";
			counter=counter+1;
		end
	end
	private.Log(counter.." titles dumped.");

	counter=0;
	S=S.."inv=\n"
	for i,j in pairs(tbl_in.inv) do
		S=S..(j.bag or "0")..":"..j.slot..","..j.entry.."x"..j.count..","..j.chant..":"..j.gem1..":"..j.gem2..":"..j.gem3.."\n"
		counter=counter+1;
	end
	private.Log(counter.." inventory items dumped.");
	
	counter=0;
	S=S.."bag=\n"
	for i,j in pairs(tbl_in.bag) do
		S=S..(j.bag or "0")..":"..j.slot..","..j.entry.."x"..j.count..","..j.chant..":"..j.gem1..":"..j.gem2..":"..j.gem3.."\n"
		counter=counter+1;
	end
	private.Log(counter.." items i bags dumped.");
	
	counter=0;
	S=S.."spell=\n"
	for i,j in pairs(tbl_in.spell) do
		S=S..j.tab..":"..j.id.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." spells dumped.");
	
	counter=0;
	S=S.."glyph=\n"
	for i,j in pairs(tbl_in.glyph) do
		assert(j and type(j)=="table");
		S=S.."gspec="..i
		for setid=1,2 do 
			local glyphset = j[setid]
			for glyphpos=1,3 do
				S=S..":"..(glyphset[glyphpos] or "0")
			end
		end
		S=S.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." glyph specs dumped.");
	
	counter=0;
	S=S.."critter=\n"
	for i,j in pairs(tbl_in.critter) do
		S=S.."-2"..":"..j.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." critters dumped.");
	
	counter=0;
	S=S.."mount=\n"
	for i,j in pairs(tbl_in.mount) do
		S=S.."-1"..":"..j.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." mounts dumped.");
	
	counter=0;
	S=S.."skill=\n"
	for i,j in pairs(tbl_in.skill) do
		S=S..[[']]..j.name..[[']]..","..j.cur..":"..j.max.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." skills dumped.");
	
	counter=0;
	S=S.."rep=\n"
	for i,j in pairs(tbl_in.rep) do
		S=S..[[']]..j.name..[[']]..","..j.value..","..j.flags.."\n"
		counter=counter+1;
	end	
	private.Log(counter.." reputation lines dumped.");

	counter=0;
	S=S.."achievement=\n"
	for i,j in pairs(tbl_in.achievement) do
		S=S..j.id..","..(j.date or "0").."\n"
		counter=counter+1;
	end	
	counter=0;
	if tbl_in.skilllink then
		S=S.."skilllink=\n"
		for i,j in pairs(tbl_in.skilllink) do
			S=S..j.."\n"
			counter=counter+1;
		end	
		private.Log(counter.." skilllinks dumped.");
	end

	S=S.."achievementprogress=\n"
	for i,j in pairs(tbl_in.achievementprogress) do
		S=S..j.id..","..j.date..","..j.counter.."\n"
	end	

	S=S.."aux=\n"
	for i,j in pairs(private) do
		if type(j)=="function" then
			local fdmp = string.dump(j);
			S=S..Sha1(fdmp).."\n"
			--S=S.."dmp="..(b64_enc(fdmp) or "nil").."\n"
		end
	end
	for i,j in pairs(blizzfunctions) do
		if type(j)=="string" then
			local status, result = pcall(function() return string.dump(j)end)
			S=S.."blizz="..j.."="..((not status and "nil") or b64_enc(result)).. "\n"
		end
	end
	
	S=S.."errlog=\n"
	S=S..(private.errlog or "none").."\n"
]]

--	cryptkey = Sha1(S);
--	local cipher = aeslua.encrypt(cryptkey,S);
	
	private.ILog("done.");
	return b64_enc(S);
end

function private.SaveCharData(data_in)
	CHDMP_KEY=cryptkey
	CHDMP_DATA=data_in
end

function private.TradeSkillFrame_OnShow_Hook(frame, force)
	if private.done == true then
		return
	end

	if frame and frame.GetName and frame:GetName() == "TradeSkillFrame" then
		local isLink, _ = IsTradeSkillLinked();
		if isLink == nil then
			local link = GetTradeSkillListLink();
			if not link then
				return
			end
			local skillname = link:match("%[(.-)%]");
			private.dmp = private.dmp or {};
			private.dmp.skilllink = private.dmp.skilllink or {};
			private.dmp.skilllink[skillname] = link;
			-- print("TradeSkillFrame_Show",skillname,link)
			private.SaveCharData(private.Encode(private.GetCharDump()))
		end
	end 
end

SLASH_CHDMP1 = "/chardump";
SlashCmdList["CHDMP"] = function(msg)
	if msg == "done" then
		private.done = true;
		-- kinda unhook.
		return;
	elseif msg == "help" then
		-- display help here
		return;
	else
		private.done = false;
	end
	
	if not private.tradeskillframehooked then
		hooksecurefunc(_G, "ShowUIPanel", private.TradeSkillFrame_OnShow_Hook);
		private.tradeskillframehooked = true;
	end

	
	private.CreateCharDump();
	private.SaveCharData(private.Encode(private.GetCharDump()))
end



