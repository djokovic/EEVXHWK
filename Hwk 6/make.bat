asm86 motors.asm m1 db ep
asm86 general.asm m1 db ep
asm86 hw6_main.asm m1 db ep
asm86 trigtbl.asm m1 db ep

link86 hw6_main.obj, trigtbl.obj, general.obj, motors.obj, hw6test.obj to final.lnk

loc86  final.lnk to hw6test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))