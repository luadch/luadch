--[[

	hub_user_lastseen.lua by pulsar

        - this script updates the "lastseen" in "cfg/users.tbl"

        v0.1: by pulsar
            - first checkout

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_user_lastseen"
local scriptversion = "0.1"

--// activate this script?
local activate = true

--// updates lastseen on timer (minutes)
local delay = 1


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local start = os.time()

local update_lastseen = function()
    local user_tbl = hub.getregusers()
    for i, v in pairs( user_tbl ) do
        if ( user_tbl[ i ].is_bot ~= 1 ) and ( user_tbl[ i ].is_online == 1 ) then
            user_tbl[ i ].lastseen = util.date()
        end
    end
    cfg.saveusers( user_tbl )
end

hub.setlistener( "onTimer", {},
    function( )
        if os.difftime( os.time() - start ) >= ( delay * 60 ) then
            update_lastseen()
            start = os.time()
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )