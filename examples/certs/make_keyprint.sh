#!/bin/sh
#
# make_keyprint.sh
#
# based on a script by dennwc
# source: https://github.com/direct-connect/protocols/blob/master/examples/keyprint.sh
#
#
# --// english description //--
# 
# This bash script generates a keyprint of a particular certificate in Linux, as used in the KEYP extension.
# The script uses OpenSSL, filters all the verbosity OpenSSL adds.
# The script first calls OpenSSL to get the fingerprint then remove the verbosity and the colons convert with Python and remove any padding.
#
# Example: "adcs://your.host.addy.org:5001/?kp=SHA256/7KGKGB44A5AEPZXTNLVBIAE4HLNVBUO42ONIELL2XYFS4RTPMIYT"
#
# How to use:
#
#   - The following packages must be installed: "openssl"
#   - Go to: "luadch/certs"
#   - Command: chmod 755 make_keyprint.sh
#   - Command: sh make_keyprint.sh servercert.pem
#   - Open "luadch/cfg/cfg.tbl"
#   - Set: use_keyprint = true
#   - Set: keyprint_hash = "<your_kp>"
#   - Restart the Hub
#
# PS: for all windows user: install "cygwin" on your system and copy the "make_keyprint.sh" and the "servercert.pem" in your "/cygwin" folder, then start your cygwin terminal.

openssl x509 -noout -fingerprint -sha256 < "$1" | cut -d '=' -f 2 | tr -dc "[A-F][0-9]" | xxd -r -p | base32 | tr -d "="
