$NOLIST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 MACRO.INC                                  ;
;                                 Include File                               ;
;                                 Anjian Wu                                  ;
;                                 TA: Pipe-Mazo                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains generally useful macros for the EE51.  The macros
; included are:
;
;   CLR(reg)	clears the register reg (sets it to zero)
;   XLATW_AX	translate the 16-bit value in AX to another 16-bit value (updating AX)
;               using the table pointed to by BX
;   INPORT8_AL (addr) read into AL from addr port
;   OUTPORT8_AL(addr) outputs AL into addr port
;
; Revision History
;    11/26/2013  Anjian Wu         initial revision



; local include files
;   none




; CLR
;
; Description:      This macro clears any reg
; Operation:        XOR that reg to itself
; Arguments:        reg  - which reg to clear
; Registers Used:   reg
; Stack Depth:      0 words
; Author:           Anjian Wu
; Last Modified:    11/26/2013

%*DEFINE(CLR(reg))   (
        
        XOR     %reg, %reg              ;setup value to output

)

; XLATW_AX
;
; Description:      Translate the 16-bit value in AX to another 16-bit value (updating AX)
;                   using the table pointed to by BX
;
; Operation:        Adjust AX for WORD look up, adds AX to BX to get absolute addr. THen
;                   moves that pointer addr's val into AX for return.
;
; Arguments:        None explicitly. Assumes AX and BX are ready.
; Registers Used:   AX, BX
; Stack Depth:      0 words
; Stack Depth:      0 words
; Author:           Anjian Wu
; Last Modified:    11/26/2013

%*DEFINE(XLATW_AX)   (
    
    ;PUSH    BX              ; Save BX
    SHL     AX, 1           ; Adjust relative pointer for WORD access
    ADD     BX, AX          ; Calc absolute address
    MOV     AX, CS:[BX]     ; Grab that element
    ;POP     BX              ; Restore BX and return AX.
)

; INPORT8_AL
;
; Description:      Reads in BYTE from port at address 'addr'
; Operation:        MOV addr arg into DX and read in val to AL for return
; Arguments:        addr  - port to which to read.
; Registers Used:   AL, DX
; Stack Depth:      0 words
; Author:           Anjian Wu
; Last Modified:    11/26/2013

%*DEFINE(INPORT8_AL(addr))   (
        MOV     DX, %addr               ;get the port number into DX
        IN      AL, DX                  ;output to the port
)
; OUTPORT8_AL
;
; Description:      Writes out BYTE to port at address 'addr'
; Operation:        MOV addr arg into DX and WRITEs out val in AL
; Arguments:        addr  - port to which to read. Also assume AL ready
; Registers Used:   AL, DX
; Stack Depth:      0 words
; Author:           Anjian Wu
; Last Modified:    11/26/2013

%*DEFINE(OUTPORT8_AL(addr))   (
        MOV     DX, %addr               ;get the port number into DX
        OUT     DX, AL                  ;output to the port
)



$LIST