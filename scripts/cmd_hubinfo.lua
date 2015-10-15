--[[

    cmd_hubinfo.lua by pulsar

        usage: [+!#]hubinfo

        v0.18:
            - removed fallback string from "use_ssl" var

        v0.17:
            - added TLS Mode  / requested by Tork

        v0.16:
            - prevent possible unknown "uname" outputs on windows systems
                - changes in check_os()
                - changes in check_cpu()
                - changes in check_ram_total()
                - changes in check_ram_free()

        v0.15:
            - increase performance by caching functions on start
            - show Ubuntu version
            - show Debian Version
            - show Raspbian Version

        v0.14:
            - shows the complete hub runtime since the first hubstart

        v0.13:
            - recognize Debian, Raspbian, Ubuntu
            - rewrite some parts of code

        v0.12:
            - added hub_website, hub_network, hub_owner

        v0.11:
            - removed function: convert_size()
                - now using: util.formatbytes()

        v0.10:
            - fix some code to prevent possible nil errors on some linux/unix machines
            - sort some parts of code

        v0.09:
            - fix the following functions to prevent possible nil errors if luadch has not the required permissions
              to get informations from the OS: check_os(), check_cpu(), check_ram_total(), check_ram_free()

        v0.08:
            - fix typo
            - shows hubshare

        v0.07:
            - changed visual output style

        v0.06:
            - small fix on cfg_get vars

        v0.05:
            - added "onlogin" feature

        v0.04:
            - add some useful functions to make things easyer / thx Night
            - shows hub_name, hub_hostaddress, tcp_ports, ssl_ports, use_ssl, use_keyprint, keyprint_type, keyprint_hash
            - shows better OS view
            - shows CPU
            - shows RAM total
            - shows RAM free

        v0.03:
            - rename cmd_version.lua to cmd_hubinfo.lua
            - code cleaning
            - shows copyright
            - shows uptime
            - shows amount of running scripts
            - shows memory usage
            - shows users regged total
            - shows online users total
            - shows online users regged
            - shows online users unreg
            - shows online users active
            - shows online users passive
            - shows operating system

        v0.02:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.01:
            - shows the hubversion

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_hubinfo"
local scriptversion = "0.18"

local cmd = "hubinfo"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// caching table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_formatseconds = util.formatseconds
local os_difftime = os.difftime
local os_time = os.time
local os_getenv = os.getenv
local signal_get = signal.get
local math_floor = math.floor
local string_find = string.find
local string_sub = string.sub
local string_match = string.match
local string_format = string.format
local io_popen = io.popen
local table_concat = table.concat
local util_formatbytes = util.formatbytes

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local minlevel = cfg_get( "cmd_hubinfo_minlevel" )
local onlogin = cfg_get( "cmd_hubinfo_onlogin" )
local hub_name = cfg_get( "hub_name" )
local hub_hostaddress = cfg_get( "hub_hostaddress" )
local tcp_ports = table_concat( cfg_get( "tcp_ports" ), ", " )
local ssl_ports = table_concat( cfg_get( "ssl_ports" ), ", " )
local use_ssl = cfg_get( "use_ssl" )
local use_keyprint = cfg_get( "use_keyprint" )
local keyprint_type = cfg_get( "keyprint_type" )
local keyprint_hash = cfg_get( "keyprint_hash" )
local hub_website = cfg_get( "hub_website" ) or ""
local hub_network = cfg_get( "hub_network" ) or ""
local hub_owner = cfg_get( "hub_owner" ) or ""
local ssl_params = cfg_get( "ssl_params" )

--// table constants from "core/const.lua"
local const_file = "core/const.lua"
local const_tbl = util_loadtable( const_file ) or {}
local const_PROGRAM = const_tbl[ "PROGRAM_NAME" ]
local const_VERSION = const_tbl[ "VERSION" ]
local const_COPYRIGHT = const_tbl[ "COPYRIGHT" ]

--// functions
local get_ssl_value
local get_tls_mode
local get_kp_value
local get_kp
local trim
local split
local onbmsg
local output
local check_uptime
local get_hubruntime
local check_script_amount
local check_mem_usage
local check_users
local check_os
local check_cpu
local check_ram_total
local check_ram_free
local check_hubshare

--// vars to cache functions (onStart listener)
local cache_get_kp_value
local cache_get_ssl_value
local cache_get_kp
local cache_check_script_amount
local cache_check_os
local cache_check_cpu
local cache_check_ram_total

--// msgs
local help_title = lang.help_title or "cmd_hubinfo.lua"
local help_usage = lang.help_usage or "[+!#]hubinfo"
local help_desc = lang.help_desc or "Sends a list of basic informations about the hub"

local ucmd_menu = lang.ucmd_menu or { "General", "Hubversion" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_unknown = lang.msg_unknown or "unknown"
local msg_out = lang.msg_out or [[


=== HUBINFO =====================================================================================

        [ HUB ]

        Hubname:  %s
        Address: %s
        ADC Port:  %s
        ADCS Port:  %s
        Use SSL:  %s
        TLS Mode:  %s
        Use Keyprint:  %s
        Keyprint:  %s

        Version:  %s %s
        Copyright:  %s

        Uptime (complete):  %s
        Uptime (session):  %s

        Running scripts:  %s
        Memory usage:  %s

        Hubshare:  %s

        Hub website:  %s
        Hub Network:  %s
        Hubowner:  %s

        [ USER ]

        Users regged total:  %s
        Online users total:  %s
        Online users regged:  %s
        Online users unreg:  %s
        Online users active:  %s
        Online users passive:  %s

        [ SYSTEM ]

        OS:     %s
        CPU:   %s
        RAM total:  %s
        RAM free:  %s

===================================================================================== HUBINFO ===
  ]]


----------
--[CODE]--
----------

--// vars
local s1, s2, s3, s4, s5, s6, s7, s8, s9, s10

--// get use_ssl value
get_ssl_value = function()
    if use_ssl then
        if scriptlang == "de" then
            return "JA"
        elseif scriptlang == "en" then
            return "YES"
        else
            return "YES"
        end
    else
        if scriptlang == "de" then
            return "NEIN"
        elseif scriptlang == "en" then
            return "NO"
        else
            return "NO"
        end
    end
    return msg_unknown
end

get_tls_mode = function()
    local TLS = ""
    if use_ssl then
        local tls_mode = ssl_params.protocol
        if tls_mode == "tlsv1" then TLS = "v1.0" else TLS = "v1.2" end
    end
    return TLS
end

--// get use_keyprint value
get_kp_value = function()
    if use_keyprint then
        if scriptlang == "de" then
            return "JA"
        elseif scriptlang == "en" then
            return "YES"
        else
            return "YES"
        end
    else
        if scriptlang == "de" then
            return "NEIN"
        elseif scriptlang == "en" then
            return "NO"
        else
            return "NO"
        end
    end
    return msg_unknown
end

--// get keyprint if use_keyprint is true
get_kp = function()
    if use_keyprint then
        return keyprint_type .. keyprint_hash
    end
    return ""
end

--// trim whitespaces from both ends of a string
trim = function( s )
    return string_find( s, "^%s*$" ) and "" or string_match( s, "^%s*(.*%S)" )
end

--// split strings  / by Night
split = function( s, delim, newline )
    local i = string_find( s, delim ) + 1
    if not i then
        i = 0
    end
    local j = string_find( s, newline, i ) - 1
    if not j then
        j = - 1
    end
    return string_sub( s, i, j )
end

--// uptime
check_uptime = function()
    local d, h, m, s = util_formatseconds( os_difftime( os_time(), signal_get( "start" ) ) )
    local hub_uptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hub_uptime
end

--// uptime complete
get_hubruntime = function()
    local hci_tbl = util_loadtable( "core/hci.lua" )
    local hubruntime = hci_tbl.hubruntime
    local formatdays = function( d )
        return math_floor( d / 365 ), math_floor( d ) % 365
    end
    local d, h, m, s = util_formatseconds( hubruntime )
    if d > 365 then
        local years, days = formatdays( d )
        d = years .. msg_years .. days
    end
    hubruntime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hubruntime
end

--// running scripts amount
check_script_amount = function()
    local scripts = cfg_get( "scripts" )
    local amount = 0
    for k, v in pairs( scripts ) do
        amount = amount + 1
    end
    return amount
end

--// memory usage
check_mem_usage = function()
    return util_formatbytes( collectgarbage( "count" ) * 1024 )
end

--// hubshare
check_hubshare = function()
    local hshare = 0
    for sid, user in pairs( hub_getusers() ) do
        if not user:isbot() then
            local ushare = user:share()
            hshare = hshare + ushare
        end
    end
    hshare = util_formatbytes( hshare )
    return hshare
end

--// users
check_users = function()
    local regged_total, online_total, online_regged, online_unregged, online_active, online_passive = 0, 0, 0, 0, 0, 0
    local regusers, reggednicks, reggedcids = hub_getregusers()
    for i, user in ipairs( regusers ) do
        if ( user.is_bot ~= 1 ) and user.nick then
            regged_total = regged_total + 1
        end
    end
    for sid, user in pairs( hub_getusers() ) do
        if not user:isbot() then
            online_total = online_total + 1
            if user:isregged() then
                online_regged = online_regged + 1
            else
                online_unregged = online_unregged + 1
            end
            if user:hasfeature( "TCP4" ) then
                online_active = online_active + 1
            else
                online_passive = online_passive + 1
            end
        end
    end
    return regged_total, online_total, online_regged, online_unregged, online_active, online_passive
end

--// operating system
check_os = function()
    local s = nil
    local win = "Microsoft Windows"
    local syno = "Synology: "
    local ras_version
    local deb_version
    local ubu_version
    local syno_unknown = "Linux (Synology)"
    local raspbian_unknown = "Linux (Raspbian)"
    local debian_unknown = "Linux (Debian)"
    local ubuntu_unknown = "Linux (Ubuntu)"
    local linux_unknown = "Linux / Unix"

    local path = os_getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string_find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io_popen( "wmic os get Caption /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return trim( split( s, "=", "\r\n") )
        else
            return win
        end
    end

    local check_path_for_syno = string_find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io_popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string_sub( s, 0, string_find( s, "\n", 1 ) - 1 )
            return syno .. linux_version
        else
            return syno_unknown
        end
    end

    --// Linux/Unix?
    local check_for_linux = function()
        local f = io_popen( "cat /etc/issue")
        if f then
            s = f:read( "*a" )
            f:close()
        end
        local ras = string_find( s, "Raspbian" )
        local deb = string_find( s, "Debian" )
        local ubu = string_find( s, "Ubuntu" )
        if ras then
            ras_version = trim( s:gsub( " \\n \\l", "" ) ) .. ": "
            --ras_version = " "
            return "Raspbian"
        end
        if deb then
            deb_version = trim( s:gsub( " \\n \\l", "" ) ) .. ": "
            return "Debian"
        end
        if ubu then
            ubu_version = trim( s:gsub( " \\n \\l", "" ) ) .. ": "
            return "Ubuntu"
        end
        return false
    end

    --// Raspbian?
    if check_for_linux() == "Raspbian" then
        --local f = io_popen( "uname -s -r -v -o" )
        local f = io_popen( "uname -s -r -v" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string_sub( s, 0, string_find( s, "\n", 1 ) - 1 )
            return ras_version .. linux_version
        else
            return raspbian_unknown
        end
    end

    --// Debian?
    if check_for_linux() == "Debian" then
        local f = io_popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string_sub( s, 0, string_find( s, "\n", 1 ) - 1 )
            return deb_version .. linux_version
        else
            return debian_unknown
        end
    end

    --// Ubuntu?
    if check_for_linux() == "Ubuntu" then
        local f = io_popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string_sub( s, 0, string_find( s, "\n", 1 ) - 1 )
            return ubu_version .. linux_version
        else
            return ubuntu_unknown
        end
    end

    local check_for_otherlinux = io_popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io_popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string_sub( s, 0, string_find( s, "\n", 1 ) - 1 )
            return linux_version
        else
            return linux_unknown
        end
    end

    return msg_unknown
end

--// processor
check_cpu = function()
    local s = nil

    local path = os_getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string_find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io_popen( "wmic cpu get Name /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return trim( split( s, "=", "\r\n" ) )
        else
            return msg_unknown
        end
    end

    local check_path_for_syno = string_find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io_popen( "grep \"Processor\" /proc/cpuinfo" )
        local f2 = io_popen( "grep \"model name\" /proc/cpuinfo" )
        --// ARM CPU?
        if f then
            s = f:read( "*a" )
            f:close()
            if s ~= "" then
                return trim( split( s, ":", "\n" ) )
            end
        end
        --// Atom CPU?
        if f2 then
            s = f2:read( "*a" )
            f2:close()
            if s ~= "" then
                return trim( split( s, ":", "\n" ) )
            end
        end
    end

    local check_for_otherlinux = io_popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io_popen( "grep \"model name\" /proc/cpuinfo" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return trim( split( s, ":", "\n" ) )
        else
            return msg_unknown
        end
    end

    return msg_unknown
end

--// ram total
check_ram_total = function()
    local s = nil

    local path = os_getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string_find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io_popen( "wmic computersystem get TotalPhysicalMemory /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( split( s, "=", "\r\n" ) )
        else
            return msg_unknown
        end
    end

    local check_path_for_syno = string_find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io_popen( "grep MemTotal /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    local check_for_otherlinux = io_popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io_popen( "grep MemTotal /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    return msg_unknown
end

--// ram free
check_ram_free = function()
    local s = nil

    local path = os_getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string_find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io_popen( "wmic OS get FreePhysicalMemory /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( split( s, "=", "\r\n" ) * 1024 )
        else
            return msg_unknown
        end
    end

    local check_path_for_syno = string_find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io_popen( "grep MemFree /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    local check_for_otherlinux = io_popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io_popen( "grep MemFree /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util_formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    return msg_unknown
end

--// output message
output = function()
    return utf_format( msg_out,
                        "\t\t" .. hub_name,
                        "\t\t" .. hub_hostaddress,
                        "\t\t" .. tcp_ports,
                        "\t\t" .. ssl_ports,
                        "\t\t" .. cache_get_ssl_value,
                        "\t\t" .. get_tls_mode(),
                        "\t" .. cache_get_kp_value,
                        "\t\t" .. cache_get_kp,
                        "\t\t" .. const_PROGRAM, const_VERSION,
                        "\t\t" .. const_COPYRIGHT,
                        "\t" .. get_hubruntime(),
                        "\t" .. check_uptime(),
                        "\t" .. cache_check_script_amount,
                        "\t" .. check_mem_usage(),
                        "\t\t" .. check_hubshare(),
                        "\t\t" .. hub_website,
                        "\t" .. hub_network,
                        "\t\t" .. hub_owner,
                        "\t" .. select( 1, check_users() ),
                        "\t" .. select( 2, check_users() ),
                        "\t" .. select( 3, check_users() ),
                        "\t" .. select( 4, check_users() ),
                        "\t" .. select( 5, check_users() ),
                        "\t" .. select( 6, check_users() ),
                        "\t\t" .. cache_check_os,
                        "\t\t" .. cache_check_cpu,
                        "\t\t" .. cache_check_ram_total,
                        "\t\t" .. check_ram_free()
    )
end

onbmsg = function( user )
    local user_level = user:level()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    user:reply( output(), hub_getbot )
    return PROCESSED
end

hub.setlistener( "onLogin", {},
    function( user )
        if onlogin then
            local user_level = user:level()
            if user_level >= minlevel then
                user:reply( output(), hub_getbot )
                return nil
            end
        end
    end
)

hub.setlistener( "onStart", {},
    function()
        --// caching functions
        cache_get_kp_value = get_kp_value()
        cache_get_ssl_value = get_ssl_value()
        cache_get_kp = get_kp()
        cache_check_script_amount = check_script_amount()
        cache_check_os = check_os()
        cache_check_cpu = check_cpu()
        cache_check_ram_total = check_ram_total()

        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, {}, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )