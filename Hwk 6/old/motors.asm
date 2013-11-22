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
;   SetMotor_GetArgs -   Used by MotorHandler to set motor in reverse
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
        
;External Procedures needed
        EXTRN   XWORDLAT:NEAR      ; Used to enqueue key event/code
        EXTRN   Cos_Table:NEAR      ; Used to enqueue key event/code
        EXTRN   Sin_Table:NEAR      ; Used to enqueue key event/code

SetMotorSpeed		PROC    NEAR
				    PUBLIC  SetMotorSpeed


SetMotorSpeedAngChk:

	PUSH	AX						; Save Speed for later
    CMP     BX, NO_ANGLE_CHANGE     ; Do we need to change the angle?
    JNE     SetMotorAngleCalc        ; Yes
    ;JE     SetMotorSameAngle       ; No
    
SetMotorSameAngle:
    
    MOV     BX, AngleStored         ; Use current angle
    JMP     SetMotorSpeedChk        ; Angle is ready to use, so proceed to 
                                    ; deal with motor speed.
SetMotorAngleCalc:

    XOR     DX, DX                  ; Always clear remainder
	MOV		AX, BX					; Need to use AX specifically for IDIV
    MOV     BX, FULL_ANGLE          ; 
    CWD                           ;
    IDIV    BX          	        ; Take the MOD to Full angle
; Angle now in DX since we want MOD
	CMP		DX,	0					; Is the Angle Neg?
	JGE		SetMotorAngleSave		; Nope, store it
	;JL		SetMotorAngleNeg		; Yes, it is ,need adjustment

SetMotorAngleNeg:
	ADD		DX, FULL_ANGLE			; Calc positive equivalent angle
	;jmp
SetMotorAngleSave:
	MOV		AngleStored, DX			; Store this abs angle
    
SetMotorSpeedChk:
    POP     AX                      ; Now retrieve the Speed Arg
	CMP		AX, NO_SPEED_CHANGE     ; Are we changing the speed?
    JNE     SetMotorDiffSpeed       ; Yes
    JMP     SetMotor_SpeedCalcInit  ; No, so Start speed calculations
    
SetMotorDiffSpeed:  
    MOV     SpeedStored, AX         ; Store that speed
    ;JMP    SetMotor_SpeedCalcInit
    
;-----------------------Motor Speed Math---------------------------------

SetMotor_SpeedCalcInit:
    XOR     CX, CX                  ; Clear loop counter
    MOV     AX, CS
    MOV     ES, AX                  ; Prepare to use XWORDLAT in code segment
    
SetMotor_CalcLoop:  
    CMP     CX, numOfmotors         ;
    JGE     SetMotor_DONE           ;
    ;JL     SetMotor_GrabAllArgs    ;
    
SetMotor_GrabAllArgs: 

    MOV     BX, CX                  ; We are on the CX'th motoR     
    
    CALL    SetMotor_GetArgs        ; Update COS, SIN, Fx, and Fy values
                                    ; Passes ES, and CX
SetMotor_CalcX:     

    MOV     AX, SpeedStored         ; Grab current speed 
    SHR     AX, 1                   ; Div Speed by two to get into range [0, 7FFFH]     
    IMUL    Fx                      ; Fx * SpeedStored. 
    MOV     AX, DX                  ; Truncated answer in DX
    IMUL    COS_VAL                 ; (Fx * SpeedStored)*COS(AngleStored)
    SHL     DX, 2                   ; Truncated double sign bit
    
    MOV     S[BX], DH               ; Take only high byte of high word  
    
SetMotor_CalcY:   
 
    MOV     AX, SpeedStored         ; Grab current speed 
    SHR     AX, 1                   ; Div Speed by two to get into range [0, 7FFFH]     
    IMUL    Fy                      ; Fy * SpeedStored. 
    MOV     AX, DX                  ; Truncated answer in DX
    IMUL    SIN_VAL                 ; (Fy * SpeedStored)*SIN(AngleStored)
    SHL     DX, 2                   ; Truncated double sign bit
    
    ADD     S[BX], DH               ; Fx * v * cos q + Fy * v * sin q

SetMotor_LoopDone:
    
    INC     CX                      ; Increment the counter
    JMP     SetMotor_CalcLoop       ; LOOP
    
SetMotor_DONE:

    RET

SetMotorSpeed ENDP



SetMotor_GetArgs		PROC    NEAR
                        PUBLIC  SetMotor_GetArgs    ; Used by many functions

    PUSH    BX                      ; Save All Used Regs
    PUSH    AX;
GetArgsInit:

; NOTE XWORDLAT does not change BX

GetArgsFx:
; Grab Fx    
    MOV     AX, offset(MotorFTable) ; First grab CX'th Fx component
    CALL    XWORDLAT                ; Fx component in AX
    MOV     Fx, AX                  ; Save it
    
GetArgsFy:
; Grab Fy     
    MOV     AX, offset(MotorFTable) + FY_OFFSET ; First grab CX'th Fy component
    CALL    XWORDLAT                ; Fx component in AX
    MOV     Fy, AX                  ; Save it
    
GetArgsCos:
    MOV     BX, AngleStored         ; Grab stored angle
; Grab Cos(AngleStored)    
    MOV     AX, offset(Cos_Table)   ; Do COS operation table lookup
    CALL    XWORDLAT                ; COSVal component in AX
    MOV     COS_VAL, AX             ; Save it
    
GetArgsSin:
; Grab Sin(AngleStored)    
    MOV     AX, offset(Sin_Table)   ; Do SIN operation table lookup
    CALL    XWORDLAT                ; SIN_VAL component in AX
    MOV     SIN_VAL, AX             ; Save it

GetArgsDone:

    POP    AX;
    POP    BX                      ; Restore all used regs
    
    RET
    
SetMotor_GetArgs    ENDP


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


GetMotorSpeed		    PROC    NEAR

    MOV     AX, SpeedStored;
    RET

GetMotorSpeed ENDP

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


GetMotorDirection		    PROC    NEAR

    MOV     AX, AngleStored;
    RET

GetMotorDirection ENDP

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

SetLaser		    PROC    NEAR
                    PUBLIC  SetLaser

    MOV     LaserFlag, AX;
    RET

SetLaser ENDP

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


GetLaser		    PROC    NEAR

    MOV     AX, LaserFlag;
    RET

GetLaser ENDP


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
        MOV     LaserFlag, FALSE        ; Clear the LaserFlag to OFF
        MOV     SpeedStored, STOPPED_SPEED      ; Clear the SpeedStored to NOT moving
        MOV     AngleStored, ZERO_ANGLE   	; Clear the AngleStored to 0 deg
        MOV     Fx, 0                   ;
        MOV     Fy , 0                  ; 
        MOV     COS_VAL, 0              ; 
        MOV     SIN_VAL, 0              ;  
        XOR     BX, BX              ; Clear Counter
        
MOTORINITClearPWMvars:

        CMP     BX, numOfmotors     ; 
        JGE      MOTORINITInitVector ;
        
        MOV     S[BX], ZERO_SPEED_PWM   ; Clear PWM widths (not moving)
        MOV     S_PWM[BX], ZERO_SPEED_PWM   ; Clear PWM counters (fresh PWM cycle)
        INC     BX                      ; Increment counter/motor index
        JMP     MOTORINITClearPWMvars; Loop until all entries are cleared
        
MOTORINITInitVector:
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(MotorHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(MotorHandler)

MOTORINITCS:

        MOV     DX, _8255_CNTRL_REG
        MOV     AX, _8255_CNTRL_VAL
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

MotorHandler  PROC    NEAR
              PUBLIC  MotorHandler
           
    PUSHA   ; Always Save all regs in interrupt
MotorHandInit:

    XOR     BX, BX          ; Start with motor 0/ clear counter
    MOV     PORTB_BUFF, RESET   ; Clear portB such that we only need to turn on
                            ; bits we want. (No AND MASKs needed)
MotorHandLoop:
    CMP     BX, numOfmotors             ;
    JGE     LaserHandler                ;   
    ;JL     MotorHandPWMChk             ;

MotorHandPWMChk:
    CMP     S_PWM[BX], PWM_WIDTH_MAX    ;
    JBE      MotorHandPWMMux            ;
    ;JA    MotorHandPWMChkRESET         ;
MotorHandPWMChkRESET:
    MOV     S_PWM[BX], 0                ;
    ;JMP    MotorHandPWMMux             ;
    
MotorHandPWMMux:
    MOV     AL, S[BX]                   ; Grab counter ref value, it is used for many CMPs
    CMP     AL, 0                       ; Cx'th motor going reverse or forwards?
    JL      MotorHandPWM_NEG            ; Going reverse
    ;JGE    MotorHandPWM_POS            ; Going forward/stopped
    
MotorHandPWM_POS:
    CMP     S_PWM[BX], AL               ; Pwm counter over Active phase? (S_PWM[cx] < S[cx] ??)
    JGE     MotorHandOFFPHASE           ; Motor should be in inactive phase
    ;JL     MotorHandPOSPHASE           ; Motor should be active pos
MotorHandPOSPHASE:                      ;
    MOV     CL, CS:MOTORTABLE_POS[BX]
    OR      PORTB_BUFF, CL              ; Turn on appropriate bits for FORWARD
    JMP     MotorHandLoopEnd             ;
    
MotorHandPWM_NEG:
    NEG     AL                          ; Get the absolute value (we already know to go neg dir)
    CMP     S_PWM[BX], AL               ; Pwm counter over Active phase? (S_PWM[cx] < S[cx] ??)
    JGE     MotorHandOFFPHASE           ; Motor should be in inactive phase
    ;JL     MotorHandNEGPHASE           ; Motor should be active pos

MotorHandNEGPHASE:
    MOV     CL, CS:MOTORTABLE_NEG[BX]
    OR      PORTB_BUFF, CL              ; Turn on appropriate bits for FORWARD
    JMP     MotorHandLoopEnd    
    ;   
MotorHandOFFPHASE:
    ;OR      PORTB_BUFF, CS:BYTE PTR MOTORTABLE_ZERO[BX]; Turn on appropriate bits for FORWARD
    JMP     MotorHandLoopEnd 
    
MotorHandLoopEnd:
    INC     S_PWM[BX];
    INC     BX;
    JMP     MotorHandLoop
    
LaserHandler:
    CMP     LaserFlag, 0                ; Laser time?
    JG      LaserHandlerON              ; pew pew
    ;JLE    LaserHandlerOFF             ; don't pew pew 
    
LaserHandlerOFF:
    AND     PORTB_BUFF, LASER_OFF       ; Turn on appropriate bits for laser off
    JMP     MotorHandEOI                ;       

LaserHandlerON:
    OR      PORTB_BUFF, LASER_ON        ; Turn on appropriate bits for laser on
    ;JMP     MotorHandEOI               ;        

MotorHandEOI:
    MOV     DX, PORTB                  ;Finally write out the calculates Port B values
    MOV     AL, PORTB_BUFF
    OUT     DX, AL

    MOV     DX, INTCtrlrEOI             ;send the EOI to the interrupt controller
    MOV     AX, TimerEOI
    OUT     DX, AL
    
    POPA    ; Restore all regs (AX, BX, CX, and DX were used)
    
    IRET
    
 MotorHandler ENDP
;-------------------------------Stub Functions-----------------------------------
GetTurretAngle      PROC    NEAR
                    PUBLIC  GetTurretAngle
                    
    RET
    
GetTurretAngle ENDP

SetTurretAngle      PROC    NEAR
                    PUBLIC  SetTurretAngle
                    
    RET
    
SetTurretAngle ENDP

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
   
    Fx              DW  ?     ;Debounce count for single key press
    Fy              DW  ?     ;Debounce count for single key press
    COS_VAL         DW  ?     ;Debounce count for single key press
    SIN_VAL         DW  ?     ;Debounce count for single key press


    LaserFlag       DW  ?     ;Debounce count for auto-repeat key press
    
    S		DB	    numOfMotors	DUP	(?) ; Motor speed array (essentially PWM width)

    S_PWM   DB      numOfMotors DUP (?) ; Current motor pulse width counter
    
    PORTB_BUFF      DB  ?     ; Buffer for PORT B values (gets masked a lot)

    	
DATA    ENDS

        END 