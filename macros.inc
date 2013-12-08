$NOLIST

; EE51 Extra Credit 3
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
;   %CLR(reg)	clears the register reg (sets it to zero)
;   %SETBIT(reg, bit)	sets bit #bit in register reg
;   %CLRBIT(reg, bit)	clears bit #bit in register reg
;   %COMBIT(reg, bit)	complements bit #bit in register reg
;   %TESTBIT(reg, bit)	sets the zero flag based on bit #bit in register reg
;   %XLATW	translate the 16-bit value in AX to another 16-bit value (updating AX)
;            using the table pointed to by BX
;   %READPCB(addr)	read the PCB register at address addr and return the value in AX
;   %WRITEPCB(addr, val)	write the 16-bit value val to the PCB register at address addr
;
; Revision History
;    11/26/2013  Glen George         initial revision



; local include files
;   none




; CLR
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(CLR(reg))   (
        
        XOR     %reg, %reg              ;setup value to output

)

; XLATW_AX
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(XLATW_AX)   (
    
    ;PUSH    BX              ; Save BX
    SHL     AX, 1           ; Adjust relative pointer for WORD access
    ADD     BX, AX          ; Calc absolute address
    MOV     AX, CS:[BX]     ; Grab that element
    ;POP     BX              ; Restore BX and return AX.
)

; READPCB
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(READPCB(addr))   (
    
        MOV    DX, %addr               ;get the port number into DX
        IN     AX, DX                  ;output to the port
)

; WRITEPCB
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(WRITEPCB(addr, val))   (
  
        PUSH    AX                      ; Save used regs
        PUSH    DX                      ;  
        
        MOV     DX, %addr               ; Prepare to write to PCB @ addr
        MOV     AX, %val                ; Prepare the value to be written
        OUT     DX, AX                  ; Write word to that PCB
        
        POP     DX                      ;
        POP     AX                      ; restore used regs 
)
; OUTPORT8
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(OUTPORT8(port, value))   (
        MOV     AL, %value              ;setup value to output
        MOV     DX, %port               ;get the port number into DX
        OUT     DX, AL                  ;output to the port
)
; INPORT8_AL
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(INPORT8_AL(addr))   (
        MOV     DX, %addr               ;get the port number into DX
        IN      AL, DX                  ;output to the port
)
; OUTPORT8_AL
;
; Description:      This macro generates code to output an 8-bit value to an
;                   8-bit port.
;
; Operation:        The macro arguments are moved into DX and AL and an OUT
;                   instruction is executed.
;
; Arguments:        port  - port to which to write.
;                   value - 8-bit value to write to the port.
;
; Registers Used:   AL, DX
; Stack Depth:      0 words
;
; Author:           Glen George
; Last Modified:    Nov. 25, 1993

%*DEFINE(OUTPORT8_AL(port))   (
        MOV     DX, %port               ;get the port number into DX
        OUT     DX, AL                  ;output to the port
)



$LIST