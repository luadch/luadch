--[[

    usr_hide_share.lua

        v0.1:
            - this script hides share of specified levels

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_hide_share"
local scriptversion = "0.1"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// caching table lookups
local cfg_get = cfg.get
local hub_debug = hub.debug
local hub_getusers = hub.getusers

--// imports
local activate = cfg_get( "usr_hide_share_activate" )
local permission = cfg_get( "usr_hide_share_permission" )

local share = "0"

----------
--[CODE]--
----------

if activate then

    hub.setlistener( "onStart", {},
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if permission[ user:level() ] then
                    user:inf():setnp( "SS", share )
                end
            end
            return nil
        end
    )

    hub.setlistener( "onExit", {},
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if permission[ user:level() ] then
                    user:inf():setnp( "SS", share )
                end
            end
            return nil
        end
    )

    hub.setlistener( "onInf", {},
        function( user, cmd )
            if permission[ user:level() ] then
                cmd:setnp( "SS", share )
                user:inf():setnp( "SS", share )
            end
            return nil
        end
    )

    hub.setlistener( "onConnect", {},
        function( user )
            if permission[ user:level() ] then
                user:inf():setnp( "SS", share )
            end
            return nil
        end
    )

end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )