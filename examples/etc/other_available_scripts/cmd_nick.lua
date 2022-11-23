--[[

        cmd_nick.lua v0.03 by blastbeat

        - this script adds a command "nick" to change nick
        - usage: [+!#]nick <nick>
        - note: after changing your nick as regged user, you maybe have to login in again to get your old nick
        - note: in general this script maybe have some unexpected side effects; use with care =)

        - IMPORTANT: depends on following scripts:
          - etc_help.lua
          - etc_usercommands.lua

        - changelog 0.03:
          - added language files and ucmd

        - changelog 0.02:
          - updated script api

]]--

--// settings begin //--

local scriptname = "cmd_nick"
local scriptversion = "0.03"

local minlevel = 20

local permission = {    -- who is allowed to use this command?
    
    [ 0 ] =  false,  -- unreg
    [ 10 ] = false,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner

}

local cmd = "nick"

--// settings end //--

local nick_change = cfg.get "nick_change"

local utf_match = utf.match

local scriptlang = cfg.get "language"

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local msg_denied = lang.msg_denied or  "Changing nick is not allowed here."
local msg_usage = lang.msg_usage or "Usage: +nick <nick>"
local msg_error = lang.msg_error or "An error occurred: "
local msg_ok = lang.msg_ok or "Your nick was changed to: "

local help_title = lang.help_title or "nick"
local help_usage = lang.help_usage or "[+!#]nick <nick>"
local help_desc = lang.help_desc or "changes your nick to <nick>"

local ucmd_menu = lang.ucmd_menu or { "Change nick" }
local ucmd_nick = lang.ucmd_nick or "Nick:"

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, minlevel )
        end
        return nil
    end
)

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local command, parameters = utf_match( txt, "^[+!#](%a+) ?(.*)" )
        if command == cmd then
            if not nick_change then
                user:reply( msg_denied, hub.getbot( ) )
                return PROCESSED
            end
            local new_nick = hub.escapeto( parameters )
            if not new_nick then
                user:reply( msg_usage, hub.getbot( ) )
                return PROCESSED
            end
            local bol, err = user:updatenick( new_nick )
            if bol then
                user:reply( msg_ok .. new_nick, hub.getbot( ) )
                if user:isregged( ) then
                    --p.user:setregnick( new_nick )    -- this doesn't work as expected at the moment
                end
            else
                user:reply( msg_error .. ( err or "" ), hub.getbot( ) )
            end
            return PROCESSED
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )