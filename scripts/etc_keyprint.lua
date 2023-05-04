--[[

    etc_keyprint.lua by blastbeat

        - this script tries to compute the keyprint of the hub cert (if available), and saves it in cfg.tbl
        - using the script, the hub admin does not need to manually fiddle around with this shit anymore

]]--


local scriptname = "etc_keyprint"
local scriptversion = "0.01"

local hash_table = { }      -- this table stores the correspondence between keyprint type and cert.digest method

hash_table[ "/?kp=SHA256/" ] = "sha256"     -- atm we only care for sha256

-- note: we should NOT use the onStart listener here, to ensure that the other scripts get the right keyprint settings. otherwise you need to restart the hub twice, to get the settings working

local luasec = require "ssl"        -- we need the modules luasec..
local basexx = require "basexx"     -- ..and basexx..

if luasec and basexx then
    local x509 = require "ssl.x509"     -- ..and x509 stuff
    local ssl_params = cfg.get( "ssl_params" )      -- this should give us at least a default ssl param table, hardcoded in luadch
    local cert_path = ssl_params.certificate        -- we need the cert location
    if not cert_path then
        return      -- ssl params are invalid which really should not happen; cancel operation
    end
    local fd = io.open( tostring( cert_path ), "r" )
    if fd then     -- check, whether file can be opened..
        local cert_str = fd:read "*all"     -- ..and read content
        if not cert_str then
            fd:close( )     -- we are done because..
            return      -- ..something is wrong with the file; cancel operation..
        end
        local cert = x509.load( cert_str )      -- create a luasec cert object
        if not cert then
            fd:close( )     -- we are done because..
            return      -- ..file did not contain a valid cert; cancel operation..
        end
        local keyprint_type = cfg.get "keyprint_type"
        local method
        if keyprint_type and hash_table[ keyprint_type ] then
            method = hash_table[ keyprint_type ]
        else
            fd:close( )     -- we are done because..
            return      -- ..if this happends, either cfg.get failed, which means that the default settings are wrecked, or somebody needs to complete the hash table
        end
        local digest = cert:digest( method )
        if not digest then
            fd:close( )     -- we are done because..
            return      -- ..the method provided in the hash table was fucked up; cancel operation
        end
        local keyprint = basexx.to_base32( basexx.from_hex( digest ) ):gsub( "=", "" )     -- calculate keyprint; this should not fail, but how knows; let's trust basexx
        cfg.set( "keyprint_hash", keyprint, true )
        cfg.set( "use_keyprint", true, true )     -- activate keyprint usage, but do not save it into cfg.tbl
        fd:close( )     -- we are done.
    end
end

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )