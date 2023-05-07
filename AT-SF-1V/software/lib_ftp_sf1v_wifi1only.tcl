# ***************************************************************************
# FtpUploadFile
## FtpUploadFile startMeasurement
# ***************************************************************************
proc FtpUploadFile {fil} { 
  puts "[clock format [clock seconds]] FtpUploadFile $fil"
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
  puts "[clock format [clock seconds]] FtpGetFile $remFil $locFil"
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
  puts "[clock format [clock seconds]] FtpDeleteFile $fil"
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
  puts "[clock format [clock seconds]] FtpFileExist $fil"
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
  puts "[clock format [clock seconds]] FtpListOfFiles"
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
  
  if {$::continueFtp == "1"} {
    if {[FtpFileExist startMeasurement]=="1"} {
       catch {exec netsh.exe wlan connect RAD_TST1} res
       puts "FtpLaptopSide wlan connect RAD_TST1 res:<$res>"
       after 1000
       ReadWifi
       FtpUploadFile  wifiReport.txt
    } else {
      FtpDeleteFile wifireport.txt
    }
    catch {file delete -force wifiReport.txt} res
    puts "FtpLaptopSide delete wifiReport.txt res:<$res>"
    after 1000
    
    set eachHalpminutes 1
    set aft [expr {1000 * 30 * $eachHalpminutes}]
    after $aft  {FtpLaptopSide}
  }
}

# ***************************************************************************
# ReadWifi
# ***************************************************************************
proc ReadWifi {} {
  puts "[clock format [clock seconds]] ReadWifi"
  set reportFile wifiReport.txt
  
  catch {file delete -force $reportFile} res
  after 1000
  
  set wifiInt [exec netsh.exe wlan show interfaces]
  #puts "wifiInt:<$wifiInt>"
  set wifiRep [exec netsh.exe wlan show networks mode=bssid ]  
  #puts "wifiRep:<$wifiRep>"
  set ma ""
  set res [regexp {RAD_TST1.+?54} $wifiRep ma] 
  if {$res==0} {
    regexp {RAD_TST1.+54} $wifiRep ma
  }   
  puts "ma:<$ma>" ; update
  
  set id [open $reportFile w+]
    #puts $id $wifiInt
    puts $id $wifiRep
    puts $id $wifiInt
  close $id 
  
  return 0 
}

