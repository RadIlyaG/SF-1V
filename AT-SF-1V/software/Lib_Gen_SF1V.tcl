
##***************************************************************************
##** OpenRL
##***************************************************************************
proc OpenRL {} {
  global gaSet
  if [info exists gaSet(curTest)] {
    set curTest $gaSet(curTest)
  } else {
    set curTest "1..ID"
  }
  CloseRL
  catch {RLEH::Close}
  
  RLEH::Open
  
  puts "Open PIO [MyTime]"
  set ret [OpenPio]
  set ret1 [OpenComUut]
  
  set ret2 0
    
  set gaSet(curTest) $curTest
  puts "[MyTime] ret:$ret ret1:$ret1 ret2:$ret2 " ; update
  if {$ret1!=0 || $ret2!=0} {
    return -1
  }
  return 0
}

# ***************************************************************************
# OpenComUut
# ***************************************************************************
proc OpenComUut {} {
  global gaSet
  ##set ret [RLSerial::Open $gaSet(comDut) 115200 n 8 1]
  set ret [RLCom::Open $gaSet(comDut) 115200 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comDut) fail"
  }
  set ret [RLCom::Open $gaSet(comSer1) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comSer1) fail"
  }
  set ret [RLCom::Open $gaSet(comSer2) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comSer2) fail"
  }
  set ret [RLCom::Open $gaSet(comSer485) 9600 8 NONE 1]
  if {$ret!=0} {
    set gaSet(fail) "Open COM $gaSet(comSer485) fail"
  }
  return $ret
}
proc ocu {} {OpenComUut}
proc ouc {} {OpenComUut}
proc ccu {} {CloseComUut}
proc cuc {} {CloseComUut}
# ***************************************************************************
# CloseComUut
# ***************************************************************************
proc CloseComUut {} {
  global gaSet
  ##catch {RLSerial::Close $gaSet(comDut)}
  catch {RLCom::Close $gaSet(comDut)}
  catch {RLCom::Close $gaSet(comSer1)}
  catch {RLCom::Close $gaSet(comSer2)}
  catch {RLCom::Close $gaSet(comSer485)}
  return {}
}

#***************************************************************************
#** CloseRL
#***************************************************************************
proc CloseRL {} {
  global gaSet
  set gaSet(serial) ""
  ClosePio
  puts "CloseRL ClosePio" ; update
  CloseComUut
  puts "CloseRL CloseComUut" ; update 
#   catch {RLEtxGen::CloseAll}
  catch {RL10GbGen::Close $gaSet(id220)}
  #catch {RLScotty::SnmpCloseAllTrap}
  catch {RLEH::Close}
}

# ***************************************************************************
# RetriveUsbChannel
# ***************************************************************************
proc RetriveUsbChannel {} {
  global gaSet
  parray ::RLUsbPio::description *Ser*
  set boxL [lsort -dict [array names ::RLUsbPio::description]]
  if {[llength $boxL]!=7 && [llength $boxL]!=14} {
    set gaSet(fail) "Not all USB ports are open. Please close and open the GUIs again"
    return -1
  }
  foreach nam $boxL {
    if [string match *Ser*Num* $nam] {
      foreach {usbChan serNum} [split $nam ,] {}
      set serNum $::RLUsbPio::description($nam)
      puts "usbChan:$usbChan serNum: $serNum"      
      if {$serNum==$gaSet(pioBoxSerNum)} {
        set channel $usbChan
        break
      }
    }  
  }
  puts "serNum:$serNum channel:$channel"
  return $channel
}
# ***************************************************************************
# OpenPio
# ***************************************************************************
proc OpenPio {} {
  global gaSet descript
  set channel [RetriveUsbChannel]
  if {$channel=="-1"} {
    return -1
  }
  foreach rb {1 2 3 4} {
    set gaSet(idPwr$rb) [RLUsbPio::Open $rb RBA $channel]
  }
  
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  set gaSet(idAI)       [RLUsbPio::Open 4 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idAI) 11111111 ; # all 8 pins are IN
  
  set gaSet(idPioDrContIn)  [RLUsbPio::Open 7 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idPioDrContIn) 11111111 ; # all 8 pins are IN
  set gaSet(idPioDrContOut) [RLUsbPio::Open 8 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idPioDrContOut) 00000000 ; # all 8 pins are OUT
  
  set gaSet(idDOcomm) [RLUsbPio::Open 10 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idDOcomm) 00000000 ; # all 8 pins are OUT
  
  set gaSet(idDO1)   [RLUsbPio::Open 11 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idDO1) 11111111 ; # all 8 pins are IN
  
  set gaSet(idDO2)   [RLUsbPio::Open 12 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idDO2) 11111111 ; # all 8 pins are IN
  
  set gaSet(idDI) [RLUsbPio::Open 13 PORT $channel]
  RLUsbPio::SetConfig $gaSet(idDI) 00000000 ; # all 8 pins are OUT
  
  return 0
}

# ***************************************************************************
# ClosePio
# ***************************************************************************
proc ClosePio {} {
  global gaSet
  set ret 0
  foreach rb "1 2 3 4" {
	  catch {RLUsbPio::Close $gaSet(idPwr$rb)}
  }
  catch {RLUsbPio::Close $gaSet(idAI)}
  catch {RLUsbPio::Close $gaSet(idDI)}
  catch {RLUsbPio::Close $gaSet(idDOcomm)}
  catch {RLUsbPio::Close $gaSet(idDO1)}
  catch {RLUsbPio::Close $gaSet(idDO2)}
  catch {RLUsbPio::Close $gaSet(idPioDrContOut)}
  catch {RLUsbPio::Close $gaSet(idPioDrContIn)}
  catch {RLUsbMmux::Close $gaSet(idMuxMngIO)}
  return $ret
}

# ***************************************************************************
# SaveUutInit
# ***************************************************************************
proc SaveUutInit {fil} {
  global gaSet
  puts "SaveUutInit $fil"
  set id [open $fil w]
  puts $id "set gaSet(dbrUbootSWnum)       \"$gaSet(dbrUbootSWnum)\""
  puts $id "set gaSet(dbrUbootSWver)       \"$gaSet(dbrUbootSWver)\""
  puts $id "set gaSet(UbootSWpath)         \"$gaSet(UbootSWpath)\""
  
  puts $id "set gaSet(uutSWfrom)           \"$gaSet(uutSWfrom)\""
  puts $id "set gaSet(dbrSWnum)            \"$gaSet(dbrSWnum)\""
  puts $id "set gaSet(SWver)               \"$gaSet(SWver)\""
  puts $id "set gaSet(UutSWpath)           \"$gaSet(UutSWpath)\""
    
  puts $id "set gaSet(mainHW)              \"$gaSet(mainHW)\""
  puts $id "set gaSet(mainPcbId)           \"$gaSet(mainPcbId)\""
    
  puts $id "set gaSet(sub1HW)              \"$gaSet(sub1HW)\""
  puts $id "set gaSet(sub1PcbId)           \"$gaSet(sub1PcbId)\""
  
  puts $id "set gaSet(LXDpath)             \"$gaSet(LXDpath)\""
  
  puts $id "set gaSet(csl)                 \"$gaSet(csl)\""
  
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(DutFullName) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
  
  
  #puts $id "set gaSet(macIC)      \"$gaSet(macIC)\""
  close $id
}  
# ***************************************************************************
# SaveInit
# ***************************************************************************
proc SaveInit {} {
  global gaSet  
  set id [open [info host]/init$gaSet(pair).tcl w]
  puts $id "set gaGui(xy) +[winfo x .]+[winfo y .]"
  if [info exists gaSet(DutFullName)] {
    puts $id "set gaSet(entDUT) \"$gaSet(DutFullName)\""
  }
  if [info exists gaSet(DutInitName)] {
    puts $id "set gaSet(DutInitName) \"$gaSet(DutInitName)\""
  }
    
  if {![info exists gaSet(eraseTitle)]} {
    set gaSet(eraseTitle) 1
  }
  puts $id "set gaSet(eraseTitle) \"$gaSet(eraseTitle)\""
  
  close $id   
}

#***************************************************************************
#** MyTime
#***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}

#***************************************************************************
#** Send
#** #set ret [RLCom::SendSlow $com $toCom 150 buffer $fromCom $timeOut]
#** #set ret [Send$com $toCom buffer $fromCom $timeOut]
#** 
#***************************************************************************
proc Send {com sent {expected stamm} {timeOut 8}} {
  global buffer gaSet
  if {$gaSet(act)==0} {return -2}

  #puts "sent:<$sent>"
  
  ## replace a few empties by one empty
  regsub -all {[ ]+} $sent " " sent
  
  #puts "sent:<[string trimleft $sent]>"
  ##set cmd [list RLSerial::SendSlow $com $sent 50 buffer $expected $timeOut]
  if {$expected=="stamm"} {
    ##set cmd [list RLSerial::Send $com $sent]
    set cmd [list RLCom::Send $com $sent]
    foreach car [split $sent ""] {
      set asc [scan $car %c]
      #puts "car:$car asc:$asc" ; update
      if {[scan $car %c]=="13"} {
        append sentNew "\\r"
      } elseif {[scan $car %c]=="10"} {
        append sentNew "\\n"
      } {
        append sentNew $car
      }
    }
    set sent $sentNew
  
    set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
    puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "send: com:$com, ret:$ret tt:$tt, sent=$sent"
    puts "send: ----------------------------------------\n"
    update
    return $ret
    
  }
  #set cmd [list RLSerial::Send $com $sent buffer $expected $timeOut]
  set cmd [list RLCom::Send $com $sent buffer $expected $timeOut]
  if {$gaSet(act)==0} {return -2}
  set tt "[expr {[lindex [time {set ret [eval $cmd]}] 0]/1000000.0}]sec"
  #puts buffer:<$buffer> ; update
  regsub -all -- {\x1B\x5B..\;..H} $buffer " " b1
  regsub -all -- {\x1B\x5B.\;..H}  $b1 " " b1
  regsub -all -- {\x1B\x5B..\;.H}  $b1 " " b1
  regsub -all -- {\x1B\x5B.\;.H}   $b1 " " b1
  regsub -all -- {\x1B\x5B..\;..r} $b1 " " b1
  regsub -all -- {\x1B\x5B.J}      $b1 " " b1
  regsub -all -- {\x1B\x5BK}       $b1 " " b1
  regsub -all -- {\x1B\x5B\x38\x30\x44}     $b1 " " b1
  regsub -all -- {\x1B\x5B\x31\x42}      $b1 " " b1
  regsub -all -- {\x1B\x5B.\x6D}      $b1 " " b1
  regsub -all -- \\\[m $b1 " " b1
  set re \[\x1B\x0D\]
  regsub -all -- $re $b1 " " b2
  #regsub -all -- ..\;..H $b1 " " b2
  regsub -all {\s+} $b2 " " b3
  regsub -all {\-+} $b3 "-" b3
  regsub -all -- {\[0\;30\;47m} $b3 " " b3
  regsub -all -- {\[1\;30\;47m} $b3 " " b3
  regsub -all -- {\[0\;34\;47m} $b3 " " b3
  regsub -all -- {\[74G}        $b3 " " b3
  set buffer $b3
  
  foreach car [split $sent ""] {
    set asc [scan $car %c]
    #puts "car:$car asc:$asc" ; update
    if {[scan $car %c]=="13"} {
      append sentNew "\\r"
    } elseif {[scan $car %c]=="10"} {
      append sentNew "\\n"
    } {
      append sentNew $car
    }
  }
  set sent $sentNew
  
  #puts "sent:<$sent>"
  if $gaSet(puts) {
    #puts "\nsend: ---------- [clock format [clock seconds] -format %T] ---------------------------"
    #puts "\nsend: ---------- [MyTime] ---------------------------"
    puts "\n[MyTime] Send: com:$com, ret:$ret tt:$tt, sent=$sent,  expected=<$expected>, buffer=<$buffer>"
    #puts "send: ----------------------------------------\n"
    update
  }
  
  #RLTime::Delayms 50
  return $ret
}

#***************************************************************************
#** Status
#***************************************************************************
proc Status {txt {color white}} {
  global gaSet gaGui
  #set gaSet(status) $txt
  #$gaGui(labStatus) configure -bg $color
  $gaSet(sstatus) configure -bg $color  -text $txt
  if {$txt!=""} {
    puts "\n ..... $txt ..... /* [MyTime] */ \n"
  }
  $gaSet(runTime) configure -text ""
  update
}


##***************************************************************************
##** Wait
##** 
##** 
##***************************************************************************
proc Wait {txt count {color white}} {
  global gaSet
  puts "\nStart Wait $txt $count.....[MyTime]"; update
  Status $txt $color 
  for {set i $count} {$i > 0} {incr i -1} {
    if {$gaSet(act)==0} {return -2}
	 $gaSet(runTime) configure -text $i
	 RLTime::Delay 1
  }
  $gaSet(runTime) configure -text ""
  Status "" 
  puts "Finish Wait $txt $count.....[MyTime]\n"; update
  return 0
}


#***************************************************************************
#** Init_UUT
#***************************************************************************
proc Init_UUT {init} {
  global gaSet
  set gaSet(curTest) $init
  Status ""
  OpenRL
  $init
  CloseRL
  set gaSet(curTest) ""
  Status "Done"
}


# ***************************************************************************
# PerfSet
# ***************************************************************************
proc PerfSet {state} {
  global gaSet gaGui
  set gaSet(perfSet) $state
  puts "PerfSet state:$state"
  switch -exact -- $state {
    1 {$gaGui(noSet) configure -relief raised -image [Bitmap::get images/Set] -helptext "Run with the UUTs Setup"}
    0 {$gaGui(noSet) configure -relief sunken -image [Bitmap::get images/noSet] -helptext "Run without the UUTs Setup"}
    swap {
      if {[$gaGui(noSet) cget -relief]=="raised"} {
        PerfSet 0
      } elseif {[$gaGui(noSet) cget -relief]=="sunken"} {
        PerfSet 1
      }
    }  
  }
}
# ***************************************************************************
# MyWaitFor
# ***************************************************************************
proc MyWaitFor {com expected testEach timeout} {
  global buffer gaGui gaSet
  #Status "Waiting for \"$expected\""
  if {$gaSet(act)==0} {return -2}
  puts [MyTime] ; update
  set startTime [clock seconds]
  set runTime 0
  while 1 {
    #set ret [RLCom::Waitfor $com buffer $expected $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    #set ret [Send $com \r stam $testEach]
    #set ret [RLSerial::Waitfor $com buffer stam $testEach]
    #set ret [RLCom::Waitfor $com buffer stam $testEach]
    set ret [Send $com \r stam $testEach]
    foreach expd $expected {
      if [string match *$expd* $buffer] {
        set ret 0
      }
      puts "buffer:__[set buffer]__ expected:\"$expected\" expd:\"$expd\" ret:$ret runTime:$runTime" ; update
#       if {$expd=="PASSWORD"} {
#         ## in old versiond you need a few enters to get the uut respond
#         Send $com \r stam 0.25
#       }
      if [string match *$expd* $buffer] {
        break
      }
    }
    #set ret [Send $com \r $expected $testEach]
    set nowTime [clock seconds]; set runTime [expr {$nowTime - $startTime}] 
    $gaSet(runTime) configure -text $runTime
    #puts "i:$i runTime:$runTime ret:$ret buffer:_${buffer}_" ; update
    if {$ret==0} {break}
    if {$runTime>$timeout} {break }
    if {$gaSet(act)==0} {set ret -2 ; break}
    update
  }
  puts "[MyTime] ret:$ret runTime:$runTime"
  $gaSet(runTime) configure -text ""
  Status ""
  return $ret
}   
# ***************************************************************************
# Power
# ***************************************************************************
proc Power {ps state} {
  global gaSet gaGui 
  puts "[MyTime] Power $ps $state"
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
#   return 0
  set ret 0
  switch -exact -- $ps {
    1   {set pioL [list 1 3]}
    2   {set pioL [list 2 4]}
    all {set pioL "1 2 3 4"}
  } 
  switch -exact -- $state {
    on  {
	    foreach pio $pioL {      
        RLUsbPio::Set $gaSet(idPwr$pio) 1
      }
    } 
	  off {
	    foreach pio $pioL {
	      RLUsbPio::Set $gaSet(idPwr$pio) 0
      }
    }
  }
#   $gaGui(tbrun)  configure -state disabled 
#   $gaGui(tbstop) configure -state normal
  Status ""
  update
  #exec C:\\RLFiles\\Btl\\beep.exe &
#   RLSound::Play information
#   DialogBox -type OK -message "Turn $ps $state"
  return $ret
}

# ***************************************************************************
# GuiPower
# ***************************************************************************
proc GuiPower {n state} { 
  global gaSet descript
  puts "\nGuiPower $n $state"
  RLEH::Open
  RLUsbPio::GetUsbChannels descript
  switch -exact -- $n {
    1.1 - 2.1 - 3.1 - 4.1 - 5.1 - SE.1 {set portL [list 1 3]}
    1.2 - 2.2 - 3.2 - 4.2 - 5.2 - SE.2 {set portL [list 2 4 ]}      
    1 - 2 - 3 - 4 - 5 - SE - all       {set portL [list 1 2 3 4]}  
  }        
  set channel [RetriveUsbChannel]
  if {$channel!="-1"} {
    foreach rb $portL {
      set id [RLUsbPio::Open $rb RBA $channel]
      puts "rb:<$rb> id:<$id>"
      RLUsbPio::Set $id $state
      RLUsbPio::Close $id
    }   
  }
  RLEH::Close
} 

#***************************************************************************
#** Wait
#***************************************************************************
proc _Wait {ip_time ip_msg {ip_cmd ""}} {
  global gaSet 
  Status $ip_msg 

  for {set i $ip_time} {$i >= 0} {incr i -1} {       	 
	 if {$ip_cmd!=""} {
      set ret [eval $ip_cmd]
		if {$ret==0} {
		  set ret $i
		  break
		}
	 } elseif {$ip_cmd==""} {	   
	   set ret 0
	 }

	 #user's stop case
	 if {$gaSet(act)==0} {		 
      return -2
	 }
	 
	 RLTime::Delay 1	 
    $gaSet(runTime) configure -text " $i "
	 update	 
  }
  $gaSet(runTime) configure -text ""
  update   
  return $ret  
}

# ***************************************************************************
# AddToLog
# ***************************************************************************
proc AddToLog {line} {
  global gaSet
  #set logFileID [open tmpFiles/logFile-$gaSet(pair).txt a+]
  set logFileID [open $gaSet(logFile.$gaSet(pair)) a+] 
    puts $logFileID "..[MyTime]..$line"
  close $logFileID
}

# ***************************************************************************
# AddToPairLog
# ***************************************************************************
proc AddToPairLog {pair line}  {
  global gaSet
  set logFileID [open $gaSet(log.$pair) a+]
  puts $logFileID "..[MyTime]..$line"
  close $logFileID
}
# ***************************************************************************
# ShowLog 
# ***************************************************************************
proc ShowLog {} {
	global gaSet
	#exec notepad tmpFiles/logFile-$gaSet(pair).txt &
#   if {[info exists gaSet(logFile.$gaSet(pair))] && [file exists $gaSet(logFile.$gaSet(pair))]} {
#     exec notepad $gaSet(logFile.$gaSet(pair)) &
#   }
  if {[info exists gaSet(log.$gaSet(pair))] && [file exists $gaSet(log.$gaSet(pair))]} {
    exec notepad $gaSet(log.$gaSet(pair)) &
  }
}

# ***************************************************************************
# mparray
# ***************************************************************************
proc mparray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
	  error "\"$a\" isn't an array"
  }
  set maxl 0
  foreach name [lsort -dict [array names array $pattern]] {
	  if {[string length $name] > $maxl} {
	    set maxl [string length $name]
  	}
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name [lsort -dict [array names array $pattern]] {
	  set nameString [format %s(%s) $a $name]
	  puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
  update
}
# ***************************************************************************
# GetDbrName
# ***************************************************************************
proc GetDbrName {} {
  global gaSet gaGui
  Status "Please wait for retriving DBR's parameters"
  set barcode [set gaSet(entDUT) [string toupper $gaSet(entDUT)]] ; update
  
  if [file exists MarkNam_$barcode.txt] {
    file delete -force MarkNam_$barcode.txt
  }
  #wm title . "$gaSet(pair) : "
  if $gaSet(demo) {
    wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
  } else {
    wm title . "$gaSet(pair) : "
  }
  after 500
  
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/OI4Barcode.jar $barcode} b
  set fileName MarkNam_$barcode.txt
  after 1000
  if ![file exists MarkNam_$barcode.txt] {
    set gaSet(fail) "File $fileName is not created. Verify the Barcode"
    #exec C:\\RLFiles\\Tools\\Btl\\failbeep.exe &
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  
  set fileId [open "$fileName"]
    seek $fileId 0
    set res [read $fileId]    
  close $fileId
  
  #set txt "$barcode $res"
  set txt "[string trim $res]"
  #set gaSet(entDUT) $txt
  set gaSet(entDUT) ""
  puts "GetDbrName <$txt>"
  
  set initName [regsub -all / $res .]
  puts "GetDbrName res:<$res>"
  puts "GetDbrName initName:<$initName>"
  set gaSet(DutFullName) $res
  set gaSet(DutInitName) $initName.tcl
  
  file delete -force MarkNam_$barcode.txt
  #file mkdir [regsub -all / $res .]
  
  if {[file exists uutInits/$gaSet(DutInitName)]} {
    source uutInits/$gaSet(DutInitName)  
    #UpdateAppsHelpText  
  } else {
    ## if the init file doesn't exist, fill the parameters by ? signs
    foreach v {sw} {
      puts "GetDbrName gaSet($v) does not exist"
      set gaSet($v) ??
    }
    foreach en {licEn} {
      set gaSet($v) 0
    } 
  } 
  #wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  if $gaSet(demo) {
    wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
  } else {
    wm title . "$gaSet(pair) : $gaSet(DutFullName)"
  }
  pack forget $gaGui(frFailStatus)
  #Status ""
  update
  BuildTests
  
  set ret [GetDbrSW $barcode]
  puts "GetDbrName ret of GetDbrSW:$ret" ; update
  if {$ret!=0} {
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  }  
  puts ""
  
  focus -force $gaGui(tbrun)
  if {$ret==0} {
    Status "Ready"
  }
  return $ret
}

# ***************************************************************************
# DelMarkNam
# ***************************************************************************
proc DelMarkNam {} {
  if {[catch {glob MarkNam*} MNlist]==0} {
    foreach f $MNlist {
      file delete -force $f
    }  
  }
}

# ***************************************************************************
# GetInitFile
# ***************************************************************************
proc GetInitFile {} {
  global gaSet gaGui
  set fil [tk_getOpenFile -initialdir [pwd]/uutInits  -filetypes {{{TCL Scripts} {.tcl}}} -defaultextension tcl]
  if {$fil!=""} {
    source $fil
    set gaSet(entDUT) "" ; #$gaSet(DutFullName)
    if {[regsub -all {\.} $gaSet(DutFullName)  "/" a]!=0} {
      set gaSet(DutFullName) $a
    }
    
    #wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    if $gaSet(demo) {
      wm title . "DEMO!!! $gaSet(pair) : $gaSet(DutFullName)"
    } else {
      wm title . "$gaSet(pair) : $gaSet(DutFullName)"
    }
    #UpdateAppsHelpText
    pack forget $gaGui(frFailStatus)
    Status ""
    BuildTests
  }
}
# ***************************************************************************
# UpdateAppsHelpText
# ***************************************************************************
proc UpdateAppsHelpText {} {
  global gaSet gaGui
  #$gaGui(labPlEnPerf) configure -helptext $gaSet(pl)
  #$gaGui(labUafEn) configure -helptext $gaSet(uaf)
  #$gaGui(labUdfEn) configure -helptext $gaSet(udf)
}
proc ccc {} {
  console eval {set ::tk::console::maxLines 10000}
  console eval {.console delete 1.0 end}
  set li [list SF-1V/E1/12V/4U1S/2RS/HSP SF-1V/E1/12V/4U1S/2RS/HSP/G \
  SF-1V/E1/12V/4U1S/2RS/L1 SF-1V/E1/12V/4U1S/2RS/L1/G SF-1V/E1/12V/4U1S/2RS/L2 \
  SF-1V/E1/12V/4U1S/2RS/L2/G SF-1V/E1/12V/4U1S/2RS/L3 SF-1V/E1/12V/4U1S/2RS/L3/G \
  SF-1V/E1/12V/4U1S/2RS/L4 SF-1V/E1/12V/4U1S/2RS/L4/G SF-1V/E1/12V/4U1S/2RSM/HSP \
  SF-1V/E1/12V/4U1S/2RSM/L1 SF-1V/E1/12V/4U1S/2RSM/L2 SF-1V/E1/12V/4U1S/2RSM/L3 \
  SF-1V/E1/12V/4U1S/2RSM/L4 SF-1V/E1/WDC/4U1S SF-1V/E1/WDC/4U1S/2RS \
  SF-1V/E1/WDC/4U1S/2RS/CSP SF-1V/E1/WDC/4U1S/2RS/HSP SF-1V/E1/WDC/4U1S/2RS/HSP/G\
  SF-1V/E1/WDC/4U1S/2RS/L1 SF-1V/E1/WDC/4U1S/2RS/L1/CSP SF-1V/E1/WDC/4U1S/2RS/L1/DEMO\
  SF-1V/E1/WDC/4U1S/2RS/L1/G SF-1V/E1/WDC/4U1S/2RS/L2 SF-1V/E1/WDC/4U1S/2RS/L2/G \
  SF-1V/E1/WDC/4U1S/2RS/L3 SF-1V/E1/WDC/4U1S/2RS/L3/G SF-1V/E1/WDC/4U1S/2RS/L4 \
  SF-1V/E1/WDC/4U1S/2RS/L4/G SF-1V/E1/WDC/4U1S/2RSM/HSP SF-1V/E1/WDC/4U1S/2RSM/L1 \
  SF-1V/E1/WDC/4U1S/2RSM/L1/G SF-1V/E1/WDC/4U1S/2RSM/L2 SF-1V/E1/WDC/4U1S/2RSM/L3\
  SF-1V/E1/WDC/4U1S/2RSM/L4 SF-1V/E2/12V/4U1S/2RS/HSP/G/HSP SF-1V/E2/12V/4U1S/2RS/HSP/G/WF\
  SF-1V/E2/12V/4U1S/2RS/HSP/HSP SF-1V/E2/12V/4U1S/2RS/HSP/HSP/G SF-1V/E2/12V/4U1S/2RS/L1/G/L1 \
  SF-1V/E2/12V/4U1S/2RS/L1/G/WF SF-1V/E2/12V/4U1S/2RS/L1/L1 SF-1V/E2/12V/4U1S/2RS/L1/L1/G\
SF-1V/E2/12V/4U1S/2RS/L2/G/L2 SF-1V/E2/12V/4U1S/2RS/L2/G/WF SF-1V/E2/12V/4U1S/2RS/L2/L2 \
SF-1V/E2/12V/4U1S/2RS/L3/G/L3 SF-1V/E2/12V/4U1S/2RS/L3/G/WF SF-1V/E2/12V/4U1S/2RS/L3/L3 \
SF-1V/E2/12V/4U1S/2RS/L4/G/GO SF-1V/E2/12V/4U1S/2RS/L4/G/L4 SF-1V/E2/12V/4U1S/2RS/L4/G/WF \
SF-1V/E2/12V/4U1S/2RS/L4/L4 SF-1V/E2/48V/4U1S/2PA/2RS SF-1V/E2/48V/4U1S/2PA/2RS/HSP\
SF-1V/E2/48V/4U1S/2PA/2RS/L1 SF-1V/E2/48V/4U1S/2PA/2RS/L2 SF-1V/E2/48V/4U1S/2PA/2RS/L3 \
SF-1V/E2/48V/4U1S/2PA/2RS/L4 SF-1V/E2/48V/4U1S/2RS/L2/RG SF-1V/E2/48V/4U1S/2RS/L3/RG\
SF-1V/E2/48V/4U1S/POE SF-1V/E2/48V/4U1S/POE/2RS SF-1V/E2/48V/4U1S/POE/2RS/HSP\
SF-1V/E2/48V/4U1S/POE/2RS/HSP/G/WF SF-1V/E2/48V/4U1S/POE/2RS/HSP/HSP\
SF-1V/E2/48V/4U1S/POE/2RS/HSP/WF SF-1V/E2/48V/4U1S/POE/2RS/L1 \
SF-1V/E2/48V/4U1S/POE/2RS/L1/G SF-1V/E2/48V/4U1S/POE/2RS/L1/G/L1\
SF-1V/E2/48V/4U1S/POE/2RS/L1/G/LR1 SF-1V/E2/48V/4U1S/POE/2RS/L1/G/LR2\
SF-1V/E2/48V/4U1S/POE/2RS/L1/G/WF SF-1V/E2/48V/4U1S/POE/2RS/L1/L1\
SF-1V/E2/48V/4U1S/POE/2RS/L1/LR2 SF-1V/E2/48V/4U1S/POE/2RS/L1/WF\
SF-1V/E2/48V/4U1S/POE/2RS/L2 SF-1V/E2/48V/4U1S/POE/2RS/L2/G/LR2\
SF-1V/E2/48V/4U1S/POE/2RS/L2/G/WF SF-1V/E2/48V/4U1S/POE/2RS/L2/L2\
SF-1V/E2/48V/4U1S/POE/2RS/L2/WF SF-1V/E2/48V/4U1S/POE/2RS/L3\
SF-1V/E2/48V/4U1S/POE/2RS/L3/G/L3 SF-1V/E2/48V/4U1S/POE/2RS/L3/G/LR3\
SF-1V/E2/48V/4U1S/POE/2RS/L3/G/LR6 SF-1V/E2/48V/4U1S/POE/2RS/L3/G/WF\
SF-1V/E2/48V/4U1S/POE/2RS/L3/L3 SF-1V/E2/48V/4U1S/POE/2RS/L3/WF\
SF-1V/E2/48V/4U1S/POE/2RS/L4 SF-1V/E2/48V/4U1S/POE/2RS/L4/G/L4\
SF-1V/E2/48V/4U1S/POE/2RS/L4/G/LR4 SF-1V/E2/48V/4U1S/POE/2RS/L4/G/WF\
SF-1V/E2/48V/4U1S/POE/2RS/L4/L4 SF-1V/E2/48V/4U1S/POE/2RS/L4/WF\
SF-1V/E2/48V/4U1S/POE/2RSM/L1/G/LR2 SF-1V/E2/48V/4U1S/POE/2RSM/L1/G/WF\
SF-1V/E2/48V/4U1S/POE/2RSM/L2/G/WF SF-1V/E2/48V/4U1S/POE/2RSM/L3/G/WF \
SF-1V/E2/WDC/4U1S SF-1V/E2/WDC/4U1S/2RS/HSP/G/HSP SF-1V/E2/WDC/4U1S/2RS/HSP/RG\
SF-1V/E2/WDC/4U1S/2RS/HSP/WF SF-1V/E2/WDC/4U1S/2RS/L1/G/L1 SF-1V/E2/WDC/4U1S/2RS/L1/RG\
SF-1V/E2/WDC/4U1S/2RS/L1/WF SF-1V/E2/WDC/4U1S/2RS/L2/G/L2 SF-1V/E2/WDC/4U1S/2RS/L2/RG\
SF-1V/E2/WDC/4U1S/2RS/L2/WF SF-1V/E2/WDC/4U1S/2RS/L3/G/L3 SF-1V/E2/WDC/4U1S/2RS/L3/RG\
SF-1V/E2/WDC/4U1S/2RS/L3/WF SF-1V/E2/WDC/4U1S/2RS/L4/G/L4 SF-1V/E2/WDC/4U1S/2RS/L4/RG\
SF-1V/E2/WDC/4U1S/2RS/L4/WF SF-1V/E2/WDC/4U1S/2RSM SF-1V/E2/WDC/4U1S/L1/WF\
SF-1V/E2/WDC/4U1S/MAIN SF-1V/E2/WDC/4U1S/POE/2RS/HSP/G SF-1V/E2/WDC/4U1S/POE/2RS/HSP/HSP/G\
SF-1V/E2/WDC/4U1S/POE/2RS/L1 SF-1V/E2/WDC/4U1S/POE/2RS/L1/DEMO\
SF-1V/E2/WDC/4U1S/POE/2RS/L1/L1/G SF-1V/E2/WDC/4U1S/POE/2RS/L2/L2/G\
SF-1V/E2/WDC/4U1S/POE/2RS/L3/L3/G SF-1V/E3/48V/4U1S/POE/2RS/HSP/G/PLC\
SF-1V/E3/48V/4U1S/POE/2RS/L1/G/PLC SF-1V/E3/48V/4U1S/POE/2RS/L1/PLCD\
SF-1V/E3/48V/4U1S/POE/2RS/L2/G/PLC SF-1V/E3/48V/4U1S/POE/2RS/L2/PLCD\
SF-1V/E3/48V/4U1S/POE/2RS/L3/G/PLC SF-1V/E3/48V/4U1S/POE/2RS/L3/PLCD\
SF-1V/E3/48V/4U1S/POE/2RS/L4/G/PLC SF-1V/E3/48V/4U1S/POE/2RS/L4/PLCD\
SF-1V/E3/48V/4U1S/POE/2RSM/HSP/G/PLC SF-1V/E3/48V/4U1S/POE/2RSM/L1/G/PLC\
SF-1V/E3/48V/4U1S/POE/2RSM/L2/G/PLC SF-1V/E3/48V/4U1S/POE/2RSM/L3/G/PLC\
SF-1V/E3/48V/4U1S/POE/2RSM/L4/G/PLC SF-1V/E3/WDC/2R/4U1S/2RS/L4/G/PLC\
SF-1V/E3/WDC/4U1S/2RS/HSP/G/PLC SF-1V/E3/WDC/4U1S/2RS/L1/G/PLC\
SF-1V/E3/WDC/4U1S/2RS/L2/G/PLC SF-1V/E3/WDC/4U1S/2RS/L3/G/PLC\
SF-1V/E3/WDC/4U1S/2RS/L4/G/PLC SF-1V/E3/WDC/4U1S/2RS/L4/G/PLCGO\
SF-1V/E3/WDC/4U1S/2RS/L4/PLC SF-1V/E3/WDC/4U1S/2RSM/HSP/G/PLC\
SF-1V/E3/WDC/4U1S/2RSM/L1/G/PLC SF-1V/E3/WDC/4U1S/2RSM/L2/G/PLC\
SF-1V/E3/WDC/4U1S/2RSM/L3/G/PLC SF-1V/E3/WDC/4U1S/2RSM/L4/G/PLC\
SF-1V/E3/WDC/4U1S/2RSM/PLC/TEMP \
]
set l2 [list SF-1V/E2/WDC/4U1S/POE/2RS/L3/L3/G SF-1V/E2/WDC/4U1S/2RS/L1/G/L1 SF-1V/E1/WDC/4U1S/2RS/CSP]
return $li ; #$l2
}

proc qqq {} {
  foreach sf [ccc] {
    set dutInitName  [regsub -all / $sf .].tcl
    RetriveDutFam $dutInitName
  }
}
# ***************************************************************************
# RetriveDutFam
## set dutInitName  [regsub -all / SF-1V/E2/12V/4U1S/2RS/L1/G/L1 .].tcl
# RetriveDutFam $dutInitName
# ***************************************************************************
proc RetriveDutFam {{dutInitName ""}} {
  global gaSet 
  array unset gaSet dutFam.*
  #set gaSet(dutFam) NA 
  #set gaSet(dutBox) NA 
  if {$dutInitName==""} {
    set dutInitName $gaSet(DutInitName)
  }
  puts "[MyTime] RetriveDutFam $dutInitName"
  set fieldsL [lrange [split $dutInitName .] 0 end-1] ; # remove tcl
  
  #set gaSet(dutFam.sf)  "SF-1V"
  regexp {([A-Z0-9\-\_]+)\.E} $dutInitName ma gaSet(dutFam.sf)
  switch -exact -- $gaSet(dutFam.sf) {
    SF-1V - SF-1V_CIE {set gaSet(appPrompt) "SecFlow-1v#"}
    VB-101V {set gaSet(appPrompt) "VB101V#"}
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.sf)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  regexp {V\.(E\d)\.} $dutInitName ma gaSet(dutFam.box)
  set idx [lsearch $fieldsL $gaSet(dutFam.box)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  regexp {E\d\.([A-Z0-9]+)\.} $dutInitName ma gaSet(dutFam.ps)
  set idx [lsearch $fieldsL $gaSet(dutFam.ps)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set gaSet(dutFam.ethPort)  "4U1S"
  set idx [lsearch $fieldsL $gaSet(dutFam.ethPort)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.2RS\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RS
  } elseif {[string match *\.2RSM\.* $dutInitName]} {
    set gaSet(dutFam.serPort) 2RSM
  } else {
    set gaSet(dutFam.serPort) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.serPort)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  if {[string match *\.CSP\.* $dutInitName]} {
    set gaSet(dutFam.serPortCsp) CSP
  } else {
    set gaSet(dutFam.serPortCsp) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.serPortCsp)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.2PA\.* $dutInitName]} {
    set gaSet(dutFam.poe) 2PA
  } elseif {[string match *\.POE\.* $dutInitName]} {
    set gaSet(dutFam.poe) POE
  } else {
    set gaSet(dutFam.poe) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.poe)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set gaSet(dutFam.cell) 0
  foreach cell [list HSP L1 L2 L3 L4] {
    set qty [llength [lsearch -all [split $dutInitName .] $cell]]
    if $qty {
      set gaSet(dutFam.cell) $qty$cell
      break
    }  
  }
  ## twice, since 2 modems can be installed
  set idx [lsearch $fieldsL [string range $gaSet(dutFam.cell) 1 end]]
  set fieldsL [lreplace $fieldsL $idx $idx]
  set idx [lsearch $fieldsL [string range $gaSet(dutFam.cell) 1 end]]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.G\.* $dutInitName]} {
    set gaSet(dutFam.gps) G
  } else {
    set gaSet(dutFam.gps) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.gps)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.WF\.* $dutInitName]} {
    set gaSet(dutFam.wifi) WF
  } else {
    set gaSet(dutFam.wifi) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.wifi)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.GO\.* $dutInitName] || [string match *GO\.tcl $dutInitName]} {
    set gaSet(dutFam.dryCon) GO
  } else {
    set gaSet(dutFam.dryCon) FULL
  }
  
  if {[string match *\.RG\.* $dutInitName]} {
    set gaSet(dutFam.rg) RG
  } else {
    set gaSet(dutFam.rg) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.rg)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set qty [regexp -all {\.(LR[A1-6]?)\.} $dutInitName ma lora]
  set qty [regexp -all {\.(LR[A-Z1-6]+?)\.} $dutInitName ma lora]
  if $qty {
    set gaSet(dutFam.lora) $lora
    switch -exact -- $lora {
      LR1  {set gaSet(dutFam.lora.region) eu433; set gaSet(dutFam.lora.band) "EU 433"}
      LR2  {set gaSet(dutFam.lora.region) eu868; set gaSet(dutFam.lora.band) "EU 863-870"}
      LR3  {set gaSet(dutFam.lora.region) au915; set gaSet(dutFam.lora.band) "AU 915-928 Sub-band 2"}
      LR4  {set gaSet(dutFam.lora.region) us902; set gaSet(dutFam.lora.band) "US 902-928 Sub-band 2"}
      LR6  {set gaSet(dutFam.lora.region) as923; set gaSet(dutFam.lora.band) "AS 923-925"}
    }
    ## 10:46 26/12/2023 LRAC {set gaSet(dutFam.lora.region) us902; set gaSet(dutFam.lora.band) "US 902-928 Sub-band 2"}
  } else {
    set gaSet(dutFam.lora) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.lora)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  set qty [regexp -all {\.(PLC|PLCD|PLCGO|PLC12|PLC24)\.} $dutInitName ma plc]
  if $qty {
    set gaSet(dutFam.plc) $plc
  } else {
    set gaSet(dutFam.plc) 0
  }
  set idx [lsearch $fieldsL $gaSet(dutFam.plc)]
  set fieldsL [lreplace $fieldsL $idx $idx]
  set idx [lsearch $fieldsL "3CL"]
  set fieldsL [lreplace $fieldsL $idx $idx]
  
  if {[string match *\.2R\.* $dutInitName]} {
    set gaSet(dutFam.mem) 2
    set idx [lsearch $fieldsL ${gaSet(dutFam.mem)}R]
    set fieldsL [lreplace $fieldsL $idx $idx]
  } else {
    set gaSet(dutFam.mem) 1
  }
  
  puts "fieldsL:<$fieldsL>"
  puts "[parray gaSet dut*]\n" ; update

  if [llength $fieldsL] {
    RLSound::Play fail
    set res [DialogBox -title "Unknown option" -message "The following is unknown:\n\n$fieldsL"\
      -type OK -icon /images/error]
  }

}  

# ***************************************************************************
# BuildEepromString
## BuildEepromString newUut
# ***************************************************************************
proc BuildEepromString {mode} {
  global gaSet
  puts "[MyTime] BuildEepromString $mode"
  
  if {$gaSet(dutFam.cell)=="0" && $gaSet(dutFam.wifi)=="0"} {
    ## no modems, no wifi
    set gaSet(eeprom.mod1man) ""
    set gaSet(eeprom.mod1type) ""
    set gaSet(eeprom.mod2man) ""
    set gaSet(eeprom.mod2type) ""
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.wifi)=="0" && $gaSet(dutFam.lora)=="0"} {
    ## just modem 1, no modem 2 and no wifi
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man) ""
    set gaSet(eeprom.mod2type) ""        
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.wifi)=="WF"} {
    ## modem 1 and wifi instead of modem 2
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan  -wifi]
    set gaSet(eeprom.mod2type) [ModType -wifi]
  } elseif {$gaSet(dutFam.cell)=="0" && $gaSet(dutFam.wifi)=="WF"} {
    ## no modem 1, wifi instead of modem 2
    set gaSet(eeprom.mod1man)  ""
    set gaSet(eeprom.mod1type) ""
    set gaSet(eeprom.mod2man)  [ModMan  -wifi]
    set gaSet(eeprom.mod2type) [ModType -wifi]    
  } elseif {[string index $gaSet(dutFam.cell) 0]=="2"} {
    ## two modems are installed
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2type) [ModType $gaSet(dutFam.cell)]
  } elseif {[string index $gaSet(dutFam.cell) 0]=="1" && $gaSet(dutFam.lora)!="0"} {
    ## modem 1 and LoRa instead of modem 2
    set gaSet(eeprom.mod1man)  [ModMan $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod1type) [ModType $gaSet(dutFam.cell)]
    set gaSet(eeprom.mod2man)  [ModMan  -lora]
    set gaSet(eeprom.mod2type) [ModType -lora]
  }
  
  if {$mode=="newUut"} {
    set ret [GetMac 6]
    if {$ret=="-1" || $ret=="-2"} {
      return $ret
    } 
    foreach {a b} [split $ret {}] {
      append mac ${a}${b}:
    }
    set mac [string trim $mac :]
  } else {
    set mac "NoMac"
  }
  set gaSet(eeprom.mac) $mac
  #set mac 00:20:D2:AB:76:92
  set partNum [regsub -all {\.} $gaSet(DutFullName) /]
  switch -exact -- $gaSet(dutFam.ps) {
    12V {set ps WDC-12V}
    48V {set ps DC-48V}
    WDC {set ps WDC-20-60V}
  }
  set gaSet(eeprom.ps) $ps
  
  switch -exact -- $gaSet(dutFam.serPort) {
    0    {set ser1 "";    set ser2 "";    set ser1cts "";  set ser2cts "";  set 1rs485 ""; set 2rs485 ""}
    2RS  {set ser1 "RS232"; set ser2 "RS232"; set ser1cts "YES"; set ser2cts "YES"; set 1rs485 ""; set 2rs485 ""}
    2RSM {set ser1 "RS232"; set ser2 "RS485"; set ser1cts "YES"; set ser2cts "";  set 1rs485 ""; set 2rs485 "2W"}
  }
  set gaSet(eeprom.ser1) $ser1
  set gaSet(eeprom.ser2) $ser2
  set gaSet(eeprom.1rs485) $1rs485
  set gaSet(eeprom.2rs485) $2rs485
  
  switch -exact -- $gaSet(dutFam.poe) {
    0   {set poe "NO"}
    2PA   {set poe "2PA"}
    POE   {set poe "POE"}
  }
  set gaSet(eeprom.poe) $poe
  
  if {$mode=="newUut"} {
    set txt ""
    append txt MODEM_1_MANUFACTURER=${gaSet(eeprom.mod1man)},
    append txt MODEM_2_MANUFACTURER=${gaSet(eeprom.mod2man)},
    append txt MODEM_1_TYPE=${gaSet(eeprom.mod1type)},
    append txt MODEM_2_TYPE=${gaSet(eeprom.mod2type)},
    append txt MAC_ADDRESS=${mac},
    append txt MAIN_CARD_HW_VERSION=${gaSet(mainHW)},
    append txt SUB_CARD_1_HW_VERSION=${gaSet(sub1HW)},
    append txt CSL=${gaSet(csl)},
    append txt PART_NUMBER=${partNum},
    append txt PCB_MAIN_ID=${gaSet(mainPcbId)},
    append txt PCB_SUB_CARD_1_ID=${gaSet(sub1PcbId)},
    append txt PS=${ps},
    append txt SD-SLOT=YES,
    append txt SERIAL-1=${ser1},
    append txt SERIAL-2=${ser2},
    append txt SERIAL-1-CTS-RTS=${ser1cts},
    append txt SERIAL-2-CTS-RTS=${ser2cts},
    append txt RS485-1=${1rs485},
    append txt RS485-2=${2rs485},
    append txt POE=${poe},
    append txt DRY-CONTACT=YES,
    append txt USB-A=YES,
    append txt M.2-2=,
    append txt LIST_REF=0.0,
    append txt SER_NUM=,
    append txt END=
    
    AddToPairLog $gaSet(pair) "$txt"  
    
    set fil c:/download/sf1v/eeprom.cnt
    if [file exists $fil] {
      file copy -force $fil c:/temp/[clock format  [clock seconds] -format  "%Y.%m.%d-%H.%M.%S"].eeprom.txt
      catch {file delete -force $fil}
      after 500
    }
    set id [open $fil w]
      puts $id $txt
    close $id
  }
  
  return 0
} 

# ***************************************************************************
# ModMan
# ***************************************************************************
proc ModMan {cell} {
  switch -exact -- [string range $cell 1 end] {
    HSP - L1 - L2 - L3 - L4 {return QUECTEL}
    wifi                    {return AZUREWAVE}
    lora                    {return RAK}
  }
}  
# ***************************************************************************
# ModType
# ***************************************************************************
proc ModType {cell} {
  switch -exact -- [string range $cell 1 end] {
    HSP  {return UC20}
    L1   {return EC25-E}
    L2   {return EC25-A}
    L3   {return EC25-AU}
    L4   {return EC25-AFFD}
    wifi {return AW-CM276MA}
    lora {return RAK-2247}
  }
}                            
# ***************************************************************************
# DownloadConfFile
# ***************************************************************************
proc DownloadConfFile {cf cfTxt save com} {
  global gaSet  buffer
  puts "[MyTime] DownloadConfFile $cf \"$cfTxt\" $save $com"
  #set com $gaSet(comDut)
  if ![file exists $cf] {
    set gaSet(fail) "The $cfTxt configuration file ($cf) doesn't exist"
    return -1
  }
  Status "Download Configuration File $cf" ; update
  set s1 [clock seconds]
  set id [open $cf r]
  set c 0
  while {[gets $id line]>=0} {
    if {$gaSet(act)==0} {close $id ; return -2}
    if {[string length $line]>2 && [string index $line 0]!="#"} {
      incr c
      puts "line:<$line>"
      if {[string match {*address*} $line] && [llength $line]==2} {
        if {[string match *DefaultConf* $cfTxt] || [string match *RTR* $cfTxt]} {
          ## don't change address in DefaultConf
        } else {
          ##  address 10.10.10.12/24
          if {$gaSet(pair)==5} {
            set dutIp 10.10.10.1[set ::pair]
          } else {
            if {$gaSet(pair)=="SE"} {
              set dutIp 10.10.10.111
            } else {
              set dutIp 10.10.10.10[set gaSet(pair)]
            }  
          }
          #set dutIp 10.10.10.1[set gaSet(pair)]
          set address [set dutIp]/[lindex [split [lindex $line 1] /] 1]
          set line "address $address"
        }
      }
      if {[string match *EccXT* $cfTxt] || [string match *vvDefaultConf* $cfTxt] || [string match *aAux* $cfTxt]} {
        ## perform the configuration fast (without expected)
        set ret 0
        set buffer bbb
        ##RLSerial::Send $com "$line\r" 
        RLCom::Send $com "$line\r" 
      } else {
        if {[string match *Aux* $cfTxt]} {
          set gaSet(prompt) 205A
        } else {
          set waitFor 2I
        }
        if {[string match {*conf system name*} $line]} {
          set gaSet(prompt) [lindex $line end]
        }
        if {[string match *CUST-LAB-ETX203PLA-1* $line]} {
          set gaSet(prompt) "CUST-LAB-ETX203PLA-1"
        }
        if {[string match *WallGarden_TYPE-5* $line]} {
          set gaSet(prompt) "WallGarden_TYPE-5"          
        }
        if {[string match *BOOTSTRAP-2I10G* $line]} {
          set gaSet(prompt) "BOOTSTRAP-2I10G"          
        }
        set ret [Send $com $line\r $gaSet(prompt) 60]
#         Send $com "$line\r"
#         set ret [MyWaitFor $com {205A 2I ztp} 0.25 60]
      }  
      if {$ret!=0} {
        set gaSet(fail) "Config of DUT failed"
        break
      }
      if {[string match {*cli error*} [string tolower $buffer]]==1} {
        if {[string match {*range overlaps with previous defined*} [string tolower $buffer]]==1} {
          ## skip the error
        } else {
          set gaSet(fail) "CLI Error"
          set ret -1
          break
        }
      }            
    }
  }
  close $id  
  if {$ret==0} {
    if {$com==$gaSet(comAux1) || $com==$gaSet(comAux2)} {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
    } else {
      set ret [Send $com "exit all\r" $gaSet(prompt)]
#       Send $com "exit all\r" 
#       set ret [MyWaitFor $com {205A 2I ztp} 0.25 8]
    }
    if {$save==1} {
      set ret [Send $com "admin save\r" "successfull" 80]
      if {$ret=="-1"} {
        set ret [Send $com "admin save\r" "successfull" 80]
      }
    }
     
    set s2 [clock seconds]
    puts "[expr {$s2-$s1}] sec c:$c" ; update
  }
  Status ""
  puts "[MyTime] Finish DownloadConfFile" ; update
  return $ret 
}
# ***************************************************************************
# Ping
# ***************************************************************************
proc Ping {dutIp} {
  global gaSet
  puts "[MyTime] Pings to $dutIp" ; update
  set i 0
  while {$i<=4} {
    if {$gaSet(act)==0} {return -2}
    incr i
    #------
    catch {exec arp.exe -d}  ;#clear pc arp table
    catch {exec ping.exe $dutIp -n 2} buffer
    if {[info exist buffer]!=1} {
	    set buffer "?"  
    }  
    set ret [regexp {Packets: Sent = 2, Received = 2, Lost = 0 \(0% loss\)} $buffer var]
    puts "ping i:$i ret:$ret buffer:<$buffer>"  ; update
    if {$ret==1} {break}    
    #------
    after 500
  }
  
  if {$ret!=1} {
    puts $buffer ; update
	  set gaSet(fail) "Ping fail"
 	  return -1  
  }
  return 0
}
# ***************************************************************************
# GetMac   A47acf010028
# ***************************************************************************
proc GetMac {qty} {
  global gaSet buffer gaDBox
  puts "[MyTime] GetMac" ; update
  set ret [Login2Uboot]
  if {$ret!=0} {return $ret}
  set com $gaSet(comDut)
  set ret [Send $com "iic r 52 200 500\r" "SF1V=>"]  
  if {$ret!=0} {return $ret} 
  
  foreach iv [split $buffer " "] {
    if {[string length $iv]==2} {lappend hexs $iv}
  }
  #set hexsStr [join $hexs " "]

  ## 53 53 3d -> SS=
  ## 2C 4d 41 -> ,MA
  set res [regexp -all {53 53 3d ([\w\s]+) 2c 4d 41} $hexs ma val]
  if {$res!=0} {
    foreach i $val {
      append macLink [format %c 0x$i]
    }
    set dutMac [string toupper [join [split $macLink :] ""]]
    set hexDutMac 0x$dutMac
    puts "GetMac macLink:<$macLink> dutMac:<$dutMac> hexDutMac:<$hexDutMac>"
    #set macLink $gaSet(1.barcode1.IdMacLink)
    #puts "macLink:<$macLink>"
    if {[string match *VB-101V* $gaSet(dutFam.sf)]} {
      set firstMac 0xA47ACF000000
      set lastMac  0xA47ACFFFFFFF
      if {$hexDutMac>=$firstMac && $hexDutMac<=$lastMac} {
        return $dutMac
      } else {
        while 1 {
          update
          set ret [DialogBox -title "Get VB MAC" -text "Enter the VB MAC" -ent1focus 1\
            -type "Ok Cancel" -entQty 1 -entLab "A47ACFxxxxxx" -entPerRow 1 -icon /images/info]
          #puts "ret:<$ret>" 
        	if {$ret == "Cancel" } {
        	  return -2 
        	} elseif {$ret=="Ok"} {
            parray gaDBox
            foreach {ent1} [lsort -dict [array names gaDBox entVal*]] {
              set dutMac [string trim [string toupper $gaDBox($ent1)]] 
            } 
            set dutMac [string toupper $dutMac]
            set hexDutMac 0x$dutMac  
            if {$hexDutMac>=$firstMac && $hexDutMac<=0xA47ACFFFFFFF} {
              break
            }
          }
        }
      }  
    } else {
      set firstMac 0x1806F5000000
      set lastMac  0x1806F5FFFFFF
      puts "MyTime] GetMac firstMac: $firstMac lastMac: $lastMac hexDutMac: $hexDutMac"
      if {$hexDutMac<$firstMac || $hexDutMac>$lastMac} {
        puts "[MyTime] GetMac $hexDutMac out of RAD range. Set dutMac to -"
        set dutMac -
      }
    }
  } else {
    if {[regexp -all ff $hexs]>400} {
      puts "[MyTime] GetMac Empty EEPROM"
      set dutMac "EmptyEprom"
    } else {
      set gaSet(fail) "Read EEPROM fail"
      return -1
    }
  }
  puts "[MyTime] GetMac dutMac:<$dutMac> xdigit $dutMac:[string is xdigit $dutMac]"     
  if {[string is xdigit $dutMac]} {
    return $dutMac
  } else {
    puts "[MyTime] GetMac MACServer.exe" 
    set macFile c:/temp/mac.txt
    exec $::RadAppsPath/MACServer.exe 0 $qty $macFile 1
    set ret [catch {open $macFile r} id]
    if {$ret!=0} {
      set gaSet(fail) "Open Mac File fail"
      return -1
    }
    set buffer [read $id]
    close $id
    file delete $macFile
    set ret [regexp -all {ERROR} $buffer]
    if {$ret!=0} {
      set gaSet(fail) "MACServer ERROR"
      return -1
    }
    set mac [lindex $buffer 0]  ; # 1806F5F4763B
    puts "[MyTime] GetMac MACServer.exe -> $mac" 
 
#  19/04/2021 15:40:56
#     if 1 {
#       set cmd "0x[string range $mac 6 end]-[expr $qty - 1]" ; ## 0xF4763B - 5 
#       set theLowerMac [string range $mac 0 5][format %X [expr $cmd]] ; ## 1806F5F47636
#       set mac $theLowerMac
#     }
    
    return $mac
  }  
}
# ***************************************************************************
# SplitString2Paires
# ***************************************************************************
proc SplitString2Paires {str} {
  foreach {f s} [split $str ""] {
    lappend l [set f][set s]
  }
  return $l
}

# ***************************************************************************
# GetDbrSW
# ***************************************************************************
proc GetDbrSW {barcode} {
  global gaSet gaGui
  set gaSet(dbrSW) ""
  if {![file exist $gaSet(javaLocation)]} {
    set gaSet(fail) "Java application is missing"
    return -1
  }
  
  catch {exec $gaSet(javaLocation)\\java -jar $::RadAppsPath/SWVersions4IDnumber.jar $barcode} b
  puts "GetDbrSW b:<$b>" ; update
  after 1000
  if ![info exists gaSet(dbrUbootSWnum)] {
    set gaSet(dbrUbootSWnum) ""
  }
  set dbrUbootSWnumIndx [lsearch $b $gaSet(dbrUbootSWnum)]  
  if {$dbrUbootSWnumIndx<0} {
    set gaSet(fail) "There is no Uboot for $gaSet(dbrUbootSWnum) ID:$barcode. Verify the Barcode."
    RLSound::Play fail
	  Status "Test FAIL"  red
    DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
    pack $gaGui(frFailStatus)  -anchor w
	  $gaSet(runTime) configure -text ""
  	return -1
  }
  set dbrUbootSWver [string trim [lindex $b [expr {1+$dbrUbootSWnumIndx}]]]
  puts dbrUbootSWver:<$dbrUbootSWver>
  set gaSet(dbrUbootSWver) $dbrUbootSWver
  
  if {$gaSet(uutSWfrom)=="fromDbr"} {
    set dbrSWnumIndx [lsearch $b $gaSet(dbrSWnum)]  
    if {$dbrSWnumIndx<0} {
      set gaSet(fail) "There is no SW for $gaSet(dbrSWnum) ID:$barcode. Verify the Barcode."
      RLSound::Play fail
  	  Status "Test FAIL"  red
      DialogBox -aspect 2000 -type Ok -message $gaSet(fail) -icon images/error
      pack $gaGui(frFailStatus)  -anchor w
  	  $gaSet(runTime) configure -text ""
    	return -1
    }
    set SWver [string trim [lindex $b [expr {1+$dbrSWnumIndx}]]]
    puts SWver:<$SWver>
    set gaSet(SWver) $SWver
  } elseif {$gaSet(uutSWfrom)=="manual"} {
    puts SWver:<$gaSet(SWver)>
  }
  update
  
  pack forget $gaGui(frFailStatus)
  
  set swTxt [glob SW*_$barcode.txt]
  catch {file delete -force $swTxt}
  
  Status ""
  update
  BuildTests
  focus -force $gaGui(tbrun)
  return 0
}
# ***************************************************************************
# GuiMuxMngIO
# ***************************************************************************
proc GuiMuxMngIO {mngMode} {
  global gaSet descript
  set channel [RetriveUsbChannel]   
  RLEH::Open
  set gaSet(idMuxMngIO) [RLUsbMmux::Open 1 $channel]
  MuxMngIO $mngMode
  RLUsbMmux::Close $gaSet(idMuxMngIO) 
  RLEH::Close
}
# ***************************************************************************
# MuxMngIO
##     MuxMngIO 2ToPc
# ***************************************************************************
proc MuxMngIO {mngMode} {
  global gaSet
  puts "MuxMngIO $mngMode"
  RLUsbMmux::AllNC $gaSet(idMuxMngIO)
  after 1000
  RLUsbMmux::BusState $gaSet(idMuxMngIO) "A,B C D"
  switch -exact -- $mngMode {
    1ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 1,14
    }
    2ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 2,14
    }
    3ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 3,14
    }
    4ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 4,14
    }
    5ToPc {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 5,14
    }
    1ToPhone {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 1,13
    }
    2ToPhone {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 2,13
    }
    3ToPhone {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 3,13
    }
    4ToPhone {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 4,13
    }
    5ToPhone {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 5,13
    }
    1ToAirMux {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 1,12
    }
    2ToAirMux {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 2,12
    }
    3ToAirMux {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 3,12
    }
    4ToAirMux {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 4,12
    }
    5ToAirMux {
      RLUsbMmux::ChsCon $gaSet(idMuxMngIO) 5,12
    }
    nc {
      ## do nothing, already disconected
    }
  }  
}


# ***************************************************************************
# wsplit
# ***************************************************************************
proc wsplit {str sep} {
  split [string map [list $sep \0] $str] \0
}
# ***************************************************************************
# LoadBootErrorsFile
# ***************************************************************************
proc LoadBootErrorsFile {} {
  global gaSet
  set gaSet(bootErrorsL) [list] 
  if ![file exists bootErrors.txt]  {
    return {}
  }
  
  set id [open  bootErrors.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet(bootErrorsL) $line
      }
    }

  close $id
  
#   foreach ber $bootErrorsL {
#     if [string length $ber] {
#      lappend gaSet(bootErrorsL) $ber
#    }
#   }
  return {}
}
# ***************************************************************************
# OpenTeraTerm
# ***************************************************************************
proc OpenTeraTerm {comName} {
  global gaSet
  set path1 C:\\Program\ Files\\teraterm\\ttermpro.exe
  set path2 C:\\Program\ Files\ \(x86\)\\teraterm\\ttermpro.exe
  set path3 C:\\teraterm\\ttermpro.exe
  set path  NA
  foreach pathX [list $path1 $path2 $path3]  {
    if [file exist $pathX] {
      set path $pathX
      break
    }
  }
  if {$path=="NA"} {
    tk_messageBox -type ok -message "no teraterm installed"
    return {}
  }
  if {[string match *Dut* $comName] } {
    set baud 115200
  } else {
    set baud 9600
  }
  regexp {com(\w+)} $comName ma val
  set val Tester-$gaSet(pair).[string toupper $val]
  exec $path /c=[set $comName] /baud=$baud /W="$val" &
  return {}
}  
# *********

# ***************************************************************************
# UpdateInitsToTesters
# ***************************************************************************
proc UpdateInitsToTesters {} {
  global gaSet
  set sdl [list]
  set unUpdatedHostsL [list]
  set hostsL [list at-secfl1v-1-10 soldlogsrv1-10 at-secfl1v-2-10 at-secfl1v-3-10]
  set initsPath AT-SF-1V/software/uutInits
  #set usDefPath AT-SF-1V/ConfFiles/DEFAULT
  
  set s1 c:/$initsPath
  #set s2 c:/$usDefPath
  foreach host $hostsL {
    if {$host!=[info host]} {
      set dest //$host/c$/$initsPath
      if [file exists $dest] {
        lappend sdl $s1 $dest
      } else {
        lappend unUpdatedHostsL $host        
      }
      
      #set dest //$host/c$/$usDefPath
      #if [file exists $dest] {
      #  lappend sdl $s2 $dest
      #} else {
      #  lappend unUpdatedHostsL $host        
      #}
    }
  }
  
  set msg ""
  set unUpdatedHostsL [lsort -unique $unUpdatedHostsL]
  if {$unUpdatedHostsL!=""} {
    append msg "The following PCs are not reachable:\n"
    foreach h $unUpdatedHostsL {
      append msg "$h\n"
    }  
    append msg \n
  }
  if {$sdl!=""} {
    if {$gaSet(radNet)} {
      set emailL {ilya_g@rad.com}
    } else {
      set emailL [list]
    }
    set ret [RLAutoUpdate::AutoUpdate $sdl]
    set updFileL    [lsort -unique $RLAutoUpdate::updFileL]
    set newestFileL [lsort -unique $RLAutoUpdate::newestFileL]
    if {$ret==0} {
      if {$updFileL==""} {
        ## no files to update
        append msg "All files are equal, no update is needed"
      } else {
        append msg "Update is done"
        if {[llength $emailL]>0} {
          RLAutoUpdate::SendMail $emailL $updFileL "file://R:\\IlyaG\\SF-1V"
          if ![file exists R:/IlyaG/SF-1V] {
            file mkdir R:/IlyaG/SF-1V
          }
          foreach fi $updFileL {
            catch {file copy -force $s1/$fi R:/IlyaG/SF-1V } res
            puts $res
            catch {file copy -force $s2/$fi R:/IlyaG/SF-1V } res
            puts $res
          }
        }
      }
      tk_messageBox -message $msg -type ok -icon info -title "Tester update" ; #DialogBox icon /images/info
    }
  } else {
    tk_messageBox -message $msg -type ok -icon info -title "Tester update"
  } 
}

# ***************************************************************************
# ReadCom
# ***************************************************************************
proc ReadCom {com inStr {timeout 10}} {
  global buffer buff gaSet
  set buffer ""
  $gaSet(runTime) configure -text ""
  set secStart [clock seconds]
  set secNow [clock seconds]
  set secRun [expr {$secNow-$secStart}]
  while {1} {
    
    set ret [RLCom::Read $com buff]
    append buffer $buff
    puts "Read from Com-$com $secRun buff:<$buff>" ; update
    if {$ret!=0} {break}
    if {[string match "*$inStr*" $buffer]} {
      set ret 0
      break
    }
    
    after 1000
    set secNow [clock seconds]
    set secRun [expr {$secNow-$secStart}]
    $gaSet(runTime) configure -text "$secRun" ; update
    if {$secRun > $timeout} {
      set ret -1
      break
    }
  }
  return $ret
}

# ***************************************************************************
# SameContent
# ***************************************************************************
proc SameContent {file1 file2} {
  puts "SameContent $file1 $file2" ; update
  set f1 [open $file1]
  fconfigure $f1 -translation binary
  set f2 [open $file2]
  fconfigure $f2 -translation binary
  while {![info exist same]} {
      if {[read $f1 4096] ne [read $f2 4096]} {
          set same 0
      } elseif {[eof $f1]} {
          # The same if we got to EOF at the same time
          set same [eof $f2]
      } elseif {[eof $f2]} {
          set same 0
      }
  }
  close $f1
  close $f2
  return $same
}

# ***************************************************************************
# LoadModem
# ***************************************************************************
proc LoadModem {mdm} {
  global gaSet
  set mdm [string toupper $mdm]
  puts "[MyTime] LoadModem $mdm"
  if ![file exists $mdm.txt]  {
    return -1
  }
  
  set gaSet($mdm.fwL) [list]
  set id [open $mdm.txt r]
    while {[gets $id line] >= 0} {
      set line [string trim $line]
      if {[string length $line] != 0} {
        lappend gaSet($mdm.fwL) $line
      }
    }
  close $id
  
  return 0
}

# ***************************************************************************
# LoadModemFiles
# ***************************************************************************
proc LoadModemFiles {} {
  foreach mdm [list HSP L1 L2 L3 L4] {
    set ret [LoadModem $mdm]
    if {$ret!=0} {return $ret}
  }  
}

# ***************************************************************************
# FtpVerifyNoReport
# ***************************************************************************
proc FtpVerifyNoReport {} {
  global gaSet
  Status "Waiting for report file delete"
  set startSec [clock seconds]
  while 1 {
    #set res [FtpFileExist [string tolower  wifireport_$gaSet(wifiNet).txt]]
    catch {exec python.exe lib_sftp.py FtpFileExist wifireport_$gaSet(wifiNet).txt} res
    regexp {result: (-?1) } $res ma res
    puts "FtpFileExist res <$res>"
    set runDur [expr {[clock seconds] - $startSec}]
    puts "FtpVerifyNoReport runDur:<$runDur> res:<$res>"
    if {$runDur > 120} {
      set gaSet(fail) "wilireport_$gaSet(wifiNet).txt still exists on the ftp"
      return -1 
    }
    if {$res=="-1"} {
      break
    }
    after 10000
  }
  return 0
}
# ***************************************************************************
# FtpVerifyReportExists
# ***************************************************************************
proc FtpVerifyReportExists {} {
  global gaSet
  Status "Waiting for report file create"
  set startSec [clock seconds]
  while 1 {
    #set res [FtpFileExist  [string tolower wifireport_$gaSet(wifiNet).txt]]
    catch {exec python.exe lib_sftp.py FtpFileExist wifireport_$gaSet(wifiNet).txt} res
    regexp {result: (-?1) } $res ma res
    puts "FtpFileExist res <$res>"    
    set runDur [expr {[clock seconds] - $startSec}]
    puts "FtpVerifyReportExists runDur:<$runDur> res:<$res>"
    if {$runDur > 120} {
      set gaSet(fail) "wilireport_$gaSet(wifiNet).txt still doesn't exist on the ftp"
      return -1 
    }
    if {$res=="1"} {
      break
    }
    after 10000
  }
  return 0  
}

proc StripHtmlTags { htmlText } {
  regsub -all {<[^>]+>} $htmlText "_" newText
  return $newText
}

# ***************************************************************************
# ReadCookies
# ***************************************************************************
proc ReadCookies {} {
  global cookies state
  set cook$gaSet(pair)ies [list]
  foreach {name value} $state(meta) {
    if { $name eq "Set-Cookie" } {
      lappend cookies [lindex [split $value {;}] 0]
    }
  }
} 



proc fff {} {
  router interface create address-prefix 10.10.10.20/24 physical-interface eth2  purpose application-host
  
  gnss update admin-status enable
  
  router nat static create protocol tcp  original-port 4443  modified-ip 10.0.3.70  modified-port 8443
  
  lxd update admin-status enable
  
}
proc inex {} {
  package require tcom
  set ie [tcom::ref createobject InternetExplorer.Application]
  $ie Visible True
  ##$ie GoHome
  $ie Navigate "https://10.10.10.20:4443/login"
  while {[$ie Busy]} {
   puts -nonewline .
   update
   after 100
 }
 
  set loc [$ie LocationURL]
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [$doc body]
  set inn [$body innerHTML]
  #join [[::tcom::info interface $ie] methods] \n
  #join [[::tcom::info interface $body] methods] \n
  
  set inputs [ $body getElementsByTagName "*" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "overridelink" ] == 0 } {
        $input focus
        after 250
        $input click
        break
      }
    }
    incr index    
  }
  
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [$doc body]
  
  set inputs [ $body getElementsByTagName "input" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "username" ] == 0 } {
        $input focus
        $input value "admin"
        while { [ $doc readyState ] != "complete" } {
          after 250
        }
      }
      if { [ string compare $name "password" ] == 0 } {
        $input focus
        $input value "admin"
        while { [ $doc readyState ] != "complete" } {
          after 250
        }
      }
    }
    incr index    
  }
  
}

proc vvv {} {
  package require twapi
  set ie [ twapi::comobj InternetExplorer.Application ]
  $ie Visible 0
  set szUrl "https://10.10.10.20:4443/login"
  $ie Navigate $szUrl
  $ie Visible 1
  set w [ $ie HWND ]
  set wIE [ list $w HWND ]
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [ $doc body ]
  
  
  set inputs [ $body getElementsByTagName "*" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
      puts "$index"
    } else {
      puts "input:<$input> name:<$name>"
    }
    incr index
  }
  
  set index 0    
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "overridelink" ] == 0 } {
        $input focus
        after 250
        $input click
        break
      }
    }
    incr index    
  }
  
  $ie Navigate $szUrl
  while { [ $ie Busy ] } {
    puts -nonewline "."
    flush stdout
    after 250
  }
  set doc [ $ie Document ]
  while { [ $doc readyState ] != "complete" } {
    after 250
  }
  set body [ $doc body ]
  
  set inputs [ $body getElementsByTagName "input" ]
  set length [ $inputs length ]
  set index 0
  while { $index < $length } {
    set input [ $inputs item $index ]
    if [catch { $input name } name] {
    
    } else {
      puts "input:<$input> name:<$name>"
      if { [ string compare $name "username" ] == 0 } {
        $input value "admin"
        $input focus
      }
      if { [ string compare $name "password" ] == 0 } {
        $input value "admin"
        $input focus
      }
      
    }
    incr index    
  }
  
  set inputs [ $body getElementsByClassName "login-form" ]

}
## https://wiki.tcl-lang.org/page/IE+Automation+With+TWAPI
# ***************************************************************************
# PcNum
# ***************************************************************************
proc PcNum {} {
  global gaSet
  return [expr {[string range $gaSet(hostDescription) end-1 end]}]
} 
# ***************************************************************************
# procUutNum
# ***************************************************************************
proc UutNum {} {
  global gaSet
  return $gaSet(pair)
} 

## RetriveIdTraceData DF100148093 CSLByBarcode
## RetriveIdTraceData DF100148093 MKTItem4Barcode
## RetriveIdTraceData 21181408    PCBTraceabilityIDData
## RetriveIdTraceData TO300315253 OperationItem4Barcode
# ***************************************************************************
# RetriveIdTaceData
# ***************************************************************************
proc RetriveIdTraceData {args} {
  global gaSet
  set gaSet(fail) ""
  puts "RetriveIdTraceData $args"
  set barc [format %.11s [lindex $args 0]]
  
  set command [lindex $args 1]
  switch -exact -- $command {
    CSLByBarcode          {set barcode $barc  ; set traceabilityID null}
    PCBTraceabilityIDData {set barcode null   ; set traceabilityID $barc}
    MKTItem4Barcode       {set barcode $barc  ; set traceabilityID null}
    OperationItem4Barcode {set barcode $barc  ; set traceabilityID null}
    default {set gaSet(fail) "Wrong command: \'$command\'"; return -1}
  }
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param [set command]\?barcode=[set barcode]\&traceabilityID=[set traceabilityID]
  append url $param
  puts "url:<$url>"
  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set gaSet(fail) "http::status: <$st> http::ncode: <$nc>"; return -1
  }
  upvar #0 $tok state
  #parray state
  #puts "$state(body)"
  set body $state(body)
  ::http::cleanup $tok
  
  set re {[{}\[\]\,\t\:\"]}
  set tt [regsub -all $re $body " "]
  set ret [regsub -all {\s+}  $tt " "]
  
  return [lindex $ret end]
}

