;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Timer.INC                         		;
;                              Timer Constants                              ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for timers and their interupts
;
; Revision History:
;    11/02/2013			Created - Anjian Wu



                                        ; Timer Definitions

; Addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register

Tmr1Ctrl        EQU     0FF5EH          ;address of Timer 1 Control Register
Tmr1MaxCntA     EQU     0FF52H          ;address of Timer 1 Max Count A Register
Tmr1Count       EQU     0FF50H          ;address of Timer 1 Count Register


Tmr2Ctrl        EQU     0FF66H          ;address of Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ;address of Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ;address of Timer 2 Count Register

; Control Register Values
Tmr0CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  count timer 2 outs
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode
; Control Register Values
Tmr1CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  count timer 2 outs
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode


; Control Register Values
                                      
                                        ; Control Register Values
CTS_PER_MILSEC  EQU     2250            ; 18MHZ/(8 * 1KHz) ~ 2250 counts per MS
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
NonSpecEOI      EQU     08000H          ;Non-specific EOI command


; Interrupt Vectors and their control values
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0
Tmr1Vec         EQU     18              ;interrupt vector for Timer 18

INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority