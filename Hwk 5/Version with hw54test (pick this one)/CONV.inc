;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Conversions.INC                           ;
;                           String Conversion Constants                    	 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the CONV functions for the 8088
; 
;
; Revision History:
;    10/23/2013			Created - Anjian Wu

; General Definitions

Hex2StrMASK     EQU     000FH           ;number of interrupts per second * 10
ByteSize        EQU     4               ; 4 Bits in a byte

CounterEmpty	EQU		0				; Value for loop counter when empty

MaxHexStrSize	EQU		4				; Value for max size of Hex string (=<4)



; Queue Constants

MAX_Q_LENG	    EQU     512          ;Maxlength allowed for byte or word queue