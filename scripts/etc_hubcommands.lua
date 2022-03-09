--[[

        etc_hubcommands.lua v0.03 by blastbeat

        v0.03: by blastbeat
            - improve error handling   

        v0.02: by pulsar
            - add support for multiple commands, usage: hubcmd.add( { cmd1, cmd2, cmd3 ... }, onbmsg )

        v0.01: by blastbeat
            - this script exports a module to reg hubcommands

]]--

--// settings begin //--

--// settings end //--

local scriptname = "etc_hubcommands"
local scriptversion = "0.03"

local utf_match = utf.match
local hub_getbot = hub.getbot

local commands = { }

local reg_cmd = function( cmd, func )
    if ( type( cmd ) == "string" ) and ( type( func ) == "function" ) then
        if commands[ cmd ] then
            return false -- name is already registered
        end
        commands[ cmd ] = func
        return true
    end
    return false
end

local add = function( cmd, func ) -- quick and dirty...
    if type( cmd ) == "string" then
        cmd = { cmd }
    end
    if type( cmd ) == "table" then
        for _, name in pairs( cmd ) do
            if not reg_cmd( name, func ) then
                return false
            end
        end
        return true
    end
    return false
end

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local cmd, parameters = utf_match( txt, "^[+!#](%a+) ?(.*)" )
        local func = commands[ cmd ]
        if func then
            user:reply( "[command] " .. txt, hub_getbot( ) )
            return func( user, cmd, parameters, txt )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

--// public //--

return {

    add = add,

}
