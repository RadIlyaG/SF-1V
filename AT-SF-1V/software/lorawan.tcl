proc LoraWanOpen {} {
    set ie [ twapi::comobj InternetExplorer.Application ]
    $ie Visible 0
    set url "https://10.10.10.20/terminal/open/1/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI3OTA5OTcyMTMsImlhdCI6MTU5MDk5NzIxMywibmJmIjoxNTkwOTk3MjEzLCJpZGVudGl0eSI6MX0.2rfi8eIHCtzG0EnXzg4cmdKFI7oRAunFMstk9BdGOo8"
    set url "https://10.10.10.20/terminal/open/2/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjI3Nzk2MjM1MzIsImlhdCI6MTU3OTYyMzUzMiwibmJmIjoxNTc5NjIzNTMyLCJpZGVudGl0eSI6MX0.3UOC9QmvxiS9aPb5lWNuc9rsNylfVUcxAHRH8rJUlnI"
    $ie Navigate $url
    $ie Visible 1
    set w [ $ie HWND ]
    set wIE [ list $w HWND ]
    while { [ $ie Busy ] } {
      puts -nonewline "."
      flush stdout
      after 250
    }
    set doc [ $ie Document ]
    while { [ $doc readyState ] != "complete" } {
      after 250
    }
    set body [ $doc body ]
    
    
    set inputs [ $body getElementsByTagName "*" ]
    set length [ $inputs length ]
#     set index 0
#     while { $index < $length } {
#       set input [ $inputs item $index ]
#       if [catch { $input name } name] {
#         puts "$index"
#       } else {
#         puts "input:<$input> name:<$name>"
#       }
#       incr index
#     }
    
    set index 0    
    while { $index < $length } {
      set input [ $inputs item $index ]
      if [catch { $input name } name] {
      
      } else {
        puts "input:<$input> name:<$name>"
        if { [ string compare $name "overridelink" ] == 0 } {
          $input focus
          after 250
          $input click
          break
        }
      }
      incr index    
    }
    
    after 4000
    update
    
  }
  
proc LoraWanEcho {str} {
  set windows [twapi::find_windows -match glob -text "root@lorawan*"]
  if {[llength $windows]} {
    set win [lindex $windows 0]
    twapi::set_focus $win
    after 1000
    twapi::send_input_text  "\r"
    after 1000
    twapi::send_input_text  "\r"
    after 1000
    twapi::send_input_text  "cd LoRaWAN\r"
    after 1000
    twapi::send_input_text  "cd LoRaWAN_webui\r"
    after 1000
    twapi::send_input_text  "$str"
    after 1000
    twapi::send_input_text  "\r"
  } else {
    puts "no winds"
  }
}  

proc LoraWanClose {} {
  set windows [twapi::find_windows -match glob -text "root@lorawan*"]
  if {[llength $windows]} {
    set win [lindex $windows 0]
    ::twapi::close_window $win
  } else {
    puts "no winds"
  }
}

package require twapi
 
LoraWanOpen
#LoraWanEcho "echo au915>LoRaWAN/LoRaWAN_webui/region\r"  

#LoraWanEcho "echo eu868>LoRaWAN/LoRaWAN_webui/region\r" 
LoraWanEcho "echo eu868>region\r" 

update
#LoraWanClose    


update 
console show  