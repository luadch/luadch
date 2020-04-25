--[[

	hub_bot_cleaner.lua by pulsar

        - this script removes unused bots from "cfg/users.tbl"

        v0.3: by pulsar
            - removed "hub.reloadusers()"
            - using "hub.getregusers()" instead of "util.loadtable()"
            - using "report.send()" import function
            - code cleaning

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
local scriptversion = "0.3"

--// how many seconds after script start?
local delay = 10
--// send a report?
local report_activate = true
--// who gets a report?
local llevel = 100
--// send report to hubbot?
local report_hubbot = true
--// send report to opchat as feed
local report_opchat = false

--// table lookups
local hub_getbot = hub.getbot
local hub_isnickonline = hub.isnickonline
local hub_delreguser = hub.delreguser
local hub_getregusers = hub.getregusers
local hub_debug = hub.debug
local hub_import = hub.import
local os_time = os.time
local os_difftime = os.difftime
--// imports
local report = hub_import( "etc_report" )


----------
--[CODE]--
----------

local list = {}
local removeUnusedBots = function()
    list[ os_time() ] = function()
        local user_tbl = hub_getregusers()
        for i, v in pairs( user_tbl ) do
            if ( user_tbl[ i ].is_bot == 1 and not hub_isnickonline( user_tbl[ i ].nick ) ) then
                report.send( report_activate, report_hubbot, report_opchat, llevel, "deleted unused bot: " .. user_tbl[ i ].nick )
                hub_delreguser( user_tbl[ i ].nick )
            end
        end
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