--[[

        cmd_showdoc.lua v0.01 by blastbeat

        - this script adds a command "showdoc" to show documentation about luadch
        - usage: [+!#]showdoc

]]--

--// settings begin //--

local scriptname = "cmd_showdoc"
local scriptversion = "0.01"

local permission = {    -- who is allowed to use this command?

    [ 0 ] = false,  -- unreg
    [ 10 ] = false,  -- guest
    [ 20 ] = false,  -- reg
    [ 30 ] = false,  -- vip
    [ 40 ] = false,  -- svip
    [ 50 ] = false,  -- server
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner

}

local msg_denied = "You are not allowed to use this command."

local cmd = "showdoc"

--// settings end //--

local utf_match = utf.match

local hub_getbot = hub.getbot

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( "showdoc", "[+!#]showdoc", "sends the luadch docs to pm", 60 )
        end
        return nil
    end
)

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local command = utf_match( txt, "^[+!#](%a+)" )
        if command == cmd then
            if not permission[ user:level( ) ] then
                user:reply( msg_denied, hub.getbot( ) )
                return PROCESSED
            end
            user:reply( doc.collect( ), hub_getbot( ), hub_getbot( ) )
            return PROCESSED
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )