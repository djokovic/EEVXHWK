NAME        HW2TEST

; local include files
$INCLUDE(conv.inc)

;Procedure:			Hex2String
;
;Description:      	This procedure will convert a value ‘n’ into a hex that 		
;					is fixed at 4 characters and stores are string.
;
;                   If the Hex is less than 4 chars long, zeros are fitted
;
;					String will be <null> terminated. The string is stored at 
;					a memory location indicated by 'a'. AX - 'n', SI - 'a'.
;
;
;
;Operation:			This code will convert a hex number from AX (n) and store 
;					the signed ASCII values at 'a'. For convenience, the storing
;                   is done in REVERSE (i.e from SI + HExMaxsize down to SI, this
;                   includes ASCII_NULL).
;
;                   The procedure to actually store each char is done by calling
;                   the StoreDaChar(byte AL) function. See StoreDaChar for more 
;                   details.
;
;Arguments:        	n (AX) -> 16 - bit  value
;					a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	None;
;
;Shared Variables: 	None.
;
;Local Variables:	AX -> Holds arg, shifted arg, and masked arg
;					DX -> Holds shifted arg, used to place ASCII_NULL
;                   CX -> While loop counter
;                   SI -> String pointer
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	Fixed 4 char string starting at SI and ending at SI + 5 (
;                   including ASCII_NULL)
;
;Registers Changed: Flags
;
;Stack Depth:		5 words (4 push/pops and 1 call)
;
;Known Bugs:		None :D
;
;Data Structures:	None.
;
;Error Handling:   	If is less than CounterEmpty, the loop terminates as well;
;
;Algorithms:       	1. Mask off least sig BYTE
;                   2. Call StoreDaChar
;                   3. Update pointer (DEC)
;                   4. Shift Arg down 4 bits
;                   5. Update counter (DEC)
;                   5. LOOP until counter is empty
;
;Limitations:  		Will always allocate 5 characters worth space in mem for 
;					return value (e.g. 0xF -> 0x000F). 
;
;                   Cannot store any Hex greater than 4 chars.
;
;Author:			Anjian Wu
;History:			Pseudo code: 10-21-2013
;                   Intial working: 10/23/2013
;                   Documentation Update: 10/24/2013
;-------------------------------------------------------------------------------

CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

Hex2String		PROC    NEAR
				PUBLIC  Hex2String

        PUSH    AX
        PUSH    DX
        PUSH    CX
        PUSH    SI

HexINIT:

        MOV     CX, MaxHexStrSize   ; Counter should loop fixed Hex size of 4
        ADD     SI, MaxHexStrSize   ; Reverse insertion of chars means start at ASCII_NULL
        
        MOV     DX, ASCII_NULL      ; Place ASCII NULL
        MOV     DS:[SI], DL         ; Store
        DEC     SI;                 ; Update pointer
        
        MOV     DX, AX              ; Save the arg

        
HexLoop: 
        CMP     CX, CounterEmpty    ;Is the while loop done when counter is empty.
        JLE     Hex2StringEND       ;Yes, thus exit loop
        ;JG     HexLoopBody         ; NO continue to body
        
HexLoopBody:        
		AND     AX, Hex2StrMASK     ;Mask the last byte (4 bits)
        
        CALL    StoreDaChar         ;Store Char, Note BX is changed
        DEC     SI                  ;Update pointer
        
        SHR     DX, ByteSize        ;Shift off the last byte
        MOV     AX, DX              ;update the ARG
        
        DEC     CX                  ;Decrement the counter
		
        JMP     HexLoop             ;Loop

Hex2StringEND:
	
        POP    SI
        POP    CX
        POP    DX
        POP    AX
        
        RET
Hex2String ENDP


;Procedure:			Dec2String
;
;Description:      	This procedure will convert a value ‘n’ into a decimal that 		
;					is at most 6 characters (with sign) and stores are string.
;
;					String will be <null> terminated. The string is stored at 
;					a memory location indicated by 'a'. AX - 'n', SI - 'a'.
;                   The string is than store from SI to SI + 5
;
;					Assume we store first digit first, and <null> last.
;
;                   For positive integers, there will be NO sign designation.
;
;                   For neg integers, a "-" char is placed before the number.
;
;                   Actually calls external function StoreDaChar to store the char
;                   see that function for more details.
;
;
;Operation:			This code will convert a bin number from AX (n) and store 
;					the signed decimal value at 'a'.
;
;                   It does this by the following steps
;                   1. Check sign and places sign if needed
;                   2. Continually divide the ARG by a PWR10 (starting with 10000
;                   and decrementing by a factor of 10) and grabbing the digit 
;                   to be placed.
;                   3. Call the StoreDaChar function to store the char
;                   4. Repeat until the PWR10 counter is 0.
;                   5. Add the ASCII_NULL
;
;Arguments:        	n (AX) -> 16 - bit signed value
;					a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	Error Flag
;
;Shared Variables: 	None.
;
;Local Variables:	AX -> arg, char digit, used for storing DIV answer
;					BX -> stores arg, when AX is used 
;					CX -> PWR10 counter
;					DX -> Stores Remainder from DIV
;                   SI -> String pointer
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Changed:	Flags
;
;Stack Depth:		6 (5 push pops and 1 CALL)
;
;Known Bugs:		None :D
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;
;Algorithms:        1. Continually divide the ARG by a PWR10 (starting with 10000
;                   and decrementing by a factors of 10) and grabbing the digit 
;                   to be placed.
;                   2. Call the StoreDaChar function to store the char digit
;                   3. Repeat until the PWR10 counter is 0.
;
;Limitations:  		Only handles numbers less than 5 digits. Will always 			
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;
;Author:			Anjian Wu
;
;History:			Pseudo code: 10-21-2013
;                   Intial working: 10/23/2013
;                   Documentation Update: 10/24/2013
;-------------------------------------------------------------------------------


Dec2String		PROC    NEAR
				PUBLIC  Dec2String

        PUSH    AX                      ; Store Registers used
        PUSH    DX
        PUSH    CX
        PUSH    SI
        PUSH    DX
        
DecSignCheck:

		CMP     AX, 0                   ; Check to see if Num is neg
        JGE     DecIsPos                ; Num is not neg, thus no '-' needed
        ;JL                             ; Num is neg, need 2's complement and '-' 
DecIsNeg:
        NEG     AX                      ;
        MOV     BL, '-'                 ;
        MOV     DS:[SI], BL             ;Place the character in mem
        INC     SI                      ;Update the char pointer
       
        JMP     Bin2BCDInit             ;
DecIsPos:
        MOV     BL, '0'                 ;
        MOV     DS:[SI], BL             ;

        INC     SI                      ;Update the char pointer
		;JMP    Bin2BCDInit
        
Bin2BCDInit:                            ;initialization
        MOV     BX, AX                  ;BX = arg. Save the arg

        MOV     CX, 10000               ;start with 10^3 (10000's digit)
        CLC                             ;no error yet
        ;JMP    Bin2BCDLoop             ;now start looping to get digits


Bin2BCDLoop:                            ;loop getting the digits in arg

        JC      Dec2StringEND          ;if there is an error - we're done
        CMP     CX, 0                   ;check if pwr10 > 0
        JLE     Dec2StringEND          ;if not, have done all digits, done
        ;JMP    Bin2BCDLoopBody         ;else get the next digit

Bin2BCDLoopBody:                        ;get a digit
        MOV     AX, BX
        MOV     DX, 0                   ;setup for arg/pwr10 remainder

        DIV     CX                      ;digit (AX) = arg/pwr10
        CMP     AX, 10                  ;check if digit < 10
        JAE     TooBigError             ;if not, it's an error
        ;JB     HaveDigit               ;otherwise process the digit

HaveDigit:                              ;put the digit into the result
      
        CALL    StoreDaChar             ;Store Char, BX is changed, but that's OK
        INC     SI                      ;Update the char pointer
        
DecUpdatePWR10:

        MOV     BX, DX                  ;now work with arg = arg MODULO pwr10
        MOV     AX, CX                  ;setup to update pwr10
        MOV     CX, 10                  ;   (clears CH too)
        MOV     DX, 0                   ;setup for arg/pwr10 remainder   
        DIV     CX                      ;   (note: pwr10/10 <= 100 so no overflow)
        MOV     CX, AX                  ;pwr10 = pwr10/10 (note: CH = 0)
        CLC                             ;no error
        JMP     EndBin2BCDLoopBody      ;done getting this digit

TooBigError:                            ;the value was too big
        STC                             ;set the error flag
        ;JMP    EndBin2BCDLoopBody      ;and done with this loop iteration

EndBin2BCDLoopBody:
        JMP     Bin2BCDLoop             ;keep looping (end check is at top)

Dec2StringEND:
        MOV     AX, ASCII_NULL          ;
        MOV     DS:[SI], AL             ;Place the character in mem
       
        POP    DX                       ; Restore registers used
        POP    SI
        POP    CX
        POP    DX
        POP    AX
        
        RET
       
Dec2String      ENDP    


;Procedure:			StoreDaChar
;
;Description:       This function takes AL and SI as the args. AL maps to its corresponding
;                   ASCII char. It will then take this char and store it at DS:SI
;
;Operation:         The passed integer is looked up in a table containing the
;                   ASCII char of every HEX char (from '0' to 'F').
;
; Arguments:         AL -> unsigned value for which to compute the square root.
;
; Return Value:      AL -> becomes last placed Char
;
;
;Shared Variables: 	None.
;
;Local Variables:	AL -> INT sign flag
;					BX -> INT current power of 10
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	A CHAR at (DS:SI)
;
;Registers Changed: flags, AL becomes last placed Char.
;
;Stack Depth:		1 WORD
;
;Known Bugs:		None :D
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;
;Algorithms:       	Table lookup.
;
;Limitations:  		None.

;Author:			Anjian Wu
;History:			Pseudo code: 10-21-2013
;                   Intial working: 10/23/2013
;                   Documentation Update: 10/24/2013
;-------------------------------------------------------------------------------

StoreDaChar		PROC    NEAR
				PUBLIC  StoreDaChar

        PUSH    BX

                
        MOV	    BX, OFFSET(ASCIICharTable);point into the table of square roots
        XLAT	CS:ASCIICharTable		;get the square root   
        
        MOV     DS:[SI], AL             ;Place the character in mem

        POP     BX
        RET
        
StoreDaChar         ENDP

; ASCIICharTable
;
; Description:      This table contains the ASCII char of Hex 0 - F in code segment
;
; Author:           Anjian Wu
; Last Modified:    10-23-2013


ASCIICharTable	LABEL	BYTE

	DB	 '0'
    DB	 '1'
    DB	 '2'
    DB	 '3'
    DB	 '4'
    DB	 '5'
    DB	 '6'
    DB	 '7'
    DB	 '8'
    DB	 '9'
    DB	 'A'
    DB	 'B'
    DB	 'C'
    DB	 'D'
    DB	 'E'
    DB	 'F'
    
CODE ENDS

        END
