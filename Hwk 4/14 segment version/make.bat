asm86chk display.asm
asm86chk conv.asm

asm86 conv.asm m1 db ep
asm86 display.asm m1 db ep
asm86 hw4_main.asm m1 db ep
asm86 segtab14.asm m1 db ep


link86 segtab14.obj, display.obj, hw4_main.obj, conv.obj, hw4test.obj to final.lnk

loc86  final.lnk to hw4test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))