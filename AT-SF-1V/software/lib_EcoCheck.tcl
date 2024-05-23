# ***************************************************************************
# MainEcoCheck
# MainEcoCheck DF1002650119 ETX-2-100G-4QSFP-16SFPP-GB-M
# ***************************************************************************
proc MainEcoCheck {barcode} {
  package require sqlite3
  package require json
  package require tls
  package require base64
  ::http::register https 8445 ::tls::socket
  ::http::register https 8443 ::tls::socket

  #global gaSet
  set ::db_file \\\\prod-svm1\\tds\\Temp\\SQLiteDB\\EcoCheck.db
  set ret [DbFileExists]
  if {$ret!=0} {return $ret}
  
  set res [Retrive_OperationItem4Barcode $barcode]
  foreach {res_val res_txt} $res {}
  puts "MainEcoCheck OperationItem4Barcode res_val:<$res_val> res_txt:<$res_txt>"
  if {$res_val=="-1"} {
    return $res_txt
  } else {
    set dbr_asmbl $res_txt
  }
  set res [Retrive_MktPdn $dbr_asmbl]
  foreach {res_val res_txt} $res {}
  puts "MainEcoCheck MktPdn res_val:<$res_val> res_txt:<$res_txt>"
  if {$res_val=="-1"} {
    return $res_txt
  } else {
    set mkt_pdn_num $res_txt
  }
  
  puts ""
  set lis [list]
  foreach unit [list $dbr_asmbl $mkt_pdn_num] type {dbr pdn} {
    set ret [CheckDB $unit]
    puts "MainEcoCheck unit:<$unit> type:<$type> ret:<$ret>"
    if {$ret!=0} {
      foreach item $ret {
        append lis  "$item, "
      }
    }
  }
    
  if {[llength $lis]!=0} {
    set lis [lsort -unique $lis]
    set lis [string trimright $lis " ,"]
    if {[llength $lis]==1} {
      set verb "is an"
    } else {
      set verb "are"
    }
    # set txt "The following change/s for \'$unit\' $verb released:\n\n$lis\n\nConsult with your team Leader"
    # set txt "There $verb unapproved ECO/NPI/NOI for the tested option:\n$lis\n
    # The ATE is locked. Contact your Team Leader"
    
    # if {$type=="pdn"} {
      # set unit "$mkt_pdn_num (DBR Assembly: $dbr_asmbl)"
    # }
    # set txt "Unapproved ECO/NPI/NOI:\n$barcode $unit:\n\n$lis\n
    # The ATE is locked. Contact your Team Leader"
    set txt "$barcode has unapproved ECO/NPI/NOI:\n$lis\n
    The ATE is locked. Contact your Team Leader"
    set ret $txt
    
    if ![file exists c:/logs] {
      file mkdir c:/logs
    }
    set eco_log "c:/logs/[set barcode]_[clock format [clock seconds] -format %Y.%m.%d_%H.%M.%S]_ecoLog.txt"
    if [catch {open $eco_log w+} id] {
      # do nothing
    } else {      
      puts $id "ID Number: $barcode"
      puts $id "DBR Name: $dbr_asmbl"
      puts $id "Marketing Number: $mkt_pdn_num"
      puts $id "\nUnapproved ECO: $lis"
      close $id
    }     
  }
   
  return $ret  
}
# ***************************************************************************
# DbFileExists
# ***************************************************************************
proc DbFileExists {} {
  if [file exists $::db_file] {
    return 0
  } else {
    return "The [file tail $::db_file] file doesn't exist at [file dirname $::db_file]"
  }
}

# ***************************************************************************
# CheckDB
# ***************************************************************************
proc CheckDB {unit} {
  sqlite3 dataBase $::db_file
  dataBase timeout 5000
  
  set res [lsort -unique [dataBase eval "Select ECO from ReleasedNotApproved where Unit = \'$unit\'"]]
  #puts "res:<$res>"
  if {$res==""} {
    set res 0
  }

  dataBase close
  return $res
}
# ***************************************************************************
# Retrive_MktPdn
# ***************************************************************************
proc Retrive_MktPdn {dbr_asmbl_unit} {
  puts "\nRetrive_MktPdn $dbr_asmbl_unit"
  #set barc [format %.11s $barcode]
  #set url "http://webservices03:8080/ATE_WS/ws/rest/MKTPDNByBarcode?barcode=[set barc]"  
  
  #set url "http://webservices03:8080/ATE_WS/ws/rest/MKTPDNByDBRAssembly?dbrAssembly=[set dbr_asmbl_unit]"
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param MKTPDNByDBRAssembly?dbrAssembly=[set dbr_asmbl_unit]
  append url $param
  set paramName "Marketing Number"
  return [Retrive_WS $url $paramName]
} 
# ***************************************************************************
# Retrive_OperationItem4Barcode
# ***************************************************************************
proc Retrive_OperationItem4Barcode {barcode} {
  puts "\nRetrive_OperationItem4Barcode $barcode"
  set barc [format %.11s $barcode]
  
  set url "https://ws-proxy01.rad.com:8445/ATE_WS/ws/rest/"
  set param OperationItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set paramName "DBR Assembly Name"
  return [Retrive_WS $url $paramName]
} 

# ***************************************************************************
# Retrive_WS
# ***************************************************************************
proc Retrive_WS {url paramName} {
  puts "Retrive_WS $url $paramName"
  set res_val 0
  set res_txt [list]
  if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
    after 2000
    if [catch {::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]} tok] {
       set res_val -1
       set res_txt "Fail to get $paramName"
       return [list $res_val $res_txt]
    }
  }
  
  update
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  
  
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    set res_val -1
    set res_txt "http::status: <$st> http::ncode: <$nc>"
  }
  upvar #0 $tok state
  #parray state
  #puts "$state(body)"
  set body $state(body)
  ::http::cleanup $tok
  
  if {$res_val==0} {
    set asadict [::json::json2dict $body]
    foreach {name whatis} $asadict {
      foreach {par val} [lindex $whatis 0] {
        puts "<$par> <$val>"
        if {$val!="null"} {
          lappend res_txt $val
        }  
      }
    }
  }
  return [list $res_val $res_txt]
}



if {[lindex $argv 0]=="Run"} {
  console show
  
  set ret [MainEcoCheck DF1002650119 ] ; #ETX-2-100G-4QSFP-16SFPP-GB-M
  if {$ret!=0} {
    tk_messageBox -message $ret -type ok -icon error -title "Unapproved changes"
  }
  # puts "MainEcoCheck ETX-2-100G-4QSFP-16SFPP-GB-M"
  #exit
}  
#console show



