--[[

	cmd_uptime.lua by Night

        usage: [+!#]uptime

        v0.9: by pulsar
            - added "years" to util.formatseconds
                - removed formatdays()
                - changed get_lastconnect(), get_hubuptime(), get_hubruntime()

        v0.8: by pulsar
            - added check_hci() function
            - removed table lookups

        v0.7: by pulsar
            - changes in get_hubuptime() and get_hubruntime()

        v0.6: by pulsar
            - using new luadch date style

        v0.5: by pulsar
            - shows the complete hub runtime since the first hubstart

        v0.4: by pulsar
            - improved get_hubuptime() and get_lastconnect() function

        v0.3: by pulsar
            - add users uptime
            - change output style
            - code cleanup

        v0.2: by pulsar
            - added multilanguage support
            - completed some code

        v0.1: by Night
            - adds uptime command

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_uptime"
local scriptversion = "0.9"

local cmd = "uptime"

--// imports
local help, hubcmd
local minlevel = cfg.get( "cmd_uptime_minlevel" )
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local hci_file = "core/hci.lua"
local hci_tbl = util.loadtable( hci_file )

--// msgs
local help_title = lang.help_title or "uptime"
local help_usage = lang.help_usage or "[+!#]uptime"
local help_desc = lang.help_desc or "Show hub uptime"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."

local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"

local msg_unknown = lang.msg_unknown or "<unknown>"

local msg_uptime = lang.msg_uptime or [[


=== UPTIME ==========================================================

                  Hub uptime (complete):  %s
                  Hub uptime (session):  %s

                  Your uptime:  %s

========================================================== UPTIME ===
  ]]


----------
--[CODE]--
----------

local check_hci = function()
    if type( hci_tbl ) ~= "table" then
        hci_tbl = { [ "hubruntime" ] = 0, [ "hubruntime_last_check" ] = 0, }
        util.savetable( hci_tbl, "hci_tbl", hci_file )
    end
end

check_hci()

local get_lastconnect = function( user )
    local lastconnect
    local profile = user:profile()
    local lc = profile.lastconnect
    local lc_str = tostring( lc )
    if not lc then
        lastconnect = msg_unknown
    else
        if #lc_str == 14 then
            local sec, y, d, h, m, s = util.difftime( util.date(), lc )
            lastconnect = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local y, d, h, m, s = util.formatseconds( os.difftime( os.time(), lc ) )
            lastconnect = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    end
    return lastconnect
end

local get_hubuptime = function()
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

local get_hubruntime = function()
    local hubruntime = hci_tbl.hubruntime
    local y, d, h, m, s = util.formatseconds( hubruntime )
    return y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
end

local onbmsg = function( user )
    local user_level = user:level()
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
	local msg = utf.format( msg_uptime, get_hubruntime(), get_hubuptime(), get_lastconnect( user ) )
    user:reply( msg, hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub.import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )