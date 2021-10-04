--[[

    usr_desc_prefix.lua by blastbeat

        - this script adds a prefix to the desc of an user
        - you can use the prefix table to define different prefixes for different user levels

        v0.08: by pulsar
            - removed table lookups
            - simplify 'activate' logic

        v0.07: by pulsar
            - possibility to choose which levels should be tagged
            - caching some new table lookups

        v0.06: by pulsar
            - new feature: activate / deactivate script

        v0.05: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.04: by blastbeat
            - updated script api

        v0.03: by blastbeat
            - some fixes

        v0.02: by blastbeat
            - updated script api

]]--


--// settings
local scriptname = "usr_desc_prefix"
local scriptversion = "0.08"

--// imports
local activate = cfg.get( "usr_desc_prefix_activate" )
local prefix_table = cfg.get( "usr_desc_prefix_prefix_table" )
local permission = cfg.get( "usr_desc_prefix_permission" )

--// code

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local default = hub.escapeto( "[ UNKNOWN ] " )    -- default nick prefix

hub.setlistener( "onStart", { },    -- add prefix to already connected users
    function( )
        for sid, user in pairs( hub.getusers() ) do
            if permission[ user:level() ] then
                local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
                local desc = prefix .. ( user:description( ) or "" )
                user:inf():setnp( "DE", desc )
                hub.sendtoall( "BINF " .. sid .. " DE" .. desc .. "\n" )
            end
        end
        return nil
    end
)

hub.setlistener( "onExit", { },    -- remove prefix on script exit
    function( )
        for sid, user in pairs( hub.getusers() ) do
            if permission[ user:level() ] then
                local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
                local desc = utf.sub( user:description(), utf.len( prefix ) + 1, -1 )
                user:inf():setnp( "DE", desc or "" )
                hub.sendtoall( "BINF " .. sid .. " DE" .. desc .. "\n" )
            end
        end
        return nil
    end
)

hub.setlistener( "onInf", { },    -- add prefix to incoming inf
    function( user, cmd )
        local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
        local desc = cmd:getnp "DE"
        if desc then
            if permission[ user:level() ] then
                local desc = prefix .. desc
                cmd:setnp( "DE", desc )
                user:inf():setnp( "DE", desc )
            end
        end
        return nil
    end
)

hub.setlistener( "onConnect", { },    -- add prefix to connecting user
    function( user )
        local prefix = hub.escapeto( prefix_table[ user:level() ] ) or default
        if permission[ user:level() ] then
            user:inf():setnp( "DE", prefix .. ( user:description( ) or "" ) )
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )