asm86 chips.asm m1 db ep
asm86 display.asm m1 db ep
asm86 event.asm m1 db ep
asm86 general.asm m1 db ep
asm86 keypad.asm m1 db ep
asm86 keytable.asm m1 db ep
asm86 queue.asm m1 db ep
asm86 remote.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 timers.asm m1 db ep
asm86 vectors.asm m1 db ep
asm86 conv.asm m1 db ep
asm86 segtab14.asm m1 db ep



link86 chips.obj, display.obj, event.obj, general.obj, keypad.obj, keytable.obj to final1.lnk
link86 queue.obj, remote.obj, serial.obj, timers.obj, vectors.obj, conv.obj,segtab14.obj to final2.lnk
link86 final1.lnk, final2.lnk to final.lnk


loc86  final.lnk to remote NOIC AD(SM(CODE(2000H),DATA(400H),STACK(7000H)))

pcdebug

l remote