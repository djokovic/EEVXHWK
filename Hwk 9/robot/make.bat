asm86 chips.asm m1 db ep
asm86 event.asm m1 db ep
asm86 general.asm m1 db ep
asm86 motors.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 robot.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 timers.asm m1 db ep
asm86 vectors.asm m1 db ep
asm86 conv.asm m1 db ep
asm86 trigtbl.asm m1 db ep
asm86 parser.asm m1 db ep



link86 chips.obj, event.obj, general.obj, motors.obj, trigtbl.obj, parser.obj to final1.lnk
link86 queue.obj, robot.obj, serial.obj, timers.obj, vectors.obj, conv.obj to final2.lnk
link86 final1.lnk, final2.lnk to final.lnk


loc86  final.lnk to robot NOIC AD(SM(CODE(2000H),DATA(400H),STACK(7000H)))



