NAME        HW3



;Procedure:			QueueInit
;
;Description:      	This procedure will intialize the queue of passed length 'l',
;                   size ''s', and pointed address 'a'. It does this by simply
;                   setting the queue head and tail pinters to the same (zero).
;                   It will also store the length 'l' of the queue and size 's'
;                   on the data memory. 
;Operation:			
;
;Arguments:        	
;
;Return Values:    	None;
;
;Shared Variables: 	None.
;
;Local Variables:	i -> INT sign flag
;					temp -> INT current power of 10
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	None.
;
;Registers Used:	AX, SI (probably a lot others, but not sure yet)
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	None;
;
;Algorithms:       	Repeatedly mask off next hex digit and store.
;
;Limitations:  		Will always allocate 5 characters worth space in mem for 
;					return value (e.g. 0xF -> 0x000F).
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------




;Procedure:			QueueEmpty
;
;Description:      	This procedure will check the queue at address 'a' and 
;                   see if it is empty. It does this by checking whether
;                   The headpointer is equal to the tail pointer.
;                   If it is empty zeroflag -> true
;                   If it is not empty zeroflag -> reset
;
;Operation:			This code will convert a bin number from AX (n) and store 
;					the signed decimal value at 'a'.
;
;Arguments:        	n (AX) -> 16 - bit signed value
;					a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	error -> INT Error flag
;
;Shared Variables: 	None.
;
;Local Variables:	Sign -> INT sign flag
;					pwr10 -> INT current power of 10
;					error ->  INT Error flag
;					digit -> BCD each digit from algorithm
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Used:	AX, SI (probably a lot others, but not sure yet)
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;Algorithms:       	Repeatedly divide by powers of 10 and get the remainders
;                   (which are the BCD digits).
;
;Limitations:  		Only handles numbers less than 5 digits. Will always 			
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------


Dec2String		PROC    NEAR
				PUBLIC  Dec2String
				
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

        MOV     CX, 10000                ;start with 10^3 (1000's digit)
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
        MOV     AX, 0          ;
        MOV     DS:[SI], AL             ;Place the character in mem
        
        RET
       
Dec2String      ENDP    


;Procedure:			StoreDaChar
;
;Description:       This function returns the integer square root of the
;                   8-bit unsigned integer passed to the function.  The
;                   returned value is rounded to the nearest integer.
;
;Operation:         The passed integer is looked up in a table containing the
;                   square root of every integer (a 256 entry table).
;
; Arguments:         AL - unsigned value for which to compute the square root.
; Return Value:      AL - integer square root of the passed argument.
;
;
;Shared Variables: 	None.
;
;Local Variables:	Sign -> INT sign flag
;					pwr10 -> INT current power of 10
;					error ->  INT Error flag
;					digit -> BCD each digit from algorithm
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Changed: flags, BX.
;
;Stack Depth:		None.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;
;Algorithms:       	 Table lookup.
;
;Limitations:  		Only handles numbers less than 5 digits. Will always 			
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------

StoreDaChar		PROC    NEAR
				PUBLIC  StoreDaChar
                
                
        MOV	    BX, OFFSET(ASCIICharTable);point into the table of square roots
        XLAT	CS:ASCIICharTable		;get the square root   
        
        MOV     DS:[SI], AL             ;Place the character in mem
 ;       INC     SI                      ;Update the char pointer
        
        RET
        
StoreDaChar         ENDP

; ASCIICharTable
;
; Description:      This table contains the ASCII char of Hex 0 - F
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
