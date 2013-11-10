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
LEDDisplay2     EQU     8               ; 14- seg also hardware mapped to 8h - 0DH


DISPLAYSTRUC     STRUC           	    ;structure containing all queue info
    array		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch 
                                        ;status
DISPLAYSTRUC      ENDS

;Structure for storing Queue return values or args

DISPLAYVARS      STRUC           	    ;structure containing all queue info
    buffer		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch 
                                        ;status
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

