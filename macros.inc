$NOLIST


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 MACRO.INC                                  ;
;                                 Include File                               ;
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
;    11/25/93  Glen George         initial revision
;    11/21/94  Glen George         updated comments
;    11/13/96  Glen George         updated comments
;    11/19/97  Glen George         updated comments
;    10/20/98  Glen George         updated comments
;    12/26/99  Glen George         updated comments
;     1/30/03  Glen George         updated comments



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

; SETBIT
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

%*DEFINE(SETBIT(reg, bit))   (
        
    %
)


$LIST