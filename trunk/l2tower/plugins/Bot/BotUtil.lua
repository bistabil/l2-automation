
function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

log = function(...)
    local resultLine = "";
    for i = 1, select("#", ...) do
        local line = select(i, ...);
        if (line == nil) then
            resultLine = resultLine .. " NIL";
        elseif type(line) == "table" then
            resultLine = resultLine .. " " .. createTableString(line) .. " ";
        elseif type(line) == "userdata" then
            resultLine = resultLine .. " " .. type(line);
        else
            resultLine = resultLine .. " " .. tostring(line);
        end;
    end;
    this:Log(resultLine);
    --dprint(resultLine);
end;

function createTableString(input)
 	local shift = 0;
 	local tablesOpened = {}
 	local function innerCreateTableString(input)
		if type(input) == "table" then
		    if (nil == tablesOpened[input]) then
		        tablesOpened[input] = input;
                local result = {"Table: \n"};
                shift = shift + 1;
                for key, value in pairs (input) do
                    result[#result+1] = string.rep("|   ", shift);
                    result[#result+1] = string.format("[%s] = %s", tostring(key), innerCreateTableString(value));
                end;
                shift = shift - 1;
                return table.concat(result);
            else
                return "[RECURSIVE LINK]\n";
            end
   		 else
      		return tostring(input) .. "\n";
   		 end;
  	end;
  	return innerCreateTableString(input);
end

function table.contains(tbl, item)
	for k,v in pairs(tbl) do
		if v == item then
			return true;
		end
	end
	return false;
end

function table.any(tbl, cmpFu)
	for k,v in pairs(tbl) do
		if cmpFu(v) then
			return true;
		end
	end
	return false;
end

L2TowerPausedLock = 0;

-- L2Tower Pause is used in order to take full control over char (disable all scripts and L2Tower functionality)
function LockPause()
	L2TowerPausedLock = L2TowerPausedLock + 1

	if L2TowerPausedLock == 1 then
		L2TowerPaused = IsPaused();
		if not L2TowerPaused then
			SetPause(true);
		end
	end
end

function UnlockPause()
	L2TowerPausedLock = L2TowerPausedLock - 1

	if L2TowerPausedLock == 0 then
		if not L2TowerPaused then
			SetPause(false);
		end
	elseif L2TowerPausedLock < 0 then
		this:Log("L2TowerPausedLock become negative");
		L2TowerPausedLock = 0;
	end
end

-- puts current coroutine to sleep for "timeout" ms
function ThreadSleepMs(timeout)
	local resumeAt = GetTime() + timeout;
	EventsBus:waitOn("OnLTick", function () return resumeAt < GetTime() end)
	return true;
end

-- puts current coroutine to sleep for "timeout" seconds.
function ThreadSleepS(timeout) 
	local resumeAt = GetTime() + timeout * 1000;
	EventsBus:waitOn("OnLTick1s", function () return resumeAt < GetTime() end)
	return true;
end


function SelectTargetByOId(oId)
	ClearTargets();
	CancelTarget(false)
	if oId and oId > 0 then
		TargetRaw(oId)
		if CurrentThread then
			EventsBus:waitOn("OnMyTargetSelected", function (target) return target:GetId() == oId end)
		end
	end
	return true;
end

function TalkByTarget(oId)
	ClearTargets();
	CancelTarget(false)
	if oId and oId > 0 then
		TargetRaw(oId)
		EventsBus:waitOn("OnMyTargetSelected", function (target) return target:GetId() == oId end)
		TargetRaw(oId)
	end
	return true;
end

function CastSkill(id, count, timeout)
	timeout = timeout or 1000;
	local skill = GetSkills():FindById(id)
	if skill and skill:CanBeUsed() then
		UseSkillRaw(id,false,false)
		local myId = GetMe():GetId();

		local res = EventsBus:waitOn("OnMagicSkillLaunched", function (user, target, skillId, skillLvl)
			return myId == user:GetId() and id == skillId;
		end, timeout)
		if res then 
			return true;
		elseif count > 0 then
			return CastSkill(id, (count - 1), timeout)
		else
			log("Failed to cast skill:", id);
		end
	end
	return false
end

-- @return false in case if some skill failed to cast or process has been stopped
function CastAllByList(list, count, timeout)
	if "table" ~= type(list) then return dprint("CastAllByList(list) - >> list not a table") end
	CancelTarget(false)
	for _, id in pairs(list) do
		if not CastSkill(id, count, timeout) then
			return false;
		end
	end
end

function MobsCount(range)
	mobs = GetMonsterList()
	i=0
	for m in mobs.list do
		 if m:GetDistance() <= range and m:GetHpPercent() ~= 0 then
			 i = i+1
		 end
	end
	return i
end