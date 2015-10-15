--[[

    hub_runtime.lua by pulsar

        description: this script saves the hub runtime and adds a command to show/reset the hub runtime

        usage: [+!#]runtime show|reset

        v0.4:
            - added "get_hubruntime()" function
            - added "reset_hubruntime()" function
            - added help, ucmd
            - added report

        v0.3:
            - small fix

        v0.2:
            - using new luadch date style

        v0.1:
            - saves the hub runtime

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_runtime"
local scriptversion = "0.4"

local cmd = "runtime"
local cmd_p1 = "show"
local cmd_p2 = "reset"

local file = "core/hci.lua"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_import = hub.import
local hub_debug = hub.debug
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_date = util.date
local util_difftime = util.difftime
local util_convertepochdate = util.convertepochdate
local util_formatseconds = util.formatseconds
local utf_format = utf.format
local utf_match = utf.match
local os_time = os.time
local os_difftime = os.difftime
local math_floor = math.floor

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local minlevel = cfg_get( "hub_runtime_minlevel" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "hub_runtime_report" )
local report_opchat = cfg_get( "hub_runtime_report_opchat" )
local report_hubbot = cfg_get( "hub_runtime_report_hubbot" )
local llevel = cfg_get( "hub_runtime_llevel" )

--// msgs
local help_title = lang.help_title or "hub_runtime.lua"
local help_usage = lang.help_usage or "[+!#]runtime show|reset"
local help_desc = lang.help_desc or "Show/reset the hub runtime"

local msg_runtime = lang.msg_runtime or "Hub runtime: %s"
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

--// functions
local get_hubruntime, set_hubruntime, reset_hubruntime, onbmsg

----------
--[CODE]--
----------

local hci_tbl
local minutes = 5
local delay = minutes * 60
local start = os_time()

get_hubruntime = function()
    hci_tbl = util_loadtable( file )
    local hrt = hci_tbl.hubruntime
    local formatdays = function( d )
        return math_floor( d / 365 ), math_floor( d ) % 365
    end
    local d, h, m, s = util_formatseconds( hrt )
    if d > 365 then
        local years, days = formatdays( d )
        d = years .. msg_years .. days
    end
    hrt = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hrt
end

set_hubruntime = function()
    hci_tbl = util_loadtable( file )
    local hrt = hci_tbl.hubruntime
    local hrt_lc = hci_tbl.hubruntime_last_check
    if hrt_lc == 0 then hrt_lc = util_date() end
    local hrt_lc_str = tostring( hrt_lc )
    if #hrt_lc_str ~= 14 then hrt_lc = util_convertepochdate( hrt_lc ) end
    local sec, y, d, h, m, s = util_difftime( util_date(), hrt_lc )
    local new_time = hrt + sec
    hci_tbl.hubruntime = new_time
    hci_tbl.hubruntime_last_check = util_date()
    util_savetable( hci_tbl, "hci_tbl", file )
end

reset_hubruntime = function()
    hci_tbl = util_loadtable( file )
    hci_tbl.hubruntime = 0
    util_savetable( hci_tbl, "hci_tbl", file )
end

hub.setlistener( "onTimer", {},
    function()
        if os_difftime( os_time() - start ) >= delay then
            set_hubruntime()
            start = os_time()
        end
        return nil
    end
)

onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local user_firstnick = user:firstnick()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(%S+)$" )
    if param == cmd_p1 then
        user:reply( utf_format( msg_runtime, get_hubruntime() ), hub_getbot )
        return PROCESSED
    end
    if param == cmd_p2 then
        reset_hubruntime()
        user:reply( msg_reset_1, hub_getbot )
        local msg = utf_format( msg_reset_2, user_firstnick )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
        return PROCESSED
    end
    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_show, cmd, { cmd_p1 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_reset, cmd, { cmd_p2 }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )