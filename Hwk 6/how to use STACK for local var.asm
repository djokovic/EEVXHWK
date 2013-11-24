; Bin2BCD
;
;
; Description:      This function converts the 16-bit binary value passed to
;                   it to BCD (4-digits) and returns that result.  If there
;                   is an overflow (the number is bigger than 9999), the carry
;                   flag is set.  The number is assumed to be positive.
;
; Operation:        The function starts with the largest power of 10 possible
;                   (1000) and loops dividing the number by the power of 10,
;                   the quotient is a digit and the remainder is used in the
;                   next iteration of the loop.  Each loop iteration divides
;                   the power of 10 by 10 until it is 0.  At that point the
;                   number has been converted to BCD.
;
; Arguments:        arg (SP+2) - binary value to convert to BCD.
; Return Values:    AX         - BCD of passed binary value.
;                   CF         - set to 1 if passed value > 9999 (decimal), 0
;                                otherwise.
;
; Local Variables:  digit (AX)    - computed BCD digit.
;                   error (CF)    - error flag.
;                   pwr10 (SP-2)  - current power of 10 being computed.
;                   result (SP-4) - BCD result from conversion.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   If the number to be converted is greater than 9999 the
;                   carry flag is set and a meaningless value is returned.
;
; Registers Used:   flags, AX
; Stack Depth:      5 words
;
; Algorithms:       Repeatedly divide by powers of 10 and get the remainders
;                   (which are the BCD digits).
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      Can only handle positive numbers which are less than 9999.
;
; Revision History: 10/19/94   Glen George      initial revision
;                   10/18/95   Glen George      updated comments
;                   10/28/96   Glen George      updated comments
;                   10/29/97   Glen George      fixed bug in assembly language
;                                                  implementation (non-zero
;                                                  remainder when divide by
;                                                  10)
;                                               updated comments
;                   12/26/99   Glen George      updated comments
;                   12/25/00   Glen George      updated comments
;                    1/28/02   Glen George      updated comments
;                    1/27/03   Glen George      updated comments



;Argument equates (include the return address (1 word) and BP (1 word)).
arg     EQU     WORD PTR [BP + 4]
pwr10   EQU     WORD PTR [BP - 2]
result  EQU     WORD PTR [BP - 4]

;local variables - 2 words
LocalVarSize    EQU     4


Bin2BCD         PROC    NEAR
                PUBLIC  Bin2BCD


Bin2BCDInit:                            ;initialization
        PUSH    BP                      ;save BP
        MOV     BP, SP                  ;and get BP pointing at our stack frame
        SUB     SP, LocalVarSize        ;save space on stack for local variables

        PUSH    CX                      ;save registers
        PUSH    DX

        MOV     result, 0               ;result starts at 0
        MOV     pwr10, 1000             ;start with 10^3 (1000's digit)
        CLC                             ;no error yet
        ;JMP    Bin2BCDLoop             ;now start looping to get digits


Bin2BCDLoop:                            ;loop getting the digits in arg

        JC      EndBin2BCDLoop          ;if there is an error - we're done
        CMP     pwr10, 0                ;check if pwr10 > 0
        JLE     EndBin2BCDLoop          ;if not, have done all digits, done
        ;JMP    Bin2BCDLoopBody         ;otherwise get the next digit

Bin2BCDLoopBody:                        ;get a digit of the BCD

        MOV     DX, 0                   ;setup to divide by pwr10
        MOV     AX, arg
        DIV     pwr10                   ;digit (AX) = arg/pwr10
        CMP     AX, 10                  ;check if digit < 10
        JAE     TooBigError             ;if not, it's an error
        ;JB     HaveDigit               ;otherwise process the digit

HaveDigit:                              ;put the digit in the result
        SHL     result, 4               ;need to shift result to make room for the digit
        OR      result, AX              ;actually or in the digit
        MOV     arg, DX                 ;now work with arg = arg MODULO pwr10
        MOV     AX, pwr10               ;setup to update pwr10
        MOV     CL, 10
        DIV     CL                      ;   note: pwr10/10 <= 100 so fits
        MOV     AH, 0                   ;clear out remainder (not 0 if AX was 1)
        MOV     pwr10, AX               ;now pwr10 = pwr10/10
        CLC                             ;no error
        JMP     EndBin2BCDLoopBody      ;done getting this digit

TooBigError:                            ;the value was too big
        STC                             ;set the error flag
        ;JMP    EndBin2BCDLoopBody      ;and done with this loop iteration

EndBin2BCDLoopBody:
        JMP     Bin2BCDLoop             ;keep looping (end check is at top)


EndBin2BCDLoop:                         ;done converting
        MOV     AX, result              ;move result into return value

        POP     DX                      ;restore registers
        POP     CX
        ADD     SP, LocalVarSize        ;remove local variables from stack
        POP     BP                      ;restore BP
        RET     2                       ;and return (releasing stack space)


Bin2BCD         ENDP