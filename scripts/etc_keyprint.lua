--[[

    etc_keyprint.lua by blastbeat

        - this script tries to computes the keyprint of the hub cert (if availabe), and saves it in cfg.tbl
        - using the script, the hub admin does not need to manually fiddle around with this shit anymore

]]--


local scriptname = "etc_keyprint"
local scriptversion = "0.01"

local hash_table = { }      -- this table stores the correspondence between keyprint type and hash method, used in the cert.digest method

hash_table[ "/?kp=SHA256/" ] = "sha256"     -- atm we only care for sha256

-- note: we should NOT use the onStart listener here, to ensure that the other scripts get the right keyprint settings. otherwise you need to restart the hub twice, to get the settings working
-- this means that the following code is executed exactly ONCE, namely after hub start.
-- however, this is not a problem, because if you change the certificate of the hub, you need to restart the whole hub anyway, so the scripts gets executed, and the new keyprint will be calculated

local luasec = require "ssl"        -- we need the modules luasec..
local basexx = require "basexx"     -- ..and basexx..
if luasec and basexx then
    local x509 = require "ssl.x509"     -- ..and x509 stuff
    local ssl_params = cfg.get( "ssl_params" ) or { }
    local cert_path = ssl_params.certificate        -- we need the cert location
    local fd = io.open( tostring( cert_path ), "r" )
    if fd then     -- check, whether cert exist..
        local cert_str = fd:read "*all"     -- .. and read content
        local cert = x509.load( cert_str )      -- create a luasec cert object
        local keyprint_type = cfg.get "keyprint_type"
        local method
        if keyprint_type and hash_table[ keyprint_type ] then
            method = hash_table[ keyprint_type ]
        else
            return      -- if this happends, either cfg.get failed, which means that the default settings are wrecked, or somebody needs to complete the hash table
        end
        local keyprint = basexx.to_base32( basexx.from_hex( cert:digest( method ) ) ):gsub( "=", "" )     -- calculate keyprint
        if cfg.set( "keyprint_hash", keyprint ) then        -- save it in cfg.tbl
            cfg.set( "use_keyprint", true )     -- activate keyprint usage!
        end
        fd:close( )     -- we are done.
    end
end

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )