--[[

    etc_ccpmblocker.lua by pulsar and blastbeat
        
        v0.1

            - This script controls the CCPM - Client to Client Private Message feature
            
]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_ccpmblocker"
local scriptversion = "0.1"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local hub_debug = hub.debug

--// imports
local block_level = cfg_get( "etc_ccpmblocker_block_level" )


----------
--[CODE]--
----------

local check_ccpm = function( user, cmd, su )
    local user_level = user:level()
    if block_level[ user_level ] then
        local s, e = string.find( su, "CCPM" )
        if s then
            local new_su
            local l = #su
            if e < l then
                new_su = su:gsub( "CCPM,", "" )
            else
                new_su = su:gsub( ",CCPM", "" )
            end
            cmd:setnp( "SU", new_su )
        end    
    end
end

local listener = function( user )
    local cmd = user:inf()
    local su = cmd:getnp "SU"
    if su then
        check_ccpm( user, cmd, su )
    end
    return nil
end

hub.setlistener( "onConnect", {}, listener )
hub.setlistener( "onInf", {}, listener )

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )