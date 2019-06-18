#!/bin/sh
#
# make_keyprint.sh
#
# based on a script by ullner
# source: https://adc.svn.sourceforge.net/svnroot/adc/trunk/Source/scripts/keyp_keyprint_generation.sh
#
#
# --// english description //--
# 
# This bash script generates a keyprint of a particular certificate in Linux, as used in the KEYP extension.
# The script uses OpenSSL, filters all the verbosity OpenSSL adds and then uses Python to encode it into Base32.
# The script first calls OpenSSL to get the fingerprint then remove the verbosity and the colons convert with Python and remove any padding.
#
# Example: "adcs://your.host.addy.org:5001/?kp=SHA256/7KGKGB44A5AEPZXTNLVBIAE4HLNVBUO42ONIELL2XYFS4RTPMIYT"
#
# How to use:
#
#   - The following packages must be installed: "openssl" and "python"
#   - Go to: "luadch/certs"
#   - Command: chmod 755 make_keyprint.sh
#   - Command: sh make_keyprint.sh servercert.pem
#   - Open "luadch/cfg/cfg.tbl"
#   - Set: use_keyprint = true
#   - Set: keyprint_hash = "<your_kp>"
#   - Restart the Hub
#
# PS: for all windows user: install "cygwin" on your system and copy the "make_keyprint.sh" and the "servercert.pem" in your "/cygwin" folder, then start your cygwin terminal.
#
#
# --// german description //--
#
# Einen KeyPrint generieren, auf Basis des Luadch Zertifikates (servercert.pem)
# Durch einen an die Adresse hinzugefügten "KeyPrint" kurz "KP" werden "man in the middle" Attacken vermieden.
# Der Client prüft mit einer "KeyPrint" versehenen Adresse automatisch das Serverzertifikat und verbindet nur wenn das Zertifikat authentisch ist.
#
# Beispiel: "adcs://your.host.addy.org:5001/?kp=SHA256/7KGKGB44A5AEPZXTNLVBIAE4HLNVBUO42ONIELL2XYFS4RTPMIYT"
#
# Benutzung:
#
#   - Die folgenden Pakete müssen installiert sein: "openssl" und "python"
#   - In folgendes Verzeichnis gehn: "luadch/certs"
#   - Befehl: chmod 755 make_keyprint.sh
#   - Befehl: sh make_keyprint.sh servercert.pem
#   - Öffne: "luadch/cfg/cfg.tbl"
#   - Einstellung: use_keyprint = true
#   - Einstellung: keyprint_hash = "<your_kp>"
#   - Hub neustarten
#
# PS: Für alle Windows User unter euch: Installiert euch "cygwin" und kopiert euch die beiden Dateien "make_keyprint.sh" und "servercert.pem" in das "/cygwin" Verzeichnis und startet euer "Cygwin Terminal"

openssl x509 -noout -fingerprint -sha256 < "$1" | cut -d '=' -f 2 | tr -dc "[A-F][0-9]" | python -c "import sys; import base64; keyp=base64.b32encode(base64.b16decode(sys.stdin.readline())); print 'generate keyprint...'; print 'done.'; print 'create file and save keyprint...'; f=file('keyprint.txt', 'w'); f.write(keyp.replace('=', '')); f.close(); print 'done.'; print 'the keyprint.txt was created.'; print 'your SHA256 keyprint hash is:'; print keyp;" | tr -d "="