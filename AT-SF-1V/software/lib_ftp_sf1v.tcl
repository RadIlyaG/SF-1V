# ***************************************************************************
# FtpUploadFile  
## FtpUploadFile startMeasurement
# ***************************************************************************
proc FtpUploadFile {fil} { 
  puts "[MyTime] FtpUploadFile $fil"
  if ![file exists $fil] {
    puts "FtpUploadFile. $fil doesn't exist"
    return -1
  }
  set hh [::ftp::Open ftp.rad.co.il ate ate2009]
  ::ftp::Cd $hh sf1v
  ::ftp::Put $hh $fil
  ::ftp::Close $hh
  
  return 0
}  
# ***************************************************************************
# FtpGetFile
## FtpGetFile wifiReport.txt LocWifiReport.txt
# ***************************************************************************
proc FtpGetFile {remFil locFil} { 
  puts "[MyTime] FtpGetFile $remFil $locFil"
  set hh [::ftp::Open ftp.rad.co.il ate ate2009]
  ::ftp::Cd $hh sf1v
  
  set ret -1
  foreach val [::ftp::List $hh] {
    if {[lsearch $val [string tolower $remFil]]!="-1"} {
      ::ftp::Get $hh $remFil $locFil
      set ret 1
      break
    }
  }
  
  ::ftp::Close $hh
  
#   set id [open wifiReport.txt r]
#     set t [read $id]
#   close $id
#   
#   puts $t  
#   
  return $ret
} 

# ***************************************************************************
# FtpDeleteFile
##  FtpDeleteFile startMeasurement
# ***************************************************************************
proc FtpDeleteFile {fil} {
  puts "[MyTime] FtpDeleteFile $fil"
  set hh [::ftp::Open ftp.rad.co.il ate ate2009]
  ::ftp::Cd $hh sf1v
  set ret 0
  foreach val [::ftp::List $hh] {
    if {[lsearch $val [string tolower $fil]]!="-1"} {
      catch {::ftp::Delete $hh $fil} ret
      break
    }
  }
#   if [file exists $fil] {
#     catch {::ftp::Delete $hh $fil} ret
#   }
  ::ftp::Close $hh
  return $ret
}

# ***************************************************************************
# FtpFileExist
##  FtpFileExist  startMeasurement
# ***************************************************************************
proc FtpFileExist {fil} {
  puts "[MyTime] FtpFileExist $fil"
  set hh [::ftp::Open ftp.rad.co.il ate ate2009]
  ::ftp::Cd $hh sf1v
  
  set ret -1
  foreach val [::ftp::List $hh] {
    if {[lsearch $val [string tolower $fil]]!="-1"} {
      set ret 1
      break
    }
  }
  ::ftp::Close $hh
  puts "ret of FtpFileExist $fil: <$ret>"
  return $ret
}
# ***************************************************************************
# FtpListOfFiles
# ***************************************************************************
proc FtpListOfFiles {} {
  puts "[MyTime] FtpListOfFiles"
  set hh [::ftp::Open ftp.rad.co.il ate ate2009]
  ::ftp::Cd $hh sf1v
  set li [::ftp::NList $hh]
  ::ftp::Close $hh
  puts "ret of FtpListOfFiles : <$li>"
  return $li
}

# ***************************************************************************
# FtpLaptopSide
# ***************************************************************************
proc FtpLaptopSide {} {
  ## meantime
  #set ::continueFtp 1
  puts "\n\n [MyTime] FtpLaptopSide continueFtp:$::continueFtp"
  if {$::continueFtp == "1"} {
    set listOfFiles []
    set listOfFiles [FtpListOfFiles]
    set startQty 0
    foreach fil $listOfFiles {
      if {[string match *startmeasur* $fil]} {
        incr startQty
        set wifiNet [string range $fil 17 end]
        puts "\nFtpLaptopSide wifiNet:<$wifiNet>"
        
        set intf NA
        switch -exact -- $wifiNet {
          at-secfl1v-1-10_1 {set intf "Wi-Fi_1"}
          at-secfl1v-2-10_1 {set intf "Wi-Fi_2"}
        }
        if {$intf eq "NA"} {
          puts "No intf for $wifiNet"
          continue
        }
        
        set wifiInt [exec netsh.exe wlan show interfaces]
#         set res [regexp "Name\\s+:\\s+$intf\\s\[\\w\\d:\\-_\\#\\s\]+?State\[\\s\\:\]+\(\[a-z\\s\]+\)\\s+SSID\[\\s:\]+\(\[\\w-\]+\)" $wifiInt ma sta ssid]
        set res [regexp "Name\\s+:\\s+$intf\\s\[\\w\\d:\\-_\\#\\s\]+?State\[\\s\\:\]+\(\[a-z\\s\]+\)\\s+SSID\[\\s:\]+RAD_TST1_$wifiNet" $wifiInt ma sta ssid]        
        if $res {
          set ssid "RAD_TST1_$wifiNet"
          if [string match *disconnected* $ma] {
            catch {exec netsh.exe wlan connect RAD_TST1_$wifiNet interface=$intf} res
            puts "FtpLaptopSide wlan connect RAD_TST1_$wifiNet res:<$res>"
          } else {
            set sta [string trim $sta]
            set ssid [string trim $ssid]
            puts "FtpLaptopSide intf:<$intf> status:<$sta> SSID:<$ssid>" ; update
            if {($sta eq "connected") && ($ssid eq "RAD_TST1_$wifiNet")} {
              puts "FtpLaptopSide $wifiNet already connected"
            } else {
              catch {exec netsh.exe wlan connect RAD_TST1_$wifiNet interface=$intf} res
              puts "FtpLaptopSide wlan connect RAD_TST1_$wifiNet res:<$res>"
            }
          }
        } else {
          catch {exec netsh.exe wlan connect RAD_TST1_$wifiNet interface=$intf} res
          puts "FtpLaptopSide wlan connect RAD_TST1_$wifiNet res:<$res>"
        }
        after 1000
        ReadWifi  wifiReport_$wifiNet.txt $wifiNet $intf  
        after 500
        FtpUploadFile  wifiReport_$wifiNet.txt  
        after 1000
        catch {file delete -force wifiReport_$wifiNet.txt} res
        puts "FtpLaptopSide delete wifiReport_$wifiNet.txt res:<$res>"      
      }
    }
      
    after 1000
    
    set eachHalpminutes 1
    set aft [expr {1000 * 30 * $eachHalpminutes}]
    after $aft  {FtpLaptopSide}
  }
}

# ***************************************************************************
# ReadWifi
# ***************************************************************************
proc ReadWifi {reportFile wifiNet intf} {
  puts "\n[MyTime] ReadWifi $reportFile wifiNet $intf"
  #set reportFile wifiReport.txt
  
  catch {file delete -force $reportFile} res
  after 1000
  
  set wifiInt [exec netsh.exe wlan show interfaces]
  #puts "wifiInt:<$wifiInt>"
#   regsub -all {\s:} [regsub -all {\^}  [regsub -all {\s+} $wifiInt "^"] " "] ":"
  #regexp  {Name[\s:]+Wi-Fi[\sa-zA-Z0-9\-_:\#%\(\)\.]+?Host} $wifiInt ma
  set ma ""
  set res [regexp  "Name\[\\s:\]+$intf\[\\sa-zA-Z0-9\\-_:\\#%\\(\\)\\.\]+?RAD_TST1_$wifiNet\\s+Name" $wifiInt ma]
  if {$res eq 0} {
    set res [regexp  "Name\[\\s:\]+$intf\[\\sa-zA-Z0-9\\-_:\\#%\\(\\)\\.\]+?RAD_TST1_$wifiNet\\s+Host" $wifiInt ma]
  }  
  puts "ReadWifi $intf ma:<$ma>"
  puts ""

#   set wifiRep [exec netsh.exe wlan show networks mode=bssid ]  
#   puts "wifiRep:<$wifiRep>"
#   set ma ""
#   set res [regexp {RAD_TST1.+?54} $wifiRep ma] 
#   if {$res==0} {
#     regexp {RAD_TST1.+?54} $wifiRep ma
#   }   
#   puts "ma:<$ma>" ; update
  
  set id [open $reportFile w+]
#     puts $id $wifiRep
#     puts $id $wifiInt
    puts $id $ma
  close $id 
  
  return 0 
}

proc MyTime {} {
  return [clock format [clock seconds] -format "%H:%M:%S %d.%m.%Y"]
}


