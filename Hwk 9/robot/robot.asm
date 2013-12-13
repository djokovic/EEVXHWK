NAME        Robot

$INCLUDE(robot.inc);
$INCLUDE(general.inc); Include files
$INCLUDE(chips.inc);
$INCLUDE(macros.inc);
$INCLUDE(queue.inc);
$INCLUDE(vectors.inc);
$INCLUDE(timer.inc);
$INCLUDE(display.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW9 Robot Mainloop Functions               ;
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
        EXTRN   ClrIRQVectors:NEAR  
        EXTRN   KeyHandlerInit:NEAR  
        EXTRN   Motorinit:NEAR  
        EXTRN   SerialInit:NEAR   
        EXTRN   ParseSerialChar:NEAR
        EXTRN   ParseReset:NEAR
       
;Main Loop Fuctions
        EXTRN   DequeueEvent:NEAR    
        EXTRN   EnqueueEvent:NEAR           
        EXTRN   EventAvailable:NEAR        
        EXTRN   SerialPutChar:NEAR             
		EXTRN   no_op:NEAR     
     

		
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
        CALL    SerialInit                 ; Initialize serial function variables
        CALL    EnqueueEventInit           ; Initialize the Event queue function vars
        
        CALL    MotorInit                   ;
        CALL    ParseReset                  ;                                   
        
        STI                                ; Start interrupts
        ;JMP     Robot_FSM_LOOP            ;

    
Robot_FSM_LOOP:
    
        CALL    EventAvailable              ; Is there a pending event? 
        JZ      RobotFSMIdle               ; Event queue is empty, thus stay idle
        ;JNZ    RobotFSMIdle              ; There was an event!
RobotFSMEvent:

        CALL    DequeueEvent                ; Grab that event into AX
        CALL    ParseRobotWord             ; Pass to get event parsed
        
RobotFSMIdle:
    
JMP     Robot_FSM_LOOP                     ; Loop forever

; Name:             ParseRobotWord
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
ParseRobotWord     PROC    NEAR

; Arg: AX = [AH = key, AL = value]

    MOV     BL, AL                      ; Save event value
    XOR     BH, BH                      ; Isolate the Event val     
    
    XCHG    AH, AL                      ; Swap such that Event Type is LSNibble
    XOR     AH, AH                      ; Isolate the Event Type      

    SHL     AX, WORD_LOOKUP_ADJUST      ; Prepare for WORD table lookup
    XCHG    BX, AX                      ; Copy to BX for pointer, and AX now has Event val
    CALL    CS:Robot_Call_Table[BX]     ; Go to that FSM  function, passing Event val in AX
    
    RET
    
ParseRobotWord ENDP

Robot_Call_Table	    LABEL	WORD
                                    
	DW		no_op 	            ;KEY_EVENT_KEY - An internal key press
	DW		HandleSerErr        ;SER_ERR_KEY   - An internal serial CHIP issue
	DW      ParseSerialChar     ;RX_ENQUEUED_KEY - External serial char stream
	DW      HandleModem         ;MODEM_KEY - Internal serial chip modem issue

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
                            
    %DisplayCSStrPrep(AX)                ;
    CALL    StatusFeedback               ;
    
    RET
    
HandleSerErr    ENDP

SerErrTable     LABEL       BYTE

    DB     '        ', CAR_RETURN   ;
    DB     'R  0-RUN', CAR_RETURN   ; Overrun serial error
    DB     '        ', CAR_RETURN   ;
    DB     'R PARITY', CAR_RETURN   ; Parity serial error
    DB     '        ', CAR_RETURN   ;
    DB     'R FRAME ', CAR_RETURN   ; Frame serial error
    DB     '        ', CAR_RETURN   ;
    DB     '        ', CAR_RETURN   ;
    DB     '        ', CAR_RETURN   ;
    DB     'R BREAK ', CAR_RETURN   ; Break int
    
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
    
;Procedure:			StatusFeedback
;
;Description:      	Stub function for now.
;                
;Arguments:        	ES:SI
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
;History:			12-12-2013: initial version
;------------------------------------------------------------------------------
StatusFeedback      PROC    NEAR
                    PUBLIC  StatusFeedback

    XOR     CX, CX          ;
    
StatusFeedbackLoop: ; Counter goes from 0 to DisplaySize - 1 or ends early if ASCII_NULL found

    CMP     CX, Display_SIZE    ; Is the counter maxed out?
    JG      StatusFeedbackDone      ; Yes, exit loop
                                ; No, continue loop
	XOR		AX, AX			    ; Clear AX
	
    MOV     AL, ES:[SI]         ; Grab char at address arg, put in AL
    CMP     AL, ASCII_NULL      ; Is it ASCII_NULL? Cuz if so, end loop
    JE      StatusFeedbackDone  ; Yes, end loop
StatusFeedbackPutChar:
    CALL    SerialPutChar        ;
    
    INC     CX                          ; Update Counter
    INC     SI                          ; Update char pointer (Str source)
    
    JMP     StatusFeedbackLoop  ; 
    
StatusFeedbackDone:
    RET
    
StatusFeedback    ENDP
    
    
    
CODE    ENDS
    
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

; Empty for now


DATA    ENDS

;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START