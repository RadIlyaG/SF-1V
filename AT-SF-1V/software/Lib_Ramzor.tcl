
######################################################
## Ramzor
##  Ramzor color state :
##  Ramzor green on
##  Ramzor red off
##  Ramzor all on
##
## file needed:
## 1. USB_RELAY_DEVICE.dll
## 2. hidusb-relay-cmd.exe
##
## Comment:
## Relay without power default state: n.c --> com
######################################################
proc Ramzor {color state {cmdLoc .}} {
  if {$color=="green"} {
    set li [list 1]
    set colLi "green"
  } elseif {$color=="red"} {
    set li [list 2]
    set colLi "red"
  } elseif {$color=="all"} {
    set li [list 1 2]
    set colLi [list "green" "red"]
  }
  
  foreach Id {1 2} {
    puts "OFF $Id"
    if [catch {exec $cmdLoc/hidusb-relay-cmd.exe off $Id} res] {
      return $res
    }
  }
  after 500
  foreach Id $li col $colLi {
    puts "$col $state"
    if {$state=="on"} {
      if [catch {exec $cmdLoc/hidusb-relay-cmd.exe $state $Id} res] {
        return $res
      }
    } else {
      puts "Already OFF"
    }
  }
  return 0
}

# ***************************************************************************
# Relay_DEMO
# ***************************************************************************
proc Relay_DEMO {} {
  # ON - (n.o -> com)   
  catch {exec c:/relay/hidusb-relay-cmd.exe on  1} res
  catch {exec c:/relay/hidusb-relay-cmd.exe on  2} res
  after 3000
  # OFF - (n.c -> com , default - no power)
  catch {exec c:/relay/hidusb-relay-cmd.exe off 1} res
  catch {exec c:/relay/hidusb-relay-cmd.exe off 2} res
}

#console show
