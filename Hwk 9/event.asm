NAME        Remote


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
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

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
		
DequeueEvent()
{
    
    Return Dequeue(EventQueue, char);
}

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
EnqueueEvent(char)
{


    Enqueue(EventQueue, char);
    
    Return
    
    
}

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
EventAvailable()
{
    
    RETURN  QueueEmpty(EventQueue);
    
    
}

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
EventFull()
{
    Return QueueFull(EventQueue);

}


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
EnqueueEventInit()
{
    QueueInit(EventQueue, WORD, MAX_Q_LENGTH);
}


DATA    SEGMENT PUBLIC  'DATA'

EventQueue          QUEUESTRUC <>           ; Holds the EventQueue


DATA    ENDS