@echo off
rem show_certinfo.bat
rem shows information about the servercert.pem
openssl x509 -noout -in servercert.pem -issuer -subject -dates
pause