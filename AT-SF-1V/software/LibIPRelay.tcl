
proc GuiIPRelay {} {
  #**************************************************************
  #* GuiIPRelay
  #**************************************************************
  global gaSet
  set base .topIPRelay
  toplevel $base -class Toplevel
  wm focusmodel $base passive
  wm geometry $base +200+10
  wm resizable $base 1 1
  wm title $base "IP Address of IPRelay"

  set fraRelay [frame $base.fraRelay]
  pack $fraRelay -padx 4
  pack [label $fraRelay.labIPRelay -text "IP Address : "] -side left
  pack [entry $fraRelay.entIPRelay -width 25 -textvar gaSet(iprelay) -validate all -vcmd "isIP %P %V"]

  pack [Separator $base.sep1 -orient horizontal] -fill x -padx 2 -pady 3
  pack [frame $base.frBut ] -pady 4 -anchor center
  pack [Button $base.frBut.butOk -text Ok -width 7 \
    -command "
       SaveInit
       grab release $base
       focus .
       destroy $base
      "] -padx 6
  focus -force $base
  grab $base
  return {}
}



proc isIP {str type} {
  #***************************************************************************
  #** isIP
  #***************************************************************************
   # modify these if you want to check specifi ranges for
   # each portion - now it look for 0 - 255 in each
   set ipnum1 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum2 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum3 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum4 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set fullExp {^($ipnum1)\.($ipnum2)\.($ipnum3)\.($ipnum4)$}
   set partialExp {^(($ipnum1)(\.(($ipnum2)(\.(($ipnum3)(\.(($ipnum4)?)?)?)?)?)?)?)?$}
   set fullExp [subst -nocommands -nobackslashes $fullExp]
   set partialExp [subst -nocommands -nobackslashes $partialExp]
   if [string equal $type focusout] {
      if [regexp -- $fullExp $str] {
	 return 1
      } else {
	 tk_messageBox -message "IP is NOT complete!"
	 return 0
      }
   } else {
      return [regexp -- $partialExp $str]
   }
}


proc IPRelay-Red {} {
  # *******************************************************
  # *          IPRelay-Red
  # *******************************************************
  global gaSet
  if {[info exists gaSet(iprelay)] && $gaSet(iprelay)!=""} { 
    if [catch {::http::geturl http://$gaSet(iprelay):8080/index.html?o0=1 -timeout 3000} tok] {
      ## there is an error, don't do anything
      puts $tok
    } else {
      after 100 "::http::cleanup $tok"
    }
  }
}


proc IPRelay-Green {} {
  # *******************************************************
  # *          IPRelay-Green
  # *******************************************************
  global gaSet gIdAfter gRelayState
  set gRelayState green  
  catch {after cancel $gIdAfter}
  if {[info exists gaSet(iprelay)] && $gaSet(iprelay)!=""} { 
    if [catch {::http::geturl http://$gaSet(iprelay):8080/index.html?o0=0 -timeout 3000} tok] {
      ## there is an error, don't do anything
      puts $tok
    } else {
      after 100 "::http::cleanup $tok"
    }    
  }
}


proc IPRelay-LoopRed {} {
  # *******************************************************
  # *          IPRelay-LoopRed
  # *******************************************************
  global gRelayState gIdAfter
  if {$gRelayState=="green"} {
    return
  }
  IPRelay-Red
  set gIdAfter [after 30000 IPRelay-LoopRed]
}

