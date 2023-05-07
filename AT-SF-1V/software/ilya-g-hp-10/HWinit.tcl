#set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_201\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     1
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT3GQ1VA  
  }
  2 {
      set gaSet(comDut)    5
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FTRQC03         
  }
  
}  
source lib_PackSour.tcl
