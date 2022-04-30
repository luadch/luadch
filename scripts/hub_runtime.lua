--[[

    hub_runtime.lua by pulsar

        description: this script saves the hub runtime and adds a command to show/reset the hub runtime

        usage: [+!#]runtime show|reset

        v0.7: by pulsar
            - added "years" to util.formatseconds
                - changed get_hubuptime(), get_hubruntime()

        v0.6: by pulsar
            - changed check_hci() function

        v0.5: by pulsar
            - removed table lookups
            - show session runtime too
            - fix #67 -> https://github.com/luadch/luadch/issues/67
                - added check_hci()

        v0.4: by pulsar
            - added "get_hubruntime()" function
            - added "reset_hubruntime()" function
            - added help, ucmd
            - added report

        v0.3: by pulsar
            - small fix

        v0.2: by pulsar
            - using new luadch date style

        v0.1: by pulsar
            - saves the hub runtime

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_runtime"
local scriptversion = "0.7"

local cmd = "runtime"
local cmd_p1 = "show"
local cmd_p2 = "reset"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local minlevel = cfg.get( "hub_runtime_minlevel" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "hub_runtime_report" )
local report_opchat = cfg.get( "hub_runtime_report_opchat" )
local report_hubbot = cfg.get( "hub_runtime_report_hubbot" )
local llevel = cfg.get( "hub_runtime_llevel" )
local hci_file = "core/hci.lua"
local hci_tbl = util.loadtable( hci_file )

--// msgs
local help_title = lang.help_title or "hub_runtime.lua"
local help_usage = lang.help_usage or "[+!#]runtime show|reset"
local help_desc = lang.help_desc or "Show/reset the hub runtime"

local msg_runtime = lang.msg_runtime or [[


=== RUNTIME ============================================================

               Hub runtime - Session:   %s
               Hub runtime - Complete: %s

============================================================ RUNTIME ===
  ]]

local msg_reset_1 = lang.msg_reset_1 or "Hub runtime was reset."
local msg_reset_2 = lang.msg_reset_2 or "Hub runtime has been reset by: %s"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]runtime show|reset"

local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"

local ucmd_menu_show = lang.ucmd_menu_show or { "Hub", "Core", "Hub runtime", "show" }
local ucmd_menu_reset = lang.ucmd_menu_reset or { "Hub", "Core", "Hub runtime", "reset", "OK" }

local msg_unknown = lang.msg_unknown or "<UNKNOWN>"

--// functions
local check_hci, get_hubuptime, get_hubruntime, set_hubruntime, reset_hubruntime, onbmsg


----------
--[CODE]--
----------

local minutes = 1
local delay = minutes * 60
local start = os.time()

check_hci = function()
    if type( hci_tbl ) ~= "table" then
        hci_tbl = { [ "hubruntime" ] = 0, [ "hubruntime_last_check" ] = 0, }
        util.savetable( hci_tbl, "hci_tbl", hci_file )
    end
end

check_hci()

get_hubuptime = function()
    local hubuptime
    local start = signal.get( "start" ) or os.time()
    if not start then
        hubuptime = msg_unknown
    else
        local y, d, h, m, s = util.formatseconds( os.difftime( os.time(), start ) )
        hubuptime = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    end
    return hubuptime
end

get_hubruntime = function()
    local hrt = hci_tbl.hubruntime
    local y, d, h, m, s = util.formatseconds( hrt )
    hrt = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hrt
end

set_hubruntime = function()
    local hrt = hci_tbl.hubruntime
    local hrt_lc = hci_tbl.hubruntime_last_check
    if hrt_lc == 0 then hrt_lc = util.date() end
    local hrt_lc_str = tostring( hrt_lc )
    if #hrt_lc_str ~= 14 then hrt_lc = util.convertepochdate( hrt_lc ) end
    local sec, y, d, h, m, s = util.difftime( util.date(), hrt_lc )
    local new_time = hrt + sec
    hci_tbl.hubruntime = new_time
    hci_tbl.hubruntime_last_check = util.date()
    util.savetable( hci_tbl, "hci_tbl", hci_file )
end

reset_hubruntime = function()
    hci_tbl.hubruntime = 0
    util.savetable( hci_tbl, "hci_tbl", hci_file )
end

hub.setlistener( "onTimer", {},
    function()
        if os.difftime( os.time() - start ) >= delay then
            set_hubruntime()
            start = os.time()
        end
        return nil
    end
)

onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local user_firstnick = user:firstnick()
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local param = utf.match( parameters, "^(%S+)$" )
    if param == cmd_p1 then
        user:reply( utf.format( msg_runtime, get_hubuptime(), get_hubruntime() ), hub.getbot() )
        return PROCESSED
    end
    if param == cmd_p2 then
        reset_hubruntime()
        user:reply( msg_reset_1, hub.getbot() )
        local msg = utf.format( msg_reset_2, user_firstnick )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
        return PROCESSED
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_show, cmd, { cmd_p1 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_reset, cmd, { cmd_p2 }, { "CT1" }, minlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )