--[[

    etc_banner.lua

        - this script sends a banner in regular intervals to mainchat

        v0.09: by pulsar
            - add "activate", possibility to activate/deactivate the banner
            - add new table lookups
        
        v0.08: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.07: by pulsar
            - cleaning code

        v0.06: by pulsar
            - small changes
            - fix doubleposting

        v0.05: by pulsar
            - small changes
            - option to send banner in main and/or pm
            - level choice

        v0.04: by pulsar
            - add 'time' variable

        v0.03: by blastbeat
            - clean up

        v0.02: by blastbeat
            - updated script api, cached table lookups

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_banner"
local scriptversion = "0.09"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local cfg_get = cfg.get
local os_time = os.time
local os_difftime = os.difftime
local hub_getusers = hub.getusers
local hub_getbot = hub.getbot()

--// imports
local time = cfg_get( "etc_banner_time" )
local destination_main = cfg_get( "etc_banner_destination_main" )
local destination_pm = cfg_get( "etc_banner_destination_pm" )
local permission = cfg_get( "etc_banner_permission" )
local banner = cfg_get( "etc_banner_banner" )
local activate = cfg_get( "etc_banner_activate" )

----------
--[CODE]--
----------

local delay = time * 60 * 60
local start = os_time()

local check = function()
    for sid, user in pairs( hub_getusers() ) do
        local user_level = user:level()
        local user_isbot = user:isbot()
        if not user_isbot then
            if permission[ user_level ] then
                if destination_main then
                    user:reply( banner, hub_getbot )
                end
                if destination_pm then
                    user:reply( banner, hub_getbot, hub_getbot )
                end
            end
        end
    end
end

hub.setlistener( "onTimer", { },
    function()
        if activate then
            if os_difftime( os_time() - start ) >= delay then
                check()
                start = os_time()
            end
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

---------
--[END]--
---------