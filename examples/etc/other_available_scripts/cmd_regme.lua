--[[

        cmd_regme.lua v0.04 by blastbeat

        - this script adds a command "regme" to let users themselfs
        - usage: [+!#]regme <password>

        - changelog 0.04:
          - updated script api
          - regged hubcommand

        - changelog 0.03:
          - some clean ups

        - changelog 0.02:
          - added language files and ucmd

]]--

--// settings begin //--

local scriptname = "cmd_regme"
local scriptversion = "0.04"
local scriptlang = cfg.get "language"

local reglevel = 10    -- level to reg
local permission = true    -- permission to all

local cmd = "regme"

--// settings end //--

local utf_match = utf.match

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "regme"
local help_usage = lang.help_usage or "[+!#]regme <password>"
local help_desc = lang.help_desc or "let users reg themselfs"

local ucmd_menu = lang.ucmd_menu or { "Regme" }
local ucmd_what = lang.ucmd_what or "Password:"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: +regme <password>"
local msg_error = lang.msg_error or "An error occured: "
local msg_ok = lang.msg_ok or "You are regged with following parameters: "

local hubcmd

local onbmsg = function( user, command, parameters )
    local user_level = user:level( )
    if not permission then
        user:reply( msg_denied, hub.getbot( ) )
        return PROCESSED
    end
    local password = utf_match( parameters, "^(%S+)" )
    if not password then
        user:reply( msg_usage, hub.getbot( ) )
        return PROCESSED
    end
    local levels = cfg.get "levels" or { }
    local bol, err = hub.reguser{ nick = user:firstnick( ), password = password, level = reglevel, by = user:nick( ) }
    if not bol then
        user:reply( msg_error .. ( err or "" ), hub.getbot( ) )
    else
        user:reply( msg_ok .. user:firstnick( ) .. " " .. password .. " " .. reglevel, hub.getbot( ) )
    end
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help and permission then
            help.reg( help_title, help_usage, help_desc, 0 )
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_what .. "]" }, { "CT1" }, 0 )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )