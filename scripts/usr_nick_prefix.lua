--[[

    usr_nick_prefix.lua by blastbeat

        - this script adds a prefix to the nick of an user
        - you can use the prefix table to define different prefixes for different user levels
        - TODO: onInf ( nick change, etc )

        v0.12: by pulsar
            - removed table lookups
            - simplify 'activate' logic

        v0.11: by pulsar
            - imroved user:kill()

        v0.10: by pulsar
            - small bugfix  / thx Sopor
            - code cleaning

        v0.09: by pulsar
            - possibility to choose which levels should be tagged
            - caching some new table lookups

        v0.08: by pulsar
            - new feature: activate / deactivate script

        v0.07: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.06: by pulsar
            - no white spaces anymore

        v0.05: by blastbeat
            - updated script api

        v0.04: by blastbeat
            - updated script api, fixed bugs

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_nick_prefix"
local scriptversion = "0.12"

--// imports
local activate = cfg.get( "usr_nick_prefix_activate" )
local prefix_table = cfg.get( "usr_nick_prefix_prefix_table" )
local permission = cfg.get( "usr_nick_prefix_permission" )


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local default = hub.escapeto( "[UNKNOWN]" )  -- default nick prefix

-- add prefix to already connected users
hub.setlistener( "onStart", { },
    function( )
        for sid, user in pairs( hub.getusers() ) do
            if permission[ user:level() ] then
                local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
                user:updatenick( prefix .. user:nick() )
            else
                user:updatenick( user:nick() )
            end
        end
        return nil
    end
)

-- add prefix to already connected users
hub.setlistener( "onInf", { },
    function( user, cmd )
        if cmd:getnp "NI" then
            if permission[ user:level() ] then
                local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
                user:updatenick( prefix .. user:nick() )
                return PROCESSED
            end
        end
        return nil
    end
)

-- remove prefix on script exit
hub.setlistener( "onExit", { },
    function( )
        for sid, user in pairs( hub.getusers() ) do
            if permission[ user:level() ] then
                local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
                local original_nick = utf.sub( user:nick(), utf.len( prefix ) + 1, -1 )
                user:updatenick( original_nick, false, true )
            end
        end
        return nil
    end
)

-- add prefix to connecting user
hub.setlistener( "onConnect", { },
    function( user )
        if permission[ user:level() ] then
            local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
            local bol, err = user:updatenick( prefix .. user:nick(), true )
            if not bol then
                -- disable to prevent spam; remember: never fire listenter X inside listener X; will cause infinite loop
                --scripts.firelistener( "onFailedAuth", user:nick( ), user:ip( ), user:cid( ), "Nick prefix failed: " .. err ) -- todo: i18n
                user:kill( "ISTA 220 " .. hub.escapeto( err ) .. "\n", "TL300" )
                return PROCESSED
            end
        end
        return nil
    end
)


hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
