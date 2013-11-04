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

ArrayEmpty      EQU     0             ; Empty is set at 0 index
ByteSizeQueue   EQU     0             ; 0 indicates byte queue
ByteQ           EQU     1             ; Byte norm factor for indexing
WordQ           EQU     2             ; Word norm factor for indexing
Display_SIZE    EQU     8             ; Size of chars that can fit in display


DISPLAYSTRUC     STRUC           	;structure containing all queue info
    charptr	    DW      ?       	;counter for debouncing the switch
    array		DB	    Display_SIZE	DUP	(?) ;pointer to the function to get switch status
DISPLAYSTRUC      ENDS

;Structure for storing Queue return values or args

DISPLAYVARS      STRUC           	    ;structure containing all queue info
    dequeued	DW      ?       	;counter for debouncing the switch
DISPLAYVARS      ENDS
