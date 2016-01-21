--[[

    usr_hide_share.lua by pulsar

        Usage: [+!#]hideshare <NICK>

        v0.3:
            - imroved user:kill()

        v0.2:
            - added help, lang
            - possibility to manually hide/unhide usershares
                - added ucmd, onbmsg
                - renamed "usr_hide_share_permission" to "usr_hide_share_restrictions"
                - using "usr_hide_share_permission" for cmd permissions
            - some english translation improvements  / thx Devious

        v0.1:
            - this script hides share of specified levels

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_hide_share"
local scriptversion = "0.3"

local cmd = "hideshare"

----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// caching table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_getusers = hub.getusers
local hub_isnickonline = hub.isnickonline
local hub_import = hub.import
local hub_sendtoall = hub.sendtoall
local hub_escapeto = hub.escapeto
local utf_match = utf.match
local utf_format = utf.format
local util_getlowestlevel = util.getlowestlevel
local util_loadtable = util.loadtable
local util_savetable = util.savetable

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local activate = cfg_get( "usr_hide_share_activate" )
local permission = cfg_get( "usr_hide_share_permission" )
local restrictions = cfg_get( "usr_hide_share_restrictions" )

local path = "scripts/data/usr_hide_share.tbl"

--// msgs
local help_title = lang.help_title or "usr_hide_share.lua"
local help_usage = lang.help_usage or "[+!#]hideshare <NICK>"
local help_desc = lang.help_desc or "Hide/unhide the share of a user"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_isbot = lang.msg_isbot or "User is a bot."
local msg_notonline = lang.msg_notonline or "User is offline."
local msg_usage = lang.msg_usage or "Usage: [+!#]hideshare <NICK>"

local msg_default = lang.msg_default or "This user's share is hidden due to permission levels."
local msg_hide_user = lang.msg_hide_user or "Share hidden for: %s"
local msg_hide_target = lang.msg_hide_target or "Your share was hidden by: %s"
local msg_unhide_user = lang.msg_unhide_user or "Share restored for: %s  |  User was disconnected"
local msg_unhide_target = lang.msg_unhide_target or "Your share was restored by: %s  |  Therefore, you will be disconnected now"

local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Hide//unhide share", "OK" }

--// functions
local checkOnListener
local checkOnCommand
local onbmsg


----------
--[CODE]--
----------

local user_tbl = util_loadtable( path )
local oplevel = util_getlowestlevel( permission )
local share = "0"

--// check user on listener
checkOnListener = function( user, cmdx, se )
    if restrictions[ user:level() ] or user_tbl[ user:firstnick() ] then
        if cmdx then cmdx:setnp( "SS", share ) end
        user:inf():setnp( "SS", share )
        if se then hub_sendtoall( "BINF " .. user:sid() .. " SS" .. share .. "\n" ) end
    end
end

--// check user by using command
checkOnCommand = function( user, target )
    if restrictions[ target:level() ] then
        user:reply( msg_default, hub_getbot )
    else
        if type( user_tbl[ target:firstnick() ] ) == "nil" then
            --// add user to db
            user_tbl[ target:firstnick() ] = 1
            util_savetable( user_tbl, "user_tbl", path )
            --// target share flag manipulation
            target:inf():setnp( "SS", share )
            hub_sendtoall( "BINF " .. target:sid() .. " SS" .. share .. "\n" )
            --// report
            target:reply( utf_format( msg_hide_target, user:nick() ), hub_getbot )
            user:reply( utf_format( msg_hide_user, target:nick() ), hub_getbot )
        else
            --// remove user from db
            user_tbl[ target:firstnick() ] = nil
            util_savetable( user_tbl, "user_tbl", path )
            --// report & disconnect
            target:kill( "ISTA 230 " .. hub_escapeto( utf_format( msg_unhide_target, user:nick() ) ) .. "\n", "TL300" )
            user:reply( utf_format( msg_unhide_user, target:nick() ), hub_getbot )
        end
    end
end

if activate then
    hub.setlistener( "onStart", {},
        function()
            --// help, ucmd, hucmd
            local help = hub_import( "cmd_help" )
            if help then help.reg( help_title, help_usage, help_desc, oplevel ) end
            local ucmd = hub_import( "etc_usercommands" )
            if ucmd then
                ucmd.add( ucmd_menu_ct2_1, cmd, { "%[userNI]" }, { "CT2" }, oplevel )
            end
            local hubcmd = hub_import( "etc_hubcommands" )
            assert( hubcmd )
            assert( hubcmd.add( cmd, onbmsg ) )
            --// hide share
            for sid, user in pairs( hub_getusers() ) do
                checkOnListener( user, false, true )
            end
            return nil
        end
    )
    hub.setlistener( "onExit", {},
        function()
            for sid, user in pairs( hub_getusers() ) do
                checkOnListener( user, false, true )
            end
            return nil
        end
    )
    hub.setlistener( "onInf", {},
        function( user, cmdx )
            checkOnListener( user, cmdx, false )
            return nil
        end
    )
    hub.setlistener( "onConnect", {},
        function( user )
            checkOnListener( user, false, false )
            return nil
        end
    )
    onbmsg = function( user, command, parameters )
        local user_nick, user_level = user:nick(), user:level()
        local target_nick, target_firstnick, target_level
        local param = utf_match( parameters, "^(%S+)" )
        --// [+!#]hideshare <NICK>
        if param then
            if user_level < oplevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            local target = hub_isnickonline( param )
            if target then
                if not target:isbot() then
                    checkOnCommand( user, target )
                else
                    user:reply( msg_isbot, hub_getbot )
                end
            else
                user:reply( msg_notonline, hub_getbot )
            end
            return PROCESSED
        end
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )