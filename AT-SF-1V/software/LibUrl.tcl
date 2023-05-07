package require http
package require tls
package require base64


proc UpdateDB {barcode uutName hostDescription  date time status  failTestsList failDescription dealtByServer} {
  #***************************************************************************
  #** UpdateDB
  #***************************************************************************

  # convert some characters to ascii  for url address
  foreach f {uutName hostDescription failTestsList failDescription dealtByServer} {
    set url_$f [ConvertToUrl [set $f]]
  }
  puts "UpdateDB <$barcode> <$uutName> <$hostDescription> <$date> <$time> <$status> <$failTestsList> <$failDescription> <$dealtByServer>"
  #set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/add_row?barcode=DF123456789_4&uutName=uutName_4&hostDescription=hostDescription_4&date=date&time=time&status=status&failTestsList=failTestsList_1&failDescription=failDescription&dealtByServer=dealtByServer"
#   set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/add_row?barcode=$barcode&uutName=$url_uutName&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"
  set url "http://webservices03.rad.com:10211/ATE_WS/ws/tcc_rest/add_row?barcode=$barcode&uutName=$url_uutName&hostDescription=$url_hostDescription&date=$date&time=$time&status=$status&failTestsList=$url_failTestsList&failDescription=$url_failDescription&dealtByServer=$url_dealtByServer"  
  puts "UpdateDB url:<$url>"
#   ::http::register https 8443 [list ::tls::socket -tls1 1]

  set tok [::http::geturl $url -headers [list Authorization "Basic [base64::encode webservices:radexternal]"]]
  update
  if {[http::status $tok]=="ok" && [http::ncode $tok]=="200"} {
    puts "Add line to DB successfully"
  }
  upvar #0 $tok state
  #parray state
  ::http::cleanup $tok

}


proc CopyToLocalDB {} {
  #***************************************************************************
  #** CopyToLocalDB
  #***************************************************************************
  set url "https://webservices03:8443/ATE_WS/ws/tcc_rest/downloadFile"
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


proc ConvertToUrl {s} {
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


