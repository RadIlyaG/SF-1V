# ***************************************************************************
# TstAlm 
# ***************************************************************************
proc TstAlm {state} {
  global gaSet buffer
  set ret [Login]
  if {$ret!=0} {
    #set ret [Login]
    if {$ret!=0} {return $ret}
  }
  set gaSet(fail) "Logon fail"
  set com $gaSet(comDut)
  Send $com "exit all\r" stam 0.25 
  
  set ret [Send $com "configure reporting\r" ">reporting"]
  if {$ret!=0} {return $ret}
  if {$state=="off"} { 
    set ret [Send $com "mask-minimum-severity log major\r" ">reporting"]
  } elseif {$state=="on"} { 
    set ret [Send $com "no mask-minimum-severity log\r" ">reporting"]
  } 
  return $ret
}

# ***************************************************************************
# PowerResetAndLogin2Uboot
# ***************************************************************************
proc PowerResetAndLogin2Uboot {} {
  puts "[MyTime] PowerResetAndLogin2Uboot"
  Power all off
  after 2000
  Power all on 
  
  set ret [Login2Uboot]
  return $ret 
}
# ***************************************************************************
# PowerResetAndLogin2App
# ***************************************************************************
proc PowerResetAndLogin2App {} {
  global gaSet buffer
  puts "[MyTime] PowerResetAndLogin2App"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match {*SF1v login:*} $buffer]} {
    set ret [Send $com su\r "assword"]
    set ret [Send $com 1234\r $gaSet(appPrompt)] 
    if {$ret==0} {return $ret}   
  }
  

  Power all off
  after 2000
  Power all on 
  
  set ret [Login2App]
  return $ret 
}

# ***************************************************************************
# Login2Uboot
# ***************************************************************************
proc Login2Uboot {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into Uboot"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  }
  
  set gaSet(fail) "Login to Uboot level fail" 
  if {$ret!=0} {
    for {set i 1} {$i<=60} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      puts "Login2Uboot i:$i [MyTime] buffer:<$buffer>" ; update
      #puts "Login2Uboot i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      if {[string match {*to stop autoboot:*} $gaSet(loginBuffer)]} {
        set ret [Send $com \r\r "SF1V=>"]
        if {$ret==0} {break}
      }
      if {[string match {*for safe-mode menu*} $gaSet(loginBuffer)]} {
        set ret [Send $com s "to continue"]
        if {$ret=="-1"} {
          set gaSet(fail) "Enter to safe-mode menu fail"
          break
        } elseif {$ret=="-2"} {
          break
        } elseif {$ret==0} {
          set gaSet(loginBuffer) ""
          set ret [OpenUboot]
          if {$ret!=0} {
            break
          }
        }  
      }
      if {[string match {*SF1V=>*} $gaSet(loginBuffer)]} {
        set ret 0
        break
      }
      if {[string match {*BootROM: Bad header at offset 00000000*} $gaSet(loginBuffer)]} {
        return -1
      }
      after 1000
    }
  }
  
  return $ret
}
# ***************************************************************************
# OpenUboot
# ***************************************************************************
proc OpenUboot {} {
  global gaSet buffer
  set com $gaSet(comDut)
  puts "[MyTime] Open Uboot"
  set ret [Send $com "andromeda\r" "with startup"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to basic safe-mode menu fail"
  } elseif {$ret==0} {
    Send $com "advanced\r" "stam" 1
    set ret [DescrPassword "tech" "with startup"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to advanced safe-mode menu fail"
    } elseif {$ret==0} {
      set ret [Send $com "12\r" "with startup"]
      if {$ret=="-1"} {
        set gaSet(fail) "Enable access to U-BOOT fail"
      } elseif {$ret==0} {
        set ret [Send $com "1\r" "Reset device"]
        if {$ret=="-1"} {
          set gaSet(fail) "Reset device fail"
        } 
      }
    }
  }
  return $ret
}
# ***************************************************************************
# Login2App
# ***************************************************************************
proc Login2App {} {
  global gaSet buffer
  set ret -1
  set gaSet(loginBuffer) ""
  set statusTxt  [$gaSet(sstatus) cget -text]
  Status "Login into Application"
  set com $gaSet(comDut)
  
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  Send $com "\r" stam 0.25
  append gaSet(loginBuffer) "$buffer"
  
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  }
  
  set gaSet(fail) "Login to Application level fail" 
  if {$ret!=0} {
    for {set i 1} {$i<=40} {incr i} {
      $gaSet(runTime) configure -text "$i" ; update
      if {$gaSet(act)==0} {set ret -2; break}
      RLCom::Read $com buffer
      append gaSet(loginBuffer) "$buffer"
      #puts "Login2App i:$i [MyTime] gaSet(loginBuffer):<$gaSet(loginBuffer)>" ; update
      puts "Login2App i:$i [MyTime] buffer:<$buffer>" ; update
      if {[string match {*SF1v login*} $gaSet(loginBuffer)] || [string match {*VB101V login*} $gaSet(loginBuffer)]} {
        set ret [Send $com su\r "assword"]
        set ret [Send $com 1234\r $gaSet(appPrompt)]
        if {[string match {*LOGIN(uid=0)*} $gaSet(loginBuffer)]} {
          set ret [Send $com "exit\r\r\r" "login:"] 
          set ret [Send $com su\r "assword"]
          set ret [Send $com 1234\r $gaSet(appPrompt)]
        }
        
        if {$ret==0} {break}
      }
      if {[string match {*SF1V=>*} $gaSet(loginBuffer)]} {
        return -1
      }
      after 5000
    }
  }
  
  return $ret
}

# ***************************************************************************
# ReadEthPortStatus
# ***************************************************************************
proc ReadEthPortStatus {port} {
  global gaSet buffer bu glSFPs
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read EthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  set ret [Send $com "show status\r" more 8]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  set res [regexp {SFP\+?\sIn} $bu - ]
  if {$res==0} {
    set gaSet(fail) "The status of port $port is not \'SFP In\'"
    return -1
  }
  #21/04/2020 10:18:09
  set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Operational Status of port $port fail"
    return -1
  }
  set opStat [string trim $value]
  puts "opStat:<$opStat>"
  if {$opStat!="Up"} {
    set gaSet(fail) "The Operational Status of port $port is $opStat"
    return -1
  }
  
  set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)Typical} $bu - val]
  if {$res==0} {
    set res [regexp {Manufacturer Part Number :\s([\w\-\s]+)SFP Manufacture Date} $bu - val]
    if {$res==0} {
      set gaSet(fail) "Read Manufacturer Part Number of SFP in port $port fail"
      return -1
    } 
  }
  set val [string trim $val]
  puts "val:<$val> glSFPs:<$glSFPs>" ; update
  if {[lsearch $glSFPs $val]=="-1"} {
    set gaSet(fail) "The Manufacturer Part Number of SFP in port $port is \'$val\'"
    return -1  
  }
  
  return 0
}

# ***************************************************************************
# ReadUtpPortStatus
# ***************************************************************************
proc ReadUtpPortStatus {port} {
  global gaSet buffer bu 
#   Status "Read EthPort Status of $port"
#   set ret [Login]
#   if {$ret!=0} {
#     set ret [Login]
#     if {$ret!=0} {return $ret}
#   }
  Status "Read UtpEthPort Status of $port"
  set gaSet(fail) "Show status of port $port fail"
  set com $gaSet(comDut) 
  Send $com "exit all\r" stam 0.25 
  set ret [Send $com "config port ethernet $port\r" ($port)]
  if {$ret!=0} {return $ret}
  after 2000
  set ret [Send $com "show status\r" more 8]
  set bu $buffer
  set ret [Send $com "\r" ($port)]
  if {$ret!=0} {return $ret}   
  append bu $buffer
  
  puts "ReadEthPortStatus bu:<$bu>"
  set res [regexp {Operational Status[\s\:]+([\w]+)\s} $bu - value]
  if {$res==0} {
    set gaSet(fail) "Read Operational Status of port $port fail"
    return -1
  }
  set opStat [string trim $value]
  puts "opStat:<$opStat>"
  if {$opStat!="Up"} {
    set gaSet(fail) "The Operational Status of port $port is $opStat"
    return -1
  }
  
  return 0
}

# ***************************************************************************
# AdminSave
# ***************************************************************************
proc AdminSave {} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  Status "Admin Save"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "admin save\r" "successfull" 60]
  return $ret
}

# ***************************************************************************
# ShutDown
# ***************************************************************************
proc ShutDown {port state} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "$state of port $port fail"
  Status "ShutDown $port \'$state\'"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r $state" "($port)"]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# SpeedEthPort
# ***************************************************************************
proc SpeedEthPort {port speed} {
  global gaSet buffer
  set com $gaSet(comDut)
  set ret [Login]
  if {$ret!=0} {return $ret}
  set gaSet(fail) "Configuration speed of port $port fail"
  Status "SpeedEthPort $port $speed"
  set ret [Send $com "exit all\r" "2I"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "configure port ethernet $port\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "no auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  #set ret [Send $com "speed-duplex 100-full-duplex rj45\r" "($port)"]
  set ret [Send $com "speed-duplex 100-full-duplex\r" "($port)"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "auto-negotiation\r" "($port)"]
  if {$ret!=0} {return $ret}
  return $ret
}  

# ***************************************************************************
# Pages
# ***************************************************************************
proc Pages {run} {
  global gaSet buffer
  set ret [GetPageFile $gaSet($::pair.barcode1)]
  if {$ret!=0} {return $ret}
  
  set ret [WritePages]
  if {$ret!=0} {return $ret}
  
  return $ret
}
# ***************************************************************************
# LogonDebug
# ***************************************************************************
proc LogonDebug {com} {
  global gaSet buffer
  Send $com "exit all\r" stam 0.25 
  Send $com "logon debug\r" stam 0.25 
  Status "logon debug"
  if {[string match {*command not recognized*} $buffer]==0} {
#     set ret [Send $com "logon debug\r" password]
#     if {$ret!=0} {return $ret}
    regexp {Key code:\s+(\d+)\s} $buffer - kc
    catch {exec $::RadAppsPath/atedecryptor.exe $kc pass} password
    set ret [Send $com "$password\r" ETX-2I 1]
    if {$ret!=0} {return $ret}
  } else {
    set ret 0
  }
  return $ret  
}
# ***************************************************************************
# DescrPassword
# ***************************************************************************
proc DescrPassword {mode prompt} {
  global buffer gaSet
  set com $gaSet(comDut)
  regexp {Challenge code:\s+(\d+)\s} $buffer - kc
  catch {exec $::RadAppsPath/atedecryptor.exe $kc $mode} password
  set ret [Send $com "$password\r" $prompt 1]
  return $ret
}

# ***************************************************************************
# UsbMicroSDcheck
# ***************************************************************************
proc UsbMicroSDcheck {} {
  global buffer gaSet
  puts "\n[MyTime] UsbMicroSDcheck"; update
  set com $gaSet(comDut)
  
  set gaSet(fail) "Scanning usb for storage devices fail"
  Status "Scanning usb for storage devices"
  set ret [Send $com "gpio set B12\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "usb stop\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  after 1000
  set ret [Send $com "usb start\r" "SF1V=>" 60]
  if {$ret!=0} {return $ret}
  set res [regexp {torage devices[\.\s]+(\d)\sStorage} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Scanning usb for storage devices fail"
    return -1
  }
  puts "UsbMicroSDcheck value:<$value>"
  if {$value!="2"} {
    set gaSet(fail) "Only $value devices found. Should be 2"
    #return -1 
  }
  
  set ret [Send $com "fatls usb 0\r" "SF1V=>" 20]
  if {$ret!=0} {
    set gaSet(fail) "Read content of SD_port fail"
    return -1
  }
  if {[string match {*Unrecognized filesystem type*} $buffer]==1} {
    set gaSet(fail) "SD_port fail"
    return -1
  }
  if {[string match {*sd.txt*} [string tolower $buffer]]==0} {
    set gaSet(fail) "sd.txt doesn't exist on SD_port"
    return -1
  } else {
    set ret 0
  }
  
  set ret [Send $com "fatls usb 1\r" "SF1V=>" 20]
  if {$ret!=0} {
    set gaSet(fail) "Read content of DOK_port fail"
    return -1
  }
  if {[string match {*Unrecognized filesystem type*} $buffer]==1} {
    set gaSet(fail) "DOK_port fail"
    return -1
  }
  
  if {[string match {*dok.txt*} [string tolower $buffer]]==0} {
    set gaSet(fail) "dok.txt doesn't exist on DOK_port"
    return -1
  } else {
    set ret 0
  }
  return $ret
}

# ***************************************************************************
# DryContactAlarmcheckFull
# ***************************************************************************
proc neDryContactAlarmcheckFull {} {
  global buffer gaSet
  puts "\n[MyTime] DryContactAlarmcheckFull"; update
  set com $gaSet(comDut)
  
  set gaSet(fail) "Set DryContact fail"
  set ret [Send $com "gpio clear B22\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gpio clear B18\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "gpio input B16\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B16 fail"
    return -1
  }
  puts "B16 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B16 value is $value. Should be 0"
    return -1
  }
  
  set ret [Send $com "gpio input B17\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B17 fail"
    return -1
  }
  puts "B17 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B17 value is $value. Should be 0"
    return -1
  }
  
  set ret [Send $com "gpio set B18\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gpio input B16\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B16 fail"
    return -1
  }
  puts "B16 1 value:<$value>"
  if {$value!="1"} {
    set gaSet(fail) "B16 value is $value. Should be 1"
    return -1
  }
  
  set ret [Send $com "gpio clear B18\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gpio input B16\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B16 fail"
    return -1
  }
  puts "B16 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B16 value is $value. Should be 0"
    return -1
  }
  
  set ret [Send $com "gpio set B22\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gpio input B17\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B17 fail"
    return -1
  }
  puts "B17 1 value:<$value>"
  if {$value!="1"} {
    set gaSet(fail) "B17 value is $value. Should be 1"
    return -1
  }
  
  set ret [Send $com "gpio clear B22\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "gpio input B17\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B17 fail"
    return -1
  }
  puts "B17 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B17 value is $value. Should be 0"
    return -1
  }
  
  return $ret
}

# ***************************************************************************
# DryContactAlarmcheckGo
# ***************************************************************************
proc DryContactAlarmcheck {mode} {
  global buffer gaSet
  puts "\n[MyTime] DryContactAlarmcheck $mode"; update
  set com $gaSet(comDut)
  
  foreach {B18 B22} {clear clear set clear clear set set set} {
    after 500
    puts "\nDryContactAlarmcheckGo B18:$B18 B22:$B22"
    set ret [Send $com "gpio $B18 B18\r" "SF1V=>"]
    if {$ret!=0} {return $ret}
    set ret [Send $com "gpio $B22 B22\r" "SF1V=>"]
    if {$ret!=0} {return $ret}
    RLUsbPio::Set $gaSet(idPioDrContOut) 00000000
    after 500
    RLUsbPio::Get $gaSet(idPioDrContIn) buffer
    set b18bit [string index $buffer end]
    set b22bit [string index $buffer end-1]
    puts "DryContactAlarmcheckGo buffer after 0x8:<$buffer> b18bit:$b18bit b22bit:$b22bit"
    if {$mode=="FULL"} {
      if {$B18=="clear" && $b18bit!="1"} {
        set gaSet(fail) "Relay K1 doesn't work"
        return -1
      } elseif {$B18=="set" && $b18bit!="0"} {
        set gaSet(fail) "Relay K1 doesn't work"
        return -1
      }
      if {$B22=="clear" && $b22bit!="1"} {
        set gaSet(fail) "Relay K2 doesn't work"
        return -1
      } elseif {$B22=="set" && $b22bit!="0"} {
        set gaSet(fail) "Relay K2 doesn't work"
        return -1
      }
    } elseif {$mode=="GO"} {
      if {$b18bit!="1"} {
        set gaSet(fail) "Wrong GO Alarm"
        return -1
      } 
      if {$b22bit!="1"} {
        set gaSet(fail) "Wrong GO Alarm"
        return -1
      } 
    }
    after 500
    RLUsbPio::Set $gaSet(idPioDrContOut) 11111111
    after 500
    RLUsbPio::Get $gaSet(idPioDrContIn) buffer
    puts "DryContactAlarmcheckGo buffer after 1x8:<$buffer>"
  }
  
  Power 2 off
  set ret [Wait "Wait for PowerSupply down" 20]
  if {$ret!=0} {return -1}
  set ret [Send $com "gpio input B16\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B16 fail"
    return -1
  }
  puts "B16 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B16 value is $value. Should be 0"
    return -1
  }
  
  set ret [Send $com "gpio input B17\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B17 fail"
    return -1
  }
  puts "B17 0 value:<$value>"
  if {$value!="0"} {
    set gaSet(fail) "B17 value is $value. Should be 0"
    return -1
  }
  
  Power 2 on
  after 5000
  set ret [Send $com "gpio input B16\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B16 fail"
    return -1
  }
  puts "B16 1 value:<$value>"
  if {$value!="1"} {
    set gaSet(fail) "B16 value is $value. Should be 1"
    return -1
  }
  
  set ret [Send $com "gpio input B17\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set res [regexp {value is\s+(\d)\s+} $buffer ma value]
  if {$res==0} {
    set gaSet(fail) "Read B17 fail"
    return -1
  }
  puts "B17 1 value:<$value>"
  if {$value!="1"} {
    set gaSet(fail) "B17 value is $value. Should be 1"
    return -1
  } 
   Power 2 off
  
  return $ret
}

# ***************************************************************************
# UbootConfIp
# ***************************************************************************
proc UbootConfIp {} {
  global gaSet buffer
  puts "\n[MyTime] UbootConfIp"; update
  set com $gaSet(comDut)
  
  set gaSet(fail) "Set environment variables fail"
  set ret [Send $com "setenv serverip 10.10.10.10\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "setenv ipaddr 10.10.10.10[set gaSet(pair)]\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "saveenv\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  
  for {set i 1} {$i<=10} {incr i} {
    if {$gaSet(act)==0} {set ret -2; return}   
    puts "ping $i"
    set ret [Send $com "ping 10.10.10.10\r" "10.10.10.10 is alive" 11]
    if {$ret==0} {break}

  }
  if {$ret!=0} {
    set gaSet(fail) "10.10.10.10 is not alive" 
  }
  
  return $ret
}  

# ***************************************************************************
# Uboot2eMMC
# ***************************************************************************
proc Uboot2eMMC {} {
  global gaSet buffer
  puts "\n[MyTime] Uboot2eMMC"; update
  set com $gaSet(comDut)
  
  set ret [UbootConfIp]
  if {$ret!=0} {return $ret}
  
  Status "Downloading the \'[file tail $gaSet(UbootSWpath)]\' file"
  
  set gaSet(fail) "Configuration burning UBOOT to eMMC fail"
  set ret [Send $com "mmc partconf 0 1 1 1\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "bubt [file tail $gaSet(UbootSWpath)] mmc\r" "SF1V=>" 180]
  if {$ret!=0} {return $ret}
  
  if {[string match {*checksum..OK*} $buffer] && [string match {*Done*} $buffer] } {
    set gaSet(fail) "Burning UBOOT to eMMC fail"
    set ret -1
  }
  set ret [Send $com "reset\r" "resetting"]
  if {$ret!=0} {return $ret}
  
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  return $ret
}
# ***************************************************************************
# UbootCheckVersionRam
# ***************************************************************************
proc UbootCheckVersionRam {} {
  global gaSet buffer
  puts "\n[MyTime] UbootCheckVersionRam"; update
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  
  set ret [Send $com "reset\r" "resetting"]
  if {$ret!=0} {return $ret}
  
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  
  set res [regexp {\sSF1V-([\w\.]+)\s} $gaSet(loginBuffer) ma val]
  if {$res==0} {
    set gaSet(fail) "Read Uboot parametes fail"
    return -1
  }
  puts "gaSet(dbrUbootSWver):<$gaSet(dbrUbootSWver)> val:<$val>"
  if {$gaSet(dbrUbootSWver) != $val} {
    set gaSet(fail) "Uboot version is \'$val\'. Should be \'$gaSet(dbrUbootSWver)\'"
    return -1
  }
  AddToPairLog $gaSet(pair) "Uboot SW ver: $val"
  
  regexp {DRAM[\:\s]+(\d)\sG} $gaSet(loginBuffer) ma val
  puts "gaSet(dutFam.mem):<$gaSet(dutFam.mem)> val:<$val>"
  if {"$gaSet(dutFam.mem)" != $val} {
    set gaSet(fail) "DRAM is \'$val\'. Should be \'$gaSet(dutFam.mem)\'"
    return -1
  }
  
  return $ret
}  
# ***************************************************************************
# BrdEepromPerf
# ***************************************************************************
proc BrdEepromPerf {} {
  global gaSet buffer
  puts "[MyTime] BrdEepromPerf"
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret!=0} {return $ret}
  
  set ret [BuildEepromString newUut] 
  if {$ret!=0} {return $ret}  
  
  for {set i 1} {$i<=10} {incr i} {
    puts "ping $i"
    set ret [Send $com "ping 10.10.10.10\r" "10.10.10.10 is alive"]
    if {$ret==0} {break}
  }
  if {$ret!=0} {
    set gaSet(fail) "10.10.10.10 is not alive" 
  }
  
  set gaSet(fail) "Programming eEprom fail"
  set ret [Send $com "iic c eeprom.cnt\r" "SF1V=>" 20]  
  if {$ret!=0} {return $ret} 
  
  if {[string match *done* $buffer]==0} {
    set ret [Send $com "\r" "SF1V=>" 20]  
    if {$ret!=0} {return $ret} 
  
    if {[string match *done* $buffer]==0} {
      set gaSet(fail) "Programming eEprom fail. No done"
      return -1
     }
   }
  
  set ret [Send $com "reset\r" "resetting"]  
  if {$ret!=0} {return $ret} 
  
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "iic r 52 200 500\r" "SF1V=>"]  
  if {$ret!=0} {return $ret} 
  
  foreach iv [split $buffer " "] {
    if {[string length $iv]==2} {lappend hexs $iv}
  }
  #set hexsStr [join $hexs " "]

  ## 53 53 3d -> SS=
  ## 2C 4d 41 -> ,MA
  set res [regexp -all {53 53 3d ([\w\s]+) 2c 4d 41} $hexs ma val]
  if {$res==0} {
    set gaSet(fail) "Read Eeprom's content Fail" 
    return -1
  }
  foreach i $val {
    append macc [format %c 0x$i]
  }
  puts "gaSet(eeprom.mac):<$gaSet(eeprom.mac)> macc:<$macc>"
  if {$gaSet(eeprom.mac) != $macc} {
    set gaSet(fail) "$gaSet(eeprom.mac) was programmed, but UUT has $macc"  
  }
  
  return $ret
}

# ***************************************************************************
# SwDownloadPerf
# ***************************************************************************
proc SwDownloadPerf {} {
  global gaSet buffer
  puts "[MyTime] SwDownloadPerf"
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret!=0} {return $ret}
  
#   set ret [UbootConfIp]
#   if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Deleting partions fail"
  set ret [Send $com "mmc dev 0 2\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mmc erase 0 2000\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mmc dev 0 1\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mmc erase 0 2000\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mmc dev 0 0\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "mmc erase 0 2000\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  
  set ret [Uboot2eMMC]
  if {$ret!=0} {return $ret}
  
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  set ret [Send $com "env default -a\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  set ret [Send $com "saveenv\r" "SF1V=>"]
  if {$ret!=0} {return $ret}
  
  set ret [UbootConfIp]
  if {$ret!=0} {return $ret}
  
  Status "Downloading the \'zimage_safe\' and \'armada\' files"
  set ret [Send $com "run tftpsafe\r" "TFTP from server"]  
  if {$ret!=0} {return $ret} 
  set ret [ReadCom $com  "with startup" 180]
  puts "[MyTime] ret after readComWithStartup:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Downloading the \'zimage_safe\' and \'armada\' files fail"
    return $ret
  }
  
  set ret [Send $com "advanced\r" "with startup"]
  if {$ret!=0} {
    set gaSet(fail) "Get advanced UBoot menu fail"
    return $ret
  }
  
  Status "Quick Formatting"
  set ret [Send $com "6\r" "yes/no"]
  set ret [Send $com "yes\r" "QUICK FORMATING"]
  if {$ret!=0} {
    set gaSet(fail) "Start Quick Formatting fail"
    return $ret
  }
  set ret [ReadCom $com "with startup" 120]
  puts "[MyTime] ret after readComQuickFormatting:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Quick Formatting fail"
    return $ret
  }
  
  set ret [Send $com "4\r" "tftp/usb"]
  set ret [Send $com "\r" "server address"]
  set ret [Send $com "10.10.10.10\r" "this machine"]
  set ret [Send $com "10.10.10.10[set gaSet(pair)]\r" "255.255.255.0"]
  set ret [Send $com "255.255.255.0\r" ".tar"]
  if {[string match *VB-101V* $gaSet(dutFam.sf)]} {
    set ret [Send $com "SF_0290_2.3.01.30.tar\r" "tar.gz"]
  } else {
    set ret [Send $com "[file tail $gaSet(UutSWpath)]\r" "tar.gz"]
  }
  set ret [Send $com "[file tail $gaSet(LXDpath)]\r" "tar.lzma"]
  set ret [Send $com "\r" "with startup"]
  if {$ret!=0} {
    set gaSet(fail) "TFTP config fail"
    return $ret
  }
  
#   set ret [Wait "Wait for TFTP config" 20]
#   if {$ret!=0} {return -1}
  
  Status "Loading SW"
  set ret [Send $com "5\r" "yes/no"]
  set ret [Send $com "yes\r" "Loading" 15]
  if {$ret!=0} {
    set gaSet(fail) "Start Loading SW fail"
    return $ret
  }
  set ret [ReadCom $com "y/n" 240]
  puts "[MyTime] ret after readComLoadingSW:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Loading SW fail"
    return $ret
  }
  if {[string match {*tftp: timeout*} $buffer] || [string match {*No such file or directory*} $buffer]} {
    set gaSet(fail) "Loading SW fail"
    return -1
  }
  
  set ret [Send $com "n\r" "with startup"]
  if {$ret!=0} {
    set gaSet(fail) "Get advanced UBoot menu after Loading SW fail"
    return $ret
  }
  
  Status "Loading LXD"
  set ret [Send $com "8\r" "Loading lxd package"]
  if {$ret!=0} {
    set gaSet(fail) "Start Loading LXD fail"
    return $ret
  }
  set ret [ReadCom $com "with startup" 1560]
  puts "[MyTime] ret after readComLoadingLXD:<$ret>" ; update
  if {[string match {*Failed to load lxd package*} $buffer]} {
    after 2000
    Status "Loading LXD"
    set ret [Send $com "8\r" "Loading lxd package"]
    if {$ret!=0} {
      set gaSet(fail) "Start Loading LXD fail"
      return $ret
    }
    set ret [ReadCom $com "with startup" 1560]
    puts "[MyTime] ret after readComLoadingLXD:<$ret>" ; update
  }
  if {$ret!=0} {
    set gaSet(fail) "Loading LXD fail"
    return $ret
  }
  
  Status "HW confg"
  set ret [Send $com "15\r" "sub menu"]
  if {$ret!=0} {
    set gaSet(fail) "HW confg fail"
    return $ret
  }
  set ret [Send $com "1\r" "y/n"]
  if {$gaSet(dutFam.wifi)=="WF"} {
    set ret [Send $com "y\r" "sub menu"]  
  } else {
    set ret [Send $com "n\r" "sub menu"]  
  }
  if {$ret!=0} {
    set gaSet(fail) "HW confg fail"
    return $ret
  }
  set ret [Send $com "0\r" "with startup"]
  if {$ret!=0} {
    set gaSet(fail) "Get advanced UBoot menu after HW config fail"
    return $ret
  }
  
  set ret [Send $com "12\r" "with startup"]
  if {$ret!=0} {
    set gaSet(fail) "Get advanced UBoot menu after Unlook Uboot fail"
    return $ret
  }
  
  set ret [Send $com "1\r" "Reset device"]
  if {$ret!=0} {
    set gaSet(fail) "Reset device fail"
    return $ret
  }
  if {$ret==0} {
    set ret [Login2App]
  }
  return $ret
}  

# ***************************************************************************
# VB101V_SwDownloadPerf
# ***************************************************************************
proc VB101V_SwDownloadPerf {} {
  global gaSet buffer
  puts "[MyTime] VB101V_SwDownloadPerf"
  set com $gaSet(comDut)
  Power all off
  after 2000
  Power all on
  
  set ret [ReadCom $com  "safe-mode menu" 60]
  puts "[MyTime] ret after readComWithStartup:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Reach safe-mode fail"
    return $ret
  }
  
  set ret [Send $com "s\r" "assword"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to basic safe-mode menu fail"
  } elseif {$ret==0} {
    Send $com "andromeda\r" "stam" 1
    Send $com "advanced\r" "stam" 1
    set ret [DescrPassword "tech" "with startup"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to advanced safe-mode menu fail"
    } elseif {$ret==0} {
      set ret [Send $com "4\r" "tftp/usb"]
      set ret [Send $com "\r" "server address"]
      set ret [Send $com "10.10.10.10\r" "this machine"]
      set ret [Send $com "10.10.10.10[set gaSet(pair)]\r" "255.255.255.0"]
      set ret [Send $com "255.255.255.0\r" ".tar"]
      set ret [Send $com "[file tail $gaSet(UutSWpath)]\r" "tar.gz"]
      set ret [Send $com "[file tail $gaSet(LXDpath)]\r" "tar.lzma"]
      set ret [Send $com "\r" "with startup"]
      if {$ret!=0} {
        set gaSet(fail) "TFTP config fail"
        return $ret
      }
      
      Status "Loading SW"
      set ret [Send $com "5\r" "yes/no"]
      set ret [Send $com "yes\r" "Loading" 15]
      if {$ret!=0} {
        set gaSet(fail) "Start Loading SW fail"
        return $ret
      }
      set ret [ReadCom $com "y/n" 240]
      puts "[MyTime] ret after readComLoadingSW:<$ret>" ; update
      if {$ret!=0} {
        set gaSet(fail) "Loading SW fail"
        return $ret
      }
      
      set ret [Send $com "n\r" "with startup"]
      if {$ret!=0} {
        set gaSet(fail) "Get advanced UBoot menu after Loading SW fail"
        return $ret
      }
  
  
      set ret [Send $com "12\r" "with startup"]
      if {$ret!=0} {
        set gaSet(fail) "Get advanced UBoot menu after Unlook Uboot fail"
        return $ret
      }
      
      set ret [Send $com "1\r" "Reset device"]
      if {$ret!=0} {
        set gaSet(fail) "Reset device fail"
        return $ret
      }
      
    }  
  }
  return $ret
}  


# IDPerf
# ***************************************************************************
proc IDPerf {} {
  global gaSet buffer
  puts "[MyTime] IDPerf"
  
  set ret [BuildEepromString fromIDPerf] 
  if {$ret!=0} {return $ret}
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  
  set ret [Send $com "show system info\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Show system info fail"
    return -1
  }
  if [string match {*unknown command*} $buffer] {
    after 2000
    set ret [Send $com "show system info\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {
      set gaSet(fail) "Show system info fail"
      return -1
    }
    if [string match {*unknown command*} $buffer] {
      set gaSet(fail) "Show system info fail"
      return -1
    }
  }
  
  AddToPairLog $gaSet(pair) "$buffer"
  
  set mo1 ""
  regexp {Modem-1[\s\:]+?([\w\/\-]*)\s+Modem-2} $buffer ma mo1
  set mo1 [string trim $mo1]
  if {$gaSet(eeprom.mod1man)=="" && $gaSet(eeprom.mod1type)==""} {
    set eep ""
  } else {
    set eep ${gaSet(eeprom.mod1man)}/${gaSet(eeprom.mod1type)}
  }
  if {$mo1 != $eep} {
    set gaSet(fail) "Modem-1 is \'$mo1\'. Should be \'$eep\'"
    return -1  
  }
  
  set mo2 ""
  regexp {Modem-2[\s\:]+?([\w\/\-]*)\s+MAC} $buffer ma mo2
  set mo2 [string trim $mo2]
  if {$gaSet(eeprom.mod2man)=="" && $gaSet(eeprom.mod2type)==""} {
    set eep ""
  } else {
    set eep ${gaSet(eeprom.mod2man)}/${gaSet(eeprom.mod2type)}
  }
  if {$gaSet(dutFam.wifi)=="WF"} {
    if {$mo2 != "Wi-Fi"} {
      set gaSet(fail) "Modem-2 is \'$mo2\'. Should be \'Wi-Fi\'"
      return -1  
    }
  } else {
    if {$mo2 != $eep} {
      set gaSet(fail) "Modem-2 is \'$mo2\'. Should be \'$eep\'"
      return -1  
    }
  }
  
  set mac ""
  regexp {MAC address[\s\:]+?([\w\:]*)\s+MAIN_} $buffer ma mac
  set mac [string trim $mac]
  set mac1 [join [split $mac :] ""]
  set mac2 0x$mac1
  puts "mac:$mac" ; update
  if {[string match *VB-101V* $gaSet(dutFam.sf)]} {
    if {($mac2<0xA47ACF000000 || $mac2>0xA47ACFFFFFFF)} {
      set gaSet(fail) "The MAC of UUT is $mac. It out of VB's range"
      return -1
    }
  } else {
    if {($mac2<0x0020D2500000 || $mac2>0x0020D2FFFFFF) && ($mac2<0x1806F5000000 || $mac2>0x1806F5FFFFFF)} {
      set gaSet(fail) "The MAC of UUT is $mac. It out of RAD's range"
      return -1
    } 
  }
  
  set gaSet(1.mac1) $mac1
      
  set mcHW ""
  regexp {MAIN_CARD_HW_VERSION[\s\:]+?([\w\.]*)\s+SUB_} $buffer ma mcHW
  set mcHW [string trim $mcHW]
  set eep $gaSet(mainHW)
#   if {$mcHW != $eep} {
#     set gaSet(fail) "MAIN_CARD_HW_VERSION is \'$mcHW\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set sc1HW ""
  regexp {SUB_CARD_1_HW_VERSION[\s\:]+?([\w\.]*)\s+CSL} $buffer ma sc1HW
  set sc1HW [string trim $sc1HW]
  set eep $gaSet(sub1HW)
#   if {$sc1HW != $eep} {
#     set gaSet(fail) "SUB_CARD_1_HW_VERSION is \'$sc1HW\'. Should be \'$eep\'"
#     return -1  
#   }
  
  set csl ""
  regexp {CSL[\s\:]+?([\w\.]*)\s+Part number} $buffer ma csl
  set csl [string trim $csl]
  set eep $gaSet(csl)
#   if {$csl != $eep} {
#     set gaSet(fail) "CSL is \'$csl\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set partNum ""
  regexp {Part number[\s\:]+?([\w\-\/]*)\s+PCB-main} $buffer ma partNum
  set partNum [string trim $partNum]
  set eep $gaSet(DutFullName)
  if {$partNum != $eep} {
    set gaSet(fail) "Part number is \'$partNum\'. Should be \'$eep\'"
    return -1  
  }
   
  set pcbMid ""
  regexp {PCB-main ID[\s\:]+?([\w\-\/\.]*)\s+PCB-sub} $buffer ma pcbMid
  set pcbMid [string trim $pcbMid]
  set eep $gaSet(mainPcbId)
  if {[string match *VB-101V* $gaSet(dutFam.sf)] && ![string match *VB-101V/* $pcbMid]} {
    set gaSet(fail) "PCB-main ID is \'$pcbMid\'. Should contain \'VB-101V\'"
    return -1  
  } elseif {[string match *SF-1V* $gaSet(dutFam.sf)] && ![string match *SF-1V/* $pcbMid]} {
    set gaSet(fail) "PCB-main ID is \'$pcbMid\'. Should contain \'SF-1V\'"
    return -1  
  }
#   if {$pcbMid != $eep} {
#     set gaSet(fail) "PCB-main ID is \'$pcbMid\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set pcbS1id ""
  regexp {PCB-sub-card-1 ID[\s\:]+?([\w\-\/\.]*)\s+PS} $buffer ma pcbS1id
  set pcbS1id [string trim $pcbS1id]
  set eep $gaSet(sub1PcbId)
  if {[string match *VB-101V* $gaSet(dutFam.sf)] && ![string match *VB-101V/* $pcbS1id]} {
    set gaSet(fail) "PCB-sub-card-1 ID is \'$pcbS1id\'. Should contain \'VB-101V\'"
    return -1  
  } elseif {[string match *SF-1V* $gaSet(dutFam.sf)] && ![string match *SF-1V/* $pcbS1id]} {
    set gaSet(fail) "PCB-sub-card-1 ID is \'$pcbS1id\'. Should contain \'SF-1V\'"
    return -1  
  }
#   if {$pcbS1id != $eep} {
#     set gaSet(fail) "PCB-sub-card-1 ID is \'$pcbS1id\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set ps ""
  regexp {PS[\s\:]+?([\w\-\/\.]*)\s+SD-slot} $buffer ma ps
  set ps [string trim $ps]
  set eep $gaSet(eeprom.ps)
#   if {$ps != $eep} {
#     set gaSet(fail) "PS is \'$ps\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set sd ""
  regexp {SD-slot[\s\:]+?([\w\-\/\.]*)\s+Serial-1} $buffer ma sd
  set sd [string trim $sd]
  set eep YES
#   if {$sd != $eep} {
#     set gaSet(fail) "SD-slot is \'$sd\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set ser1 ""
  regexp {Serial-1[\s\:]+?([\w\-\/\.]*)\s+Serial-2} $buffer ma ser1
  set ser1 [string trim $ser1]
  set eep $gaSet(eeprom.ser1)
#   if {$ser1 != $eep} {
#     set gaSet(fail) "Serial-1 is \'$ser1\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set ser2 ""
  regexp {Serial-2[\s\:]+?([\w\-\/\.]*)\s+SERIAL-1-CTS} $buffer ma ser2
  set ser2 [string trim $ser2]
  set eep $gaSet(eeprom.ser2)
#   if {$ser2 != $eep} {
#     set gaSet(fail) "Serial-2 is \'$ser2\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set ser1cts ""
  regexp {SERIAL-1-CTS-DTR[\s\:]+?([\w\-\/\.]*)\s+SERIAL-2-CTS} $buffer ma ser1cts
  set ser1cts [string trim $ser1cts]
  set eep YES
#   if {$ser1cts != $eep} {
#     set gaSet(fail) "SERIAL-1-CTS-DTR is \'$ser1cts\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set ser2cts ""
  regexp {SERIAL-2-CTS-DTR[\s\:]+?([\w\-\/\.]*)\s+RS485-1} $buffer ma ser2cts
  set ser2cts [string trim $ser2cts]
  set eep YES
#   if {$ser2cts != $eep} {
#     set gaSet(fail) "SERIAL-2-CTS-DTR is \'$ser2cts\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set RS4851 ""
  regexp {RS485-1[\s\:]+?([\w\-\/\.]*)\s+RS485-2} $buffer ma RS4851
  set RS4851 [string trim $RS4851]
  set eep $gaSet(eeprom.1rs485)
#   if {$RS4851 != $eep} {
#     set gaSet(fail) "RS485-1 is \'$RS4851\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set RS4852 ""
  regexp {RS485-2[\s\:]+?([\w\-\/\.]*)\s+POE} $buffer ma RS4852
  set RS4852 [string trim $RS4852]
  set eep $gaSet(eeprom.2rs485)
#   if {$RS4852 != $eep} {
#     set gaSet(fail) "RS485-2 is \'$RS4852\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set poe ""
  regexp {POE[\s\:]+?([\w\-\/\.]*)\s+Dry-Contact} $buffer ma poe
  set poe [string trim $poe]
  set eep $gaSet(eeprom.poe)
#   if {$poe != $eep} {
#     set gaSet(fail) "POE is \'$poe\'. Should be \'$eep\'"
#     return -1  
#   }   
   
  set dc ""
  regexp {Dry-Contact[\s\:]+?([\w\-\/\.]*)\s+USB-A} $buffer ma dc
  set dc [string trim $dc]
  set eep YES
#   if {$dc != $eep} {
#     set gaSet(fail) "Dry-Contact is \'$dc\'. Should be \'$eep\'"
#     return -1  
#   }
   
  set usb ""
  regexp {USB-A[\s\:]+?([\w\-\/\.]*)\s+SecFlow} $buffer ma usb
  set usb [string trim $usb]
  set eep YES
#   if {$usb != $eep} {
#     set gaSet(fail) "USB-A is \'$usb\'. Should be \'$eep\'"
#     return -1  
#   }

  set ret [Send $com "os-image show-list\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Show system info fail"
    return -1
  }
  
  set sw NA
  set state NA
  if {[string match *VB-101V* $gaSet(dutFam.sf)]} {
    set res [regexp {VB_\d{4}_([\d\w\.]+?)\.tar\s+\((\w+)\)} $buffer ma sw state]
  } else {
    set res [regexp {SF_\d{4}_([\d\w\.]+?)\.tar\s+\((\w+)\)} $buffer ma sw state]
  }
  if {$res==0} {
    set gaSet(fail) "Read os-image list fail"
    return -1 
  }
  
  if {$gaSet(uutSWfrom)=="fromDbr"} {
    if {$sw!=$gaSet(SWver)} {
      set gaSet(fail) "The SW is \'$sw\'. Should be \'$gaSet(SWver)\'" 
      return -1 
    }
  } else {
    set UutSWfile [lindex [split [file rootname [file tail $gaSet(UutSWpath)]] _] 2]
    if {$sw!=$UutSWfile} {
      set gaSet(fail) "The SW is \'$sw\'. Should be \'$UutSWfile\'" 
      return -1 
    }
  }
  if {$state!="active"} {
    set gaSet(fail) "The SW state is \'$state\'. Should be \'active\'" 
    return -1 
  }
  AddToPairLog $gaSet(pair) "SW ver: $sw active"
   
  return $ret
}  
# ***************************************************************************
# CellularModemPerf
# ***************************************************************************
proc CellularModemPerf {slot l4} {
  global gaSet buffer
  puts "[MyTime] CellularModemPerf $slot $l4"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem fail" 
  set ret [Send $com "cellular disable\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  
  if {[string match {*cellular already disabled*} $buffer]} {
    ## skip waiting
  } else {
    set ret [Wait "Wait for cellular disable" 20]
    if {$ret!=0} {return -1}
  }
  
  set ret [Send $com "cellular wan update sim-slot [expr {3-$slot}] admin-status disable\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  if {$l4=="notL4"} {
    set ret [Send $com "cellular wan update sim-slot $slot admin-status enable operator-name cellcom apn-name Statreal user-name guest password guest\r" "$gaSet(appPrompt)"]
  } elseif {$l4=="L4"} {
    set ret [Send $com "cellular wan update sim-slot $slot admin-status enable operator-name cellcom apn-name Statreal user-name guest password guest connection-method ppp\r" "$gaSet(appPrompt)"]
  }
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  set ret [Send $com "cellular settings update default-route yes\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  for {set i 1} {$i<=30} {incr i} {
    Status "Waif for powering down" 
    set ret [Send $com "cellular enable\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
    if {[string match {*still powering down*} $buffer] } {
      after 3000
    } elseif {[string match {*cellular enabled*} $buffer] } {
      break
    }
  }  
  
  set sec1 [clock seconds]
  set st NA
  for {set i 1} {$i<=40} {incr i} {
    # puts "[MyTime] CellularModemPerf.1 i:$i"
    set sec2 [clock seconds]
    set aft [expr {$sec2-$sec1}]
    set ret [Wait "Slot-$slot Wait for cellular (after $aft sec: $st)" 10]
    if {$ret!=0} {return -1}
    
    set ret [Send $com "cellular network show\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
    
    set st "NA" 
    set rssi "NA"
    set res [regexp " $slot\[\\s\\|\]\+\(\[A\-Z\\.\]\+\)\\!\?\\s" $buffer ma st]
    puts "CellularModemPerf $slot i:$i st:<$st>"
    
    if {$st=="CONNECTED"} {
      set ret 0
      set res [regexp " $slot\.\+\?No\[\\s\\|\]\+\(\-\\d\{2\}\)" $buffer ma rssi]
      break
    } else {
      #set ret [Wait "Slot-$slot Wait for cellular ($i. $st)" 8]
      #if {$ret!=0} {return -1}
    } 
  }  
  puts "[MyTime] CellularModemPerf $slot i:$i st:<$st> rssi:<$rssi>"
  set sec2 [clock seconds]
  set aft [expr {$sec2-$sec1}]
  
  if {$st!="CONNECTED"} {
    set gaSet(fail) "After $aft sec Oper Status of slot-$slot is \'$st\'. Should be \'CONNECTED\'" 
    return -1
  }
  
  AddToPairLog $gaSet(pair) "RSSI of slot-$slot is \'$rssi\'"
  if {$rssi>"-51" || $rssi<"-90"} {
    set gaSet(fail) "RSSI of slot-$slot is \'$rssi\'. Should be between -51 and -90" 
    return -1
  }
  
  set ret [Ping2Cellular $slot "8.8.8.8"]
  if {$ret=="-1"} {
    set ret [Ping2Cellular $slot "8.8.8.8"]
    if {$ret=="-1"} {
      set ret [Ping2Cellular $slot "8.8.8.8"]
    }
  }
  
  return $ret
}  

# ***************************************************************************
# Ping2Cellular
# ***************************************************************************
proc Ping2Cellular {slot ip} {
  global gaSet buffer
  Status "Ping to $slot $ip"
  
  set com $gaSet(comDut)
  set ret [Send $com "\r\r" $gaSet(appPrompt)]
  set ret [Send $com "ping $ip\r" $gaSet(appPrompt)]
  if {$ret!=0} {
    set gaSet(fail) "Sending pings from slot-$slot to $ip fail"
    return $ret
  } 
  if {[string match {*Network is unreachable*} $buffer]} {
    after 5000
    set ret [Send $com "ping $ip\r" $gaSet(appPrompt)]
    if {$ret!=0} {
      set gaSet(fail) "Sending pings from slot-$slot to $ip fail"
      return $ret
    }
  }
  set res1 [regexp {(\d) packets received} $buffer ma val1]  
  set res2 [regexp {(\d+)% packet loss} $buffer ma val2]
  if {$res1==0 || $res2==0} {
    set gaSet(fail) "Read pings from slot-$slot to $ip fail"
    return -1 
  }
  if {$val1!=5} {
    set gaSet(fail) "Ping fail - received $val1 packets. Should be 5" 
    return -1 
  }
  set mutar 16
  set mutar 0
  if {$val2!="$mutar"} {
    set gaSet(fail) "Ping fail - ${val2}% packet loss" 
    return -1 
  }
  return 0
}
  
# ***************************************************************************
# CellularFirmware
# ***************************************************************************
proc CellularFirmware {} {
  global gaSet buffer
  puts "[MyTime] CellularFirmware"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem fail" 
  set ret [Send $com "cellular disable\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  
  if {[string match {*cellular already disabled*} $buffer]} {
    ## skip waiting
  } else {
    set ret [Wait "Wait for cellular disable" 20]
    if {$ret!=0} {return -1}
  }
  
  set gaSet(fail) "Read modem version fail" 
  set ret [Send $com "cellular modem power-up\r" "$gaSet(appPrompt)" 30]
  if {$ret!=0} {return -1}
  set ret [Send $com "cellular modem get version\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem version fail"
    return -1 
  }
  set fw [string trim $val]
  set mdm [string range $gaSet(dutFam.cell) 1 end] 
  set cellFwL $gaSet($mdm.fwL)
  puts "CellularFirmware fw:<$fw> mdm:<$mdm> cellFwL:<$cellFwL>"
  if {[lsearch $cellFwL $fw]!="-1"} {
    set ret 0
  } else {
    set gaSet(fail) "The FW is \'$fw\'. Should be one of $cellFwL"
    set ret -1 
  }
  
  set ret [Send $com "cellular modem get imei\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  Send $com "cellular modem power-down\r" "$gaSet(appPrompt)" 
  
  return $ret
}
# ***************************************************************************
# CellularModemPerfDual
# ***************************************************************************
proc CellularModemPerfDual {l4} {
  global gaSet buffer
  puts "[MyTime] CellularModemPerfDual $l4"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration dual modem fail" 
  Status "Modem 1 power-down"
  set ret [Send $com "cellular modem 1 power-down\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    after 2000
    set ret [Send $com "cellular modem 1 power-down\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {
      after 2000
      set ret [Send $com "cellular modem 1 power-down\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {return -1}
    }
  }
  Status "Modem 2 power-down"
  set ret [Send $com "cellular modem 2 power-down\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    after 2000
    set ret [Send $com "cellular modem 2 power-down\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {
      after 2000
      set ret [Send $com "cellular modem 2 power-down\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {return -1}
    }
  }
  
  foreach mdm {1 2} {
    for {set i 1} {$i<=20} {incr i} {
      Status "Waif for powering down"    
      set ret [Send $com "cellular disable modem-id $mdm\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular disabled*} $buffer] || [string match {*already disabled*} $buffer] } {
        break
      }
    }  
  }
  
  
  set ret [Send $com "router static\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "enable\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "configure terminal\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "ip route 8.8.8.0/24 ppp0\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "ip route 151.101.2.0/24 ppp1\r" "config"]
  if {$ret!=0} {return -1}
  set ret [Send $com "exit\r" "static"]
  if {$ret!=0} {return -1}
  set ret [Send $com "exit\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  
  if {$l4=="notL4"} {
    set ret [Send $com "cellular wan update sim-slot 1 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest radio-access-technology auto connection-method direct-IP\r" "$gaSet(appPrompt)"]
  } elseif {$l4=="L4"} {
    set ret [Send $com "cellular wan update sim-slot 1 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest connection-method ppp\r" "$gaSet(appPrompt)"]
  }  
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  if {$l4=="notL4"} {
    set ret [Send $com "cellular wan update sim-slot 2 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest radio-access-technology auto connection-method direct-IP\r" "$gaSet(appPrompt)"]
  } elseif {$l4=="L4"} {
    set ret [Send $com "cellular wan update sim-slot 2 admin-status enable operator-name cellcom apn-name internetg user-name guest password guest connection-method ppp\r" "$gaSet(appPrompt)"]
  }
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  set ret [Send $com "cellular settings update modem-id 1 default-route no\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  set ret [Send $com "cellular settings update modem-id 2 default-route no\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*Completed OK*} $buffer]==0} {return -1}
  
  foreach mdm {1 2} {
    for {set i 1} {$i<=30} {incr i} {
      Status "Waif for powering down and up" 
      set ret [Send $com "cellular enable modem-id $mdm\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular enabled*} $buffer] || [string match {*cellular already enabled*} $buffer]} {
        break
      }
    }  
  }
  
  set sec1 [clock seconds]
  set st1 [set st2 NA]
  for {set i 1} {$i<=40} {incr i} {
    # puts "[MyTime] CellularModemPerf.1 i:$i"
    set sec2 [clock seconds]
    set aft [expr {$sec2-$sec1}]
    set ret [Wait "Slot-1&2 Wait for cellular (after $aft sec: $st1 $st2)" 10]
    if {$ret!=0} {return -1}
    
    set ret [Send $com "cellular network show\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
    
    set st1 "NA" 
    set rssi1 "NA"
    set st2 "NA" 
    set rssi2 "NA"
    set res [regexp { 1[\s\|]+([A-Z\.]+?)\!?\s} $buffer ma st1]
    puts "CellularDualModemPerf 1 i:$i res1:<$res> st1:<$st1>"
    set res [regexp { 2[\s\|]+([A-Z\.]+?)\!?\s} $buffer ma st2]
    puts "CellularDualModemPerf 2 i:$i res2:<$res> st2:<$st2>"
    
    if {$st1=="CONNECTED" && $st2=="CONNECTED"} {
      set ret 0
      set res [regexp {1.+?No[\s\|]+(-\d{2})} $buffer ma rssi1]
      set res [regexp {2.+?No[\s\|]+(-\d{2})} $buffer ma rssi2]
      break
    } else {
#       set ret [Wait "Slot-1&2 Wait for cellular ($i. $st1 $st2)" 8]
#       if {$ret!=0} {return -1}
    }
  }  
  puts "[MyTime] CellularDualModemPerf i:$i st1:<$st1> rssi1:<$rssi1> st2:<$st2> rssi2:<$rssi2>"
   set sec2 [clock seconds]
  set aft [expr {$sec2-$sec1}]
  if {$st1!="CONNECTED"} {
    set gaSet(fail) "After $aft sec Oper Status of slot-1 is \'$st1\'. Should be \'CONNECTED\'" 
    return -1
  }
  if {$st2!="CONNECTED"} {
    set gaSet(fail) "After $aft sec Oper Status of slot-2 is \'$st2\'. Should be \'CONNECTED\'" 
    return -1
  }
  
  AddToPairLog $gaSet(pair) "RSSI of slot-1 is \'$rssi1\'"
  AddToPairLog $gaSet(pair) "RSSI of slot-2 is \'$rssi2\'"
  
  if {$rssi1>"-51" || $rssi1<"-90"} {
    set gaSet(fail) "RSSI of slot-1 is \'$rssi1\'. Should be between -51 and -90" 
    return -1
  }
  if {$rssi2>"-51" || $rssi2<"-90"} {
    set gaSet(fail) "RSSI of slot-2 is \'$rssi2\'. Should be between -51 and -90" 
    return -1
  }
  
  set ret [Ping2Cellular 1 "8.8.8.8"]
  if {$ret=="-1"} {
    set ret [Ping2Cellular 1 "8.8.8.8"]
    if {$ret=="-1"} {
      set ret [Ping2Cellular 1 "8.8.8.8"]
    }
  }
  if {$ret!=0} {return $ret}
  
  set ret [Ping2Cellular 2 "151.101.2.1"]
  if {$ret=="-1"}  {
    set ret [Ping2Cellular 2 "151.101.2.1"]
  }
  if {$ret!=0} {return $ret}
    
  return $ret
}  
# ***************************************************************************
# CellularFirmwareDual
# ***************************************************************************
proc CellularFirmwareDual {} {
  global gaSet buffer
  puts "[MyTime] CellularFirmwareDual"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration modem fail" 
 
  foreach mdm {1 2} {
    for {set i 1} {$i<=20} {incr i} {
      Status "Waif for modem $mdm powering down" 
      set ret [Send $com "cellular disable modem-id $mdm\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {return -1}
      if {[string match {*still powering down*} $buffer] } {
        after 3000
      } elseif {[string match {*cellular disabled*} $buffer] || [string match {*already disabled*} $buffer] } {
        break
      }
    }  
  }
  
  set gaSet(fail) "Read modem version fail" 
  Status "Modem 1 power-up"
  set ret [Send $com "cellular modem 1 power-up\r" "$gaSet(appPrompt)" 30]
  if {$ret!=0} {return -1}
  Status "Modem 2 power-up"
  set ret [Send $com "cellular modem 2 power-up\r" "$gaSet(appPrompt)" 30]
  if {$ret!=0} {return -1}
  
  
  Status "Modem 1 get version"
  set gaSet(fail) "Read modem 1 version fail" 
  set ret [Send $com "cellular modem 1 get version\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*failed to communicate with modem*} $buffer]} {
    set ret [Send $com "cellular modem 1 power-down\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 1 power-up\r" "$gaSet(appPrompt)" 30]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 1 get version\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
  }
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val1]
  if {$res==0} {
    set gaSet(fail) "Read modem 1 version fail"
    return -1 
  }
  set fw1 [string trim $val1]
  
  set ret [Send $com "cellular modem 1 get imei\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem 1 IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  Status "Modem 2 get version"
  set gaSet(fail) "Read modem 2 version fail" 
  set ret [Send $com "cellular modem 2 get version\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  if {[string match {*failed to communicate with modem*} $buffer]} {
    set ret [Send $com "cellular modem 2 power-down\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 2 power-up\r" "$gaSet(appPrompt)" 30]
    if {$ret!=0} {return -1}
    set ret [Send $com "cellular modem 2 get version\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {return -1}
  }
  
  set res [regexp {Version[\s\:]+(\w+)\s} $buffer ma val2]
  if {$res==0} {
    set gaSet(fail) "Read modem 2 version fail"
    return -1 
  }
  set fw2 [string trim $val2]
  
  set ret [Send $com "cellular modem 2 get imei\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return -1}
  set res [regexp {IMEI[\s\:]+(\w+)\s} $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read modem 2 IMEI fail"
    return -1 
  }
  set gaSet(1.imei1) $val
  
  set mdm [string range $gaSet(dutFam.cell) 1 end] 
  set cellFwL $gaSet($mdm.fwL)
  puts "CellularFirmware fw1:<$fw1>  fw2:<$fw2>  mdm:<$mdm> cellFwL:<$cellFwL>"

  if {[lsearch $cellFwL $fw1]!="-1" && [lsearch $cellFwL $fw2]!="-1"} {
    set ret 0
  } elseif {[lsearch $cellFwL $fw1]=="-1"} {
    set gaSet(fail) "The FW of modem-1 is \'$fw1\'. Should be one of $cellFwL"
    set ret -1 
  } elseif {[lsearch $cellFwL $fw2]=="-1"} {
    set gaSet(fail) "The FW of modem-2 is \'$fw2\'. Should be one of $cellFwL"
    set ret -1 
  }
  Send $com "cellular modem 1 power-down\r" "$gaSet(appPrompt)" 
  Send $com "cellular modem 2 power-down\r" "$gaSet(appPrompt)" 
  
  return $ret
}
  
# ***************************************************************************
# SerialPortsPerf
# ***************************************************************************
proc SerialPortsPerf {ser} {
  global gaSet buffer
  if {$ser==2 && $gaSet(dutFam.serPort)=="2RS"} {
    set ser 2
  } elseif {$ser==2 && $gaSet(dutFam.serPort)=="2RSM"} {
    set ser 485
  }
  puts "[MyTime] SerialPortsPerf Serial-$ser"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2 
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
       
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  switch -exact -- $ser {
    1 {set dev "/dev/ttySC0"}
    2 - 485 {set dev "/dev/ttySC1"}
  }  
  #set dev "/dev/ttySC[expr {$ser - 1}]" ; # /dev/ttySC0 for Ser1 and  /dev/ttySC1 for Ser2
  set gaSet(fail) "Configuration Serial-$ser fail" 
  set ret [Send $com "cat $dev &\r" "#"]
  if {$ret!=0} {return -1}
  Send $com "bgPid=\$\!\r" "#" 2
  
  Send $gaSet(comSer$ser) \r stam 0.5
  
  Status "Send from Console to Serial-$ser"
  set txt1.Ser1 "ABCD1234"
  set txt1.Ser485 [set txt1.Ser2 "EFGH0987"]
  set txt1 [set txt1.Ser$ser]
  
  for {set i 1} {$i<=2} {incr i} {
    set ret [Send $com "echo \"1\r2\r\" > $dev\r" "#"]
    set ret [RLCom::Read $gaSet(comSer$ser) buffer]
    puts "buffer:<$buffer>"
    set ret [Send $com "echo \"$txt1\" > $dev\r" "#"]
    if {$ret!=0} {return -1}
    set ret [ReadCom $gaSet(comSer$ser) "$txt1" 3]
    puts "ret after i:$i readCom1.Ser-$ser:<$ret>" ; update
    if {$ret==0} {break}
  }
  if {$ret!=0} {
    set gaSet(fail) "Read \'$txt1\' on Serial-$ser fail" 
    return $ret
  }
  
  Status "Send from Serial-$ser to Console"
  set txt2.Ser1 "1234ABCD"
  set txt2.Ser485 [set txt2.Ser2 "10987EFGH"]
  set txt2 [set txt2.Ser$ser]
  
  for {set i 1} {$i<=2} {incr i} {
    #set ret [Send $gaSet(comSer$ser) "2\r1\r" "stam" 0.5]
    RLCom::SendSlow $gaSet(comSer$ser) "2\r1\r" 100 buffer "stam" 1
    set ret [RLCom::Read $com buffer]
    puts "buffer:<$buffer>"
    #set ret [Send $gaSet(comSer$ser) "$txt2\r" "stam" 0.5]
    RLCom::SendSlow $gaSet(comSer$ser) "$txt2\r" 100 buffer "stam" 1
    set ret [ReadCom $com "$txt2" 3]
    puts "ret after i:$i  readCom2.Cons:<$ret>" ; update
    if {$ret==0} {break}
  }
  if {$ret!=0} {
    set gaSet(fail) "Read \'$txt2\' from Serial-$ser fail" 
    return $ret
  }
  
  return $ret
  
}
# ***************************************************************************
# SerialCloseBackGrPr
# ***************************************************************************
proc SerialCloseBackGrPr {ser mode} {
  global gaSet buffer
  if {$ser==2 && $gaSet(dutFam.serPort)=="2RS"} {
    set ser 2
  } elseif {$ser==2 && $gaSet(dutFam.serPort)=="2RSM"} {
    set ser 485
  }
  Send $gaSet(comSer$ser) "kill \$bgPid\r" \#
  if {$mode=="Exit"} {
    Send $gaSet(comSer$ser) "exit\r\r\r" login
  }
  return 0
}

# ***************************************************************************
# DataPerf
# ***************************************************************************
proc DataPerf {port} {
  global gaSet buffer
  puts "[MyTime] DataPerf ETH-$port"
  
  MuxMngIO ${port}ToPc
  
  set gaSet(fail) "Configuration Eth-$port fail" 
  set ret [RouterCreate $port]
  if {$ret!=0} {return $ret}
  
  set com $gaSet(comDut)
  Send $com "exit\r\r" login: 2
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 90]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }

  Status "Eth-$port. Delete old testing files"
  set ret [Send $com "rm /tmp/EthTestRef*\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Delete old testing files fail"
    return -1
  }
  if [catch {file delete -force c:/download/sf1v/EthTestCheck.$gaSet(pair).$port} res] {
    set gaSet(fail) "$res" 
    return -1
  }
  
  set ref c:/download/sf1v/EthTestRef$port
  if ![file exists $ref] {
    set gaSet(fail) "File \'$ref\' doesn't exist" 
    return -1
  }
  
   ## tftp -g -r EthTestRef2 -l /tmp/EthTestRef2 10.10.10.10
  Send $com "ls /tmp/Eth*\r" rr 1
  Status "Eth-$port. Download file to UUT"
  set ret [Send $com "tftp -g -r EthTestRef$port -l /tmp/EthTestRef$port 10.10.10.10\r" "#" 25]
  if {$ret!=0} {
    set gaSet(fail) "Download file to UUT via ETH-$port fail"
    return -1
  }
  Send $com "ls /tmp/Eth*\r" rr 1
  if {[string match {*No such file or directory*} $buffer]} {
    set gaSet(fail) "No file EthTestRef$port at UUT's /tmp folder"
    return -1
  }
  
  
  ## tftp -p -l /tmp/EthTestRef2 -r EthTestCheck2 10.10.10.10
  Status "Eth-$port. Upload file to PC"
  set ret [Send $com "tftp -p -l /tmp/EthTestRef$port -r EthTestCheck.$gaSet(pair).$port  10.10.10.10\r" "#" 25]
  if {$ret!=0} {
    set gaSet(fail) "Upload file to PC via ETH-$port fail"
    return -1
  }
  
  if {[string match *error* $buffer]} {
    set gaSet(fail) "Error during uploading"
    return -1
  }
  
  set chk c:/download/sf1v/EthTestCheck.$gaSet(pair).$port
  if ![file exists $chk] {
    set gaSet(fail) "File \'$chk\' doesn't exist" 
    return -1
  }
  
  set res [SameContent $ref $chk]
  puts "[MyTime] Res of SameContent $ref $chk : <$res>"
  if {$res!="1"} {
    set gaSet(fail) "Eth-$port. Files \'$ref \' and \'$chk\' are not equal"
    return $ret 
  }
  set refSize [file size $ref]
  set chkSize [file size $chk]
  puts "refSize:<$refSize> chkSize:<$chkSize>" ; update
  if {$refSize!=$chkSize} {
    set gaSet(fail) "Eth-$port. Files \'$ref \' and \'$chk\have different size - $refSize and $chkSize"
    return -1 
  }
  
  
  ## exec taskkill.exe /F /IM 3cdaemon.exe
  ## exec C:\\\Program\ Files\ (x86)\\3Com\\3CDaemon\\3cdaemon.exe &
  
  if [catch {file delete -force $chk} res] {
    exec taskkill.exe /F /IM 3cdaemon.exe
    after 5000
    exec C:\\\Program\ Files\ (x86)\\3Com\\3CDaemon\\3cdaemon.exe &
    after 5000
    if [catch {file delete -force $chk} res] {
      puts "\n fail file delete -force $chk , res: <$res>"
      update
    }
  }
  
  return $ret
}  
# ***************************************************************************
# RouterCreate
# ***************************************************************************
proc RouterCreate {port} {
  global gaSet buffer
  puts "[MyTime] RouterCreate $port"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match " \# " $buffer]} {
    Send $com "exit\r" "login:"
    set ret [Login2App]
  } elseif {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "router interface create address-prefix 10.10.10.10[set gaSet(pair)]/24 physical-interface eth$port interface-id 1\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Router Create on Eth-$port fail" 
    return -1
  }
  
  Status "Check Eth-$port link status"
  set ret [Send $com "port show status\r" $gaSet(appPrompt)]
  if {$ret!=0} {
    set gaSet(fail) "Read port show status fail" 
    return -1
  }
  set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
  if {$res==0} {
    set gaSet(fail) "Read port show status fail" 
    return -1
  }
  puts "RouterCreate $port ma:<$ma> val:<$val>"
  if {$val!="UP"} {
    after 10000
    set ret [Send $com "port show status\r" $gaSet(appPrompt)]
    if {$ret!=0} {
      set gaSet(fail) "Read port show status fail" 
      return -1
    }
    set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read port show status fail" 
      return -1
    }
    puts "RouterCreate $port ma:<$ma> val:<$val>"
    if {$val!="UP"} {
      after 10000
      set ret [Send $com "port show status\r" $gaSet(appPrompt)]
      if {$ret!=0} {
        set gaSet(fail) "Read port show status fail" 
        return -1
      }
      set res [regexp "eth$port\[\\s\\|\]+\(UP\|DOWN\)\\s" $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read port show status fail" 
        return -1
      }
      puts "RouterCreate $port ma:<$ma> val:<$val>"
      if {$val!="UP"} {
        set gaSet(fail) "Link of Eth-$port isn't UP" 
        set ret "-1"
      } else {
        set ret "0"
      }  
    } else {
      set ret "0"
    }
  } else {
    set ret "0"
  }
  
  return $ret
}
# ***************************************************************************
# RouterRemove
# ***************************************************************************
proc RouterRemove {} {
  global gaSet buffer
  puts "[MyTime] RouterRemove"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match " \# " $buffer]} {
    Send $com "exit\r" "login:"
    set ret [Login2App]
  } elseif {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "router interface remove interface-id 1\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Router Remove fail"
    return -1
  }
  
  return $ret
}
# ***************************************************************************
# PoePerf
# ***************************************************************************
proc PoePerf {} {
  global gaSet buffer
  set poe $gaSet(dutFam.poe)
  puts "[MyTime] PoePerf $poe"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2 
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update       
    }
  }
  if {$ret!=0} {return $ret}
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  Status "POE configuration"
  
  foreach port [list 2 3 4 5] {
    Status "Eth-$port. POE show"
    set ret [Send $com "poe disable\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {set gaSet(fail) "Set poe disable fail" ;  return -1}
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      MuxMngIO ${port}ToAirMux
    } else {  
      MuxMngIO ${port}ToPhone
    }
    after 2000
    set ret [Send $com "poe enable\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {set gaSet(fail) "Set poe enable fail" ;  return -1}
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set mP 30
    } else {
      set mP 15
    }
    set ret [Send $com "poe ports update admin-status enable max-power $mP port-id $port\r" "$gaSet(appPrompt)"]
    after 5000
    if {$ret!=0} {set gaSet(fail) "Set poe admin-status of port-$port fail" ;  return -1}
    set ret [Send $com "poe show\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {set gaSet(fail) "Poe show fail" ;  return -1}
    
    set res [regexp {tion:\s+(\w+)\s} $buffer ma val]
    if {$res==0} {
      set gaSet(fail) "Read POE HW Configuration fail" 
      return -1
    }
    if {$val!="$poe"} {
      set gaSet(fail) "POE HW Configuration is \'$val\'. Should be \$poe\'" 
      return -1
    }
    
    foreach dd [list ma maxPwr admSt pwr  vlt cur typ opSt] {
      set $dd 0
    }
    set re "\\s$port\[\\s\\|\]\+\(\\d\+\)\[\\s\\|\]\+\(\\w\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\d\\.\\w\\/\]\+\)\[\\s\\|\]\+\(\[\\w\\-\]\+\)\[\\s\\|\]\+\(\\w\*\)"
    set res [regexp $re $buffer ma maxPwr admSt pwr  vlt cur typ opSt]
    #regexp {\s5[\s\|]+(\d+)[\s\|]+(\w+)[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)[\s\|]+([\d\.]+)[\s\|]+([\w\-]+)[\s\|]+(\w+)} $buffer ma maxPwr admSt pwr  vlt cur typ opSt
    foreach dd [list ma maxPwr admSt pwr vlt cur typ opSt] {
      puts "$dd:<[set $dd]>"
    }
    if {$res==0} {
      set gaSet(fail) "Read POE values of port-$port fail" 
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set val 30
    } else {
      set val 15
    }
    if {$maxPwr!=$val} {
      set gaSet(fail) "The Max. Power of port-$port is $maxPwr. Should be $val"
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set min "3.3" ; set max "4.0"
    } else {
      set min "1.2" ; set max "2.7"
    }
    if {$pwr<=$min || $pwr>$max} {
#       11/05/2021 11:02:32 set gaSet(fail) "The Power of port-$port is $pwr. Should be between $min and $max"
#       return -1
    }
    
#     11/05/2021 11:02:12 set min "47.0" ; set max "51.0"
    set min "44.0" ; set max "57.0"
    if {$vlt<=$min || $vlt>=$max} {
      set gaSet(fail) "The Voltage of port-$port is $vlt. Should be between $min and $max"
      return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set min "0.070" ; set max "0.090"
    } else {
      set min "0.019" ; set max "0.065"
    }
    if {$cur<=$min || $cur>=$max} {
#       11/05/2021 11:02:29 set gaSet(fail) "The Current of port-$port is $cur. Should be between $min and $max"
#       return -1
    }
    
    if {$poe=="2PA" && ($port==2 || $port==3)} {
      set val "Alt-B"
    } else {
      set val "Alt-A"
    }
    if {$typ!=$val} {
      set gaSet(fail) "The Type of port-$port is $typ. Should be $val"
      return -1
    }
    set val "OK"
    if {$opSt!=$val} {
      set gaSet(fail) "The Type of port-$port is $opSt. Should be $val"
      return -1
    }
    
    AddToPairLog $gaSet(pair) "Port-$port. Max. Power: $maxPwr, Admin Status: $admSt, Power: $pwr, Voltage: $vlt, Current: $cur, Type: $typ, Oper Status: $opSt"  
  
    
    set ret [Send $com "poe ports update admin-status disable port-id $port\r" "$gaSet(appPrompt)"]
    after 2000
    if {$ret!=0} {set gaSet(fail) "Disable admin-status of port-$port fail" ;  return -1}
  }
  
  return $ret
}  

# ***************************************************************************
# GpsPerf
# ***************************************************************************
proc GpsPerf {} {
  global gaSet buffer
  puts "[MyTime] GpsPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "gnss update admin-status disable\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Enable gnss show fail" 
    return -1
  }
  after 5000
  set ret [Send $com "gnss update admin-status enable\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Enable gnss show fail" 
    return -1
  }
  set ret [Send $com "gnss show\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Gnss show fail" 
    return -1
  }
  
  set emptyLen [llength [lrange $buffer [lsearch $buffer Day] [lsearch $buffer Satellites]]]
  puts "GpsPerf emptyLen:$emptyLen"
  if {$emptyLen!=11} {
    set gaSet(fail) "Wrong empty gnss fields" 
    return -1
  }
  
  set maxWait 10
  set sec1 [clock seconds]
  set lat [set vis -1]
  
  for {set i 1} {$i<[expr {60 * $maxWait}]} {incr i 10} {
    set sec2 [clock seconds]
    set aft [expr {$sec2-$sec1}]
    set ret [Wait "Wait for GPS sync ($aft sec)" 10]
    if {$ret!=0} {return -1}
    #Status "Wait for GPS sync ($i)"
    set ret [Send $com "gnss show\r" "$gaSet(appPrompt)"]
    if {$ret!=0} {
      set gaSet(fail) "Gnss show fail" 
      return -1
    }  
    
    set emptyLen [llength [lrange $buffer [lsearch $buffer Day] [lsearch $buffer Satellites]]]
    puts "GpsPerf i:$i After $aft sec emptyLen:$emptyLen"
    if {$emptyLen>11} {
      
      set res [regexp {Latitude\s+([\d\:\.]+)\s} $buffer ma val]
      if {$res==0} {
        set gaSet(fail) "Read gnss fail"
        set ret -1
        break 
      }
      if {[string match {*:31:48*} $val]} {
        set lat $val
        set ret 0
      } else {  
        set gaSet(fail) "The Latitude has not \':31:48\' value" 
        set ret -1
        break
      }
      
      if {$ret==0} {
        set res [regexp {Visible:([\d\/]+)\s} $buffer ma val]
        if {$res==0} {
          set gaSet(fail) "Read gnss fail"
          set ret -1
          break 
        }
        if {$val!="0/0"} {
          set vis $val
          set ret 0
        } else {  
          set gaSet(fail) "Visible: 0/0. Should be more" 
          set ret -1
          break
        }
        
        if {$ret==0} {
          break
        }
      }
    } else {
      after 5000
      set ret -1
      set gaSet(fail) "GPS did not synchronized after $maxWait minutes"
    }
  }
  if {$ret==0} {
    AddToPairLog $gaSet(pair) "Latitude: $lat, Visible: $vis"  
  }

  return $ret
}  

# ***************************************************************************
# AlarmRunLedsPerf
# ***************************************************************************
proc AlarmRunLedsPerf {} {
  global gaSet buffer
  puts "[MyTime] AlarmRunLedsPerf"
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *SF1V=>* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2Uboot]
  }
  if {$ret!=0} {return $ret}
  
  RLSound::Play information
  set txt "Disconnect all the cables, except PWR and CONSOLE\n\
  Remove SFP-9G, DiskOnKey, SIM (if exist) and SD cards\n\
  Disconnect Antenna/s from MAIN (and MAIN-2 if exists) and GPS (if exists).\n\
  Connect Antenna to AUX (and to AUX-2 if exists)."
  set ret [DialogBox -title "ALM led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "ALM led test fail"
    return -1 
  }
  
  set ret [Send $com "gpio set B12\r" "SF1V=>"] 
  if {$ret!=0} {return $ret} 
  set ret [Send $com "usb start\r" "SF1V=>"] 
  if {$ret!=0} {return $ret} 
  set res [regexp {storage devices[\s\.]+(\d)\sStorage Device} $buffer ma val]
  if {$res==0} {
    Send $com "usb stop\r" "SF1V=>"
    set gaSet(fail) "Read USB fail"
    return -1 
  }
  if {$val!=0} {
    Send $com "usb stop\r" "SF1V=>"
    set gaSet(fail) "Found $val storage devices. Should be 0" 
    return -1
  }
  Send $com "usb stop\r" "SF1V=>"
  
  set ret [Send $com "alarm ON\r" "SF1V=>"]  
  if {$ret!=0} {set gaSet(fail) "Set alarm ON fail" ; return $ret}
  set ret [Send $com "gpio clear 26\r" "SF1V=>"]  
  if {$ret!=0} {set gaSet(fail) "Set run ON fail" ; return $ret}
  RLSound::Play information
  set ret [DialogBox -title "ALM led Test" -type "OK Cancel" -icon images/info\
      -text "Verify the red ALM is blinking and the green RUN is ON" -aspect 2000] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "ALM led test fail"
    return -1 
  }
  
  set ret [Send $com "alarm OFF\r" "SF1V=>"]  
  if {$ret!=0} {set gaSet(fail) "Set alarm OFF fail" ; return $ret} 
  set ret [Send $com "gpio set 26\r" "SF1V=>"]  
  if {$ret!=0} {set gaSet(fail) "Set run OFF fail" ; return $ret} 
  RLSound::Play information
  set ret [DialogBox -title "ALM led Test" -type "OK Cancel" -icon images/info\
  -text "Verify the ALM and RUN leds are off"] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "ALM led test fail"
    return -1 
  }
  
#   set ret [Send $com "gpio clear 26\r" "SF1V=>"]  
#   if {$ret!=0} {set gaSet(fail) "Set run ON fail" ; return $ret}
#   RLSound::Play information
#   set ret [DialogBox -title "RUN led Test" -type "OK Cancel" -icon images/info\
#   -text "Verify the green RUN is ON"] 
#   if {$ret=="Cancel"} {
#     set gaSet(fail) "RUN led test fail"
#     return -1 
#   }
  
#   set ret [Send $com "gpio set 26\r" "SF1V=>"]  
#   if {$ret!=0} {set gaSet(fail) "Set run OFF fail" ; return $ret} 
#   RLSound::Play information
#   set ret [DialogBox -title "RUN led Test" -type "OK Cancel" -icon images/info\
#   -text "Verify the RUN is off"] 
#   if {$ret=="Cancel"} {
#     set gaSet(fail) "RUN led test fail"
#     return -1 
#   }
  
  set ret 0
  
  return $ret
}  
# ***************************************************************************
# FrontLedsPerf
# ***************************************************************************
proc FrontLedsPerf {} {
  global gaSet buffer
  puts "[MyTime] FrontLedsPerf"
  
  set com $gaSet(comDut)
  Power all off
  after 2000
  Power all on
  
  set ret [ReadCom $com  "safe-mode menu" 60]
  puts "[MyTime] ret after readComWithStartup:<$ret>" ; update
  if {$ret!=0} {
    set gaSet(fail) "Reach safe-mode fail"
    return $ret
  }
  
  set ret [Send $com "s\r" "assword"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to basic safe-mode menu fail"
  } elseif {$ret==0} {
    Send $com "andromeda\r" "stam" 1
    Send $com "advanced\r" "stam" 1
    set ret [DescrPassword "tech" "with startup"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to advanced safe-mode menu fail"
    } elseif {$ret==0} {
      set ret [Send $com "11\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Lock U-BOOT fail"
         return -1 
      }
    
      set ret [Send $com "14\r" "Sequence"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set ret [Send $com "1\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set txt "Verify Port 2-5 LINK/ACT are green, SPD are green\n\
      S1 and S2 Tx-RX are green\n\
      Port 1 Link/Act is green\n\
      Sim 1 and 2 are green (if exist)\n\
      PWR is green"
      RLSound::Play information
      set ret [DialogBox -title "Front leds Test" -type "OK Cancel" -icon images/info -text $txt] 
      if {$ret=="Cancel"} {
        set gaSet(fail) "Front leds Test fail"
        return -1 
      }
      
      set ret [Send $com "14\r" "Sequence"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set ret [Send $com "2\r" "with startup"]
      if {$ret!=0} {
         set gaSet(fail) "Set LED test fail"
         return -1 
      }
      set txt "Verify Port 2-5 LINK/ACT, SPD are OFF\n\
      S1 and S2 Tx-RX are OFF\n\
      Port 1 Link/Act is OFF\n\
      Sim 1 and 2 are OFF (if exist)\n\
      PWR is green"
      RLSound::Play information
      set ret [DialogBox -title "Front leds Test" -type "OK Cancel" -icon images/info -text $txt] 
      if {$ret=="Cancel"} {
        set gaSet(fail) "Front leds Test fail"
        return -1 
      }
      set ret 0
    }  
  }    
  if {$ret==0} {
    set ret [Send $com "c\r" "Loading software"]
    set ret [Login2App]
    if {$ret!=0} {return $ret}
  
    
  }
  return $ret
}

# ***************************************************************************
# ReadImei
# ***************************************************************************
proc ReadImei {} {
  global gaSet buffer
  puts "[MyTime] ReadImei"
  set com $gaSet(comDut)
   
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [Login2App]
  }
  if {$ret!=0} {return $ret}
  
  set cellQty [string index $gaSet(dutFam.cell) 0]
  if {$cellQty==1} {
    if [info exists gaSet(1.imei1)] {} ; #return 0
    foreach sl {1 2} {
      Status "Read Cellular parameters of slot-$sl"
      set ret [Send $com "cellular modem power-down\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Set modem power-down fail"
        return $ret 
      }
      set ret [Send $com "cellular modem select sim-slot $sl\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Select sim-slot $sl fail"
        return $ret 
      }
      set ret [Send $com "cellular modem power-up\r" "$gaSet(appPrompt)" 30]
      if {$ret!=0} {
        set gaSet(fail) "Set modem power-up fail"
        return $ret 
      }
      set ret [Send $com "cellular modem get iccid\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Set modem get iccid fail"
        return $ret 
      }
      if {[string match {*failed to communicate with modem*} $buffer]} {
        set ret [Send $com "cellular modem power-down\r" "$gaSet(appPrompt)"]
        if {$ret!=0} {
          set gaSet(fail) "Set modem power-down fail"
          return $ret 
        }
        set ret [Send $com "cellular modem select sim-slot $sl\r" "$gaSet(appPrompt)"]
        if {$ret!=0} {
          set gaSet(fail) "Select sim-slot $sl fail"
          return $ret 
        }
        set ret [Send $com "cellular modem power-up\r" "$gaSet(appPrompt)" 30]
        if {$ret!=0} {
          set gaSet(fail) "Set modem power-up fail"
          return $ret 
        }
        set ret [Send $com "cellular modem get iccid\r" "$gaSet(appPrompt)"]
        if {$ret!=0} {
          set gaSet(fail) "Set modem get iccid fail"
          return $ret 
        }
        if {[string match {*failed to communicate with modem*} $buffer]} {
          set gaSet(fail) "Failed to communicate with modem"
          return -1
        }
      }
      regexp {ICCID:\s+(\w+)\s} $buffer ma icc
      puts "icc.1 : <$icc>"
      if {[string length $icc]>"4"} {
        set gaSet(fail) "The SIM slot-$sl is not empty" 
        return -1
      }
    
      set ret [Send $com "cellular modem get imei\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Read modem get imei fail"
        return $ret 
      }
      regexp {IMEI:\s+(\w+)\s} $buffer ma val
      set gaSet(1.imei$sl) $val      
    } 
  } elseif {$cellQty==2} {
    if {[info exists gaSet(1.imei1)] && [info exists gaSet(1.imei2)]} {} ; #return 0
    foreach mdm {1 2} {
      Status "Read Cellular parameters of modem-$mdm"
#         set ret [Send $com "cellular modem $mdm power-down\r" "$gaSet(appPrompt)"]
#         if {$ret!=0} {
#           set gaSet(fail) "Set modem $mdm power-down fail"
#           return $ret 
#         }
      set ret [Send $com "cellular modem $mdm power-up\r" "$gaSet(appPrompt)" 30]
      if {$ret!=0} {
        set gaSet(fail) "Set modem $mdm power-up fail"
        return $ret 
      }
      set ret [Send $com "cellular modem $mdm get iccid\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Set modem $mdm get iccid fail"
        return $ret 
      }
      regexp {ICCID:\s+(\w+)\s} $buffer ma icc
      puts "icc.$mdm : <$icc>"
      if {[string length $icc]>"4"} {
        set gaSet(fail) "The SIM slot-$mdm is not empty" 
        return -1
      }
    
      set ret [Send $com "cellular modem $mdm get imei\r" "$gaSet(appPrompt)"]
      if {$ret!=0} {
        set gaSet(fail) "Read modem $mdm get imei fail"
        return $ret 
      }
      regexp {IMEI:\s+(\w+)\s} $buffer ma val
      set gaSet(1.imei$mdm) $val      
    } 
  }
  return $ret
}
  
# ***************************************************************************
# FactorySettingsPerf
# ***************************************************************************
proc FactorySettingsPerf {} {
  global gaSet buffer
  set poe $gaSet(dutFam.poe)
  puts "[MyTime] FactorySettingsPerf"  
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set ret [Send $com "delete startup-cfg\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Delete startup-cfg fail"
    return $ret 
  }
  
#   set ret [PowerResetAndLogin2App]
#   if {$ret!=0} {return $ret}
  
  set ret [Send $com "factory-default\r" "yes/no"]
  if {$ret!=0} {
    set gaSet(fail) "Perform factory-default fail"
    return $ret 
  }
  set ret [Send $com "yes\r" "Restarting system"]
  if {$ret!=0} {
    set gaSet(fail) "Restarting system fail"
    return $ret 
  }
  
  set ret [Login2App]
  if {$ret!=0} {return $ret}
  
  if {[string match {*to stop autoboot:*} $gaSet(loginBuffer)]} {
    set gaSet(fail) "The Uboot is not locked"
    return -1
  }
  
  return $ret
}  
# ***************************************************************************
# WifiPerf
# ***************************************************************************
proc WifiPerf {baud locWifiReport} {
  global gaSet buffer
  puts "[MyTime] WifiPerf $baud $locWifiReport"  
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
#   if {[string match *$gaSet(appPrompt)* $buffer]} {
#     set ret 0
#   } else {
#     set ret [PowerResetAndLogin2App]
#   }
#   set ret [PowerResetAndLogin2App]
#   if {$ret!=0} {return $ret}

  set ret [Send $com "router interface create address-prefix ${gaSet(WifiNet)}.5[PcNum].[UutNum]/24 interface-id 8 physical-interface wlan-ap1 label no\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Create Router interface fail"
    return $ret 
  }
  set ret [Send $com "wlan update country-code IL\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {
    set gaSet(fail) "Update country-code fail"
    return $ret 
  }
  if {$baud=="2.4"} {
    set rad 802.11g
  } else {
    set rad 802.11ac
  }
  set ret [Send $com "wlan access-point create radio-mode $rad admin-status enable password RAD_TST1 ssid RAD_TST1_$gaSet(wifiNet) max-clients 8 channel 0\r" "Completed OK"]  
  if {$ret!=0} {
    set gaSet(fail) "Access-point create fail"
    return $ret 
  }
  set ret [Send $com "wlan access-point update admin-status enable\r" "Completed OK"]  
  if {$ret!=0} {
    set gaSet(fail) "Access-point update fail"
    return $ret 
  }
  set ret [Send $com "router dhcp-server create address-prefix ${gaSet(WifiNet)}.5[PcNum].0/24 address-range-start ${gaSet(WifiNet)}.5[PcNum].[UutNum]1 address-range-end 50.50.5[PcNum].[UutNum]2\r" "Completed OK"]  
  if {$ret!=0} {
    set gaSet(fail) "Access-point create fail"
    return $ret 
  }

  set ret [WiFiReport $locWifiReport $baud on]
  if {$ret!=0} {return $ret}
  
  for {set try 1} {$try <= 5} {incr try} {
    set ret [Ping2Cellular WiFi ${gaSet(WifiNet)}.5[PcNum].[UutNum]2]   
    puts "[MyTime] ping res: $ret at try $try" 
    if {$ret==0} {break}
    set ret [Ping2Cellular WiFi ${gaSet(WifiNet)}.5[PcNum].[UutNum]1]   
    puts "[MyTime] ping res: $ret at try $try" 
    if {$ret==0} {break}
    after 10000
  }
  if {$ret!=0} {
    #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    
    return $ret
  }
  
  if {$baud=="2.4"} {  
    ## we stop the measurement and wait upto 2 minutes to verify that wifireport will be deleted
    #FtpDeleteFile [string tolower startMeasurement_$gaSet(wifiNet)]
    #FtpDeleteFile  [string tolower wifireport_$gaSet(wifiNet).txt]
    catch {exec python.exe lib_sftp.py FtpDeleteFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
    puts "FtpDeleteFile <$res>"
    set ret [FtpVerifyNoReport]
    if {$ret!=0} {return $ret}

    #FtpUploadFile startMeasurement_$gaSet(wifiNet)
    catch {exec python.exe lib_sftp.py FtpUploadFile startMeasurement_$gaSet(wifiNet)} res
    puts "FtpDeleteFile <$res>"
    regexp {result: (-?1) } $res ma ret
    RLSound::Play information
    set txt "Disconnect Antenna from MAIN2"
    set ret [DialogBox -title "WiFi $baud Test" -type "OK Cancel" -icon images/info -text $txt] 
    if {$ret=="Cancel"} {
      set gaSet(fail) "WiFi $baud fail"
      return -1 
    }
    set ret [Wait "Wait for WiFi signal down" 40]
    if {$ret!=0} {return -1}
    
    ## we start the measurement and wait upto 2 minutes to verify that wifireport will be created
    set ret [FtpVerifyReportExists]
    if {$ret!=0} {return $ret}
    
    set ret [WiFiReport $locWifiReport $baud off]
    if {$ret!=0} {
      #FtpDeleteFile  [string tolower wifireport_$gaSet(wifiNet).txt]
      catch {exec python.exe lib_sftp.py FtpDeleteFile wifireport_$gaSet(wifiNet).txt} res
      puts "FtpDeleteFile <$res>"
      set ret [FtpVerifyNoReport]
      if {$ret!=0} {return $ret}
      set ret [Wait "Wait for WiFi signal down" 35]
      if {$ret!=0} {return -1}
      set ret [FtpVerifyReportExists]
      if {$ret!=0} {return $ret}
    
      set ret [WiFiReport $locWifiReport $baud off]
      if {$ret!=0} {return $ret}
    }
   
  }
  
  return $ret
}
# ***************************************************************************
# WiFiReport
# ***************************************************************************
proc WiFiReport {locWifiReport baud ant} {
  global gaSet
  puts "\n[MyTime]  WiFiReport $locWifiReport $baud $ant"
  catch {file delete -force $locWifiReport} res
  puts "WiFiReport catch res:<$res>"
  AddToPairLog $gaSet(pair) "Antenna: $ant"
  
  Status "Looking for RAD_TST1"
  set ret -1
  for {set i 1} {$i <= 50} {incr i} {
    if {$gaSet(act)==0} {return -2}
    puts "i:<$i>"
    $gaSet(runTime) configure -text "$i" ; update
    #if {[FtpGetFile wifiReport_$gaSet(wifiNet).txt $locWifiReport]=="1"} {}
    catch {exec python.exe lib_sftp.py FtpGetFile [string tolower wifiReport_$gaSet(wifiNet).txt] $locWifiReport} res
    regexp {result: (-?1) } $res ma res
    puts "FtpGetFile res <$res>"
    
    if {$res=="1" } {
      after 500
      if {[file exists $locWifiReport]} { 
        set ret  [WiFiReadReport $locWifiReport $baud $ant $i]
        puts "WiFiReport i:$i ret after WiFiReadReport <$ret> fail:<$gaSet(fail)>" 
        if {$ret=="TryAgain"} {
          ## wait a little and then try again
          after 2000
        } else {
          break
        }
      } else {
        set gaSet(fail) "$locWifiReport does not exist"
        puts "$locWifiReport does not exist"
        after 2000
      }
    } else {
      set gaSet(fail) "FtpGetFile wifiReport_$gaSet(wifiNet).txt fail"
      puts "FtpGetFile wifiReport_$gaSet(wifiNet).txt fail"
      after 2000
    }
  }
  if {$ret=="TryAgain"} {set ret -1}
  puts "WiFiReport ret before return <$ret> gaSet(fail):<$gaSet(fail)>" 
  return $ret
}
# ***************************************************************************
# WiFiReadReport
#  set locWifiReport LocWifiReport.txt
# ***************************************************************************
proc WiFiReadReport {locWifiReport baud ant tr} {
  global gaSet
  puts "\n[MyTime]  WiFiReadReport $locWifiReport $baud $ant $tr"
  set ret 0
  set id [open $locWifiReport r]
    set wlanIntfR [read $id]
  close $id
  puts "WiFiReadReport wlanIntfR:<$wlanIntfR>"
  
  set ::wlanIntfR $wlanIntfR
  #set res [regexp "SSID\\s+\(\\d+\)\\s+:\\s+RAD_TST1_$gaSet(wifiNet)" $wlanIntfR ma val]
  set res [regexp "SSID\\s+:\\s+RAD_TST1_$gaSet(wifiNet)" $wlanIntfR ma]

  if {$res==0} {
    if {$ant=="off"} {
      AddToPairLog $gaSet(pair) "No RAD_TST1_$gaSet(wifiNet)"
      return 0
    }
    set gaSet(fail) "Read SSID RAD_TST1_$gaSet(wifiNet) fail"
    return "TryAgain"
  }
  puts "WiFiReadReport ma:<$ma>"
  set res [regexp "SSID\\s+:\\s+RAD_TST1_$gaSet(wifiNet).+?%" $wlanIntfR wlanIntf]
  if {$res==0} {
    set gaSet(fail) "Read SSID fail"
    return "TryAgain"
  }
  
  puts "WiFiReadReport wlanIntf:<$wlanIntf>"
  set ::wlanIntf $wlanIntf
  
  set res [regexp {SSID[\s\d\:]+([\w\_\-]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read SSID or data of RAD_TST1_$gaSet(wifiNet) fail"
    return "TryAgain" 
  }
  if {$val!="RAD_TST1_$gaSet(wifiNet)"} {
    set gaSet(fail) "SSID is $val. Should be RAD_TST1_$gaSet(wifiNet)"
    return "-1"
  }
  
  set res [regexp {Radio type[\s\:]+([\w\.]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Radio type fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Baud: $baud, Radio type: $val"  
  if {$baud=="2.4" && $val!="802.11g"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11g"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$baud=="5" && $val!="802.11a" && $val!="802.11ac"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11a or 802.11ac"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  }
  
  set res [regexp {Signal[\s\:]+(\d+)%} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Signal fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Signal: $val"  
  puts "WiFiReadReport Antena:<$ant> val:<$val>"
  set minSignal 55
  if {$ant=="on" && $val<="$minSignal"} {
    set gaSet(fail) "Signal is ${val}%. Should be more then ${minSignal}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$ant=="off" && $val>"$minSignal"} {
    set gaSet(fail) "Signal is ${val}%. Should be less then ${minSignal}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } else {
    set gaSet(fail) ""
    return 0
  }
  if {$ret eq "0"} {
    set gaSet(fail) ""
  }
  return $ret
}

proc __WiFiReadReport {locWifiReport baud ant tr} {
  global gaSet
  puts "\n[MyTime]  WiFiReadReport $locWifiReport $baud $ant $tr"
  set ret 0
  set id [open $locWifiReport r]
    set wlanIntfR [read $id]
  close $id
  puts "WiFiReadReport wlanIntfR:<$wlanIntfR>"
  
  set ::wlanIntfR $wlanIntfR
  set res [regexp "SSID\\s+\(\\d+\)\\s+:\\s+RAD_TST1_$gaSet(wifiNet)" $wlanIntfR ma val]
  if {$res==0} {
    if {$ant=="off"} {
      AddToPairLog $gaSet(pair) "No RAD_TST1_$gaSet(wifiNet)"
      return 0
    }
    set gaSet(fail) "Read SSID fail"
    return "TryAgain"
  }
  puts "WiFiReadReport SSID:$ma"
  set res [regexp "SSID ${val}.+?54" $wlanIntfR wlanIntf]
  if {$res==0} {
    set gaSet(fail) "Read SSID fail"
    return "TryAgain"
  }
  
  puts "WiFiReadReport wlanIntf:<$wlanIntf>"
  set ::wlanIntf $wlanIntf
  
  set res [regexp {SSID[\s\d\:]+([\w\_\-]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read SSID or data of RAD_TST1_$gaSet(wifiNet) fail"
    return "TryAgain" 
  }
  if {$val!="RAD_TST1_$gaSet(wifiNet)"} {
    set gaSet(fail) "SSID is $val. Should be RAD_TST1_$gaSet(wifiNet)"
    return "-1"
  }
  
  set res [regexp {Radio type[\s\:]+([\w\.]+)\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Radio type fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Baud: $baud, Radio type: $val"  
  if {$baud=="2.4" && $val!="802.11g"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11g"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$baud=="5" && $val!="802.11a" && $val!="802.11ac"} {
    set gaSet(fail) "Radio type is $val. Should be 802.11a or 802.11ac"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  }
  
  set res [regexp {Signal[\s\:]+(\d+)\%\s} $wlanIntf ma val]
  if {$res==0} {
    set gaSet(fail) "Read Signal fail"
    return "TryAgain" 
  }
  AddToPairLog $gaSet(pair) "Signal: $val"  
  puts "WiFiReadReport Antena:<$ant> val:<$val>"
  set minSignal 30
  if {$ant=="on" && $val<="$minSignal"} {
    set gaSet(fail) "Signal is ${val}%. Should be more then ${minSignal}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } elseif {$ant=="off" && $val>"$minSignal"} {
    set gaSet(fail) "Signal is ${val}%. Should be less then ${minSignal}%"
    if {$tr<6} {
      return "-1"
    } else {
      return "TryAgain"
    }
  } else {
    set gaSet(fail) ""
    return 0
  }
  if {$ret eq "0"} {
    set gaSet(fail) ""
  }
  return $ret
}

# ***************************************************************************
# PlcPerf
# ***************************************************************************
proc PlcPerf {} {
  global gaSet buffer
  puts "[MyTime] PlcPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Modpoll ChangeMode fail"
    return -1 
  }  
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    puts "PLC open relay of DigitalOutput ch:<$ch>"
    set ret [Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"]
  }  
  RLSound::Play information
  set txt "Verify 6 DIGITAL IN and 6 DIGITAL OUT are OFF"
  set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "Digital On/OUT led test fail"
    return -1 
  }
  
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    ## read DI
    puts "PLC read DigitalInput ch:<$ch>"
    set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r $ch -c 1 /dev/ttyS1\r" "#"]
    set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val]
    puts "ma:<$ma> val:<$val>"
    if {$val ne 0} {
       set gaSet(fail) "The Digital Input of ch-$ch is $val. Should be 0" 
       set ret -1
       break
    }
  } 
  
  if {$ret==0} {
    RLUsbPio::Get $gaSet(idDOno) buffer
    puts "DigitalOutput buffer after open relay:<$buffer>"
  }
  
  if {$ret==0} {
    set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
    if {$ret!=0} {
      set gaSet(fail) "Modpoll ChangeMode fail"
      return -1 
    }
    for {set ch 1} {$ch <= 6} {incr ch} {
      puts "PLC close relay of DigitalOutput ch:<$ch>"
      set ret [Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"]
    }
   
    RLSound::Play information
    set txt "Verify 6 Green DIGITAL IN and 6 Red DIGITAL OUT are ON"
    set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
    if {$ret=="Cancel"} {
      set gaSet(fail) "Digital On/OUT led test fail"
      set ret -1
    } else {
      set ret 0
    }
  }
  
  if {$ret==0} {
    RLUsbPio::Get $gaSet(idDOno) buffer
    puts "DigitalOutput buffer after close relay:<$buffer>"
  }

  after 250 
  if {$ret==0} {
    for {set ch 1} {$ch <= 6} {incr ch} {
      set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r $ch -c 1 /dev/ttyS1\r" "#"]
      set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val]
      puts "ma:<$ma> val:<$val>"
      if {$val ne 1} {
        set gaSet(fail) "The Digital Input of ch-$ch is $val. Should be 1" 
        set ret -1
        break
      }
    }
  } 
  
   
  
  #     after 250
#     ## stop the polling
#     set ret [Send $com \3]
    
  if {$ret==0} {  
    for {set ch 1} {$ch <= 6} {incr ch} {
      puts "PLC open relay of DigitalOutput ch:<$ch>"
      Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"
    } 
   
    set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 3 -r 1 -c 6 /dev/ttyS1\r" "#"]
    for {set ch 1} {$ch <= 6} {incr ch} {  
      set res [regexp "\\\[$ch\\\]\\:\\s+\(\-?\\d+\)\\s" $buffer ma val]
      puts "PLC Read Analog Input $ch val:<$val>"
      AddToPairLog $gaSet(pair) "Analog Input $ch: $val"  
      if {$val>"32000" || $val<"28000"} {
        set gaSet(fail) "Analog Input $ch is $val. Should be between 28000 and 32000" 
        set ret -1
        break  
      } else {
        set ret 0
      }
    }
  }

  return $ret
}
# ***************************************************************************
# LoRaPerf
# ***************************************************************************
proc LoraPerf {} {
  global gaSet buffer
  puts "[MyTime] LoRaPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } elseif {[string match *root@lorawan:~* $buffer]} {
    Send $com "exit\r\r" stam 1
    Send $com "exit\r\r" stam 1
    set ret [Login2App]
  } elseif {[string match *\#* $buffer] && [string length $buffer]<5} {
    Send $com "exit\r\r" stam 1
    set ret [Login2App]
  } elseif {[string match {*SF1v login*} $buffer]} {
    set ret [Login2App]
  } else {
    set ret [PowerResetAndLogin2App]
  }
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration LoRa router fail" 
  set ret [Send $com "router interface create address-prefix 10.10.10.10[set gaSet(pair)]/24 physical-interface eth2  purpose application-host\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return $ret}
  if {![string match {*Completed OK*} $buffer ]} {
    if {[string match {*overlaps with an existing interface*} $buffer ]} {
      ## it's ok, the router is existing, lets' continue
      set ret 0
    } else {
      return -1
    }  
  }
  
  set gaSet(fail) "Configuration LoRa router nat fail" 
  set ret [Send $com "router nat static create protocol tcp  original-port 4443  modified-ip 10.0.3.70  modified-port 8443\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return $ret}
  if {![string match {*Completed OK*} $buffer ]} {
    if {[string match {*Similar rule already exist*} $buffer ]} {
      ## it's ok, the router is existing, lets' continue
      set ret 0
    } else {
      return -1
    }
  }
   
  set dat [clock format [clock seconds] -format "%Y.%m.%d-%H:%M:%S"]
  set gaSet(fail) "Configuration Date fail" 
  set ret [Send $com "date $dat\r" "$gaSet(appPrompt)"]
  if {$ret!=0} {return $ret}
  
  set gaSet(fail) "Configuration lxd admin-status fail" 
  set ret [Send $com "lxd update admin-status enable\r" "$gaSet(appPrompt)" 16]
  if {$ret!=0} {return $ret}
  
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2  
  if [string match {*SF1v login*} $buffer]==0 {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2
  }
  if {$gaSet(dutFam.lora)=="LR1"} {
    set ret [LoraChangeRegion $gaSet(dutFam.lora.region)]
  } else {
    set ret [LoraChangeRegion eu868]
  }
  if {$ret!=0} {return $ret}
    
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2  
  if [string match {*SF1v login*} $buffer]==0 {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2
  }
  set ret [LoraStartStop LoraAndGps]
  if {$ret!=0} {return $ret}
  
  if {$gaSet(dutFam.lora)=="LR2" || $gaSet(dutFam.lora)=="LR3" || \
      $gaSet(dutFam.lora)=="LR4" || $gaSet(dutFam.lora)=="LR6" || \
      $gaSet(dutFam.lora)=="LRAC"} {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2  
    if [string match {*SF1v login*} $buffer]==0 {
      Send $com "exit\r\r" "stam" 3 
      Send $com "\33" "stam" 1  
      Send $com "\r\r" "stam" 2
    }
    set ret [LoraChangeRegion $gaSet(dutFam.lora.region)] ; # au915
    if {$ret!=0} {return $ret}
  }
  
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2   
  if [string match {*SF1v login*} $buffer]==0 {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2
  }
  if {$ret!=0} {return $ret}
  set ret [LoraStartStop Band]
  if {$ret!=0} {return $ret}
  
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2   
  if [string match {*SF1v login*} $buffer]==0 {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2
  }
  if {$ret!=0} {return $ret}
  set ret [LoraGatewayId]
  if {$ret!=0} {return $ret}

  Send $com "exit\r\r" "stam" 3 
  Send $com "exit\r\r" "stam" 3 
  Send $com "\33" "stam" 1  
  Send $com "\r\r" "stam" 2  
  if [string match {*SF1v login*} $buffer]==0 {
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2
  }
  set ret [LoraStartStop GW_ID]
  if {$ret!=0} {return $ret}
  
  return $ret
}

# ***************************************************************************
# LoraStartStop
# ***************************************************************************
proc LoraStartStop {mode} {
  global cookies state gaSet tok body  gaSet buffer
  puts "[MyTime] LoraStartStop $mode"
  
  package require base64
 
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [Login2App]
  }
  if {$ret!=0} {return $ret}
  
  catch {exec ipconfig.exe /flushdns} fld
  puts "[MyTime] fld:<$fld>"
  
  for {set try 1} {$try <= 5} {incr try} {
    set ret [Ping2Cellular PC 10.10.10.10]   
    puts "[MyTime] ping res: $ret at try $try" 
    if {$ret==0} {break}
    after 10000
  }
  if {$ret!=0} {return $ret}
  
  
  Status "Login to LoRaWAN Gateway"
  set gaSet(fail) "Connection  to LoRaWAN Gateway fail"
  #::http::register https 4443 ::tls::socket 
  
  set timeout 10000
  
  set gaSet(curl) C:/curl-7.73.0-win64-mingw/bin/curl.exe
  for {set i 1} {$i<=5} {incr i} {
    puts "[MyTime] Try to login $i"
    puts "\nlogin without User:Password"
    catch {exec $gaSet(curl) -k  -c cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/login"} resBody
    set csrf - ;  regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf
    if {$csrf=="-"} {
      regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    }  
    #puts $resBody
    puts csrf1<$csrf>
    
    puts "\nlogin with User:Password"

    catch {exec $gaSet(curl)  -i -L -k -c cook$gaSet(pair) -b cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/login" \
        --data-raw "csrf_token=[set csrf]&username=admin&password=admin"} resBody
    set csrf - ; regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf ; #regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    if {$csrf=="-"} {
      regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    }
    #puts $resBody
    puts csrf2<$csrf>

    set body [StripHtmlTags $resBody] 
    set res [regexp {Dashboard[\_\s]+Version:\s+_([\d\.]+)_+Band:\s+_([A-Za-z\s\d\-]+)_+Status:\s+_([a-zA-Z]+)_} $body ma ver band status]
    puts "resAftefLgin with User:Password i:$i <$res>" 
    
    if {[string match {*502 Bad Gateway*} $body]} {
      set ret [Wait "Wait for Browser" 10]
    } else {
      if {$res=="1"} {
        break
      }
      set ret [Wait "Wait for Browser" 10]
    }  
  }
  
  Status "Read Dashboard"

  set res [regexp {Dashboard[\_\s]+Version:\s+_([\d\.]+)_+Band:\s+_([A-Za-z\s\d\-]+)_+Status:\s+_([a-zA-Z]+)_} $body ma ver band status]
  if {$res==0} {
    set gaSet(fail) "Read Dashboard fail"
    return -1
  }
  puts "res:<$res> ver:<$ver> band:<$band> status:<$status>" 
  set dashVer $gaSet(loraDashBver) ; # 02/11/2020 11:42:07 "1.0.4"
  if {$ver!=$dashVer} {
    set gaSet(fail) "The Version is $ver. Should be $dashVer" 
    return -1
  }
 
  if {$status=="Running"} {
    Status "Stop Gateway"
    catch {exec $gaSet(curl)  -i -L -k -b cook$gaSet(pair) -c cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/stop_gateway?csrf_token=[set csrf]" \
      --data-raw "csrf_token=[set csrf]"} resBody
    set csrf - ; regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf ; #regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    if {$csrf=="-"} {
      regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    }
    #puts $resBody
    puts csrfStop<$csrf>
    set body [StripHtmlTags $resBody] 
    set res [regexp {Dashboard[\_\s]+Version:\s+_([\d\.]+)_+Band:\s+_([A-Za-z\s\d\-]+)_+Status:\s+_([a-zA-Z]+)_} $body ma ver band status]
    puts "res:<$res> ver:<$ver> band:<$band> status:<$status>" 

    
    after 2000
  }
  
  Status "Start Gateway"
  catch {exec $gaSet(curl)  -i -L -k -c cook$gaSet(pair) -b cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/start_gateway?csrf_token=[set csrf]" \
    --data-raw "csrf_token=[set csrf]"} resBody
  set csrf - ; regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf ; #regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
  #puts $res
  if {$csrf=="-"} {
    regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
  }
  puts csrfStart<$csrf>
  set body [StripHtmlTags $resBody] 
  set res [regexp {Dashboard[\_\s]+Version:\s+_([\d\.]+)_+Band:\s+_([A-Za-z\s\d\-]+)_+Status:\s+_([a-zA-Z]+)_} $body ma ver band status]
  puts "res:<$res> ver:<$ver> band:<$band> status:<$status>" 


 
  Status "Read Logs"
  set ret 0
  set max 40
  set ::logs ""
  for {set i 1} {$i<=$max} {incr i} {
    set ret1 [set ret2 [set ret3 [set ret4 [set ret5 -1]]]]
    set ret [Wait "Wait for reading logs ($i : $max)" 15 ]
    if {$ret!=0} {return $ret}

    catch {exec $gaSet(curl)  -i -L -k -c cook$gaSet(pair) -b cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/runtime_logs"} resBody  
    
    set body [StripHtmlTags $resBody] 
    puts "[MyTime] runtime_logs.$i.<$body>"; update
    
    set ::logs $body
    
    puts "mode:$mode"
    if {$mode=="GW_ID"} {
      set res [regexp {gateway MAC address is configured to ([0-9A-F]+)\s?} $body ma val]
      if {$res} {
        set gaSet(initGID) [string toupper $gaSet(initGID)]
        puts "body gateway MAC:<$val> gaSet(initGID):<$gaSet(initGID)>"
        AddToPairLog $gaSet(pair) "Gateway MAC from web: $val"
        if {$val != $gaSet(initGID)} {
          set gaSet(fail) "gateway MAC address is $val. Should be $gaSet(initGID)"
          return -1
        } else {
          set ret5 0
        }
      }
      break
    }
    if {$mode=="LoraAndGps"} {
      set ret -1
      set gaSet(fail) "Not all fields of LoRa web were found" 
      switch -exact -- $gaSet(dutFam.lora) {
        LR1 {set mote "F4330811"}
        LR2 - LR3 - LR4 - LR6 - LRAC {set mote "2601170E"}
      }
      set ret1 [LoraReadLog $mote]
     
      set ret2 0
       
      set ret3 0 ; #02/11/2020 11:44:59
      
      puts "[MyTime] $ret1 $ret2 $ret3"
      if {$ret1==0 && $ret2==0 && $ret3==0} {
        set ret 0
        break
      }
    
      if {$ret1!=0} {
        set gaSet(fail) "\'Received packet with valid CRC from mote $mote ...\' was not received" 
      }
      if {$ret2!=0} {
        set gaSet(fail) "\'JSON up: \"rxpk\":\"tmst\": ...\' was not received" 
      }
      if {$ret3!=0} {
        set gaSet(fail) "GPS coordinates were not received" 
      }
    }
    
    if {$mode=="Band"} {
      puts "DashBand:<$band>, gaSet(dutFam.lora.band):<$gaSet(dutFam.lora.band)>"
      if {$band!=$gaSet(dutFam.lora.band)} {
        set gaSet(fail) "The Band is \'$band\'. Should be \'$gaSet(dutFam.lora.band)\'"
        set ret -1
        break 
      }
      if {[llength [split $band -]] == 2 || [llength [split $band -]] == 3} {
        regexp {[A-Z]{2}\s(\d+)-(\d+)} $band ma low upp
      } elseif {[llength [split $band -]] == 1} {
        regexp {[A-Z]{2}\s(\d+)} $band ma low
        set low [expr {$low - 1}]
        set upp [expr {$low + 3}]
      } 
      puts "band:$band low:$low upp:$upp"
      set lowFreq [expr {1000000 * $low}]
      set uppFreq [expr {1000000 * $upp}]
      set centerFreq [regexp -all -inline {center frequency\s+(\d+),} $body]
      if [llength $centerFreq] {
        foreach {ff fr1 dd fr2} $centerFreq {}
        if {$fr1<$lowFreq || $fr1>$uppFreq} {
          set gaSet(fail) "Radio 0 center is $fr1. Should be between $lowFreq and $uppFreq"
          set ret -1
          break
        }
        if {$fr2<$lowFreq || $fr2>$uppFreq} {
          set gaSet(fail) "Radio 0 center is $fr2. Should be between $lowFreq and $uppFreq"
          set ret -1
        }
        set ret 0
        set ret4 0
        break
      }
    }
    
  }
  
  if {$ret1==0 && $ret2==0 && $ret3==0} {
    AddToPairLog $gaSet(pair) "Received packet with valid CRC from mote $mote"
  }
  if {$ret4==0} {
    AddToPairLog $gaSet(pair) "The Band: \'$band\'. Center Frequency: $fr1, $fr2"
  }
  ## INFO: Received pkt from mote: 2601170E (fcnt=39)
  ## JSON up: {"rxpk":[{"tmst":201396179,"chan":1,"rfch":1,"freq":868.300000,"stat":1,"modu":"LORA","datr":"SF7BW125","codr":"4/5","lsnr":3.0,"rssi":-121,"size":15,"data":"QA4XASaAKQABApFzSE8v"}]}
  ## GPS coordinates: latitude 31.80413, longitude 35.21204, altitude 773 m
  
  Status "Stop Gateway"
  catch {exec $gaSet(curl)  -i -L -k -b cook$gaSet(pair) -c cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/stop_gateway?csrf_token=[set csrf]" \
    --data-raw "csrf_token=[set csrf]"} resBody
  set csrf - ; regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf ; #regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
  if {$csrf=="-"} {
      regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
    }
  #puts $res
  puts csrfStop<$csrf>
  set body [StripHtmlTags $resBody] 
  set res [regexp {Dashboard[\_\s]+Version:\s+_([\d\.]+)_+Band:\s+_([A-Za-z\s\d\-]+)_+Status:\s+_([a-zA-Z]+)_} $body ma ver band status]
  puts "res:<$res> ver:<$ver> band:<$band> status:<$status>" 


  Status "Logout"
  catch {exec $gaSet(curl) -k  -c cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/logout"} resBody
  set csrf - ; regexp {csrf_token" value="([a-zA-Z0-9\.\-\_]+)"} $resBody ma csrf ; #regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
  if {$csrf=="-"} {
    regexp {X-Csrftoken: ([a-zA-Z0-9\.\-\_]+)\s} $resBody ma csrf
  }
  #puts $resBody
  puts csrfLogout<$csrf>
  
  return $ret
}

# ***************************************************************************
# LoraChangeRegion
# ***************************************************************************
proc LoraChangeRegion {reg} {
  global cookies state gaSet tok body  gaSet buffer
  puts "[MyTime] LoraChangeRegion $reg"
  
  Status "Change Region to $reg"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set gaSet(fail) "Cd to LoRaWAN_webui fail"
  for {set k 1} {$k<=5} {incr k} {
    Status "Cd to LoRaWAN_webui ($k)"
    if {$gaSet(act)==0} {return -2}
    set ret [Send $com "cd\r\r" "#"]
    set ret [Send $com "pwd\r" "#"]
                                                                    
    set LoRaWAN "/mnt/extra/lxd/storage-pools/default/containers/lorawan/rootfs/root/LoRaWAN/LoRaWAN_webui"
    set ret [Send $com "cd $LoRaWAN\r" "#"]
    if {[string match {*can't cd*} $buffer]} {
      set ret -1
    }
    Send $com "pwd\r" "#"
    if {![string match {*LoRaWAN_webui*} $buffer]} {
      set ret -1
    }
    if {$ret!=0} {
      Wait "Wait for LoraWan container" 10
    } else {
      break
    }
  } 
  if {$ret!=0} {return $ret} 
  
  set ret [Send $com "ls\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "LS of $LoRaWAN fail"
    return $ret
  }
  
  set ret [Send $com "echo $reg > region\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "echo $reg > region fail"
    return $ret
  }
  
  set ret [Send $com "cat region\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "cat region fail"
    return $ret
  }
  set res [regexp {region (.+) \#} $buffer ma reg]
  if {$res==0} {
    set gaSet(fail) "Read region fail"
    return -1
  } else {
    set ret 0
  }
  AddToPairLog $gaSet(pair) "Region: $reg"
  
  return $ret
} 

# ***************************************************************************
# LoraGatewayId
# ***************************************************************************
proc LoraGatewayId {} {
  global cookies state gaSet tok body  gaSet buffer
  puts "[MyTime] LoraGatewayId"
  Status "Generate Gateway Id"
   
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
      return -1
    }
  }
   
  set ret [Send $com "lxc exec lorawan bash\r" "root@lorawan"]
  if {$ret=="-1"} {
    set gaSet(fail) "Enter to root@lorawan fail"
    return -1
  }
  Send $com "ls LoRaWAN/LoRaWAN_webui/gwid\r" "#"
  if {[string match {*No such file or directory*} $buffer]} {
    catch {exec $gaSet(curl)  -i -L -k -b cook$gaSet(pair) -c cook$gaSet(pair) "https://10.10.10.10[set gaSet(pair)]:4443/generate_id"} resBody
  }
  Send $com "ls LoRaWAN/LoRaWAN_webui/gwid\r" "#"
  if {[string match {*No such file or directory*} $buffer]} {
    set gaSet(fail) "No GatewayID"
    return -1
  }
  
  set gaSet(initGID) ""
  set ret [Send $com "cat LoRaWAN/LoRaWAN_webui/gwid\r" "#"]
  set res [regexp {gwid (.+) root} $buffer ma id]
  if {$res==0} {
    set gaSet(fail) "Read GatewayID fail"
    return -1
  } else {
    set ret 0
  }
  set gaSet(initGID) "$id"
  AddToPairLog $gaSet(pair) "GW_ID after \'generate_id\': $id"
  
  return $ret
 
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *$gaSet(appPrompt)* $buffer]} {
    set ret 0
  } else {
    set ret [Login2App]
  }
  if {$ret!=0} {return $ret}
  
  
  for {set try 1} {$try <= 5} {incr try} {
    set ret [Ping2Cellular PC 10.10.10.10]   
    puts "[MyTime] ping res: $ret at try $try" 
    if {$ret==0} {break}
    after 10000
  }
  if {$ret!=0} {return $ret}
  
  
  ::http::register https 4443 ::tls::socket

  set timeout 10000
  set login [::http::formatQuery username admin password admin]
  catch {::http::geturl https://10.10.10.10[set gaSet(pair)]:4443/login -query $login -timeout $timeout } tok
  upvar #0 $tok state
  #parray state
  #ReadCookies
  set cookies [list]
  foreach {name value} $state(meta) {
    if { $name eq "Set-Cookie" } {
      lappend cookies [lindex [split $value {;}] 0]
    }
  }
  set body [StripHtmlTags $state(body)]
  http::cleanup $tok
  puts "login.<$body>"; update 
  #puts "cookies:<$cookies>"
  
  if {[string match {*502 Bad Gateway*} $body]} {
    after 2000
    catch {::http::geturl https://10.10.10.10[set gaSet(pair)]:4443/login -query $login -timeout $timeout } tok
    upvar #0 $tok state
    #parray state
    #ReadCookies
    set cookies [list]
    foreach {name value} $state(meta) {
      if { $name eq "Set-Cookie" } {
        lappend cookies [lindex [split $value {;}] 0]
      }
    }
    set body [StripHtmlTags $state(body)]
    http::cleanup $tok
    puts "login2.<$body>"; update 
    if {[string match {*502 Bad Gateway*} $body]} {
      set gaSet(fail) "Login to Dashboard fail"
      return -1
    }
  }
  
  catch {::http::geturl https://10.10.10.10[set gaSet(pair)]:4443/edit-configuration -headers [list Cookie [join $cookies {;}]]} tok
  upvar #0 $tok state
#   ReadCookies
  #parray state
  set cookies [list]
  foreach {name value} $state(meta) {
    if { $name eq "Set-Cookie" } {
      lappend cookies [lindex [split $value {;}] 0]
    }
  }
  set body [StripHtmlTags $state(body)] 
  http::cleanup $tok
  #puts "cookies:<$cookies>"
  if [regexp {___Server port - uplink____(.+?)__Backup/Restore Configuration_} $body ma val] {
    set body [regsub -all {_} [regsub -all {\s} $ma ""] " "]
  }
  puts "edit-configuration.<$body>"; update
  
  if {[string match {*GenerateGatewayID*} $body]} {
    catch {::http::geturl https://10.10.10.10[set gaSet(pair)]:4443/generate_id -headers [list Cookie [join $cookies {;}]]} tok
    upvar #0 $tok state
  #   ReadCookies
    #parray state
    set cookies [list]
    foreach {name value} $state(meta) {
      if { $name eq "Set-Cookie" } {
        lappend cookies [lindex [split $value {;}] 0]
      }
    }
    set body [StripHtmlTags $state(body)] 
    http::cleanup $tok
    #puts "cookies:<$cookies>"
    if [regexp {___Server port - uplink____(.+?)__Backup/Restore Configuration_} $body ma val] {
      set body [regsub -all {_} [regsub -all {\s} $ma ""] " "]
    }
    puts "generate_id.<$body>"; update
    
    catch {::http::geturl https://10.10.10.10[set gaSet(pair)]:4443/edit-configuration -headers [list Cookie [join $cookies {;}]]} tok
    upvar #0 $tok state
  #   ReadCookies
    #parray state
    set cookies [list]
    foreach {name value} $state(meta) {
      if { $name eq "Set-Cookie" } {
        lappend cookies [lindex [split $value {;}] 0]
      }
    }
    set body [StripHtmlTags $state(body)] 
    http::cleanup $tok
    #puts "cookies:<$cookies>"
    if [regexp {___Server port - uplink____(.+?)__Backup/Restore Configuration_} $body ma val] {
      set body [regsub -all {_} [regsub -all {\s} $ma ""] " "]
    }
    puts "edit-configuration.<$body>"; update
    set ret 0
  } else {
    set ret 0
  }
  
  return $ret
}

# ***************************************************************************
# LoraReadLog
# ***************************************************************************
proc LoraReadLog {mote} {
  global cookies state gaSet tok body  gaSet buffer
  puts "[MyTime] LoraReadLog $mote"
  
  Status "Read Log"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } elseif {[string match *root@lorawan:~* $buffer]} {
    ## we are inside the Linux box already
  } else {  
    set ret [Send $com "exit\r\r" "login"]
    if {$ret!=0} {
      set ret [Send $com "exit\r\r" "login"]
      if {$ret!=0} {
        set gaSet(fail) "Logout fail"
        return -1
      }
    }
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
      return -1
    }
  }
  
  if {[string match *root@lorawan:~* $buffer]} {
    ## we are in Loara already
  } else {
    set ret [Send $com "lxc exec lorawan bash\r" "#"]
    set ret [Send $com "\r" "#"]
    if {[string match *root@lorawan:~* $buffer]==0} {
      set gaSet(fail) "Enter to root@lorawan fail"
      return -1
    }
  }
  
  set ret [Send $com "ps aux |  grep lora_pkt\r" "#"]
  if {![string match {*lora_pkt _fwd*} $buffer]} {
    set gaSet(fail) "The \'lora_pkt_fwd\' doesn't exist"
    set ret -1    
  }
  
  if {$ret==0} {
    Send $com "grep  \"with valid CRC from mote:\" /var/run/gateway.log\r" "#"
    if {![string match "*with valid CRC from mote: [set mote]*" $buffer]} {
      set ret -1
    } else {
      set ret 0
    }
  }
  return $ret
} 

# ***************************************************************************
# PlcAnalogInputPerf
# ***************************************************************************
proc PlcAnalogInputPerf {} {
  global gaSet buffer
  set plc $gaSet(dutFam.plc)
  puts "[MyTime] PlcAnalogInputPerf PLC:<$plc>"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Modpoll ChangeMode fail"
    return -1 
  }  
  
  if {$ret==0} {  
#     for {set ch 1} {$ch <= 6} {incr ch} {
#       puts "PLC open relay of DigitalOutput ch:<$ch>"
#       Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"
#     } 
#     
#     for {set ch 1} {$ch <= 6} {incr ch} {
#       puts "PLC close relay of DigitalOutput ch:<$ch>"
#       Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"
#     }
   
    foreach  AI  {xx000001 xx000010} {}
    foreach AI IN { 
      #xx101010 xx010101 
      #RLUsbPio::Set $gaSet(idAI) $AI
      #RLUsbPio::SetConfig $gaSet(idAI) 00000000
      #puts "\n\nAnalog Input: $AI"
      #after 2000
      set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 3 -r 1 -c 6 /dev/ttyS1\r" "#"]
      for {set ch 1} {$ch <= 6} {incr ch} {  
        set res [regexp "\\\[$ch\\\]\\:\\s+\(\-?\\d+\)\\s" $buffer ma val]
        if {$res eq 0} {
          set gaSet(fail) "Read Analog Input fail"
          return -1
        }
        puts "PLC Read Analog Input $ch val:<$val>"
        AddToPairLog $gaSet(pair) "Analog Input $ch: $val"  
        if [string match *6CL* $gaSet(DutFullName)] {
          set min 800
          set max 1600
        } else {
          # 10:48 24/07/2023 if {$plc=="PLC24" || $plc=="PLC"} {}
          if {$plc=="PLC24"} {
            set min 5200
            set max 5900
          } else {
            set min 28000
            set max 32000
          }
        }
        if {$val>$max || $val<$min} {
          set gaSet(fail) "Analog Input $ch is $val. Should be between $min and $max" 
          return -1  
        } else {
          set ret 0
        }
      }
    }
  }
  
  
  return $ret
}

# ***************************************************************************
# PlcDigitalInputPerf
# ***************************************************************************
proc PlcDigitalInputPerf {} {
  global gaSet buffer
  puts "[MyTime] PlcDigitalInputPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Modpoll ChangeMode fail"
    return -1 
  }  
  
#   for {set ch 1} {$ch <= 6} {incr ch} {
#       puts "PLC open relay of DigitalOutput ch:<$ch>"
#       Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"
#     } 
#     
#     for {set ch 1} {$ch <= 6} {incr ch} {
#       puts "PLC close relay of DigitalOutput ch:<$ch>"
#       Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"
#     }
   
  foreach DI {xx010101 xx101010} {
    RLUsbPio::Set $gaSet(idDI) $DI
    puts "DI : $DI"
    #puts "PLC read DigitalInput ch:<$ch>"
    set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r 1 -c 6 /dev/ttyS1\r" "#"]
    foreach ch {1 2 3 4 5 6} {
      set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val$ch]
    }
    foreach ch {1 2 3 4 5 6} {
      set di$ch [string index $DI end-[expr {$ch-1}]]
      puts "ch:$ch di$ch:<[set di$ch]> val$ch:<[set val$ch]>"
      if {[set val$ch] ne [set di$ch]}  {
        set gaSet(fail) "The Digital Input of ch-$ch is [set val$ch]. Should be [set di$ch]" 
        return -1
      }
    }
    
  }  
#   foreach ch {1 2 3 4 5 6} DI {xx000001 xx000010 xx000100 xx001000 xx010000 xx100000} {
#     ## read DI
#     RLUsbPio::Set $gaSet(idDI) $DI
#     puts "PLC read DigitalInput DI:<$DI> ch:<$ch>"
#     set ret [Send $com "/mnt/extra/modpoll/modpoll -1 -b 115200 -p none -m rtu -t 1 -r $ch -c 1 /dev/ttyS1\r" "#"]
#     set res [regexp "\\\[$ch\\\]\\:\\s+\(\\d\)\\s" $buffer ma val]
#     puts "ma:<$ma> val:<$val>"
#     if {$val ne 1} {
#        set gaSet(fail) "The Digital Input of ch-$ch is $val. Should be 1" 
#        set ret -1
#        break
#     }
#   } 
  
  
  return $ret
}    

# ***************************************************************************
# PlcDigitalOutPerf
# ***************************************************************************
proc PlcDigitalOutPerf {} {
  global gaSet buffer buffer1 buffer2 b
  puts "[MyTime] PlcDigitalOutPerf $gaSet(dutFam.dryCon)"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Modpoll ChangeMode fail"
    return -1 
  }  
  
  foreach rlyState {OFF ON} rlyStateBit {0 1} {
    for {set ch 1} {$ch <= 6} {incr ch} {
      puts "\n\n[MyTime] PLC set relay of CH-$ch to $rlyState"
      Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 $rlyStateBit\r" "#"
    } 
  #   Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r 1 -c 6 /dev/ttyS1 0\r" "#"
    
    foreach DOcomm {xx101010 xx010101} {
      set b1 ""
      set b2 ""
      set b [list]
    
      RLUsbPio::Set $gaSet(idDOcomm) $DOcomm
      RLUsbPio::Get $gaSet(idDO1) buffer1
      RLUsbPio::Get $gaSet(idDO2) buffer2
      foreach {f s} [split $buffer1 ""] {
        append b1 "$f$s "
      }
      foreach {f s} [split $buffer2 ""] {
        append b2 "$f$s "
      }
      set b [concat $b2 $b1]
      puts "DigitalOutput rlyState:$rlyState DOcomm:<$DOcomm> buffer:<$b>"
      
      for {set ch 1} {$ch <= 6} {incr ch} {
        set ret 0
        set commBit [lindex [split $DOcomm "" ] end-[expr {$ch-1}]]
        set doPair  [lindex $b end-[expr {$ch-1}]]
        set ncBit [string index $doPair 1]
        set noBit [string index $doPair 0]
        puts "rlyState:$rlyState ch:$ch commBit:$commBit doPair:$doPair noBit:$noBit ncBit:$ncBit"
        
        if {$rlyState eq "OFF"} {
          if {$gaSet(dutFam.dryCon) eq "GO"} {
            if {$doPair ne "11"} {
              set gaSet(fail) "The Digital_OUT-$ch fail (Relay is $rlyState)" 
              return -1
            }
          } else {
            if {($commBit eq "0" && $doPair ne "10") || ($commBit eq "1" && $doPair ne "11")} {
              set gaSet(fail) "The Digital_OUT-$ch fail (Relay is $rlyState)" 
              return -1
            }     
          }          
        } elseif {$rlyState eq "ON"} {
          
            if {($commBit eq "0" && $doPair ne "01") || ($commBit eq "1" && $doPair ne "11")} {
              set gaSet(fail) "The Digital_OUT-$ch fail (Relay is $rlyState)" 
              return -1
            }
           
        }
        
      }
    }
  }
  
  
#   for {set ch 1} {$ch <= 6} {incr ch} {
#     puts "PLC relay to NO of DigitalOutput ch:<$ch>"
#     Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"
#   } 
#   #Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r 1 -c 6 /dev/ttyS1 1\r" "#"
#   
#   foreach DOcomm {xx101010 xx010101} {
#     set b1 ""
#     set b2 ""
#     set b [list]
#   
#     RLUsbPio::Set $gaSet(idDOcomm) $DOcomm
#     RLUsbPio::Get $gaSet(idDO1) buffer1
#     RLUsbPio::Get $gaSet(idDO2) buffer2
#     foreach {f s} [split $buffer1 ""] {
#       append b1 "$f$s "
#       
#     }
#     foreach {f s} [split $buffer2 ""] {
#       append b2 "$f$s "
#      
#     }
#     set b [concat $b2 $b1]
#     puts "DigitalOutput buffer after relay NO DOcomm:<$DOcomm> buffer:<$b>"
#   }
  
  
  
#   RLUsbPio::Set $gaSet(idDOcomm) 00000001
#   RLUsbPio::Get $gaSet(idDOno) buffer
#   puts "DigitalOutput NO buffer after relay NO:<$buffer>"
#   RLUsbPio::Get $gaSet(idDOnc) buffer
#   puts "DigitalOutput NC buffer after relay NO:<$buffer>"
    
  return $ret
}  
# ***************************************************************************
# PlcLedsPerf
# ***************************************************************************
proc PlcLedsPerf {}  {
  global gaSet buffer
  puts "[MyTime] PlcLedsPerf"
  
  set com $gaSet(comDut)
  Send $com "\r" stam 0.25
  Send $com "\r" stam 0.25
  if {[string match *\#* $buffer] && [string length $buffer]<5} {
    ## we are inside the Linux box already
  } else {  
    Send $com "exit\r\r" "stam" 3 
    Send $com "\33" "stam" 1  
    Send $com "\r\r" "stam" 2       
    if {[string match *login:* $buffer]} {
      set ret 0
    } else {
      Power all off
      after 3000
      Power all on
      set ret [ReadCom $com "login:" 180]
      puts "ret after readComLogin:<$ret>" ; update 
    }
    if {$ret!=0} {return $ret}
    
    Send $com "root\r" "assword"
    Send $com "xbox360\r" "stam" 2
    set ret [DescrPassword "tech" "\#"]
    if {$ret=="-1"} {
      set gaSet(fail) "Enter to Linux shell fail"
    }
  }
  
  set ret [Send $com "chmod 755 /mnt/extra/modpoll/modpoll\r" "#"]
  if {$ret!=0} {
    set gaSet(fail) "Modpoll ChangeMode fail"
    return -1 
  }  
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 1\r" "#"
  }
  RLUsbPio::Set $gaSet(idDI) 11111111
  RLSound::Play information
  set txt "Verify 5VDC between + and - of the Digital IN connector\n\
  Verify 6 Green DIGITAL IN and 6 Red DIGITAL OUT are ON"
  set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "Digital On/OUT led test fail"
    return -1 
  }
  
  for {set ch 1} {$ch <= 6} {incr ch} {
    Send $com "/mnt/extra/modpoll/modpoll -b 115200 -p none -m rtu -t 0 -r $ch -c 1 /dev/ttyS1 0\r" "#"
  }
  RLUsbPio::Set $gaSet(idDI) 00000000
  RLSound::Play information
  set txt "Verify 6 DIGITAL IN and 6 DIGITAL OUT are OFF"
  set ret [DialogBox -title "Digital On/OUT led Test" -type "OK Cancel" -icon images/info -text $txt] 
  if {$ret=="Cancel"} {
    set gaSet(fail) "Digital On/OUT led test fail"
    return -1 
  }
  
  return 0
}