#set gaSet(javaLocation) C:\\Program\ Files\\Java\\jre1.8.0_201\\bin\\
switch -exact -- $gaSet(pair) {
  1 - 5 - SE {
      set gaSet(comDut)     1; #6; #2
      set gaSet(comSer1)    4
      set gaSet(comSer2)    2; #6
      set gaSet(comSer485)  8
      console eval {wm geometry . +150+1}
      console eval {wm title . "Con 1"} 
      set gaSet(pioBoxSerNum) FT7EUAUJ
  }
  2 {
      set gaSet(comDut)     10; #6
      set gaSet(comSer1)    4; #7
      set gaSet(comSer2)    2; #8
      set gaSet(comSer485)  6; #10
      console eval {wm geometry . +150+200}
      console eval {wm title . "Con 2"} 
      set gaSet(pioBoxSerNum) FT567XS1         
  }
  
}  
source lib_PackSour.tcl
