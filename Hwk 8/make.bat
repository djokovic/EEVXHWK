asm86 parser.asm m1 db ep
asm86 hw8_main.asm m1 db ep
asm86 vectors.asm m1 db ep
asm86 chips.asm m1 db ep

link86 parser.obj, vectors.obj, hw8_main.obj, chips.obj, hw8test.obj to final.lnk

loc86  final.lnk to hw8test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))