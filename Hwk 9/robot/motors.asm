NAME        Motors

$INCLUDE(motors.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);
$INCLUDE(vectors.inc);

CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
;External Procedures needed
        EXTRN   XWORDLAT:NEAR       ; Used to grab elements from WORD table
        EXTRN   Cos_Table:NEAR      ; Table for COS operations
        EXTRN   Sin_Table:NEAR      ; Table for SIN operations
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
;   GetMotorSpeed  -   Retrieves the motor speed 
;   GetMotorDirection  -  retrieves motor angle (0 to 359 deg)
;   SetLaser        -   Turns on/off the laser
;   GetLaser        -   Checks if Laser is turned on or not
;
;
;   MotorInit       - Initializes all motor vars, installs handler and sets up CS
;   MotorHandler    -   Interrupt handler that outputs to PORTB with proper PWM
;   SetMotor_GetTrig -   Used by MotorHandler to grab COS_VAL and SIN_VAL
;   SetMotor_GetArgs -   Used by MotorHandler to grab Fx and Fy values

;
;                                   Data Segment
;
;
;   s           -   this is the PWM width value set by SetMotorSpeed for each motor
;   s_pwm       -   This is the PWM counter that keeps track of where in the 
;                   PWM phase each motor is in.
;   SpeedStored -   Current ABS motor speed
;   AngleStored -   Current robot moving angle
;   LaserFlag   -   Status of laser
;   portb_buff  -   Holds the buffer value to be outputted.
;
;                                  Temporary Stack Variables
;
;   Fx          -   This is the calculated Fx component, which changed per motor 
;   Fy          -   This is the calculated Fy component, which changed per motor 
;   COS_VAL     -   Stores the COS(anglestored)
;   SIN_VAL     -   Stores the SIN(anglestored)
;
;                                 What's was last edit?
;
;       			Pseudo code -> 11-18-2013 - Anjian Wu
;       			Finished, but buggy -> 11-20-2013 - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;       			Added Stack Variables -> 11-24-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			SetMotorSpeed
;
;Description:      	This function performs the holonomic calculations for each
;                   respective motor by storing the speed and angle passed, as
;                   well as calculating each motor's PWM length/counter such that
;                   the overall speed and angle of the system matches the stored
;                   angle and speed. Ultimately the function's stored
;                   PWM values for each counter (aka s[0 to 2]) will be accessed
;                   by the MotorHandler as the PWM width reference by which
;                   each motor can be turned on or off.
;           
;                   
;Operation:			1.Check Angle 2.Angle Calc 3.Check Speed 4. Speed Calc
;
;                                           Check Angle
;                   * Check if angle needs to be changed (comp to NO_ANGLE_CHANGE)
;                       * If not, then use previous anglestored and go to Check Calc
;
;                                           Angle Calc
;                   * AngleStored = BX MOD FULL_ANGLE
;                       * If angle is neg, AngleStored = AngleStored + FULL_ANGLE deg
;
;                                           Check Speed
;                   * Check if speed needs to be changed (comp to NO_SPEED_CHANGE)
;                       * If not, then use previous speedstored and go to Speed Calc
;
;                                           SpeedCalc
;                   * Grab speed. Divide speed by two (To get into range 0 to 7FFFH)
;                     Do this because upper half of the range would appear negative.
;                   * For each i'th motor out of numOfMotors
;                       *   CALL SetMotor_GetArgs(i)
;                       *   CX = TopWordOf(TopWordOf(Fx * speedstored) * COS_VAL)
;                       *   DX = TopWordOf(TopWordOf(Fy * speedstored) * SIN_VAL)
;                       *   s[i] = TopByteOf((CX + DX) << 2)
;                   * DONE
;
;Arguments:        	AX     -> ABS speed to be set
;                   BX     -> Angle to be set
;
;Return Values:    	None.
;
;Result:            Possibly new values in s[0 to 2], speedstored, and anglestored
;
;Shared Variables: 	s[0 to 2]   (WRITE)
;                   SpeedStored (WRITE/READ) 
;                   AngleStored (WRITE/READ)
;
;Local Variables:	AX      -   Used for DIV and MUL operations
;                   BX      -   Counter as well as pointer
;                   CX      -   Used for ADDing X and Y components
;                   DX      -   Holds MOD and remainder values
;                   ES      -   Used to pass Code Segment
;                   Fx (SP -2)  - Holds Fx component per i'th motor
;                   Fy (SP -4)  - Holds Fy component per i'th motor
;                   COS_VAL(SP -6)  - Holds the COS(ANGLESTORED)
;                   SIN_VAL (SP -8) - Holds the SIN(ANGLESTORED)
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	AX, BX, CX, DX, ES.
;
;Stack Depth:		8 words + SetMotorVarSize
;
;Known Bugs:		None.
;
;Data Structures:	1D array. Stack frame
;
;Error Handling:   	none.
;
;Algorithms:       	Tables driven loop up to get values for COS_VAL, SIN_VAL, FX, and Fy
;                   Math Algorithm ( * = IMUL)
;                       *   CX = TopWordOf(TopWordOf(Fx * speedstored) * COS_VAL)
;                       *   DX = TopWordOf(TopWordOf(Fy * speedstored) * SIN_VAL)
;                       *   s[i] = TopByteOf((CX + DX) << 2) ; Cut off repetitive sign bits
;                   
;
;Limitations:  		Limited to 127 bits of resolution for PWM.
;                   Also during operation, Shared variables will be changed
;                   as the MotorHandler is READing from those variables. However
;                   it should not affect operation much.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;                   12-12-2013 -> Added PUSH/POPS to save args
;------------------------------------------------------------------------------
; SetMotorSpeed Local Vars (In motors.inc but commented here for reference)
;Fx          EQU     WORD PTR [BP - 2]   ; Stores the Fx component for each motor
;Fy          EQU     WORD PTR [BP - 4]   ; Stores the Fy component for each motor
;COS_VAL     EQU     WORD PTR [BP - 6]   ; Stores the COS(ANGLESTORED)
;SIN_VAL     EQU     WORD PTR [BP - 8]   ; Stored the SIN(ANGLESTORED)

SetMotorSpeed		PROC    NEAR
				    PUBLIC  SetMotorSpeed
    PUSH    AX
    PUSH    BX
                    
SetMotorStackFrameInit:
    PUSH    BP                      ;save BP
    MOV     BP, SP                  ;and get BP pointing at our stack frame
    SUB     SP, SetMotorVarSize        ;save space on stack for local variables

    PUSHA           ; Save all regs used (AX - DX)
SetMotorSpeedAngChk:

	PUSH	AX						; Save Speed for later
    CMP     BX, NO_ANGLE_CHANGE     ; Do we need to change the angle?
    JNE     SetMotorAngleCalc       ; Yes
    JE      SetMotorSpeedChk        ; No, go to speed check

SetMotorAngleCalc:

	MOV		AX, BX					; Need to use AX specifically for IDIV
    MOV     BX, FULL_ANGLE          ; 
    CWD                             ; Prepare for signed DIV
    IDIV    BX          	        ; Take the MOD to Full angle
; Angle now in DX since we want MOD
	CMP		DX,	ZERO_ANGLE			; Is the Angle Neg?
	JGE		SetMotorAngleSave		; Nope, store it
	;JL		SetMotorAngleNeg		; Yes, it is ,need adjustment

SetMotorAngleNeg:
	ADD		DX, FULL_ANGLE			; Calc positive equivalent angle
	;jmp    SetMotorAngleSave
SetMotorAngleSave:
	MOV		AngleStored, DX			; Store this abs angle
    ;jmp    SetMotorSpeedChk
SetMotorSpeedChk:
    POP     AX                      ; Now retrieve the Speed Arg
	CMP		AX, NO_SPEED_CHANGE     ; Are we changing the speed?
    JE      SetMotor_SpeedCalcInit  ; No, so Start speed calculations
    ;JNE    SetMotorDiffSpeed       ; Yes, so save that speed
    
SetMotorDiffSpeed:  
    MOV     SpeedStored, AX         ; Store that speed
    ;JMP    SetMotor_SpeedCalcInit
    
;-----------------------Motor Speed Math---------------------------------

SetMotor_SpeedCalcInit:
    XOR     BX, BX                  ; Clear loop counter
    MOV     AX, CS
    MOV     ES, AX                  ; Prepare to use XWORDLAT in code segment
    CALL    SetMotor_GetTrig        ; Grab COS(AngleStored) and SIN(AngleStored)
                                    ; This only needs to be done ONCE
    
SetMotor_CalcLoop:  
    CMP     BX, numOfmotors         ; Is the counter done with all motors?
    JGE     SetMotor_DONE           ; Yes, done
    ;JL     SetMotor_GrabAllArgs    ; No, keep going
    
SetMotor_GrabAllArgs:     
    CALL    SetMotor_GetArgs        ; Update Fx, and Fy values for BX'th motor
                                    ; Must be done every loop...
                                    ; Passes ES, and CX
SetMotor_CalcX:     

    MOV     AX, SpeedStored         ; Grab current speed 
    SHR     AX, SPEED_ADJUST        ; Div Speed to get into range [0, 7FFFH]     
    IMUL    Fx                      ; Fx * SpeedStored. 
    MOV     AX, DX                  ; Truncated answer in DX
    IMUL    COS_VAL                 ; (Fx * SpeedStored)*COS(AngleStored)    
    MOV     CX, DX;    
SetMotor_CalcY:   
 
    MOV     AX, SpeedStored         ; Grab current speed 
    SHR     AX, SPEED_ADJUST        ; Div Speed by two to get into range [0, 7FFFH]     
    IMUL    Fy                      ; Fy * SpeedStored. 
    MOV     AX, DX                  ; Truncated answer in DX
    IMUL    SIN_VAL                 ; (Fy * SpeedStored)*SIN(AngleStored)
    
    ADD     CX, DX                  ; Add X and Y components
    
    SAL     CX, EXTRA_SIGN_BITS     ; Take out the duplicated sign bits
    
    MOV     s[BX], CH               ; Store (Fx * v * cos q + Fy * v * sin q)

SetMotor_LoopDone:
    
    INC     BX                      ; Increment the counter
    JMP     SetMotor_CalcLoop       ; LOOP
    
SetMotor_DONE:

    POPA    ; Restore all regs used.

    ADD     SP, SetMotorVarSize        ;release local variables from stack
    POP     BP                      ;restore BP

    POP     BX
    POP     AX
    
    RET

SetMotorSpeed ENDP

;Procedure:			SetMotor_GetTrig
;
;Description:      	This function updates COS_VAL, and SIN_VAL for SetMotor's math. It does this
;                   through using the Cos_Table and Sin_Table. Since these are WORD tables, 
;                   the actual table grabbing is done though function XWORDLAT (from General.asm).
;                   Note this function is only use in SetMotorSpeed since COS_VAL and SIN_VAL
;                   are store in Stack frame.
;           
;                   NOTE: XWORDLAT takes the following ARGs.
;                   XWORDLAT(AX = table offset, BX = relative offset, ES = CS or DS)
;
;                   By doing this, the SetMotorSpeed is easier to debug since stack variables
;                   can be easily searched before SetMotorSpeed finishes, while also avoiding
;                   using permanent data segment space.
;                   
;Operation:			
;                                           COS Grab
;                   * CALL XWORDLAT(AX = offset(Cos_Table) , AngleStored)
;                   * COS_VAL = AX.
;                                           SIN Grab
;                   * CALL XWORDLAT(AX = offset(Sin_Table) , AngleStored)
;                   * SIN_VAL = AX.
;
;Arguments:        	BX     -> Motor index (0 to numOfMotors -1)
;                   ES     -> Code segment or Data segment
;                   BP     -> Where local variables COS_VAL and SIN_VAL are.
;
;Return Values:    	None.
;
;Result:            Updated COS_VAL, SIN_VAL for SetMotorSpeed
;
;Shared Variables: 	AngleStored (READ)
;
;Local Variables:	AX      -   Used as table offset arg to pass to XWORDLAT, also holds
;                               XWORLAT return values.
;                   BX      -   Used as relative pointer arg for XWORDLAT
;                   ES      -   Used to pass Code Segment
;                   COS_VAL(BP -6)  - Holds the COS(ANGLESTORED)
;                   SIN_VAL (BP -8) - Holds the SIN(ANGLESTORED)
;                   
;
;Global Variables:	None.
;						
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	AX, BX, ES.
;
;Stack Depth:		2 words.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:       	Table look up. Stack frame
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
SetMotor_GetTrig		PROC    NEAR

    PUSH    BX                      ; Save All Used Regs
    PUSH    AX;
GetTrigInit:

; NOTE XWORDLAT does not change BX

GetTrigCos:
    MOV     BX, AngleStored         ; Grab stored angle, this is the proper element
                                    ; index for look up
; Grab Cos(AngleStored)    
    MOV     AX, offset(Cos_Table)   ; Do COS operation table lookup
    CALL    XWORDLAT                ; COSVal component in AX
    MOV     COS_VAL, AX             ; Save it
    
GetTrigSin:
; Grab Sin(AngleStored)    
    MOV     AX, offset(Sin_Table)   ; Do SIN operation table lookup
    CALL    XWORDLAT                ; SIN_VAL component in AX
    MOV     SIN_VAL, AX             ; Save it

GetTrigDone:

    POP    AX;
    POP    BX                      ; Restore all used regs
    
    RET
    
SetMotor_GetTrig    ENDP

;Procedure:			SetMotor_GetArgs
;
;Description:      	This function takes in a relative pointer (BX), and memory segment (ES)
;                   and updates stack variables Fx, Fy for SetMotorSpeed. It does this
;                   through using the relative pointer ARG on tables MotorFTable
;                   
;                   Since these are WORD tables, the actual table grabbing is
;                   done though function XWORDLAT (from General.asm).
;           
;                   NOTE: XWORDLAT takes the following ARGs.
;                   XWORDLAT(AX = table offset, BX = relative offset, ES = CS or DS)
;
;                   By doing this, the SetMotorSpeed is easier to debug since stack variables
;                   can be easily searched before SetMotorSpeed finishes, while also avoiding
;                   using permanent data segment space.
;                   
;Operation:			
;                                           Fx Grab
;                   * CALL XWORDLAT(AX = offset(MotorFTable), BX = i'th motor)
;                   * Fx = AX.
;                                           Fy Grab
;                   * CALL XWORDLAT(AX = offset(MotorFTable) + 2*FY_OFFSET, BX = i'th motor)
;                   * Fy = AX.
;
;Arguments:        	BX     -> Motor index (0 to numOfMotors -1)
;                   ES     -> Code segment or Data segment
;
;Return Values:    	None.
;
;Result:            Updated Fx, Fy for SetMotorSpeed
;
;Shared Variables: 	SpeedStored (READ) 
;                   AngleStored (READ)
;
;Local Variables:	AX      -   Used as table offset arg to pass to XWORDLAT, also holds
;                               XWORLAT return values.
;                   BX      -   Used as relative pointer arg for XWORDLAT
;                   ES      -   Used to pass Code Segment
;                   Fx (SP -2)  - Holds Fx component per i'th motor
;                   Fy (SP -4)  - Holds Fy component per i'th motor
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	AX, BX, ES.
;
;Stack Depth:		2 words.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:       	Table look up.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------

SetMotor_GetArgs		PROC    NEAR

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
    MOV     AX, offset(MotorFTable) + 2*FY_OFFSET ; First grab CX'th Fy component
                                                  ; 2x FY_OFFSET since this is
                                                  ; WORD table and offset is in
                                                  ; terms of 'elements'
                                                  
    CALL    XWORDLAT                ; Fx component in AX
    MOV     Fy, AX                  ; Save it

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
;Operation:			Simply Returns the speedstore value
;Arguments:        	None.
;Return Values:    	AX -> Speedstore
;Result:            Grabs the current motor speed for User.
;Shared Variables: 	Speedstore (Read)
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	AX
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
GetMotorSpeed		    PROC    NEAR
                        PUBLIC  GetMotorSpeed

    MOV     AX, SpeedStored; Grab the stored speed
    RET

GetMotorSpeed ENDP

;Procedure:			GetMotorDirection
;
;Description:      	This function returns the value of the motor angle. This value
;                   is exactly the anglestore shared variable. 
;Operation:			Simply Returns the anglestore 
;Arguments:        	None.
;Return Values:    	AX -> the angle to be returned, between 0 and 359 deg
;Result:            Grabs the current motor speed for User.
;Shared Variables: 	anglestore (Read)
;Local Variables:	None.
;Global Variables:	None.									
;Input:            	None.
;Output:           	None.
;Registers Used:	AX
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
GetMotorDirection		    PROC    NEAR
                            PUBLIC  GetMotorDirection

    MOV     AX, AngleStored; Grab the angle stored
    RET
GetMotorDirection ENDP

;Procedure:			SetLaser
;
;Description:      	This function will turn the robot laser on or off depending
;                   on the passed arg in AX. If AX is 0 then lazer is turned off.
;                   Else it is turned on. Also will record laser status in LaserFlag.
;Operation:			* Compare arg to zero
;                   * If zero then turn clear LaserFlag
;                   * If not then set LaserFlag
;                   
;Arguments:        	arg -> AX -> on or off.
;Return Values:    	None.
;Result:            Updates LaserFlag
;Shared Variables: 	LaserFlag (Write)
;Local Variables:	None.                  
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	AX
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------

SetLaser		    PROC    NEAR
                    PUBLIC  SetLaser
    MOV     LaserFlag, AX; Store new laserflag
    RET
SetLaser ENDP

;Procedure:			GetLaser
;
;Description:      	This function returns the value of the LaserFlag. This value
;                   is exactly the LaserFlag shared variable. It will simply return
;                   this value. Zero value indicates FALSE, other wise TRUE.
;Operation:			Simply Returns the LaserFlag value
;Arguments:        	None.
;Return Values:    	AX -> LaserFlag
;Result:            Grabs the current motor speed for User.
;Shared Variables: 	LaserFlag (Read)
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	AX
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
GetLaser		    PROC    NEAR
    MOV     AX, LaserFlag; return laserflag
    RET
GetLaser ENDP

; MOTORINIT
;
; Description:       Does all initializations for Motors.
;
;                    Installs the MotorHandler for the timer0 interrupt at 
;                    interrupt table index Tmr0Vec. ALso clears the 
;                    LaserFlag, SpeedStored, s[0 to 2], AngleStored, s_pwm
;                    Thus rendering the motors NOT moving, and at 0 deg angle.
;
;                    Also sets up the PORTB on the 8255 and proper chip select
;
; Operation:         First clear LaserFlag, SpeedStored, s[0 to 2], AngleStored, 
;                    s_pwm.
;
;                    Then writes the address of the MotorHandler to the
;                    timer0 location in the interrupt vector table. Notice
;                    need to multiple by 4 since table stores a CS and IP.
;
;                    Setup Parallel Chip control reg for MODE0 in both group A and B
;
;                    Then set up chip select and PORTB control word values
;                     
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Used to temporarily store vector table offset for ES and for
;                         PORt values to be outputted.
;                    DX - used for PORT outputs
;                    BX - used as counter and pointer 
; 
; Shared Variables:  LaserFlag (WRITE)
;                    SpeedStored (WRITE)
;                    AngleStored (WRITE)
;                    s[0 to 2] (WRITE)
;                    s_pwm (WRITE)
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
; Registers Used:    AX, ES, BX, DX
;
; Stack Depth:       0 words
;
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu

;-------------------------------------------------------------------------------

MOTORINIT          PROC    NEAR
                   PUBLIC  MOTORINIT
                   
MOTORINITInitStart:
        MOV     LaserFlag, FALSE            ; Laser OFF
        MOV     SpeedStored, STOPPED_SPEED  ; Should NOT be moving
        MOV     AngleStored, ZERO_ANGLE   	; Going straight 
        MOV     s_pwm, ZERO_SPEED_PWM       ; Should NOT be moving e.g. PWM = 0

        XOR     BX, BX                      ; Clear Counter
        
MOTORINITClearPWMvars:

        CMP     BX, numOfmotors             ; For each motor PWM counter
        JGE     MOTORINITInitVector         ; If each done, then leave loop
        
        MOV     s[BX], ZERO_SPEED_PWM       ; Should NOT be moving
        INC     BX                          ; Increment counter/motor index
        JMP     MOTORINITClearPWMvars       ; Loop until all entries are cleared
        
MOTORINITInitVector:
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(MotorHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(MotorHandler)

MOTORINITCS:

        MOV     DX, _8255_CNTRL_REG ; Set up parallel chip
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
;                   by looping through each motor which share the s_pwm counter and determining
;                   which phase in the PWM each motor is in. It will then set the
;                   PORT B buffer appropriately, ultimately outputting the final result
;                   to the parallel chip.
;
;                   Approach is to CLEAR the portb_buff at the beginning of the interrupt, 
;                   by doing this, only OR masks are needed to turn on only the bits necessary.
;                   The function will then mux which MASKS to use accordingly to the sign of 
;                   each s[i'th] PWM ref of each motor, as well as whether s_pwm is < abs(s[i'th]).
;                   If in inactive PWM phase, then AND maskes are used to only turn off
;                   forward bits, without touching REVERSE bit.
;                                    
;                   
;Operation:			*   Clear i(BX) and portb_buff (assuming neither motor or laser on)
;                   *   Is s_pwm above PWM_WIDTH_MAX? If so reset s_pwm, else continue
;                   *   For i < numOfMotors
;                       *   If s[i] is < 0, then 
;                           *   If  neg(s[i]) > s_pwm
;                               *   Grab mask from MOTORTABLE_NEG[at i'th offset]
;                               *   OR MASK portb_buff
;                       *   If s[i] is >= 0, then 
;                           *   If  (s[i]) > s_pwm
;                               *   Grab mask from MOTORTABLE_POs[at i'th offset]
;                               *   OR MASK portb_buff
;                       *   Else ; we are in inactive phase of PWM
;                           *   Mask off only the FORWARD bit of i'th motor
;                   *   Is the LaserFlag set?
;                       * If so OR MASK portb_buff with LASER_ON
;                       * Else keep going
;                   *   Increment s_pwm, OUTPUT portb_buff to parallel chip
;                   *   Send out interrupt EOI
;                               
;
;Arguments:        	None.
;
;Return Values:    	None.
;
;Result:            Sets each individual motor's PORTB bit depending on PWM phase of
;                   eash motor. Also sets Laser's bit.
;
;Shared Variables: 	s[bx](READ)             - this is the PWM width value set by SetMotorSpeed
;                   s_pwm(WRITE/READ)       - This is the PWM counter that keeps track of
;                                             where in the PWM phase each motor is in.
;
;Local Variables:	portb_buff(WRITE/READ)   - Stores the bits which will eventually be written out to
;                                              the parallel chip.
;                   BX  -   Stores counter for each motor, and acts as pointer for table
;                   AL  -   Holds the s[i] values for compares
;                   DX  -   Holds address for PORT writing
;                   CL  -   Holds bits that are MASKED on  
;
;Global Variables:	None.
;					
;Input:            	None.
;
;Output:           	Each motor via PORT B on the parallel chip.
;
;Registers Used:	AL, BX, CL, DX
;
;Stack Depth:		8 words
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None
;
;Algorithms:       	Table look up.
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

    XOR     BX, BX              ; Start with motor 0/ clear counter
    MOV     portb_buff, RESET   ; Clear portB such that we only need to turn on
                                ; bits we want. (No AND MASKs needed)
MotorHandPWMChk:
    CMP     s_pwm, PWM_WIDTH_MAX    ; Is the current PWM counter outside PWN range?
    JBE     MotorHandLoop           ; Nope, proceed
    ;JA    MotorHandPWMChkRESET     ; Yes it is, clear it.
MotorHandPWMChkRESET:
    MOV     s_pwm, RESET            ; Reset the PWM counter to beginning of PWM phase
    ;JMP    MotorHandLoop           ;

MotorHandLoop:
    CMP     BX, numOfmotors             ; For each numOfmotors motors
    JGE     LaserHandler                ; If each is done, proceed to Laser handling
    ;JL     MotorHandPWMMux             ;
    
MotorHandPWMMux:
    MOV     AL, s[BX]                   ; Grab counter ref value, it is used for many CMPs
    CMP     AL, ZERO_SPEED_PWM          ; Bx'th motor going reverse or forwards?
    JL      MotorHandPWM_NEG            ; Going reverse
    ;JGE    MotorHandPWM_POS            ; Going forward/stopped
    
MotorHandPWM_POS:
    MOV     CL, CS:MOTORTABLE_POs[BX]
    OR      portb_buff, CL              ; Turn on appropriate bits for FORWARD
    
    CMP     s_pwm, AL                   ; Pwm counter over Active phase? (s_pwm < s[bx])
    JGE     MotorHandOFFPHASE           ; Motor should be in inactive phase
    JMP     MotorHandLoopEnd            ;
    
MotorHandPWM_NEG:
    NEG     AL                          ; Get the absolute value (we already know to go neg dir)
    MOV     CL, CS:MOTORTABLE_NEG[BX]   ; Grab REVERSE mask from table on bx'th motor.
    OR      portb_buff, CL              ; Turn on appropriate bits for REVERSE
    
    CMP     s_pwm, AL                   ; Pwm counter over Active phase? (s_pwm < s[bx])
    JGE     MotorHandOFFPHASE           ; Motor should be in inactive phase
    JMP     MotorHandLoopEnd       
    
MotorHandOFFPHASE:
    MOV     CL, CS:MOTORTABLE_ZERO[BX]   ; Grab OFF mask from table on bx'th motor.
    AND      portb_buff, CL              ; Turn OFF forward bits, while leaving reverse
                                         ; bit untouched.
    ;JMP     MotorHandLoopEnd            ; 
    
MotorHandLoopEnd:
    INC     BX;
    JMP     MotorHandLoop
 ;-------------------------------Laser Functions-----------------------------------
   
LaserHandler:
    CMP     LaserFlag, FALSE            ; Laser time?
    JNE     LaserHandlerON              ; pew pew
    ;JE     LaserHandlerOFF             ; Turn off laser
    
LaserHandlerOFF:
    JMP     MotorHandEOI                ; Don't turn on laser

LaserHandlerON:
    OR      portb_buff, LASER_ON        ; Turn on appropriate bits for laser on
    ;JMP     MotorHandEOI               ;        

MotorHandEOI:
    INC     s_pwm                      ; Update shared PWM counter

    XOR     DX, DX
    MOV     DX, PORTB                  ;Finally write out the calculates Port B values
    MOV     AL, portb_buff
    OUT     DX, AL

    MOV     DX, INTCtrlrEOI             ;send the EOI to the interrupt controller
    MOV     AX, TimerEOI
    OUT     DX, AL
    
    POPA    ; Restore all regs (AX, BX, CX, and DX were used)
    
    IRET
    
 MotorHandler ENDP
;-------------------------------Stub Functions-----------------------------------
;Procedure:			GetTurretAngle
;
;Description:      	This function is just a stub function
;Operation:			Just returns
;Arguments:        	None.
;Return Values:    	None.
;Result:            None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
GetTurretAngle      PROC    NEAR
                    PUBLIC  GetTurretAngle
                    
    RET
    
GetTurretAngle ENDP
;Procedure:			SetTurretAngle
;
;Description:      	This function is just a stub function
;Operation:			Just returns
;Arguments:        	None.
;Return Values:    	None.
;Result:            None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
SetTurretAngle      PROC    NEAR
                    PUBLIC  SetTurretAngle
                    
    RET
    
SetTurretAngle ENDP
;Procedure:			SetRelTurretAngle
;
;Description:      	This function is just a stub function
;Operation:			Just returns
;Arguments:        	None.
;Return Values:    	None.
;Result:            None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
SetRelTurretAngle      PROC    NEAR
                        PUBLIC  SetRelTurretAngle
                    
    RET
    
SetRelTurretAngle ENDP
;Procedure:			SetTurretElevation
;
;Description:      	This function is just a stub function
;Operation:			Just returns
;Arguments:        	None.
;Return Values:    	None.
;Result:            None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
SetTurretElevation      PROC    NEAR
                    PUBLIC  SetTurretElevation
                    
    RET
    
SetTurretElevation ENDP
;Procedure:			GetTurretElevation
;
;Description:      	This function is just a stub function
;Operation:			Just returns
;Arguments:        	None.
;Return Values:    	None.
;Result:            None.
;Shared Variables: 	None.
;Local Variables:	None.
;Global Variables:	None.								
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		N/A
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-18-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;------------------------------------------------------------------------------
 GetTurretElevation      PROC    NEAR
                    PUBLIC  GetTurretElevation
                    
    RET
    
GetTurretElevation ENDP

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
; Description:      This table contains all the MASK values for AND mask
;                   such that when masked with PORTB bits, it will set
;                   the (i+1)'th motor to stop.
;
; Author:           Anjian Wu
; Last Modified:    11/18/2013


MOTORTABLE_ZERO	    LABEL	BYTE
                    PUBLIC  MOTORTABLE_ZERO
                                    
	DB		STOP_M1 	;MASK BACKWARD for Motor 1
	DB		STOP_M2 	;MASK BACKWARD for Motor 2
	DB		STOP_M3 	;MASK BACKWARD for Motor 3
			
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'


    SpeedStored     DW  ?     ;Stores current speed                                        
    AngleStored     DW  ?     ;Stores current motor angle
    LaserFlag       DW  ?     ;Flag for whether laser should be on
    s		DB	    numOfMotors	DUP	(?) ; Motor speed array (essentially PWM width)
    s_pwm   DB      ? ; Current motor pulse width counter  
    portb_buff      DB  ?     ; Buffer for PORT B values (gets masked a lot)

    	
DATA    ENDs

        END 