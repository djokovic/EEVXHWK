NAME        Remote

$INCLUDE(remote.inc);
$INCLUDE(general.inc); Include files
$INCLUDE(display.inc);
$INCLUDE(chips.inc);
$INCLUDE(macros.inc);
$INCLUDE(queue.inc);
$INCLUDE(vectors.inc);
$INCLUDE(timer.inc);


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW9 Remote Mainloop Functions              ;
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
;   Procedures
;
;   Remote_FSM_LOOP     -   If available, dequeue next WORD in rx_queue
;   ParseRemoteWord     -   Parses four types of Event Handlers
;
;   HandleKey           -   Updates display and tx_queue with command
;   HandleSerErr        -   Displays serial chip error
;   ParseRemoteChar     -   Concatenates the status message as string. Then
;                           will display to user.
;   HandleModem         -   Stub function for now, since no flow control
;
;   RemoteParseInit     -   Initializes all parsing variables and ToggleHandler
;   ToggleHandler       -   Timer handler that actually Calls Display and cycles
;                           between displaying statuses.
;   GetTokenTypeVal     -   Grabs next token type and val
;   RemoteParseReset    -   Resets state machine variables for Remote FSM
;   SetError            -   Indicates RemoteFSM error
;   no_op               -   Just Returns
;   AddDirChar          -   Concat the Direction Status String from Robot
;   AddSpeedChar        -   Concat the Speed Status String from Robot
;
;   Tables
;   Token Tables        -   Contains all tokens/token vals for Remote FSM
;   Toggle_JMP_Table    -   Jump table inside Toggle handler, muxes what value display                    
;   Toggle_Label_Table  -   Muxes which value label to display
;   SerErrTable         -   Table of error strings for display
;   KeyDisplayTable     -   Table of cmd strings for display
;   KeyCmdTable         -   Table of strings cmds for Serial to Robot
;
;                              What's was last edit?
;
;       			Pseudo code ->  12-06-2013 - Anjian Wu
;                   Added KeyDisplayError/KeyDisplayInit Table -> 12-10-13 -AW
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP  GROUP   STACK, DATA

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP
        
;external function declarations
 
;Init/Setup Functions 
        EXTRN   InitUserInterfaceCS:NEAR  
        EXTRN   EnqueueEventInit:NEAR
        EXTRN   Timer0Init:NEAR  
        EXTRN   Timer1Init:NEAR  
        EXTRN   Timer2Init:NEAR  
        EXTRN   ClrIRQVectors:NEAR  
        EXTRN   KeyHandlerInit:NEAR  
        EXTRN   DisplayHandlerInit:NEAR  
        EXTRN   SerialInit:NEAR       
        
;Main Loop Fuctions
        EXTRN   Display:NEAR        
        EXTRN   DequeueEvent:NEAR    
        EXTRN   EnqueueEvent:NEAR           
        EXTRN   EventAvailable:NEAR        
        EXTRN   SerialPutChar:NEAR             
         

		
; Name:             Remote Main Loop
; Description:      This is the remote main loop
;
;                   *   Set up all initializations
;                   *   Enter remote_fsm_loop
;                   *   LOOP forever checking whether an event is available
;                       , if so dequeue it and pass to ParseRemoteWord
;
; Input:            None.
; Output:           None.
;
; User Interface:   None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;       			Initial Version ->  12-05-2013 - Anjian Wu
;----------------------------------------------------------------------------------------		
START:

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX
        
        CALL    ClrIRQVectors              ; Clear whole vector table with Illegal Function
        CALL    InitUserInterfaceCS        ; Initialize All UI hardware (keypad, display)
        CALL    Timer0Init                 ; Initialize timer 0 interrupt
        CALL    Timer1Init                 ; Initialize timer 1 interrupt
        CALL    Timer2Init                 ; Initialize timer 2 interrupt
        CALL    KeyHandlerInit             ; Initialize keypad function variables
        CALL    SerialInit                 ; Initialize serial function variables
        CALL    DisplayHandlerInit                ; Initialize display function variables
        CALL    EnqueueEventInit           ; Initialize the Event queue function vars
                                           
        CALL    RemoteParseInit            ;
        
        STI                                ; Start interrupts
        ;JMP     REMOTE_FSM_LOOP            ;

    
REMOTE_FSM_LOOP:
    
        CALL    EventAvailable              ; Is there a pending event? 
        JZ      RemoteFSMIdle               ; Event queue is empty, thus stay idle
        ;JNZ    RemoteFSMEvent              ; There was an event!
RemoteFSMEvent:

        CALL    DequeueEvent                ; Grab that event into AX
        CALL    ParseRemoteWord             ; Pass to get event parsed
        
RemoteFSMIdle:
    
JMP     REMOTE_FSM_LOOP                     ; Loop forever

; Name:             ParseRemoteWord
; Description:      Uses a call table to select the next function to call to handle
;                   the event type. The event val is passed to this function call.
;
; Input:            None.
; Output:           None.
;
; User Interface:   None.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;       			Initial Version ->  12-05-2013 - Anjian Wu
;----------------------------------------------------------------------------------------	
ParseRemoteWord     PROC    NEAR

; Arg: AX = [AH = key, AL = value]

    MOV     BL, AL                      ; Save event value
    XOR     BH, BH                      ; Isolate the Event val     
    
    XCHG    AH, AL                      ; Swap such that Event Type is LSNibble
    XOR     AH, AH                      ; Isolate the Event Type      

    SHL     AX, WORD_LOOKUP_ADJUST      ; Prepare for WORD table lookup
    XCHG    BX, AX                      ; Copy to BX for pointer, and AX now has Event val
    CALL    CS:Remote_Call_Table[BX]    ; Go to that FSM  function, passing Event val in AX
    
    RET
    
ParseRemoteWord ENDP

Remote_Call_Table	    LABEL	WORD
                                    
	DW		HandleKey 	        ;KEY_EVENT_KEY - An internal key press
	DW		HandleSerErr        ;SER_ERR_KEY   - An internal serial CHIP issue
	DW      ParseRemoteChar     ;RX_ENQUEUED_KEY - External serial char stream
	DW      HandleModem         ;MODEM_KEY - Internal serial chip modem issue


;Procedure:			HandleKey
;
;Description:      	Maps the key pressed into the command string with fixed length.
;                   Then that command is stored into the tx_queue. Also displays
;                   the proper message to the user describing the command.
;                
;Arguments:        	hexcode.
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
;Error Handling:   	If tx_queue is FULL, then stop and return.
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-06-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
HandleKey       PROC    NEAR

; Arg: AL = value

    MOV     CL, AL          ; Save a copy of AL
    
    %StrTblOffsetCalc_AX(CMD_LENGTH, KeyCmdTable)
                            ; Calc abs starting addr of the char string
                            ; AX = CMD_LENGTH*AL + OFFSET(KeyCmdTable)
    
    MOV     BX, AX          ; Need the abs addr in BX for XLAT
                            
    XOR     AL, AL          ; Clear counter
    
;-----------------------Loop enqueue the char string-----------------------------
HandleKeyEnqueue:
    CMP     AL, CMD_LENGTH          ; Go from AL = 0 to CMD_LENGTH - 1
    JGE     HandleKeyEnqueueDone    ; Yes, so exit loop
    
    PUSH    AX                      ; Save counter
    XLAT	CS:KeyCmdTable			; Get next char (at CS:BX[AL] -> AL by design)      
    CALL    SerialPutChar           ; Is TX_queue Full?
    
    POP     AX

    JC      HandleKeyError          ; Yes it is, tell user.
                                    ; Cannot send this char, exit this function
                                    ; immediately. Any partially sent string is unlikely
                                    ; to be valid string, thus ROBOT side will likely throw
                                    ; a string error as well.
    ;JNZ    HandleKeyEnqueueOk      ; It is ok to enqueue.
    
HandleKeyEnqueueOk:
    
    INC     AL                      ; Increment Counter
    
    JMP     HandleKeyEnqueue
;-----------------------Now update display for USER-----------------------------
HandleKeyEnqueueDone:
    XOR     AX, AX          ; 
    MOV     AL, CL          ; Restore the copy of event value
    %StrTblOffsetCalc_AX(Display_SIZE+1, KeyDisplayTables)
                            ; Calc abs starting addr of the char string
                            ; AX = (Display_SIZE+1)*AL + OFFSET(KeyDisplayTable)
    JMP     HandleKeyDone
    
HandleKeyError:
    MOV     AX, OFFSET(KeyDisplayError) ; Send out the Error TX display
    ;JMP     HandleKeyDone
HandleKeyDone:

    MOV     Action_Buff_PTR, AX ;   
    MOV     ToggleCTR, ACTION_LABEL;
    
    RET     
    
HandleKey   ENDP

KeyCmdTable	    LABEL	BYTE
;                   The way KEYS are mapped physically is...
;                   __________________________
;                  | [0]  |  [1]  | [2] | [3] |  
;                  |__________________________|
;                  | [4]  |  [5]  | [6] | [7] |
;  Keypad ------>  |__________________________|
;                  | [8]  |  [9]  | [10]| [11]|    
;                  |__________________________|
;                  | [12] |  [13] | [14]| [15]|  
;                  |_____ |_______|_____|_____|   
                             
	DB		'T',        '+',   '0015',     13 ;Key 0
	DB		'T',        ' ',   '0000',     13 ;Key 1
	DB      'T',        '-',   '0015',     13 ;Key 2
	DB      ' ',        ' ',   '    ',     13 ;Key 3
	DB      ' ',        ' ',   '    ',     13 ;Key 4
	DB      'O',        ' ',   '    ',     13 ;Key 5
	DB      'S',        ' ',   '0000',     13 ;Key 6
	DB      'F',        ' ',   '    ',     13 ;Key 7
	DB      ' ',        ' ',   '    ',     13 ;Key 8
	DB      'D',        '+',   '0015',     13 ;Key 9
	DB      'V',        '+',   '4369',     13 ;Key 10
	DB      'D',        '-',   '0015',     13 ;Key 11
	DB      ' ',        ' ',   '    ',     13 ;Key 12
	DB      'D',        '-',   '0090',     13 ;Key 13
	DB      'V',        '-',   '4369',     13 ;Key 14 
	DB      'D',        '+',   '0090',     13 ;Key 15
	DB      ' ',        ' ',   '    ',     13 ;Key Not assigned
	

KeyDisplayTables	    LABEL	BYTE
;                   The way KEYS are mapped physically is...
;                   __________________________
;                  | [0]  |  [1]  | [2] | [3] |  
;                  |__________________________|
;                  | [4]  |  [5]  | [6] | [7] |
;  Keypad ------>  |__________________________|
;                  | [8]  |  [9]  | [10]| [11]|    
;                  |__________________________|
;                  | [12] |  [13] | [14]| [15]|  
;                  |_____ |_______|_____|_____|     
; The addition of KeyDisplayInit and KeyDisplayError Tables
; to ease coding.
                          
	DB		'T ANG+  ', ASCII_NULL      ;Key 0
	DB		'T RESET ', ASCII_NULL      ;Key 1
	DB		'T ANG-  ', ASCII_NULL      ;Key 2
	DB		'NoNoNoNo', ASCII_NULL      ;Key 3	
	DB		'NoNoNoNo', ASCII_NULL      ;Key 4	
	DB		'LAZR OFF', ASCII_NULL      ;Key 5
	DB		'S T O P ', ASCII_NULL      ;Key 6
	DB		'LAZR ON ', ASCII_NULL      ;Key 7
	DB		'NoNoNoNo', ASCII_NULL      ;Key 8	
	DB		'DIR +15 ', ASCII_NULL      ;Key 9
	DB		'SPEED+  ', ASCII_NULL      ;Key 10
	DB		'DIR -15 ', ASCII_NULL      ;Key 11
	DB		'NoNoNoNo', ASCII_NULL      ;Key 12	
	DB		'DIR -90 ', ASCII_NULL      ;Key 13
	DB		'SPEED-  ', ASCII_NULL      ;Key 14
	DB		'DIR +90 ', ASCII_NULL      ;Key 15
    DB      'Special!', ASCII_NULL      ;NOT KEY
    
KeyDisplayInit     LABEL	BYTE
    DB      'PressKey', ASCII_NULL      ;Initial Message
KeyDisplayError     LABEL	BYTE
    DB      'TX FULL ', ASCII_NULL      ;TX queue is Full Error

;Procedure:			HandleSerErr
;
;Description:      	Determines which Serial error occurred at the chip,
;                   and informs the user to the issue.
;                
;Arguments:        	None.
;Return Values:    	none.
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
;History:			12-06-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
HandleSerErr    PROC    NEAR


    %StrTblOffsetCalc_AX(Display_SIZE+1, SerErrTable)
                            ; Calc abs starting addr of the char string
                            ; AX = Display_SIZE*AL + OFFSET(SerErrTable)
                            
    MOV     Error_Buff_PTR, AX ;   

    RET
    
HandleSerErr    ENDP

SerErrTable     LABEL       BYTE

    DB     'NO ERROR', ASCII_NULL   ;
    DB     'OVERRUN ', ASCII_NULL   ; Overrun serial error
    DB     '        ', ASCII_NULL   ;
    DB     'PARITY  ', ASCII_NULL   ; Parity serial error
    DB     '        ', ASCII_NULL   ;
    DB     'FRAME   ', ASCII_NULL   ; Frame serial error
    DB     '        ', ASCII_NULL   ;
    DB     '        ', ASCII_NULL   ;
    DB     '        ', ASCII_NULL   ;
    DB     'BREAK   ', ASCII_NULL   ; Break int


;Procedure:			HandleModem
;
;Description:      	Stub function for now.
;                
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	None
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
;History:			12-06-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
HandleModem    PROC    NEAR

    RET
    
HandleModem    ENDP

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
            
    MOV     Dir_PTR, zero               ; Initialize Direction Buff
    MOV     Spd_PTR, zero               ; Initialize Speed Buff
    MOV     ToggleCTR, zero             ; Start with first Status to toggle
    MOV     TogglePreScaler, zero
    
    MOV     Action_Buff_PTR, OFFSET(KeyDisplayInit) ; Display NO actions yet
    MOV     Error_Buff_PTR, OFFSET(SerErrTable)     ; Display NO error yet
    MOV     FSM_state, ST_INITIAL                   ;
    
    %DisplayCSStrPrep(AX)                           ;
    MOV     SI, Action_Buff_PTR                     ;
    CALL    Display                                 ;
    
    XOR     BX, BX                      ; Clear Counter
        
RemoteParseInitBufClear:

    CMP     BX, Display_SIZE             ; For each motor PWM counter
    JGE     RemoteParseInitBufClearDone ; If each done, then leave loop
    
    MOV     Dir_Buffer[BX], ASCII_NULL  ; Tell user we are going straight
    MOV     Spd_Buffer[BX], ASCII_NULL  ; Tell user we are not moving

    INC     BX                          ; Increment buffer/counter index
    JMP     RemoteParseInitBufClear     ; Loop until all entries are cleared
    
RemoteParseInitBufClearDone:

    XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX
                            ;store the vector
    MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(ToggleHandler)   ; Install ToggleHandler
    MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(ToggleHandler)
    

	RET
	
RemoteParseInit  ENDP  

;Function:			ToggleHandler
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
;                   12-11-2013: Fixed bug with prescaler and args passing to display - Anjian Wu
;------------------------------------------------------------------------------
ToggleHandler   PROC    NEAR
    
    PUSHA                               ; Save all Regs
TogglePrescale:
    INC     TogglePreScaler            ;
    CMP     TogglePreScaler, PRESCALE  ;
    JL      ToggleDone                  ; Not yet
    ;JGE     TogglePrescalePass          ;
TogglePrescalePass:    
    MOV     TogglePreScaler, zero      ;

    CMP     ToggleCTR, numOfStatus      ;
    JL      ToggleMux
    ;JGE    ToggleMuxReset
ToggleMuxReset:
    MOV     ToggleCTR, zero             ;
    ;JMP    ToggleMux                   ;
ToggleMux:
    MOV     BX, ToggleCTR               ;
    SHL     BX, 1                       ;
    JMP     CS:Toggle_JMP_Table[BX]     ;
    
T_Action_Val:    
    MOV     AX, Action_Buff_PTR
    %DisplayCSStrPrep(AX)                ;
    JMP     ToggleSet
    
T_Speed_Val: 	;3
    LEA     AX, Spd_Buffer
    %DisplayDSStrPrep(AX)                ;
    JMP     ToggleSet
    
T_Angle_Val:	    ;5
    LEA     AX, Dir_Buffer
    %DisplayDSStrPrep(AX)                ;
    JMP     ToggleSet
    
T_Error_Val:	    ;7
    MOV     AX, Error_Buff_PTR
    %DisplayCSStrPrep(AX)                ;
    JMP     ToggleSet
    
T_Label:
    MOV     AX, ToggleCTR                ;
    SHR     AX, bit_size                ; All 'labels' are EVEN indexed, thus we can
                                        ; map the JMP table offset to the string offset
                                        ; with just a simple SHR 1.
    %StrTblOffsetCalc_AX(Display_SIZE+1, Toggle_Label_Table); Calc ABS address into AX
    
    MOV     SI, AX                      ; Need abs address in SI
    
    %DisplayCSStrPrep(AX)               ; String in CS
    ;JMP     ToggleSet
    
ToggleSet:
    CALL    Display                     ; Pass ES:SI to be displayed
    
    INC     ToggleCTR                   ;
    
ToggleDone:; Send out EOI as usual

    MOV     DX, INTCtrlrEOI             ;All timers share same EOI
    MOV     AX, TimerEOI
    OUT     DX, AL                      ; Send out Timer EOI
    
    
    POPA                                ; Restore all Regs
    
    IRET
    
ToggleHandler   ENDP


Toggle_Label_Table	    LABEL	BYTE

                          
	DB		'Action:?', ASCII_NULL      ;0
	DB		'Speed: ?', ASCII_NULL      ;1
	DB		'Angle: ?', ASCII_NULL      ;2
	DB		'Errors:?', ASCII_NULL      ;3


Toggle_JMP_Table	    LABEL	WORD
                                    
	DW		T_Label 	    ;0 - Action Label
	DW		T_Action_Val    ;1
	DW		T_Label 	    ;2 - Speed Label
	DW		T_Speed_Val 	;3
	DW		T_Label 	    ;4 - Angle Label
	DW		T_Angle_Val	    ;5
	DW		T_Label 	    ;6 - Error Label
	DW		T_Error_Val	    ;7
    
    
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
;                   12-10-2013: Adapted for Remote - Anjian Wu
;------------------------------------------------------------------------------

ParseRemoteChar		PROC	NEAR

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
;History:			12-10-2013: Created - Anjian Wu
;------------------------------------------------------------------------------
RemoteParseReset  PROC    NEAR
            
    MOV     Dir_PTR, zero               ; Set default val as positive
    MOV     Spd_PTR, zero               ; Set Default FSM machine state
    MOV     FSM_state, ST_INITIAL       ;
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

    CMP     Dir_Ptr, Display_SIZE    ;
    
    JG      AddDirCharDone          ;
    
    XOR     BH, BH                  ;
    MOV     BL, Dir_PTR             ;
 
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

    CMP     Spd_Ptr, Display_SIZE    ;
    
    JG      AddDirCharDone          ;
    
    XOR     BH, BH                  ;
    MOV     BL, Spd_Ptr             ;
 
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
        %TABENT(TOKEN_OTHER, 9)     ;TAB
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
        %TABENT(TOKEN_OTHER, 1)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_OTHER, -1)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_NUM, '0')	    ;0  (digit)
        %TABENT(TOKEN_NUM, '1')		;1  (digit)
        %TABENT(TOKEN_NUM, '2')		;2  (digit)
        %TABENT(TOKEN_NUM, '3')		;3  (digit)
        %TABENT(TOKEN_NUM, '4')		;4  (digit)
        %TABENT(TOKEN_NUM, '5')		;5  (digit)
        %TABENT(TOKEN_NUM, '6')		;6  (digit)
        %TABENT(TOKEN_NUM, '7')		;7  (digit)
        %TABENT(TOKEN_NUM, '8')		;8  (digit)
        %TABENT(TOKEN_NUM, '9')		;9  (digit)
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

Dir_Buffer      DB  Display_SIZE+1	DUP	(?)   ;
Dir_PTR         DB  ?                         ;

Spd_Buffer      DB  Display_SIZE+1	DUP	(?)   ; 
Spd_PTR         DB  ?                         ;

Action_Buff_PTR DW  ?                         ;

Error_Buff_PTR  DW  ?                         ;

Errorflag       DW      ?                     ; Holds error type

FSM_state       DB      ?                     ; Holds the current state of FSM

ToggleCTR       DW      ?                     ;

TogglePreScaler DW      ?                     ;


DATA    ENDS

;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START