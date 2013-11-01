asm86chk hw3.asm
asm86chk hw3_main.asm

asm86 hw3.asm m1 db ep
asm86 hw3_main.asm m1 db ep

link86 hw3.obj, hwk3_test.obj, hw3test.obj to final.lnk

loc86  final.lnk to hw3test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))