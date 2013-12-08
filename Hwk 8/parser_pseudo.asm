NAME        Parser


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
;   ASCII2NUM           -   Used to prepare passed args to Motor Vars from 
;                           parsed chars.
;
;   Nothing             -   Just returns
;   SetSpeed            -   Handles absolute speed setting
;   SetRelSpeed         -   Handles relative speed setting
;   SetDir              -   Handles direction setting
;   RotRelTurrAng       -   Handles rel turret rotation setting
;   RotAbsTurrAng       -   Handles abs turret rotation setting
;   SetTurrEleAng       -   Handles turrent ele angle setting
;   SetLaser            -   Handles Laser ON or OFF
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
;       			Pseudo code ->  12-01-2013 - Anjian Wu
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
;------------------------------------------------------------------------------

ParseSerialChar(c)
{
    Error_flag = false;

    (TokenVal, TokenType) = GetFPToken(c);  Grab next Token val and type
        
    TokenIndex = TokenType * NUM_TOKEN_TYPES + TokenVal; Get actual transition
        
        
    TokenIndex = TokenIndex * Size(TRANSITION_ENTRY); Calc the table offset
        
    StateTable(TokenValue, TokenIndex).ACTION               ; CALL that function
        
    StateBit = StateTable(TokenValue, TokenIndex).NextState ; Grab next statebit
    
    IF(StateBit = ST_INITIAL)
    {
        ParseReset  ; If that statebit is back to START, need to reset all vars
                    ; (e.g. the sign var since NO '+' or '-' defaults to assume POS)
        
    }

    
    Return Error_flag
}

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
; Last Modified:    12-02-2013

; Left in Assembly since will stay same;

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
ParseReset
{
    sign = POS;
    ParseError = false;
    StateBit = ST_INITIAL;
    magnitude = 0;

}

;Procedure:			ASCII2NUM
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
ASCII2NUM(c)
{
    if(magnitude > MAG_BOUNDARY)
    {
        ErrorFlag = true;
    }
    
    if( c==0 AND (magnitude != 0))
    {
        magnitude = magnitude * 10 + c;
    }
    

    return
}

;Procedure:			SetSign
;
;Description:      	Sets sign based on passed token val. If TokenVal < 0, the
;                   make sign NEG, else sign is POS.
;Arguments:        	TokenVal
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
SetSign(TokenVal)
{
    
    If(TokenVal < 0)
    {
        sign = NEG;
    }
    else
    {
        sign = POS;
    }
    
    return
}

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
SetError()
{
    errorflag = true;

    return; 
}

;Procedure:			Nothing
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
Nothing
{

    return; Do nothing and just return
}


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
SetSpeed
{
    speed = magnitude;
    
    SetMotorSpeed(speed, NO_ANGLE_CHANGE)

    return; 
}

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
;------------------------------------------------------------------------------
SetRelSpeed
{
    speed = magnitude;
    
    currspeed = GetMotorSpeed();
    
    if(sign = NEG)
    {
        speed = -speed;
    }

    SetMotorSpeed(currspeed+ speed, NO_ANGLE_CHANGE)

    return
}

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
;------------------------------------------------------------------------------
SetDir
{
    dir = magnitude;
        
    currdir = GetMotorDirection();
    
    if(sign = NEG)
    {
        dir = -dir;
    }

    SetMotorSpeed(NO_SPEED_CHANGE, currdir+ dir)

    return
}

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
;------------------------------------------------------------------------------
RotAbsTurrAng
{
    dir = magnitude ; ABS implies already positive number
        
    SetTurretAngle(dir) ; Send it out to set Turret Angle

    return
}

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
;------------------------------------------------------------------------------
RotRelTurrAng
{
    dir = magnitude;
    
    if(sign = NEG)
    {
        dir = -dir;
    }

    SetRelTurretAngle(dir) ; Pass the relative signed angle changed directly

    return
}

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
;------------------------------------------------------------------------------
SetTurrEleAng
{
    ele = magnitude;
        
    currele = GetTurretElevation();
    
    if(sign = NEG)
    {
        ele = -ele;
    }
    
    if(!( currele + ele > -60 | currele + ele < 60))
    {
        ErrorFlag = true;
    }
    else
    {
        SetTurretElevation(currele + ele)
    }
    
    return;
}

;Procedure:			SetLaser
;
;Description:      	Call SetLaser based on whether we are in ST_LAZON or not.
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	StateBit (READ)
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
SetLaser
{
    boolean flag;
    
    IF(StateBit == ST_LAZON)
    {
        flag = true
    }
    else
    {
        flag = false;
    }
    SetLaser(flag)

    return; 
}


; StateTable
;
; Description:      This is the state transition table for the state machine.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; Author:           Anjian Wu
; Last Modified:    12-02-2013


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
	%TRANSITION(ST_SAS_INIT, Nothing)	;TOKEN_S - Set Speed
	%TRANSITION(ST_SRS_INIT, Nothing)   ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_DIR_INIT, Nothing)	;TOKEN_D - Set Dir
	%TRANSITION(ST_RTA_INIT, Nothing)	;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_STEA_INIT, Nothing)	;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_LAZON, Nothing)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_LAZOFF, Nothing)     ;TOKEN_O - Laser Off
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NUM - A digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_IGNORE
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	
	
;-----------------------------Setting Absolute Speed----------------------------------	
	;Current State = ST_SAS_INIT: Waiting for digit to srat      
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_SAS, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SAS_INIT, Nothing)	;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	

	;Current State = ST_SAS: Keep grabbing digit until return   
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SAS, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetSpeed)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER
	
;-----------------------------Setting Relative Speed----------------------------------	

	;Current State = ST_SRS_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_SRS, ASCII2NUM)      ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_SRS_WAIT, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_SRS_WAIT, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_SRS_INIT, Nothing)	;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	

	;Current State = ST_SRS_WAIT: Got sign, now need to wait for digit to start      
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_SRS, ASCII2NUM)      ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_SRS_WAIT, Nothing)	;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER

		;Current State = ST_SRS : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S - Set Speed
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V - Set Rel Speed
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D - Set Dir
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T - Rot Turr Angl
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E - Set Turr Ele
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F - Laser On
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O - Laser Off
	
	%TRANSITION(ST_SRS_WAIT, ASCII2NUM) ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INITIAL, SetRelSpeed);TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER


;-----------------------------Setting Direction Speed----------------------------------	

	;Current State = ST_DIR_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_DIR, ASCII2NUM)      ;TOKEN_NUM: A digit - thus concatenate it
	
	%TRANSITION(ST_DIR_WAIT, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_DIR_WAIT, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_DIR_INIT, Nothing)	;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	

	;Current State = ST_DIR_WAIT: Got sign, now need to wait for digit to start      
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_DIR, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_DIR_WAIT, Nothing)	;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER

		;Current State = ST_DIR : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_DIR, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INTIAL, SetDir)      ;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER

;-----------------------------Rotating Turrent Angle----------------------------------	

	;Current State = ST_RTR_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	%TRANSITION(ST_RTA_ABS, ASCII2NUM)  ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_RTA_WAIT, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_RTA_WAIT, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_RTA_INIT, Nothing)	;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	

	;Current State = ST_RTR_WAIT: Got sign, now need to wait for digit to start      
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_RTA, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_RTA_REL, Nothing)	;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER

    ;Current State = ST_RTA_ABS : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_RTA, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INTIAL, RotAbsTurrAng);TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER
	
    ;Current State = ST_RTA_REL : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_RTA, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INTIAL, RotRelTurrAng);TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER
	
;-----------------------------Elevation of Turrent----------------------------------	

	;Current State = ST_STEA_INIT: Waiting for DIGIT or Sign           
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	%TRANSITION(ST_STEA, ASCII2NUM)      ;TOKEN_NUM: A digit - thus concatenate it	
	%TRANSITION(ST_STEA_WAIT, SetSign)   ;TOKEN_POS - '+' Wait for sign
	%TRANSITION(ST_STEA_WAIT, SetSign)   ;TOKEN_NEG - '-' Wait for sign
	%TRANSITION(ST_STEA_INIT, Nothing)	;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER	

	;Current State = ST_STEA_WAIT: Got sign, now need to wait for digit to start      
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_STEA, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_STEA_WAIT, Nothing)	;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER

		;Current State = ST_STEA : Digit started, thus keep grabbing until return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	
	%TRANSITION(ST_STEA, ASCII2NUM)      ;TOKEN_NUM - A digit - thus concatenate it
	
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_POS - '+'
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_NEG - '-'
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_IGNORE - Keep Waiting for start of digit
	%TRANSITION(ST_INTIAL, SetTurrEleAng)   ;TOKEN_END - Return
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_OTHER
	
;-----------------------------Fire Laser----------------------------------	

	;Current State = ST_LAZON: Waiting for return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	%TRANSITION(ST_ERROR, Nothing)   ;TOKEN_NUM
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_POS
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_NEG 
	%TRANSITION(ST_LAZON, Nothing)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetLaser)		;TOKEN_OTHER	

	
;-----------------------------Laser OFF----------------------------------	

	;Current State = ST_LAZOFF: Waiting for return       
	                                    ;Input Token Type
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_S 
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_V 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_D 
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_T
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_E
	%TRANSITION(ST_ERROR, Nothing)	    ;TOKEN_F
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_O
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_NUM
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_POS
	%TRANSITION(ST_ERROR, Nothing)      ;TOKEN_NEG 
	%TRANSITION(ST_LAZOFF, Nothing)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_ERROR, Nothing)		;TOKEN_END
	%TRANSITION(ST_INITIAL, SetLaser)	;TOKEN_OTHER	
	
	
;-----------------------------Error----------------------------------	

	;Current State = ST_ERROR: Waiting for return       
	                                        ;Input Token Type
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_S 
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_V 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_D 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_T
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_E
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_F
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_O
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_NUM
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_POS
	%TRANSITION(ST_INITIAL, SetError)       ;TOKEN_NEG 
	%TRANSITION(ST_INITIAL, SetError)	    ;TOKEN_IGNORE 
	%TRANSITION(ST_INITIAL, SetError)		;TOKEN_END
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

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_IGNORE, 0)		;<null>  (end of string)
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
        %TABENT(TOKEN_POS, +1)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_NEG, -1)		;-  (negative sign)
        %TABENT(TOKEN_DP, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_NUM, 0)	;0  (digit)
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
        %TABENT(TOKEN_D, 'D')	;D
        %TABENT(TOKEN_E, 'E')		;E  (exponent indicator)
        %TABENT(TOKEN_F, 'F')	;F
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_O, 'O')	;O
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S, 'S')	;S
        %TABENT(TOKEN_OTHER, 'T')	;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_V, 'V')	;V
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
        %TABENT(TOKEN_D, 'd')	    ;d
        %TABENT(TOKEN_E, 'e')		;e  
        %TABENT(TOKEN_F, 'f')	;f
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_O, 'o')	;o
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_S, 's')	;s
        %TABENT(TOKEN_OTHER, 't')	;t
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_V, 'v')	;v
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
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
;the data segment

