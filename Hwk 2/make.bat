asm86chk HW2.asm

asm86 HW2.asm m1 db ep
asm86 hw2test.asm m1 db ep

link86 hw2test.obj, HW2.obj to final.lnk

loc86  final.lnk to hw2test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))