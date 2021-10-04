--[[

	hub_bot_cleaner.lua by pulsar

        - this script removes unused bots from "cfg/users.tbl"

        v0.4: by pulsar
            - changed visuals
            - removed table lookups

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
local scriptversion = "0.4"

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

--// imports
local report = hub.import( "etc_report" )


----------
--[CODE]--
----------

local list = {}
local removeUnusedBots = function()
    list[ os.time() ] = function()
        local user_tbl = hub.getregusers()
        for i, v in pairs( user_tbl ) do
            if ( user_tbl[ i ].is_bot == 1 and not hub.isnickonline( user_tbl[ i ].nick ) ) then
                report.send( report_activate, report_hubbot, report_opchat, llevel, "[ BOT CLEANER ]--> deleted unused bot:  " .. user_tbl[ i ].nick )
                hub.delreguser( user_tbl[ i ].nick )
            end
        end
    end
end

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os.difftime( os.time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {}, removeUnusedBots() )

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )