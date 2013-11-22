;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  General.INC                         		;
;                               General Constants                    	    ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains general operations
;
; Revision History:
;    11/02/2013			Created - Anjian Wu


; General Constants

ASCII_NULL      EQU     0           ;
nibble_size     EQU     4           ;
BYTE_size       EQU     8           ;
WORD_size       EQU     16          ;

TRUE            EQU     1           ;
FALSE           EQU     0           ;

RESET           EQU     0           ; General Value for Resetting something

CLEAR           EQU     0           ;
; General Definitions for Main Loops

FIRST_RESERVED_VEC	EQU	1	    ;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3       ;
NUM_IRQ_VECTORS     EQU 256     ;number of interrupt vectors

