;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                           ;
;                                  Keypad.INC                           	;
;                               Keypad Constants                            ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the display functions
;
; Revision History:
;    11/02/2013			Created - Anjian Wu



; General Definitions

KEYEVENT        EQU     1               ; Even code indicating key pressed

AUTO_REPEAT     EQU     1000            ; Counter for auto-repeat

DEBOUNCE_TARGET EQU     100             ; Count for single key debounce

numOfRows 		EQU     4               ; number of rows in display

KEYOFFSET 		EQU     080h            ; Where keypad is first mapped 

lownibblemask   EQU     000Fh           ; Used to mask lower nibble

NOKEYPRESS      EQU     0               ; Value to indicate no keys pressed

; Key Definitions

; The following are constants that indicate what value maps to each key
;                   The way KEYS are arranged is...
;                   [0]     [1]   [2]   [3]
;                   [4]     [5]   [6]   [7]
;                   [8]     [9]   [10]  [11]
;                   [12]    [13]  [14]  [15]
KEY0        	EQU     0               
KEY1        	EQU     1   
KEY2        	EQU     2   
KEY3        	EQU     3   
KEY4        	EQU     4   
KEY5        	EQU     5   
KEY6        	EQU     6   
KEY7        	EQU     7   
KEY8        	EQU     8   
KEY9        	EQU     9   
KEY10        	EQU     10   
KEY11        	EQU     11  
KEY12        	EQU     12  
KEY13        	EQU     13  
KEY14        	EQU     14   
KEY15        	EQU     15   
NOTAKEY        	EQU     255  