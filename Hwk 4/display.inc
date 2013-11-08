;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Display.INC                         		;
;                           Display Constants                            	;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the queue functions
;
; Revision History:
;    11/02/2013			Created - Anjian Wu



; General Definitions

ArrayEmpty      EQU     0               ; Empty is set at 0 index
Display_SIZE    EQU     8               ; Size of chars that can fit in display
SEGMENT_NULL    EQU     0               ; Byte value for ASCII_NULL in segment

; Display Addresses

LEDDisplay      EQU     0               ; Display is hardware mapped to 0 - 7H


DISPLAYSTRUC     STRUC           	;structure containing all queue info
    array		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch status
DISPLAYSTRUC      ENDS

;Structure for storing Queue return values or args

DISPLAYVARS      STRUC           	    ;structure containing all queue info
    digit     DW      ?
    buffer		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch status
DISPLAYVARS      ENDS


; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

; Register Values
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
NonSpecEOI      EQU     08000H          ;Non-specific EOI command


; Timer Definitions

; Addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register
Tmr2Ctrl        EQU     0FF66H          ;address of Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ;address of Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ;address of Timer 2 Count Register

; Interrupt Vectors
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0