package require http
package require tls
package require base64
package require json
::http::register https 8445 [list tls::socket -tls1 1]
package require md5

package provide RLWS 1.7

namespace eval RLWS { 

set ::RLWS::debugWS 0

set ::RLWS::MRserverUR http://ws-proxy01.rad.com:10211/MacRegREST/MacRegExt/ws

# set ::RLWS:::HttpsURL http://ws-proxy01.rad.com:10211/ATE_WS/ws
set ::RLWS:::HttpsURL https://ws-proxy01.rad.com:8445/ATE_WS/ws

}

# console show
proc ::RLWS::UpdateDB {barcode uutName hostDescription  date time status  failTestsList failDescription dealtByServer} {
  #***************************************************************************
  #** UpdateDB
  #***************************************************************************

  # convert some characters to ascii  for url address
  foreach f {uutName hostDescription failTestsList failDescription dealtByServer} {
    set url_$f [::RLWS::_convertToUrl [set $f]]
  }
  if $::RLWS::debugWS {puts "UpdateDB <$barcode> <$uutName> <$hostDescription> <$date> <$time> <$status> <$failTestsList> <$failDescription> <$dealtByServer>"}
  set url "http://webservices03.rad.com:10211/ATE_WS/ws/tcc_rest/add_row?barcode=$barcode&uutName=$url_uutName&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"  
  if $::RLWS::debugWS {puts "UpdateDB url:<$url>"}

  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    if $::RLWS::debugWS {puts "Add line to DB successfully"}
  }
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok

}
# ***************************************************************************
# UpdateDB2
# ***************************************************************************
proc ::RLWS::UpdateDB2 {barcode uutName hostDescription  date time status  failTestsList failDescription dealtByServer traceID poNumber {data1 ""} {data2 ""} {data3 ""}} {
  set dbPath "//prod-svm1/tds/Temp/SQLiteDB/"
  set dbName "JerAteStats.db" 
  if {$data1==""} {
    set data1 [info host]
  }
  foreach f {uutName hostDescription failTestsList failDescription dealtByServer data1 data2 data3} {
    set url_$f [::RLWS::_convertToUrl [set $f]]
  }
  if $::RLWS::debugWS {puts "UpdateDB2 <$barcode> <$uutName> <$hostDescription> <$date> <$time> <$status> <$failTestsList> <$failDescription> \
  <$dealtByServer> <$traceID> <$poNumber> <$data1> <$data2> <$data3>"}
  set url "http://webservices03.rad.com:10211/ATE_WS/ws/tcc_rest/add_row2_with_db?barcode=$barcode&uutName=$url_uutName"
  append url "&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status"
  append url "&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"
  append url "&dbPath=$dbPath&dbName=$dbName&traceID=$traceID&poNumber=$poNumber&data1=$url_data1&data2=$url_data2&data3=$url_data3" 
  if $::RLWS::debugWS {puts "UpdateDB url:<$url>"}

  # set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  # update
  # if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    # if $::RLWS::debugWS {puts "Add line to DB successfully"}
  # }
  # upvar #0 $tok state
  # parray state
  # ::http::cleanup $tok
  set resLst [::RLWS::_operateWS $url NA "UpdateDB2"]
  return $resLst
}

proc CopyToLocalDB {} {
  #***************************************************************************
  #** CopyToLocalDB
  #***************************************************************************
  set url "$::RLWS:::HttpsURL/tcc_rest/downloadFile"
  set myLocation "c:/Logs/demo.db"

  ::http::register https 8443 [list ::tls::socket -tls1 1]

  set idFile [open $myLocation wb]   
  set tok [http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"] -channel $idFile -binary 1]          
  close $idFile
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    puts "Downloaded successfully"
  }
  update
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok
  
}

proc ::RLWS::_convertToUrl {s} {
  #***************************************************************************
  #** ConvertToUrl
  # valid url char :  ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=
  # space = %20
  # ""    = %22
  # {}    = %7b %7d
  # %     = %25
  # ^     = %5e
  # < >   = %3c %3e
  #***************************************************************************
  foreach i "20 22 25 3c 3e 5e 7b 7d" {
    set c [format %c 0x$i]
    lappend specialChars $c %$i
  }
  return [string map "$specialChars" $s]
}

# ***************************************************************************
# Get_SwVersions  (SWVersions4IDnumber.jar)
#  ::RLWS::Get_SwVersions DE1005790454 ; # no SW
#  ::RLWS::Get_SwVersions DC1002287083 
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText contains list of SWxxxx and Versions
#  ::RLWS::Get_SwVersions DC1002287083 returns
#      0 {SW3814 B1.0.3 SW3841 5.2.0.75.28}
#  ::RLWS::Get_SwVersions DE1005790454 returns
#      0 {}
# ***************************************************************************
proc ::RLWS::Get_SwVersions {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  # 11:46 06/04/2025 set url "http://ws-proxy01.rad.com:8081/ExtAppsWS/Proxy/Select"
  set url "http://ws-proxy01.rad.com:10211/ExtAppsWS/Proxy/Select"
  set query [::http::formatQuery queryName "qry.get.sw.for_idNumber_2" db inventory params $barc]
  append url "/?[set query]"
  set resLst [::RLWS::_operateWS $url $query "SW Version"]
  foreach {res resTxt} $resLst {}
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get SW Version"]
    }
  }
  return $resLst 
}

# ***************************************************************************
# Get_OI4Barcode (OI4Barcode.jar)
#  ::RLWS::Get_OI4Barcode EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is DBR Assembly Name (located at resultText)
#   ::RLWS::Get_OI4Barcode EA1004489579 will return
#       0 RIC-LC/8E1/UTP/ACDC
# ***************************************************************************
proc ::RLWS::Get_OI4Barcode {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param OperationItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "DBR Assembly Name"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get DBR Assembly Name"]
    }
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "item"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_CSL
#  ::RLWS::Get_CSL EA1004489579
#  ::RLWS::Get_CSL DC1002310354 no CSL!!
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is CSL (located at resultText)
#   ::RLWS::Get_CSL EA1004489579 will return
#       0 A 
# ***************************************************************************
proc ::RLWS::Get_CSL {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param CSLByBarcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "CSL"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get CSL"]
    }    
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "CSL"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_MrktName
#  ::RLWS::Get_MrktName EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is MKT Name (located at resultText)
#   ::RLWS::Get_MrktName EA1004489579 will return
#       0 RIC-LC/8E1/4UTP/ETR/RAD   
# ***************************************************************************
proc ::RLWS::Get_MrktName {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param MKTItem4Barcode\?barcode=[set barc]\&traceabilityID=null
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Marketing Name"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Marketing Name"]
    }     
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "MKT Item"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Get_MrktNumber
#  ::RLWS::Get_MrktNumber ETX-1P/ACEX/1SFP1UTP/4UTP/WF
#  ::RLWS::Get_MrktNumber ETX-2I-10G-B_ATT/19/DC/8SFPP
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is Marketing Number (located at resultText)
#   ::RLWS::Get_MrktNumber ETX-2I-10G-B_ATT/19/DC/8SFPP will return
#     0 1001799698
# ***************************************************************************
proc ::RLWS::Get_MrktNumber {dbr_assm} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param MKTPDNByDBRAssembly\?dbrAssembly=$dbr_assm
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Marketing Number"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Marketing Number"]
    } 
  }
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "MKT_PDN"]} ] ]
  return [list $res $value] 
} 
# ***************************************************************************
# Disconnect_Barcode  (DisconnectBarcode.jar)
#  ::RLWS::Disconnect_Barcode EA1004489579
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#    ::RLWS::Disconnect_Barcode EA1004489579 will return
#       0 Disconnected
# ***************************************************************************
proc ::RLWS::Disconnect_Barcode {id {mac ""}} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  set url "$::RLWS:::HttpsURL/rest/"
  set param DisconnectBarcode\?mac=[set mac]&idNumber=[set barc]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Disconnect Barcode"]
  return $resLst
} 

# ***************************************************************************
# Get_PcbTraceIdData
#  ::RLWS::Get_PcbTraceIdData 21181408 pcb
#  ::RLWS::Get_PcbTraceIdData 21181408 {pcb product}
#  ::RLWS::Get_PcbTraceIdData 21181408 {pcb product "po number"}
#  ::RLWS::Get_PcbTraceIdData 21181408 {"po number" "pcb_pdn" "sub_po_number" "pdn" "product" "pcb_pdn" "pcb"}
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is PcbTraceId Data 
#   resultText is a list of required parametes/s and its value/s:
#   ::RLWS::Get_PcbTraceIdData 21181408 {pcb product} will return
#       0 {SF-1V/PS.REV0.3I SF1P/PS12V/RG/PS3/TERNA/3PIN/R06}   
# ***************************************************************************
proc ::RLWS::Get_PcbTraceIdData {id var_list} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param PCBTraceabilityIDData\?barcode=null\&traceabilityID=$id
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Pcb TraceId Data"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Pcb TraceId Data"]
    } 
  }
  foreach var $var_list {
    set var_indx [lsearch $resTxt $var]
    if {$var_indx=="-1"} {
      return [list -1 "No such parameter: $var"]
    }
    lappend value [lindex $resTxt [expr {1 + $var_indx} ] ]
  }
  #set value [lindex $resTxt [expr {1 + [lsearch $resTxt "po number"]} ] ]
  return [list $res $value] 
} 


# ***************************************************************************
# CheckMac  (CheckMAC.jar)
# ::RLWS::CheckMac EA1004489579 112233445566
# ::RLWS::CheckMac DE100579045 123456123456
# Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if ID and MAC are not connected or connected to each other
#                  1 if ID or MAC connected to something else
# ***************************************************************************
proc ::RLWS::CheckMac {id mac} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set li [::RLWS::_chk_connection_to_mac $mac]
  foreach {res connected_id} $li {}
  if {$res!=0} {
    return [list $res $connected_id]
  }
  set short_id [format %.11s $id]
  set li [::RLWS::_chk_connection_to_id $short_id]
  foreach {res connected_mac} $li {}
  if {$res!=0} {
    return [list $res $connected_mac]
  }
  if $::RLWS::debugWS {puts "CheckMac input_id:<$short_id>, to $mac connected id: <$connected_id>"}
  if $::RLWS::debugWS {puts "CheckMac input_mac:<$mac>, to $short_id connected mac: <$connected_mac>"}
  
  if {$connected_id == $short_id && $connected_mac == $mac} {
    return [list 0 "$id connected $mac"]
  }
  if {$connected_id == "" && $connected_mac == ""} {
    return [list 0 "$mac & $id aren't connected at all"]
  }
  if {$connected_id != "" && $connected_id != $short_id} {
    return [list 1 "$mac already connected to $connected_id"]
  }
  if {$connected_mac != "" && $connected_mac != $mac} {
    return [list 1 "$id already connected to $connected_mac"]
  }
  return "-100 None"
}

proc ::RLWS::_chk_connection_to_mac {{mac "112233445566"}} {
  set url "$RLWS::MRserverUR/q001_mac_extant_chack"
  set query [::http::formatQuery macID $mac]
  foreach {res connected_id} [::RLWS::_operateWS $url $query "Connection"] {}
  if {$res!=0} {return [list $res $connected_id]}
  set connected_id [lindex $connected_id [expr 1+ [lsearch $connected_id "id_number"] ] ]
  return [list $res $connected_id]
}

proc ::RLWS::_chk_connection_to_id {{id "EA100448957"}} {
  set url "$RLWS::MRserverUR/q003_idnumber_extant_check"
  set query [::http::formatQuery idNumber $id]
  foreach {res connected_mac} [::RLWS::_operateWS $url $query "Connection"] {}
  if {$res!=0} {return [list $res $connected_mac]}
  set connected_mac [lindex $connected_mac [expr 1+ [lsearch $connected_mac "mac"] ] ]
  return [list $res $connected_mac]
}

# ***************************************************************************
#::RLWS:: _operateWS
# ***************************************************************************
proc ::RLWS::_operateWS {url {query "NA"} paramName} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set res_val 0
  set res_txt [list]
  set ::RLWS::asadict ""
  set ::RLWS::body ""
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd {::http::geturl $url -headers $headers}
  if {[string range $query 0 3]=="file"} {
    set mode get_file
    set localUCF [string range $query 5 end]
  } elseif {[string range $query 0 1]=="NA"} {
    set mode no_query
  } else {
    set mode use_query
  }
  
  if {$mode=="get_file"} {
    catch {open $localUCF w+} f
    append cmd " -channel $f -binary 1"
  } elseif {$mode=="use_query"} {
    append cmd " -query $query"
  }
  
  if $::RLWS::debugWS {
    puts "url:<$url>"
    puts "headers:<$headers>"    
    puts "cmd:<$cmd>"
  }
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      # puts "tok:<$tok>"
      set res_val -1
      #  12:48 20/08/2024set res_txt "Fail to get $paramName"
      set res_txt "Network problem"
      catch {close $f}
      return [list $res_val $res_txt]
    }
  }
  catch {close $f}
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  if $::RLWS::debugWS {
    puts "$procName ::http::status:<$st>"
    puts "$procName ::http::ncode:<$nc>"
  }
  
  if {$st=="ok" && $nc=="200"} {
    #puts "Get $command from $barc done successfully"
  } else {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      set res_val -1
      #set res_txt "Network problem "; #"Fail to get $paramName"; # "http::status: <$st> http::ncode: <$nc>"
      set res_txt "Fail to get $paramName"; #"Fail to get $paramName"; # "http::status: <$st> http::ncode: <$nc>"
    }
  }
  upvar #0 $tok state
  if $::RLWS::debugWS {
    #parray state
    puts "$procName state(url):<$state(url)>"
    if [info exist state(-query)] {
      puts "$procName state(-query):<$state(-query)>"
    }
    puts "$procName state(body):<$state(body)>"    
  }
  set body $state(body)
  set ::RLWS::body $body
  ::http::cleanup $tok
  
  if {$res_val==0} {
    if [string match {*DisconnectBarcode*} $url] {
      return [list 0 "Disconnected"]
    }
    if [string match {*ServerPing*} $url] {
      return [list 0 $body]
    }
    if [string match {*add_row2_with_db*} $url] {    
      return [list 0 "Web TCC DataBase is updated successfully"]
    }
    if {$mode=="get_file" && $res_val==0} {    
      if [catch {file size $localUCF} size] {
        return [list "-1" "Fail to get size of UserConfigurationFile"] ; #$localUCF
      } else {
        if [catch {open $localUCF r} fid] {
         return [list "-1" "Fail to read UserConfigurationFile"] ; #$localUCF
        } else {
          set problem 0
          set ucf_content [read $fid]
          if {[string match {*Proxy Error*} $ucf_content] || \
              [string match {*invalid response*} $ucf_content] || \
              [string match {*Error reading*} $ucf_content] || \
              [string match {*stam bdika no color*} $ucf_content]} {
            set problem 1
          }
          if $::RLWS::debugWS {
            #puts "ucf_content:<$ucf_content>"
          }
          catch {close $fid}
          if $problem {
            return [list "-1" "Server problem"] ; #"Fail to get UserConfigurationFile"
          }
        }
        return [list 0 $size]  
      }
      #return [list $res_val $res_txt]      
    }
    
    set asadict [::json::json2dict $body]
    set ::RLWS::asadict $asadict
    if {[string match {*qry.get.sw.for_idNumber_2*} $url]} {
      foreach par $asadict {
        foreach {swF swV verF verV} $par {
          lappend res_txt $swV $verV
        }
      }
    } else {
      foreach {name whatis} $asadict {
        foreach {par val} [lindex $whatis 0] {
          #puts "<$par> <$val>"
          if {$val!="null"} {
            lappend res_txt $par $val
          }                 
        }
      }
    }
  }
  return [list $res_val $res_txt]
}

# ***************************************************************************
# Get_ConfigurationFile
#  ::RLWS::Get_ConfigurationFile ETX-2I-100G_ATT/ACRF/4Q/16SFPP c:/temp/1.txt FAIL!!!
#  ::RLWS::Get_ConfigurationFile ETX-2I-100G_FTR/DCRF/4Q/16SFPP/K10 c:/temp/1.txt
#  ::RLWS::Get_ConfigurationFile ETX-2I-10G-B_ATT/19/DCR/8SFPP c:/temp/1.txt
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have a size of the downloaded file
#   ::RLWS::Get_ConfigurationFile ETX-2I-100G_FTR/DCRF/4Q/16SFPP/K10 c:/temp/1.txt returns
#      0 42207
# ***************************************************************************
proc ::RLWS::Get_ConfigurationFile {dbr_assm localUCF} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  if [file exists $localUCF] {
    catch {file delete -force $localUCF}
    after 500
  }
  
  set url "$::RLWS:::HttpsURL/configDownload/ConfigFile?"
  set param "dbrAssembly=[set dbr_assm]"
  append url $param
  set resLst [::RLWS::_operateWS $url file_$localUCF "Get Configuration File"]
  return $resLst
}
# ***************************************************************************
# Get_File
#   ::RLWS::Get_File //prod-svm1/tds/Install/ATEinstall/JATE_Team/LibUrl_WS/ LibUrl.tcl c:/temp/my_lib_url.tcl
#   ::RLWS::Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have a size of the downloaded file
#   ::RLWS::Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl returns
#      0 21377
# ***************************************************************************
proc ::RLWS::Get_File {path file_name local_file} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url "$::RLWS:::HttpsURL/tcc_rest/downloadFile2?"
  set param "fullpath=[set path][set file_name]&filename=[set local_file]" 
  append url $param
  set resLst [::RLWS::_operateWS $url file_$local_file "Get $path/$file_name"]
  return $resLst
}

# ***************************************************************************
# Get_Mac  (MACServer.exe)
#  ::RLWS::Get_Mac 0
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 
#   resultText will have first MAC
#   ::RLWS::Get_Mac 1 will return
#     0 1806F5879CB6
# ***************************************************************************
proc ::RLWS::MacServer {qty} {
  return [::RLWS::Get_Mac $qty]
}
proc ::RLWS::Get_Mac {qty} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url "$RLWS::MRserverUR/sp001_mac_address_alloc"
  set query [::http::formatQuery p_mode 0 p_trace_id 0 p_serial 0 p_idnumber_id 0 p_alloc_qty $qty p_file_version 1]
  set resLst [::RLWS::_operateWS $url $query "MACs"]
  set Error_indx [lsearch [lindex $resLst 1] "Error"]
  set Error_Val [lindex [lindex $resLst 1] [expr {1+$Error_indx}]]
  #puts "$resLst $Error_indx $Error_Val"
  if {[lindex $resLst 0]==0 && $Error_Val==0} {
    return [list 0 [lindex [lindex $resLst 1] end]]
  } else {
    return [list -1 "Server problem. [lindex $resLst 1]"]
  }  
}

# ***************************************************************************
# Get_Pages (Get28e01Data.exe)
# ::RLWS::Get_Pages IO3001960310 50190576 0 
# ***************************************************************************
proc ::RLWS::Get28e01Data  {id {traceId ""} {macs_qty 10} } {
  return [::RLWS::Get_Pages $id $traceId $macs_qty]
}
proc ::RLWS::Get_Pages {id {traceId ""} {macs_qty 10} } {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set headers [list "content-type" "text/xml" "SOAPAction" ""]
  set data "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
  append data "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
  append data "xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
  append data "xmlns:mod=\"http://model.macregid.webservices.rad.com\">\n"
  append data "<soapenv:Header/>\n"
  append data "<soapenv:Body>\n"
  append data "<mod:get_Data_4_Dallas soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n"
  append data "<ParamStr1 xsi:type=\"xsd:string\">2</ParamStr1>\n"
  append data "<ParamStr2 xsi:type=\"xsd:string\">$id</ParamStr2>\n"
  append data "<ParamStr3 xsi:type=\"xsd:string\">0</ParamStr3>\n"
  append data "<ParamStr4 xsi:type=\"xsd:string\">$traceId</ParamStr4>\n"
  append data "</mod:get_Data_4_Dallas>\n"
  append data "</soapenv:Body>\n"
  append data "</soapenv:Envelope>\n"
  #puts $data
  
  set url "http://ws-proxy01.rad.com:10211/Pages96WS/services/MacWS"
  set cmd {::http::geturl $url -headers $headers -query $data}
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      #puts "tok:<$tok>"
      #set res_val -1
      #set res_txt "Fail to get Pages for $id $traceId."
      return [list -1 "Network problem"]
    }
  }
  
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  set body  [::http::data $tok]
  if $::RLWS::debugWS {puts "tok:<$tok> st:<$st> nc:<$nc> body:<$body>"}
  #upvar #0 $tok state
  ::http::cleanup $tok
  
  if $::RLWS::debugWS {set ::b $body}
  regsub -all {[<>]} $body " " b1  
  if ![string match {*ns1:get_Data_4_DallasResponse*} $b1] {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      set res_val -1
      set res_txt "Fail to get Pages"
      #set res_txt "Fail to get Pages for $id $traceId.."
      return [list $res_val $res_txt]
    }
  }
  if [string match {*502 Proxy Error*} $b1] {
    set res_val -1
    set res_txt "Server problem. Fail to get Pages"
    return [list $res_val $res_txt]
  }
  if [string match {*ERROR*} $b1] {
    set err ERROR
    regexp {(ERROR[\w\s\!]+)/} $b1 ma err
    
    ## if till now we did not checked Ping_Services
    if ![info exists pa_ret] {
      foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
        if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
      }
    }  
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      set res_txt "Fail to get Pages"
      return [list -1 $res_txt]
    }
  }
  
  set res 0
  regexp {(Page 0 - [0-9A-F\s]+) /} $b1 ma page0
  regexp {(Page 1 - [0-9A-F\s]+) /} $b1 ma page1
  regexp {(Page 2 - [0-9A-F\s]+) /} $b1 ma page2
  regexp {(Page 3 - [0-9A-F\s]+) /} $b1 ma page3
  append resTxt $page0\n
  append resTxt $page1\n
  append resTxt $page2\n
  append resTxt $page3
   
  return [list $res $resTxt]
}

# ***************************************************************************
# Ping_Network
# ***************************************************************************
proc ::RLWS::Ping_Network {} {
  package require tdom
  if $::RLWS::debugWS {puts "\nPing_Network"}
  set url "https://ws-proxy01.rad.com:8443/ServerPing/ProxyServerPing"
  set resLst [::RLWS::_operateWS $url "NA" "Network"]
  foreach {ret resTxt} $resLst {}
  if {$ret!=0} {
    return $resLst 
  }
  
  set doc [ dom parse -html $resTxt ] 
  set nodes [$doc childNodes]
  set txt [$nodes asText]
  set status [lrange $txt [lsearch $txt "Status"] end]
  puts "status:$status"
  
  set result ""
  set Webservices03_indx [lsearch $status "Webservices03"]
  set Webservices03_status [lindex $status [expr {$Webservices03_indx + 1}]]
  append result "Webservices03: $Webservices03_status, "
  
  set WsMacPages_indx [lsearch $status "ws-mac-pages"]
  set WsMacPages_status [lindex $status [expr {$WsMacPages_indx + 1}]]
  append result "ws-mac-pages: $WsMacPages_status, "
  
  if ![regexp {webservices03 DB Connection ([\sA-Za-z]+) webservices03} $status ma val] {
    return [list -1 "Fail to read Webservices03 DB Connection"]
  } else {
    set Webservices03_DB_status $val
  }
  append result "webservices03 DB Connection: $Webservices03_DB_status, "
  
  if ![regexp {webservices03 Agile Connection ([\sA-Za-z]+) ws-mac-pages} $status ma val] {
    return [list -1 "Fail to read Webservices03 Agile Connection"]
  } else {
    set Webservices03_Agile_status $val
  }
  append result "webservices03 Agile Connection: $Webservices03_Agile_status, "
  
  if ![regexp {ws-mac-pages DB Connection ([\sA-Za-z]+) ws-mac-pages} $status ma val] {
    return [list -1 "Fail to read WsMacPages DB Connection"]
  } else {
    set WsMacPages_DB_status $val
  }
  append result "ws-mac-pages DB Connection: $WsMacPages_DB_status, "
  
  if ![regexp {ws-mac-pages Agile Connection ([\sA-Za-z]+)} $status ma val] {
    return [list -1 "Fail to read  WsMacPages Agile Connection"]
  } else {
    set  WsMacPages_Agile_status $val
  }
  append result "ws-mac-pages Agile Connection: $WsMacPages_DB_status, "
  
  set result [string trimright $result]
  set result [string trimright $result ,]
  
  if {[regexp -all {OkK} $resTxt]==6} {
    return [list 0 "Server OK"]
  } else {
    if ![file exists c:/temp] {
      file mkdir c:/temp
    }
    set fi c:/temp/[clock format [clock seconds] -format "%Y.%m.%d_%H.%M.%S"]_NetworkProblem.html
    set id [open $fi w+]
    puts $id $resTxt
    close $id
    return [list -1 [list "Server problem" $result $fi]]
  }  
}

# ***************************************************************************
# Ping_Services
#   ::RLWS::Ping_Services
# ***************************************************************************
proc ::RLWS::Ping_Services {} {
  set procName [lindex [info level 0] 0]
  if $::RLWS::debugWS {puts "\n$procName"}
  
  set result ""
  set res 0
  foreach srv {"Webservices03" "PagesServer"} {
    foreach db {DB Agile} {
      foreach {ret resTxt} [::RLWS::_pingToService $srv $db] {
        if $::RLWS::debugWS {puts "srv:<$srv> db:<$db> ret:<$ret> <$resTxt>"}
        incr res $ret
        append result "${resTxt}, "
      }
    }
  }  
  set result [string trimright $result]
  set result [string trimright $result ,]
  if {$res==0} {
    return [list 0 "Server OK"]
  } else {
    set rslt "Server problem. "
    append rslt $result
    return [list -1 $rslt]
  }  
}
# ***************************************************************************
# pingToService
# ***************************************************************************
proc ::RLWS::_pingToService {server db} {
  set procNameArgs [info level 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  if {$server=="Webservices03"} {
    #set url https://ws-proxy01.rad.com:8445/ServerPing03/monitorWS/Ping
    set url http://ws-proxy01.rad.com:10211/ServerPing03/monitorWS/Ping
  } elseif {$server=="PagesServer"} {
    set url http://ws-proxy01.rad.com:10211/ServerPing/monitorWS/Ping
  }
  append url $db
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd [list ::http::geturl $url -headers $headers]
  return [_eval_ping_srv_db $cmd $server $db]
}  
  

# ***************************************************************************
# ::RLWS::Ping_ServicesLocalNet
# ***************************************************************************
proc ::RLWS::Ping_ServicesLocalNet {} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  #

  # foreach ping_serv [list Ping_WebServices03 Ping_WsMacPages Ping_WS03_DB \
      # Ping_WS03_Agile Ping_WsMacPages_DB Ping_WsMacPages_Agile] {
      # foreach {ret resTxt} [$ping_serv] {puts "$ping_serv ret:<$ret> <$resTxt>"}
  # }
  # foreach srv {"webservices03" "webservices03" "webservices03" "ws-mac-pages"}  cmd {Ping PingDB PingAgile Ping} {    
    # foreach {ret resTxt} [PingToService $srv $cmd] {puts "srv:<$srv> cmd:<$cmd> ret:<$ret> <$resTxt>"}
  # }
  
  set result ""
  set res 0
  foreach srv {"webservices03" "ws-mac-pages"} {
    foreach db {"" DB Agile} {
      foreach {ret resTxt} [::RLWS::_pingToServiceLocalNet $srv $db] {
        if $::RLWS::debugWS {puts "srv:<$srv> db:<$db> ret:<$ret> <$resTxt>"}
        incr res $ret
        append result $resTxt\n
      }
    }
  }
  if {$res==0} {
    return [list 0 "Server OK"]
  } else {
    #return [list $res [list "Server problem" $result]]
    return [list -1 [list "Server problem" $result]]
  }
}

# ***************************************************************************
# _pingToServiceLocalNet
# ::RLWS::_PingToServiceLocalNet webservices03 Ping
# ***************************************************************************
proc ::RLWS::_pingToServiceLocalNet {server db} {
  set procNameArgs [info level 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url "https://[set server].rad.com:8443/ServerPing/monitorWS/Ping[set db]"
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd [list ::http::geturl $url -headers $headers]
  return [::RLWS::_eval_ping_srv_db $cmd $server $db]
}  
  
# ***************************************************************************
# _eval_ping_srv_db
# ***************************************************************************
proc ::RLWS::_eval_ping_srv_db {cmd server db} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  if [catch {eval $cmd} tok] {
    puts $tok
    return [list -1 "Network problem"]
  }
  
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  upvar #0 $tok state
  if $::RLWS::debugWS {
    puts "$procName state(url):<$state(url)>"
    if [info exist state(-query)] {
      puts "$procName state(-query):<$state(-query)>"
    }
    puts "$procName state(body):<$state(body)>"
    puts "$procName ::http::status:<$st>"
    puts "$procName ::http::ncode:<$nc>"
  }
  set body $state(body)
  ::http::cleanup $tok
  
  set title "$server"
  if {$db!=""} {
    #  append title " to $db Connection"
    append title " to $db"
  }
  if [string match {*OK*} $body] {
    return [list 0 "$title: OK"]
  } else { 
    return [list -1 "$title: Error"]
  }
}
# ***************************************************************************
# ::RLWS::Ping_WebServices03
# ***************************************************************************
proc nePing_WebServices03 {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://webservices03.rad.com:8443/ServerPing/monitorWS/Ping"
  foreach {ret resTxt} [_operateWS $url "NA" "Webservices03"] {}
  if {$ret!=0} {
    return [list $ret $resTxt] 
  }
  if [string match {*OK*} $::RLWS::body] {
    return [list 0 "Webservices03: OK"]
  } else { 
    return [list -1 "Webservices03: Error"]
  }
}
# ***************************************************************************
# Ping_WsMacPages
# ***************************************************************************
proc nePing_WsMacPages {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://ws-mac-pages.rad.com:8443/ServerPing/monitorWS/Ping"
  foreach {ret resTxt} [_operateWS $url "NA" "ws-mac-pages"] {}
  if {$ret!=0} {
    return [list $ret $resTxt]
  }
  if [string match {*OK*} $::RLWS::body] {
    return [list 0 "ws-mac-pages: OK"]
  } else { 
    return [list -1 "ws-mac-pages: Error"]
  }
}
proc nePing_WS03_DB {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://webservices03.rad.com:8443/ServerPing/monitorWS/PingDB"
  set resLst [_operateWS $url "NA" "webservices03 DB Connection"]
  foreach {ret resTxt} $resLst {}
  puts $::RLWS::body
  if {$ret!=0} {
    return $resLst 
  }
  return $ret
}
proc nePing_WS03_Agile {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://webservices03.rad.com:8443/ServerPing/monitorWS/PingAgile"
  set resLst [_operateWS $url "NA" "webservices03 Agile Connection"]
  foreach {ret resTxt} $resLst {}
  puts $::RLWS::body
  if {$ret!=0} {
    return $resLst 
  }
  return $ret
}

proc nePing_WsMacPages_DB {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://ws-mac-pages.rad.com:8443/ServerPing/monitorWS/PingDB"
  set resLst [_operateWS $url "NA" "ws-mac-pages DB Connection"]
  foreach {ret resTxt} $resLst {}
  puts $::RLWS::body
  if {$ret!=0} {
    return $resLst 
  }
  return $ret
}

proc nePing_WsMacPages_Agile {} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set url "https://ws-mac-pages.rad.com:8443/ServerPing/monitorWS/PingAgile"
  set resLst [_operateWS $url "NA" "ws-mac-pages Agile Connection"]
  foreach {ret resTxt} $resLst {}
  puts $::RLWS::body
  if {$ret!=0} {
    return $resLst 
  }
  return $ret
}

# ***************************************************************************
# ::RLWS::Ping_WebServices03_ATE_WS
# ***************************************************************************
proc ::RLWS::Ping_WebServices03_ATE_WS {} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url "$::RLWS:::HttpsURL/rest/Ping"
  set headers [list Authorization "Basic [base64::encode webservices:radexternal]"]
  set cmd {::http::geturl $url -headers $headers}
  
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      return [list -1 $tok]
    }
  }
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  upvar #0 $tok state
  
  if $::RLWS::debugWS {parray state}
  #puts "$state(body)"
  set body $state(body)
  if $::RLWS::debugWS {set ::b $body}
  
  ::http::cleanup $tok
  set asadict [::json::json2dict $body]
  foreach {name whatis} $asadict {
    foreach {par val} [lindex $whatis 0] {
      if {[regexp {Server ~~~  = webservices03} $val]} {
        set ret 0
        break
      }                 
    }
  }
  return $ret
}
# ***************************************************************************
# Ping_Pages
# ***************************************************************************
proc ::RLWS::Ping_Pages {}  {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set headers [list "content-type" "text/xml" "SOAPAction" ""]
  set data "<soapenv:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
  append data "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
  append data "xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
  append data "xmlns:mod=\"http://model.macregid.webservices.rad.com\">\n"
  #append data "xmlns:mod=\"http://model.chinaws.webservices.rad.com\">\n"
  append data "<soapenv:Header/>\n"
  append data "<soapenv:Body>\n"
  append data "<mod:ping soapenv:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"/>\n"
  append data "</soapenv:Body>\n"
  append data "</soapenv:Envelope>\n"
  #puts $data
  
  set url "https://ws-proxy01.rad.com:8445/Pages96WS/services/MacWS"
  set cmd {::http::geturl $url -headers $headers -query $data}
  if [catch {eval $cmd} tok] {
    after 2000
    if [catch {eval $cmd} tok] {
      puts "tok:<$tok>"
      return [list -1 $tok]
    }
  }
  
  set st [::http::status $tok]
  set nc [::http::ncode $tok]
  set body  [::http::data $tok]
  if $::RLWS::debugWS {puts "tok:<$tok> st:<$st> nc:<$nc> body:<$body>"}
  #upvar #0 $tok state
  ::http::cleanup $tok
  
  if $::RLWS::debugWS {set ::b $body}
  regsub -all {[<>]} $body " " b1
  return [regexp {Server ~~~  = WS-MAC-Pages} $b1]
}

# ***************************************************************************
# Get_TraceId
#  ::RLWS::Get_TraceId DA200047522
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is TraceabilityID (located at resultText)
#   ::RLWS::Get_TraceId DA200047522 will return
#       0 21146247C
# ***************************************************************************
proc ::RLWS::Get_TraceId {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/traceability/"
  set param TraceabilityByBarcode\?barcode=[set barc]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Traceability"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Traceability"]
    } 
  }
  
  set pcb_ba_index [lsearch $resTxt "pcb_barcode"]
  if {$pcb_ba_index == "-1"} {
    if ![info exists pa_ret] {
      foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
        if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
      }
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Traceability"]
    } 
  }
  
  set value [lindex $resTxt [expr {1 + $pcb_ba_index} ] ]
  if {$value == 0} {
    if ![info exists pa_ret] {
      foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
        if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
      }
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Traceability"]
    }
  }
  return [list $res $value] 
} 

proc _check_Get_TraceId {} {
  foreach id {DA200047522 DC1001956326 DC100195633 DF100272461 DF1002696111 DF1002721426 FP200125518 DF1002708683 \
    DF100272461  DA200047522  DF1002723594  DE100794971  DE1007947959  DF1002724690  DF1002724618   DE100798981  DC1002311636  DE100799177  DE100794971  DC1001956326
    DE1007983030  IO300197853   DE1007954162  DC1002332967
    IO300000205 DE1007315549 DE100728260 DE100729904 IO3000823322  DE100731137 DE1007377716
    DE100760152 IO300078795 DE100749487 IO300101810 DE100732002 IO300171499 IO3001194935
    IO300142344 DE100725064 DE100725827 DE100731228 DE100740010 DE100727144 IO300088155
    IO300101807 IO3001402889 DE100726907 IO3001797477 DE100725112 DE100727790 DE100731101
    IO3000896726 IO300051155 DE100752202 IO300089938 DE100726448 IO300151093 DE100727768
    IO3001380152 DE100753052 IO300187291 DE100740009 DE100612501 DE1007485635 DF1002383457
    DF1002345891 DF1002382908 DF1002692230 DF1002573555 DF1002374343 DF1002638302
    DF1002373229 DF100193327 DF1002386092 DF1002643562 DF1002373423 DF1002643562
    DF1002277590 DF1002277703 DF1002433202 DF1002599748 DF1002334761 DF1002724849 DF1002558273 DF1002373210
    DF1002291095 DF1002644163 DF100193327  DF1002718361 DF1002704678 DF1002704678} {
 ## DF1002386092 DF1002382908 DF1002644163 seems all exists, but no TraceID
 ## DF1002374343 has TraceID
    foreach {ret resTxt} [Get_TraceId $id] {}
    if {$ret!=10} {
      puts "[format %12.12s $id] $resTxt  [Get_OI4Barcode $id]"
    }
  }  
}

# ***************************************************************************
# Get_DigitalSerialCode
#  ::RLWS::Get_DigitalSerialCode DZ100078016
#  ::RLWS::Get_DigitalSerialCode EB100124573
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is DBR Assembly Name (located at resultText)
#   ::RLWS::Get_DigitalSerialCode DZ100078016 will return
#       0 5113721198
# ***************************************************************************
proc ::RLWS::Get_DigitalSerialCode {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/digital/"
  set param DigitalSerialCodeByBarcode\?barcode=[set barc]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Digital Serial Code"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Digital Serial Code"]
    }
  }
  
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "DigitalSerial"]} ] ]
  if {$value == 0 || $value == ""} {
    return [list -1 "Fail to get Digital Serial Code"]
  }
  return [list $res $value] 
}
# ***************************************************************************
# Get_EmpName
#  ::RLWS::Get_EmpName 114965
#  
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is Employee Name (located at resultText)
#   ::RLWS::Get_EmpName 114965 will return
#       0 "KOBY LAZARY"
# ***************************************************************************
proc ::RLWS::Get_EmpName {empId} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param GetUserName\?employeeNumber=[set empId]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Employee Name"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Employee Name"]
    }
  }
  
  set firstname [lindex $resTxt [expr {1 + [lsearch $resTxt "firstname"]} ] ]
  if {$firstname == ""} {
    return [list -1 "Fail to get Employee First Name"]
  }
  set secondname [lindex $resTxt [expr {1 + [lsearch $resTxt "secondname"]} ] ]
  if {$secondname == ""} {
    return [list -1 "Fail to get Employee Second Name"]
  }
  
  return [list $res "$firstname $secondname"]  
}

# ***************************************************************************
# Update_SimID_LoraGW
#  ::RLWS::Update_SimID_LoraGW EA1004489579 89011703274284322239 0016C001F1109216
#  
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if there is Update succeeded
#   ::RLWS::Update_SimID_LoraGW EA1004489579 89011703274284322239 0016C001F1109216 will return
#       0 "Update succeeded"
#   ::RLWS::Update_SimID_LoraGW EA10044895 89011703274284322239 0016C001F1109216 will return
#       -1 "Fail to Update SimID and LoraGW"
# ***************************************************************************
proc ::RLWS::Update_SimID_LoraGW {id simId loraGw} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set simIdLen [string length $simId]
  if {$simIdLen<18 || $simIdLen>22} {
    return [list -1 "Length of ICCID is $simIdLen. Should be 18-22"]
  }
  if ![string is digit $simId] {
    return [list -1 "ICCID is not digit number"]
  }
  
  set loraGwLen [string length $loraGw]
  if {$loraGwLen!=16} {
    return [list -1 "Length of LoRa gateway ID is $loraGwLen. Should be 16"]
  }
  if ![string is xdigit $loraGw] {
    return [list -1 "LoRa gateway ID is not hex string"]
  }
  
  set barc [format %.11s $id]
  set url "$::RLWS:::HttpsURL/rest/"
  set param Update_SIM_ID_LORA_GW\?pID_NUMBER=[set barc]&pSIM_ID=[set simId]&pLORA_ID=[set loraGw]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Update SimID and LoraGW"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  set status [lindex $resTxt [expr {1 + [lsearch $resTxt "status"]} ] ]
  if {[llength $resTxt] == 0 || $status=="1"} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to Update SimID and LoraGW"]
    }
  }
  
  if {$status==0} {
    return [list 0 "Update succeeded"] 
  } else {
    return [list -1 $resTxt]
  }  
}

# ***************************************************************************
# ::RLWS::Update_DigitalSerialNumber
#  ::RLWS::Update_DigitalSerialNumber DF200041584 G1342551RB2205RONEN
#  Returns list of two values - result and resultText
#   result may be -1 if WS fails,
#                  0 if OK
#   ::RLWS::Update_DigitalSerialNumber DF200041584 G1342551RB2205RONEN will return
#       0 ""
#   ::RLWS::Update_DigitalSerialNumber ZF200041584 G1342551RB2205RONEN will return
#       -1 "ID NUMBER NOT EXISTS"
# ***************************************************************************
proc ::RLWS::Update_DigitalSerialNumber {id serial} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set barc [format %.11s $id]
  
  set url "$::RLWS:::HttpsURL/digital/"
  set param UpdateDigitalSerialnumber\?barcode=[set barc]\&serial1=[set serial]
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Update Digital Serial Number"]
  foreach {res resTxt} $resLst {}
  if {$res!=0} {
    return $resLst 
  }
  if {[llength $resTxt] == 0} {
    foreach {pa_ret pa_resTxt} [::RLWS::Ping_Services] {
      if $::RLWS::debugWS {puts "pa_ret:<$pa_ret> <$pa_resTxt>"}
    }
    if {$pa_ret != 0} {
      return [list $pa_ret $pa_resTxt]
    } else {
      return [list -1 "Fail to get Digital Serial Code"]
    }
  }
    
  set value [lindex $resTxt [expr {1 + [lsearch $resTxt "DigitalSerial"]} ] ]
  if $::RLWS::debugWS {puts "res:<$res> value:<$value>"}
  if {$value == "ID NUMBER NOT EXISTS"} {
    return [list -1 "Fail to Update Digital Serial Number, $value"]
  } 
  if {$value==0} {
    return [list 0 {}]
  } else {
    return [list -1 $value] 
  }
}

## type: Prod || RMA
## dateFrom, dateTo: 02/04/2024
## ::RLWS::Get_ReportQSFC RMA 02/04/2024 12/04/2024
proc ::RLWS::Get_ReportQSFC {type dateFrom dateTo} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  
  set url "$::RLWS:::HttpsURL/rest/"
  set param ${type}ReportQSFC?dateFrom=${dateFrom}&dateTo=${dateTo}
  append url $param
  set resLst [::RLWS::_operateWS $url "NA" "Update Digital Serial Number"]
  return $resLst
}  

# ***************************************************************************
# MacReg (MACReg_2MAC_2IMEI.exe)
# 
# ::RLWS::MacReg 123456123456 EA1004489579 ;  # will return 0 {}
# ::RLWS::MacReg 123456123456 EA1004489579 -imei2 123456789012345  ; # return: -1 {IMEI 123456789012345 isn't Valid}
# ::RLWS::MacReg 123456123456 EA1004489579 -imei1 862940033957501  ; # return: 0 {}
# ::RLWS::MacReg 123456123456 EA1004489579 -sp1 Enable -imei1 862940033957501
# ::RLWS::MacReg 123456123456 EA1004489579 -imei1 862940033962501
# ***************************************************************************
proc ::RLWS::MacReg {mac1 id args} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  foreach nam [list mac2 imei1 imei2] {
    set $nam ""
  }
  foreach nam [list sp1 sp2 sp3 sp4 sp5 sp6 sp7 sp8] {
    set $nam "DISABLE"
  }
  foreach {nam val} $args {
    set nam [string tolower [string trim $nam]] ; # -IMEI1 -> -imei1
    set val [string toupper [string trim $val]] ; # Enable - > ENABLE
    switch -exact -- $nam {
      -mac2   {set mac2 $val}
      -imei1  {set imei1 $val}
      -imei2  {set imei2 $val}
      -sp1    {set sp1 $val}
      -sp2    {set sp2 $val}
      -sp3    {set sp3 $val}
      -sp4    {set sp4 $val}
      -sp5    {set sp5 $val}
      -sp6    {set sp6 $val}
      -sp7    {set sp7 $val}
      -sp8    {set sp8 $val}
      default {return [list "-1" "Wrong parameter $nam"]}
    }
  }
  
  set id [string toupper [string trim $id]]      ; # ea1004489579 -> EA1004489579
  set mac1 [string toupper [string trim $mac1]]  ; # abcd1234ef00 -> ABCD1234EF00
  
  foreach {ret resTxt} [::RLWS::_checkIdNumber $id] {}
  if $::RLWS::debugWS {puts " MacReg after checkIdNumber ret:<$ret> resTxt:<$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}
  set id [format %.11s $id]
  
  foreach {ret resTxt} [::RLWS::_checkIdNumberIsValid $id] {}
  if $::RLWS::debugWS {puts " MacReg after checkIdNumberIsValid ret:<$ret> resTxt:<$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}  
  
  if {$imei1 != ""} {
    foreach {ret resTxt} [::RLWS::_checkIMEIisValid $imei1] {}
    if $::RLWS::debugWS {puts " MacReg after checkIMEIisValid ret:<$ret> resTxt:<$resTxt>"}
    if {$ret!=0} {return [list $ret $resTxt]}
  }
  if {$imei2 != ""} {
    foreach {ret resTxt} [::RLWS::_checkIMEIisValid $imei2] {}
    if $::RLWS::debugWS {puts " MacReg after checkIMEIisValid2 ret:<$ret> resTxt:<$resTxt>"}
    if {$ret!=0} {return [list $ret $resTxt]}
  }  
  
  ## check if there is/are connected MAC/s IMEI/s  and is/are not equal to provided
  ## if no connected, or connected is/are as provided, then ret:<0> resTxt:<>
  ## if connected is not equal to provided and password was not provided then ret:<-1> resTxt:<No password>
  ## if connected is not equal to provided and password was provided then ret:<0> resTxt:<>
  foreach {ret resTxt} [::RLWS::_overwriteAllMacAndIMEI $id $imei1 $imei2 $mac1 $mac2] {}
  if $::RLWS::debugWS {puts " MacReg after overAll ret:<$ret> resTxt:<$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}
  
  if {$imei1 != ""} {
    foreach {ret resTxt} [::RLWS::_overwriteCurrentIMEI $imei1 $id] {}
    if $::RLWS::debugWS {puts " MacReg after overImei1 ret:<$ret> resTxt:<$resTxt>"}
    if {$ret!=0} {return [list $ret $resTxt]}
  }
  
  if {$imei2 != ""} {
    foreach {ret resTxt} [::RLWS::_overwriteCurrentIMEI2 $imei2 $id] {}
    if $::RLWS::debugWS {puts " MacReg after overImei2 ret:<$ret> resTxt:<$resTxt>"}
    if {$ret!=0} {return [list $ret $resTxt]}
  }
  
  foreach {ret resTxt} [::RLWS::_macExtantCheck $mac1 $id] {}
  if $::RLWS::debugWS {puts " MacReg after macExtantCheck1 ret:<$ret> resTxt:<$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}
  
  if {$mac2 != ""} {
    foreach {ret resTxt} [::RLWS::_macExtantCheck $mac2 $id] {}
    if $::RLWS::debugWS {puts " MacReg after macExtantCheck2 ret:<$ret> resTxt:<$resTxt>"}
    if {$ret!=0} {return [list $ret $resTxt]}
  }
  
  set app_ver 3
  
  set secret1 [md5::md5 -hex MACREG@RAD_WS${mac1}]
  set url $RLWS::MRserverUR/qupdateSeq/
  set query1 [::http::formatQuery ID_NUMBER $id mac $mac1 SP_TYPE1 $sp1 SP_TYPE2 $sp2\
     SP_TYPE3 $sp3 SP_TYPE4 $sp4 SP_TYPE5 $sp5 SP_TYPE6 $sp6 SP_TYPE7 $sp7 SP_TYPE8 $sp8\
     APP_VER $app_ver SEQ 1 IMEI $imei1 IMEI2 $imei2 HAND $secret1]
  foreach {ret resTxt} [_operateWS $url $query1 "Qupdate1"] {}
  if $::RLWS::debugWS {puts " MacReg after Qupdate1 ret:<$ret> resTxt:<$resTxt>"}
    
    
  if {$mac2 != ""} {
    set secret2 [md5::md5 -hex MACREG@RAD_WS${mac2}]
    set query2 [::http::formatQuery ID_NUMBER $id mac $mac2 SP_TYPE1 $sp1 SP_TYPE2 $sp2\
       SP_TYPE3 $sp3 SP_TYPE4 $sp4 SP_TYPE5 $sp5 SP_TYPE6 $sp6 SP_TYPE7 $sp7 SP_TYPE8 $sp8\
       APP_VER $app_ver SEQ 2 IMEI $imei1 IMEI2 $imei2 HAND $secret2]
    foreach {ret resTxt} [_operateWS $url $query2 "Qupdate2"] {}
    if $::RLWS::debugWS {puts " MacReg after Qupdate2 ret:<$ret> resTxt:<$resTxt>"}
  }  
  
  return [list 0 ""]
}


# ***************************************************************************
# checkIdNumber
# checkIdNumber EA100448957
# ***************************************************************************
proc ::RLWS::_checkIdNumber {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
 if {![string is alpha [string range $id 0 1]] || ![string is integer [string range $id 2 end]]} {
    return [list "-1" "$id is not valid"]
  }
  set id_len [string length $id]
  if {$id_len<11} {
    return [list -1 "$id is too short, < 11 characters"]
  } elseif {$id_len==11} {
    return [list 0 "$id"]
  } elseif {$id_len>12} {
    return [list -1 "$id is too long, > 12 characters"]
  } elseif {$id_len==12} {
    set id_contDig [string index $id end]
    set calc_contDig [_calcControlDigit $id]
    if {$id_contDig != $calc_contDig} {
      return [list "-1" "$id is not valid"]
    } else {
      return [list 0 "$id"]
    }
  }
}
proc ::RLWS::_checkIdNumberIsValid {id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url $RLWS::MRserverUR/qry_check_valid_idnumber/
  set query [::http::formatQuery idNumber $id]
  foreach {ret resTxt} [_operateWS $url $query "Check IdNumber is Valid $id"] {}
  if {$ret!=0} {return [list $ret $resTxt]}
  
  ##::asadict == Name qry.check.valid.idnumber result true
  if {[lsearch $::RLWS::asadict "result"]!="-1" && [lsearch $::RLWS::asadict "true"]!="-1"} {
    return [list 0 ""]
  } else {
    return [list -1 "$id is not Valid"]
  }  
}
# ***************************************************************************
# calcControlDigit
#  calcControlDigit DF1002704216
# ***************************************************************************
proc ::RLWS::_calcControlDigit {id} {
  set barcode [string range $id 3 end-1]  ; # DF1002704216 -> 00270421
  set temp 0
  for {set i 0} {$i<8} {incr i} {
    if {[expr {$i % 2}] == 0 } {
      incr temp [expr {[string index $barcode $i] * 3}]
    } else {
      incr temp [string index $barcode $i]
      # print(id_barcode, barcode[i], temp)
    }
  }  
  set temp [expr {10 - [expr {$temp % 10}]}]
  if {$temp == 10} {
    return 0
  } else {
    return $temp
  }  
}      

# ***************************************************************************
# checkIMEIisValid
#  checkIMEIisValid 860548048283565
# ***************************************************************************
proc ::RLWS::_checkIMEIisValid {imei} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  if ![string is double $imei] {
    return [list -1 "$imei has not only digits"]
  }
  set url $RLWS::MRserverUR/check_imei_valid/
  set query [::http::formatQuery imei $imei]
  foreach {ret resTxt} [_operateWS $url $query "Check IMEI is Valid $imei"] {}
  if {$ret!=0} {return [list $ret $resTxt]}
  if {[lindex $resTxt 0]=="true"} {
    return [list 0 ""]
  } else {
    return [list -1 "IMEI $imei isn't Valid"]
  }  
}

# ***************************************************************************
# overwriteAllMacAndIMEI
# ::RLWS::_overwriteAllMacAndIMEI EA100448957 862940033957501 862940033962501 123456123456 AABBCCDDEEFF
# ::RLWS::_overwriteAllMacAndIMEI EA100448957 1234567890123 1234567890123 123456123456 AABBCCDDEEFF
# ::RLWS::_overwriteAllMacAndIMEI EA100448957 862940033957501 862940033962501 123456123456 AABBCCDDEEFF
# ***************************************************************************
proc ::RLWS::_overwriteAllMacAndIMEI {id imei1 imei2 mac1 mac2} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url $RLWS::MRserverUR/getConfirmationMessage/
  set query [::http::formatQuery imei1 $imei1 mac1 $mac1 imei2 $imei2 mac2 $mac2 idnumber $id]
  foreach {ret resTxt} [_operateWS $url $query "Get Confirmation Message"] {}
  if {$ret!=0} {return [list $ret $resTxt]}
  if {[lsearch $resTxt *ConfirmationMessage*]=="-1"} {return [list -1 "No Confirmation Message"]}
  if {[lindex $resTxt 1] == ""} {return [list 0 ""]}
  regsub -all @ [lindex $resTxt 1] "\n" confirmationMessageText2
  return [_managerApproval $confirmationMessageText2]
}

proc ::RLWS::_overwriteCurrentIMEI {imei id} {
  if $::RLWS::debugWS {puts "\n overwriteCurrentIMEI $imei $id"}
  return [_imei_check $imei $id]
}
proc ::RLWS::_overwriteCurrentIMEI2 {imei2 id} {
  if $::RLWS::debugWS {puts "\n overwriteCurrentIMEI2 $imei2 $id"}
  return [_imei2_check $imei2 $id]
}

# ***************************************************************************
# imei_check
#  imei_check 1234567890123 EA100448957
# ***************************************************************************
proc ::RLWS::_imei_check {imei id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url $RLWS::MRserverUR/q005_imei_check/
  set query [::http::formatQuery imei $imei]
  foreach {ret resTxt} [::RLWS::_operateWS $url $query "Check IMEI $imei"] {}
  if {$ret!=0} {return [list $ret $resTxt]}
  if $::RLWS::debugWS {puts "imei_check resTxt1:<$resTxt>"}
  
  set id_number_indx [lsearch $resTxt "id_number"]
  # if {$id_number_indx=="-1"} {return -1}
  if {$id_number_indx=="-1"} {return [list 0 ""]}
  set id_number [lindex $resTxt 1+$id_number_indx]
  if {$id!=$id_number && $id_number!=0} {
    foreach {ret resTxt} [::RLWS::_deleteImei $id_number] {}
  }
  if $::RLWS::debugWS {puts "imei_check resTxt2:<$resTxt>"}
  return [list $ret $resTxt]
}

# ***************************************************************************
# imei2_check
#  imei2_check 1234567890123 EA100448957
# ***************************************************************************
proc ::RLWS::_imei2_check {imei2 id} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set url $RLWS::MRserverUR/q0051_imei_check/
  set query [::http::formatQuery imei2 $imei2 Imei_Index 2]
  foreach {ret resTxt} [::RLWS::_operateWS $url $query "Check IMEI2 $imei2"] {}
  if {$ret!=0} {return [list $ret $resTxt]}
  if $::RLWS::debugWS {puts "imei_check2 resTxt:<$resTxt>"}
  
  set id_number_indx [lsearch $resTxt "id_number"]
  # if {$id_number_indx=="-1"} {return -1}
  if {$id_number_indx=="-1"} {return [list 0 ""]}
  set id_number [lindex $resTxt 1+$id_number_indx]
  if {$id!=$id_number && $id_number!=0} {
    foreach {ret resTxt} [::RLWS::_deleteImei2 $id_number] {}
  }
  if $::RLWS::debugWS {puts "imei_check2 resTxt2:<$resTxt>"}
  return [list $ret $resTxt]
}

# ***************************************************************************
# deleteImei
# deleteImei EA100448957
# ***************************************************************************
proc ::RLWS::_deleteImei {id_number} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set secret [md5::md5 -hex MACREG@RAD_WS${id_number}]
  set url $RLWS::MRserverUR/q006_imei_delete/
  set query [::http::formatQuery idnumber $id_number HAND $secret]
  set resLst [::RLWS::_operateWS $url $query "Delete IMEI from $id_number"]
  if {[lsearch $resLst "-100"]!=0} {
    return [list -1 -100]
  }
  return [list 0 ""]
}

# ***************************************************************************
# deleteImei2
# deleteImei2 EA100448957
# ***************************************************************************
proc ::RLWS::_deleteImei2 {id_number} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set secret [md5::md5 -hex MACREG@RAD_WS${id_number}]
  set url $RLWS::MRserverUR/q0061_imei_delete/
  set query [::http::formatQuery idnumber $id_number HAND $secret Imei_Index 2]
  set resLst [::RLWS::_operateWS $url $query "Delete IMEI2 from $id_number"]
  if {[lsearch $resLst "-100"]!=0} {
    return [list -1 -100]
  }
  return [list 0 ""]
}



# ***************************************************************************
# getConfirmationMessage
#
# ::RLWS::_getConfirmationMessage EA1004489579 123456123456 AABBCCDDEEFF 862940033957501 862940033962501
# ::RLWS::_getConfirmationMessage EA1004489579 123456123456 AABBCCDDEEFF "" ""
# ::RLWS::_getConfirmationMessage EA1004489579 123456123456 AABBCCDDEEFF 862940033957501 862940033962501
# ***************************************************************************
proc ::RLWS::_getConfirmationMessage {id mac1 mac2 imei1 imei2} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
  set id [format %.11s $id]
  set url "http://ws-proxy01.rad.com:10211/MacRegREST/MacReg/Qry/getConfirmationMessage/"
  set query [::http::formatQuery imei1 $imei1 mac1 $mac1 imei2 $imei2 mac2 $mac2 idnumber $id]
  set resLst [::RLWS::_operateWS $url $query "Get Confirmation Message"]
  foreach {ret resTxt} $resLst {}
  if {$ret!=0} {
    return $resLst
  }
  set confirmationMessage [lindex $resLst 1]
  if {[lindex $confirmationMessage 0] != "ConfirmationMessage"} {
    return [list -1 "Fail to get ConfirmationMessage"]
  }
  set confirmationMessageText [lindex $confirmationMessage 1]
  if {$confirmationMessageText == {}} {
    return [list 0 ""]
  }
  regsub -all @ $confirmationMessageText "\n" confirmationMessageText2
  #regsub -all @ $confirmationMessageText "" confirmationMessageText2
  return [::RLWS::_managerApproval $confirmationMessageText2]
}

# ***************************************************************************
# managerApproval
# ***************************************************************************
proc ::RLWS::_managerApproval {txt} {
  set procNameArgs [info level 0]
  set procName [lindex $procNameArgs 0]
  if $::RLWS::debugWS {puts "\n$procNameArgs"}
 set messageTxt ""
  foreach {ret resTxt} [::RLWS::_getManagerPassword] {}
  if {$ret!=0} {
    return [list $ret $resTxt]
  } else {
    set managerPassword $resTxt
  }
  # puts "managerApproval managerPassword : <$managerPassword>"
  append messageTxt $txt \n " Please enter password to replace : " 
  #set res [tk_messageBox -title "Enter password" -message $messageTxt -icon "info" -type okcancel]
  set res -1
  while 1 {
    set res [::RLWS::_dialgBox $messageTxt]
    if $::RLWS::debugWS {puts "managerApproval res of dialgBox : <$res>"}
    if {$res=="-1"} {
      ## Cancel
      return [list -1 "No password"]
    } else {
      if {$res==$managerPassword} {
        return [list 0 ""]
      }
    } 
  } 
  return {}
}

# ***************************************************************************
# _getManagerPassword
# ***************************************************************************
proc ::RLWS::_getManagerPassword {} {
  set secret [md5::md5 -hex "MACREG@RAD_WS"]
  set url $RLWS::MRserverUR/get_manager_password/
  set query [::http::formatQuery HAND $secret]
  set resLst [::RLWS::_operateWS $url $query "Get Manager Password"]
  foreach {ret resTxt} $resLst {}
  if {$ret!=0} {
    return $resLst
  }
  return [list 0 [lindex $resTxt 1]]
}

# ***************************************************************************
# _dialgBox
# ***************************************************************************
proc ::RLWS::_dialgBox {messageTxt} {
  if [winfo exists .tmpldlg] {
    destroy .tmpldlg
  }
  set dlg [eval Dialog .tmpldlg -modal local -separator 0 -title {EnterPassword} -side bottom -anchor c -default 0 -cancel 1]
  # foreach but "OK Cancel" {
    # $dlg add -text $but -name $but -command [list btn $dlg $but]
  # }
  set msg [message [$dlg getframe].msg -text $messageTxt  \
     -anchor c -aspect 20000 -justify left]
  pack $msg -anchor w -padx 3 -pady 3 ; #-fill both -expand 1
  
  set fr [frame [$dlg getframe].fr -bd 0 -relief groove]
    set ent [entry $fr.ent -show *] 
    pack $ent -padx 2 -fill x
  pack $fr -padx 2 -pady 2 -fill both -expand 1 
  focus -force $ent
  
  foreach but "OK Cancel" {
    $dlg add -text $but -name $but -command [list ::RLWS::btn $dlg $but $ent]
  }
  
  foreach {ret entTxt} [$dlg draw] {}
  if $::RLWS::debugWS {puts "DialogBox ret:<$ret> entTxt:<$entTxt>\n"}	
  if {$ret=="Cancel"} {
    set ret -1
  } else {
    set ret $entTxt
  }
  if $::RLWS::debugWS {puts "DialogBox ret:<$ret>\n"}	
  destroy $dlg
  return $ret
}

proc ::RLWS::btn {dlg but ent} {
  set entTxt [$ent get] 
  if $::RLWS::debugWS {puts "btn $but <$entTxt>"}
  update
  Dialog::enddialog $dlg [list $but $entTxt]
  #return $entTxt
}


# ***************************************************************************
# macExtantCheck
# _macExtantCheck 123456123456 EA100448957
# ***************************************************************************
proc ::RLWS::_macExtantCheck {mac id_number} {
  if $::RLWS::debugWS {puts "\n[info level 0]"}
  set secret [md5::md5 -hex MACREG@RAD_WS${mac}]
  set ret 0
  
  set url $RLWS::MRserverUR/q001_mac_extant_chack/
  set query [::http::formatQuery macID $mac]
  foreach {ret resTxt} [::RLWS::_operateWS $url $query "Check Connected to $mac"] {}
  if $::RLWS::debugWS {puts "* ret after q001_mac_extant_chack: <$ret> <$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}
  
  catch {unset id}
  catch {unset ret}
  if {$resTxt!=""} {
    set id_lbl_indx [lsearch $resTxt "id"]
    if {$id_lbl_indx=="-1"} {return -1}
    set id [lindex $resTxt 1+$id_lbl_indx]
    set secretForDel [md5::md5 -hex MACREG@RAD_WS${id}]
    set url $RLWS::MRserverUR/q002_delete_mac_extant/
    set query [::http::formatQuery macID $id HAND $secretForDel]
    foreach {ret resTxt} [::RLWS::_operateWS $url $query "Delete Connected to $mac"] {}
    
    if $::RLWS::debugWS {puts "* ret after q002_delete_mac_extant: <$ret> <$resTxt>"}
    if [string match {*-100*} $resTxt] {return [list $ret "-100"]}
    if {$ret!=0} {return [list $ret $resTxt]}
  }
  
  catch {unset ret}
  set url $RLWS::MRserverUR/q003_idnumber_extant_check/
  set query [::http::formatQuery idNumber $id_number]
  foreach {ret resTxt} [::RLWS::_operateWS $url $query "Check Connected to $id_number"] {}
  if $::RLWS::debugWS {puts "* ret after q003_idnumber_extant_check: <$ret> <$resTxt>"}
  if {$ret!=0} {return [list $ret $resTxt]}
  
  catch {unset id}
  catch {unset ret}
  if {$resTxt!=""} {
    set id_lbl_indx [lsearch $resTxt "id"]
    if {$id_lbl_indx=="-1"} {return -1}
    set id [lindex $resTxt 1+$id_lbl_indx]
    set secretForDel [md5::md5 -hex MACREG@RAD_WS${id}]
    set url $RLWS::MRserverUR/q002_delete_mac_extant/
    set query [::http::formatQuery macID $id HAND $secretForDel]
    foreach {ret resTxt} [::RLWS::_operateWS $url $query "Delete Connected to $mac"] {}
  }
  if $::RLWS::debugWS {puts "* ret after q002_delete_mac_extant: <$ret> <$resTxt>"}
  if [string match {*-100*} $resTxt] {return [list $ret "-100"]}
  
  return $ret
}


  #proc UpdateDB2 {barcode uut hostDescription date tim status failTestsList failReason operator traceID poNumber data1 data2 data3} {
  #  return [::RLWS::UpdateDB2 $barcode $uut $hostDescription $date $tim $status $failTestsList $failReason $operator $traceID $poNumber $data1 $data2 $data3]
  #}



puts "set ::RLWS::debugWS 1"
proc ::RLWS::TestRLWS {} {
  #set ::RLWS::debugWS 1
  
  set testList []
  lappend testList [list ::RLWS::Ping_Services]
  lappend testList [list ::RLWS::CheckMac EA1004489579 112233445566]
  lappend testList [list ::RLWS::Get_ConfigurationFile ETX-2I-100G_FTR/DCRF/4Q/16SFPP/K10 c:/temp/1.txt]
  lappend testList [list ::RLWS::Get_CSL EA1004489579]
  lappend testList [list ::RLWS::Get_DigitalSerialCode DZ100078016]
  lappend testList [list ::RLWS::Get_EmpName 114965]
  lappend testList [list ::RLWS::Get_File //prod-svm1/tds/Install/ATEinstall/bwidget1.8/ arrow.tcl c:/temp/arrow.tcl]
  lappend testList [list ::RLWS::Get_Mac 1]
  lappend testList [list ::RLWS::Get_MrktName EA1004489579]
  lappend testList [list ::RLWS::Get_MrktNumber ETX-2I-10G-B_ATT/19/DC/8SFPP]
  lappend testList [list ::RLWS::Get_OI4Barcode EA1004489579]
  lappend testList [list ::RLWS::Get_Pages IO3001960310 50190576 0]
  lappend testList [list ::RLWS::Get_PcbTraceIdData 21181408 {pcb product {po number}}]
  lappend testList [list ::RLWS::Get_SwVersions DC1002287083]
  lappend testList [list ::RLWS::Get_TraceId DA200047522]
  lappend testList [list ::RLWS::Get_Mac 0]
  lappend testList [list ::RLWS::Update_DigitalSerialNumber DF200041584 G1342551RB2205RONEN]
  lappend testList [list ::RLWS::Update_SimID_LoraGW EA1004489579 89011703274284322239 0016C001F1109216]
  
  foreach {date tim} [split [clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"] " "] {break}
  lappend testList [list ::RLWS::UpdateDB2 EA1004489579 uut hostDescription $date $tim Pass "" "" "Ilya Ginzburg" 12345678 987654 [info host] data2 data3]
  #::RLWS::MacReg 123456123456 EA1004489579
 
  foreach tst $testList {
    foreach {ret resTxt} [eval $tst] {}
    set stam ""
    if {$ret!=0} {
      set stam "!!! "
    }
    puts "$stam [lindex $tst 0] ret:$ret resTxt:$resTxt"
  }
  
}
