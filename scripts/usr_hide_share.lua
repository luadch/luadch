--[[

    usr_hide_share.lua by pulsar

        Usage: [+!#]hideshare <NICK>

        v0.4:
            - removed table lookups
            - simplify 'activate' logic

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
local scriptversion = "0.4"

local cmd = "hideshare"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local activate = cfg.get( "usr_hide_share_activate" )
local permission = cfg.get( "usr_hide_share_permission" )
local restrictions = cfg.get( "usr_hide_share_restrictions" )

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

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local hide_share_tbl = util.loadtable( path )
local oplevel = util.getlowestlevel( permission )
local share = "0"

--// check user on listener
checkOnListener = function( user, cmdx, se )
    if restrictions[ user:level() ] or hide_share_tbl[ user:firstnick() ] then
        if cmdx then cmdx:setnp( "SS", share ) end
        user:inf():setnp( "SS", share )
        if se then hub.sendtoall( "BINF " .. user:sid() .. " SS" .. share .. "\n" ) end
    end
end

--// check user by using command
checkOnCommand = function( user, target )
    if restrictions[ target:level() ] then
        user:reply( msg_default, hub.getbot() )
    else
        if type( hide_share_tbl[ target:firstnick() ] ) == "nil" then
            --// add user to db
            hide_share_tbl[ target:firstnick() ] = 1
            util.savetable( hide_share_tbl, "hide_share_tbl", path )
            --// target share flag manipulation
            target:inf():setnp( "SS", share )
            hub.sendtoall( "BINF " .. target:sid() .. " SS" .. share .. "\n" )
            --// report
            target:reply( utf.format( msg_hide_target, user:nick() ), hub.getbot() )
            user:reply( utf.format( msg_hide_user, target:nick() ), hub.getbot() )
        else
            --// remove user from db
            hide_share_tbl[ target:firstnick() ] = nil
            util.savetable( hide_share_tbl, "hide_share_tbl", path )
            --// report & disconnect
            target:kill( "ISTA 230 " .. hub.escapeto( utf.format( msg_unhide_target, user:nick() ) ) .. "\n", "TL300" )
            user:reply( utf.format( msg_unhide_user, target:nick() ), hub.getbot() )
        end
    end
end

hub.setlistener( "onStart", {},
    function()
        --// help, ucmd, hucmd
        local help = hub.import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, oplevel ) end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct2_1, cmd, { "%[userNI]" }, { "CT2" }, oplevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        --// hide share
        for sid, user in pairs( hub.getusers() ) do
            checkOnListener( user, false, true )
        end
        return nil
    end
)

hub.setlistener( "onExit", {},
    function()
        for sid, user in pairs( hub.getusers() ) do
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
    local param = utf.match( parameters, "^(%S+)" )
    --// [+!#]hideshare <NICK>
    if param then
        if user_level < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        local target = hub.isnickonline( param )
        if target then
            if not target:isbot() then
                checkOnCommand( user, target )
            else
                user:reply( msg_isbot, hub.getbot() )
            end
        else
            user:reply( msg_notonline, hub.getbot() )
        end
        return PROCESSED
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )