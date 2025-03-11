wm iconify . ; update

package require registry
set gaSet(hostDescription) [registry get "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters" srvcomment ]
set jav [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment" CurrentVersion]
set gaSet(javaLocation) [file normalize [registry -64bit get "HKEY_LOCAL_MACHINE\\SOFTWARE\\javasoft\\Java Runtime Environment\\$jav" JavaHome]/bin]


## delete barcode files TO3001483079.txt
foreach fi [glob -nocomplain -type f *.txt] {
  if [regexp {\w{2}\d{9,}} $fi] {
    file delete -force $fi
  }
}
if [file exists c:/TEMP_FOLDER] {
  file delete -force c:/TEMP_FOLDER
}
after 1000
set ::RadAppsPath c:/RadApps

if 1 {
  set gaSet(radNet) 0
  foreach {jj ip} [regexp -all -inline {v4 Address[\.\s\:]+([\d\.]+)} [exec ipconfig]] {
    if {[string match {*192.115.243.*} $ip] || [string match {*172.18.9*} $ip]} {
      set gaSet(radNet) 1
    }  
  }
  if {$gaSet(radNet)} {
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautosync.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autosyncapp/rlautosync.tcl c:/tcl/lib/rl
      after 2000
    }
    set mTimeTds [file mtime //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl]
    set mTimeRL  [file mtime c:/tcl/lib/rl/rlautoupdate.tcl]
    puts "mTimeTds:$mTimeTds mTimeRL:$mTimeRL"
    if {$mTimeTds>$mTimeRL} {
      puts "$mTimeTds>$mTimeRL"
      file copy -force //prod-svm1/tds/install/ateinstall/jate_team/autoupdate/rlautoupdate.tcl c:/tcl/lib/rl
      after 2000
    }
    update
  }
  
  package require RLAutoSync
  
  set s1 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/SF-1V/AT-SF-1V]
  set d1 [file normalize  C:/AT-SF-1V]
  set s2 [file normalize //prod-svm1/tds/AT-Testers/JER_AT/ilya/TCL/SF-1V/download]
  set d2 [file normalize  C:/download]
  
  if {$gaSet(radNet)} {
    set emailL {{meir_ka@rad.com} {} }
  } else {
    set emailL [list]
  }
  
  set ret [RLAutoSync::AutoSync "$s1 $d1 $s2 $d2" \
      -noCheckFiles {init*.tcl skipped.txt eeprom.cnt EthTest* *ifiReport.txt \
                     cook* LocWifiReport*.txt startMea*  *.db} \
      -noCheckDirs {temp tmpFiles OLD old} -jarLocation $::RadAppsPath \
      -javaLocation $gaSet(javaLocation) -emailL $emailL -putsCmd 1 -radNet $gaSet(radNet)]
  #console show
  puts "ret:<$ret>"
  set gsm $gMessage
  foreach gmess $gMessage {
    puts "$gmess"
  }
  update
  if {$ret=="-1"} {
    set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
    -message "The AutoSync process did not perform successfully.\n\n\
    Do you want to continue? "]
    if {$res=="no"} {
      SQliteClose
      exit
    }
  }
  
  if {$gaSet(radNet)} {
    package require RLAutoUpdate
    set s2 [file normalize W:/winprog/ATE]
    set d2 [file normalize $::RadAppsPath]
    set ret [RLAutoUpdate::AutoUpdate "$s2 $d2" \
        -noCopyGlobL {Get_Li* Get28* Macreg.2* Macreg-i* DP* *.prd}]
    #console show
    puts "ret:<$ret>"
    set gsm $gMessage
    foreach gmess $gMessage {
      puts "$gmess"
    }
    update
    if {$ret=="-1"} {
      set res [tk_messageBox -icon error -type yesno -title "AutoSync"\
      -message "The AutoSync process did not perform successfully.\n\n\
      Do you want to continue? "]
      if {$res=="no"} {
        SQliteClose
        exit
      }
    }
  }
}

package require BWidget
package require img::ico
package require RLSerial
package require RLEH
package require RLTime
package require RLStatus
package require RLUsbPio
package require RLUsbMmux
package require RLSound  
package require RLCom
RLSound::Open ; # [list failbeep fail.wav passbeep pass.wav beep warning.wav]
#package require RLScotty ; #RLTcp
package require ezsmtp
package require http
package require RLAutoUpdate
##package require registry
package require sqlite3
package require ftp
package require http
package require tls
package require base64
::http::register https 8445 ::tls::socket
::http::register https 8443 ::tls::socket
package require json

source Gui_SF1V.tcl
source Main_SF1V.tcl
source Lib_Put_SF1V.tcl
source Lib_Gen_SF1V.tcl
source [info host]/init$gaSet(pair).tcl
source lib_bc.tcl
source Lib_DialogBox.tcl
source LibEmail.tcl
source LibIPRelay.tcl
source lib_SQlite.tcl
source lib_Ftp_SF1V.tcl

#console show 

if [file exists uutInits/$gaSet(DutInitName)] {
  source uutInits/$gaSet(DutInitName)
} else {
  source [lindex [glob uutInits/SF-1V*.tcl] 0]
}
source lib_SQlite.tcl
source LibUrl.tcl
source Lib_GetOperator.tcl

source Lib_Ramzor.tcl
source lib_EcoCheck.tcl

set gaSet(act) 1
set gaSet(initUut) 1
set gaSet(oneTest)    0
set gaSet(puts) 1
set gaSet(noSet) 0

set gaSet(toTestClr)    #aad5ff
set gaSet(toNotTestClr) SystemButtonFace
set gaSet(halfPassClr)  #ccffcc

set gaSet(useExistBarcode) 0
#set gaSet(1.barcode1) CE100025622

set gaSet(gpibMode) com
set gaSet(relDebMode) Release

set gaSet(wifiNet) [info host]_$gaSet(pair)
if ![file exist startMeasurement_$gaSet(wifiNet)] {
  set id [open startMeasurement_$gaSet(wifiNet) w+]
  after 100
  close $id
}
if ![info exists gaSet(loraDashBver)] {
  set gaSet(loraDashBver) "1.1.0"
}

set gaSet(WifiNet) 50.50

if ![info exists gaSet(demo)] {
  set gaSet(demo) 0
}
set gaSet(testmode) finalTests

GUI
BuildTests
update

wm deiconify .
wm geometry . $gaGui(xy)
update
Status "Ready"

