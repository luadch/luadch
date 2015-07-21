--[[

    etc_usercommands.lua by blastbeat

        v0.03: by blastbeat
            - added some dynamic ucmd testing...
                - usage: user.write( ucmd.format( ... ) )

        v0.02: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.01: by blastbeat
            - this script exports a module to reg usercommands

]]--

--// settings begin //--

local scriptname = "etc_usercommands"
local scriptversion = "0.03"

--// settings end //--

local cfg_get = cfg.get
local utf_match = utf.match
local hub_escapeto = hub.escapeto
local hub_debug = hub.debug
local table_insert = table.insert
local table_concat = table.concat

local toplevelmenu = cfg_get( "etc_usercommands_toplevelmenu" )

local commands = { }
local level = { }

local sep = [[/]]    -- accordings the UCMD specs

local format = function( menu, command, params, flags, llevel )
    table_insert( menu, 1, toplevelmenu )
    local menu = hub_escapeto( table_concat( menu, sep ) )    -- create ucmd name with submenus
    local ucmd = "ICMD " .. menu
    --hub.debug( ucmd )
    ucmd = ucmd .. " TTBMSG\\s%[mySID]\\s+"
    ucmd = ucmd .. hub_escapeto( hub_escapeto( command .. " " .. table_concat( params, " " ) ) .. "\n" )
    ucmd = ucmd .. " " .. table_concat( flags, " " ) .. "\n"
    return ucmd
end

local add = function( menu, command, params, flags, llevel )    -- quick and dirty...
    local ucmd = format( menu, command, params, flags, llevel )
    assert( not level[ ucmd ] )    -- names are unique
    level[ ucmd ] = llevel
    commands[ #commands + 1 ] = ucmd
end

hub.setlistener( "onLogin", { },
    function( user )
        local userlevel = user:level( )
        for i, ucmd in ipairs( commands ) do
            if level[ ucmd ] <= userlevel then
                user.write( ucmd )
            end
        end
        return nil
    end
)

--[[ test
hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local cmd, menu = utf_match( txt, "^[+!#](%a+) ?(.*)" )
        if cmd == "ucmdtest" then
            user:reply( "[ucmd test!] " .. txt, hub.getbot( ) )
            local ucmd = format( { menu }, "", { }, { "CT1" } )
            user.write( ucmd )
            return PROCESSED
        end
        return nil
    end
)
]]

hub_debug( "** Loaded " .. scriptname .. " ".. scriptversion .. " **" )

--// public //--

return {

    format = format,
    add = add,

}