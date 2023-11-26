# ***************************************************************************
# BuildTests
# ***************************************************************************
proc BuildTests {} {
  global gaSet gaGui glTests
  
  if {![info exists gaSet(DutInitName)] || $gaSet(DutInitName)==""} {
    puts "\n[MyTime] BuildTests DutInitName doesn't exists or empty. Return -1\n"
    return -1
  }
  puts "\n[MyTime] BuildTests DutInitName:$gaSet(DutInitName)\n"
  
  RetriveDutFam   
  
#   set lTestsAllTests [list]
#   set lDownloadTests [list UbootDownload UbootVersion BrdEeprom SwDownload]
#   eval lappend lTestsAllTests $lDownloadTests
  
  set lTestNames [list]
  lappend lTestNames UbootDownload UbootVersion 
  
  lappend lTestNames BrdEeprom SwDownload
#   if {![string match *VB-101V* $gaSet(dutFam.sf)]} {
#     lappend lTestNames BrdEeprom SwDownload
#   }
#   
  if {[string match *VB-101V* $gaSet(dutFam.sf)]} {
    lappend lTestNames VB101V_SwDownload
  }
  
  lappend lTestNames PowerSupply UsbMicroSD DryContactAlarm
  lappend lTestNames ID
  
  if {[string index $gaSet(dutFam.cell) 0]=="1"} {
    if {[string index $gaSet(dutFam.cell) 2]=="4"} {
      lappend lTestNames CellularModemL4_slot1 CellularModemL4_slot2
    } else {
      lappend lTestNames CellularModem_slot1 CellularModem_slot2
    } 
  } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
    if {[string index $gaSet(dutFam.cell) 2]=="4"} {
      lappend lTestNames CellularDualModemL4
    } else {
      lappend lTestNames CellularDualModem
    }
  }
  
  lappend lTestNames Data_Eth1 Data_Eth2 Data_Eth3 Data_Eth4 Data_Eth5 
  
  if {$gaSet(dutFam.serPort)!="0"} {
    lappend lTestNames SerialPorts
  }
  
  if {$gaSet(dutFam.gps)!="0"} {
    lappend lTestNames GPS
  }
  
  if {$gaSet(dutFam.wifi)!="0"} {
    lappend lTestNames WiFi_2G  WiFi_5G
  }
  
  if {$gaSet(dutFam.lora)!="0"} {
    lappend lTestNames LoRa
  }
  
  if {$gaSet(dutFam.poe)!="0"} {
    lappend lTestNames POE
  }
  if {$gaSet(dutFam.plc)!="0"} {
    lappend lTestNames PLC
  }
  
  
  lappend lTestNames AlarmRunLeds CloseUboot_FrontLeds Factory_Settings
  if !$gaSet(demo) {
    lappend lTestNames Mac_BarCode
  }
  
  eval lappend lTestsAllTests $lTestNames
  
  set glTests ""
  set gaSet(TestMode) AllTests
  set lTests [set lTests$gaSet(TestMode)]
  
  for {set i 0; set k 1} {$i<[llength $lTests]} {incr i; incr k} {
    lappend glTests "$k..[lindex $lTests $i]"
  }

  set gaSet(startFrom) [lindex $glTests 0]
  $gaGui(startFrom) configure -values $glTests -height [llength $glTests]
  
}


# ***************************************************************************
# Testing
# ***************************************************************************
proc Testing {} {
  global gaSet glTests

  set startTime [$gaSet(startTime) cget -text]
  set stTestIndx [lsearch $glTests $gaSet(startFrom)]
  set lRunTests [lrange $glTests $stTestIndx end]
  
  if ![file exists c:/logs] {
    file mkdir c:/logs
    after 1000
  }
  set ti [clock format [clock seconds] -format  "%Y.%m.%d_%H.%M"]
  set gaSet(logFile) c:/logs/logFile_[set ti]_$gaSet(pair).txt
#   if {[string match {*Leds*} $gaSet(startFrom)] || [string match {*Mac_BarCode*} $gaSet(startFrom)]} {
#     set ret 0
#   }
  
  set pair 1
  if {$gaSet(act)==0} {return -2}
    
  set ::pair $pair
  puts "\n\n ********* DUT start *********..[MyTime].."
  Status "DUT start"
  set gaSet(curTest) ""
  update
    
  AddToPairLog $gaSet(pair) "********* DUT start *********"
  puts "RunTests1 gaSet(startFrom):$gaSet(startFrom)"

  foreach numberedTest $lRunTests {
    set gaSet(curTest) $numberedTest
    puts "\n **** Test $numberedTest start; [MyTime] "
    update
      
    set testName [lindex [split $numberedTest ..] end]
    $gaSet(startTime) configure -text "$startTime ."
    AddToPairLog $gaSet(pair) "Test \'$testName\' started"
    set ret [$testName 1]
    if {$ret!=0 && $ret!="-2" && $testName!="Mac_BarCode" && $testName!="ID" && $testName!="Leds"} {
#     set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
#     puts $logFileID "**** Test $numberedTest fail and rechecked. Reason: $gaSet(fail); [MyTime]"
#     close $logFileID
#     puts "\n **** Rerun - Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n"
#     $gaSet(startTime) configure -text "$startTime .."
      
#     set ret [$testName 2]
    }
    
    if {$ret==0} {
      set retTxt "PASS."
    } else {
      set retTxt "FAIL. Reason: $gaSet(fail)"
    }
    AddToPairLog $gaSet(pair) "Test \'$testName\' $retTxt"
       
    puts "\n **** Test $numberedTest finish;  ret of $numberedTest is: $ret;  [MyTime]\n" 
    update
    if {$ret!=0} {
      break
    }
    if {$gaSet(oneTest)==1} {
      set ret 1
      set gaSet(oneTest) 0
      break
    }
  }
  
  if {$ret==0} {
    AddToPairLog $gaSet(pair) ""
    AddToPairLog $gaSet(pair) "All tests pass"
  } 

  AddToPairLog $gaSet(pair) "WS: $::wastedSecs"
  puts "RunTests4 ret:$ret gaSet(startFrom):$gaSet(startFrom)"   
  return $ret
}

# ***************************************************************************
# UbootDownload
# ***************************************************************************
proc UbootDownload {run} {
  global gaSet buffer
  while 1 {
    MuxMngIO 2ToPc
    RLSound::Play information
    Power all off
    set res [DialogBox -title "Reset button" -type "Continue Stop" -icon /images/info\
        -text "Press and do not release the Reset botton of the UUT. \n\
        Press Continue and then after 8-10 seconds release the button"]
    if {$res=="Stop"} {
      set ret -2
      set gaSet(fail) "User stop"
      return $ret
    } elseif {$res=="Continue"} {
  #     after 10000 {
  #       RLSound::Play information
  #       DialogBox -title "Reset button" -text "Release the Reset botton" -type "Ok" -icon /images/info]
  #     }
      Power all on 
      set com $gaSet(comDut)
      set ret [ReadCom $com "Trying Uart" 10]
      puts "ret after readComUart:<$ret>" ; update
      
      if {$ret!=0} {
        set res [DialogBox -title "Reset button" -type {"Try again" Stop} -icon /images/question\
          -text "Entry to UART fail. Try again?\r"]
        if {$res=="Stop"} {
          set gaSet(fail) "Entry to UART fail"
          return -1
        } else {  
          continue
        }  
      } else {
        set ret 0
        break
      }
    }  
  }    
  set id [open c:/download/sf1v/raw_mode_boot.pattern r]
  set raw [read $id]
  close $id
  
  Status "Downloading the \'raw_mode_boot.pattern\' file"
  set ret [RLCom::Send $com $raw buffer Boot 10]
  puts "[MyTime] after Send raw"; update
  catch {unset raw}
  Status "Downloading the \'[file tail $gaSet(UbootSWpath)]\' file"
  
  set kwb $gaSet(UbootSWpath)
#   #set kwb c:/download/sf1v/$gaSet(pair)_[file tail $gaSet(UbootSWpath)]
#   if [catch {file copy -force $gaSet(UbootSWpath) $kwb} res] {
#     set gaSet(fail) "Fail to prepare $kwb file ($res)"
#     return -1
#   }
  
  Status "Downloading the \'[file tail $kwb]\' file"
  set ret [RLCom::DownLoad $com $kwb]
  
#   catch {RLCom::Close $gaSet(comDut)}
#   after 1000
#   set cmd [list {*}[auto_execok start] {}]
#   catch [exec c:/rlfiles/tools/xmodem/XModemSend20.exe $gaSet(comDut) 115200 $kwb] ret
#   puts "[MyTime] ret after download:<$ret>" ; update
#   RLCom::Open $gaSet(comDut) 115200 8 NONE 1
#   after 1000
  
  set ret [ReadCom $com  "SF1V=>" 22]
  puts "[MyTime] ret after readComSF1V:<$ret>" ; update
  puts "buffer:<$buffer>"; update
   
  if {$ret==0} {
    set ret [Uboot2eMMC]
  }      
    
  return $ret
}
# ***************************************************************************
# UbootVersion
# ***************************************************************************
proc UbootVersion {run} {
   set ret [UbootCheckVersionRam]
   return $ret
}

proc neUbootDownload {run} {
  global gaSet buffer
  RLSound::Play information
  Power all off
  set res [DialogBox -title "Reset button" -type "Continue Stop" -icon /images/info\
      -text "Press and do not release the Reset botton of the UUT. \n\Press Continue"]
  if {$res=="Stop"} {
    set ret -2
    set gaSet(fail) "User stop"
    return $ret
  } elseif {$res=="Continue"} {
    RLSound::Play information
    Power all on 
    set com $gaSet(comDut)
    set ret [ReadCom $com "Trying Uart" 10]
    puts "ret after readComUart:<$ret>" ; update
    #after 10000 
    set res [DialogBox -title "Reset button" -text "Release the Reset botton. \nPress Continue" \
      -type "Continue Stop" -icon /images/info]
    if {$res=="Stop"} {
      set ret -2
      set gaSet(fail) "User stop"
      return $ret
    } elseif {$res=="Continue"} {
       #set com $gaSet(comDut)
       #set ret [ReadCom $com "Trying Uart" 10]
       #puts "ret after readComUart:<$ret>" ; update
       if {$ret!=0} {
         set gaSet(fail) "Entry to Trying UART fail"
         return -1
       }
       
       set id [open c:/download/sf1v/raw_mode_boot.pattern r]
       set raw [read $id]
       close $id
       
       Status "Downloading the \'raw_mode_boot.pattern\' file"
       set ret [RLCom::Send $com $raw buffer Boot 10]
       puts "[MyTime] after Send raw"; update
       catch {unset raw}
       Status "Downloading the Uboot ile"
       set ret [RLCom::DownLoad $com $gaSet(UbootSWpath)]
       puts "[MyTime] ret after download:<$ret>" ; update
       
       set ret [ReadCom $com  "SF1V=>" 22]
       puts "[MyTime] ret after readComSF1V:<$ret>" ; update
       puts "buffer:<$buffer>"; update
       
       
    }
  }
  
  return $ret
}

# ***************************************************************************
# PowerSupply
# ***************************************************************************
proc PowerSupply {run} {
  global gaSet buffer
  
  set com $gaSet(comDut)
  if {$gaSet(dutFam.ps)=="48V" || $gaSet(dutFam.ps)=="WDC"} {
    Power all on
    after 2000
    set ret -1
    for {set i 1} {$i<=20} {incr i} {
      Send $com \r stam 1
      if {$buffer!=""} {
        set ret 0
        break
      }
    }
    if {$ret!=0} {
      set gaSet(fail) "No communication with UUT when 2x48V PS are ON"      
    } else {
      Power 1 on
      Power 2 off 
      after 3000
      set ret -1
      for {set i 1} {$i<=20} {incr i} {
        Send $com \r stam 1
        if {$buffer!=""} {
          set ret 0
          break
        }
      }
      if {$ret!=0} {
        set gaSet(fail) "No communication with UUT when only PS-1 is ON"      
      } else {
        Power 1 on
        Power 2 on 
        after 1000
        Power 1 off
        after 3000
        set ret -1
        for {set i 1} {$i<=20} {incr i} {
          Send $com \r stam 1
          if {$buffer!=""} {
            set ret 0
            break
          }
        }
        if {$ret!=0} {
          set gaSet(fail) "No communication with UUT when only PS-2 is ON"      
        }
      }
    } 
  } else {
    set ret [PowerResetAndLogin2Uboot]
    if {$ret!=0} {
      set gaSet(fail) "No communication with UUT"
    }
    
  }
  return $ret
}
# ***************************************************************************
# UsbMicroSD
# ***************************************************************************
proc UsbMicroSD {run} {
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret==0} {
    for {set i 1} {$i<=3} {incr i} {
      puts "\n Call UsbMicroSDcheck $i"; update
      set ret [UsbMicroSDcheck]
      puts "Ret UsbMicroSDcheck $i : <$ret>"; update
      if {$ret==0} {break}
      if {$ret=="-2"} {break}
      after 10000
    }
  }
  return $ret
}

# ***************************************************************************
# DryContactAlarm
# ***************************************************************************
proc DryContactAlarm {run} {
  global gaSet buffer
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret==0} {
    set ret [DryContactAlarmcheck $gaSet(dutFam.dryCon)]
    if {$ret!=0} {
      set ret [PowerResetAndLogin2Uboot]
      if {$ret==0} {
        set ret [DryContactAlarmcheck $gaSet(dutFam.dryCon)]
      }  
    }
  }
  return $ret
}

# ***************************************************************************
# BrdEeprom
# ***************************************************************************
proc BrdEeprom {run} {
  MuxMngIO 2ToPc
  set ret [BrdEepromPerf]   
  return $ret
}

# ***************************************************************************
# SwDownload
# ***************************************************************************
proc SwDownload {run} {
  MuxMngIO 2ToPc
  set ret [SwDownloadPerf]   
  return $ret
}
# ***************************************************************************
# VB101V_SwDownload
# ***************************************************************************
proc VB101V_SwDownload {run} {
  MuxMngIO 2ToPc
  set ret [VB101V_SwDownloadPerf]   
  return $ret
}
# ***************************************************************************
# ID
# ***************************************************************************
proc ID {run} {
  set ret [IDPerf]   
  return $ret
}

# ***************************************************************************
# CellularModem
# ***************************************************************************
proc CellularModem {run} {
  set ret [CellularModemPerf 1 notL4]   
  if {$ret!=0} {return -1}
  set ret [CellularModemPerf 2 notL4]   
  if {$ret!=0} {return -1}  
  set ret [CellularFirmware]   
  if {$ret!=0} {return -1}
  return $ret
} 
# ***************************************************************************
# CellularModem_slot1
# ***************************************************************************
proc CellularModem_slot1 {run} {
  set ret [CellularFirmware]   
  if {$ret!=0} {return -1}
  set ret [CellularModemPerf 1 notL4]   
  if {$ret!=0} {return -1}
  return $ret
} 
# ***************************************************************************
# CellularModem_slot2
# ***************************************************************************
proc CellularModem_slot2 {run} {
  set ret [CellularModemPerf 2 notL4]   
  if {$ret!=0} {return -1}  
  return $ret
} 
# ***************************************************************************
# CellularDualModem
# ***************************************************************************
proc CellularDualModem {run} {
  set ret [CellularModemPerfDual notL4]   
  if {$ret!=0} {return -1}
  set ret [CellularFirmwareDual]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# CellularModemL4
# ***************************************************************************
proc CellularModemL4 {run} {
  set ret [CellularModemPerf 1 L4]   
  if {$ret!=0} {return -1}
  set ret [CellularModemPerf 2 L4]   
  if {$ret!=0} {return -1}  
  set ret [CellularFirmware]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# CellularModemL4_slot1
# ***************************************************************************
proc CellularModemL4_slot1 {run} {
  set ret [CellularFirmware]   
  if {$ret!=0} {return -1}
  set ret [CellularModemPerf 1 L4]   
  if {$ret!=0} {return -1}
  return $ret
}
# ***************************************************************************
# CellularModemL4_slot2
# ***************************************************************************
proc CellularModemL4_slot2 {run} {
  set ret [CellularModemPerf 2 L4]   
  if {$ret!=0} {return -1}  
  return $ret
}
# ***************************************************************************
# CellularDualModemL4
# ***************************************************************************
proc CellularDualModemL4 {run} {
  set ret [CellularModemPerfDual L4]   
  if {$ret!=0} {return -1}
  set ret [CellularFirmwareDual]   
  if {$ret!=0} {return -1}
  return $ret
}

# ***************************************************************************
# SerialPorts
# ***************************************************************************
proc SerialPorts {run} {
  set ret [SerialPortsPerf 1]
  SerialCloseBackGrPr 1 notExit
  if {$ret!=0} {return $ret}
  
  set ret [SerialPortsPerf 2]
  SerialCloseBackGrPr 2 Exit
  if {$ret!=0} {return $ret}
  return $ret
}

# ***************************************************************************
# Data_Eth1
# ***************************************************************************
proc Data_Eth1 {run} {
  set ret [Data $run 1]
  return $ret
}
proc Data_Eth2 {run} {
  set ret [Data $run 2]
  return $ret
}
proc Data_Eth3 {run} {
  set ret [Data $run 3]
  return $ret
}
proc Data_Eth4 {run} {
  set ret [Data $run 4]
  return $ret
}
proc Data_Eth5 {run} {
  set ret [Data $run 5]
  return $ret
}
# ***************************************************************************
# Data
# ***************************************************************************
proc Data {run port} {
  global gaSet
  
  #foreach port {1 2 3 4 5} {}
  set gaSet(fail) ""
  set ret [DataPerf $port]
  set fail $gaSet(fail)
  set res [RouterRemove]
  if {$res==0} {
    set gaSet(fail) $fail
  } else {
    set ret $res
  }  
  if {$ret!=0} {return $ret}
  
  #{}
  return $ret
}

# ***************************************************************************
# POE
# ***************************************************************************
proc POE {run} {
  set ret [PoePerf]
  MuxMngIO nc    
  return $ret
}
# ***************************************************************************
# GPS
# ***************************************************************************
proc GPS {run} {
  MuxMngIO nc
  set ret [GpsPerf]
  return $ret
}

# ***************************************************************************
# AlarmRunLeds
# ***************************************************************************
proc AlarmRunLeds {run} {
  set ret [AlarmRunLedsPerf]
  return $ret
}
# ***************************************************************************
# CloseUboot_FrontLeds
# ***************************************************************************
proc CloseUboot_FrontLeds {run} {
  set ret [FrontLedsPerf]
  return $ret
}

# ***************************************************************************
# Factory_Settings
# ***************************************************************************
proc Factory_Settings {run} {
  set ret [ReadImei]
  puts "Factory_Settings ret after ReadImei: <$ret>"
  if {$ret!=0} {return $ret}
  set ret [FactorySettingsPerf]
  return $ret
}

# ***************************************************************************
# Mac_BarCode
# ***************************************************************************
proc Mac_BarCode {run} {
  global gaSet  
  puts "Mac_BarCode"
  set pair 1
  mparray gaSet *mac*
  mparray gaSet *barcode*
  mparray gaSet *imei*
  if {$gaSet(dutFam.cell)!=0} {
    if {[llength [array get gaSet *imei*]]==0} {
      set gaSet(fail) "No IMEI was read" 
      return -1
    }
  }
    
  set badL [list]
  set ret -1
  foreach unit {1} {
    if ![info exists gaSet($pair.mac$unit)] {
      set ret [IDPerf]
      if {$ret!=0} {return $ret}
    }  
  } 
  foreach unit {1} {
    if {![info exists gaSet($pair.barcode$unit)] || $gaSet($pair.barcode$unit)=="skipped"}  {
      set ret [ReadBarcode]
      if {$ret!=0} {return $ret}
    }  
  }
  
  set ret [RegBC]  
  if {$ret!=0} {return $ret}
  
  set ret [ImeiSQliteAddLine]  
  return $ret
}

# ***************************************************************************
# WiFi2.4G   WiFi5G
# ***************************************************************************
proc WiFi_2G {run} {
  global gaSet
  Power all off
  after 2000
  Power all on 
  Wait "Wait for up" 15
  
  #FtpDeleteFile  [string tolower startMeasurement_$gaSet(wifiNet)]
  #FtpDeleteFile  [string tolower wifireport_$gaSet(wifiNet).txt]
  catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
  puts "FtpDeleteFile <$res>"
  
  set locWifiReport LocWifiReport_$gaSet(wifiNet).txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  
  #set ret [FtpUploadFile startMeasurement_$gaSet(wifiNet)]
  catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  regexp {result: (-?1) } $res ma ret
  
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 2.4 $locWifiReport]
  
  if {$ret==0} {
    #FtpDeleteFile  [string tolower startMeasurement_$gaSet(wifiNet)]
    #FtpDeleteFile [string tolower wifireport_$gaSet(wifiNet).txt]
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
  
  }

  return $ret
}
# ***************************************************************************
# WiFi5G  
# ***************************************************************************
proc WiFi_5G {run} {
  global gaSet
  Power all off
  after 2000
  Power all on   
  
  Wait "Wait for up" 15
  
  RLSound::Play information
  set txt "Connect Antenna to AUX2. Verify no Antenna on MAIN2"
  set ret [DialogBox -title "WiFi 5G Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "WiFi $baud fail"
    return -1 
  }
  
  #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
  #FtpDeleteFile [string tolower wifireport_$gaSet(wifiNet).txt]
  catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
  puts "FtpDeleteFile <$res>"
  
  set locWifiReport LocWifiReport.txt
  if {[file exists $locWifiReport]} {
    file delete -force $locWifiReport
  }
  set ret [FtpVerifyNoReport]
  if {$ret!=0} {return $ret}
  
  #set ret [FtpUploadFile startMeasurement_$gaSet(wifiNet)]
  catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
  puts "FtpDeleteFile <$res>"
  regexp {result: (-?1) } $res ma ret
  
  
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  set ret [WifiPerf 5 $locWifiReport]
  
  if {$ret==0} {
    #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
    #FtpDeleteFile [string tolower wifireport_$gaSet(wifiNet).txt]
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
  }
  #FtpDeleteFile startMeasurement
  return $ret
}
# ***************************************************************************
# PLC
# ***************************************************************************
proc PLC {run} {
  #set ret [PlcPerf] ; #PlcPerf   PlcAnalogInputPerf
  set ret [PlcAnalogInputPerf] ; #PlcPerf  
  if {$ret!=0} {return $ret}
  set ret [PlcDigitalInputPerf]
  if {$ret!=0} {return $ret} 
  set ret [PlcDigitalOutPerf]
  if {$ret!=0} {return $ret} 
  set ret [PlcLedsPerf]
  return $ret
}
# ***************************************************************************
# LoRa
# ***************************************************************************
proc LoRa {run} {
  MuxMngIO 2ToPc
  set ret [LoraPerf]
}