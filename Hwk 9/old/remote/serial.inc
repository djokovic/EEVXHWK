;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Serial.INC                         		;
;                              Serial Constants                             ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for timers and their interupts
;
; Revision History:
;    11/28/2013			Created - Anjian Wu
;    11/29/2013			Added a lot of constants, masks, comments - Anjian Wu

;General Serial Definitions

NO_PARITY           EQU  0   ;code for no parity
PARITY_ODD	        EQU  1   ;code for odd parity
PARITY_EVEN         EQU  2   ;code for even parity
PARITY_STICKY_CLR   EQU  3   ;code for sticky clr parity
PARITY_STICKY_SET   EQU  4   ;code for sticky set parity

BAUD_RATE           EQU  9600   ; The baud rate value

; Addresses
TX_ADDRESS      EQU		100H		    ;RX buff 
RX_ADDRESS      EQU     TX_ADDRESS      ;TX hold reg addr
IER_ADDRESS		EQU		101H    	    ;interrupt enable register addr
IIR_ADDRESS		EQU		102H		    ;interrupt identification register addr
LCR_ADDRESS		EQU		103H		    ;line control register addr
MCR_ADDRESS		EQU		104H		    ;modem control register addr
LSR_ADDRESS		EQU		105H		    ;line Status register addr
MSR_ADDRESS		EQU		106H            ;modem status register addr
SCR_ADDRESS		EQU		107H      		;scratch register addr
DLL_ADDRESS		EQU		100H    		;divisor latch LSB addr 
DLM_ADDRESS		EQU		101H    		;division latch MSB addr

Int2Vec		    EQU		14		        ;INT2 interrupt in vector table addr

INT2Ctrl        EQU     0FF3CH	        ;INT2 Control register I2CON addr

INT2_MASK_REG   EQU     00BDH	        ;AND Mask to enable INT2 from IMASK reg
IMASK_ADDR      EQU     0FF28H          ; 

; Control Register Values
INT2VAL         EQU		0011h   ;Value for INT2 control
                                ;00000000000-----  Reserved values
                                ;-----------0----  Level Trigger Mode (Edge)
                                ;------------0---  Int Mask (Unmasked)
                                ;-------------001  Priority (Set for 2nd highest)

INT2EOI         EQU     14      ; INT2 is type 14

; Serial Mask Values

RXINT_ON        EQU     01H             ; Enable RX int from IER (OR MASK)
                                        ;0000----  Reserved as cleared
                                        ;----0---  Modem Int Enable 
                                        ;-----0--  Receiver Line Int Enable 
                                        ;------0-  THRE Int Enable
                                        ;-------1  Receive RX Int Enable 
                                        
ERRINT_ON       EQU     00000100B       ; Enable Err int from IER (OR MASK)
                                        ;0000----  Reserved as cleared
                                        ;----0---  Modem Int Enable 
                                        ;-----0--  Receiver Line Int Enable 
                                        ;------0-  THRE Int Enable
                                        ;-------1  Receive RX Int Enable 
                                        
MODEM_ON       EQU     00001000B       ; Enable MODEM int from IER (OR MASK)
                                        ;0000----  Reserved as cleared
                                        ;----1---  Modem Int Enable 
                                        ;-----0--  Receiver Line Int Enable 
                                        ;------0-  THRE Int Enable
                                        ;-------0  Receive RX Int Enable 

THRE_OFF        EQU     11111101B       ; Disable THRE int from IER (AND MASK)
                                        ;1111----  Reserved as cleared (leave untouched)
                                        ;----1---  Modem Int Enable (leave untouched)
                                        ;-----1--  Receiver Line Int Enable (leave untouched)
                                        ;------0-  THRE Int Enable
                                        ;-------1  Receive RX Int Enable (leave untouched)
                                        
THRE_ON         EQU     00000010B       ; Enable THRE int from IER (OR MASK)
                                        ;0000----  Reserved as cleared (leave untouched)
                                        ;----0---  Modem Int Enable (leave untouched)
                                        ;-----0--  Receiver Line Int Enable (leave untouched)
                                        ;------1-  THRE Int Enable
                                        ;-------0  Receive RX Int Enable (leave untouched)
                                        
IIR_MASK        EQU     00000111B       ; Only lower 3 bits of IIR contains INT info (AND MASK)
                                        ;00000---  Reserved as cleared (leave untouched)
                                        ;-----???  Interrupt ID
                                        
ERROR_BIT_MASKS EQU     00011110B       ; For isolating 4 different types of error bits (AND MASK)
                                        ;0-------  Reserved as cleared (leave untouched)
                                        ;-0------  TEMT Empty (leave untouched)
                                        ;--0-----  THRE Empty (leave untouched)
                                        ;---1----  Break Int
                                        ;----1---  Framing Err
                                        ;-----1--  Parity Err
                                        ;------1-  Overrun Err
                                        ;-------0  Data Rdy (leave untouched)
                                        
DLAB_BIT_ON     EQU     10000000B       ; OR mask to turn on DLAB
                                        ;1-------  DLAB bit (TURN ON)
                                        ;-0------  Set Break (leave untouched)
                                        ;--0-----  Stick Parity (leave untouched)
                                        ;---0----  Even Parity (leave untouched)
                                        ;----0---  Enable Parity (leave untouched)
                                        ;-----0--  # of Stop Bits (leave untouched)
                                        ;------00  worth length (leave untouched)
                                        
DLAB_BIT_OFF    EQU     01111111B       ; AND mask to turn off DLAB
                                        ;0-------  DLAB bit (TURN OFF)
                                        ;-1------  Set Break (leave untouched)
                                        ;--1-----  Stick Parity (leave untouched)
                                        ;---1----  Even Parity (leave untouched)
                                        ;----1---  Enable Parity (leave untouched)
                                        ;-----1--  # of Stop Bits (leave untouched)
                                        ;------11  worth length (leave untouched)
                                        
PARITY_BITS            EQU  11000111B   ; AND MASK to clear all parity bits
                                        ;1-------  DLAB bit (leave untouched)
                                        ;-0------  Set Break (leave untouched)
                                        ;--0-----  Stick Parity
                                        ;---0----  Even Parity
                                        ;----1---  Enable Parity
                                        ;-----1--  # of Stop Bits (leave untouched)
                                        ;------11  worth length (leave untouched)
                                        
NO_PARITY_MASK         EQU  00000000B   ;no parity is generated or checked
PARITY_ODD_MASK 	   EQU  00001000B   ;odd parity (an odd number of logic 1's)
PARITY_EVEN_MASK       EQU  00011000B   ;even parity (an even number of logic 1's)
PARITY_STICKY_CLR_MASK EQU  00111000B   ;parity bit is transmitted and checked as cleared
PARITY_STICKY_SET_MASK EQU  00101000B   ;parity bit is transmitted and checked as set
; Table below shows bits used for all PARITY OR masks
                                        ;0-------  DLAB bit (leave untouched)
                                        ;-?------  Set Break (leave untouched)
                                        ;--?-----  Stick Parity
                                        ;---?----  Even Parity
                                        ;----0---  Enable Parity
                                        ;-----0--  # of Stop Bits (leave untouched)
                                        ;------00  worth length (leave untouched)
                                        
WORD_LENTH_BITS        EQU  00000011B   ;Bits to OR MASK ON for Word length
                                        ;0-------  DLAB bit (leave untouched)
                                        ;-0------  Set Break (leave untouched)
                                        ;--0-----  Stick Parity (leave untouched)
                                        ;---0----  Even Parity (leave untouched)
                                        ;----0---  Enable Parity (leave untouched)
                                        ;-----0--  # of Stop Bits (leave untouched)
                                        ;------11  WORD LENGTH, set for 8 bits

STOP_BITS              EQU  00000000B   ;Bits to OR MASK ON for Word length
                                        ;0-------  DLAB bit (leave untouched)
                                        ;-0------  Set Break (leave untouched)
                                        ;--0-----  Stick Parity (leave untouched)
                                        ;---0----  Even Parity (leave untouched)
                                        ;----0---  Enable Parity (leave untouched)
                                        ;-----0--  # of Stop Bits (ONE STOP BIT)
                                        ;------00  WORD LENGTH (leave untouched)
; Serial Register Values
                        
div_rate        EQU     5               ; 9.216 MHz /115200/16 = 5

SERIAL_NO_INT   EQU     00000001B       ; Value of IIR for NO more interrupts pending
                                        ;00000---  Reserved as cleared (leave untouched)
                                        ;-----???  Interrupt ID

