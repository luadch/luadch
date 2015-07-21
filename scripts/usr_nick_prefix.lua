--[[

    usr_nick_prefix.lua by blastbeat

        - this script adds a prefix to the nick of an user
        - you can use the prefix table to define different prefixes for different user levels
        - TODO: onInf ( nick change, etc )
        
        - v0.09: by pulsar
            - possibility to choose which levels should be tagged
            - caching some new table lookups

        - v0.08: by pulsar
            - new feature: activate / deactivate script

        - v0.07: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        - v0.06: by pulsar
            - no white spaces anymore

        - v0.05: by blastbeat
            - updated script api

        - v0.04: by blastbeat
            - updated script api, fixed bugs

]]--


--// settings begin //--

local scriptname = "usr_nick_prefix"
local scriptversion = "0.09"

--// settings end //--


--// caching table lookups
local cfg_get = cfg.get
local hub_debug = hub.debug
local hub_getusers = hub.getusers
local hub_escapeto = hub.escapeto
local utf_len = utf.len
local utf_sub = utf.sub

--// imports
local prefix_activate = cfg_get( "usr_nick_prefix_activate" )
local prefix_table = cfg_get( "usr_nick_prefix_prefix_table" )
local permission = cfg_get( "usr_nick_prefix_permission" )


local default = hub_escapeto( "[UNKNOWN]" )    -- default nick prefix

if prefix_activate then

    hub.setlistener( "onStart", { },    -- add prefix to already connected users
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if permission[ user:level() ] then
                    local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
                    user:updatenick( prefix .. user:nick() )
                end
            end
            return nil
        end
    )

    hub.setlistener( "onInf", { },    -- add prefix to already connected users
        function( user, cmd )
            if cmd:getnp "NI" then
                if permission[ user:level() ] then
                    local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
                    user:updatenick( prefix .. user:nick() )
                    return PROCESSED
                end
            end
            return nil
        end
    )

    hub.setlistener( "onExit", { },    -- remove prefix on script exit
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if permission[ user:level() ] then
                    local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
                    local original_nick = utf_sub( user:nick(), utf_len( prefix ) + 1, -1 )
                    user:updatenick( original_nick, false, true )
                end
            end
            return nil
        end
    )

    hub.setlistener( "onConnect", { },    -- add prefix to connecting user
        function( user )
            local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
            local bol, err = user:updatenick( prefix .. user:nick(), true )
            if permission[ user:level() ] then
                if not bol then
                    user:kill( "ISTA 220 " .. hub_escapeto( err ) .. "\n" )
                    return PROCESSED
                end
            end
            return nil
        end
    )

end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )