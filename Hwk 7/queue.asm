NAME        queue

$INCLUDE(queue.inc);
$INCLUDE(general.inc);

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
;
;   QueueInit   -    Initializes the queue. Needs address - SI, Size - BL
;                    and length - AX.
;   QueueEmpty  -    Checks whether queue is empty. Needs address - SI
;   QueueFull   -    Checks whether queue is full. Needs address - SI
;   Enqueue     -    Adds a new element to queue. Needs address - SI and
;                    value to be added - AX.
;   Dequeue     -    Removed a value from queue at address SI and into AX
;
;                                 What's was last edit?
;
;       			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			QueueInit
;
;Description:      	This procedure will intialize the queue of passed length AX,
;                   size BL, and pointed address SI. It does this by simply
;                   setting the queue head and tail pinters to the same (zero).
;                   It will also store the length of the queue and size
;                   on the data memory. Notice also that the values of head, tail,
;                   and length are NORMALIZED to the size.
;
;                   Thus the struc will be initialized to contain.
;                   1. Headpointer - normalized pointer to first ele to be dequeued
;                   2. Tailpointer - normalized pointer to first empty ele
;                   3. Queuelength - normalized queue size (in terms of # of elements)
;                   4. Queuesize   - normalization factor (1 - byte, 2 - word)s
;                   The code also has error handling for out of bound lengths.
;                   The total size of the struc allocated is 1024 bytes ONLY.
;
;
;Operation:			*   Determine if queue length can fit
;                   *   Reset Head and tail pointer, and store leng val in struc
;                   *   Set queue size accordingly (either 1 or 2), this is determined
;                       by BL being 0 or > 0.
;                   *   DONE
;
;Arguments:        	AX   -> length of queue
;                   BL   -> size of each unit (byte or word)
;                   SI   -> address of where queue is
;
;Return Values:    	None.
;
;Result:            An initialized queue strucata SI with pointers, length, size, and array.
;
;Shared Variables: 	The queue structure created is shared with HW3Test
;
;Local Variables:	    [SI].leng -> Word holding leng
;                       [SI].head -> Word holding head pointer
;                       [SI].tail -> Word holding tail pointer
;                       [SI].qsize-> Word holding size
;
;
;Global Variables:	None.
;
;
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	BL - Used for compare
;                   AX - Used to compare max length
;
;Stack Depth:		Two words.
;
;Known Bugs:		None for now.
;
;Data Structures:	Queue struc (1024 bytes + 8 words)
;
;Error Handling:   	If passed queue length 'l' is too large, then do not initialize
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
;History:			10-27-2013: Pseudo code - Anjian Wu
;                   11/01/2013: Debugged,Documented, and working - Anjian Wu
;                   11/02/2013: Fixed bug where queue could go beyond allocated
;                               - length Anjian Wu

;-------------------------------------------------------------------------------
CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
		

QueueInit		PROC    NEAR
				PUBLIC  QueueInit

    PUSH    AX          ; Save used regs
    PUSH    BX

QICheck:; Reg changed: None
    CMP     AX, MAX_Q_LENG - 1                ; Is this queue too long?
    JLE     QIStart
    JG      QILengthtoobig  ;
    ;JLE    QIStart

QIStart:; Reg changed: None

    MOV     [SI].leng,  AX                  ; Stored the length value.
    MOV     [SI].head,  ArrayEmpty          ; Clear Head Pointer @ address SI in struc
    MOV     [SI].tail,  ArrayEmpty          ; Clear Tail Pointer @ address SI in struc

QIwordorbyte:; Reg changed: BL, BX
    CMP     BL, BYTE_QUEUE                  ; Is this a byte queue?
    JE      QIbytesize                      ; Yes
    ;JNE     QIwordsize                     ; NO, it is word queue

QIwordsize:; Reg changed: None
    MOV     [SI].qsize, WordQ               ; Queuesize is WORD
    JMP     QIDone                          ;

QIbytesize:; Reg changed: None
    MOV     [SI].qsize, ByteQ               ; Queuesize is WORD; Queuesize is BYTE
    JMP     QIDone                          ;

QILengthtoobig:                             ; Queue too big

    ;JMP    QIDone
QIDone:

    POP     BX                              ;Restore used regs
    POP     AX

    RET

 QueueInit      ENDP



;Procedure:			QueueEmpty
;
;Description:      	This procedure will check the queue at address SI and
;                   see if it is empty. It does this by checking whether
;                   The headpointer is equal to the tail pointer.
;
;                   If it is empty zeroflag -> true
;                   If it is not empty zeroflag -> reset
;
;Operation:
;                   1. Grab head and tail pointer values from struc @ addr SI
;                   2. Compare head and tail
;                   3. Set flag true if head = tail, else false
;
;Arguments:         SI -> location in memory (DS:SI)
;
;Return Values:    	zeroflag -> whether or not queue is empty
;
;Result:            Information regarding whether queue is empty or not in ZF
;
;Shared Variables: 	The queue structure created is shared with HW3Test
;
;Local Variables:	[SI].head  -> Headpointer value
;					[SI].tail  -> Tailpointer value
;
;Global Variables:	None.
;
;
;Input:            	None.
;Output:           	None.
;
;Registers Used:	AX - for head
;                   BX - for tail
;
;Stack Depth:		2 Words
;
;Known Bugs:		None.
;
;Data Structures:	Queue struc (1024 bytes + 8 words)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;-------------------------------------------------------------------------------

QueueEmpty		PROC    NEAR
				PUBLIC  QueueEmpty

    PUSH    AX
    PUSH    BX

QEstart:; Reg changed: AX, BX

    MOV     AX, [SI].head   ; Grab current pointers from struc
    MOV     BX, [SI].tail   ; Grab current pointers from struc

QEflagtime:; Reg changed: None
    CMP     AX, BX          ; If head = tail -> head - tail = 0 -> zeroflag = 1
                            ; Else zeroflag = 0

QEdone:
    POP    BX
    POP    AX

    RET

 QueueEmpty      ENDP

;Procedure:			QueueFull
;
;Description:       This function take the address of the queue at SI to
;                   see if it is FULL. It does this by looking at the
;                   head/tailed pointers and queue length of address SI queue
;                   doing the following calculation.
;
;                   COMAPRE (Tail + 1 MOD length + 1) with HEAD pointer
;
;                   If this is true, then queue is full, else it is not full.
;                   Note as said before, tail pointer is at next EMPTY spot.
;
;                   If it is full zeroflag -> true
;                   If it is not full; zeroflag -> reset
;
;Operation:
;                   1. Grab length and tail pointer values from struc @ addr SI
;
;                   2. DO (Tail + 1 MOD length + 1), then grab head from struc
;                   3. Compare the remainder value to head
;                   4. ZF is automatically set after compare(true -> full)
;
;Arguments:         SI -> location in memory (DS:SI)
;
;Return Values:    	zeroflag -> whether or not queue is full
;
;Result:            Information regarding whether queue is full or not in ZF

;
;Shared Variables: 	The queue structure created is shared with HW3Test
;
;Local Variables:	[SI].head  -> Headpointer value
;					[SI].tail  -> Tailpointer value
;					[SI].leng  -> queue length value
;
;Global Variables:	None.
;
;
;Input:            	None.
;Output:           	None.
;
;Registers Used:	AX, BX, DX
;
;Stack Depth:		3 Words
;
;Known Bugs:		None
;
;Data Structures:	Queue struc (1024 bytes + 8 words)
;
;Error Handling:   	None.
;
;Algorithms:       	Next position is determined by using (Tail + 1 MOD length + 1)
;                   and comparing that to the Head pointer.
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;-------------------------------------------------------------------------------

QueueFull		PROC    NEAR
				PUBLIC  QueueFull

    PUSH    AX              ;Save used regs
    PUSH    BX
    PUSH    DX

QFstart:; Reg changed: None

    MOV     AX, [SI].tail   ; Grab current pointers from struc
    MOV     BX, [SI].leng   ; Grab leng  from struc
;

QFmath:; Reg changed: AX, DX, BX

    INC     BX
    INC     AX                  ; Check potential next tail pos

    MOV     DX, 0               ;
    DIV     BX                  ;

    MOV     BX, [SI].head       ; The mod is the next position

QFflagtime:; Reg changed: None
    CMP     DX, BX          ; If (Tail + 1) mod length = Head -> zeroflag = 1
                            ; Else zeroflag = 0

QFdone:                     ; Flags are ready to be returned

    POP    DX
    POP    BX
    POP    AX                   ; restore used regs

    RET
 QueueFull      ENDP


;Procedure:			Dequeue
;
;Description:       This function take the address of the queue at SI
;                   and returns the value of the data (byte or word) stored at
;                   head pointer. This is a blocking function in that if the
;                   queue is empty, the function will wait until the queue is
;                   no longer empty. After the value is taken off the queue,
;                   the head pointer is updated to (Head + 1) mod Leng;
;
;Operation:
;                   1. Grab the queue empty flag
;                   2. If is it empty then loop polling the Queueempty
;                      until the queue is not empty and ready.
;                   3. Grab the values of head, size, and leng of queue
;                      off the queue struc at address SI
;                   4. If the size is word, retreive the WORD from location
;                      HEAD*2 since Head is normalized to WORD, and there
;                      two bytes in a word.
;                      Otherwise grab the byte at Head.
;                   5. Update head pointer with (Head + 1) mod Leng;

;
;Arguments:         SI -> location in memory (DS:SI)
;
;Return Values:    	AX -> The value from queue from head pointer
;
;Results:           Updates queue pointers after extracting an element.
;
;Shared Variables: 	The queue structure created is shared with HW3Test
;
;Local Variables:	[SI].head  -> Headpointer value
;					[SI].tail  -> Tailpointer value
;					[SI].leng  -> queue length value
;					[SI].qsize -> queue size (type) either byte or word
;                   AX         -> Result from division
;                   BX         -> pointer, div operand, queue size
;                   DX         -> Remaineder for modulo
;                   qvar.dequeued -> Temporarily holds return arg
;
;Global Variables:	None.
;
;
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX, BX, DX
;
;Stack Depth:		3 Words
;
;Known Bugs:		Never
;
;Data Structures:	Queue struc (1024 bytes + 8 words)
;                   Queue vars struc (1 word)
;
;Error Handling:   	None.
;
;Algorithms:       	Next position is determined by using (Tail + 1 MOD length + 1)
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;-------------------------------------------------------------------------------

Dequeue		    PROC    NEAR
				PUBLIC  Dequeue

    PUSH    BX
    PUSH    DX

DQBlock:; Reg changed: None

    CALL    QueueEmpty          ; Blocking function, keep checking whether queue
                                ; is empty

    JZ      DQBlock             ; If still empty, keep looping
    ;JMP    DQStart             ;

DQStart:; Reg changed: BX

    MOV     BX, [SI].qsize      ; Grab the queue size (Byte or Word)
    CMP     BX, WORDQ           ; Is the Queue WORD queue?
    JE     DQWORDGRAB          ; Yes it is word queue
    ;JNE     DQBYTEGRAB          ; No it is byte queue

DQBYTEGRAB:; Reg changed: AX, BX, AL
    MOV     AX, 0               ; Clear AH and AL
    MOV     BX, [SI].head       ; Grab the head element index
    MOV     AL, [SI].array[BX]  ; Now us the index as offset @ array @ SI
    JMP     DQsaveret           ;

DQWORDGRAB:; Reg changed: AX, BX
    MOV     BX, [SI].head       ; Grab the head element index
    SHL     BX, 1                  ; Actual Position maps to every other address
    MOV     AX, WORD PTR [SI].array[BX]  ; Now use the index as offset @ array @ SI

DQsaveret:; Reg changed: BX

    LEA     BX, qvars           ; Grab queue vars struc offset
    MOV     [BX].dequeued , AX   ; Stored the return value

DQNextPos:; Reg changed: BX, AX, DX
    MOV     BX, [SI].leng       ; Grab the fixed Queue length
    INC     BX

    MOV     AX, [SI].head       ; Grab the head element index
    INC     AX                  ; Check potential next tail pos

    MOV     DX, 0               ;
    DIV     BX                  ;

    MOV     [SI].head, DX       ; The mod is the next position

DQArgGet:; Reg changed: BX, AX

    LEA     BX, qvars           ;
    MOV     AX, [BX].dequeued   ; Restore the return value

DQdone:

    POP    DX
    POP    BX

    RET

 Dequeue      ENDP


;Procedure:			Enqueue
;
;Description:       This function take the address of the queue at SI
;                   and sets the value of the data (byte or word) to
;                   tail pointer. This is a blocking function in that if the
;                   queue is full, the function will wait until the queue is
;                   no longer full. After the value is written to the queue,
;                   the tail pointer is updated to (Tail + 1) mod Leng;
;
;Operation:
;                   1. Grab the queue full flag
;                   2. If is it full then loop polling the Queuefull
;                      until the queue is not full and ready.
;                   3. Grab the values of qsize and jump to word or byte
;                      labels such that proper insertion is made.
;
;                   4. If the size is word, write the WORD to location
;                      Tail*2 since Tail is normalized to WORD, and there
;                      two bytes in a word.
;                      If the queue is byte queue, the simply write directly
;                      to location at tail pointer
;
;                   5. Update tail pointer with (Tail + 1) mod Leng;

;
;Arguments:         SI -> location in memory (DS:SI)
;                   AX/AL -> The value to be added to queue
;
;Return Values:    	None.
;
;Result:            Updates queue after inserting an element.
;
;Shared Variables: 	The queue structure created is shared with HW3Test
;
;Local Variables:	[SI].head  -> Headpointer value
;					[SI].tail  -> Tailpointer value
;					[SI].leng  -> queue length value
;					[SI].qsize -> queue size (type) either byte or word
;                   AX         -> Result from division
;                   BX         -> pointer, div operand, queue size
;                   DX         -> Remaineder for modulo
;
;Global Variables:	None.
;
;
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX, BX, DX
;
;Stack Depth:		3 Words
;
;Known Bugs:		None
;
;Data Structures:	Queue struc (1024 bytes + 8 words)
;
;Error Handling:   	None.
;
;Algorithms:       	Next position is determined by using (Head + 1 MOD length + 1)
;
;Limitations:  		If AX is intended as WORD and size is BYTE,
;                   only the lower AL will be written.
;
;                   If AL is intended as BYTE and size is WORD,
;                   the full AX will be written.
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;-------------------------------------------------------------------------------
Enqueue		    PROC    NEAR
				PUBLIC  Enqueue

    PUSH    AX              ;Save used regs
    PUSH    BX
    PUSH    DX

EQBlock:; Reg changed: None

    CALL    Queuefull           ; Blocking function, keep checking whether queue
                                ; is empty

    JZ      EQBlock             ; If still full, keep looping
    ;JMP    EQStart             ;
EQStart:; Reg changed: BX

    MOV     BX, [SI].qsize      ; Grab the queue size (Byte or Word)
    CMP     BX, WORDQ           ; Is the Queue WORD queue?
    JE     EQWORDPUT            ; Yes it is word queue
    ;JNE     EQBYTEPUT          ; No it is byte queue

EQBYTEPUT:; Reg changed: BX, AL

    MOV     BX, [SI].tail       ; Grab the tail element index
;;;
    MOV     [SI].array[BX], AL  ; Now us the index as offset @ array @ SI
;;;
    JMP     EQNextPos           ;

EQWORDPUT:; Reg changed: CX, AX, BX

    MOV     BX, [SI].tail       ; Grab the tail element index
    SHL     BX, 1               ; Actual Position maps to every other address (MUL 2x)
;;;
    MOV     WORD PTR [SI].array[BX], AX  ; Now use the index as offset @ array @ SI
;;;

EQNextPos:; Reg changed: None
    MOV     BX, [SI].leng       ; Grab the  Queue length
    INC     BX                  ; Length + 1

    MOV     AX, [SI].tail       ; Grab the tail element index
    INC     AX                  ; Update to potential next tail pos

    MOV     DX, 0               ; Clear the remainder
    DIV     BX                  ; Do the modulus, answer in remainder

    MOV     [SI].tail, DX       ; The mod is the next position

EQdone:; Reg changed: None

    POP    DX
    POP    BX
    POP    AX                   ; restore used regs

    RET

Enqueue      ENDP

CODE    ENDS

 ;-------------------------------------------------------------------------------


DATA    SEGMENT PUBLIC  'DATA'


qvars       QUEUEVARS <>      ;"Minute Set" switch information


DATA    ENDS

        END