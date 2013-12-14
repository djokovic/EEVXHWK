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
;    12/05/2014         Added FMS_ERROR key, ZERO, changed other keys to 
;                       ASCII based - Anjian


; General Constants
CAR_RETURN		EQU		13			;
ASCII_NULL      EQU     0           ;
bit_size        EQU     1           ;
nibble_size     EQU     4           ;
BYTE_size       EQU     8           ;
WORD_size       EQU     16          ;
ArrayEmpty      EQU     0               ; Empty is set at 0 index

TRUE            EQU     1           ;
FALSE           EQU     0           ;

RESET           EQU     0           ; General Value for Resetting something

CLEAR           EQU     0           ;

ZERO            EQU     0           ;

DIGIT           EQU     10          ; A digit in base 10 

WORD_LOOKUP_ADJUST  EQU    1           ; Two bytes in one word -> SHL by 1

; General Definitions for Main Loops

FIRST_RESERVED_VEC	EQU	1	    ;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3       ;
NUM_IRQ_VECTORS     EQU 256     ;number of interrupt vectors

; MainLoop Key Codes

KEY_EVENT_KEY       EQU     0   ; Event code indicating key pressed
SER_ERR_KEY         EQU     1   ; Event code indicating serial error
RX_ENQUEUED_KEY     EQU     2   ; Event code indicating new rx value gotten
MODEM_KEY           EQU     3   ; Event code indicating modem event
FSM_ERROR           EQU     4   ; Error key showing FSM error

; General Addresses

INTCtrlReg          EQU     0FF22H  ;EOI interrupt controller       