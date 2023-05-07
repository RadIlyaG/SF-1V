console show
# package require twapi
# 
# 
# foreach ad [::twapi::get_network_adapters] {
#   if [string match {*D-Link DWA-131*} [::twapi::get_network_adapter_info $ad -description]] {
#     #puts "$ad:[::twapi::get_network_adapter_info $ad -all]"
#     puts "$ad:[::twapi::get_network_adapter_info $ad -unicastaddresses]"
#   }
# }
# 
# 
# netsh>wlan show networks
# netsh wlan> connect name=IPVgate-3nQ
# netsh trace>show interfaces
# 
# netsh wlan>interface ip
# netsh interface ipv4>show interfaces
# netsh interface ipv4>show ipaddresses


# ***************************************************************************
# Ping2Wifi
# ***************************************************************************
proc Ping2Wifi {wifiNet} {
  global gaSet
  puts ""
  puts ""
  set res [catch {exec netsh.exe wlan disconnect interface="Wi-Fi"}  discRes ]
  puts "disconnect from $wifiNet res:<$res> discRes:<$discRes>"
  if {$res=="1"} {
    set gaSet(fail) "Can't disconnect from Wi-Fi"
    return -1
  }

  set res [catch {exec netsh.exe wlan connect name=$wifiNet} connRes]
  puts "Connect to $wifiNet res:<$res> connRes:<$connRes>"
  if {$res=="1"} {
    set gaSet(fail) "Can't connect to net \'wifiNet\'"
    return -1
  }
#   puts [clock seconds]
#   set ipaddL [exec netsh.exe interface ipv4 show ipaddresses]
#   puts [clock seconds]
#   puts "ipaddL:$ipaddL" ; update
  
  set status "disconnected"
  for {set tr 1} {$tr<=5} {incr tr} {
    puts [clock seconds]
    set intfL [exec netsh.exe interface ipv4 show interfaces]
    puts [clock seconds]
    puts "tr:<$tr> intfL:$intfL"  ; update
    foreach intf [split $intfL \n] {
      if [regexp {(\d+)\s+\d+\s+\d+\s+(\w+)\s+Wi-Fi} $intf ma idx status] {
        puts "tr:<$tr> $intf idx:<$idx> status:<$status>"  ; update
        break
      }
    } 
    if {$status=="connected"} {break} 
    after 1000
  }
# set ipaddL [exec netsh.exe interface ipv4 show ipaddresses]
# foreach ipadd $ipaddL {

#}

  if {$status!="connected"} {
    set gaSet(fail) "Wi-Fi net can't connect"
    return -1
  }
  
  puts [clock seconds]
  set ipIntf [exec netsh.exe interface ipv4 show ipaddress interface=$idx]
  puts [clock seconds]
  puts ipIntf:<$ipIntf>
  regexp {Address\s+([\d\.]+)\s} $ipIntf ma ip
  puts ip:<$ip> ; update
  
  set wifiInt [exec netsh.exe wlan show interfaces]
  puts "wifiInt:<$wifiInt>"
  set wifiRep [exec netsh.exe wlan show networks mode=bssid ]
  puts "wifiRep:<$wifiRep>"

  set pingN 10
  set pingRes [exec ping $ip -n $pingN]
  puts $pingRes  ; update
  set res [regexp {Received[\s\=]+(\d+)[\,\s]+Lost[\s\=]+(\d+)} $pingRes ma rcvN lstN]
  if {$res==0} {
    set gaSet(fail) "Read Ping Result fail"
    return -1
  }
  puts "pingN:<$pingN> rcvN:<$rcvN> lstN:<$lstN>"
  if {$rcvN!=$pingN} {
    set gaSet(fail) "Received $rcvN packets instead of $pingN"
    return -1
  }
  if {$lstN!=0} {
    set gaSet(fail) "Lost $lstN packets"
    return -1
  }

  set res [catch {exec netsh.exe wlan disconnect interface="Wi-Fi"}  discRes ]
  puts "disconnect from $wifiNet res:<$res> discRes:<$discRes>" 
  
  return 0
  
}  

foreach wifiNet [list  "HUAWEI P10 PLUS"] {
  #set ret [Ping2Wifi $wifiNet]
}
foreach wifiNet [list IPVgate-3nQ IPVgate-6hp] {
#   set ret [Ping2Wifi $wifiNet]
#   puts "ret of Ping2Wifi $wifiNet - $ret"
#   after 2000
}
foreach wifiNet [list RAD-2] {
  set ret [Ping2Wifi $wifiNet]
  puts "ret of Ping2Wifi $wifiNet - $ret"
  after 2000
}
