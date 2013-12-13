NAME        Robot


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW9 Motor Mainloop Functions               ;
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
;   ROBOT_FSM_LOOP     -   If available, dequeue next WORD in rx_queue
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

		
; Name:             Robot Main Loop
; Description:      This is the robot main loop. It has two purposes.
;                   1. Continually parse incoming command strings which are
;                      CR terminated.
;
;                   2. Set up TWO timer interrupts 
;                       a) one for PWM for motors
;                       b) one for periodically sending back status strings to
;                          the remote (thus it is longer period interrupt)
;
;                   Of course the hardware INT2 is also set up for serial.
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
    Timer0Init()                    ; - For Motor PWM control and output
    Timer1Init()                    ; - For periodically sending status messages (will be written
                                    ;   later after I determine Robot fully works first)
    ClrIRQVectors()                 ;
    MotorInit()                     ;
    SerialInit()                    ; Leave Actual TX_queue (byte) in Serial functions files
    DisplayInit()                   ;
    ParseReset()                    ;
    QueueInit()                     ;tx and rx queues are in MAINLOOP level
    
    RemoteFSMInit()                 ;

    ROBOT_FSM_LOOP()                ;
}
    
VOID ROBOT_FSM_LOOP()
{
    If(QueueEmpty(rx_queue) == FALSE)
    {
        char = dequeue(rx_queue)  ;

        ParseSerialChar(char)   ; Pass char to serial char FSM which handles all commands.
    }
    
    LOOPFOREVER
}

