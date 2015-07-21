--[[

	hub_bot_cleaner by pulsar

        v0.2:
            - add needReload
            - add timer
            - add report
            
        v0.1:
            - this script removes unused bots from "cfg/users.tbl"

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_bot_cleaner"
local scriptversion = "0.2"

--// how many seconds after script start?
local delay = 10
--// send a report?
local sendreport = true
--// who gets a report?
local reportlevel = 100

----------
--[CODE]--
----------

local user_file = "cfg/user.tbl"
local hub_getbot = hub.getbot
local hub_isnickonline = hub.isnickonline
local hub_delreguser = hub.delreguser
local hub_getusers = hub.getusers
local hub_reloadusers = hub.reloadusers
local hub_debug = hub.debug
local util_loadtable = util.loadtable
local os_time = os.time
local os_difftime = os.difftime

local list = {}
local removeUnusedBots = function()
    list[ os_time() ] = function()
        local user_tbl = util_loadtable( user_file )
        local needReload = false
        for i, v in pairs( user_tbl ) do
            if user_tbl[ i ].is_bot == 1 then
                local isOnline = hub_isnickonline( user_tbl[ i ].nick )
                if not isOnline then
                    needReload = true
                    hub_delreguser( user_tbl[ i ].nick )
                    if sendreport then
                        for sid, user in pairs( hub_getusers() ) do
                            if not user:isbot() and user:level() >= reportlevel then
                                user:reply( "deleted unused bot: " .. user_tbl[ i ].nick, hub_getbot(), hub_getbot() )
                            end
                        end
                    end
                end
            end
        end
        if needReload then hub_reloadusers() end
    end
end

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os_difftime( os_time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {}, removeUnusedBots() )

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )