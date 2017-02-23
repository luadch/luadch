--[[

        adc.lua by blastbeat

        - ADC stuff

            v0.08: by blastbeat
                - add SEGA support (Grouping of file extensions in SCH)

            v0.07: by pulsar
                - improved out_put messages

            v0.06: by pulsar
                - add missing "AP" client flag in INF

            v0.05: by pulsar
                - add SUDP support (encrypting UDP traffic)
                    - added: "KY" to "SCH"

            v0.04: by pulsar
                - add support for ASCH (Extended searching capability)
                    - added: "FC", "TO", "RC" to "STA"
                    - added: "MC", "PP", "OT", "NT", "MR", "PA", "RE" to "SCH"
                    - added: "FI", "FO", "DA" to "RES"

            v0.03: by pulsar
                - set "nonpclones" to "false" in "commands.SCH"

            v0.02: by pulsar
                - add support for KEYP (Keyprint)
                    - added: "KP" to "INF"
]]--

----------------------------------// DECLARATION //--

local clean = use "cleantable"

--// lua functions //--

local type = use "type"
local ipairs = use "ipairs"
local tostring = use "tostring"

--// lua libs //--

local os = use "os"
local math = use "math"
local table = use "table"
local debug = use "debug"
local string = use "string"

--// lua lib methods //--

local os_date = os.date
local os_time = os.time
local os_clock = os.clock
local string_sub = string.sub
local math_random = math.random
local string_gsub = string.gsub
local string_find = string.find
local string_match = string.match
local table_insert = table.insert
local table_concat = table.concat
local table_remove = table.remove
local debug_traceback = debug.traceback

--// extern libs //--

local adclib = use "adclib"
local unicode = use "unicode"

--// extern lib methods //--

local utf_find = unicode.utf8.find

local adclib_hash = adclib.hash
local adclib_isutf8 = adclib.isutf8
local adclib_hashpas = adclib.hashpas

--// core scripts //--

local out = use "out"
local mem = use "mem"
local types = use "types"

--// core methods //--

local types_utf8 = types.utf8

local out_put = out.put
local types_check = types.check

--// functions //--

local parse
local createid
local tokenize

local checkadccmd
local checkadcstr
local checkadcstring

--// exported adc object methods //--

local adccmd_pos
local adccmd_mysid
local adccmd_getnp
local adccmd_addnp
local adccmd_setnp
local adccmd_fourcc
local adccmd_deletenp
local adccmd_getallnp
local adccmd_hasparam
local adccmd_targetsid
local adccmd_adcstring

--// tables //--

local _base32

local _clone

local _regex    -- some regex patterns
local _buffer    -- array with message params
local _protocol    -- adc specs

local _protocol_types    -- caching..
local _protocol_commands

local _adccmds    -- collection of all created adc commands

--// simple data types //--

local _eol

local _th    -- pattern strings..
local _su
local _sid
local _sup
local _sta
local _bool
local _onetwo
local _integer
local _feature

local _contextsend
local _contextdirect

local _

----------------------------------// DEFINITION //--

_adccmds = { }

_clone = { }

_buffer = { }

_th = "^" .. string.rep( "[A-Z2-7]", 39 ) .. "$"
_su = "[A-Z]" .. string.rep( "[A-Z0-9]", 3 ) .. ","
_sta = "^[012]%d%d$"
_sid = "^" .. string.rep( "[A-Z2-7]", 4 ) .. "$"
_sup = "^" .. string.rep( "[A-Z]", 3 ) .. "[A-Z0-9]$"
_bool = "^[1]?$"
_onetwo = "^[12]?$"
_integer = "^%d*$"
_feature = "[%+%-][A-Z]" .. string.rep( "[A-Z0-9]", 3 )

_regex = {

    th = function( str )
        return string_match( str, _th )
    end,
    sid = function( str )
        return string_match( str, _sid )
    end,
    bool = function( str )
        return string_match( str, _sid )
    end,
    bool = function( str )
        return string_match( str, _bool )
    end,
    integer = function( str )
        return string_match( str, _integer )
    end,
    sta = function( str )
        return string_match( str, _sta )
    end,
    onetwo = function( str )
        return string_match( str, _onetwo )
    end,
    su = function( str )
        str = str .. ","
        for i = 1, #str, 5 do
            if not string_match( string_sub( str, i, i + 5 ), _su ) then
                return false
            end
        end
        return true
    end,
    sup = function( str )
        return string_match( str, _sup )
    end,
    feature = function( str )
        for i = 1, #str, 5 do
            if not string_match( string_sub( str, i, i + 5 ), _feature ) then
                return false
            end
        end
        return true
    end,
    default = function( )
        return true
    end,
    --default = function( str )
    --    return str
    --end,
    nowhitespace = function( str )
        return not ( string_find( str, "\\n" ) or string_find( str, "\\s" ) )
    end,
    context = {

        hub = "[H]",
        send = "[BFDE]",
        bcast = "[BF]",
        direct = "[DE]",
        hubdirect = "[HDE]",

    },

}

_protocol = {

    types = {

        I = { len = 0, },
        H = { len = 0, },
        B = {

            _regex.sid,

            len = 1,

        },
        F = {

            _regex.sid,
            _regex.feature,

            len = 2,

        },
        D = {

            _regex.sid,
            _regex.sid,

            len = 2,

        },
        E = {

            _regex.sid,
            _regex.sid,

            len = 2,

        },

    },
    commands = {

        SUP = {

            pp = { len = 0, },
            np = {

                AD = _regex.sup,
                RM = _regex.sup,

            },
            nonpclones = false,    -- doesnt remove named parameters when parameter with same name already was found (for example ADBAS0, ADBASE)

        },
        MSG = {

            pp = {

                _regex.default,

                len = 1,

            },
            np = {

                PM = _regex.sid,
                ME = _regex.bool,

            },
            nonpclones = true,    -- removes named parameters when parameter with same name already was found (for example ME1, ME)

        },
        STA = {

            pp = {

                _regex.sta,
                _regex.default,

                len = 2,

            },
            np = {

                PR = _regex.default,
                FC = _regex.default,
                TL = _regex.default,
                TO = _regex.default,
                I4 = _regex.default,
                I6 = _regex.default,
                FM = _regex.default,
                FB = _regex.default,
                --// ASCH - Extended searching capability //--  http://adc.sourceforge.net/ADC-EXT.html#_asch_extended_searching_capability
                FC = _regex.default,
                TO = _regex.default,
                RC = _regex.default,


            },
            nonpclones = true,    -- removes named parameters when parameter with same name already was found (for example ME1, ME)

        },
        INF = {

            pp = { len = 0, },
            np = {

                ID = _regex.th,
                PD = _regex.th,
                I4 = _regex.default,    -- ip string will be compared with real ip later, so no need for checking here..
                I6 = _regex.default,
                U4 = _regex.integer,
                U6 = _regex.integer,
                SS = _regex.integer,
                SF = _regex.integer,
                US = _regex.integer,
                DS = _regex.integer,
                SL = _regex.integer,
                AS = _regex.integer,
                AM = _regex.integer,
                NI = _regex.nowhitespace,
                HN = _regex.integer,
                HR = _regex.integer,
                HO = _regex.integer,
                OP = _regex.bool,
                AW = _regex.onetwo,
                BO = _regex.bool,
                HI = _regex.bool,
                HU = _regex.bool,
                SU = _regex.su,
                CT = _regex.integer,
                DE = _regex.default,
                EM = _regex.default,
                AP = _regex.default,
                VE = _regex.default,
                --// KEYP - Certificate substitution protection //--  http://adc.sourceforge.net/ADC-EXT.html#_keyp_certificate_substitution_protection_in_conjunction_with_adcs
                KP = _regex.default,

            },
            nonpclones = true,    -- removes named parameters when parameter with same name already was found (for example HN1, HN4)

        },
        CTM = {

            pp = {

                _regex.default,
                _regex.integer,
                _regex.default,

                len = 3,

            },
            np = { },
            nonpclones = false,

        },
        RCM = {

            pp = {

                _regex.default,
                _regex.default,

                len = 2,

            },
            np = { },
            nonpclones = false,

        },
        SCH = {

            pp = { len = 0, },
            np = {

                AN = _regex.default,
                NO = _regex.default,
                EX = _regex.default,
                LE = _regex.integer,
                GE = _regex.integer,
                EQ = _regex.integer,
                TO = _regex.default,
                TY = _regex.onetwo,
                TR = _regex.th,
                TD = _regex.integer,
                --// ASCH - Extended searching capability //--  http://adc.sourceforge.net/ADC-EXT.html#_asch_extended_searching_capability
                MT = _regex.default,
                PP = _regex.default,
                OT = _regex.default,
                NT = _regex.default,
                MR = _regex.default,
                PA = _regex.default,
                RE = _regex.default,
                --// SUDP - Encrypting UDP traffic //--  http://adc.sourceforge.net/ADC-EXT.html#_sudp_encrypting_udp_traffic
                KY = _regex.default,
                --// SEGA - Grouping of file extensions in SCH //--  http://adc.sourceforge.net/ADC-EXT.html#_sega_grouping_of_file_extensions_in_sch
                GR = _regex.integer,
                RX = _regex.default,

            },
            nonpclones = false,

        },
        RES = {

            pp = { len = 0, },
            np = {

                FN = _regex.default,
                SI = _regex.integer,
                SL = _regex.integer,
                TO = _regex.default,
                TR = _regex.th,
                TD = _regex.integer,
                --// ASCH - Extended searching capability //--  http://adc.sourceforge.net/ADC-EXT.html#_asch_extended_searching_capability
                FI = _regex.default,
                FO = _regex.default,
                DA = _regex.default,

            },
            nonpclones = true,

        },
        PAS = {

            pp = {

                _regex.th,

                len = 1,

            },
            nonpclones = true,

        },

    },
    contexts = {

        STA = _regex.context.hubdirect,
        SUP = _regex.context.hub,
        SID = _regex.context.hub,
        INF = _regex.context.bcast,
        MSG = _regex.context.send,
        SCH = _regex.context.send,
        RES = _regex.context.direct,
        CTM = _regex.context.direct,
        RCM = _regex.context.direct,
        GPA = _regex.context.hub,
        PAS = _regex.context.hub,
        QUI = _regex.context.hub,
        GET = _regex.context.hub,
        GFI = _regex.context.hub,
        SND = _regex.context.hub,

    }

}

_base32 = {

    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",

}

_protocol_types = _protocol.types
_protocol_commands = _protocol.commands

_contextsend = "[BFDE]"
_contextdirect = "[DE]"

adclib.createsid = function( )
    return ""..
        _base32[ math_random( 32 ) ] ..
        _base32[ math_random( 32 ) ] ..
        _base32[ math_random( 32 ) ] ..
        _base32[ math_random( 32 ) ]
end

adclib.createsalt = function( num )
    num = num or 10
    local eol = 0
    for i = 1, num do
        eol = eol + 1
        _buffer[ eol ] = _base32[ math_random( 32 ) ]
    end
    return table_concat( _buffer, "", 1, eol )
end

checkadccmd = function( data, traceback, noerror )
    local what = type( data )
    if not _adccmds[ data ] then
        _ = noerror or error( "wrong type: adccmd expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

checkadcstring = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "string" or not adclib_isutf8( data ) or not parse( data ) then
        _ = noerror or error( "wrong type: adcstring expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

checkadcstr = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "string" or not adclib_isutf8( data ) or utf_find( data, " " ) or utf_find( data, "\n" ) then
        _ = noerror or error( "wrong type: adcstr expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

createid = function( )
    local str = os_date( ) .. os_clock( ) .. os_time( )
    local pass = adclib.createsalt( )
    local pid = adclib_hashpas( pass .. str, str .. pass )
    return pid, adclib_hash( pid )
end

tokenize = function( str )
    _eol = _eol + 1
    _buffer[ _eol ] = str
end

adccmd_pos = function( self, pos )
    types_check( pos, "number" )
    if pos == 1 then
        return self[ 1 ] .. self[ 2 ]
    else
        return self[ 2 * pos ]
    end
end

adccmd_getallnp = function( self )
    local length = self.length
    local namedstart = self.namedstart
    if namedstart then
        local i = namedstart - 3
        return function( )
            i = i + 3
            if i < length then
                return self[ i ], self[ i + 1 ]
            end
        end
    else
        return function( )
        end
    end
end

adccmd_getnp = function( self, target )
    types_utf8( target )
    local namedstart = self.namedstart
    if namedstart then
        for i = namedstart, self.length, 3 do
            if target == self[ i ] then
                return self[ i + 1 ]
            end
        end
    end
    return nil
end

adccmd_addnp = function( self, target, value )
    types_utf8( target )
    types_utf8( value )
    local length = self.length
    self[ length ] = " "
    self[ length + 1 ] = target
    self[ length + 2 ] = value
    self[ length + 3 ] = "\n"
    self.namedstart = self.namedstart or length + 1
    local namedend = self.namedend
    if namedend then
        self.namedend = namedend + 3
    else
        self.namedend = length + 2
    end
    self.length = length + 3
    self.cache = nil
    --types_check( self:adcstring( ), "adcstring" )
    return true
end

adccmd_setnp = function( self, target, value )
    types_utf8( target )
    types_utf8( value )
    local namedstart = self.namedstart
    local len = self.length
    if namedstart then
        for i = namedstart, len, 3 do
            if target == self[ i ] then
                self[ i + 1 ] = value
                self.cache = nil
                return true
            end
        end
    end
    --types_check( self:adcstring( ), "adcstring" )
    return adccmd_addnp( self, target, value )    -- add new np
end

adccmd_deletenp = function( self, target )
    types_utf8( target )
    local length = self.length
    local namedstart = self.namedstart
    if namedstart then
        for i = namedstart, length, 3 do
            if target == self[ i ] then
                table_remove( self, i - 1 )
                table_remove( self, i - 1 )
                table_remove( self, i - 1 )
                local namedend = self.namedend - 3
                self.namedend = namedend
                self.length = length - 3
                if namedend <= namedstart then
                    self.namedstart, self.namedend = nil, nil
                end
                self.cache = nil
                return true
            end
        end
    end
    return false
end

adccmd_hasparam = function( self, target )
    types_utf8( target )
    for i = 1, self.length - 1 do
        local param = self[ i ]
        if target == param .. self[ i + 1 ] or target == param then
            return true
        end
    end
    return false
end

adccmd_adcstring = function( self )
    local adcstring = self.cache
    if not adcstring then
        adcstring = table_concat( self, "", 1, self.length )
        self.cache = adcstring
    end
    return adcstring
end

adccmd_mysid = function( self )
    return string_match( self[ 1 ], _contextsend ) and self[ 4 ]
end

adccmd_targetsid = function( self )
    return string_match( self[ 1 ], _contextdirect ) and self[ 6 ]
end

adccmd_fourcc = function( self )
    return self[ 1 ] .. self[ 2 ]
end

parse = function( data )

    --types_utf8( data )

    out_put( "adc.lua: try to parse '", data, "'" )

    local command = { }    -- array with parsed and checked message params (includes seperators and "\n"); is used also as adc command object with methods

    _eol = 0    -- end of buffer

    string_gsub( data, "([^ ]+)", tokenize )    -- extract message data into buffer; seperators wont be saved

    if _eol < 2 then
        out_put( "adc.lua: function 'parse': adc message to short" )
        return nil
    end

    --// extract type, command from message header; check context //--

    local fourcc = _buffer[ 1 ]

    local msgtype = string_sub( fourcc, 1, 1 )

    local header = _protocol_types[ msgtype ]

    if not header then
        out_put( "adc.lua: function 'parse': type '", msgtype, "' is invalid, unknown or unsupported" )
        return nil
    end
    local msgcmd = string_sub( fourcc, 2, -1 )
    local context = _protocol.contexts[ msgcmd ]
    if not context or not string_match( msgtype, context ) then
        out_put( "adc.lua: function 'parse': invalid message header: type/cmd mismatch, unknown or unsupported ('", fourcc, "')" )
        return nil
    end

    --// parse message header, body and parameters //--

    command[ 1 ] = msgtype
    command[ 2 ] = msgcmd

    local length = 2

    --// header //--

    local len = header.len

    if _eol < len then
        out_put( "adc.lua: function 'parse': adc message to short" )
        return nil
    end

    for i, regex in ipairs( header ) do
        local param = _buffer[ i + 1 ]
        if not regex( param ) then
            out_put( "adc.lua: function 'parse': invalid value in header '", fourcc, "': ", param )
            return nil
        end
        length = length + 2
        command[ length - 1 ] = " "
        command[ length ] = param
    end

    --// body //--

    local cmd = _protocol_commands[ msgcmd ]
    if not cmd then
        out_put( "adc.lua: function 'parse': command '", msgcmd, "' is unknown or unsupported" )
        return nil
    end

    --// positional parameters //--

    local paramstart = 2 + len    -- start of message params in buffer
    local positionalstart    -- start of positional parameters in array "command"
    local positionalend    -- end of positional parameters in array "command"
    local namedstart    -- start of named parameters in array "command"
    local namedend    -- end of named parameters in array "command"

    local ppregex = cmd.pp

    len = paramstart + ppregex.len - 1

    for i = paramstart, len do
        local param = _buffer[ i ]
        if ppregex[ i - paramstart + 1 ]( param ) then
            length = length + 2
            command[ length - 1 ] = " "
            command[ length ] = param
            positionalstart = positionalstart or length
        else
            out_put( "adc.lua: function 'parse': invalid positional parameter in '", fourcc, "' on position ", i, ": ", param )
            return nil
        end
    end
    positionalend = positionalstart and length

    --// named paramters //--

    local noclones = cmd.nonpclones

    local np = cmd.np

    for i = len + 1, _eol do
        local param = _buffer[ i ]
        local name = string_sub( param, 1, 2 ) or ""
        local npregex = np[ name ]
        --if npregex then
            local body = string_sub( param, 3, -1 ) or ""
            if _clone[ name ] ~= true and _clone[ name ] ~= body then
                if ( not npregex ) or npregex( body ) then
                    length = length + 3
                    command[ length - 2 ] = " "
                    command[ length - 1 ] = name
                    command[ length ] = body
                    if noclones then
                        _clone[ name ] = true
                    else
                        _clone[ name ] = body
                    end
                    namedstart = namedstart or length - 1
                else
                    out_put( "adc.lua: function 'parse': invalid named parameter in '", fourcc, "': ", body )
                    return nil
                end
            else
                out_put( "adc.lua: function 'parse': removed clone named parameter in '", fourcc, "': ", body )
            end
        --else
        --    out_put( "adc.lua: function 'parse': ignored unknown named parameter in '", fourcc, "': ", name )
        --end
    end

    clean( _clone )

    namedend = namedstart and length

    length = length + 1

    command[ length ] = "\n"

    --// create adc command object //--

    local contextsend = "[BFDE]"
    local contextdirect = "[DE]"

    --// public methods of the object //--

    command.length = length
    command.namedend = namedend
    command.namedstart = namedstart

    --// this saves creating closures, but you have to use "self" //--

    command.pos = adccmd_pos
    command.mysid = adccmd_mysid
    command.getnp = adccmd_getnp
    command.addnp = adccmd_addnp
    command.setnp = adccmd_setnp
    command.fourcc = adccmd_fourcc
    command.getallnp = adccmd_getallnp
    command.deletenp = adccmd_deletenp
    command.hasparam = adccmd_hasparam
    command.adcstring = adccmd_adcstring
    command.targetsid = adccmd_targetsid

    out_put( "adc.lua: function 'parse': parsed '", command:adcstring( ), "'" )

    _adccmds[ command ] = fourcc

    return command, fourcc
end

----------------------------------// BEGIN //--

use "setmetatable" ( _adccmds, { __mode = "k" } )

types.add( "adcstr", checkadcstr )
types.add( "adccmd", checkadccmd )
types.add( "adcstring", checkadcstring )

----------------------------------// PUBLIC INTERFACE //--

return {

    parse = parse,
    createid = createid,

}
