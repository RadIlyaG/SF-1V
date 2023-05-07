console show
package require ftp
source lib_Ftp_SF1V.tcl

set ::continueFtp 1
bind . <F1> {console show}

after 10 FtpLaptopSide
wm iconify . ; update