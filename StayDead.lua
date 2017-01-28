-- initialize addon
local addon_prefix = "StayDead"
RegisterAddonMessagePrefix(addon_prefix)

-- create frame
local events = CreateFrame("Frame", "StayDead_events")
local sync = CreateFrame("Frame", "StayDead_sync")

-- register events
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("GROUP_JOINED")
sync:RegisterEvent("CHAT_MSG_ADDON")

-- disable addon by default
local status = "off";

-- hide function
function StayDead_Status()
    if (status == "on") then
        StaticPopup1Button1:Hide();
    end
    if  (status == "off") then
        StaticPopup1Button1:Show();
    end
end

-- fetch status of leader
function StayDead_fetch()
    -- raid
    if (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
        for i=1,GetNumGroupMembers(),1 do
            name, rank = GetRaidRosterInfo(i);
            if (rank == 2) then
                SendAddonMessage(addon_prefix, "fetch:init", "WHISPER", name);
            end
        end

    -- party
    elseif (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        for i=1,GetNumGroupMembers(),1 do
            if (UnitIsGroupLeader("party" .. i)) then
                SendAddonMessage(addon_prefix, "fetch:init", "WHISPER", UnitName("party" .. i));
            end
        end    
    end
end

-- event handling
events:SetScript("OnEvent", function(self, event, arg1)
    -- fire on death
    if (event == "PLAYER_DEAD") then
        StayDead_Status();

    elseif (event == "GROUP_JOINED") then
        events:UnregisterEvent("GROUP_JOINED")
        events:RegisterEvent("GROUP_LEFT")
        events:RegisterEvent("PLAYER_DEAD")
        StayDead_fetch()
    
    elseif (event == "GROUP_LEFT") and (status == "on") then
        events:RegisterEvent("GROUP_JOINED")
        events:UnregisterEvent("GROUP_LEFT")
        events:UnregisterEvent("PLAYER_DEAD")
        
        print("|cFF8753efStayDead|r disabled");
        status = "off"

    elseif (event == "PLAYER_LOGIN") then
        StayDead_fetch()
    end
end)

-- sync handling
sync:SetScript("OnEvent", function(self, event, prefix, message, channel, _, sender)
    if (event == "CHAT_MSG_ADDON") and (prefix == addon_prefix) then
        local action, message = string.match(message, "(%a*):(.*)")
    
        -- receiving
        if (action == "sync") then
            if (UnitIsGroupLeader(sender)) then
                -- updating status
                if (message == "StayDead_on") and (status == "off") then
                    print("|cFF8753efStayDead|r activated");
                    status = "on";
                
                elseif (message == "StayDead_off") and (status == "on") then
                    print("|cFF8753efStayDead|r disabled");
                    status = "off";
                end
            end
    
        -- fetching
        elseif (action == "fetch") then
            if (UnitInParty(sender)) then
                SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. status, "WHISPER", sender);
            end
        end
    end
end)

-- slash handler
local function handler(msg, editbox)
    -- sync to others
    if (UnitIsGroupLeader("player")) then
        if (msg == "on") or (msg == "off") then
            SendAddonMessage(addon_prefix, "sync:" .. addon_prefix .. "_" .. msg, "RAID");
        end

    -- restricted
    else
        print("You need to be leader to use this function.")
    end
end

-- slash commands
SLASH_STAYDEAD1 = '/sd';
SlashCmdList["STAYDEAD"] = handler;