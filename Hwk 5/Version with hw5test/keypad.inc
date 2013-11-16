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

KEYEVENT        EQU     1               ; 
AUTO_REPEAT     EQU     3000               ; 
DEBOUNCE_TARGET EQU     100               ; 

numOfRows 		EQU     4               ; 

KEYOFFSET 		EQU     080h            ; 

lownibblemask   EQU     000Fh           ;



; Key Definitions

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