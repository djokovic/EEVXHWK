NAME        HW3

$INCLUDE(queue.inc);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW3 Queue Functions                        ;
;                                 Code Outline                            	 ;
;                                 Anjian Wu                                  ;
;                                                                            ;
;                                 TA: Pipe-Mazo                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;   QueueInit
;   QueueEmpty
;   QueueFull
;   Enqueue
;   Dequeue
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			QueueInit
;
;Description:      	This procedure will intialize the queue of passed length 'l',
;                   size ''s', and pointed address 'a'. It does this by simply
;                   setting the queue head and tail pinters to the same (zero).
;                   It will also store the length 'l' of the queue and size 's'
;                   on the data memory. Notice also that the values of head, tail,
;                   and length are NORMALIZED to the size.
;                   Thus the struc will be initialized to contain.
;                   1. Headpointer - normalized pointer to first ele to be dequeued
;                   2. Tailpointer - normalized pointer to first empty ele
;                   3. Queuelength - normalized queue size (in terms of # of elements)
;                   4. Queuesize   - normalization factor (1 - byte, 2 - word)s
;                   The code also has error handling for out of bound lengths.
;                   The total size of the struc allocated is 1024 bytes ONLY.
;                   
;                   
;Operation:			
;                   1.  Reset Head and tail pointer val in struc
;                   2.  Set queue size accordingly (either 1 or 2)
;                   3.  Grab the LOWEST 2's power queue size that can fit
;                       the queue length requirement. We do this with a while
;                       that increments n from 0 to 10 and testing compared
;                       to the queue length.
;                   2.  Save that 2^n/size value to Queueleng in queue struc
;
;Arguments:        	l   -> length of queue
;                   s   -> size of each unit (byte or word)
;                   a   -> address of where queue is
;
;Return Values:    	Error flag -> indicated size of length is too large or not;
;
;Shared Variables: 	None.
;
;Local Variables:	size -> byte normalized value of queuesize (either 1 or 2)
;                   error -> error flag for if 'l' is too large.
;                   n -> integer counter for while loop
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	An initialized queue struc with pointers, length, and size;
;
;Registers Used:	To be arranged
;
;Stack Depth:		To be arranged
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes)
;
;Error Handling:   	If passed queue length 'l' is too large, then return error flag;
;                   
;
;Algorithms:       	None.
;
;Limitations:  		Only stores a queue of up to 2^9 bytes or 2^8 words.
;                   Queue length that is initialized is always power of 2.
;                   Also a queue cannot be any size less than 2 (aka. 1 byte ele)
;
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;-------------------------------------------------------------------------------
;QUEUESTRUC      STRUC           	;structure containing all queue info
;    head	    DW      ?       	;counter for debouncing the switch
;    tail	    DW      ?       	;time until change repeat rates
;    size	    DB      ?       	;rate at which to repeat the switch
;    length		DW      ?  		    ;flag indicating have a debounced switch
;    array		1024	DUP	?       ;pointer to the function to get switch status
;SWSTRUC         ENDS
;-------------------------------------------------------------------------------
CGROUP  GROUP   CODE

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP

;-------------------------------------------------------------------------------

QueueInit		PROC    NEAR
				PUBLIC  QueueInit
                
QICheck:
    CMP     AX, MAX_LENG    ;
    JL      QILengthtoobig  ;
    ;JLE    QIStart
    
QIStart:
    MOV     [SI].head,  0           ; Clear Head Pointer @ address a in struc
    MOV     [SI].tail,  0           ; Clear Tail Pointer @ address a in struc
    MOV     [SI].length, MAX_LENG   ;
QIwordorbyte:    
    CMP     BL, 0                   ; 
    JLE     QIbytesize              ;
    ;JG     QIwordsize              ;

QIwordsize:    

    MOV     [SI].size, 2            ; Queuesize is WORD
    JMP     QIleng                  ;
    
QIbytesize:
    MOV     [SI].size, 1            ; Queuesize is WORD; Queuesize is BYTE
    JMP     QIDone                  ;
    
QILengthtoobig:                     ; Queue too big

    ;JMP    QIDone
QIDone:

    RET
    
 QueueInit      ENDP      



;Procedure:			QueueEmpty
;
;Description:      	This procedure will check the queue at address 'a' and 
;                   see if it is empty. It does this by checking whether
;                   The headpointer is equal to the tail pointer.
;                   If it is empty zeroflag -> true
;                   If it is not empty zeroflag -> reset
;
;Operation:			
;                   1. Grab head and tail pointer values from struc @ addr 'a'
;                   2. Compare head and tail
;                   3. Set flag true if head = tail, else false
;
;Arguments:         a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	zeroflag -> whether or not queue is empty
;
;Shared Variables: 	None.
;
;Local Variables:	Head -> Headpointer value
;					Tail -> Tailpointer value
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	None.
;
;Registers Used:	To be determined.
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;-------------------------------------------------------------------------------

QueueEmpty		PROC    NEAR
				PUBLIC  QueueEmpty
       
    PUSH    AX
    PUSH    BX
QEstart:
                
    MOV     AX, [SI].head   ; Grab current pointers from struc
    MOV     BX, [SI].tail   ; Grab current pointers from struc
    
QEflagtime:   
    CMP     AX, BX          ; If head = tail -> head - tail = 0 -> zeroflag = 1
                            ; Else zeroflag = 0
                        
QEdone:
    POP    BX
    POP    AX
    
    RET

 QueueEmpty      ENDP      

;Procedure:			QueueFull
;
;Description:       This function take the address of the queue at 'a' to
;                   see if it is FULL. It does this by looking at the
;                   head/tailed pointers and queue length of address 'a'
;                   doing the following calculation.
;                   (Tail + 1) % length = X. If X = H then it is FULL,
;                   else it is not full.
;                   Note as said before, tail pointer is at next EMPTY spot.
;
;                   If it is full zeroflag -> true
;                   If it is not full; zeroflag -> reset
;
;Operation:			
;                   1. Grab head and tail pointer values from struc @ addr 'a'
;                      as well as the leng value.
;                   2. Check if (Tail + 1) % length =  H, if so it is full,
;                      else it is not full.
;                   3. Set flag true if it is full, else false.
;
;Arguments:         a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	zeroflag -> whether or not queue is full
;
;Shared Variables: 	None.
;
;Local Variables:	Head -> Headpointer value
;					Tail -> Tailpointer value
;					Leng -> leng of queue value
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	None.
;
;Registers Used:	To be determined.
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;-------------------------------------------------------------------------------

QueueFull		PROC    NEAR
				PUBLIC  QueueFull
       
    PUSH    AX
    PUSH    BX
    PUSH    DX
QFstart:
                
    MOV     AX, [SI].tail   ; Grab current pointers from struc
    MOV     BX, [SI].length ;
 
QFmath:                     ; Calc (Tail + 1) % length
    INC     AX              ; Check potential next tail pos
    
    MOV     DX, 0           ; Clear Remainder holder
    DIV     BX              ; Proceed with modulo, MOD in DX
    
    MOV     BX, [SI].head   ; Reuse BX by replacing it with head
    
QFflagtime:   
    CMP     DX, BX          ; If (Tail + 1) % length = Head -> zeroflag = 1
                            ; Else zeroflag = 0
                        
QFdone:                     ; Flags are ready to be returned
    POP    DX
    POP    BX
    POP    AX
    
    RET
 QueueFull      ENDP      

;QueueFull(a)
;{
        
;    zeroflag = false; Assume to be not full at first
    
;    Head = Headpointer(a); Grab all pointer values off struc
;    Tail = Tailpointer(a);
;    Leng = Queueleng(a);
    
;    If((Tail + 1) % Leng(a) == Head) ; Check to see if next tail IS head
;    {
        
;        zeroflag = true; Queue is full
    
;    }
    

;}
;Return zeroflag

;Procedure:			Dequeue
;
;Description:       This function take the address of the queue at 'a' 
;                   and returns the value of the data (byte or word) stored at
;                   head pointer. This is a blocking function in that if the
;                   queue is empty, the function will wait until the queue is
;                   no longer empty. After the value is taken off the queue,
;                   the head pointer is updated to (Head + 1) % Leng;
;
;Operation:			
;                   1. Grab the queue empty flag
;                   2. If is it empty then loop polling the Queueempty
;                      until the queue is not empty and ready.
;                   3. Grab the values of head, size, and leng of queue
;                      off the queue struc at address 'a'
;                   4. If the size is word, retreive the WORD from location
;                      HEAD*2 since Head is normalized to WORD, and there 
;                      two bytes in a word.
;                      Otherwise grab the byte at Head.
;                   5. Update head pointer with (Head + 1) % Leng;
    
;
;Arguments:         a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	ReturnValue -> The value from queue from head pointer
;
;Shared Variables: 	None.
;
;Local Variables:	Head -> Headpointer value
;					Leng -> leng of queue value
;					Size -> size of element (byte or word)
;                   next_pos -> next normalized position of head pointer
;                   Empty -> the flag indicating queue is empty or not
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	Updates queue after extracting an element.
;
;Registers Used:	To be determined.
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		Only dequeues one element at a time.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;-------------------------------------------------------------------------------

Dequeue		    PROC    NEAR
				PUBLIC  Dequeue
				
DQBlock:

    CALL    QueueEmpty          ;

    JZ      DQBlock             ;

DQStart:

    MOV     BX, [SI].size       ;ss
    MOV     CX, [SI].length     ;
    
    CMP     BX, 2               ;
    JGE     DQWORDGRAB          ;
    ;JL     DQBYTEGRAB          ;
    
DQBYTEGRAB:

    MOV     BX, [SI].head       ;
    
    

DQWORDGRAB:
				
Dequeue(a)
{

    Bool Empty = QueueEmpty(a); Initial check to see if empty

    While (Empty)
    {
    
        nop;
        Empty = QueueEmpty(a); While it is empty, keep polling the queue
        
    }
    
    Head = Headpointer(a); Now we can grab current queue pointer vals
    Size = Queuesize(a);
    Leng = Queueleng(a);
    
    
if (Size > 1); Check to see if this queue at 'a' is BYTE or WORD queue
    {
        ReturnValue = WORDREAD(DS:[Head*Size]); Do a WORD read at actual address
    }
    else
    {
        ReturnValue = BYTEREAD(DS:[HEAD]); Do a byte read at normalize = actual address
    }
    
    next_pos = (Head + 1) % Leng; Update next head position, should be ok since queue 
                                
    
    Headpointer(a) = next_pos;
    

    return ReturnValue;

}


;Procedure:			Enqueue
;
;Description:       This function take the address of the queue at 'a' 
;                   and sets the value of the data (byte or word) to 
;                   tail pointer. This is a blocking function in that if the
;                   queue is full, the function will wait until the queue is
;                   no longer full. After the value is written to the queue,
;                   the tail pointer is updated to (Tail + 1) % Leng;
;
;Operation:			
;                   1. Grab the queue full flag
;                   2. If is it full then loop polling the Queuefull
;                      until the queue is not full and ready.
;                   3. Grab the values of tail, size, and leng of queue
;                      off the queue struc at address 'a'
;                   4. If the size is word, write the WORD to location
;                      Tail*2 since Tail is normalized to WORD, and there 
;                      two bytes in a word.
;                      Otherwise write to the byte at Tail.
;                   5. Update tail pointer with (Tail + 1) % Leng;
    
;
;Arguments:         a (DS:SI) -> location in memory (DS:SI)
;                   b         -> WORD or BYTE
;
;Return Values:    	ReturnValue -> The value from queue from head pointer
;
;Shared Variables: 	None.
;
;Local Variables:	Tail -> Tailpointer value
;					Leng -> leng of queue value
;					Size -> size of element (byte or word)
;                   next_pos -> next normalized position of head pointer
;                   Empty -> the flag indicating queue is empty or not
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	Updates queue after inserting an element.
;
;Registers Used:	To be determined.
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		Only enqueues one element at a time.
;                   If b is intended as WORD and size is BYTE, 
;                   only the lower BYTE will be written.
;
;                   If b is intended as BYTE and size is WORD, 
;                   the full WORD will be written.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;-------------------------------------------------------------------------------

Enqueue(a, b)
{

    Bool Full = QueueFull(a); First check is queue full

    While (Full)
    {
    
        nop;
        Full = QueueFull(a); While it is full, keep blocking until not full
        
    }
    
    Tail = Tailpointer(a); Grab all relevant queue size values
    Size = Queuesize(a);
    Leng = Queueleng(a);
    
    
    if (Size > 1) ; We are adding to a WORD queue
    {
        WORDWRITE(DS:[Tail*Size]) = b; Write to location Tail*size, since tail is 
                                     ; normalized
    }
    else          ; We are adding to a BYTE queue
    {
        BYTEWRITE(DS:[Tail]) = b; Write to location Tail, since tail is 
                                ; the actual location as well as normalized.
    }
    
    next_pos = (Tail + 1) % Leng; Update the tail position
    
    Tailpointer(a) = next_pos; Update the struc with new tail

    return ;

}

DATA    SEGMENT PUBLIC  'DATA'


queue       QUEUESTRUC <>      ;"Minute Set" switch information


DATA    ENDS