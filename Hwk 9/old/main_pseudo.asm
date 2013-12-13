NAME        Remote


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
;   Remote_FSM_LOOP     -   If available, dequeue next WORD in rx_queue
;   ParseRemoteWord     -   Parses four types of Event Handlers
;
;   EventHandlers:
;
;   HandleKey           -   Updates display and tx_queue with command
;   HandleSerErr        -   Displays serial chip error
;   HandleSerialVal     -   Concatenates the status message as string. Then
;                           will display to user.
;   HandleModem         -   Stub function for now, since no flow control
;
;                              What's was last edit?
;
;       			Pseudo code ->  12-06-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        
        EXTRN   InitUserInterfaceCS:NEAR  
        EXTRN   Timer0Init:NEAR  
        EXTRN   Timer1Init:NEAR  
        EXTRN   ClrIRQVectors:NEAR  
        EXTRN   KeypadInit:NEAR  
        EXTRN   ParseReset:NEAR  
        EXTRN   QueueEventInit:NEAR  
                
        EXTRN   ParseSerialChar:NEAR        
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
		
VOID SETUP()
{

    SetUp(Datasegment, Stack)       ;
    InitUserInterfaceCS()           ;
    Timer0Init()                    ;
    Timer1Init()                    ;
    ClrIRQVectors()                 ;
    KeypadInit()                    ;
    SerialInit()                    ; Leave Actual TX_queue (byte) in Serial functions files
    DisplayInit()                   ;
    ParseReset()                    ;
    EnqueueEventInit()              ; Leave actual WORD EnqueueEvent Queue in separate file
                                    ; which contains EnqueueEvent.
    RemoteFSMInit()                 ;

    REMOTELOOP()                    ;
}
    
VOID REMOTE_FSM_LOOP()
{
    If(EventAvailable() == TRUE)
    {
        word = DequeueEvent()  ;

        ParseRemoteWord(HIGH_BYTE(word), LOW_BYTE(word))   ;
    }
    
    LOOPFOREVER
}

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
ParseRemoteWord(BYTE eventtype, BYTE eventvalue)
{


    Function_addr = Remote_Call_Table(eventtype) ;
    
    CALL(Function_addr(eventvalue)) ;
    
    
}


Remote_Call_Table	    LABEL	WORD
                                    
	DW		HandleKey 	        ;KEY_EVENT_KEY - An internal key press
	DW		HandleSerErr        ;SER_ERR_KEY   - An internal serial CHIP issue
	DW      HandleSerialVal     ;RX_ENQUEUED_KEY - External serial char stream
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
HandleKey(Hexcode)
{
    
    fixed length string command = KeyMagnitudeTable(Hexcode * FIXEDLENGTH) ;
        
    For(int i = 0, i < command.length(), i++)
    {
        SerialPutChar(command[i]);
        
        IF(carryflag)
        {
            return;
        }
        
    }
    
    Display(KeyDisplayTable(Hexcode * FIXEDLENGTH);
    
    
}

KeyCmdTable	    LABEL	BYTE
                                    
	DB		'T',        '+',        DELTA_T_ANG     ;0
	DB		'T',        UNSIGNED,   TURR_INIT       ;1
	DB      'T',        '-',        DELTA_T_ANG     ;2
	DB      UNSIGNED,   UNSIGNED,   UNASSIGNED      ;3
	DB      UNSIGNED,   UNSIGNED,   UNASSIGNED      ;4
	DB      'O',        UNSIGNED,   UNASSIGNED      ;5
	DB      'S',        UNSIGNED,   STOP            ;6
	DB      'F',        UNSIGNED,   UNASSIGNED      ;7
	DB      UNSIGNED,   UNSIGNED,   UNASSIGNED      ;8
	DB      'D',        '+',        DELTA_DIR_SMALL ;9
	DB      'V',        '+',        DELTA_SPEED     ;10
	DB      'D',        '-',        DELTA_DIR_SMALL ;11
	DB      UNSIGNED,   UNSIGNED,   UNASSIGNED      ;12
	DB      'D',        '-',        DELTA_DIR_BIG   ;13
	DB      'V',        '-',        DELTA_SPEED     ;14 
	DB      'D',        '+',        DELTA_DIR_BIG   ;15
	

KeyDisplayTable	    LABEL	BYTE
                                    
	DB		'T ANG+  ', ASCII_NULL      ;0
	DB		'T RESET ', ASCII_NULL      ;1
	DB		'T ANG-  ', ASCII_NULL      ;2
	DB		'NOTKEY  ', ASCII_NULL      ;3	
	DB		'NOTKEY  ', ASCII_NULL      ;4	
	DB		'LAZR OFF', ASCII_NULL      ;5
	DB		'S T O P ', ASCII_NULL      ;6
	DB		'LAZR ON ', ASCII_NULL      ;7
	DB		'NOTKEY  ', ASCII_NULL      ;8	
	DB		'DIR +45 ', ASCII_NULL      ;9
	DB		'SPEED+  ', ASCII_NULL      ;10
	DB		'DIR -45 ', ASCII_NULL      ;11
	DB		'NOTKEY  ', ASCII_NULL      ;12	
	DB		'DIR +90 ', ASCII_NULL      ;13
	DB		'SPEED-  ', ASCII_NULL      ;14
	DB		'DIR -90 ', ASCII_NULL      ;15


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
HandleSerErr(Errorkey)
{
    Display(KeyDisplayTable(Hexcode * FIXEDLENGTH);

}

SerErrTable     LABEL       BYTE

    DB     '        '   ;
    DB     'OVERRUN '   ; Overrun serial error
    DB     '        '   ;
    DB     'PARITY  '   ; Parity serial error
    DB     '        '   ;
    DB     'FRAME   '   ; Frame serial error
    DB     '        '   ;
    DB     '        '   ;
    DB     '        '   ;
    DB     'BREAK   '   ; Break int

;Procedure:			HandleSerVal
;
;Description:      	Concats the next incoming serial char from the Motorboard
;                   into a status string. 
;                   
;                   Just like how the Motor's board expects
;                   a carriage return for termination, the incoming serial channel
;                   is solely to transport strings. Thus it requires an ASCII_NULL
;                   termination. 
;                   
;                   The completed string is them sent to be displayed 
;                   to user. How frequently status messages come is solely dependent on
;                   how often the motor's side sends the message.
;
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
;Error Handling:   	If the string seems to be greater than spec (MAX_LENGTH)
;                   then the string is truncated, and an ASCII_NULL is inserted.
;                   
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-06-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------
HandleSerVal(Char)
{
    Status[index] = Char
    
    index ++;
    
    If(Char == ASCII_NULL)
    {
        Display(Status);
        index = 0;
    }
    If(index => MAX_LENGTH)
    {
        Status[MAX_LENGTH] = ASCII_NULL;
        Display(Status);
        
        index = 0;
    }
        
}

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
HandleModem(Key)
{
    return; For now, not doing flow control

}
