;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Queues.INC                         		;
;                           Queue Conversion Constants                    	;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the queue functions
;
; Revision History:
;    10/29/2013			Created - Anjian Wu
;    11/01/2013   Debugged,Documented, and working - Anjian Wu
;
;Structure for Queue allocation, information, and storage

QUEUESTRUC      STRUC           	;structure containing all queue info
    head	    DW      ?       	;counter for debouncing the switch
    tail	    DW      ?       	;time until change repeat rates
    qsize	    DW      ?       	;rate at which to repeat the switch
    leng	    DW      ?       	;rate at which to repeat the switch
    array		DB	  1024	DUP	(?) ;pointer to the function to get switch status
QUEUESTRUC      ENDS

;Structure for storing Queue return values or args

QUEUEVARS      STRUC           	    ;structure containing a queue arg
    dequeued	DW      ?       	;return value arg for Dequeue
QUEUEVARS      ENDS


; General Definitions

ArrayEmpty      EQU     0             ; Empty is set at 0 index
ByteSizeQueue   EQU     0             ; 0 indicates byte queue
ByteQ           EQU     1             ; Byte norm factor for indexing
WordQ           EQU     2             ; Word norm factor for indexing
MAX_LENG	    EQU     512           ; Maxlength allowed for byte or word queue
