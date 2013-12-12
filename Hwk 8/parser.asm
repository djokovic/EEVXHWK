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


;Procedure:			ParseSerialChar
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

ParseSerialChar		PROC	NEAR
					PUBLIC 	ParseSerialChar

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
	CALL	CS:RobotFSMTable[BX].ACTION	;do the actions

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

	MOV		CL, CS:RobotFSMTable[BX].NEXTSTATE
    MOV     FSM_state, CL   ; We need this nextstate stored for next time.
    
	CMP		FSM_state, ST_INITIAL	; Did the state machine restart?
	JNE		ParseDone	    ; If not then just continue.
	;JE		ParseNeedReset	; Else we need to reset some parser variables
ParseNeedReset:
	CALL	ParseReset		; Reset parser variables (FSM_STATE, magnitude, sign)
    ;JMP    ParseDone       ;
ParseDone:
    MOV     AX, Errorflag       ; Restore the error (if any) back into AX for return
                                ; AH - whether or not error happened, AL - FSM_state (if error)
    
	POP  CX
	POP	 BX
	POP  DX                     ; Restore used regs
	
    
    RET
    
ParseSerialChar ENDP

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

;Function:			ParseReset
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
ParseReset  PROC    NEAR
            
    MOV     sign, POS               ; Set default val as positive
    MOV     FSM_state, ST_INITIAL   ; Set Default FSM machine state
    MOV     magnitude, zero         ; Assume magnitude is zero
    
	RET
	
ParseReset  ENDP                   

;Procedure:			Concat_Num
;
;Description:      	Takes the token value (which should be the digit val) and inserts
;                   that digit into the 1's (base 10) digit of the current magnitude.
;                   IF the magnitude, during the calc, is determined to be too big
;                   then the errorflag is raised, else the magnitude is stored.
;                	    
;Operation:         * Multiply stored magnitude by DIGIT 
;                   * Check if overflow
;                   * ADD next digit's val (the arg)
;                   * Check if carry
;                   * Check if value is at MAX_MAG + 1 (which is OK if sign is NEG)
;                       * If equal, then check if this is special case -(MAX_MAG + 1 )
;                           * If so then continue to store it
;                           * Else CALL SetError
;                       * If greater than CALL SetError
;                   * Else it is OK and store the new magnitude
;                   * Return
;
;Arguments:        	AL = token val/next digit
;Return Values:    	none.
;Shared Variables: 	magnitude(READ/WRITE)
;Local Variables:	AX  - stores digit, magnitude
;                   BX  - copy of digit
;                   DX  - operand of multiply 
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, BX, DX
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	If during the calculation, the magnitude is...
;                   1. Greater than 16-bits
;                   2. Greater than MAX_MAG
;                   Then the digit cannot be added. Thus just return with errorflag raised.
;Algorithms:       	new magnitude = magnitude * 10 + digit
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
Concat_Num  PROC    NEAR

    PUSH    AX                      ; Store used regs
    PUSH    BX                      ;
    PUSH    DX                      ;
    
Concat_NumInit:
    XOR     BX, BX                  ; 
    MOV     BL, AL                  ; Store the digit for later
    
Concat_Num_Test:   
    MOV     AX, magnitude           ; Copy mag for math
    MOV     DX, DIGIT               ; We need a new spot for the next digit insertion
    MUL     DX                      ; Add a 0's into magnitudes one's digit
    JO      Concat_MagTooBig        ; Did the mag get too large? if so error
    
    ADD     AX, BX                  ; Fill the new one's digit place with the passed digit
    JC      Concat_MagTooBig        ; Did the mag get too large? if so error
    
    CMP     AX, MAX_MAG + 1         ; Does the mag fit the # of bits restriction?
    JE      Concat_MagMaybeTooBig   ; It is exactly MAX_MAG + 1 , check if special case
	JA		Concat_MagTooBig		; Too large, report error
    ;JLE    Concat_success          ; Everything ok, store the new mag
    
Concat_success:
    MOV     magnitude, AX           ; Store new magnitude
    JMP     Concat_done             ; Done

;   Since we are concatenating string rep of a 16-bit signed, the
;   -(MAX_MAG + 1) is handled as a special case. 

Concat_MagMaybeTooBig:
	CMP		sign, NEGA				; Are we dealing with negative number?
	JE		Concat_success			;
	;JMP	Concat_MagTooBig		;
	
Concat_MagTooBig:
    CALL    SetError                ; The new Mag is too large
Concat_done:

    POP     DX
    POP     BX
    POP     AX                      ; Restore used regs
    
    RET
    
Concat_Num  ENDP

;Procedure:			SetSign
;
;Description:      	Sets sign based on passed token val. The token val is exactly
;                   the sign we want.
;Operation:         *sign = token val
;Arguments:        	AL - Token val containing sign
;Return Values:    	none.
;Shared Variables: 	sign(write)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AL
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
SetSign     PROC    NEAR
    
    MOV     sign, AL    ; The passed token val itself is already the sign
    
    RET
    
SetSign ENDP

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
 


;Procedure:			SetSpeed
;
;Description:      	Sets the speed only, and does not change angle. The speed is 
;                   exactly the magnitude.
;
;Operation:         * SetMotorSpeed(magnitude, NO_ANGLE_CHANGED)
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, BX
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
SetSpeed        PROC    NEAR

	PUSH 	AX                  ; Saved used regs
	PUSH	BX
                
    MOV     AX, magnitude       ; Concat_Num already ensures magnitude is VALID val
                                ; thus just directly set it
    MOV     BX, NO_ANGLE_CHANGE ;
    CALL    SetMotorSpeed       ;

	POP		BX
	POP		AX                  ; Restore used regs
	
    RET
    
SetSpeed    ENDP

;Procedure:			SetRelSpeed
;
;Description:      	Sets the relative speed passed on stored values of magnitude and sign.
;                   If magnitude * sign's change in speed is beyond MIN or MAX ABS_SPEED,
;                   then CAP the value at exactly the MIN or MAX_ABS_SPEED.
;
;Operation:         * Grab motor speed
;                   * If (sign is POS)
;                       * next speed = current speed + magnitude 
;                   * Else
;                       * next speed = current speed - magnitude 
;                   * If either previous operations exceeded 16-bits (carry flag)
;                     then set next speed to MAX_ABS_SPEED and MIN_ABS_SPEED 
;                     respectively.
;                   * Also if next speed happens to be NO_SPEED_CHANGE, then also
;                     set next speed as MAX_ABS_SPEED.
;                   * Finally SetMotorSpeed(next speed, NO_ANGLE_CHANGE).
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;                   sign (READ)
;Local Variables:	AX - next speed
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, BX
;Stack Depth:		2 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	If change in speed results in exceeding 16-bits (carry flag)
;                   then set next speed to MAX_ABS_SPEED and MIN_ABS_SPEED 
;                   respectively. Also if next speed happens to be NO_SPEED_CHANGE, 
;                   then also set next speed as MAX_ABS_SPEED.
;Algorithms:       	next speed = current speed +- magnitude
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SetRelSpeed     PROC    NEAR

    PUSH    AX                      ; Save Used Regs
    PUSH    BX

SetRelSpeedInit:
    CALL    GetMotorSpeed           ; Current Speed now in AX
    CMP     sign, POS               ; Is this positive speed change?
    JE      SetRelSpeedPos          ; Yes
    ;JNE    SetRelSpeedNeg          ; No
    
SetRelSpeedNeg:
    SUB     AX, magnitude           ; next speed = current speed - magnitude
    JNC     SetRelSpeedWrite        ; Speed is valid?
    ;JC      SetRelWentNeg          ; Speed went 'negative' and not valid
SetRelWentNeg:
    MOV     AX, MIN_ABS_SPEED       ; Just make the robot at lowest speed
    JMP     SetRelSpeedWrite        ;
    
SetRelSpeedPos:
    ADD     AX, magnitude           ; next speed = current speed + magnitude
    JC      SetRelWentOver          ; Is speed is within 16-bits? 
	CMP		AX, NO_SPEED_CHANGE		; Is speed at reserved NO_SPEED_CHANGE val?
	JNE		SetRelSpeedWrite		; Speed is valid
    ;JE      SetRelWentOver         ; Speed is valid 16-bit num, but went 
									; to the val of NO_SPEED_CHANGE, which is 
									; reserved
    
SetRelWentOver:                    
    MOV     AX, MAX_ABS_SPEED       ; Just make the robot at max speed
    ;JMP     SetRelSpeedWrite        
    
SetRelSpeedWrite:                   ; Speed is valid, so store it
    MOV     BX, NO_ANGLE_CHANGE     ; Just speed change, not angle
    CALL    SetMotorSpeed           ; Set new speed
    
    POP     BX
    POP     AX                      ; Restore used regs
    
    RET
    
SetRelSpeed ENDP

;Procedure:			SetDir
;
;
;Description:      	Sets the signed angle direction of the robot without changing speed.
;                   Since magnitude is now in degrees, this function transforms
;                   the magnitude into it's equivalent degrees in [-360,+360].
;                   This approach violates the HW8tests, but passes equivalent
;                   angle vals.
;
;Operation:         * DeltaAngle = MOD((sign*magnitude), FULL_ANGLE)
;                   * NewAngle = GetMotorSpeed + DeltaAngle
;                   * SetMotorSpeed(NO_SPEED_CHANGE, NewAngle)
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;                   sign (READ)
;Local Variables:	AX  - delta angle
;                   BX  - NO_SPEED_CHANGE
;                   DX  - current angle
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, BX, DX
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	DeltaAngle = MOD((sign*magnitude), FULL_ANGLE)
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SetDir      PROC    NEAR

    PUSH    AX                      ; Save Used Regs
    PUSH    BX
    PUSH    DX
 
	%SignAngleMod_DX(sign, magnitude) ; Calc signed angle value
    
    ; EQuivalent Angle now in DX with value in range [-360,360]
    
    ; We grab a small magnitude equivalent angle because now we can ADD the signed
    ; angles safely without worrying about truncation.
    
    CALL    GetMotorDirection       ; Grab current angle [-360,360] in AX
    
    ADD     AX, DX                  ; Combine to get overall new angle (fits in signed 16-bit for sure)
                                    ; [-360*2,+360*2]
  
 SetDirSend:
    MOV     BX, NO_SPEED_CHANGE     ; We just want angle changed, not speed
    
    XCHG    AX, BX                  ; Actually want args passed swapped

    CALL    SetMotorSpeed           ; Change Angle only
    
    POP     DX
    POP     BX
    POP     AX                      ; Restore used regs

    RET
    
SetDir  ENDP

;Procedure:			RotAbsTurrAng
;
;Description:      	Sets the signed angle of the robot turret.
;                   Since magnitude is now in degrees, this function transforms
;                   the magnitude into it's equivalent degrees in [-360,+360].
;                   This approach violates the HW8tests, but passes equivalent
;                   angle vals.
;
;Operation:         * NewAngle = MOD((sign*magnitude), FULL_ANGLE)
;                   * SetTurretAngle(NewAngle)
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;                   sign (READ)
;Local Variables:	AX  - NewAngle angle
;                   DX  - NewAngle angle
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, DX
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	NewAngle = MOD((sign*magnitude), FULL_ANGLE)
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
RotAbsTurrAng       PROC    NEAR
    
    PUSH    AX                      ; Save Used Regs
    PUSH    BX
    PUSH    DX
    
	%SignAngleMod_DX(sign, magnitude) ; Calc signed angle value
    
    ; EQuivalent Angle now in DX with value in range [0,360]
    ;
    ; We grab a small magnitude equivalent angle because now we can ADD the signed
    ; angles safely without worrying about truncation.
    ; Also we know it is positive since this function is for ABS angle and 
    ; magnitude = 15-bit, so just reused SignAngleMod_DX.
    
    MOV     AX, DX                  ;  Prepare to pass angle
                
    CALL    SetTurretAngle       ;  Pass angle in AX [0 to 360]

    POP     DX
    POP     BX
    POP     AX                      ; Restore used regs
    
    RET                             ;
    
    
RotAbsTurrAng   ENDP

;Procedure:			RotRelTurrAng
;
;Description:      	Sets the relative change signed angle of the robot turret.
;                   Since magnitude is now in degrees, this function transforms
;                   the magnitude into it's equivalent degrees in [-360,+360].
;                   This approach violates the HW8tests, but passes equivalent
;                   angle vals.
;
;Operation:         * Deltangle = MOD((sign*magnitude), FULL_ANGLE)
;                   * SetRelTurretAngle(Deltangle)
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;                   sign (READ)
;Local Variables:	AX  - delta angle
;                   DX  - current angle
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, DX
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	Deltangle = MOD((sign*magnitude), FULL_ANGLE)
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
RotRelTurrAng   PROC    NEAR
    PUSH    AX                      ; Save Used Regs
    PUSH    BX
    PUSH    DX
    
	%SignAngleMod_DX(sign, magnitude) ; Calc signed angle value
    
    MOV     AX, DX                  ; Prepare to pass angle ARG
    CALL    SetRelTurretAngle       ; Pass the SIGNED relative angle [ -360,+ 360]

    POP     DX
    POP     BX
    POP     AX                      ; Restore used regs
    
    RET
    
RotRelTurrAng   ENDP

;Procedure:			SetTurrEleAng
;
;Description:      	Sets the signed angle elevation of the robot turret.
;                   Since magnitude is now in degrees, this function transforms
;                   the magnitude into it's equivalent degrees in [-360,+360].
;                   This approach violates the HW8tests, but passes equivalent
;                   angle vals.
;   
;                   Also ensures that the NewAngle is within [MIN_ELEVATION,MAX_ELEVATION]
;
;Operation:         * NewAngle = MOD((sign*magnitude), FULL_ANGLE)
;                   * IF NewAngle is > MAX_ELEVATION or < MIN_ELEVATION
;                       then NewAngle = MAX_ELEVATION, MIN_ELEVATION respectively
;                   * SetTurretAngle(NewAngle)
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;                   sign (READ)
;Local Variables:	AX  - delta angle
;                   DX  - current angle
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX, DX
;Stack Depth:		3 words
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	IF NewAngle is > MAX_ELEVATION or < MIN_ELEVATION
;                   then NewAngle = MAX_ELEVATION, MIN_ELEVATION respectively
;
;Algorithms:       	Deltangle = MOD((sign*magnitude), FULL_ANGLE)
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-04-2013: Initial assembly - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SetTurrEleAng       PROC    NEAR
    PUSH    AX                          ; Save Used Regs
    PUSH    BX
    PUSH    DX
    
	%SignAngleMod_DX(sign, magnitude)   ; Calc signed angle value
    
    CMP     DX, MAX_ELEVATION           ; Is the angle too big?
    JG      SetTurrEleAngMAX            ; Yes          
    CMP     DX, MIN_ELEVATION           ; Is the angle too small?
    JL      SetTurrEleAngMIN            ; Yes
    ;JMP    SetTurrEleAngSET            ; It is neither too small or too big
    
SetTurrEleAngSET:
    MOV     AX, DX                      ; Prepare to set angle
    CALL    SetTurretElevation          ; Pass signed angle
    JMP     SetTurrEleAngDONE           ; Done
    
SetTurrEleAngMIN:
    MOV     DX, MAX_ELEVATION           ; Too big -> just set at MAX_ELEVATION
    JMP     SetTurrEleAngSET            ; Set it
SetTurrEleAngMAX:
    MOV     DX, MIN_ELEVATION           ; Too small -> just set at MIN_ELEVATION
    JMP     SetTurrEleAngSET            ;
    
SetTurrEleAngDONE:
    
    POP     DX
    POP     BX
    POP     AX                          ; Restore used regs
   
    RET
SetTurrEleAng   ENDP

;Procedure:			LaserON
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
LaserON    PROC    NEAR

	PUSH  	AX
	PUSH	BX
	
LaserControlON:
	MOV		AX, TRUE		;

LaserOnDONE:	
    CALL    SetLaser        ; So just pass in AX
	
	POP		BX
	POP		AX
	
    RET                     ;

LaserON    ENDP

;Procedure:			LaserOFF
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
LaserOFF    PROC    NEAR

	PUSH  	AX
	PUSH	BX
	
LaserControlOff:
	MOV		AX, FALSE		;

LaserOffDONE:	
    CALL    SetLaser        ; So just pass in AX
	
	POP		BX
	POP		AX
	
    RET                     ;

LaserOFF    ENDP

; RobotFSMTable
;
; Description:      This is the state transition table for the robot side.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Anjian Wu
; Last Modified:    12-02-2013:
;                   12-05-2013: Fixed Laser state - Anjian Wu


TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act) >
)


RobotFSMTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_INITIAL: Waiting for command    
	                                    ;Input Token Type
	%TRANSITION(ST_SAS_INIT, no_op)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_SRS_INIT, no_op)     ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_DIR_INIT, no_op)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_RTR_INIT, no_op)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_STEA_INIT, no_op)	;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_LAZON, no_op)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_LAZOFF, no_op)       ;TOKEN_O - Laser Off
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_NUM - A digit
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_NEG - '-'
	%TRANSITION(ST_INITIAL, no_op)		;TOKEN_IGNORE
	%TRANSITION(ST_INITIAL, no_op)		;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	
	
;-----------------------------Setting Absolute Speed----------------------------------	
	;Current State = ST_SAS_INIT: Waiting for digit to srat      
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_O
	
	%TRANSITION(ST_SAS, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_SAS_SIGN, no_op)		;TOKEN_POS - '+' Accepted, but effectively ignored
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS_INIT, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	
	
	;Current State = ST_SAS_SIGN: Waiting for digit to srat      
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_O
	
	%TRANSITION(ST_SAS, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_POS - '+' Accepted, but effectively ignored
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS_SIGN, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	

	;Current State = ST_SAS: Keep grabbing digit until return   
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D - Set Dir
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F - Laser On
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SAS, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS, no_op)	        ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetSpeed)	;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER
	
;-----------------------------Setting Relative Speed----------------------------------	

	;Current State = ST_SRS_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_O
	
	%TRANSITION(ST_SRS, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_SRS_SIGN, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_SRS_SIGN, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_SRS_INIT, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	

	;Current State = ST_SRS_SIGN: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)    ;TOKEN_O
	
	%TRANSITION(ST_SRS, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_SRS_SIGN, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER	
		;Current State = ST_SRS : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_D - Set Dir
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_F - Laser On
	%TRANSITION(ST_INITIAL, SetError)    ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SRS, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_NEG - '-'
	%TRANSITION(ST_SRS, no_op)	        ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetRelSpeed);TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)	;TOKEN_OTHER


;-----------------------------Setting Direction Speed----------------------------------	

	;Current State = ST_DIR_INIT: Waiting for DIGIT or Sign           
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)         ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_DIR_SIGN, SetSign)       ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_DIR_SIGN, SetSign)       ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_DIR_INIT, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	;Current State = ST_DIR_SIGN: Waiting for DIGIT or Sign           
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)         ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_DIR_SIGN, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
		;Current State = ST_DIR : Digit started, thus keep grabbing until return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)         ;TOKEN_NUM - A digit - thus concatenate it
	    
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_DIR, no_op)	            ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetDir)          ;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER

;-----------------------------Rotating Turrent Angle----------------------------------	

	;Current State = ST_RTR_INIT: Waiting for DIGIT or Sign           
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	%TRANSITION(ST_RTA_ABS, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_RTR_SIGN, SetSign)       ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_RTR_SIGN, SetSign)       ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_RTR_INIT, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	;Current State = ST_RTR_SIGN: Waiting for DIGIT or Sign           
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	%TRANSITION(ST_RTA_REL, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_RTR_SIGN, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
    ;Current State = ST_RTA_ABS : Digit started, thus keep grabbing until return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	
	%TRANSITION(ST_RTA_ABS, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_RTA_ABS, no_op)	        ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, RotAbsTurrAng)  ;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER
	
    ;Current State = ST_RTA_REL : Digit started, thus keep grabbing until return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	     ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	
	%TRANSITION(ST_RTA_REL, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_RTA_REL, no_op)	        ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, RotRelTurrAng)  ;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER
	
;-----------------------------Elevation of Turret----------------------------------	

	;Current State = ST_STEA_INIT: Waiting for DIGIT or Sign           
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	%TRANSITION(ST_STEA, Concat_Num)        ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_STEA_SIGN, SetSign)       ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_STEA_SIGN, SetSign)      ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_STEA_INIT, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
	;Current State = ST_STEA_SIGN: Waiting for DIGIT or Sign           
	                                         ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	%TRANSITION(ST_STEA, Concat_Num)        ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_STEA_INIT, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
		;Current State = ST_STEA : Digit started, thus keep grabbing until return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	
	%TRANSITION(ST_STEA, Concat_Num)        ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_STEA, no_op)	            ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetTurrEleAng)   ;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER
	
;-----------------------------Fire Laser----------------------------------	

	;Current State = ST_LAZON: Waiting for return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_NUM
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_POS
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_NEG 
	%TRANSITION(ST_LAZON, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, LaserON)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	
;-----------------------------Laser OFF----------------------------------	

	;Current State = ST_LAZOFF: Waiting for return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_NUM
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_POS
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_NEG 
	%TRANSITION(ST_LAZOFF, no_op)	        ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, LaserOFF)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_OTHER	
	
	

	
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
        %TABENT(TOKEN_IGNORE, 0)	;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_IGNORE, 9)    ;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_IGNORE, 11)	;vertical tab
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
        %TABENT(TOKEN_IGNORE, ' ')	;space
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
        %TABENT(TOKEN_POS, POS)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_NEG, NEGA)		;-  (negative sign)
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
        %TABENT(TOKEN_E     , 'E')  ;E 
        %TABENT(TOKEN_F     , TRUE)	;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_O , FALSE)	;O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S     , 'S')	;S
        %TABENT(TOKEN_T, 'T')	;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_V, 'V')	    ;V
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
        %TABENT(TOKEN_E     , 'e')	;e  
        %TABENT(TOKEN_F     , TRUE)	;f
        %TABENT(TOKEN_OTHER , 'g')	;g
        %TABENT(TOKEN_OTHER , 'h')	;h
        %TABENT(TOKEN_OTHER , 'i')	;i
        %TABENT(TOKEN_OTHER , 'j')	;j
        %TABENT(TOKEN_OTHER , 'k')	;k
        %TABENT(TOKEN_OTHER , 'l')	;l
        %TABENT(TOKEN_OTHER , 'm')	;m
        %TABENT(TOKEN_OTHER , 'n')	;n
        %TABENT(TOKEN_O     , FALSE)	;o
        %TABENT(TOKEN_OTHER , 'p')	;p
        %TABENT(TOKEN_OTHER , 'q')	;q
        %TABENT(TOKEN_OTHER , 'r')	;r
        %TABENT(TOKEN_S     , 's')	;s
        %TABENT(TOKEN_T , 't')	;t
        %TABENT(TOKEN_OTHER , 'u')	;u
        %TABENT(TOKEN_V     , 'v')	;v
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