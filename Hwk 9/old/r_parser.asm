NAME        Parser

$INCLUDE(macros.inc);
$INCLUDE(parser.inc);
$INCLUDE(general.inc);
$INCLUDE(motors.inc); 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW8 Parser Functions                       ;
;                                 EE51                                  	 ;
;                                 Anjian Wu                                  ;
;                                                                            ;
;                                 TA: Pipe-Mazo                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;                          Code Segment (* indicates public)
;
;   ParseSerialChar*     -   Passed a char for processing in FSM
;   ParseReset*          -   Resets all Parser variables
;   GetTokenTypeVal      -   Grabs next token val and type
;   Concat_Num           -   Used to prepare passed args to Motor Vars from 
;                            parsed chars.
;   FSM ACTION Functions:
;   no_op               -   Just returns
;   SetSpeed            -   Handles absolute speed setting
;   SetRelSpeed         -   Handles relative speed setting
;   SetDir              -   Handles direction setting
;   RotRelTurrAng       -   Handles rel turret rotation setting
;   RotAbsTurrAng       -   Handles abs turret rotation setting
;   SetTurrEleAng       -   Handles turrent ele angle setting
;   SetSign             -   Sets the sign accordingly
;   SetError            -   Sets the errorflag
;   LaserON             -   Turns laser ON
;   LaserOff            -   Turns laser OFF
;
;                                   Data Segment
;
;   sign                -   Stores the sign of the num being processed
;   magnitude           -   Stores the universal magnitude (can be speed, angle
;                           ,etc.)
;   errorflag           -   Stores errors
;   FSM_state           -   Stores the current state
;
;                              What's was last edit?
;
;       			Pseudo code     ->  12-01-2013 - Anjian Wu
;                   Wrote Assembly  ->  12-04-2013 - Anjian Wu
;                   Wrote Assembly  ->  12-05-2013 - Anjian Wu
;                   Working         ->  12-08-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   SetMotorSpeed:NEAR          ; Sets motor speed and angle
        EXTRN   GetMotorSpeed:NEAR          ; Grabs abs speed
        EXTRN   GetMotorDirection:NEAR      ; Grabs movement angle
        EXTRN   SetLaser:NEAR               ; Sets laser on or off
        EXTRN   GetLaser:NEAR               ; Gets laser status
		EXTRN   SetTurretAngle:NEAR         ; Change abs turret angle
        EXTRN   GetTurretAngle:NEAR         ; Get abs turret angle
        EXTRN   SetRelTurretAngle:NEAR      ; Change relative turret angle
		EXTRN   SetTurretElevation:NEAR     ; Set turret ele angle
		EXTRN   GetTurretElevation:NEAR     ; Get current ele angle


;Procedure:			ParseRemoteChar
;
;Description:      	Used pass char in AX to grab NEXT token val and type, and uses
;                   that to calc the proper pointer to the function to be called
;                   by the state machine. The token TYPE is used to find the abs
;                   action function offset and the token TYPE is always passed as
;                   (AL) into the action function. The action function, however, may
;                   or may not use the passed token val. The next FSM state is also
;                   saved in a shared variable FSM_state for the next time.
;
;                   If the state machine returns to ST_INITIAL then it also resets 
;                   the parser variables. If there is an error detected after the action
;                   function is call, then the function will also reset the parser 
;                   variables.
;                   
;                   This function always returns error status in AX. See 'Error Handling'.
;
;Operation:         * Clear Errorflag, grab next token val and key using GetTokenTypeVal.
;                   * offset = (NUM_TOKEN_TYPES * FSM_State + token type)* SIZE TRANSITION_ENTRY
;                   * Call Function (Action) using offset, passing token val in AL
;                   * If Errorflag is true, store FSM_state and FSM_ERROR bytes into AX for return
;                       * Call ParseReset
;                   * Else, grab nextstate using offset, store the next state into FSM_state
;                       * If next state is ST_INITIAL, then Call ParseReset
;                   * Return Errorflag in AX 
;
;Arguments:        	AL   -> The next char to be parsed
;
;Return Values:    	AX - > The errorflag
;
;Shared Variables: 	Errorflag (WRITE/READ)
;                   FSM_state (READ/WRITE)
;
;Local Variables:	AL      -   token val, char
;                   AH      -   token type
;                   AX      -   error, char
;                   BX      -   table offset
;                   DH      -   save token type
;                   CH      -   save token val
;                   
;                   
;Global Variables:	None.					
;Input:            	none.
;Output:           	none.
;Registers Used:	AX, BX, CH, DH
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	Errors come in two ways:
;                   FSM TYPE 1. Symbol/Char error -> NEXTSTATE already is ST_INITIAL
;                   FSM TYPE 2. Value error  -> NEXTSTATE may or may not be ST_INITIAL
;                   These errors are treated the same in that the return value AX
;                   will contain the FSM_State in AL and the FSM_ERROR key in AH. The FSM
;                   will also RESET immediately if error is seen.
;
;Algorithms:        Call Table FSM look up. Table offset = NUM_TOKEN_TYPES * FSM_State + token type
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;					12-04-2013: Modified from Glen's floatptd.asm - Anjian Wu 
;                   12-08-2013: Working - Anjian Wu
;------------------------------------------------------------------------------

ParseRemoteChar		PROC	NEAR
					PUBLIC 	ParseRemoteChar

ParseSerialInit:

    PUSH 	DX       ; Save all Regs
	PUSH 	BX
	PUSH	CX		
	
    MOV	Errorflag, FALSE	    ;Assume no errors
	
ParseGrabTokens:	
	CALL	GetTokenTypeVal	        ; Grab next token key and val
	MOV		DH, AH			    ; Save token type
	MOV		CH, AL			    ; Save token val
	
ParseComputeTrans:		        ;figure out what transition to do
	MOV		AL, NUM_TOKEN_TYPES	;find row in the table
	MUL		FSM_State           ;Get to current FSM state
	ADD		AL, DH		        ;Calc abs transition inside that state
	ADC		AH, zero		     ;propagate low byte carry into high byte

	IMUL	BX, AX, SIZE TRANSITION_ENTRY   ;now convert to table offset

ParseDoActions:				    ;do the actions (don't affect regs)

	MOV		AL, CH			    ;Pass Token Val (not always used by ACTION)
	CALL	CS:RemoteFSMTable[BX].ACTION	;do the actions

ParseCheckError:
    CMP     Errorflag, TRUE     ; Was there an error from the FSM action?
                                ; Errors can come in two ways
                                ; FSM TYPE 1. Symbol/Char error -> NEXTSTATE already is ST_INITIAL
                                ; FSM TYPE 2. Value error  -> NEXTSTATE may or may not be ST_INITIAL
    JNE     ParseNextTransition ; Nope, so grab the next one
    ;JE     ParseRecordError    ; There was an error
    
ParseRecordError:
    MOV     AL, FSM_State       ; Store the current state before it is updated 
                                ; since it where there that error was found
    MOV     AH, FSM_ERROR       ; Indicate that this was an FSM error (This
                                ; differentiates a value of FALSE vs. error in FSM_State = 0)
                                
    MOV     Errorflag, AX       ; Store that state as an error-type
    JMP     ParseNeedReset      ; We just got error, thus immediately exit this cmd path
                                ; and go back to ST_INITIAL to wait for VALID next cmd.
                                ; * Notice this IS redundant for FSM TYPE 1 errors since nxt state
                                ;   is already ST_INITIAL, however
                                ;   we treat all errors the same to simplify code.
    
ParseNextTransition:			;now go to next state

	MOV		CL, CS:RemoteFSMTable[BX].NEXTSTATE
    MOV     FSM_state, CL   ; We need this nextstate stored for next time.
    
	CMP		FSM_state, ST_INITIAL	; Did the state machine restart?
	JNE		ParseDone	    ; If not then just continue.
	;JE		ParseNeedReset	; Else we need to reset some parser variables
ParseNeedReset:
	CALL	RemoteParseReset; Reset parser variables (FSM_STATE, magnitude, sign)
    ;JMP    ParseDone       ;
ParseDone:
    MOV     AX, Errorflag       ; Restore the error (if any) back into AX for return
                                ; AH - whether or not error happened, AL - FSM_state (if error)
    
	POP  CX
	POP	 BX
	POP  DX                     ; Restore used regs
	
    
    RET
    
ParseRemoteChar ENDP

; GetTokenTypeVal
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits because the table only has 127 ASCII chars inside.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX - table pointer, points at lookup tables.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Used:   AX, BX.
; Stack Depth:      0 words.
;
; Author:           Anjian Wu
; Last Modified:    12-02-2013: Adapted from Glen's floatptd.asm - Anjian Wu :)
;                   12-08-2013: Add documentation to show understanding - Anjian Wu


GetTokenTypeVal	PROC    NEAR


InitGetFPToken:				;setup for lookups
	AND	AL, TOKEN_MASK		;strip unused bits (high bit) ONLY 127 CHARS IN TABLE
	MOV	AH, AL			    ;and preserve value in AH

; TokenTypeTable and TokenValueTable's values are paired/mapped one to one

TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable	        ;have token type in AL
	XCHG	AH, AL			            ;token type in AH, character in AL

TokenValueLookup:			             ;get the token value
    MOV     BX, OFFSET(TokenValueTable)  ;BX points at table
	XLAT	CS:TokenValueTable	         ;have token value in AL


EndGetFPToken:                     	     ;done looking up type and value
        RET


GetTokenTypeVal	ENDP


;Function:			RemoteParseInit
;Description:      	Resets all Parser variables to initial state, zero magnitude, and pos sign     
;Operation:         * Set sign as POS, set FSM_state as ST_INITIAL, and set magnitude as zero         
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	none.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
RemoteParseInit  PROC    NEAR
            
    MOV     Dir_PTR, zero               ; Set default val as positive
    MOV     Spd_PTR, zero               ; Set Default FSM machine state
    
    MOV     Action_Buff_PTR, OFFSET(KeyDisplayTable)+INITKEYMSG ; 
    MOV     Error_Buff_PTR, OFFSET(SerErrTable) ;
    
    XOR     BX, BX                      ; Clear Counter
        
RemoteParseInitBufClear:

    CMP     BX, DISP_LENGTH             ; For each motor PWM counter
    JGE     RemoteParseInitBufClearDone ; If each done, then leave loop
    
    MOV     Dir_Buffer[BX], ASCII_NULL  ; Should NOT be moving
    MOV     Spd_Buffer[BX], ASCII_NULL  ; Should NOT be moving

    INC     BX                          ; Increment counter/motor index
    JMP     MOTORINITClearPWMvars       ; Loop until all entries are cleared
    
RemoteParseInitBufClearDone:

	RET
	
RemoteParseInit  ENDP  

;Function:			RemoteParseReset
;Description:      	Resets all Parser variables to initial state, zero magnitude, and pos sign     
;Operation:         * Set sign as POS, set FSM_state as ST_INITIAL, and set magnitude as zero         
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	none.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
RemoteParseReset  PROC    NEAR
            
    MOV     Dir_PTR, zero               ; Set default val as positive
    MOV     Spd_PTR, zero               ; Set Default FSM machine state
    
	RET
	
RemoteParseReset  ENDP                   

;Procedure:			SetError
;
;Description:      	An error has occurred, so set the error flag true.
;
;Operation:         * Errorflag = TRUE
;        
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	Errorflag(write)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AH, AL
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SetError        PROC    NEAR

    MOV     Errorflag, TRUE     ; An error has occurred

    RET
    
SetError ENDP

;Procedure:			no_op
;
;Description:      	Just return (stub function)
;        
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
no_op        PROC    NEAR

    RET
    
no_op   ENDP

;Procedure:			AddDirChar
;
;Description:      	Turns the laser ON
;
;Operation:         * SetLaser(TRUE)
;                
;Arguments:         None.
;Return Values:    	None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
AddDirChar    PROC    NEAR

    PUSH    BX

    CMP     Dir_Ptr, DISP_LENGTH    ;
    
    JG      AddDirCharDone          ;

    MOV     BX, Dir_PTR             ;
 
    MOV     Dir_Buffer[BX], AL     ;
    
    INC     Dir_PTR                 ;
    
AddDirCharDone:
    POP     BX                      ;

    RET                     ;

AddDirChar    ENDP

;Procedure:			AddSpeedChar
;
;Description:      	Turns the laser OFF
;
;Operation:         * SetLaser(FALSE)  
;Arguments:         None.
;Return Values:    	None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
AddSpeedChar    PROC    NEAR

    PUSH    BX

    CMP     Spd_Ptr, DISP_LENGTH    ;
    
    JG      AddDirCharDone          ;

    MOV     BX, Spd_Ptr             ;
 
    MOV     Spd_Buffer[BX], AL     ;
    
    INC     Spd_Ptr                 ;
    
AddSpeedCharDone:

    POP     BX
    
    RET                     ;

AddSpeedChar    ENDP

; RemoteFSMTable
;
; Description:      This is the state transition table for the robot side.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Anjian Wu
; Last Modified:    12-10-2013: Initial Version - Anjian Wu


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act) >
)


RemoteFSMTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_INITIAL: Waiting for status    
	                                    ;Input Token Type
	%TRANSITION(ST_SPEED, no_op)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_DIR, no_op)	        ;TOKEN_D - Set Dir
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_NUM - A digit or ASCII_NULL
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_END - C Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	
	
	;Current State = ST_SPEED: Grab speed chars   
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D - Set Dir
	%TRANSITION(ST_SPEED, AddSpeedChar) ;TOKEN_NUM - A digit
	%TRANSITION(ST_INITIAL, no_op)	    ;TOKEN_END - C Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	
	
	;Current State = ST_DIR: Grab speed chars   
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D - Set Dir
	%TRANSITION(ST_DIR, AddDirChar)	    ;TOKEN_NUM - A digit or ASCII_NULL
	%TRANSITION(ST_INITIAL, no_op)		;TOKEN_END - C Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	

	
; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Anjian Wu
; Last Modified:    12-02-2013
; Last Modified:    12-05-2013: Just made Laser tokens return True/False - Anjian Wu
%*DEFINE(TABLE)  (
        %TABENT(TOKEN_NUM, 0)	;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_OTHER, 9)    ;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_END, 13)	    ;carriage return
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_OTHER, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_OTHER, POS)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_OTHER, NEGA)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_NUM, 0)	    ;0  (digit)
        %TABENT(TOKEN_NUM, 1)		;1  (digit)
        %TABENT(TOKEN_NUM, 2)		;2  (digit)
        %TABENT(TOKEN_NUM, 3)		;3  (digit)
        %TABENT(TOKEN_NUM, 4)		;4  (digit)
        %TABENT(TOKEN_NUM, 5)		;5  (digit)
        %TABENT(TOKEN_NUM, 6)		;6  (digit)
        %TABENT(TOKEN_NUM, 7)		;7  (digit)
        %TABENT(TOKEN_NUM, 8)		;8  (digit)
        %TABENT(TOKEN_NUM, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_D     , 'D')	;D
        %TABENT(TOKEN_OTHER     , 'E')  ;E 
        %TABENT(TOKEN_OTHER     , TRUE)	;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_OTHER , FALSE)	;O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S     , 'S')	;S
        %TABENT(TOKEN_OTHER, 'T')	;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_OTHER, 'V')	    ;V
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_D     , 'd')	;d
        %TABENT(TOKEN_OTHER     , 'e')	;e  
        %TABENT(TOKEN_OTHER     , TRUE)	;f
        %TABENT(TOKEN_OTHER , 'g')	;g
        %TABENT(TOKEN_OTHER , 'h')	;h
        %TABENT(TOKEN_OTHER , 'i')	;i
        %TABENT(TOKEN_OTHER , 'j')	;j
        %TABENT(TOKEN_OTHER , 'k')	;k
        %TABENT(TOKEN_OTHER , 'l')	;l
        %TABENT(TOKEN_OTHER , 'm')	;m
        %TABENT(TOKEN_OTHER , 'n')	;n
        %TABENT(TOKEN_OTHER     , FALSE)	;o
        %TABENT(TOKEN_OTHER , 'p')	;p
        %TABENT(TOKEN_OTHER , 'q')	;q
        %TABENT(TOKEN_OTHER , 'r')	;r
        %TABENT(TOKEN_S     , 's')	;s
        %TABENT(TOKEN_OTHER , 't')	;t
        %TABENT(TOKEN_OTHER , 'u')	;u
        %TABENT(TOKEN_OTHER     , 'v')	;v
        %TABENT(TOKEN_OTHER , 'w')	;w
        %TABENT(TOKEN_OTHER , 'x')	;x
        %TABENT(TOKEN_OTHER , 'y')	;y
        %TABENT(TOKEN_OTHER , 'z')	;z
        %TABENT(TOKEN_OTHER , '{')	;{
        %TABENT(TOKEN_OTHER , '|')	;|
        %TABENT(TOKEN_OTHER , '}')	;}
        %TABENT(TOKEN_OTHER , '~')	;~
        %TABENT(TOKEN_OTHER , 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE	
        
        
CODE    ENDS
    
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

Errorflag      DW      ?                ; Holds error type
magnitude       DW      ?               ; Shared magnitude (can be angle, speed), unsigned 
										; 15-bit val
sign            DB      ?               ; Can be POS or NEG
FSM_state       DB      ?               ; Holds the current state of FSM

DATA    ENDS

        END 