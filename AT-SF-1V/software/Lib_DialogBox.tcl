package require img::gif
package require img::jpeg
package require img::ico
##***************************************************************************
##** DialogBox
#
#
#** For icon option in [pwd] must be gif file with name like icon.  
#**   error.gif for icon 'error'
#**   stop.gif  for icon 'stop'
#**
#** Input parameters:
#**   -title   Specifies a string to display as the title of the message box. 
#**            The default value is an empty string. 
#**   -text or -message   Specifies the message to display in this message box.  
#**            The default value is an empty string. 
#**   -icon    Specifies an icon to display.
#**            If this option is not specified, then no icon will be displayed.
#**            The following packages will enable to use gif, jpeg and ico files for icon 
#**              package require img::gif
#**              package require img::jpeg
#**              package require img::ico 
#**   -type    Arranges for a predefined set of buttons to be displayed.
#**            The default value is 'ok' button.
#**   -parent  Makes window the logical parent of the message box. 
#**            The message box is displayed on top of its parent window.
#**            The default value is window '.'
#**   -aspect  Specifies a non-negative integer value indicating desired 
#**            aspect ratio for the text.
#**            The aspect ratio is specified as 100*width/height.
#**            100 means the text should be as wide as it is tall, 
#**            200 means the text should be twice as wide as it is tall, 
#**            50 means the text should be twice as tall as it is wide, and so on.
#**            Used to choose line length for text if width option isn't specified. 
#**            Defaults to 1150. 
#**   -default Button index (0,1,2 ...), default state is "0". 
#**            In case of  no Entry, It sets the focus on the Button. 
#**            In case of  Entry, It selects wich Button will perform
#**            on all the Entry validation check.  
#**   -entQty  Entry Quantity (0,1,2 ...), default state is "0".
#**            The Entry values will be placed at "gaDBox".
#**   -entLab Entry Lable Description ([list "UUT 1" "UUT 2" "UUT 3" "UUT 4"]).
#**   -entPerRow Number of Entries per row, default state is 1.
#**   -ent1focus Whether the first entry gets focus, default state is 0 (no focus).
#**
#**    Return value: Name of the pressed Button
#**
#**  Examples:
#**  DialogBox -entQty 2 -type "Accept Cancel" -entLab [list "Left" "Right"]  -text "Please insert BarCode for each UUT"
#**    parray gaDBox
#**    gaDBox(entVal1) = 7296152000316
#**    gaDBox(entVal2) = 7296152000317

#**  DialogBox -entQty 4 -type "Accept Cancel" -entLab [list "UUT 1" "UUT 2" "UUT 3" "UUT 4"]  -text "Please insert BarCode for each UUT"
#**    parray gaDBox
#**    gaDBox(entVal1) = 7296152000316
#**    gaDBox(entVal2) = 7296152000317
#**    gaDBox(entVal3) = 7296152000318
#**    gaDBox(entVal4) = 7296152000319
#**
#**  DialogBox -entQty 1 -type "Accept Cancel"  -text "Please insert BarCode ..." -title "Info" -icon "info"
#**  DialogBox -entQty 1 -type "Accept Cancel"   -text "Please insert BarCode ..." -title "Error" -icon "error"
#**  DialogBox -default 1 -entQty 2 -type "Cancel Accept" -entLab [list "UUT 1" "UUT 2"]  -text "Please insert BarCode for each UUT" 
#**  DialogBox -type "Pass Fail" -text "Check the Results" -title "Question" -icon "question" -aspect 2000
#**  DialogBox -text "Test is completed."  -icon info
#**  DialogBox -text "Test is completed."  -icon images/info  
#**  DialogBox -message "Test is completed."
#**  DialogBox -entQty 4 -ent1focus 1 -entPerRow 2 -type "Cancel Accept" -entLab [list "UUT 1" "UUT 2" a b] -text "Please insert BarCode for each UUT"
#**
##***************************************************************************
proc DialogBox {args} {
  global gaDBox
  catch {array unset gaDBox}
  
  # each option & default value
  foreach {opt def} {title "DialogBox" text "" icon "" type ok \
                     parent . aspect 1150 default 0 entQty 0 entLab "" entPerRow 1\
                     linkText "" linkCmd "" justify center width "" message ""\
                     ent1focus 0 place center font TkDefaultFont DotEn 0 DashEn 0\
                     RadButQty 0 RadButPerRow 1 RadButLab "" RadButVar "" RadButVal "" RadButInvoke ""\
                     bg SystemButtonFace fg SystemWindowText} {
    set var$opt [Opt $args "-$opt" $def]
  }
  
  set varaccpButIndx $vardefault
  if {$varentQty>0} {
    set vardefault [llength $vartype]
  }
  
  set lOptions [list -parent $varparent -modal local -separator 0 \
      -title $vartitle -side bottom -anchor c -default $vardefault -cancel 1 -place $varplace]
  if [winfo exists .tmpldlg] {
    wm deiconify .tmpldlg
    wm deiconify $varparent
    wm deiconify .tmpldlg
    return {}
  }

  #create icon 
  if {[string length $varicon]>0} {
    if {[string index $varicon end-3]=="."} {
      set micon $varicon
    } else {
      set micon $varicon.gif
    }
  }
  if {[catch {image create photo -file [pwd]/$micon} img] == 0} {
    set lOptions [concat $lOptions "-image $img"]
  }
  
  #create Dialog
  set dlg [eval Dialog .tmpldlg $lOptions]

  #create Buttons
  foreach but $vartype {
    if {[lsearch $vartype $but]==$varaccpButIndx} {
      $dlg add -text $but -name $but -command [list EndDlg $dlg $but $varentQty $varDotEn $varDashEn]
    } else {
      $dlg add -text $but -name $but -command [list Dialog::enddialog $dlg $but]
    }    
  }
  
  #create message
  ## supports -message for convertion from tk_messageBox to DialogBox 
  if {$varmessage!=""} {
    set vartext $varmessage
  }
  puts "\n[MyTime] DialogBox txt:<$vartext>"
  set msg [message [$dlg getframe].msg -text $vartext  \
     -anchor c -aspect $varaspect -justify left -font $varfont -bg $varbg -foreground $varfg]

  pack $msg -anchor w -padx 3 -pady 3 ; #-fill both -expand 1
  
  if {$varentQty>0} {
    #-textvariable gaDBox(entVal$fi)
    #-vcmd {EntryValidCmd %P}  -validate all
    #set varentPerRow 2
    set fr [frame [$dlg getframe].fr -bd 2 -relief groove]
      for {set fi 1} {$fi<=$varentQty} {incr fi} {
        set f [frame $fr.f$fi -bd 0 -relief groove]
          set labText [lindex $varentLab [expr $fi-1]]
          set lab$fi [label $f.lab$fi  -text $labText]
          set ent$fi [entry $f.ent$fi] 
          
          ## user defined Entry width
          if {$varwidth!=""} {
            [set ent$fi] configure -width $varwidth
          }
          pack [set ent$fi] -padx 2 -side right -fill x -expand 1
          
          ## don't pack empty Label
          if {$labText!=""} {            
            pack [set lab$fi] -padx 2 -side right
          }
          
        #pack $f -padx 2 -pady 2  -anchor e -fill x -expand 1
        grid $f -padx 2 -pady 2 -row [expr {($fi-1) / $varentPerRow}] -column [expr {($fi-1) % $varentPerRow}]
        
        
        ## in case of 2 Entries pack them side-by-side
        if {$varentQty=="2"} {
          #pack configure $f -side left; # -fill x -expand 1
        }
        [set ent$fi] delete 0 end					         
      }
    pack $fr -padx 2 -pady 2 -fill both -expand 1 
    set taskL [exec tasklist.exe]
    if {[regexp -all wish* $taskL]!="1"} {
      if {$varent1focus==1} {
        focus -force $ent1
      }  
    } else {
      ##  if just one wish is existing - put the focus
      focus -force $ent1
    }
    
    ## binding for each Entries, except last
    for {set fi 1} {$fi<$varentQty} {incr fi} {
      bind [set ent$fi] <Return> [list ReturnOnEntry [set ent$fi] $fi [list focus -force [set ent[expr {$fi+1}]] ] $varDotEn $varDashEn ]
    }
    ## binding for the last Entry
    bind [set ent$varentQty] <Return> [list ReturnOnEntry [set ent$varentQty] $fi [list $dlg invoke $varaccpButIndx ] $varDotEn $varDashEn ]
  }
  if {$varRadButQty>0} {
    set fr [frame [$dlg getframe].fr -bd 2 -relief groove]
      for {set fi 1} {$fi<=$varRadButQty} {incr fi} {
        set f [frame $fr.f$fi -bd 0 -relief groove]
          set labText [lindex $varRadButLab [expr $fi-1]]
          set var [lindex $varRadButVar [expr $fi-1]]
          set val [lindex $varRadButVal [expr $fi-1]]
          set radBut$fi [radiobutton $f.radBut$fi -text $labText -variable gaDBox($var) -value $val]
          pack [set radBut$fi] -padx 2 -side left -fill x -expand 1
          
        grid $f -padx 2 -pady 2 -row [expr {($fi-1) / $varRadButPerRow}] -column [expr {($fi-1) % $varRadButPerRow}]
      }
      foreach rb $varRadButInvoke {
        #puts $rb
        .tmpldlg.frame.fr.f[set rb].radBut[set rb] invoke
      }
    pack $fr -padx 2 -pady 2 -fill both -expand 1 
    
  }
  
  #create "html" link
  if {$varlinkText!=""} {
    set ht [label [$dlg getframe].ht -text $varlinkText -fg blue -cursor hand2]
    set curFont [$ht cget -font]
    if {[llength $curFont]>1} {
      set newFont [linsert $curFont end underline]
    } else {
      set newFont {{MS Sans Serif} 8 underline}
    }
    $ht configure -font $newFont
    pack $ht -anchor w  -padx 6
    bind $ht <1> $varlinkCmd
  }
  
  set sn [clock seconds]
  set ret [$dlg draw]	
  puts "[MyTime] DialogBox ret:<$ret>\n"	
  destroy $dlg
  incr ::wastedSecs [expr {[clock seconds]-$sn}]
  return $ret
}
#***************************************************************************
#** Opt
#***************************************************************************
proc Opt {lOpt opt def} {
  set tit [lsearch $lOpt $opt]
  if {$tit != "-1"} {
    set title [lindex $lOpt [incr tit]]
  } else {
    set title $def
  }
  return $title
}
# ***************************************************************************
# EndDlg
# ***************************************************************************
proc EndDlg {dlg but varentQty dotEn dashEn} {
  global gaDBox
  set res 1
  for {set fi 1} {$fi<=$varentQty} {incr fi} {
    set res [ReturnOnEntry [$dlg getframe].fr.f$fi.ent$fi $fi [list return 1]  $dotEn $dashEn]
    #puts "fi:$fi res:$res"
    if {$res!="1"} {return}
  }    
  Dialog::enddialog $dlg $but
}
# ***************************************************************************
# ReturnOnEntry
# ***************************************************************************
proc ReturnOnEntry {e fi cmd dotEn dashEn} {
  global gaDBox
  set P [$e get]
  set res [EntryValidCmd $P $dotEn $dashEn]
  #puts "e:$e P:$P res:$res cmd:$cmd fi:$fi" ; update
  if {$res==1} {
    set gaDBox(entVal$fi) $P
    eval $cmd
  } else {
    $e selection range 0 end 
  }
}
# ***************************************************************************
# EntryValidCmd
# this proc must return 1 or 0
# ***************************************************************************
proc EntryValidCmd {P dotEn dashEn} {
  #puts "EntryValidCmd $P $dotEn $dashEn"
  set leng [string length $P]
	set rep [regexp -all { } $P]
	if {$dotEn=="1"} {
    set dot "OK"
    set P  [regsub -all {[\.]} $P ""]
  } elseif {$dotEn=="0"}  {
    if {[regexp {\.} $P]==0} {
      set dot "OK"
    } else {
      set dot "BAD"
    }
  }
  if {$dashEn=="1"} {
    set dash "OK"
    set P  [regsub -all {[\-]} $P ""]
  } elseif {$dashEn=="0"}  {
    if {[regexp {\-} $P]==0} {
      set dash "OK"
    } else {
      set dash "BAD"
    }
  }
  set num [string is alnum [regsub -all {[\s]} $P ""]]
  
  puts "leng:<$leng> rep:<$rep> num:<$num> $dot $dash"
	if {($leng>0) && ($leng!=$rep) && ($num=="1") && ($dot=="OK") && ($dash=="OK")} {
	  return 1
  } else {
    return 0
  }
}
