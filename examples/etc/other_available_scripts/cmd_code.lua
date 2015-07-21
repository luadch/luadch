--[[

        cmd_code.lua v0.05 by blastbeat

        - this script adds a command "code" to bypass char/word replacer
        - usage: [+!#]code <message>

        - changelog 0.05:
          - updated script api
          - regged hubcommand

        - changelog 0.04:
          - some clean ups

        - changelog 0.03:
          - added language files and ucmd

        - changelog 0.02:
          - added usercommand and language file

]]--

--// settings begin //--

local scriptname = "cmd_code"
local scriptversion = "0.05"

local cmd = "code"

local minlevel = 0    -- minimum level to get the help/ucmd

--// settings end //--

local utf_match = utf.match

local hub_broadcast = hub.broadcast

--// language //--

local scriptlang = cfg.get "language"

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "code"
local help_usage = lang.help_usage or "[+!#]code <message>"
local help_desc = lang.help_desc or "sends <message> in mainchat; example: '+code www.google.de' will exactly send '+code www.google.de'; chars or words wont be replaced"

local ucmd_menu = lang.ucmd_menu or { "Send Code/Link" }
local ucmd_what = lang.ucmd_what or "What"

local hubcmd

local onbmsg = function( user, command, parameters, txt )
    hub_broadcast( txt, user )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_what .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )