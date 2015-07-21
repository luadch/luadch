--[[

        doc.lua by blastbeat

        - this script provides documentation facilities

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local pairs = use "pairs"
local print = use "print"
local tostring = use "tostring"

--// lua libs //--

local io = use "io"
local table = use "table"

--// lua lib methods //--

local table_concat = table.concat

--// extern libs //--

--// extern lib methods //--

--// core scripts //--

--// core methods //--

--// constants //--

--// functions //--

local add
local get
local export
local collect

--// tables //--

local doc

--// simple data types //--

local _
local path
local notdefined

----------------------------------// DEFINITION //--

doc = { }
path = "docs/documentation.txt"
notdefined = "<not defined>"

add = function( namespace, func, help )
    doc[ namespace ] = doc[ namespace ] or { }
    doc[ namespace ][ func ] = help
end

get = function( )
    return doc
end

export = function( )
    local file, err = io.open( path, "w+" )
    _ = err and print( err )
    if file then
        file:write( collect( ) )
        file:close( )
    end
end

collect = function( )
    local tmp = { "\n    DOCUMENTATION\n" }
    for namespace, tbl in pairs( doc ) do
        tmp[ #tmp + 1 ] = "\n\nnamespace: " .. namespace
        for func, help in pairs( tbl ) do
            local pub = help.public
            if pub and pub ~= "<no export>" then
                 tmp[ #tmp + 1 ] = "\n\n  method:    " .. pub
                 tmp[ #tmp + 1 ] = "\n  args:      " .. ( help.arg or notdefined )
                 tmp[ #tmp + 1 ] = "\n  return:    " .. ( help.ret or notdefined )
                 tmp[ #tmp + 1 ] = "\n  desc:      " .. ( help.desc or notdefined )
                 tmp[ #tmp + 1 ] = "\n  example:   " .. ( help.example or notdefined )
            end
        end
    end
    return table_concat( tmp )
end

----------------------------------// BEGIN //--



----------------------------------// DOCUMENTATION //--
--[[
doc.add( "util", "savetable", {

        arg = "tbl (table), name (string), path (string)",
        ret = "true | false (boolean), err (string)",
        desc = "saves table to path; err is optional error message; NO further checks or validation that means only numbers, strings, booleans, tables should be in tbl",
        public = "save",
        example = 'util.save( { "test", a = { 1, 2 } }, "test", "core/scripts/test.tbl" )'

    }
)

doc.add( "util", "loadtable", {

        arg = "path (string)",
        ret = "tbl (table) | nil, err (string)",
        desc = "executes file and returns a table or nil; the file will be utf8 checked; err is optional error message",
        public = "load",
        example = 'local test = util.load "core/scripts/test.tbl"'

    }
)

doc.add( "util", "serialize", {

        arg = "tbl (table), name (string), file (userdata file handler), tab (string)",
        ret = "<none>",
        desc = "serializes tbl to file; file WONT be close, NO further checks or validation that means only numbers, strings, booleans, tables should be in tbl",
        public = "serialize",

    }
)

doc.add( "util", "savearray", {

        arg = "array (table), path (string)",
        ret = "true | false (boolean), err (string)",
        desc = "saves array to path; array HAS TO BE an array that means only keys 1 .. n; NO further checks or validation of the array; err is optional error message",
        public = "savearray",
        example = 'util.savearray( { "w", 1, { "w" = 1 } }, "core/scripts/test/test.lua" )'

    }
)

doc.add( "cfg", "set", {

        arg = "target (string), newvalue (string|number|table|boolean|nil)",
        ret = "<none>",
        desc = "sets target in configuration with newvalue; args WONT be checked or validated; note: some settings need a restart of the hub",
        public = "set",
        example = 'cfg.set( "tcp_ports" ) = { 5000, 5001 }    -- tcp server listens on port 5000, 5001'

    }
)

doc.add( "cfg", "get", {

        arg = "target (string)",
        ret = "cfg_of_target (string|number|table|boolean|nil)",
        desc = "returns configuration of target; if target in cfg is nil (not false!), then it returns target in default cfg (maybe also nil)",
        public = "get",
        example = 'local hubname = cfg.get( "hub_name" )'

    }
)

doc.add( "cfg", "loadusers", {

        arg = "<none>",
        ret = "usertbl (table), err (string)",
        desc = "returns user database or empty table, with optional error message",
        public = "loadusers",
        example = 'local regusers, err = cfg.loadusers( )'

    }
)

doc.add( "cfg", "saveusers", {

        arg = "regusers (table)",
        ret = "<none>",
        desc = "saves table regusers as user database, args WONT be checked or validated",
        public = "saveusers",
        example = 'cfg.saveusers( regusers )'

    }
)

doc.add( "cfg", "start", {

        arg = "<none>",
        ret = "settings (table), err (string)",
        desc = "(re)loads settings table and returns it (maybe empty table) with optional error message",
        public = "reload",
        example = 'settings, err = cfg.reload( )'

    }
)

doc.add( "server", "wrapserver", {

        arg = "listener (function), socket (luasocket userdata), ip, serverport, mode, sslctx",
        ret = "handler (table) | nil, err (string)",
        desc = "wraps a server socket, sslctx is optional",
        public = "<no export>",

    }
)

doc.add( "server", "wrapsslclient", {

        arg = "listener (function), socket (luasocket userdata), ip, serverport, clientport, mode, sslctx",
        ret = "handler (table), socket (luasocket userdata) | nil, nil, err (string)",
        desc = "wraps a ssl client socket",
        public = "<no export>",

    }
)

doc.add( "server", "wraptcpclient", {

        arg = "listener (function), socket (luasocket userdata), ip, serverport, clientport, mode",
        ret = "handler (table), socket (luasocket userdata)",
        desc = "wraps a client socket",
        public = "<no export>",

    }
)

doc.add( "server", "addtimer", {

        arg = "listener (function)",
        ret = "<none>",
        desc = "adds listener in timer",
        public = "addtimer",

    }
)

doc.add( "server", "firetimer", {

        arg = "listener (function)",
        ret = "<none>",
        desc = "calls all timer listeners",
        public = "<no export>",

    }
)

doc.add( "server", "addserver", {

        arg = "listeners (function), port (number), addr (string), mode (string), sslctx (table)",
        ret = "true | false (boolean), err (string)",
        desc = "adds a new server with correspondending listener, sslctx is optional (for ssl connections); returns status",
        public = "add",

    }
)

doc.add( "server", "removesocket", {

        arg = "tbl (table), socket (luasocket userdata)",
        ret = "true | false (boolean)",
        desc = "removes socket from tbl",
        public = "<no export>",

    }
)

doc.add( "server", "closeall", {

        arg = "<none>",
        ret = "<none>",
        desc = "closes all sockets and removes them from lists",
        public = "closeall",

    }
)

doc.add( "server", "closesocket", {

        arg = "socket (luasocket userdata)",
        ret = "<none>",
        desc = "closes socket and removes it from lists, this fct should not be called",
        public = "<no export>",

    }
)

doc.add( "server", "loop", {

        arg = "<none>",
        ret = "signal (string)",
        desc = "main loop of luadch",
        public = "loop",

    }
)
]]
----------------------------------// PUBLIC INTERFACE //--

return {

    add = add,
    get = get,
    export = export,
    collect = collect,

}
