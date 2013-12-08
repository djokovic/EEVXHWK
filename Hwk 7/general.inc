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
;    11/23/2013			Added WORD_LOOKUP_ADJUST - Anjian Wu


; General Constants

ASCII_NULL      EQU     0           ;
nibble_size     EQU     4           ;
BYTE_size       EQU     8           ;
WORD_size       EQU     16          ;
MAX_Q_LENG	    EQU     512          ;Maxlength allowed for byte or word queue

TRUE            EQU     1           ;
FALSE           EQU     0           ;

RESET           EQU     0           ; General Value for Resetting something

CLEAR           EQU     0           ;

WORD_LOOKUP_ADJUST  EQU    1           ; Two bytes in one word -> SHL by 1

; General Definitions for Main Loops

FIRST_RESERVED_VEC	EQU	1	    ;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3       ;
NUM_IRQ_VECTORS     EQU 256     ;number of interrupt vectors

; MainLoop Key Codes

KEY_EVENT_KEY       EQU     1   ; Even code indicating key pressed
SER_ERR_KEY         EQU     2   ;
RX_ENQUEUED_KEY     EQU     3   ;
MODEM_KEY           EQU     4   ;

; General Addresses

INTCtrlReg          EQU     0FF22H  ;EOI interrupt controller       