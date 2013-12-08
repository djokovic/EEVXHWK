;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Vector.INC                         		;
;                              IVector Constants                            ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for timers and their interupts
;
; Revision History:
;    11/23/2013			Created - Anjian Wu


                                        ; IVector Definitions

; Interrupt Vectors and their control values
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0
Tmr1Vec         EQU     18              ;interrupt vector for Timer 1

INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority