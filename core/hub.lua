--[[

    hub.lua by blastbeat

        v0.21: by pulsar
            - improved out_put/out_error messages

        v0.20: by blastbeat
            - add user.sslinfo() function

        v0.19: by pulsar
            - add TLS info flag to login function

        v0.18: by blastbeat
            - changes in user.setlevel() function

        v0.17: by pulsar
            - improved BINF flags of bots in createbot()

        v0.16: by pulsar
            - using new luadch date style for:
                - lastlogout
                - lastconnect

        v0.15: by pulsar
            - improve "user.version"

        v0.14: by pulsar
            - add "AP" to "user.version"

        v0.13: by pulsar
            - change "profile.date" style, old: DD.MM.YYYY  new: YYYY-MM-DD

        v0.12: by blastbeat
            - fix v0.10

        v0.11: by blastbeat
            - added lastlogout to _regex.reguser
            - added lastlogout to disconnect function

        v0.10: by pulsar
            - fix missing escaping in "_normalsup" and "_pingsup"

        v0.09: by pulsar
            - changes in createbot() function
                - using "HubBot" TAG for the hubbot

        v0.08: by pulsar
            - fix missing "AP" in "IINF" / thx fly out to Derek (darekgal @ sourceforge)
                - fixes problems to detect hubsoft name at dchublist.org
            - fix "I4" in "BINF" function in the "_identify" table / thx fly out to scott (cottsay @ sourceforge)
                - fixes problems when luadch and a client both reside behind the same NAT

        v0.07: by pulsar
            - added "isiponline()" function / written by Night

        v0.06: by pulsar
            - added "insertreglevel()" function / thx fly out to Night for the idea an code improvement

        v0.05: by pulsar
            - changes in reloadusers() function

        v0.04: by pulsar
            - added "ADKEYP" in "_normalsup"
            - added "ADKEYP" in "_pingsup"

        v0.03: by pulsar
            - new "os.date()" output style, consistent output of date (win/linux/etc)

        v0.02: by pulsar
            - changed "level = tostring( level )"  to  "level = tonumber( level )"

        v0.01: by blastbeat

]]--

----------------------------------// DECLARATION //--

local clean = use "cleantable"
local tablesize = use "tablesize"

--// lua functions //--

local type = use "type"
local pcall = use "pcall"
local pairs = use "pairs"
local error = use "error"
local ipairs = use "ipairs"
local loadfile = use "loadfile"
local tostring = use "tostring"
local tonumber = use "tonumber"

--// lua libs //--

local io = use "io"
local os = use "os"
local table = use "table"
local string = use "string"

--// lua lib methods //--

local os_date = os.date
local os_time = os.time
local os_difftime = os.difftime
local table_concat = table.concat
local table_remove = table.remove

--// extern libs //--

local adclib = use "adclib"
local unicode = use "unicode"

--// extern lib methods //--

local utf = unicode.utf8

local utf_sub = utf.sub
local utf_gsub = utf.gsub
local utf_find = utf.find
local utf_match = utf.match
local utf_format = utf.format
local adclib_hash = adclib.hash
local adclib_escape = adclib.escape
local adclib_isutf8 = adclib.isutf8
local adclib_hashpas = adclib.hashpas
local adclib_unescape = adclib.unescape
local adclib_createsid = adclib.createsid
local adclib_createsalt = adclib.createsalt
local adclib_hasholdpas = adclib.hasholdpas

--// core scripts //--

local out = use "out"
local adc = use "adc"
local cfg = use "cfg"
local mem = use "mem"
local util = use "util"
local types = use "types"
local const = use "const"
local server = use "server"
local signal = use "signal"
local scripts = use "scripts"

--// core methods //--

local types_utf8 = types.utf8

local cfg_get = cfg.get
local cfg_reload = cfg.reload
local cfg_saveusers = cfg.saveusers
local cfg_loadusers = cfg.loadusers
local out_put = out.put
local out_error = out.error
local out_scriptmsg = out.scriptmsg
local signal_set = signal.set
local signal_get = signal.get
local scripts_import = scripts.import
local scripts_firelistener = scripts.firelistener
local mem_free = mem.free
local adc_parse = adc.parse
local types_check = types.check
local util_formatseconds = util.formatseconds
local util_date = util.date
local util_difftime = util.difftime

--// functions //--

local checkuser

local init
local states
local incoming
local createhub
local createbot
local createuser
local disconnect
local loadsettings
local loadlanguage

local userisbot
local usernotregged

local featuretoken

local exit
local login
local debug
local import
local getbot
local regbot
local restart
local newuser
local reguser
local getuser
local getusers
local killuser
local escapeto
local reghubbot
local sendtoall
local broadcast
local usercount
local reloadcfg
local loadusers
local escapefrom
local insertuser
local delreguser
local featuresend
local reloadusers
local killscripts
local iscidonline
local issidonline
local getregusers
local isnickonline
local isuseronline
local isuserregged
local loadregusers
local insertreguser
local restartscripts
local isuserconnected
local insertreglevel
local isiponline

--// tables //--

local _luadch
local _verify
local _normal
local _protocol
local _identify

local _G
local _regex
local _regusers
local _usersids
local _usercids
local _usernicks
local _userclients
local _regusercids
local _regusernicks
local _matchreguser

local _nobot_normalstatesids
local _normalstatesids
local _bots

local _tmp

--// simple data types //--

local _
local _hubbot

local _pingsup
local _normalsup

--// language //--

local _i18n_hub_is_full
local _i18n_no_base_support
local _i18n_no_cid_nick_found
local _i18n_cid_taken
local _i18n_nick_taken
local _i18n_invalid_pid
local _i18n_invalid_ip
local _i18n_reg_only
local _i18n_invalid_pass
local _i18n_hub_is_full
local _i18n_nick_or_cid_taken
local _i18n_login_message
local _i18n_unknown
local _i18n_max_bad_password

--// caching config //--

local _cfg_hub_bot
local _cfg_hub_bot_desc
local _cfg_hub_name
local _cfg_hub_description
local _cfg_bot_rank
local _cfg_bot_level
local _cfg_reg_rank
local _cfg_reg_level
local _cfg_max_users
local _cfg_reg_only
--local _cfg_hub_pass
local _cfg_nick_change
local _cfg_hub_hostaddress
local _cfg_hub_website
local _cfg_hub_network
local _cfg_hub_owner
local _cfg_min_share
local _cfg_max_share
local _cfg_min_slots
local _cfg_max_slots
local _cfg_max_user_hubs
local _cfg_max_reg_hubs
local _cfg_max_op_hubs
local _cfg_max_bad_password
local _cfg_bad_pass_timeout
local _cfg_kill_wrong_ips

--// constants //--

local NAME = const.PROGRAM_NAME
local VERSION = const.VERSION

----------------------------------// DEFINITION //--

_normalsup = "" ..
    "ISUP ADBAS0 ADBASE ADTIGR ADKEYP ADOSNR ".. --> ADKEYP (keyprint)
    "ADUCM0 ADUCMD\nISID %s\nIINF " ..
    "NI%s APLUADCH VE%s DE%s HU1 HI1 CT32\n"
_pingsup = "" ..
    "ISUP ADBAS0 ADBASE ADTIGR ADKEYP ADOSNR " .. --> ADKEYP (keyprint)
    "ADPING ADUCM0 ADUCMD\nISID %s\nIINF " ..
    "NI%s APLUADCH VE%s DE%s HH%s WS%s NE%s OW%s " ..
    "UC%s MS%s XS%s ML%s XL%s XU%s XR%s XO%s MC%s UP%s HU1 HI1 CT32\n"

_G = _G
_usersids = { }    -- keys: SIDs
_usernicks = { }    -- keys: nicks
_userclients = { }    -- keys: clients, users
_usercids = { TIGR = { } }    -- keys: sessions hashs (TIGR)
_regusernicks = { }    -- same as above...
_regusercids = { TIGR = { } }
_regex = {

    reguser = {    -- TODO: multiple hashs...

        cid = "^" .. string.rep( "[A-Z2-7]", 39 ) .. "$",
        hash = "^" .. string.rep( "[A-Z]", 3 ) .. "[A-Z0-9]$",
        nick = "^[^ \n]+$",
        password = "^[%S]+$",
        rank    = "^%d+$",
        level = "^%d+$",
        is_bot = "^%d+$",
        date = ".*",
        by = "^[^ \n]+$",
        badpassword = "^%d+$",
        lastconnect = "^%d+$",
        lastlogout = "^%d+$",
        is_online = "^%d+$"

    },

}

_matchreguser = _regex.reguser
_normalstatesids = { }    -- keys: SIDs
_nobot_normalstatesids = { }    -- keys: SIDs
_bots = { }    -- TODO...

_tmp = { }

local finallisteners

featuretoken = function( s )
    _tmp[ utf_sub( s, 2, -1 ) ] = utf_sub( s, 1, 1 )
end

checkuser = function( data, traceback, noerror )
    local what = type( data )
    if not ( _userclients[ data ] or _bots[ data ] ) then
        _ = noerror or error( "wrong type: user expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

loadusers = function( )
    local users, err = cfg_loadusers( )
    _ = err and out_error( "hub.lua: function 'loadusers': error while loading userdatabase: ", err )
    for i, usertbl in ipairs( users ) do
        for key, value in pairs( usertbl ) do
            local regex = _matchreguser[ tostring( key ) ]
            if not regex or not utf_match( tostring( value ), regex ) then
                out_error( "hub.lua: function 'loadusers': error while loading userdatabase: corrupt database, creating new one" )
                users = { }
                break
            end
        end
    end
    return users
end

userisbot = function( traceback )
    error( "user is bot, method not supported", ( type( traceback ) == "number" and traceback ) or 3 )
end

usernotregged = function( traceback )
    error( "user not regged", ( type( traceback ) == "number" and traceback ) or 3 )
end

debug = out_scriptmsg    -- public

login = function( user, bot )
    if bot then
        sendtoall( user:inf( ):adcstring( ) )
    elseif user then
        local sendonly = user:sup( ):hasparam( "ADOSNR" )
        if not sendonly then
            for sid, onlineuser in pairs( _normalstatesids ) do
                user.write( onlineuser:inf( ):adcstring( ) )
            end
        end
        user:state "normal"
        local sid = user:sid( )
        _normalstatesids[ sid ] = user
        _nobot_normalstatesids[ sid ] = user
        insertreglevel( user ) --> thx fly out to Night for the idea
        sendtoall( user:inf( ):adcstring( ) )
        if sendonly then user:sendonly( ) end
        local ssl_params, TLS = cfg_get( "ssl_params" ), ""
        local tls_mode = ssl_params.protocol
        if tls_mode == "tlsv1" then TLS = "[TLS: v1.0]" else TLS = "[TLS: v1.2]" end
        local msg = utf_format(
            _i18n_login_message, NAME, VERSION, TLS, util_formatseconds( os_difftime( os_time( ), signal_get "start" ) )
        )
        user:reply( msg, _hubbot )
        scripts_firelistener( "onLogin", user )
    end
    return true
end    -- private

insertreglevel = function( user ) --> this function makes it unnecessary the use the "scripts/hub_user_ranks.lua", thx Night
    --> send INF string to REG levels
    if user:isregged( ) then
        local key_level = cfg_get "key_level" or 50
        local user_level = user:level( )
        if ( user_level >= key_level ) then
            user:inf( ):addnp( "", "OP1" )
        else
            user:inf( ):addnp( "", "RG1" )
        end
        if user_level == 100 then
            user:inf( ):addnp( "", "CT16" )
        elseif ( user_level >= 80 ) then
            user:inf( ):addnp( "", "CT8" )
        elseif ( user_level >= key_level ) then
            user:inf( ):addnp( "", "CT4" )
        else
            user:inf( ):addnp( "", "CT2" )
        end
    end
end

insertuser = function( nick, cid, hash, user )
    _usernicks[ nick ] = user
    _usercids[ hash ] = _usercids[ hash ] or { }
    _usercids[ hash ][ cid ] = user
end    -- private

insertreguser = function( user, profile )
    if profile then
        for key, value in pairs( profile ) do
            if not utf_match( value, _matchreguser[ key ] ) then
                return nil, "invalid profile" -----!
            end
        end
        local hash = profile.hash
        local cid = profile.cid
        local nick = profile.nick
        if not ( ( cid and hash ) or nick ) then
            return nil, "no cid/hash/nick"-----!
        end
        if user and _usersids[ user:sid( ) ] then
            if user:isregged( ) then
                return nil, "user already inserted in hub"-----!
            end
            user:addregmethods( profile )
            user.addregmethods = nil
            return user
        else
            return nil, "invalid user object"-----!
        end
    else
        return nil, "no profile"-----!
    end
end    -- private

newuser = function( client )
    local sid
    repeat
        sid = adclib_createsid( )
    until not _usersids[ sid ] and sid ~= "AAAA"
    local user = createuser( client, sid )
    _usersids[ sid ] = user
    _userclients[ user ] = client
    _userclients[ client ] = user
    --_userclients[ client ] = true
    user.alive = true    -- experimental flag
    client.setlistener( finallisteners )
    out_put( "hub.lua: function 'newuser': sid of new user: ", sid )
    return user, sid
end    -- private

loadregusers = function( )
    for i, usertbl in ipairs( _regusers ) do
        usertbl.isonline = nil  -- users are supposed to be offline
        local cid = usertbl.cid
        local hash = usertbl.hash or "TIGR"
        local nick = usertbl.nick
        if nick then
            _regusernicks[ nick ] = usertbl
        end
        if hash and cid then
            _regusercids[ hash ] = _regusercids[ hash ] or { }
            _regusercids[ hash ][ cid ] = usertbl
        end
    end
    cfg_saveusers( _regusers )  -- save modified user.tbl
end    -- private

import = scripts_import    -- public

restartscripts = function( )
    killscripts( )
    scripts.start( _luadch )
end    -- public

killscripts = function( )
    scripts.kill( )
    for bot, sid in pairs( _bots ) do
        bot.kill( )
    end
    if _cfg_hub_bot and _cfg_hub_bot ~= "" then    --// mmh..
        reghubbot( _cfg_hub_bot, _cfg_hub_bot_desc )
    end
    mem_free( )
end    -- private

reloadcfg = function( )
    local _, err = cfg_reload( )
    _ = err and out_error( "hub.lua: function 'reloadcfg': error while loading settings: ", err )
    mem_free( )
end    -- public

reloadusers = function( )
    _regusers = loadusers( )
    _regusernicks = { }
    _regusercids = { }
    _regusercids.TIGR = { }
    loadregusers( )
    mem_free( )
end    -- public

reghubbot = function( name, desc )
    _hubbot = regbot{ nick = name, desc = desc,

        client = function( self, adccmd )
            local user = _nobot_normalstatesids[ adccmd:mysid( ) ]
            if user and adccmd:fourcc( ) == "EMSG" then
                user.write( adccmd:adcstring( ) )
                scripts_firelistener( "onBroadcast", user, adccmd, escapefrom( adccmd[ 8 ] ) )
            end
            return true
        end,

    }
    return _hubbot
end    -- private

getbot = function( which )    -- TODO: get all regged bots
    if which == "all" then
        return _bots
    end
    return _hubbot
end    -- public

regbot = function( profile )
    if type( profile ) ~= "table" then
        return nil, "invalid profile"-----!
    end
    local sid
    repeat
        sid = adclib_createsid( )
    until not _usersids[ sid ] and sid ~= "AAAA"
    local bot, err = createbot( sid, profile )
    if not bot then
        return nil, err
    else
        _usersids[ sid ] = bot
        _normalstatesids[ sid ] = bot
        insertuser( bot.nick( ), bot.cid( ), "TIGR", bot )
        login( bot, true )
        return bot
    end
end    -- public

restart = function( )
    scripts_firelistener "onExit"
    signal.set( "hub", "restart" )
    server.closeall( )
    mem_free( )
end    -- public

exit = function( )
    scripts_firelistener "onExit"
    signal.set( "hub", "exit" )
end    -- public

reguser = function( profile )
    if type( profile ) ~= "table" then
        return nil, "invalid profile"-----!
    end
    for key, value in pairs( profile ) do
        local regex = _matchreguser[ tostring( key ) ]
        if not regex or not utf_match( tostring( value ), regex ) then
            return nil, "invalid profile"-----!
        end
    end
    local hash = profile.hash or "TIGR"
    local cid = profile.cid
    local nick = profile.nick
    if not ( ( cid and hash ) or nick ) then
        return false, "no cid/hash/nick"-----!
    end
    if hash and cid then
        _regusercids[ hash ] = _regusercids[ hash ] or { }
        if _regusercids[ hash ][ cid ] then
            return nil, "cid already regged"-----!
        end
        local onlineuser = _usercids[ hash ][ cid ]
        if onlineuser then
            onlineuser:kill( "ISTA 224 " .. _i18n_nick_or_cid_taken .. "\n" )
        end
    end
    if nick then
        if _regusernicks[ nick ] then
            return nil, "nick already regged"-----!
        end
        local onlineuser = _usernicks[ nick ]
        if onlineuser then
            onlineuser:kill( "ISTA 222 " .. _i18n_nick_or_cid_taken .. "\n" )
        end
    end
    profile.date = profile.date or os_date( "%Y-%m-%d / %H:%M:%S" )
    profile.by = profile.by or _i18n_unknown
    if nick then
        _regusernicks[ nick ] = profile
    end
    if cid then
        _regusercids[ hash ][ cid ] = profile
    end
    _regusers[ #_regusers + 1 ] = profile
    cfg_saveusers( _regusers )
    return true
end    -- public

delreguser = function( nick, cid, hash )
    hash = hash or "TIGR"
    if nick then
        nick = tostring( nick )
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
    end
    if _regusercids[ hash ] then
        local profile = _regusernicks[ nick ] or _regusercids[ hash ][ cid ]
        if type( profile ) ~= "table" then
            return false, "wrong nick or cid"-----!
        end
        local cid = profile.cid
        local nick = profile.nick
        if nick then
            _regusernicks[ nick ] = nil
        end
        if cid then
            _regusercids[ hash ][ cid ] = nil
        end
        for i, tbl in ipairs( _regusers ) do
            if tbl == profile then
                table_remove( _regusers, i )
                cfg_saveusers( _regusers )
                break
            end
        end
        return true
    end
end    -- public

isuseronline = function( nick, sid, cid, hash )
    hash = hash or "TIGR"
    local user
    if nick then
        local nick = tostring( nick )
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
        user = _usernicks[ nick ]
    elseif cid and _usercids[ hash ] then
        user = _usercids[ hash ][ cid ]
    elseif sid then
        return _normalstatesids[ sid ]
    end
    if user and user:state( ) == "normal" then
        return user
    end
    return nil
end    -- public

iscidonline = function( cid, hash )
    local user
    hash = hash or "TIGR"
    if _usercids[ hash ] then
        user =  _usercids[ hash ][ cid ]
    end
    if user and user:state( ) == "normal" then
        return user
    end
    return nil
end    -- public

isiponline = function( ip )
	local _user
    for sid, user in pairs( _nobot_normalstatesids ) do
		_user = user
		if _user:ip( ) == ip then
			return _user
		end
    end
	return nil
end

isnickonline = function( nick )
    local user
    if nick then
        local nick = tostring( nick )
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
        user =  _usernicks[ nick ]
    end
    if user and user:state( ) == "normal" then
        return user
    end
    return nil
end    -- public

issidonline = function( sid )
    return _normalstatesids[ sid ]
end

isuserconnected = function( nick, sid, cid, hash )
    hash = hash or "TIGR"
    if nick then
        local nick = tostring( nick )
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
        return _usernicks[ nick ]
    elseif cid and _usercids[ hash ] then
        return _usercids[ hash ][ cid ]
    elseif sid then
        return _usersids[ sid ]
    end
    return nil
end    -- public

isuserregged = function( nick, cid, hash )
    hash = hash or "TIGR"
    local ciduser, nickuser
    local nick = tostring( nick )
    if nick then
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
        nickuser = _regusernicks[ nick ]
    end
    if cid and _regusercids[ hash ] then
        ciduser = _regusercids[ hash ][ cid ]
    end
    if ( ciduser and nickuser and nickuser ~= ciduser ) then    -- cid and nick doesnt match
        return nil
    end
    return ciduser or nickuser
end    -- public

escapeto = adclib_escape    -- public

escapefrom = adclib_unescape    -- public

getuser = function( sid )
    return _nobot_normalstatesids[ sid ], _normalstatesids[ sid ], _usersids[ sid ]
end    -- public

--[[killuser = function( user, client, adcstring, quitstring1, quitstring2 )    -- ugly
    user = user or ( client and _userclients[ client ] )
    client = client or ( user and _userclients[ user ] )
    _ = client and ( adcstring and client.write( adcstring ) )
    if user then
        local usersid = user:sid( )
        local usernick = user:nick( ) or { }    -- dangerous?! ugly?
        local usercid = user:cid( ) or { }
        local userhash = user:hash( ) or "TIGR"
        local userstate = user:state( )
        local ip, port = user:peer( )

        _usersids[ usersid ] = nil
        _usernicks[ usernick ] = nil
        _usercids[ userhash ][ usercid ] = nil
        _userclients[ user ] = nil
        _normalstatesids[ usersid ] = nil
        _nobot_normalstatesids[ usersid ] = nil

        local qui = "IQUI " .. usersid .. "\n"

        quitstring1 = quitstring1 or qui
        user.write( quitstring1 )
        if userstate == "normal" then
            quitstring2 = quitstring2 or qui
            sendtoall( quitstring2 )
            scripts_firelistener( "onLogout", user )
        end
        user.destroy( )
        out_put( "hub.lua: remove user ", usersid, " ", ip, ":", port )
    end
    if not client then
        return nil, "no client to close"-----!
    end
    client.dispatchdata( )
    client.close( )
    _userclients[ client ] = nil
    return true
end    -- private]]

sendtoall = function( adcstring )
    types_utf8( adcstring )    -- TODO: check type
    local counter = 0
    for sid, user in pairs( _nobot_normalstatesids ) do
        --if not user:isbot( ) then
            user.write( adcstring )
            counter = counter + 1
        --end
    end
    return counter
end    -- public

featuresend = function( adcstring, features )
    types_utf8( adcstring )    -- TODO: check type
    types_utf8( features )
    clean( _tmp )
    utf_gsub( features, "([+-][^+-]+)", featuretoken )
    local counter = 0
    for sid, user in pairs( _nobot_normalstatesids ) do
        local bol = true
        --if not user:isbot( ) then
            --if features then
                for feature, sign in pairs( _tmp ) do
                    local support = user:hasfeature( feature )
                    if sign == "-" and support then
                        bol = false
                        break
                    elseif sign == "+" and not support then
                        bol = false
                        break
                    end
                end
            --end
            if bol then
                user.write( adcstring )
                counter = counter + 1
            end
        --end
    end
    return counter
end    -- public

broadcast = function( msg, from, pm, me )    -- this function sends BMSGs to users
    local counter = 0
    --// the following ode works not as espected ( adding a pm flag to BMSG has no effect ), so i use user:reply instead of hub:sendToAll //--

   --[[
    if not msg then
        return false, "Invalid msg"
    end
    if ( from and type( from ) ~= "table" ) or ( type( from ) == "table" and not from.sid ) then
        return false, "Invalid user object \"from\""
    end
    if ( pm and type( pm ) ~= "table" ) or ( type( pm ) == "table" and not pm.sid ) then
        return false, "Invalid user object \"pm\""
    end
    local from_sid = " " .. ( ( from and from:sid( ) ) or ( pm and pm:sid( ) ) ) or ""
    local group_sid = ( pm and " PM" .. pm:sid( ) ) or ""
    local fourcc = ( features and ( "FMSG " .. tostring( features ) ) ) or ( ( from or pm ) and "BMSG" ) or "IMSG"
    msg = " " .. this:escapeTo( tostring( msg ) ) .. ( ( me == 1 and " ME1" ) or "" )
    return this:sendToAll( fourcc .. from_sid .. msg .. group_sid .. "\n", features )
    ]]

    for sid, user in pairs( _nobot_normalstatesids ) do
        --if not user:isbot( ) then
            user:reply( msg, from, pm, me, 4 )
            counter = counter + 1
        --end
    end
    return counter
end    -- public


getusers = function( )
    return _nobot_normalstatesids, _normalstatesids, _usersids
end    -- public

getregusers = function( )
  return _regusers, _regusernicks, _regusercids
end    -- public

createhub = function( )
    return {

        _VERSION = VERSION,

        exit = exit,
        --login = login,    -- private
        debug = debug,
        import = import,
        getbot = getbot,
        regbot = regbot,
        restart = restart,
        --newuser = newuser,    -- private
        reguser = reguser,
        getuser = getuser,
        getusers = getusers,
        --killuser = killuser,    -- private
        escapeto = escapeto,
        --reghubbot = reghubbot,    -- private
        sendtoall = sendtoall,
        broadcast = broadcast,
        usercount = usercount,
        reloadcfg = reloadcfg,
        escapefrom = escapefrom,
        --insertuser = insertuser,    -- private
        delreguser = delreguser,
        featuresend = featuresend,
        reloadusers = reloadusers,
        --killscripts = killscripts,    -- private
        iscidonline = iscidonline,
        issidonline = issidonline,
        getregusers = getregusers,
        isnickonline = isnickonline,
        isiponline = isiponline,
        --isuseronline = isuseronline,    -- private
        --isuserregged = isuserregged,    -- private
        --loadregusers = loadregusers,    -- private
        --insertreguser = insertreguser,    -- private
        restartscripts = restartscripts,
        --isuserconnected = isuserconnected,    -- private

    }
end    -- private

createbot = function( _sid, p )

    --// private closures of the object //--

    local _client = p.client
    local _isreguser = false
    local _rank = _cfg_bot_rank or 5
    local _level = _cfg_bot_level or 0
    local _nick = escapeto( p.nick )
    local _desc = escapeto( p.desc )

    if type( _client ) ~= "function" then
        return nil, "invalid bot listener"-----!
    end

    --// create inf //--

    local profile, _pid, _cid = _regusernicks[ _nick ]
    if profile and profile.is_bot then
        _cid = profile.cid
    elseif not profile then
        _pid, _cid = adc.createid( )
        local profile, err = reguser{ nick = _nick, is_bot = 1, cid = _cid, hash = "TIGR", password = _pid, rank = _rank }
        if not profile then
            return nil, err
        end
    else
        return nil, "nick is already regged as user"-----!
    end
    local hubbot = cfg_get( "hub_bot" )
    local _inf
    if _nick == hubbot then
        _inf = "BINF " .. _sid ..
               " ID" .. _cid ..
               " NI" .. _nick ..
               " DE" .. _desc ..
               " OP1 CT5" ..
               " HN0 HR0 HO1" ..
               " SL0 SS0 SF0" ..
               " I4" .. "0.0.0.0" ..
               --" AW" .. "2" ..
               " SU" .. "ADC0,ADCS,TCP4,UDP4" ..
               " VE" .. "HubBot"

        _inf = adc_parse( _inf )
        if not _inf then
        return nil, "invalid inf"-----!
        end
    else
        _inf = "BINF " .. _sid ..
               " ID" .. _cid ..
               " NI" .. _nick ..
               " DE" .. _desc ..
               " OP1 CT5" ..
               " HN0 HR0 HO1" ..
               " SL0 SS0 SF0" ..
               " I4" .. "0.0.0.0" ..
               --" AW" .. "2" ..
               " SU" .. "ADC0,ADCS,TCP4,UDP4" ..
               " VE" .. "Bot"

        _inf = adc_parse( _inf )
        if not _inf then
        return nil, "invalid inf"-----!
        end
    end

    --// public methods of the object //--

    local bot = { }

    bot.alive = true    -- experimental flag

    bot.salt = userisbot
    bot.sup = userisbot
    bot.supports = userisbot
    bot.updatenick = userisbot
    bot.sendsta = userisbot

    if _nick == hubbot then
        bot.version = function( _ )
            return "HubBot"
        end
    else
        bot.version = function( _ )
            return "Bot"
        end
    end
    bot.email = function( _ )
        return ""
    end
    bot.share = function( _ )
        return 0
    end
    bot.slots = function( _ )
        return 0
    end
    bot.hubs = function( _ )
        return 0, 0, 1
    end
    bot.client = function( _ )
        return _client
    end
    bot.state = function( _ )
        return "normal"
    end
    bot.isbot = function( _ )
        return true
    end
    bot.sid = function( _ )
        return _sid
    end
    bot.cid = function( _ )
        return _cid
    end
    bot.hash = function( _ )
        return "TIGR"
    end
    bot.send = function( _, msg )
        local adccmd = adc_parse( utf_sub( tostring( _ or msg ), 1, -2 ) )
        if adccmd then
            local bol, err = pcall( _client, bot, adccmd )
            _ = bol or out_error( "hub.lua: function 'createbot': botscript error: ", err )
        end
        return adccmd
    end
    bot.write = bot.send
    bot.inf = function( _ )
        return _inf
    end
    bot.nick = function( _ )
        return _inf:getnp "NI"
    end
    bot.features = function( _, feature )
       return _inf and _inf:getnp( "SU" )
    end

    bot.firstnick = bot.nick

    bot.description = function( _ )
        return _inf:getnp "DE"
    end
    bot.kill = function( _ )
        _bots[ bot ] = nil
        --local qui = "IQUI " .. _sid .. "\n"
        disconnect( true, nil, bot, "IQUI " .. _sid .. "\n" )
    end
    bot.reply = function( _, p )    -- mhh.. do we need this? noooo...
        --p = p or { }
        --msg = tostring( p.msg ) or ""
        --bot:send( "IMSG " .. escapeto( msg ) .. "\n" )
    end
    bot.rank = function( _ )
        return _rank
    end
    bot.level = function( _ )
        return _level
    end
    bot.hasfeature = function( _, feature )
        types_utf8( feature )
        return utf_find( _inf:getnp( "SU" ) or "", feature ) ~= nil
    end

    bot.ip = function( )
        return _i18n_unknown
    end
    bot.clientport = function( )
        return _i18n_unknown
    end
    bot.peer = function( _ )
        return _i18n_unknown, _i18n_unknown
    end
    bot.isregged = function( )
        return true
    end
    bot.serverport = function( _ )
        return _i18n_unknown
    end
    bot.ssl = function( _ )
        return _i18n_unknown
    end
    bot.password = function( _ )
            return _pid
        end
    bot.profile = function( _ )
        return _regusernicks[ _nick ]
    end

    bot.setregnick = userisbot
    bot.setpassword = userisbot
    bot.setrank = userisbot
    bot.setlevel = userisbot

    bot.redirect = userisbot
    bot.destroy = function( ) end

    bot.regcid = function( _ )
        return profile.cid
    end
    bot.reghash = function( _ )
        return profile.hash
    end
    bot.regnick = function( _ )
        return profile.nick
    end
    bot.regid = function( _ )
        local num
        for i, usertbl in ipairs( _regusers ) do
            if usertbl == profile then
                return i
            end
        end
        error( "strange error, regid not found..", 2 )
    end
    _bots[ bot ] = _sid
    return bot
end    -- private

createuser = function( _client, _sid )

    --// private closures of the object //--

    local _ip = _client.ip( )
    local _port = _client.clientport( )
    local _serverport = _client.serverport( )
    local _ssl = _client.ssl( )
    local _isreguser = false
    local _rank = 0
    local _level = 0
    local _inf = nil
    local _sup = nil
    local _salt = nil
    local _sessionhash = nil

    local _firstnick    -- experimental

    local _state = "protocol"

    --// public methods of the object //--

    local user = { }
    --local user = _client

    user.firstnick = function( _ )
        return _firstnick
    end
    user.serverport = function( _ )
        return _serverport
    end
    user.ssl = function( _ )
        return _ssl
    end
    user.sslinfo = function( _ )
        if _ssl then
            return _client.getsslinfo( )
        end
        return nil, "not using ssl"
    end
    user.client = function( _ )
        return _client
    end
    user.state = function( _, state )
        _state = state or _state
        return _state
    end
    user.isbot = function( _ )
        return false
    end
    user.ip = function( _ )
        return _ip
    end
    user.clientport = function( _ )
        return _port
    end
    user.peer = function( _ )
            return _ip, _port
    end
    user.sid = function( _ )
        return _sid
    end

    local client_write = _client.write    -- caching table lookups...

    user.sendonly = function( )
        client_write = function( ) end
        _client.write = function( ) end
        user.write = function( ) end
        local tmp = _client.close
        _client.close = function( ) tmp( "disconnect OSNR bot" ) end
    end

    user.send = function( _, adcstring )
        return client_write( adcstring )
    end

    user.write = client_write

    local user_send = user.send    -- caching table lookups...

    user.sendsta = function( _, code, desc, flags )
        local code, desc = tostring( code ), escapeto( tostring( desc ) )
        if not utf_match( code, "^[012]%d%d$" ) then
            return false, "invalid code"-----!
        end
        local msg = "ISTA " .. code .. " " .. desc
        if type( flags == "table" ) then
            for flag, value in pairs( flags ) do
                msg = msg .. " " .. escapeto( flag ) .. escapeto( value )
            end
        end
        msg =  msg .. "\n"
        return client_write( msg )
    end

    user.inf = function( _, adccmd )
        if adccmd then
            _inf = _inf or adccmd
            _firstnick = _firstnick or user.nick( )
        end
        return _inf
    end
    user.sup = function( _, adccmd )
        if adccmd then
            _sup = _sup or adccmd
        end
        return _sup
    end
    user.cid = function( _ )
        return _inf and _inf:getnp "ID"    -- dangerous...
    end
    user.nick = function( _ )
        return _inf and _inf:getnp "NI"
    end
    user.description = function( _ )
        return _inf and _inf:getnp "DE"
    end
    user.email = function( _ )
        return _inf and _inf:getnp "EM"
    end
    user.share = function( _ )
        return _inf and tonumber( _inf:getnp "SS" )
    end
    user.slots = function( _ )
        return _inf and tonumber( _inf:getnp "SL" )
    end
    user.features = function( _ )
       return _inf and _inf:getnp "SU"
    end
    user.hubs = function( _ )
        if _inf then
            return tonumber( _inf:getnp "HN" ), tonumber( _inf:getnp "HR" ), tonumber( _inf:getnp "HO" )
        end
        return nil
    end
    user.version = function( _ )
        local ve = _inf and _inf:getnp "VE"
        local ap = _inf and _inf:getnp "AP"
        ve = ve or ""
        ap = ap or ""
        if ap ~= "" then return ap .. " " .. ve else return ve end
        --return _inf and _inf:getnp "VE"
    end
    user.updatenick = function( _, nick, notsend, bypass )
        if not _inf then
            return false, "user has no inf"    -- user is maybe not in normal state
        end
        types_utf8( nick )
        if utf_find( nick, " " ) then
            nick = escapeto( nick )
        end
        local oldnick = user.nick( )
        _firstnick = _firstnick or oldnick
        if not bypass then
            if nick == oldnick then
                return false, "no nick change"
            end
            if isuserconnected( nick ) then
                return false, "nick taken"
            end
            if _regusernicks[ nick ] and not ( nick == _firstnick ) then
                return false, "nick is regged"
            end
        end
        if utf_match( nick, _regex.reguser.nick ) then
            _inf:setnp( "NI", nick )
            _usernicks[ oldnick ] = nil
            _usernicks[ nick ] = user
            if not notsend then
                sendtoall( "BINF " .. _sid .. " NI" .. nick .. "\n" )
            end
            return true
        end
        return false, "invalid nick"
    end
    user.kill = function( _, adcstring, quitstring1, quitstring2 )
        types_utf8( adcstring )    --TODO
        types_utf8( quitstring1 or "" )    --TODO
        types_utf8( quitstring2 or "" )    --TODO

        local qui = "IQUI " .. _sid .. "\n"

        client_write( adcstring )
        client_write( quitstring1 or qui )

        _client.close( )

        disconnect( _client, nil, user, quitstring2 or qui )
    end
    user.redirect = function( _, url )
        types_utf8( url )
        user:kill( "IQUI " .. _sid .. " RD" .. adclib_escape( url ) .. "\n" )
    end
    user.salt = function( _, data )
        if data then
            _salt = _salt or data
        end
        return _salt
    end
    user.hash = function( _, data)
        if data then
            _sessionhash = _sessionhash or data
        end
        return _sessionhash
    end
    user.isregged = function( _ )
        return _isreguser
    end
    user.reply = function( _, msg, from, pm, me, traceback )
        types_utf8( msg, traceback )
        msg = escapeto( msg ) .. ( ( me == "1" and " ME1" ) or "" )    -- add flag for me-message
        local fromsid, groupsid
        if pm then
            checkuser( pm )
            fromsid = ( from and ( checkuser( from ) and from.sid( ) ) ) or pm.sid( )
            groupsid = pm.sid( )
            client_write( "DMSG " .. fromsid .. " " .. _sid .. " ".. msg .. " PM" .. groupsid .. "\n" )
        elseif not pm and from then
            checkuser( from )
            client_write( "BMSG " .. from.sid( ) .. " " .. msg .. "\n" )
        else
            client_write( "IMSG " .. msg .. "\n" )
        end
        return true
    end
    user.rank = function( _ )
        return _rank
    end
    user.level = function( _ )
        return _level
    end
    user.supports = function( _, feature )
        types_utf8( feature )
        if _sup and _sup:hasparam( "AD" .. tostring( feature ) ) then
            return true
        end
        return false
    end
    user.hasfeature = function( _, feature )
        types_utf8( feature )
        return utf_find( _inf:getnp( "SU" ) or "", feature ) ~= nil
    end

    user.destroy = function( )
        _client = nil
        client_write = nil
        user.waskilled = true    -- experimental flag
    end

    user.regcid = usernotregged
    user.reghash = usernotregged
    user.regnick = usernotregged
    user.password = usernotregged
    user.setregnick = usernotregged
    user.setpassword = usernotregged
    user.setrank = usernotregged
    user.setlevel = usernotregged
    user.regid = usernotregged
    user.profile = usernotregged

    user.addregmethods = function( _, profile )

        _isreguser = true

        user.regcid = function( _ )
            return profile.cid
        end
        user.reghash = function( _ )
            return profile.hash
        end
        user.regnick = function( _ )
            return profile.nick
        end
        user.password = function( _ )
            return profile.password
        end
        user.rank = function( _ )
            return tonumber( profile.rank ) or _cfg_reg_rank or 2
        end
        user.level = function( _ )
            return tonumber( profile.level ) or _cfg_reg_level or 20
        end
        user.setregnick = function( _, nick, update, notsend )
            types_utf8( nick )
            if utf_find( nick, " " ) then
                nick = escapeto( nick )
            end
            if profile.nick == nick then
                return false, "no nick change"
            end
            if _regusernicks[ nick ] then
                return false, "nick already regged"
            end
            local onlineuser = _usernicks[ nick ]
            if onlineuser and not ( user.cid( ) == onlineuser.cid( ) ) then
                return false, "nick taken"
            end
            if utf.match( nick, _regex.reguser.nick ) then
                _regusernicks[ profile.nick or "" ] = nil
                _regusernicks[ nick ] = user
                profile.nick = nick
                cfg_saveusers( _regusers )
                if update then
                    user:updatenick( nick, notsend )
                end
                return true
            end
            return false, "invalid Nick"
        end
        user.setpassword = function( _, password )
            password = tostring( password )
            if utf.match( password, _regex.reguser.password ) then
                profile.password = password
                cfg_saveusers( _regusers )
                return true
            end
            return false, "invalid pass"
        end
        user.setrank = function( _, rank )
            rank = tostring( rank )
            if utf.match( rank, _regex.reguser.rank ) then
                profile.rank = rank
                cfg_saveusers( _regusers )
                return true
            end
            return false, "invalid rank"
        end
        user.setlevel = function( _, level )
            level = tonumber( level )
            if utf.match( level, _regex.reguser.level ) then
                profile.level = level
                cfg_saveusers( _regusers )
                --return true
                return cfg_saveusers( _regusers )
            end
            return false, "invalid level"
        end
        user.regid = function( _ )
            local num
            for i, usertbl in ipairs( _regusers ) do
                if usertbl == profile then
                    return i
                end
            end
            error( "strange error, regid not found..", 2 )
        end
        user.profile = function( _ )
            return profile
        end
    end
    return user
end    -- private

_protocol = {

    HSUP = function( user, adccmd )
        if adccmd:hasparam "ADBASE" or adccmd:hasparam "ADBAS0" then
            local response
            if adccmd:hasparam "ADPING" then
                local max_share = _cfg_max_share[ 0 ] or 100
                max_share = max_share * 1024^4
                response = utf_format( _pingsup,
                    user.sid( ),
                    _cfg_hub_name,
                    adclib_escape( VERSION ),
                    _cfg_hub_description,
                    _cfg_hub_hostaddress,
                    _cfg_hub_website,
                    _cfg_hub_network,
                    _cfg_hub_owner,
                    tablesize( _normalstatesids ),
                    _cfg_min_share[ 0 ] or 0,
                    max_share,
                    _cfg_min_slots[ 0 ] or 1,
                    _cfg_max_slots[ 0 ] or 100,
                    _cfg_max_user_hubs,
                    _cfg_max_reg_hubs,
                    _cfg_max_op_hubs,
                    _cfg_max_users,
                    os_difftime( os_time( ), signal_get( "start" ) )
                )
            else
                response = utf_format( _normalsup,
                    user.sid( ),
                    _cfg_hub_name,
                    adclib_escape( VERSION ),
                    _cfg_hub_description
                )
            end
            user.write( response )
            if _cfg_max_users <= #_usersids then
                user:kill( "ISTA 211 " .. _i18n_hub_is_full .. "\n" )-----!
                return true
            end
            user:sup( adccmd )
            user:state "identify"
            user:hash "TIGR"    -- assume TIGR support^^
        else
            user:kill( "ISTA 220 " .. _i18n_no_base_support .. "\n" )-----!
        end
        return true
    end

}

_identify = {

    BINF = function( user, adccmd )
        local pid = adccmd:getnp "PD"
        local cid = adccmd:getnp "ID"
        local nick = adccmd:getnp "NI"
        local hash = user.hash( )
        if not ( cid and pid and nick ) then
            user:kill( "ISTA 220 " .. _i18n_no_cid_nick_found .. "\n" )
            return true
        end
        if cid ~= adclib_hash( pid ) then
            user:kill( "ISTA 227 " .. _i18n_invalid_pid .. "\n" )
            return true
        end
        local onlineuser = isuserconnected( nil, nil, cid, hash )
        if onlineuser then
            onlineuser:kill( "ISTA 224 " .. _i18n_cid_taken .. "\n" )
        end
        if isuserconnected( nick ) then
            user:kill( "ISTA 222 " .. _i18n_nick_taken .. "\n" )
            return true
        end
        local infip = adccmd:getnp "I4"
        local userip = user.ip( ) or ""

        if ( not infip ) or ( infip == "0.0.0.0" ) then    -- TODO: I6
            adccmd:setnp( "I4", userip )
        --[[
        elseif infip and ( infip ~= userip ) then
            if _cfg_kill_wrong_ips then
                user:kill( "ISTA 246 " .. _i18n_invalid_ip .. userip .. "/" .. infip .. "\n" )
            else
                adccmd:setnp( "I4", userip )
            end
            return true
        end
        ]]--
        elseif infip and ( infip ~= userip ) then
            if _cfg_kill_wrong_ips then
                user:kill( "ISTA 246 " .. _i18n_invalid_ip .. userip .. "/" .. infip .. "\n" )
                return true
            end
        end

        local reguser = isuserregged( nick, cid, hash )
        if not reguser and _cfg_reg_only then
            user:kill( "ISTA 226 " .. _i18n_reg_only .. "\n" )
            return true
        elseif not reguser and ( _regusernicks[ nick ] or _regusercids.TIGR[ cid ] ) then
            user:kill( "ISTA 221 " .. _i18n_nick_or_cid_taken .. "\n" )
            return true
        elseif reguser then
            local bol, err = insertreguser( user, reguser )
            if not bol then
                --killuser( user, nil, "ISTA 220 " .. escapeto( err ) .. "\n" )
                user:kill( "ISTA 220\n" )
                return true
            end
        end
        adccmd:deletenp "PD"
        user:inf( adccmd )
        insertuser( nick, cid, hash, user )
        if scripts_firelistener( "onConnect", user ) or user.waskilled then
            return true
        end
        --if _cfg_hub_pass or reguser then
        if reguser then
            local profile = user.profile( )
            profile.lastconnect = profile.lastconnect or util_date()
            local lc = tostring( profile.lastconnect )
            if #lc ~= 14 then profile.lastconnect = util_date() end
            local sec, y, d, h, m, s = util_difftime( util_date(), profile.lastconnect )
            if ( ( profile.badpassword or 0 ) >= _cfg_max_bad_password ) and ( sec < _cfg_bad_pass_timeout ) then
                user:kill( "ISTA 223 " .. _i18n_max_bad_password .. sec .. "/" .. _cfg_bad_pass_timeout .. "\n" )
                return true
            end
            --[[profile.lastconnect = profile.lastconnect or os_time( )
            local diff = os_difftime( os_time( ), profile.lastconnect )
            if ( ( profile.badpassword or 0 ) >= _cfg_max_bad_password ) and ( diff < _cfg_bad_pass_timeout ) then
                user:kill( "ISTA 223 " .. _i18n_max_bad_password .. diff .. "/" .. _cfg_bad_pass_timeout .. "\n" )
                return true
            end ]]
            user:salt( adclib_createsalt( ) )
            user.write( "IGPA " .. user.salt( ) .. "\n" )
            user:state "verify"
        else
            login( user, false )
        end
        return true
    end,

}

_verify = {

    HPAS = function( user, adccmd )
        local salt = user.salt( )
        --local pass = _cfg_hub_pass
        local pass
        local regged = user.isregged( )
        local usercid = user.cid( )
        local userhash = adccmd[ 4 ]
        if regged then
            pass = user.password( )
        end
        local profile = user.profile( )
        local hubhash = adclib_hashpas( pass, salt )
        local hubhashold = adclib_hasholdpas( pass, salt, usercid )
        if ( userhash ~= hubhash ) and ( userhash ~= hubhashold ) then
            profile.badpassword = ( profile.badpassword or 0 ) + 1
            user:kill( "ISTA 223 " .. _i18n_invalid_pass .. "\n" )
        else
            profile.badpassword = 0
            login( user )
        end
        --[[
        if regged and cfg_get "nick_change" then        --// mhh.. the whole thing needs rework
            user:setregnick( user:nick( ) )
        end
        ]]--
        profile.lastconnect = util_date( )
        profile.is_online = 1
        cfg_saveusers( _regusers )
        return true
    end,

}

_normal = {

    BINF = function( user, adccmd )
        if not scripts_firelistener( "onInf", user, adccmd ) then
            sendtoall( adccmd:adcstring( ) )
        end
        return true
    end,
    HSUP = function( user, adccmd )

        --// ignoring...//--

        return true
    end,
    BMSG = function( user, adccmd )
        if not scripts_firelistener( "onBroadcast", user, adccmd, escapefrom( adccmd[ 6 ] ) ) then
            sendtoall( adccmd:adcstring( ) )
        end
        return true
    end,
    FMSG = function( user, adccmd )
        if not scripts_firelistener( "onBroadcast", user, adccmd, escapefrom( adccmd[ 8 ] ) ) then
            local features = adccmd[ 6 ]
            featuresend( adccmd:adcstring( ), features )
        end
        return true
    end,
    EMSG = function( user, adccmd, targetuser )
        if not scripts_firelistener( "onPrivateMessage", user, targetuser, adccmd, escapefrom( adccmd[ 8 ] ) ) then
            targetuser.write( adccmd:adcstring( ) )
            if not targetuser.isbot( ) then user.write( adccmd:adcstring( ) ) end
        end
        return true
    end,
    DMSG = function( user, adccmd, targetuser )
        if not scripts_firelistener( "onPrivateMessage", user, targetuser, adccmd, escapefrom( adccmd[ 8 ] ) ) then
            targetuser.write( adccmd:adcstring( ) )
        end
        return true
    end,
    DCTM = function( user, adccmd, targetuser )
        if not scripts_firelistener( "onConnectToMe", user, targetuser, adccmd ) then
            targetuser.write( adccmd:adcstring( ) )
        end
        return true
    end,
    DRCM = function( user, adccmd, targetuser )
        if not scripts_firelistener( "onRevConnectToMe", user, targetuser,adccmd ) then
            targetuser.write( adccmd:adcstring( ) )
        end
        return true
    end,
    BSCH = function( user, adccmd )
        if not scripts_firelistener( "onSearch", user, adccmd ) then
            sendtoall( adccmd:adcstring( ) )
        end
        return true
    end,
    FSCH = function( user, adccmd )
        if not scripts_firelistener( "onSearch", user, adccmd ) then
            local features = adccmd[ 6 ]
            featuresend( adccmd:adcstring( ), features )
        end
        return true
    end,
    DRES = function( user, adccmd, targetuser )
        if not scripts_firelistener( "onSearchResult", user, targetuser, adccmd ) then
            targetuser.write( adccmd:adcstring( ) )
        end
        return true
    end,

}

states = function( user, adccmd, fourcc, state, targetuser )
    if state == "normal" then
        local ret = _normal[ fourcc ]
        return ret and ret( user, adccmd, targetuser )
    elseif state == "protocol" then
        local ret = _protocol[ fourcc ]
        return ret and ret( user, adccmd, targetuser )
    elseif state == "identify" then
        local ret = _identify[ fourcc ]
        return ret and ret( user, adccmd, targetuser )
    elseif state == "verify" then
        local ret = _verify[ fourcc ]
        return ret and ret( user, adccmd, targetuser )
    end
end

incoming = function( client, data, err )
    local user = _userclients[ client ]
    --local user = client
    local usersid = user.sid( )
    user.alive = true    -- experimental flag
    if data == "" or not data then    -- useless data
        return true
    end
    if not adclib_isutf8( data ) then    -- check incoming data
        out_put( "hub.lua: function 'incoming': protocol error: no utf8 string" )
        return true
    end
    local adccmd, fourcc = adc_parse( data )
    if adccmd then    -- adc command, try to process
        local mysid = adccmd:mysid( )
        local userstate = user.state( )
        local targetsid = adccmd:targetsid( )
        local targetuser = _normalstatesids[ targetsid ]
        out_put( "hub.lua: function 'incoming': user: ", usersid, ", state: ", userstate )
        scripts_firelistener( "onIncoming", user, adccmd )
        if targetsid and not targetuser then    -- targetuser doesnt exist
            user.write "ISTA 140\n"
        elseif not mysid or mysid == usersid then    -- match sids
            local bol, ret = pcall( states, user, adccmd, fourcc, userstate, targetuser )
            _ = bol or out_error( "hub.lua: function 'incoming': lua error: ", ret )
        else    -- user sends with invalid sid -> kick
            user:kill( "ISTA 140\n" )
        end
        out_put( "hub.lua: function 'incoming': adc command processed" )
    end
    return true
end

disconnect = function( client, err, user, quitstring )
    if not client then    -- should not happen
        out_error( "hub.lua: function 'disconnect': no client! disconnect error: ", err )
        return false
    end
    local user = user or _userclients[ client ]
    --local user = client
    if user then
        local usersid = user.sid( )
        local usernick = user.nick( ) or { }    -- dangerous?! ugly?
        local usercid = user.cid( ) or { }
        local userhash = user.hash( ) or "TIGR"
        local userstate = user.state( )
        local ip, port = user.peer( )

        _usersids[ usersid ] = nil
        _usernicks[ usernick ] = nil
        _usercids[ userhash ][ usercid ] = nil
        _userclients[ user ] = nil
        _normalstatesids[ usersid ] = nil
        _nobot_normalstatesids[ usersid ] = nil

        if userstate == "normal" then
            if user:isregged( ) then
              local profile = user:profile( )
              profile.lastlogout = util_date( )
              profile.is_online = 0
              cfg_saveusers( _regusers )
            end
            sendtoall( quitstring or ( "IQUI " .. usersid .. "\n" ) )
            scripts_firelistener( "onLogout", user )
        end
        user.destroy( )
        out_put( "hub.lua: function 'disconnect': remove user ", usersid, " ", ip, ":", port )
    end
    _userclients[ client ] = nil
    return true
end

loadlanguage = function( )

    local i18n, err = cfg.loadlanguage( )

    _ = err and out_put( "hub.lua: function 'loadlanguage': error while loading language file: ", err )

    i18n = i18n or { }

    _i18n_unknown = adclib_escape( i18n.hub_unknown or "<unknown>" )
    _i18n_reg_only = adclib_escape( i18n.hub_reg_only or "Registered users only." )
    _i18n_cid_taken = adclib_escape( i18n.hub_cid_taken or "Your CID is taken." )
    _i18n_nick_taken = adclib_escape( i18n.hub_nick_taken or "Your nick is taken." )
    _i18n_invalid_ip = adclib_escape( i18n.hub_invalid_ip or "Your IP in INF doesnt match with your real IP." )
    _i18n_hub_is_full = adclib_escape( i18n.hub_hub_is_full or "Hub is full." )
    _i18n_invalid_pid = adclib_escape( i18n.hub_invalid_pid or "Your PID is invalid." )
    _i18n_invalid_pass = adclib_escape( i18n.hub_invalid_pass or "Invalid password." )
    _i18n_login_message = i18n.hub_login_message or "This server is running %s %s %s (Uptime: %d days, %d hours, %d minutes, %d seconds)"
    _i18n_no_base_support = adclib_escape( i18n.hub_no_base_support or "Your client does not support BASE." )
    _i18n_max_bad_password = adclib_escape( i18n.hub_max_bad_password or "Max bad password exceeded. Timeout in seconds: " )
    _i18n_nick_or_cid_taken = adclib_escape( i18n.hub_nick_or_cid_taken or "Nick/CID taken." )
    _i18n_no_cid_nick_found = adclib_escape( i18n.hub_no_cid_nick_found or "No CID/PID/nick found in your INF." )
end

loadsettings = function( )    -- caching table lookups...
    _cfg_hub_bot = cfg_get "hub_bot"
    _cfg_hub_bot_desc = cfg_get "hub_bot_desc"
    _cfg_hub_name = escapeto( cfg_get "hub_name" )
    _cfg_hub_description = escapeto( cfg_get "hub_description" )
    _cfg_bot_rank = cfg_get "bot_rank"
    _cfg_bot_level = cfg_get "bot_level"
    _cfg_reg_rank = cfg_get "reg_rank"
    _cfg_reg_level = cfg_get "reg_level"
    _cfg_max_users = cfg_get "max_users"
    _cfg_reg_only = cfg_get "reg_only"
    --_cfg_hub_pass = cfg_get "hub_pass"
    _cfg_hub_hostaddress = escapeto( cfg_get "hub_hostaddress" )
    _cfg_hub_website = escapeto( cfg_get "hub_website" )
    _cfg_hub_network = escapeto( cfg_get "hub_network" )
    _cfg_hub_owner = escapeto( cfg_get "hub_owner" )
    _cfg_min_share = cfg_get "min_share"
    _cfg_max_share = cfg_get "max_share"
    _cfg_min_slots = cfg_get "min_slots"
    _cfg_max_slots = cfg_get "max_slots"
    _cfg_max_user_hubs = cfg_get "max_user_hubs"
    _cfg_max_reg_hubs = cfg_get "max_reg_hubs"
    _cfg_max_op_hubs = cfg_get "max_op_hubs"
    _cfg_max_bad_password = cfg_get "max_bad_password"
    _cfg_bad_pass_timeout = cfg_get "bad_pass_timeout"
    _cfg_kill_wrong_ips = cfg_get "kill_wrong_ips"
end

init = function( )

    _regusers = loadusers( )

    loadsettings( )
    loadlanguage( )
    _luadch = createhub( )
    loadregusers( )
    reghubbot( cfg_get "hub_bot", cfg_get "hub_bot_desc" )
    scripts.start( _luadch )
    for i, port in pairs( cfg_get "tcp_ports" ) do
        server.addserver( { incoming = newuser, disconnect = disconnect }, port )
    end
    for i, port in pairs( cfg_get "ssl_ports" ) do
        server.addserver( { incoming = newuser, disconnect = disconnect }, port, nil, nil, cfg_get "ssl_params", 10000, true )
    end
    server.addtimer(
        function( )
            scripts_firelistener "onTimer"
        end
    )
    cfg.registerevent( "reload", reloadusers )
    cfg.registerevent( "reload", loadlanguage )
    cfg.registerevent( "reload", loadsettings )
end

----------------------------------// BEGIN //--

use "setmetatable" ( _usernicks, { __mode = "v" } )
use "setmetatable" ( _userclients, { __mode = "kv" } )
use "setmetatable" ( _usercids.TIGR, { __mode = "v" } )
use "setmetatable" ( _normalstatesids, { __mode = "v" } )
use "setmetatable" ( _nobot_normalstatesids, { __mode = "v" } )

types.add( "user", checkuser )

finallisteners = { incoming = incoming, disconnect = disconnect }

----------------------------------// PUBLIC INTERFACE //--

return {

    init = init,

    object = _luadch,

}