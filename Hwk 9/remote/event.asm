NAME        event

$INCLUDE(queue.inc);
$INCLUDE(vectors.inc);
$INCLUDE(timer.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Event Queue Functions                      ;
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
;   DequeueEvent     -   No args, and returns next dequeued val
;   EnqueueEvent     -   Takes a WORD and enqueues it.
;   EventAvailable   -   Checks if queue is empty
;   EventFull        -  Checks if queue is full.
;   EnqueueEventInit -  initializes the word queue
;                              What's was last edit?
;
;       			Pseudo code ->  12-06-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP
        
        
                
        EXTRN   QueueInit:NEAR        
        EXTRN   QueueFull:NEAR        
        EXTRN   QueueEmpty:NEAR    
        EXTRN   Enqueue:NEAR           
        EXTRN   Dequeue:NEAR          
		
; Name:             DequeueEvent
; Description:      Returns with the dequeued WORD from EventQueue
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
		
DequeueEvent    PROC    NEAR
                PUBLIC  DequeueEvent


    LEA     SI, EventQueue              ;
    CALL    Dequeue                     ;
    RET
    
DequeueEvent    ENDP
; Name:             EnqueueEvent
; Description:      Enqueues the passed char into EventQueue
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
EnqueueEvent    PROC    NEAR
                PUBLIC  EnqueueEvent

    LEA     SI, EventQueue              ;
    CALL    Enqueue                     ;
    RET
    
EnqueueEvent    ENDP
;Procedure:			EventAvailable
;
;Description:      	Checks if EventQueue is empty
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
EventAvailable      PROC    NEAR
                    PUBLIC  EventAvailable

    LEA     SI, EventQueue              ;
    CALL    QueueEmpty                  ;
    RET
    
EventAvailable  ENDP

;Procedure:			EventFull
;
;Description:      	Checks if EventQueue is Full
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
EventFull   PROC    NEAR
            PUBLIC  EventFull
                    
    LEA     SI, EventQueue              ;
    CALL    QueueFull                   ;
    RET
    
EventFull   ENDP


;Procedure:			EnqueueEventInit
;
;Description:      	Initializes the queue at EventQueue
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
;Error Handling:    None.
;                   
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-06-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------

EnqueueEventInit    PROC NEAR
                    PUBLIC  EnqueueEventInit

    LEA     SI, EventQueue              ;
    MOV     BL, WORD_QUEUE              ;
    MOV     AX, MAX_Q_LENG - 1          ;
    CALL    QueueInit                   ;

    RET
EnqueueEventInit    ENDP

CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

EventQueue          QUEUESTRUC <>           ; Holds the EventQueue


DATA    ENDS


        END 