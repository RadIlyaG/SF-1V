# ***************************************************************************
# SQliteOpen
# ***************************************************************************
proc SQliteOpen {} {
  global gaSet
  puts "[MyTime] SQliteOpen" ; update 
  if {$gaSet(radNet)} {  
    set dbFile \\\\prod-svm1\\tds\\temp\\SQLiteDB\\JerAteStats.db
    if ![file exists $dbFile] {
      set gaSet(fail) "No DataBase file or it's not reachable"
      return -1
    }
    sqlite3 gaSet(dataBase) $dbFile 
    gaSet(dataBase) timeout 5000
    
    set res [gaSet(dataBase) eval {SELECT name FROM sqlite_master WHERE type='table' AND name='tbl'}]
    if {$res==""} {
      gaSet(dataBase) eval {CREATE TABLE tbl(Barcode, UutName, HostDescription, Date, Time, Status, FailTestsList, FailDescription, DealtByServer)}
    }
    puts "[MyTime] DataBase is open well!"  
  } else {
    puts "[MyTime] DataBase is not open - out of RadNet"
    return -1
  }  
  return 0
}
# ***************************************************************************
# SQliteClose
# ***************************************************************************
proc SQliteClose {} {
  global gaSet
  puts "[MyTime] SQliteClose" ; update
  catch {gaSet(dataBase) close}
}
# ***************************************************************************
# SQliteAddLine
# ***************************************************************************
proc SQliteAddLine {} {
  global gaSet
  if [info exist gaSet(1.barcode1)] {
    set barcode $gaSet(1.barcode1)
  } else {
    puts "no barcode"
    return -1
  }
  
  puts "SQliteAddLine $barcode"
  if $::NoATP {
    puts "[MyTime] NoAtp-NoTCC"
    return 0
  }
  if {[string match *skip* $barcode]} {
    ## do not include skipped in stats
    return 0
  }
  if {$gaSet(1.barcode1.IdMacLink)!="noLink"} {
    puts "do not report about passed unit"
    # 10:47 04/10/2023 return 0
  }
  set uut $gaSet(DutFullName)
  set hostDescription $gaSet(hostDescription)
  
  set stopTime [clock seconds]
  if ![info exist gaSet(ButRunTime)] {
    set gaSet(ButRunTime) [expr {$stopTime - 600}]
  }
  foreach {date tim} [split [clock format $stopTime -format "%Y.%m.%d %H:%M:%S"] " "] {break}  
  #foreach {date tim} [split [clock format [clock seconds] -format "%Y.%m.%d %H.%M.%S"] " "] {break}
  set status $gaSet(runStatus)
  if {$status=="Pass"} {
    set failTestsList ""
    set failReason ""
  } else {
    set failTestsList [lindex [split $gaSet(curTest) ..] end]
    set failReason $gaSet(fail)
  } 
  
  if [info exists gaSet(operator)] {
    set operator $gaSet(operator) 
  } else {
    set operator 0
  }
  
  set traceId ""
  foreach {ret resTxt} [::RLWS::Get_TraceId $barcode] {}
  if {$ret==0} {
    set traceId $resTxt
  }
  
  set po_num ""
  if {$traceId!=""} {
    foreach {ret resTxt} [::RLWS::Get_PcbTraceIdData $traceId {"po number"} ] {}
    if {$ret==0} {
      set po_num $resTxt
    }
  }  
    
  for {set tr 1} {$tr <= 6} {incr tr} {
    #if [catch {UpdateDB $barcode $uut $hostDescription $date $tim-$gaSet(ButRunTime) $status $failTestsList $failReason $operator} res] { }
    foreach {ret resTxt} [::RLWS::UpdateDB2  $barcode $uut $hostDescription \
            $date $tim-$gaSet(ButRunTime) $status $failTestsList $failReason $operator\
            $traceId $po_num [info host] "" ""] {}
    if {$ret!=0} {
      set res "Try${tr}_fail.$resTxt"
      puts "[MyTime] Web DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
      after [expr {int(rand()*3000+60)}] 
    } else {
      puts "[MyTime] Web DataBase is updated well!"
      set res "Try $tr passed"
      break
    }
  }
  
#     06/01/2021 08:20:51
#     set ret [SQliteOpen]
#     if {$ret!=0} {return $ret}
#     
#     for {set tr 1} {$tr <= 6} {incr tr} {
#       if [catch {gaSet(dataBase) eval {INSERT INTO tbl VALUES($barcode,$uut,$hostDescription,$date,$tim,$status,$failTestsList,$failReason,$operator)}} res] {
#         set res "Try${tr}_fail.$res"
#         puts "[MyTime] DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
#         after [expr {int(rand()*3000+60)}] 
#       } else {
#         puts "[MyTime] DataBase is updated well!"
#         set res "Try $tr passed"
#         break
#       }
#     }
#     SQliteClose
  

  set id [open c:/logs/logsStatus.txt a+]
    puts $id "$barcode,$uut,$hostDescription,$date,$tim,$status,$failTestsList,$failReason,$operator  res:<$res>"
  close $id  
  
  if ![string match *passed* $res] {
    if [catch {open //prod-svm1/tds/temp/DbLocked/[regsub \/ $hostDescription .]_$gaSet(pair).txt a+} id] {
      puts "[MyTime] $id"
    } else {
      puts $id "$barcode,$uut,$hostDescription,$date,$tim,$status,$failTestsList,$failReason,$operator  res:<$res>"   
      close $id
    }
  }
  
  return 0
}
# ***************************************************************************
# AddLine
# ***************************************************************************
proc AddLine {} {
  global gaSet
  set gaSet(radNet) 1
  set barcode DE1005790454
  set gaSet(1.barcode1.IdMacLink) "noLink"
  set uut IlyaGinzburg
  set hostDescription $gaSet(hostDescription)
  set status Pass
  set gaSet(pair) wert
  set failTestsList sdfsdf
  set failReason sadas
  foreach {date tim} [split [clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"] " "] {break}
  set operator "ILYA GINZBURG"
  
  for {set tr 1} {$tr <= 6} {incr tr} {
    if [catch {UpdateDB $barcode $uut $hostDescription $date $tim $status $failTestsList $failReason $operator} res] {
      set res "Try${tr}_fail.$res"
      puts "[MyTime] Web DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
      after [expr {int(rand()*3000+60)}] 
    } else {
      puts "[MyTime] Web DataBase is updated well!"
      set res "Try $tr passed"
      break
    }
  }
  
  if ![string match *passed* $res] {
    if [catch {open //prod-svm1/tds/temp/DbLocked/[regsub \/ $hostDescription .]_$gaSet(pair).txt a+} id] {
      puts "[MyTime] $id"
    } else {
      puts $id "$barcode,$uut,$hostDescription,$date,$tim,$status,$failTestsList,$failReason,0  res:<$res>"   
      close $id
    }
  }
}
# ***************************************************************************
# MyTime
# ***************************************************************************
proc MyTime {} {
  return [clock format [clock seconds] -format "%T   %d/%m/%Y"]
}
# ***************************************************************************
# LockedDBtoDB
# ***************************************************************************
proc LockedDBtoDB {} {
  set ret [SQliteOpen]
  if {$ret!=0} {return $ret}
  set  id   [open c:/logs/logsStatus.txt r]
  while {[gets $id line]>=0} {
    if [string match {*database is locked*} $line] {
      regexp {(.+)\s+res} $line ma dbLine
      set dbLine [string trim $dbLine]
      foreach {barcode uut hostDescription date tim status failTestsList failReason srv} [split $dbLine \,] {break}
      for {set tr 1} {$tr <= 3} {incr tr} {
        if [catch {gaSet(dataBase) eval {INSERT INTO tbl VALUES($barcode,$uut,$hostDescription,$date,$tim,$status,$failTestsList,$failReason,0)}} res] {
          set res "Try${tr}_fail.$res"
          puts "[MyTime] DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
          after [expr {int(rand()*3000+60)}] 
        } else {
          set res "Try $tr passed"
          break
        }
      }
    }  
  }
  close $id
  SQliteClose
  return 0
}
# ***************************************************************************
# ImeiSQliteOpen
# ***************************************************************************
proc ImeiSQliteOpen {} {
  global gaSet
  puts "[MyTime] ImeiSQliteOpen" ; update 
  if {$gaSet(radNet)} {  
    set dbFile \\\\prod-svm1\\tds\\temp\\SQLiteDB\\Imei.db
    if ![file exists $dbFile] {
      set gaSet(fail) "No Imei.db file or it's not reachable"
      return -1
    }
    sqlite3 gaSet(dataBaseImei) $dbFile 
    gaSet(dataBaseImei) timeout 5000
    
    set res [gaSet(dataBaseImei) eval {SELECT name FROM sqlite_master WHERE type='table' AND name='tbl'}]
    if {$res==""} {
      gaSet(dataBaseImei) eval {CREATE TABLE tbl(Barcode, RadName, AttName, DevId, Sw, Imei, Date, Time, HostDescription, Spare1, Spare2, Spare3, Spare4, Spare5, Spare6)}
    }
    puts "[MyTime] DataBase is open well!"  
  } else {
    puts "[MyTime] DataBase is not open - out of RadNet"
    return -1
  }  
  return 0
}
# ***************************************************************************
# ImeiSQliteAddLine
# ***************************************************************************
proc ImeiSQliteAddLine {} {
  global gaSet
  set Barcode $gaSet(1.barcode1)
  puts "ImeiSQliteAddLine Barcode:<$Barcode>"
  if {[string index $gaSet(dutFam.cell) 0] == 0 } {
    puts "ImeiSQliteAddLine. No Cellular"  
    return 0
  }
  
  set ret [RetriveIdTraceData $Barcode MKTItem4Barcode]
  puts "ImeiSQliteAddLine ret:<$ret>"
  if {$ret=="-1"} {
    return -1
  } else {
    set RadName [dict get $ret "MKT Item"]
  }
  
  # switch -exact -- $RadName {
    # SF-1V/E2/48V/4U1S/POE/2RS/L4/G/L4 {set AttName SecFlow-1v;                         set DevId BI001996}
    # SF-1V/E2/12v/4U1S/2RSM/L4/G/GO    {set AttName SF-1V/E2/12v/4U1S/2RSM/L4/G/GO;     set DevId BI006387}
    # SF-1P/E1/DC/4U2S/2RSM/L4/G/LRA/2R {set AttName SF-1P/E1/DC/4U2S/2RSM/L4/G/LRA/2R ; set DevId BI006054}
    # ETX-203AX-T/LTE/GE30/2SFP/3UTP/L4 {set AttName ETX-203AX-T;                        set DevId BI003495}
    # default                           {set AttName $RadName;                           set DevId -}
  # }
  # puts "ImeiSQliteAddLine AttName:<$AttName> DevId:<$DevId>"
  # if {$DevId=="-"} {
    # #return 0
  # }
  
  set Sw $gaSet(SWver)
  puts "ImeiSQliteAddLine Sw:<$Sw>"
  
  set cellQty [string index $gaSet(dutFam.cell) 0]
  if {$cellQty=="1"} {
    set Imei "$gaSet(1.imei1)"
  } elseif {$cellQty=="2"} {
    set Imei "${gaSet(1.imei1)}_$gaSet(1.imei2)"
  }
  puts "ImeiSQliteAddLine Imei:<$Imei>"
  
  set HostDescription $gaSet(hostDescription)
  puts "ImeiSQliteAddLine HostDescription:<$HostDescription>"
  
  set stopTime [clock seconds]
  foreach {date tim} [split [clock format $stopTime -format "%Y.%m.%d %H:%M:%S"] " "] {puts "ImeiSQliteAddLine date:<$date> tim:<$tim>"}  
  
  for {set sp 1} {$sp<=6} {incr sp} {
    set Spare$sp -
    puts "ImeiSQliteAddLine Spare$sp:<[set Spare$sp]>"
  }
  
  # for {set tr 1} {$tr <= 6} {incr tr} {
    # if [catch {UpdateDB $barcode $UutName $hostDescription $date $tim $status $failTestsList $failReason $operator} res] {
      # set res "Try${tr}_fail.$res"
      # puts "[MyTime] Web DataBase is not updated. Try:<$tr>. Res:<$res>" ; update
      # after [expr {int(rand()*3000+60)}] 
    # } else {
      # puts "[MyTime] Web DataBase is updated well!"
      # set res "Try $tr passed"
      # break
    # }
  # }
  
   
  
    set ret [ImeiSQliteOpen]
    if {$ret!=0} {return $ret}
    
    for {set tr 1} {$tr <= 6} {incr tr} {
      if [catch {gaSet(dataBaseImei) eval {INSERT INTO tbl VALUES($Barcode,$RadName,$Imei,$Sw,$date,$tim,$HostDescription,$Spare1,$Spare2,$Spare3,$Spare4,$Spare5,$Spare6)}} res] {
        set res "Try${tr}_fail.$res"
        puts "[MyTime] ImeiDataBase is not updated. Try:<$tr>. Res:<$res>" ; update
        after [expr {int(rand()*3000+60)}] 
      } else {
        puts "[MyTime] ImeiDataBase is updated well!"
        set res "Try $tr passed"
        break
      }
    }
    ImeiSQliteClose

  set id [open c:/logs/ImeilogsStatus.txt a+]
    puts $id "$Barcode,$RadName,$Imei,$Sw,$date,$tim,$HostDescription,$Spare1,$Spare2,$Spare3,$Spare4,$Spare5,$Spare6  res:<$res>"
  close $id  
  
  if ![string match *passed* $res] {
    if [catch {open //prod-svm1/tds/temp/DbLocked/Imei_[regsub \/ $hostDescription .]_$gaSet(pair).txt a+} id] {
      puts "[MyTime] $id"
    } else {
      puts $id "$Barcode,$RadName,$Imei,$Sw,$date,$tim,$HostDescription,$Spare1,$Spare2,$Spare3,$Spare4,$Spare5,$Spare6  res:<$res>"   
      close $id
    }
    set gaSet(fail) "Update IMEI DB fail"
    return -1
  } else {
    return 0
  }
}
# ***************************************************************************
# ImeiSQliteClose
# ***************************************************************************
proc ImeiSQliteClose {} {
  global gaSet
  puts "[MyTime] ImeiSQliteClose" ; update
  catch {gaSet(dataBaseImei) close}
}
