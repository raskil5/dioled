# Verify modem port responds to AT commands
opengt
set com 115200n81
set senddelay 0.2
send "AT\r"
waitfor 1 "OK"
close
