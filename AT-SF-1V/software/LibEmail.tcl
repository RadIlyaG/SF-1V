puts "inside LibEmail.tcl File" ; update

#======================
# Comments:
# 1. Copy "ezsmtp1.0.0" package to : C:\Tcl\lib\ezsmtp1.0.0  (package for E-MAIL)
# 2. Copy "email24.jpg" to tester
# 3. Copy "LibEmail.tcl" to tester
# 4. Copy "InitEmail.tcl" to tester
# 5. source LibEmail.tcl
# 6. Gui>Tools>
#    - Email Setting
#    - Email Test
# 7. ButRun>
#    - fail SendEmail
#    - MesegeTestPass > SendEmail
# 8. update: gaSet(RackId) it is the index of the Rack !
#    there can be more then one rack with the same Tester.
# 9. update UUT Name via proc TestEmail!
#======================
          	      
# package require img::ico
# package require img::gif
# package require img::jpeg
# package require ezsmtp

set gaSet(EmailSum) 10
set gaSet(RackId) 1

# ***************************************************************************
# GuiEmail                                                Mail (1)
# ***************************************************************************
proc GuiEmail {base} {
  global gaSet gaGui
  
  if {[winfo exists $base]} {
    wm deiconify $base
    return
  }
  
  toplevel $base
  focus -force $base
  wm protocol $base WM_DELETE_WINDOW "wm attribute $base -topmost 0 ; destroy $base ; InitFileEmail"
  wm focusmodel $base passive
  wm overrideredirect $base 0
  wm resizable $base 0 0
  wm deiconify $base
  wm title $base "Send Results to..."
  wm attribute $base -topmost 1
    
  #set gaSet(EmailSum) 10  
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  } else {
    for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
      set gaSet(Email.$i) ""
      set gaSet(chbutEmail.$i) "0" 
    }
    InitFileEmail  
  } 
    
  set gaGui(labMail) [Label $base.labMail -text "Emails" -font {{} 10 {bold underline}}]
  pack $gaGui(labMail) -side top -pady 2 -padx 4 -anchor w
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    set gaGui(fraMail.$i) [frame $base.fraMail$i]
      set gaGui(entMail.$i) [Entry $gaGui(fraMail.$i).entMail$i \
      -width 23 -textvariable gaSet(Email.$i)]
      set gaGui(cbMail.$i) [checkbutton $gaGui(fraMail.$i).cbMail$i \
      -text ".$i" -variable gaSet(chbutEmail.$i) -command "ActivateMail"]      
      pack $gaGui(cbMail.$i) $gaGui(entMail.$i) -side right -padx 4 -pady 2
    pack $gaGui(fraMail.$i) -side top -pady 2 -padx 4 -anchor w
  }  
  ActivateMail
  focus -force $base
  grab $base    
}

# ***************************************************************************
# ActivateMail                                                Mail (2)
# ***************************************************************************
proc ActivateMail {} {
  global gaGui gaSet
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    if {[set gaSet(chbutEmail.$i)]==0} {
      [set gaGui(entMail.$i)] configure -state disabled
    } else {
      [set gaGui(entMail.$i)] configure -state normal
    }
  }
}

##***************************************************************************
##** InitFileEmail +                                           Mail (3)
##***************************************************************************
proc InitFileEmail {} {
  global gaSet 
  set fileId [open InitEmail.tcl w]
  seek $fileId 0 start
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
    puts $fileId "set gaSet(Email.$i) \"$gaSet(Email.$i)\""
    puts $fileId "set gaSet(chbutEmail.$i) \"$gaSet(chbutEmail.$i)\""
  }  
  close $fileId
}
# ***************************************************************************
# SendEmail                                                Mail (4)
# ***************************************************************************
proc SendEmail {UutName msg} {
  global gaSet gaInfo gaGui
#  package require ezsmtp
  ezsmtp::config -mailhost radmail.rad.co.il -from "ATE-UUT210"
   

  # gaSet(RackId)
  if {[info exist gaSet(RackId)]==1} {
   # Exist:
     set RackId $gaSet(RackId)
  } else {
    #Not Exist:
    set RackId ""
  }
  
  # gaGui(Indx)
  if {[info exist gaGui(Indx)]==1} {
   # Exist:
     set RackIndx "#$gaGui(Indx)"
  } else {
    #Not Exist:
    set RackIndx ""
  }  
  
  #source InitEmail.tcl
  if {[file exists InitEmail.tcl]} {
    source InitEmail.tcl
  } else {
    for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {
      set gaSet(Email.$i) ""
      set gaSet(chbutEmail.$i) "0" 
    }
    InitFileEmail  
  }  
  
  
  
  for {set i 1} {$i<=$gaSet(EmailSum)} {incr i} {   
    if {$gaSet(chbutEmail.$i)==1} {
      if { [catch {ezsmtp::send -to "$gaSet(Email.$i)" \
      -subject "[string toupper [info host] ] : Message from Tester $gaSet(pair)" \
      -body "\n[string toupper [info host] ] : Message from Tester $gaSet(pair)\n\
       \n$msg " \
      -from "ate-j-r@rad.com"} res]} {
        puts stderr "Can't Send Email\n res:$res"
        return "Abort"
      }    
    }
  }
  return "Ok"
}

# ***************************************************************************
# TestEmail                                                Mail (5)
# ***************************************************************************
proc TestEmail {} {
  global gaSet

  set ret [SendEmail "UUT" "Demo check email ..."]
  if {$ret!="Ok"} {
   puts stderr "Email problem ..."
   return Abort 
  }
  puts "Email Test pass ... !" ; update
  return Ok
}
