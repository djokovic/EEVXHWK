NAME        Motors

$INCLUDE(motors.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW6 Motor Functions                        ;
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
;   SetMotorSpeed  -   Sets the motor speed by changing PWM width
;   GetMotorSpeed  -   Retrieves the abs motor speed 
;   GetMotorDirection  -  retrieves motor angle (0 to 359 deg)
;   SetLaser        -   Turns on the laser
;   GetLaser        -   Checks if Laser is turned on or not
;
;
;   MotorInit       - Initializes all motor vars, installs handler and sets up CS
;   MotorHandler    -   Interrupt handler that outputs to PORTB with proper PWM
;   MotorHandlerNeg -   Used by MotorHandler to set motor in reverse
;   MotorHandlerPos -   Used by MotorHandler to set motor forward
;   MotorHandlerZero-   Used by MotorHandler to set motor stop
;
;
;                                   Data Segment
;
;
;   S           -   this is the PWM width value set by SetMotorSpeed
;   S_PWM       -   This is the PWM counter that keeps track of where in the 
;                   PWM phase each motor is in.
;   S_PWM_STATUS-   This stores the status bit of each motor such that no 
;                   repetitive PORTB writing is needed.
;   SpeedStored -   Current ABS motor speed
;   AngleStored -   Current robot moving angle
;   LaserFlag   -   Status of laser
;
;                                 What's was last edit?
;
;       			Pseudo code -> 11-18-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			SetMotorSpeed
;
;Description:      	This interrupt performs the holonomic calculations for each
;                   respective motor by storing the speed and angle passed, as
;                   well as calculating each motor's PWM length/counter such that
;                   the overall speed and angle of the system matches the stored
;                   ABS angle and ABS speed. Ultimately the function's stored
;                   PWM values for each counter (aka S[0 to 2]) will be accessed
;                   by the MotorHandler as the PWM width reference by which
;                   each motor can be turned on or off.
;           
;                   
;Operation:			* Check if angle needs to be changed
;                       * If not, then used previous angle
;                   * Map the angle from + 32767 to - 32767
;                     to +360 to -360 by dividing by ANGLE_NORM
;                   * If angle is neg, then add 360 deg to get POS equivalent
;                   * Store this angle
;
;                   * Check if speed needs to be changed
;                       * If not, then used previous speed
;                   * Store this speed. Divide speed by two.
;                   * For i'th motor
;                       *   Fx = MotorFTable[i] * speed * cos(angle). take only DX
;                       *   Fy = MotorFTable[i + FY_OFFSET] * speed * sin(angle). take only DX
;                       *   S[i] = SAL (FX + Fy), 2
;                       *   increment counter
;
;Arguments:        	AX     -> ABS speed to be set
;                   BX     -> Angle to be set
;
;Return Values:    	None.
;
;Result:            Possibly new values in S[0 to 2], speedstored, and anglestored
;
;Shared Variables: 	S[0 to 2] (WRITE)
;                   SpeedStored (WRITE/READ) 
;                   AngleStored (WRITE/READ)
;
;Local Variables:	Angletemp -   temporary variable that stores angle values
;                   Speedtemp -   temporary variable that stores angle values
;                   counter   -   stores counter index
;                   Fx        -   stores x component
;                   Fy        -   stores y component
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	none.
;
;Stack Depth:		none.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:       	none.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------

CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

SetMotorSpeed(Speed, Angle)

{
    ; Check if Angle needs to be changed
    
    If (Angle == NO_ANGLE_CHANGE)
    {
        Angletemp = AngleStored;
    }
    else
    {
        Angletemp = Angle;
    }
    
    ; Map the angle from + 32767 to - 32767
    ; to +360 to -360
    
    Angletemp = Angletemp/ANGLE_NORM; ANGLE_NORM approx = 91, throw away remainder
        
    If (Angletemp < 0)
    {
        Angletemp += Full_circle; Make it equivalent positive angle
    }
    
    Anglestore = Angletemp ; Store this new angle
    
    ; Time to grab speed
    
    Speedtemp = Speed ; Assume the speed is new
    
    If (Speed == NO_SPEED_CHANGE)
    {
        Speedtemp = SpeedStored ; Grab previous speed if no speed change is needed
    }
    
    SpeedStored = Speedtemp     ;Save this speed value
    
    counter = 0;
    
    Speedtemp = Speedtemp/2;
    
    While (counter < numOfMotors)
    {
        Fx = MotorFTable[2*counter] * Speedtemp * costable[Angletemp]; Note there is truncation (take only DX)
        
        Fy = MotorFTable[2*(counter + FY_OFFSET)] * Speedtemp * sintable[Angletemp]; Note there is truncation (take only DX)
        
        S[counter] = Fx + Fy; Combine both components
        
        S[counter] = ShiftArithLeft(S[counter], 2); Adjust to get value from -128 to +127
        
        counter += 1;
        
    }

    

}
    

;Procedure:			GetMotorSpeed
;
;Description:      	This function returns the value of the motor speed. This value
;                   is exactly the speedstore shared variable. It will simply return
;                   this value.
;
;                                    
;                   
;Operation:			Simply Returns the speedstore value
;
;Arguments:        	None.
;
;Return Values:    	AX -> Speedstore
;
;Result:            Grabs the current motor speed for User.
;
;Shared Variables: 	Speedstore (Read)
;
;Local Variables:	None.
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX
;
;Stack Depth:		N/A
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------


GetMotorSpeed()

{
    
    AX = Speedstore;
    
    Return AX

}

;Procedure:			GetMotorDirection
;
;Description:      	This function returns the value of the motor angle. This value
;                   is exactly the anglestore shared variable. It will simply return
;                   value MOD 360. The MOD 360 is for when anglestore = 360, of which
;                   it is equivalent to angle of 0 degs anyways.
;
;                                    
;                   
;Operation:			Simply Returns the anglestore MOD 360 deg value
;
;Arguments:        	None.
;
;Return Values:    	AX -> the angle to be returned, between 0 and 359 deg
;
;Result:            Grabs the current motor speed for User.
;
;Shared Variables: 	anglestore (Read)
;
;Local Variables:	None.
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX
;
;Stack Depth:		N/A
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------


GetMotorSpeed()

{
    
    AX = anglestore;
    
    AX = AX MOD Full_Angle ; Full_angle is 360 degress
    
    Return AX

}

;Procedure:			SetLaser
;
;Description:      	This function will turn the robot laser on or off depending
;                   on the passed arg in AX. If AX is 0 then lazer is turned off.
;                   Else it is turned on. Also will record laser status in LaserFlag.
;
;                                    
;                   
;Operation:			* Compare arg to zero
;                   * If zero then turn laser off by turning off bit 7 of port B 
;                     of the 8255. Clear LaserFlag.
;                   * If not then turn laser on by turning on bit 7 of port B 
;                     of the 8255. Set LaserFlag.
;                   
;
;Arguments:        	arg -> AX -> on or off.
;
;Return Values:    	None.
;
;Result:            Grabs the current motor speed for User.
;
;Shared Variables: 	LaserFlag (Write)
;
;Local Variables:	None.
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX
;
;Stack Depth:		N/A
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------


SetLaser()

{
    
    IF (AX = 0)
    {
        portvalue = MASKOFF(PORTB, 7) ; Mask off the 7th bit in PortB
        PORT(PORTB, portvalue)        ; Output the new value for laser off
        LaserFlag = FALSE;
    }
    else
    {
        portvalue = MASKON(PORTB, 7) ; Mask off the 7th bit in PortB
        PORT(PORTB, portvalue)        ; Output the new value for laser off
        LaserFlag = TRUE;
    }

    Return
}

;Procedure:			GetLaser
;
;Description:      	This function returns the value of the LaserFlag. This value
;                   is exactly the LaserFlag shared variable. It will simply return
;                   this value. Zero value indicates FALSE, other wise TRUE.
;                                    
;                   
;Operation:			Simply Returns the LaserFlag value
;
;Arguments:        	None.
;
;Return Values:    	AX -> LaserFlag
;
;Result:            Grabs the current motor speed for User.
;
;Shared Variables: 	LaserFlag (Read)
;
;Local Variables:	None.
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX
;
;Stack Depth:		N/A
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------


GetLaser()

{
    
    AX = LaserFlag;
    
    Return AX

}


; MOTORINIT
;
; Description:       Does all initializations for Motors.
;
;                    Installs the MotorHandler for the timer0 interrupt at 
;                    interrupt table index Tmr0Vec. ALso clears the 
;                    LaserFlag, SpeedStored, S[0 to 2], AngleStored, S_PWM[0 to 2]
;                    and S_PWM_STATUS[0 to 2].
;
;                    Also sets up the PORTB on the 8255 and proper chip select
;
; Operation:         First clear LaserFlag, SpeedStored, S[0 to 2], AngleStored, 
;                    S_PWM[0 to 2] and S_PWM_STATUS[0 to 2].
;
;                    Then writes the address of the MotorHandler to the
;                    timer0 location in the interrupt vector table. Notice
;                    need to multiple by 4 since table stores a CS and IP.
;
;                    Then set up chip select and PORTB control word values
;                     
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Used to temporarily store vector table offset for ES
; 
; Shared Variables:  LaserFlag (WRITE)
;                    SpeedStored (WRITE)
;                    AngleStored (WRITE)
;                    S[0 to 2] (WRITE)
;                    S_PWM[0 to 2] (WRITE)
;                    S_PWM_STATUS[0 to 2] (WRITE)
;
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Used:    AX, ES
;
; Stack Depth:       0 words
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu

;-------------------------------------------------------------------------------

MOTORINIT  PROC    NEAR
                   PUBLIC  MOTORINIT
                   
; Left it in assembly since this is standard;

MOTORINITInitStart:
        MOV     LaserFlag, 0        ; Clear the LaserFlag
        MOV     SpeedStored, 0      ; Clear the SpeedStored 
        MOV     AngleStored, 0   	; Clear the AngleStored
        MOV     SpeedStored, 0      ; Clear the SpeedStored 
        MOV     AngleStored, 0   	; Clear the AngleStored
        
MOTORINITClearPWMvars:

        S[0 to 2] = 0               ; Clear PWM widths
        S_PWM[0 to 2] = 0           ; Clear PWM counters
        S_PWM_STATUS[0 to 2] = MOTOR_STOPPED ; All motors are stopped.
        
MOTORINITInitVector:
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(MotorHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(MotorHandler)

MOTORINITCS:

        MOV     DX, 8255_CNTRL_REG
        MOV     AX, 8255_CNTRL_VAL
        OUT     DX, AL
   
        MOV     DX, PORTB    ;Clear PortB
        MOV     AX, CLEAR
        OUT     DX, AL


        RET                     ;all done, return


MOTORINIT  ENDP

;Procedure:			MotorHandler
;
;Description:      	This function performs the PWM for the three motors. It does this
;                   by looping through each motor's S_PWM counter and determining
;                   which phase in the PWM each motor is in. It will then set the
;                   PORT B controls appropriately.
;
;                   Instead of writing to the PORt B each cycle, this function uses
;                   stored status bits of each motor. Thus if the motor is already inside
;                   the active phase of the PWM, there is no need to turn on the proper
;                   bits in PORTB since they are already ON.
;                                    
;                   
;Operation:			*   Loop while i < numOfMotors
;                   *   Grab speed in i'th S[i]
;                   *   If speed is NEG then
;                       * take abs of speed and check if greater than S_PWM[i] counter
;                           *   greater than we are in active neg phase
;                           *   thus check if we've set motors for this phase yet
;                               * If not, update S_PWM_STATUS[i] for NEG
;                               * Call MotorHandlerNeg(i)
;                       * else we are in inactive phase of PWM
;                           *   thus check if we've set motors for this phase yet
;                               * If not, update S_PWM_STATUS[i] for ZERO
;                               * Call MotorHandlerZero(i)
;                   *   Else speed is POS or ZERO and motor is FORWARDS
;                       * check if speed greater than S_PWM[i] counter
;                           *   greater than we are in active pos phase
;                           *   thus check if we've set motors for this phase yet
;                               * If not, update S_PWM_STATUS[i] for POS
;                               * Call MotorHandlerPos(i)
;                       * else we are in inactive phase of PWM
;                           *   thus check if we've set motors for this phase yet
;                               * If not, update S_PWM_STATUS[i] for ZERO
;                               * Call MotorHandlerZero(i)
;                   *   Update S_PWM(i) counter and i
;                   *   Loop
;
;Arguments:        	None.
;
;Return Values:    	None.
;
;Result:            Sets each individual motor's PORTB bit depending on PWM phase of
;                   eash motor.
;
;Shared Variables: 	S[c](READ) - this is the PWM width value set by SetMotorSpeed
;                   S_PWM[c](WRITE/READ) - This is the PWM counter that keeps track of
;                                          where in the PWM phase each motor is in.
;                   S_PWM_STATUS[c](WRITE/READ) - This stores the status bit of each motor
;                                          such that no repetitive PORTB writing is needed.
;
;Local Variables:	c - counter
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	Each motor via PORT B
;
;Registers Used:	None,
;
;Stack Depth:		N/A
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
; DC movement reference table
;_____________________________       
;Port B Bit 1 |  Port B Bit 0
;Port B Bit 3 |  Port B Bit 2 
;Port B Bit 5 |	 Port B Bit 4 
;           0 |	0	no movement
;           0 |	1	no movement
;           1 |	0	forwards
;           1 |	1	backwards

MotorHandler()

{
    c = 0     ; counter (used letter c since it is shorter)
    
    WHILE (c < numOfMotors)
    {
        speedtemp = S[c]; Grab the pulse width value
        
        IF(S_PWM[c] > MAX_PWM); If we went beyond max pulse width, then reset each PWM counter
        {
            S_PWM[c] = 0; 
        }
        
        IF(speedtemp < 0); Are we going backwards?
        {
            speedtemp = -speedtemp ; Negate the speed to get ABS value
            
            IF(speedtemp >= S_PWM[c])    ; Not done with NEG cycle part of PWM yet
            {
                IF(S_PWM_STATUS[c] /= MOTOR_BACKWARD); Check to make sure we are indeed going backward
                                                     ; the purpose of S_PWM_STATUS is so that we don't write to 
                                                     ; PORT B unless we need to.
                {                                  
                    S_PWM_STATUS[c] = MOTOR_BACKWARD ; The MOTOR has not been seg in NEG phase of PWM yet, so do that    
                    MotorHandlerNeg(c); SET c'th motor in neg
                }
                
            }
            else ; We are in the OFF phase of the PWM cycle
            {
                IF(S_PWM_STATUS[c] /= MOTOR_STOPPED); Check to make sure we have already stopped motor
                {
                    S_PWM_STATUS[c] = MOTOR_STOPPED; The MOTOR has not been seg in STOP phase of PWM yet, so do that  
                    MotorHandlerZero(c); SET c'th motor to stop
                }
            
            }
            
        }
        
        ELSE; Else we must be going forward/not moving
        {
            
            IF(speedtemp >= S_PWM[c]); Still in assert PWM phase
            {
                IF(S_PWM_STATUS[c] /= MOTOR_FORWARD); Check to make sure we are indeed going backward
                {
                    S_PWM_STATUS[c] = MOTOR_FORWARD; The MOTOR has not been seg in POS phase of PWM yet, so do that  
                    MotorHandlerPos(c); SET c'th motor to POS
                }
                
            }
            else ; The only other option is we are in de-assert PWM phase
            {
                IF(S_PWM_STATUS[c] /= MOTOR_STOPPED); Check to make sure we have already stopped motor
                {
                    S_PWM_STATUS[c] = MOTOR_STOPPED; The MOTOR has not been seg in STOP phase of PWM yet, so do that  
                    MotorHandlerZero(c); SET c'th motor to stop
                }
            
            }
            
        }
    
        S_PWM[c] += 1; Increment c'th counter at the end of each c'th loop
        
        c += 1; Update overall function counter
    
    
    }

}
;Procedure:			MotorHandlerNeg
;Description:      	This function takes the passed index c to mapped to the proper
;                   bit mask such that PORT B's bits for NEG motor rotation is masked ON.         
;Operation:			1. Grab port B's value. 2. Use c for lookup table 3. MASK ON with port b value
;                   3. REWRITE portB value
;Arguments:        	c - the index
;Return Values:    	None.
;Result:            New port B value
;Shared Variables: 	None.
;Local Variables:	portBtemp
;Global Variables:	None.					
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	Table look up.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
MotorHandlerNeg()
{
    portBtemp = READ(PORTB); Grab the current value of PORT B
    
    portBtemp = MASKON(MOTORTABLE_NEG[counter], portBtemp);MASK ON the bits needed to get c'th motor going NEG
    
    PORT(PORTB, portBtemp); Write out to PORT B with c'th motor in neg mode.                                       
    
    Return           
}
;Procedure:			MotorHandlerPos
;Description:      	This function takes the passed index c to mapped to the proper
;                   bit mask such that PORT B's bits for POS motor rotation is masked ON.         
;Operation:			1. Grab port B's value. 2. Use c for lookup table 3. MASK ON with port b value
;                   3. REWRITE portB value
;Arguments:        	c - the index
;Return Values:    	None.
;Result:            New port B value
;Shared Variables: 	None.
;Local Variables:	portBtemp
;Global Variables:	None.					
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	Table look up.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
MotorHandlerPos()
{
    portBtemp = READ(PORTB); Grab the current value of PORT B

    portBtemp = MASKON(MOTORTABLE_POS[counter], portBtemp);MASK ON the bits needed to get c'th motor going POS
    
    PORT(PORTB, portBtemp); Write out to PORT B with c'th motor in neg mode.       
    
    Return
}
;Procedure:			MotorHandlerNeg
;Description:      	This function takes the passed index c to mapped to the proper
;                   bit mask such that PORT B's bits for NEG motor rotation is masked ON.         
;Operation:			1. Grab port B's value. 2. Use c for lookup table 3. MASK ON with port b value
;                   3. REWRITE portB value
;Arguments:        	c - the index
;Return Values:    	None.
;Result:            New port B value
;Shared Variables: 	None.
;Local Variables:	portBtemp
;Global Variables:	None.					
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	Table look up.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
MotorHandlerZero()
{
    portBtemp = READ(PORTB); Grab the current value of PORT B

    portBtemp = MASKON(MOTORTABLE_ZERO9[counter], portBtemp);MASK ON the bits needed to get c'th motor to stop
    
    PORT(PORTB, portBtemp); Write out to PORT B with c'th motor in neg mode.       
    
    Return
}



; MotorFTables (F1 to F3)
;
; Description:      This table contains all the X and Y direction vector
;                   components for the Holonomic motion. They are taken from 
;                   Glenn's handout :)
;
; Author:           Anjian Wu
; Last Modified:    11/15/2013


MotorFTable	    LABEL	WORD
                PUBLIC  MotorFTable
                                    
	DW		Fx1 	;Fx component for Motor 1
	DW		Fx2	    ;Fx component for Motor 2	
	DW		Fx3	    ;Fx component for Motor 3	
	
	DW		Fy1 	;Fy component for Motor 1
	DW		Fy2	    ;Fy component for Motor 2	
	DW		Fy3	    ;Fy component for Motor 3	
	

; MOTORTABLE_POS
;
; Description:      This table contains all the MASK values for OR mask
;                   such that when masked with PORTB bits, it will set
;                   the (i+1)'th motor into Positive rotation.
;
; Author:           Anjian Wu
; Last Modified:    11/18/2013


MOTORTABLE_POS	    LABEL	BYTE
                    PUBLIC  MOTORTABLE_POS
                                    
	DB		FORWARD_M1 	;MASK FORWARD for Motor 1
	DB		FORWARD_M2 	;MASK FORWARD for Motor 2
	DB		FORWARD_M3 	;MASK FORWARD for Motor 3


; MOTORTABLE_NEG
;
; Description:      This table contains all the MASK values for OR mask
;                   such that when masked with PORTB bits, it will set
;                   the (i+1)'th motor into NEGATIVE rotation.
;
; Author:           Anjian Wu
; Last Modified:    11/18/2013


MOTORTABLE_NEG	    LABEL	BYTE
                    PUBLIC  MOTORTABLE_NEG
                                    
	DB		BACKWARD_M1 	;MASK BACKWARD for Motor 1
	DB		BACKWARD_M2 	;MASK BACKWARD for Motor 2
	DB		BACKWARD_M3 	;MASK BACKWARD for Motor 3


; MOTORTABLE_ZERO
;
; Description:      This table contains all the MASK values for OR mask
;                   such that when masked with PORTB bits, it will set
;                   the (i+1)'th motor into ZERO rotation.
;
; Author:           Anjian Wu
; Last Modified:    11/18/2013


MOTORTABLE_ZERO	    LABEL	BYTE
                    PUBLIC  MOTORTABLE_ZERO
                                    
	DB		STOP_M1 	;MASK STOP for Motor 1
	DB		STOP_M2 	;MASK STOP for Motor 2
	DB		STOP_M3 	;MASK STOP for Motor 3



				
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'


    SpeedStored     DW  ?     ;Flag to show that a Key was debounced recently
                                           
    AngleStored     DW  ?     ;Debounce count for single key press

    LaserFlag       DW  ?     ;Debounce count for auto-repeat key press
    
    S		DB	    numOfMotors	DUP	(?) ; Motor speed array (essentially PWM width)

    S_PWM   DB      numOfMotors DUP (?) ; Current motor pulse width counter
    
    S_PWM_STATUS    DB  numOfMotors DUP (?) ; Contains last written bit to Port B
                                            ; for each respective motor (either neg, zero, or pos)
    	
DATA    ENDS

        END 