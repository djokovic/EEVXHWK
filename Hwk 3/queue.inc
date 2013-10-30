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
    size	    DB      ?       	;rate at which to repeat the switch
    length		DW      ?    ;flag indicating have a debounced switch
    array		DB	ARRAY_SIZE	DUP	(?) ;pointer to the function to get switch status
QUEUESTRUC         ENDS

; ASCII Constants

ARRAY_SIZE      EQU     1024             ;interrupt vector for timer
MAX_LENG	    EQU     512              ;interrupt vector for timer



; General Definitions

Hex2StrMASK     EQU     000FH           ;number of interrupts per second * 10
ByteSize        EQU     4               ; 4 Bits in a byte