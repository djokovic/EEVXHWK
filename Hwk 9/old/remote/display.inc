;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Display.INC                         		;
;                               Display Constants                           ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the display functions
;
; Revision History:
;    11/02/2013			Created - Anjian Wu



; General Definitions

Display_SIZE    EQU     8               ; Size of chars that can fit in display
SEGMENT_NULL    EQU     0               ; Byte value for Sseg pattern of ASCII_NULL
SegPTRAdjust    EQU     1               ; Since we want WORD, we need to adjust 
 

; Display Addresses

LEDDisplay      EQU     0               ; Display is hardware mapped to 0 - 7H
LEDDisplay2     EQU     8               ; 14- seg also hardware mapped to 8h - 0DH


DISPLAYSTRUC     STRUC           	    ;structure containing all display buffers
    buffer		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch 
DISPLAYSTRUC      ENDS



