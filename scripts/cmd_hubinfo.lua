--[[

    cmd_hubinfo.lua by pulsar

        usage: [+!#]hubinfo

        v0.22:
            - added dynamic date on copyright info

        v0.21:
            - removed table lookups
            - changed some english language parts / thx Sopor

        v0.20:
            - fixed issue #100 -> https://github.com/luadch/luadch/issues/100
            - added ipv6 ports

        v0.19:
            - changed check_cpu for Linux to match cpu info for RPi1 based on ARMv6
            - rewrite check_cpu to reduce code

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
            - small fix on cfg.get vars

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
local scriptversion = "0.22"

local cmd = "hubinfo"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local minlevel = cfg.get( "cmd_hubinfo_minlevel" )
local onlogin = cfg.get( "cmd_hubinfo_onlogin" )
local hub_name = cfg.get( "hub_name" )
local hub_hostaddress = cfg.get( "hub_hostaddress" )
local tcp_ports = table.concat( cfg.get( "tcp_ports" ), ", " )
local ssl_ports = table.concat( cfg.get( "ssl_ports" ), ", " )
local tcp_ports_ipv6 = table.concat( cfg.get( "tcp_ports_ipv6" ), ", " )
local ssl_ports_ipv6 = table.concat( cfg.get( "ssl_ports_ipv6" ), ", " )
local use_ssl = cfg.get( "use_ssl" )
local use_keyprint = cfg.get( "use_keyprint" )
local keyprint_type = cfg.get( "keyprint_type" )
local keyprint_hash = cfg.get( "keyprint_hash" )
local hub_website = cfg.get( "hub_website" ) or ""
local hub_network = cfg.get( "hub_network" ) or ""
local hub_owner = cfg.get( "hub_owner" ) or ""
local ssl_params = cfg.get( "ssl_params" )

--// table constants from "core/const.lua"
local const_file = "core/const.lua"
local const_tbl = util.loadtable( const_file ) or {}
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
        ADC Port IPv4:  %s
        ADCS Port IPv4:  %s
        ADC Port IPv6:  %s
        ADCS Port IPv6:  %s
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

        Hub share:  %s

        Hub website:  %s
        Hub Network:  %s
        Hub owner:  %s

        [ USER ]

        Total registered users:      %s
        Total users online:            %s
        Registered users online:   %s
        Unregistered users online:  %s
        Active users online:          %s
        Passive users online:       %s

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
    if use_ssl then
        return string.sub( ssl_params.protocol, 4 ):gsub( "_", "." )
    end
    return ""
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
    return string.find( s, "^%s*$" ) and "" or string.match( s, "^%s*(.*%S)" )
end

--// split strings  / by Night
split = function( s, delim, newline )
    local i = string.find( s, delim ) + 1
    if not i then
        i = 0
    end
    local j = string.find( s, newline, i ) - 1
    if not j then
        j = - 1
    end
    return string.sub( s, i, j )
end

--// uptime
check_uptime = function()
    local d, h, m, s = util.formatseconds( os.difftime( os.time(), signal.get( "start" ) ) )
    local hub_uptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hub_uptime
end

--// uptime complete
get_hubruntime = function()
    local hci_tbl = util.loadtable( "core/hci.lua" )
    local hubruntime = hci_tbl.hubruntime
    local formatdays = function( d )
        return math.floor( d / 365 ), math.floor( d ) % 365
    end
    local d, h, m, s = util.formatseconds( hubruntime )
    if d > 365 then
        local years, days = formatdays( d )
        d = years .. msg_years .. days
    end
    hubruntime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hubruntime
end

--// running scripts amount
check_script_amount = function()
    local scripts = cfg.get( "scripts" )
    local amount = 0
    for k, v in pairs( scripts ) do
        amount = amount + 1
    end
    return amount
end

--// memory usage
check_mem_usage = function()
    return util.formatbytes( collectgarbage( "count" ) * 1024 )
end

--// hubshare
check_hubshare = function()
    local hshare = 0
    for sid, user in pairs( hub.getusers() ) do
        if not user:isbot() then
            local ushare = user:share()
            hshare = hshare + ushare
        end
    end
    hshare = util.formatbytes( hshare )
    return hshare
end

--// users
check_users = function()
    local regged_total, online_total, online_regged, online_unregged, online_active, online_passive = 0, 0, 0, 0, 0, 0
    local regusers, reggednicks, reggedcids = hub.getregusers()
    for i, user in ipairs( regusers ) do
        if ( user.is_bot ~= 1 ) and user.nick then
            regged_total = regged_total + 1
        end
    end
    for sid, user in pairs( hub.getusers() ) do
        if not user:isbot() then
            online_total = online_total + 1
            if user:isregged() then
                online_regged = online_regged + 1
            else
                online_unregged = online_unregged + 1
            end
            if user:hasfeature( "TCP4" ) or user:hasfeature( "TCP6" ) then
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

    local path = os.getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string.find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io.popen( "wmic os get Caption /value" )
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

    local check_path_for_syno = string.find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io.popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string.sub( s, 0, string.find( s, "\n", 1 ) - 1 )
            return syno .. linux_version
        else
            return syno_unknown
        end
    end

    --// Linux/Unix?
    local check_for_linux = function()
        local f = io.popen( "cat /etc/issue")
        if f then
            s = f:read( "*a" )
            f:close()
        end
        local ras = string.find( s, "Raspbian" )
        local deb = string.find( s, "Debian" )
        local ubu = string.find( s, "Ubuntu" )
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
        --local f = io.popen( "uname -s -r -v -o" )
        local f = io.popen( "uname -s -r -v" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string.sub( s, 0, string.find( s, "\n", 1 ) - 1 )
            return ras_version .. linux_version
        else
            return raspbian_unknown
        end
    end

    --// Debian?
    if check_for_linux() == "Debian" then
        local f = io.popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string.sub( s, 0, string.find( s, "\n", 1 ) - 1 )
            return deb_version .. linux_version
        else
            return debian_unknown
        end
    end

    --// Ubuntu?
    if check_for_linux() == "Ubuntu" then
        local f = io.popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string.sub( s, 0, string.find( s, "\n", 1 ) - 1 )
            return ubu_version .. linux_version
        else
            return ubuntu_unknown
        end
    end

    local check_for_otherlinux = io.popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io.popen( "uname -s -r -v -o" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            local linux_version = string.sub( s, 0, string.find( s, "\n", 1 ) - 1 )
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

    local path = os.getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string.find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io.popen( "wmic cpu get Name /value" )
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

    local check_path_for_syno = string.find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io.popen( "grep \"Processor\" /proc/cpuinfo" )
        local f2 = io.popen( "grep \"model name\" /proc/cpuinfo" )
        --// ARM CPU?
        if f then
            s = f:read( "*a" )
            f:close()
        end
        --// Atom CPU?
        if f2 then
            if s == "" then
                s = f2:read( "*a" )
            end
            f2:close()
        end
    end

    local check_for_otherlinux = io.popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io.popen( "grep \"Processor\" /proc/cpuinfo" )
        local f2 = io.popen( "grep \"model name\" /proc/cpuinfo" )
        --// ARMv6 CPU?
        if f then
            s = f:read( "*a" )
            f:close()
        end
        --// ARMv7 CPU?
        if f2 then
            if s == "" then
                s = f2:read( "*a" )
            end
            f2:close()
        end
    end

    --// Return CPU info
    if s ~= "" then
        return trim( split( s, ":", "\n" ) )
    else
        return msg_unknown
    end
end

--// ram total
check_ram_total = function()
    local s = nil

    local path = os.getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string.find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io.popen( "wmic computersystem get TotalPhysicalMemory /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( split( s, "=", "\r\n" ) )
        else
            return msg_unknown
        end
    end

    local check_path_for_syno = string.find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io.popen( "grep MemTotal /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    local check_for_otherlinux = io.popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io.popen( "grep MemTotal /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    return msg_unknown
end

--// ram free
check_ram_free = function()
    local s = nil

    local path = os.getenv( "PATH" ) or msg_unknown

    local check_path_for_win = string.find( path, ";" )

    --// Windows?
    if check_path_for_win then
        local f = io.popen( "wmic OS get FreePhysicalMemory /value" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( split( s, "=", "\r\n" ) * 1024 )
        else
            return msg_unknown
        end
    end

    local check_path_for_syno = string.find( path, "syno" )

    --// Synology?
    if check_path_for_syno then
        local f = io.popen( "grep MemFree /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    local check_for_otherlinux = io.popen( "uname -s -r -v -o" )

    --// Other Linux/Unix?
    if check_for_otherlinux then
        local f = io.popen( "grep MemFree /proc/meminfo | awk '{ print $2 }'" )
        if f then
            s = f:read( "*a" )
            f:close()
        end
        if s ~= "" then
            return util.formatbytes( s * 1024 )
        else
            return msg_unknown
        end
    end

    return msg_unknown
end

--// output message
output = function()
    return utf.format( msg_out,
                        "\t\t" .. hub_name,
                        "\t\t" .. hub_hostaddress,
                        "\t\t" .. tcp_ports,
                        "\t\t" .. ssl_ports,
                        "\t" .. tcp_ports_ipv6,
                        "\t" .. ssl_ports_ipv6,
                        "\t\t" .. cache_get_ssl_value,
                        "\t\t" .. get_tls_mode(),
                        "\t" .. cache_get_kp_value,
                        "\t\t" .. cache_get_kp,
                        "\t\t" .. const_PROGRAM, const_VERSION,
                        "\t\t" .. const_COPYRIGHT ..
                        " (2007-" .. os.date( "%Y" ) .. ")",
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
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    user:reply( output(), hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onLogin", {},
    function( user )
        if onlogin then
            local user_level = user:level()
            if user_level >= minlevel then
                user:reply( output(), hub.getbot() )
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

        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, {}, { "CT1" }, minlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
