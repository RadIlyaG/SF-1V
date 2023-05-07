#set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_201\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     4
      set gaSet(comSer1)    5
      set gaSet(comSer2)    2
      set gaSet(comSer485)  9; #9
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT6YLYQ3 ; #FT31CTG9  
  }
  2 {
      set gaSet(comDut)     10; #12
      set gaSet(comSer1)    13; #11
      set gaSet(comSer2)    12; #10
      set gaSet(comSer485)  2; #13
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT567XOH         
  }
  
}  
source lib_PackSour.tcl
