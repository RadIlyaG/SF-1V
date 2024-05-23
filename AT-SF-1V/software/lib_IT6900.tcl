# ***************************************************************************
# IT9600_normalVoltage
# ***************************************************************************
proc IT9600_normalVoltage {off on} {
  global buffer gaSet
  puts "\n[MyTime] IT9600_normalVoltage"; update
  set volt [Retrive_normalVoltage]
  puts "off:<$off> on:<$on> volt:<$volt>"; update
  if $off {
    set ret [IT6900_on_off script off]
  } else {
    set ret 0
  }

  if {$ret!="-1"} {
    set ret [IT6900_set script $volt]
  }  
  if {$ret!="-1"} {
    if $on {
      after 2000
      set ret [IT6900_on_off script on]
    } else {
      set ret 0
    }
    # after 2000
  }
  return $ret
}  
# ***************************************************************************
# Retrive_normalVoltage
# ***************************************************************************
proc Retrive_normalVoltage {} {
  global gaSet
  if {$gaSet(dutFam.ps)=="WDC"} {
    set volt 48
  } elseif {$gaSet(dutFam.ps)=="12V" || $gaSet(dutFam.ps)=="ACEX"} {
    set volt 24
  } elseif {$gaSet(dutFam.ps)=="DC"} {
    set volt 24
  }
  return $volt
}

# ***************************************************************************
# Gui_IT6900
# ***************************************************************************
proc Gui_IT6900 {} {
  global gaSet gaGui
  set base .topHwInit
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base $gaGui(xy)
  wm resizable $base 1 1
  wm protocol $base WM_DELETE_WINDOW {IT6900_quit}
  set addrL []
  set res_list [exec python.exe lib_IT6900.py get_list stam stam]
  foreach res $res_list {
    if [regexp {0x6900::(\d+)::INSTR} $res ma addr] {
      lappend addrL $addr     
    }
  }
  puts "addrL: $addrL"
  
  wm title $base "IT6900"
  set frA [TitleFrame $base.frA -text "PS's ID" -bd 2 -relief groove]
    set fr [$frA getframe]
      foreach p {1 2} {
        set lab [Label $fr.lab$p -text "PS-$p Serial Number"]
        set ent [ComboBox $fr.ent$p -values $addrL -width 20 -textvariable gaSet(it6900.$p) ]
        set but [Button $fr.but$p -command [list IT6900_clr $p] -text "Clear"]
        grid $lab $ent $but
        set gaGui(it6900.$p) $ent
      }
    pack $fr  
    
  set frB [TitleFrame $base.frB -text "Manual mode" -bd 2 -relief groove]
    set fr [$frB getframe]
    set butOn  [Button $fr.butOn  -text "ON"  -command {IT6900_on_off gui on}]
    set butOff [Button $fr.butOff -text "OFF" -command {IT6900_on_off gui off}]
    set entVolt [Entry $fr.entVolt -textvariable gaSet(it6900.volt)]
    set butSet  [Button $fr.butSet  -text "SET"  -command {IT6900_set gui ""}]
    bind $entVolt <Return> {IT6900_set}
    pack $butOn $butOff -padx 5 -side left
    pack $entVolt $butSet -padx 5 -side left
  
  pack $frA
  pack $frB
  
}

# ***************************************************************************
# IT6900_on_off
# ***************************************************************************
proc IT6900_on_off {gui_script mode} {
  puts "\nIT6900_on_off $gui_script $mode"
  global gaSet gaGui
  set ret -1
  foreach ps {1 2} {
    if {$gui_script=="gui"} {
      set addr [$gaGui(it6900.$ps) get]
    } else {
      set addr $gaSet(it6900.$ps)
    }
    if {$addr!=""} {
      set ret [exec python.exe lib_IT6900.py $addr write "outp $mode"]
    } else {
      set ret 0
    }
  } 
  if {$ret=="-1"} {
    set gaSet(fail) "No communication with IT6900"
  }
  return $ret
}
# ***************************************************************************
# IT6900_set
# ***************************************************************************
proc IT6900_set {gui_script volt} {
  global gaSet gaGui
  puts "\nIT6900_set $gui_script $volt"
  set ret -1
  foreach ps {1 2} {
    if {$gui_script=="gui"} {
      set addr [$gaGui(it6900.$ps) get]
      set volt $gaSet(it6900.volt)
    } else {
      set addr $gaSet(it6900.$ps)
    }
    if {$addr!=""} {
      set ret [exec python.exe lib_IT6900.py $addr write "volt $volt"]
    } else {
      set ret 0
    }
  }  
  if {$ret=="-1"} {
    set gaSet(fail) "No communication with IT6900"
  }
  return $ret
}

# ***************************************************************************
# IT6900_clr
# ***************************************************************************
proc IT6900_clr {ps} {
  global gaGui
  $gaGui(it6900.$ps) clearvalue
}
# ***************************************************************************
# IT6900_quit
# ***************************************************************************
proc IT6900_quit {} {
  global gaSet gaGui
  foreach ps {1 2} {
    set gaSet(it6900.$ps) [$gaGui(it6900.$ps) get]
  }
  $gaGui(fr6900.lab2) configure -text ${gaSet(it6900.1)}-${gaSet(it6900.2)}
  if {[info exists gaSet(DutFullName)] && $gaSet(DutFullName)!=""} {
    BuildTests
  }  
  SaveInit
  destroy .topHwInit
}

# ***************************************************************************
# IT9600_current
# ***************************************************************************
proc IT9600_current {} {
  global buffer gaSet
  puts "\n[MyTime] IT9600_current"; update
  set ret [IT9600_normalVoltage 1 1]
  # set ret [IT6900_on_off script off]
  # if {$ret!="-1"} {
    # set ret [IT6900_set script $volt]
  # }  
  # if {$ret!="-1"} {
    # after 2000
    # set ret [IT6900_on_off script on]
    # after 2000
  # }
  set addr $gaSet(it6900.1)
  set ret [exec python.exe lib_IT6900.py $addr query meas:curr?]
  puts "curr_ret:<$ret>"
  set ret [lindex [split $ret \n] end]
  puts "curr_ret:<$ret>"
  if {$ret>0.05} {
    set ret 0
  } else {
    set gaSet(fail) "UUT doesn't connected to IT6900"
    set ret -1
  }
  return $ret
}