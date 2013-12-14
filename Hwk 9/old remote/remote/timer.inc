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
;    11/23/2013			Created - Anjian Wu
;    12/10/2013         Added Timer2 vals - Anjian Wu


                                        ; Timer Definitions

; Addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register

Tmr1Ctrl        EQU     0FF5EH          ;address of Timer 1 Control Register
Tmr1MaxCntA     EQU     0FF5AH          ;address of Timer 1 Max Count A Register
Tmr1Count       EQU     0FF58H          ;address of Timer 1 Count Register


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
                                        ;-----------0----  Retrigger
                                        ;------------0---  Prescaler
                                        ;-------------0--  external clock
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode
                                        
Tmr1CtrlVal     EQU     0E001H          ;value to write to Timer 1 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  Retrigger
                                        ;------------0---  Prescaler
                                        ;-------------0--  external clock
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode

Tmr2CtrlVal     EQU     0E001H          ;value to write to Timer 2 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----0000000-----  reserved
                                        ;-----------0----  MaxCount
                                        ;------------000-  reserved
                                        ;---------------1  continuous mode
; Control Register Values
                                      
                                        ; Control Register Values
CTS_PER_MILSEC  EQU     2250            ; 18MHZ/(8 * 1KHz) ~ 2250 counts per MS

PRESCALE_2SEC   EQU     2000            ; 2 seconds = CTS_PER_MILSEC * 2000

TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
NonSpecEOI      EQU     08000H          ;Non-specific EOI command


COUNT_FOR_30HZ  EQU     600             ; 18,000,000 HZ/(8 * 30 Hz * PWM_WIDTH_MAX) 
                                        ; ~ 600 counts for 30 HZ of PWM
                                        
COUNT_FOR_100HZ EQU     177             ; 18,000,000 HZ/(8 * 100 Hz * PWM_WIDTH_MAX) 
                                        ; ~ 177 counts for 100 HZ of PWM                                       
                                        
                                        ; NOTE THIS IS APPROXIMATE, Clock is actually a bit faster
                                        ; than 18 MHZ


