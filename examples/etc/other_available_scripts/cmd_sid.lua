--[[

        cmd_sid.lua v0.02 by blastbeat

        - this script adds a command "+sid" to get the sid of an user
        - usage: [+!#]sid nick|cid <nick>|<cid>

        - changelog 0.02:
          - updated script api

]]--

--// settings begin //--

local scriptname = "cmd_sid"
local scriptversion = "0.02"

local permission = {    -- who is allowed to use this command?

    [ 0 ] = false,  -- unreg
    [ 10 ] = false,  -- guest
    [ 20 ] = false,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner

}

local cmd_options = {

    nick = "nick",
    cid = "cid",

}

local msg_denied = "You are not allowed to use this command."
local msg_usage = "Usage: +sid [+!#]sid nick|cid <nick>|<cid>"
local msg_error = "No corresponding SID found."
local msg_ok = "SID of user: "

local cmd = "sid"

--// settings end //--

local utf_match = utf.match

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( "sid", "[+!#]sid nick|cid <nick>|<cid>", "shows sid of user by nick or cid", 30 )
        end
        return nil
    end
)

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local command, parameters = utf_match( txt, "^[+!#](%a+) ?(.*)" )
        if command == cmd then
            if not permission[ user:level( ) ] then
                user:reply( msg_denied, hub.getbot( ) )
                return PROCESSED
            end
            local option, arg = utf.match( parameters, "^(%S+) (.*)" )
            if not ( option and arg ) or not cmd_options[ option ] then
                user:reply( msg_usage, hub.getbot( ) )
                return PROCESSED
            end
            local target_user = (
            option == "nick" and hub.isnickonline( arg ) ) or
            ( option == "sid" and hub.issidonline( arg ) ) or
            ( option == "cid" and hub.iscidonline( arg ) )
            if not target_user then
                user:reply( msg_error, hub.getbot( ) )
            else
                user:reply( msg_ok .. target_user:sid( ), hub.getbot( ) )
            end
            return PROCESSED
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )