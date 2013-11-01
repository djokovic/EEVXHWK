;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Queues.INC                         		;
;                           Queue Conversion Constants                    	;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timing functions for the 8088
; version of the Microprocessor-Based Clock.
;
; Revision History:
;    10/29/2013			Created - Anjian Wu

;Structure for Queue allocation, information, and storage

QUEUESTRUC      STRUC           	;structure containing all queue info
    head	    DW      ?       	;counter for debouncing the switch
    tail	    DW      ?       	;time until change repeat rates
    qsize	    DW      ?       	;rate at which to repeat the switch
    leng	    DW      ?       	;rate at which to repeat the switch
    array		DB	1024	DUP	(?) ;pointer to the function to get switch status
QUEUESTRUC      ENDS

;Structure for storing Queue return values or args

QUEUEVARS      STRUC           	    ;structure containing all queue info
    dequeued	DW      ?       	;counter for debouncing the switch
QUEUEVARS      ENDS

; ASCII Constants

ARRAY_SIZE      EQU     1024         ;interrupt vector for timer
MAX_LENG	    EQU     512          ;interrupt vector for timer



; General Definitions

ArrayEmpty      EQU     0             ; number of interrupts per second * 10
ByteSizeQueue   EQU     0             ; 4 Bits in a byte
ByteQ           EQU     1             ; 4 Bits in a byte
WordQ           EQU     2             ; 4 Bits in a byte