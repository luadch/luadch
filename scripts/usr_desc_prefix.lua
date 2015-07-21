--[[

    usr_desc_prefix.lua

        - this script adds a prefix to the desc of an user
        - you can use the prefix table to define different prefixes for different user levels

        - v0.07: by pulsar
            - possibility to choose which levels should be tagged
            - caching some new table lookups
        
        - v0.06: by pulsar
            - new feature: activate / deactivate script

        - v0.05: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        - v0.04: by blastbeat
            - updated script api

        - v0.03: by blastbeat
            - some fixes

        - v0.02: by blastbeat
            - updated script api

]]--


--// settings begin //--

local scriptname = "usr_desc_prefix"
local scriptversion = "0.07"

--// settings end //--


--// caching table lookups
local cfg_get = cfg.get
local hub_debug = hub.debug
local hub_escapeto = hub.escapeto
local hub_getusers = hub.getusers
local hub_sendtoall = hub.sendtoall
local utf_len = utf.len
local utf_sub = utf.sub

--// imports
local prefix_activate = cfg_get( "usr_desc_prefix_activate" )
local prefix_table = cfg_get( "usr_desc_prefix_prefix_table" )
local permission = cfg_get( "usr_desc_prefix_permission" )


local default = hub_escapeto( "[ UNKNOWN ] " )    -- default nick prefix

if prefix_activate then

    hub.setlistener( "onStart", { },    -- add prefix to already connected users
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if permission[ user:level() ] then
                    local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
                    local desc = prefix .. ( user:description( ) or "" )
                    user:inf():setnp( "DE", desc )
                    hub_sendtoall( "BINF " .. sid .. " DE" .. desc .. "\n" )
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
                    local desc = utf_sub( user:description(), utf_len( prefix ) + 1, -1 )
                    user:inf():setnp( "DE", desc or "" )
                    hub_sendtoall( "BINF " .. sid .. " DE" .. desc .. "\n" )
                end
            end
            return nil
        end
    )

    hub.setlistener( "onInf", { },    -- add prefix to incoming inf
        function( user, cmd )
            local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
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
            local prefix = hub_escapeto( prefix_table[ user:level() ] ) or default
            if permission[ user:level() ] then
                user:inf():setnp( "DE", prefix .. ( user:description( ) or "" ) )
            end
            return nil
        end
    )

end


hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )