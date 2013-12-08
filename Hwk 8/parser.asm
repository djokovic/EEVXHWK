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
;                                   Code Segment
;
;   ParseSerialChar     -   Passed a char for processing
;   ParseReset          -   
;   GetFPToken          -   Grabs next token 
;   Concat_Num          -   Used to prepare passed args to Motor Vars from 
;                           parsed chars.
;
;   no_op               -   Just returns
;   SetSpeed            -   Handles absolute speed setting
;   SetRelSpeed         -   Handles relative speed setting
;   SetDir              -   Handles direction setting
;   RotRelTurrAng       -   Handles rel turret rotation setting
;   RotAbsTurrAng       -   Handles abs turret rotation setting
;   SetTurrEleAng       -   Handles turrent ele angle setting
;   LaserControl        -   Handles Laser ON or OFF
;   SetSign             -   Sets the sign accordingly
;   SetError            -   Sets the errorflag
;
;                                   Data Segment
;
;   sign                -   Stores the sign of the num being processed
;   magnitude           -   Stores the universal magnitude (can be speed, angle,etc.)
;   errorflag           -   Stores errors
;   state_bit           -   Stores the current state
;
;                              What's was last edit?
;
;       			Pseudo code     ->  12-01-2013 - Anjian Wu
;                   Wrote Assembly  ->  12-04-2013 - Anjian Wu
;                   Wrote Assembly  ->  12-05-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   SetMotorSpeed:NEAR        
        EXTRN   GetMotorSpeed:NEAR        
        EXTRN   GetMotorDirection:NEAR    
        EXTRN   SetLaser:NEAR           
        EXTRN   GetLaser:NEAR          
		EXTRN   SetTurretAngle:NEAR      
        EXTRN   GetTurretAngle:NEAR          
        EXTRN   SetRelTurretAngle:NEAR            
		EXTRN   SetTurretElevation:NEAR      
		EXTRN   GetTurretElevation:NEAR     


;Procedure:			ParseSerialChar
;
;Description:      	This function grabs the NEXT token val and type, and uses
;                   that to calc the proper pointer to the function to be called
;                   by the state machine. If the state machine returns to ST_INITIAL
;                   then it also resets the parser variables.
;
;Arguments:        	c   -> The new char to be placed
;
;Return Values:    	Error Flag - > indicates error occurred
;
;Shared Variables: 	Error flag (WRITE)
;                   State_bit (READ/WRITE)
;
;Local Variables:	TokenIndex  - Holds the calculated pointer in state machine table
;                   TokenType   - Holds token type
;                   TokenVal    -  holds token val
;                   
;Global Variables:	None.
;								
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	None
;
;Stack Depth:		None.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:        None.
;                   
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;					12-04-2013: Modified from Glen's floatptd.asm - Anjian Wu :)
;------------------------------------------------------------------------------

ParseSerialChar		PROC	NEAR
					PUBLIC 	ParseSerialChar

ParseSerialInit:

    PUSH 	DX       ; Save all Regs
	PUSH 	BX
	PUSH	CX		
	
    MOV	Errorflag, FALSE	    ;Assume no errors
	
ParseGrabTokens:	
	CALL	GetFPToken	        ;
	MOV		DH, AH			    ;Save token type
	MOV		CH, AL			    ;Save token val
	
ParseComputeTrans:		        ;figure out what transition to do
	MOV		AL, NUM_TOKEN_TYPES	;find row in the table
	MUL		FSM_State           ;Get to current FSM state
	ADD		AL, DH		        ;Calc abs transition inside that state
	ADC		AH, zero		     ;propagate low byte carry into high byte

	IMUL	BX, AX, SIZE TRANSITION_ENTRY   ;now convert to table offset

ParseDoActions:				    ;do the actions (don't affect regs)

	MOV		AL, CH			    ;Pass Token Val (not always used by ACTION)
	CALL	CS:StateTable[BX].ACTION	;do the actions

ParseCheckError:
    CMP     Errorflag, TRUE    ; Was there an error from the FSM action?
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

	MOV		CL, CS:StateTable[BX].NEXTSTATE
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
	POP  DX
	
    
    RET
    
ParseSerialChar ENDP
; GetFPToken
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
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


GetFPToken	PROC    NEAR


InitGetFPToken:				;setup for lookups
	AND	AL, TOKEN_MASK		;strip unused bits (high bit)
	MOV	AH, AL			;and preserve value in AH


TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable	;have token type in AL
	XCHG	AH, AL			;token type in AH, character in AL

TokenValueLookup:			;get the token value
    MOV     BX, OFFSET(TokenValueTable)  ;BX points at table
	XLAT	CS:TokenValueTable	;have token value in AL


EndGetFPToken:                     	;done looking up type and value
        RET


GetFPToken	ENDP

;Function:			ParseReset
;Description:      	Resets all Parser variables to no errors, initial state,
;                   zero magnitude, and pos sign              
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
;------------------------------------------------------------------------------
ParseReset  PROC    NEAR
            PUBLIC  ParseReset
            
    MOV     sign, POS               ; Set default val as positive
    MOV     FSM_state, ST_INITIAL   ; Set Default FSM machine state
    MOV     magnitude, zero         ; Assume magnitude is zero
    
	RET
	
ParseReset  ENDP                   

;Procedure:			Concat_Num
;
;Description:      	Takes the token value and adds the DIGIT into the magnitude
;                   since table already translates ASCII to num, just need to
;                   add the next digit into the store magnitude.
;                   If the magnitude is 0 and arg = 0, it means that we have not
;                   received a valid digit yet, so just return.
;                	    
;Arguments:        	c - token val
;Return Values:    	none.
;Shared Variables: 	magnitude(WRITE)
;                   error_flag (WRITE)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	none.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	If the magnitude is already exceeded MAG_BOUNDARY, then another
;                   digit cannot be added. Thus just return errorflag raised.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
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
    MUL     DX                      ; Add a 0's place into magnitudes one's digit
    JO      Concat_MagTooBig        ; Did the mag get too large? if so error
    
    ADD     AX, BX                  ; Fill the new one's digit place with the passed digit
    JC      Concat_MagTooBig        ; Did the mag get too large? if so error
    
    CMP     AX, MAX_MAG + 1         ; Does the mag fit the # of bits restriction?
    JE      Concat_MagMaybeTooBig   ; No, error
	JA		Concat_MagTooBig		;
    ;JLE    Concat_success          ; 
    
Concat_success:
    MOV     magnitude, AX           ; It is safe to store the new mag
    JMP     Concat_done             ;
	
Concat_MagMaybeTooBig:
	CMP		sign, NEGA				;
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
;Description:      	Sets sign based on passed token val. If TokenVal < 0, the
;                   make sign NEG, else sign is POS.
;Arguments:        	AL - Token val containing sign
;Return Values:    	none.
;Shared Variables: 	sign(write)
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
;------------------------------------------------------------------------------
SetSign     PROC    NEAR
    
    MOV     sign, AL    ; The passed token val itself is already the sign
    
    RET
    
SetSign ENDP

;Procedure:			SetError
;
;Description:      	An error has occurred, so set the error flag
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
;------------------------------------------------------------------------------
SetError        PROC    NEAR

    MOV     Errorflag, TRUE     ; An error has occurred

    RET
    
SetError ENDP

;Procedure:			no_op
;
;Description:      	Just return.
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
;------------------------------------------------------------------------------
no_op        PROC    NEAR

    RET
    
no_op   ENDP
 


;Procedure:			SetSpeed
;
;Description:      	Call SetMotorSpeed with the stored magnitude
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
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
;------------------------------------------------------------------------------
SetSpeed        PROC    NEAR

	PUSH 	AX
	PUSH	BX
                
    MOV     AX, magnitude       ; Concat_Num already ensures magnitude is VALID val
                                ; thus just directly set it
    MOV     BX, NO_ANGLE_CHANGE ;
    CALL    SetMotorSpeed       ;

	POP		BX
	POP		AX
	
    RET
    
SetSpeed    ENDP

;Procedure:			SetRelSpeed
;
;Description:      	Call SetMotorSpeed with the current speed and signed magnitude
;                   combined. No angle changes
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
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
;                   12-04-2013: Initial assembly - Anjian Wu
;------------------------------------------------------------------------------
SetRelSpeed     PROC    NEAR

    PUSH    AX                      ; Save Used Regs
    PUSH    BX

SetRelSpeedInit:
    CALL    GetMotorSpeed           ; Current Speed now in AX
    CMP     sign, POS               ; Is this positive speed change?
    JE      SetRelSpeedPos          ; 
    ;JNE    SetRelSpeedNeg          ;
    
SetRelSpeedNeg:
    SUB     AX, magnitude           ;
    JNC     SetRelSpeedWrite        ; Speed is valid
    ;JC      SetRelWentNeg          ; Speed went 'negative' and not valid
SetRelWentNeg:
    MOV     AX, MIN_ABS_SPEED       ; Just make the robot at lowest speed
    JMP     SetRelSpeedWrite        ;
    
SetRelSpeedPos:
    ADD     AX, magnitude           ;
    JC      SetRelWentOver          ; Is speed is within 16-bits? 
	CMP		AX, NO_SPEED_CHANGE		; Is speed at reserved NO_SPEED_CHANGE val?
	JNE		SetRelSpeedWrite		;
    ;JE      SetRelWentOver         ; Speed is valid 16-bit num, but went 
									; to the val of NO_SPEED_CHANGE, which is 
									; reserved
    
SetRelWentOver:
    MOV     AX, MAX_ABS_SPEED       ; Just make the robot at max speed
    ;JMP     SetRelSpeedWrite        ;
    
SetRelSpeedWrite:
    MOV     BX, NO_ANGLE_CHANGE     ; Just speed change, not angle
    CALL    SetMotorSpeed           ; Set new speed
    
    POP     BX
    POP     AX                      ; Restore used regs
    
    RET
    
SetRelSpeed ENDP

;Procedure:			SetDir
;
;
;Description:      	Call SetMotorSpeed with the current direction and signed magnitude
;                   combined. NO speed is changed
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
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
;                   12-04-2013: Initial assembly - Anjian Wu
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
    
    ADD     AX, DX                  ; Combine to get overall new angle (fits in signed 16-bit)
  
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
;Description:      	Call SetTurretAngle with the abs magnitude
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
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
;                   12-05-2013: Initial assembly - Anjian Wu
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
;Description:      	Call SetRelTurretAngle with the signed magnitude. Since
;                   we have SetRelTurretAngle, we don't need to use 
;                   GetTurrentAngle.
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
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
;                   12-05-2013: Initial assembly - Anjian Wu
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
;Description:      	Call SetTurretElevation with the signed magnitude and
;                   current elevation combined.
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	magnitude (READ)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	If the NEW overall angle is beyond [-60, +60], the DO NOT
;                   change the elevation, and return with ErrorFlag set.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-05-2013: Initial assembly - Anjian Wu
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

;Procedure:			LaserControl
;
;Description:      	Call SetLaser based on whether we are in ST_LAZON or not.
;                
;Arguments:        	AL  - True or False
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
;------------------------------------------------------------------------------
LaserControl    PROC    NEAR

	PUSH  	AX
	PUSH	BX
	
	CMP		FSM_state, ST_LAZON	;
	JE		LaserControlON
	;JNE	LaserControlOff
	
LaserControlOff:
	MOV		AX, FALSE		;
	JMP		LaserControlDONE;
	
LaserControlON:
	MOV		AX, TRUE		;
	;JMP		LaserControlDONE;
	
	
LaserControlDONE:	
    CALL    SetLaser        ; So just pass in AX
	
	POP		BX
	POP		AX
	
    RET                     ;

LaserControl    ENDP



; StateTable
;
; Description:      This is the state transition table for the state machine.
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


StateTable	LABEL	TRANSITION_ENTRY

	;Current State = ST_INITIAL: Waiting for command    
	                                    ;Input Token Type
	%TRANSITION(ST_SAS_INIT, no_op)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_SRS_INIT, no_op)     ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_DIR_INIT, no_op)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_RTR_INIT, no_op)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_STEA_INIT, no_op)	;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_LAZON, no_op)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_LAZOFF, no_op)       ;TOKEN_O - Laser Off
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NUM - A digit
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_INITIAL, no_op)		;TOKEN_IGNORE
	%TRANSITION(ST_INITIAL, no_op)		;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
;-----------------------------Setting Absolute Speed----------------------------------	
	;Current State = ST_SAS_INIT: Waiting for digit to srat      
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_SAS, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_SAS_SIGN, no_op)		    ;TOKEN_POS - '+' Accepted, but effectively ignored
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS_INIT, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
	;Current State = ST_SAS_SIGN: Waiting for digit to srat      
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_SAS, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		    ;TOKEN_POS - '+' Accepted, but effectively ignored
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS_SIGN, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	;Current State = ST_SAS: Keep grabbing digit until return   
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SAS, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetSpeed)	;TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER
	
;-----------------------------Setting Relative Speed----------------------------------	

	;Current State = ST_SRS_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_SRS, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_SRS_SIGN, SetSign)        ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_SRS_SIGN, SetSign)        ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_SRS_INIT, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	;Current State = ST_SRS_SIGN: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_SRS, Concat_Num)     ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_SRS_SIGN, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
		;Current State = ST_SRS : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SRS, Concat_Num) ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SRS, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetRelSpeed);TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER


;-----------------------------Setting Direction Speed----------------------------------	

	;Current State = ST_DIR_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)      ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_DIR_SIGN, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_DIR_SIGN, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_DIR_INIT, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	

	;Current State = ST_DIR_SIGN: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)      ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_DIR_SIGN, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
		;Current State = ST_DIR : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)        ;TOKEN_O
	
	%TRANSITION(ST_DIR, Concat_Num)     ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_DIR, no_op)	        ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetDir)      ;TOKEN_END - Return
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
	%TRANSITION(ST_RTA_ABS, Concat_Num) ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_RTR_SIGN, SetSign)    ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_RTR_SIGN, SetSign)    ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_RTR_INIT, no_op)	    ;TOKEN_IGNORE 
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
	%TRANSITION(ST_RTA_REL, Concat_Num) ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_INITIAL, SetError)    ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)    ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_RTR_SIGN, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER	
	
    ;Current State = ST_RTA_ABS : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	
	%TRANSITION(ST_RTA_ABS, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_RTA_ABS, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, RotAbsTurrAng);TOKEN_END - Return
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_OTHER
	
    ;Current State = ST_RTA_REL : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_V
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F 
	%TRANSITION(ST_INITIAL, SetError)      ;TOKEN_O
	
	%TRANSITION(ST_RTA_REL, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_RTA_REL, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, RotRelTurrAng);TOKEN_END - Return
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
	%TRANSITION(ST_STEA, Concat_Num)      ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_STEA_SIGN, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_STEA_SIGN, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_STEA_INIT, no_op)	;TOKEN_IGNORE 
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
	%TRANSITION(ST_STEA, Concat_Num)      ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_INITIAL, SetError)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_STEA_INIT, no_op)	;TOKEN_IGNORE 
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
	
	%TRANSITION(ST_STEA, Concat_Num)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_POS - '+'
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_NEG - '-'
	%TRANSITION(ST_STEA, no_op)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
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
	%TRANSITION(ST_LAZON, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, LaserControl)		;TOKEN_END
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
	%TRANSITION(ST_LAZOFF, no_op)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, LaserControl)		;TOKEN_END
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

Errorflag      DW      ?               ; Holds error type
magnitude       DW      ?               ; Shared magnitude (can be angle, speed), unsigned 
										; 15-bit val
sign            DB      ?               ; Can be POS or NEG
FSM_state       DB      ?               ; Holds the current state of FSM

DATA    ENDS

        END 