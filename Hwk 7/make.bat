asm86 serial.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 hw7_main.asm m1 db ep
asm86 vectors.asm m1 db ep
asm86 chips.asm m1 db ep

link86 queue.obj, serial.obj, vectors.obj, hw7_main.obj, chips.obj, hw7test.obj to final.lnk

loc86  final.lnk to hw7test NOIC AD(SM(CODE(1000H),DATA(400H),STACK(7000H)))