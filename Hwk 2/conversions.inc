;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  conversions.INC                           ;
;                           String Conversion Constants                    	 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timing functions for the 8088
; version of the Microprocessor-Based Clock.
;
; Revision History:
;    10/23/2013			Created - Anjian Wu



; ASCII Constants

ASCII_NULL      EQU     0              ;interrupt vector for timer



; General Definitions

Hex2StrMASK     EQU     000FH           ;number of interrupts per second * 10
ByteSize        EQU     4               ; 4 Bits in a byte