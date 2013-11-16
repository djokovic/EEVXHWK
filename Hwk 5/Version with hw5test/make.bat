asm86 keytable.asm m1 db ep
asm86 keypad.asm m1 db ep
asm86 hw5_main.asm m1 db ep
asm86 display.asm m1 db ep

link86 display.obj, keytable.obj, keypad.obj, hw5_main.obj, hw5test.obj to final.lnk

loc86  final.lnk to hw5test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))