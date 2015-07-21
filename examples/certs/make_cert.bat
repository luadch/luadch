openssl ecparam -out cakey.pem -name prime256v1 -genkey
openssl req -new -x509 -days 3650 -key cakey.pem -out cacert.pem -subj /CN=Luadch-CA_Certificate
openssl ecparam -out serverkey.pem -name prime256v1 -genkey
openssl req -new -key serverkey.pem -out servercert.pem -subj /CN=Luadch-Certificate
openssl x509 -req -days 3650 -in servercert.pem -CA cacert.pem -CAkey cakey.pem -set_serial 01 -out servercert.pem
pause