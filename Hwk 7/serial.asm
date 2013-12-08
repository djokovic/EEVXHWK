NAME        Serial
$INCLUDE(macros.inc);
$INCLUDE(queue.inc);
$INCLUDE(general.inc);
$INCLUDE(serial.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW7 Serial Functions                       ;
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
;   SerialPutChar   -   Places passed char into serial tx queue
;   SerialHandler   -   Handles all serial chip interrupts (RX, Error, Modem, TX)
;		SerialModem 	- Reads modem register and enqueues the status bits
;		SerialTX_Empty 	- Either dequeues the next TX char or sets kickstart flag
;		SerialRX_Avail 	- Enqueues the next RX available char from Chip
;		SerialNone	    - Stub function (Should not enter, but if so just returns)
;		SerialError 	- Reads in all error bits and enqueues it.
;   SetBaud         -   Sets appropriate baud rate into serial chip's divider latch
;   SetParity       -   Sets appropriate parity into serial chip
;   Serialinit      -   Initializes all serial function variables and chip
;
;                                 What's was last edit?
;
;       			Pseudo code ->  11-25-2013 - Anjian Wu
;                   Working     ->  11-30-2013 - Anjian Wu
;                   Documentation-> 12-01-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   QueueInit:NEAR          ;Initializes a queue 
        EXTRN   QueueEmpty:NEAR         ;Checks if a queue is empty
        EXTRN   QueueFull:NEAR          ;Checks if a queue is full
        EXTRN   Dequeue:NEAR            ;Dequeue next char (note there is blocking)
        EXTRN   Enqueue:NEAR            ;Enqueue next char (note there is blocking)
		EXTRN   EnqueueEvent:NEAR       ;Enqueue char into eventqueue


;Procedure:			SerialPutChar
;
;Description:      	This function will insert/enqueue a passed char arg into the
;                   serial_queue. If the queue is full, then no new char is placed, and
;                   the carry flag is asserted. Else the carry flag is cleared.
;                   Also if the kickstart_flag is TRUE, then this function will
;                   also kick start the TX by turning off and on the THRE interrupt
;                   of the serial chip.
;           
;                   
;Operation:			* Check if serial queue is full, if so, then set carry flag and return
;                   * Else
;                       * Enqueue the passed char
;                       * Check if the kickstart_flag is true
;                           * If so, then read in IER value, mask OFF THRE  bit
;                           * Send out new IER value, then MASK ON THRE bit again
;                           * Finally send out final IER value to complete kickstart
;                           * Reset the kickstart_flag
;                       * Set carryflag FALSE
;
;Arguments:        	AL   -> The new char to be placed
;
;Return Values:    	Carry Flag - > indicates of queue was able to accept the char.
;
;Shared Variables: 	kickstart_flag(READ/WRITE)
;
;Local Variables:	SI - Holds address of tx queue
;                   AL - Holds char, and PORT vals for IN and OUT
;                   DX - Holds address of PORTs
;                   
;Global Variables:	None.
;								
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	SI, AL, DX
;
;Stack Depth:		3 words
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:        None.
;                   
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------


SerialPutChar		PROC NEAR
					PUBLIC SerialPutChar

    PUSH    AX                      ; Store used regs
    PUSH    DX
    PUSH    SI
    
SerialPutInit:
    LEA     SI, tx_queue            ; Grab address of Queue
	CALL	QueueFull				; Is the queue full?

	JZ		SerialPutFailed			; If so, can't enqueue so set Carry
	;JNZ 	SerialPutQueue			; Not full, so continue
	
SerialPutQueue:
	CALL	Enqueue					;   Enqueue the next char

	CMP		kickstart_flag, TRUE	;   Did Handler say need kick start?
	JNE		SerialPutSuccess		;   No, so continue to clearing carry
	;JE		SerialPutKickstart		;   Yes, kickstart

SerialPutKickstart:
   %INPORT8_AL(IER_ADDRESS)         ;   Import IER reg val into AL

    AND     AL, THRE_OFF            ;   Turn OFF THRE
    OUT     DX, AL                  ;   Write to IER reg
    OR      AL, THRE_ON             ;   Turn ON THRE
    OUT     DX, AL                  ;   Write to IER Reg
    MOV     kickstart_flag, FALSE   ;   No more kick start needed
    ;jmp    SerialPutSuccess        ;
    
SerialPutSuccess:
	CLC								; Reset Carry Flag
	JMP		SerialPutDone			;
SerialPutFailed:
	CLC								; Put carry into known state of cleared
	CMC								; Set Carry Flag	
SerialPutDone:
    POP     SI
    POP     DX
    POP     AX                      ; Restore used Regs
	RET
	
SerialPutChar ENDP
;Procedure:			SerialHandler
;
;Description:      	This function is the event handler for serial. It will
;                   take the INT2 hardware interrupt and process which type
;                   of serial chip interrupt is present via the IIR register.
;                   
;                   For errors, the error variable take all the error bits,
;                   for RX rdy or TX empty, the handler will enqueue and dequeue
;                   the RX and TX queues respectively. For Modem int, the modem
;                   status is also stored into the modem_status variable. Each of 
;                   these operations is done through mapping the IIR val into a
;                   call table such that there are unique functions to handle each
;                   valid INT type. 
;                   
;
;Operation:			* LOOP
;                       * Grab IIR address
;                       * Mask OFF all NON-interrupt ID bits
;                       * Check to see if no int's left, if so then EXIT loop
;                       * Else adjust thhe masked IIR val for WORD table lookup and 
;                         CALL Serial_Call_Table to go to proper function to handle.
;                       * Again go back to beginning of LOOP
;                   * Send out INT2 EOI to INT control reg to complete interrupt.
;
;Arguments:         None.
;
;Return Values:    	None.
;
;Shared Variables: 	None.
;
;Local Variables:	AL - Holds IIR reg val, and PORT vals for IN and OUT
;                   DX - Holds address of PORTs
;                   BX - Holds relative pointer for call table
;Global Variables:	None.
;						
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	AX, BX, DX
;
;Stack Depth:		8 Words
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None.
;
;Algorithms:       	Call table loop up
;
;Limitations:  		None.
;
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
			
SerialHandler		PROC NEAR
					PUBLIC SerialHandler
SerialHInit:
    PUSHA                       ;Save all regs
    
SerialIntLoop:
    XOR     AX, AX              ; Clear AX
    %INPORT8_AL(IIR_ADDRESS)    ; Grab the IIR reg into AL  
    AND     AL, IIR_MASK        ; Ensure we only have ID bits pass
    CMP     AL, SERIAL_NO_INT   ; Are we done with Serial Ints?
    JE      SerialHDone         ; Yes, so go to send EOI
    ;JNE    SerialHCall         ; No, continue processing

SerialHCall:

    SHL     AX, WORD_LOOKUP_ADJUST      ; Prepare for WORD table lookup
    XCHG    BX, AX                      ; Copy to BX for pointer
    CALL    CS:Serial_Call_Table[BX]    ; Go to that INT handler function
    JMP     SerialIntLoop               ; Loop
    
SerialHDone:
    MOV     DX, INTCtrlReg          ;send the EOI to INT2 control
    MOV     AX, INT2EOI
    OUT     DX, AL
    
    POPA                        ; Restore all regs
    IRET                        ;

SerialHandler   ENDP

;Name:			    Serial_Call_Table (WORD Table)
;Description:      	This is the call table used by the SerialHander that maps the 
;                   interrupt identification reg of the Serial Chip to their 
;                   respective functions to handle each INT type.                
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
Serial_Call_Table	    LABEL	WORD
                                    
	DW		SerialModem 	;IIR = 0
	DW		SerialNone      ;IIR = 1 - Should Not Happen
	DW		SerialTX_Empty 	;IIR = 2
	DW		SerialNone 	    ;IIR = 3 - Should Not Happen
	DW		SerialRX_Avail 	;IIR = 4
	DW		SerialNone	    ;IIR = 5 - Should Not Happen
	DW		SerialError 	;IIR = 6

;Procedure:			SerialError
;
;Description:      	This function takes the Serial Error from the LSR reg in the
;                   serial chip and enqueues the error with the SER_ERR_KEY such
;                   that it can be handled.                 
;Operation:			* Read in LSR reg val
;                   * Let only error bits pass into lower byte
;                   * Set SER_ERR_KEY into upper byte
;                   * Enqueue this with EnqueueEvent
;Arguments:        	AL  -   Value of error ID
;                   AH  -   Stores the SER_ERR_KEY
;Return Values:    	none.
;Shared Variables: 	none.
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SerialError		PROC NEAR

    %INPORT8_AL(LSR_ADDRESS)    ; Grab the LSR reg into AL  
    
    AND     AL, ERROR_BIT_MASKS ; Leave only Error bits uncleared
    
    MOV     AH, SER_ERR_KEY     ;Set the SER_ERR_KEY event to AH 
    CALL    EnqueueEvent        ;Passing AX into enqueue
    
    RET                         ; GO back to Serial Handler

SerialError   ENDP

;Procedure:			SerialRX_Avail
;
;Description:      	This function takes the next RX char that is available from the
;                   serial chip and enqueues it into the EnqueueEvent. It also makes
;                   sure to include the RX_ENQUEUED_KEY in the upper byte such that
;                   this event is properly identifiable.
;                   
;Operation:			* Read in RX reg val into AL
;                   * Set RX_ENQUEUED_KEY into upper byte
;                   * Enqueue this with EnqueueEvent
;Arguments:        	AL  -   Value of RX char
;                   AH  -   Stores the RX_ENQUEUED_KEY
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SerialRX_Avail		PROC NEAR

    %INPORT8_AL(RX_ADDRESS)    ; Grab the RX byte
    
    MOV     AH, RX_ENQUEUED_KEY ;Set the keyevent to AH 
    CALL    EnqueueEvent        ;Passing AX into enqueue   

	RET
	
SerialRX_Avail   ENDP

;Procedure:			SerialTX_empty
;
;Description:      	This function dequeues the next char from tx_queue and
;                   outputs it into the THRE of the serial chip. IF that tx-queue
;                   is empty, then the function will NOT output anything, and
;                   set the kickstart_flag to indicate that the THRE will remain
;                   empty and will need a kickstart.
;                   
;Operation:			* Check if tx_queue is empty
;                       * If so, then set kickstart_flag and then return
;                   *Else continue to dequeue the tx_queue and then output
;                    that char into the THRE reg of the serial chip.
;                   
;Arguments:        	SI - Holds pointer of TX-queue
;Return Values:    	none.
;Shared Variables: 	kickstart_flag(WRITE)
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SerialTX_Empty		PROC NEAR

    LEA     SI, tx_queue            ; Grab address of Queue
    CALL    QueueEmpty              ; Make sure queue is actually empty, to avoid inf
                                    ; blocking loop. Not critical code since already in Handler
    JNZ     TxQueueisReady          ; Queue has chars available
	;JZ		TXQueueisEmpty			; Queue does NOT have chars available
    
TXQueueisEmpty:
    MOV     kickstart_flag, TRUE    ; We need a kick start since chip will remain
                                    ; empty in THRE.

    JMP     SerialTX_EmptyDONE      ; Finished

TxQueueisReady:
    
    CALL    Dequeue                 ; Grab next val into AL
TxQueueOUT:
    %OUTPORT8_AL(TX_ADDRESS)        ; Output next TX char to serial chip 
    ;JMP     SerialTX_EmptyDONE     ; Finished

SerialTX_EmptyDONE:

    RET                             ;

SerialTX_Empty   ENDP

;Procedure:			SerialModem
;
;Description:      	This function will read the modem register from the serial
;                   chip and then store the ID bits into AL. It will then include
;                   the MODEM_KEY into AH and Enqueue this event for later processing.
;                   
;Operation:			* Read in MODEM reg val into AL
;                   * Set MODEM_KEY into upper byte
;                   * Enqueue this with EnqueueEvent
;
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	AL  -   Value of modem ID bits
;                   AH  -   Stores the MODEM_KEY
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SerialModem		PROC NEAR

    %INPORT8_AL(MSR_ADDRESS)  ; Grab the IIR reg into AL  
        
    MOV     AH, MODEM_KEY       ;Indicate this this MODEM val to AH 
    CALL    EnqueueEvent        ;Passing AX into enqueue
    
    RET                         ; GO back to Serial Handler
    
SerialModem   ENDP

;Procedure:			SerialNone
;Description:      	This function is a stub and just returns.            
;Operation:			* Return
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SerialNone		PROC NEAR

        RET ; Should not enter here, but if so just return.
        
SerialNone   ENDP

;Procedure:			SetBaud
;
;Description:      	This function sets the BAUD rate. It is passed the calc'ed
;                   div_rate in DX and placed the MSByte and LSByte of DX into
;                   the MSB and LSB div latches of the serial chip.
;
;Operation:			* Save all flags and turn off interrupts
;                   * Make a copy of DX in CX
;                   * Read in LCR reg val and turn ON DLAB bit
;                   * Write CH and CL into DLM reg and DLL reg respectively
;                   * Now turn back OFF DLAB bit and output to LCR reg
;                   * restore all flags
;Arguments:        	DX -> the desired divisor rate
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	CH  -   MSByte of the div rate val
;                   CL  -   LSByte of the div rate val
;                   AL  -   Values to be outputted on port
;                   DX  -   Address of port
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	CH, CL, AL, DX
;Stack Depth:		1 word
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		Interrupts are off through the whole process.
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------

SetBaud         PROC    NEAR

SetBaudInit:
    PUSHF                        ; Save All Flags
  
    CLI                          ; Turn Interrupts off to avoid critical code
   
    MOV     CX, DX               ; Make copy of DX since need it for OUT and IN instr
SetBaudDLABON:
    %INPORT8_AL(LCR_ADDRESS)     ; Grab current LCR reg val
    OR  AL, DLAB_BIT_ON          ; Mask OFF DLAB
    %OUTPORT8_AL(LCR_ADDRESS)    ; Enable LSByte div latch writing      
    MOV AL, CL                   ; Prepare to write LSByte of div factor
    %OUTPORT8_AL(DLL_ADDRESS)    ; Write to LSByte of div latch
    MOV AL, CH                   ; Prepare to write MSByte of div factor
    %OUTPORT8_AL(DLM_ADDRESS)    ; Write to MSByte of div latch       
    
SetBaudDLABOFF:
    %INPORT8_AL(LCR_ADDRESS)     ; Now retrieved the line ctrl val again 
    AND  AL, DLAB_BIT_OFF        ; Turn OFF DLAB
    %OUTPORT8_AL(LCR_ADDRESS)    ;   
    
    POPF                            ; Restore all flags
    RET

SetBaud     ENDP

;Procedure:			SetParity
;
;Description:      	This function sets the parity based on passed parity value.
;                   The arg AL can be NO_PARITY, PARITY_ODD, PARITY_EVEN, 
;                   PARITY_STICKY_CLR, or PARITY_STICKY_SET.
;
;Operation:			* Use pass AL parity code for loop up table of MASKs
;                   * Save that mask into BL for later
;                   * Now grab the LCR reg val, which controls parity
;                   * Clear all parity bits of LCR val
;                   * Finally turn ON all parity bits needed with OR mask
;                   * Output back that new parity setting
;
;Arguments:        	AL -> the desired parity key code
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	BX  -   Holds pointer for table loop up
;                   AL  -   Holds mask value, and LCR reg val
;                   BL  -   Holds copy of mask value
;                   DX  -   Address of LCR port
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	BX, AL, BL, DX
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	Table lookup
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
SetParity       PROC    NEAR

    LEA     BX, Parity_Table        ; Prepare for table look up
    XLAT	CS:Parity_Table			; Get the right parity mask  
    MOV     BL, AL                  ; Keep a copy of that value
    %INPORT8_AL(LCR_ADDRESS)        ; Now retrieved the line ctrl val  
    AND     AL, PARITY_BITS         ; Let us first clear all parity bits
    OR      AL, BL                  ; OR MASK proper parity bits
    %OUTPORT8_AL(LCR_ADDRESS)       ; Write back to LCR reg to complete parity change 
    RET                             ; Done

SetParity   ENDP

;Name:			    Parity_Table (BYTE Table)
;Description:      	This is the table used by the SetParity that maps the 
;                   parity key arg passed into the proper OR masks needed
;                   to turn on the right parity bits.              
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
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
Parity_Table	    LABEL	BYTE

    DB      NO_PARITY_MASK           ;no parity is generated or checked
	DB		PARITY_ODD_MASK 	     ;odd parity (an odd number of logic 1's)
    DB      PARITY_EVEN_MASK         ;even parity (an even number of logic 1's)
    DB      PARITY_STICKY_CLR_MASK   ;parity bit is transmitted and checked as cleared
    DB      PARITY_STICKY_SET_MASK   ;parity bit is transmitted and checked as set
    
;Procedure:			SerialInit
;
;Description:      	This function initializes 
;                   1. Local variables of the serial functions
;                   2. Serial Chip's word length, stop bits, div rate, and parity.
;                      Also chip's interrupt enables
;                   3. TX_queue
;                   4. SerialHander into vector table for INT2
;                   5. INT2Ctrl reg for triggering, and enable
;                   6. IMASK reg for allowing INT2 int
;                   After this, the Serial functions and serial chip is fully ready.
;                   
;Operation:         * Clear AL, mask ON appropriate WORD_LENTH_BITS and STOP_BITS
;                   * OUTPUT that val to LCR to set word and stop bit vals
;                   * CALL SetBaud with div rate in DX
;                   * CALL SetParity with NO_PARITY in AL
;                   * Initialize queue at tx_queue with MAX_Q_LENG - 1 elements as byte queue
;                   * Set kickstart_flag true
;                   * Install SerialHandler into Int2 of vector table
;                   * Enable RX and ERR interrupts on the serial chip by OR mask ON
;                     bits for the IER reg. Set those bits by writing to IER.
;                   * Set the INT2CON with appropriate triggering and unmask to enable
;                   * Make sure IMASK does not have INT2 masked by AND clearing the INT2 bit
;                     and writing back to IMASK reg
;                   * FInally send out to INTCtrl the INT2EOI.
;
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	kickstart_flag(WRITE)
;Local Variables:	AL  -   Holds read/write byte for ports
;                   DX  -   HOlds address for ports
;                   SI  -   holds pointer for queue
;                   AX  -   Holds val for ES 
;                   BL  -   queue size 
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	Al, AX, DX, SI, BL
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;                   11-30-2013: Working     - Anjian Wu
;                   12-01-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------

SerialInit      PROC    NEAR
	            PUBLIC  SerialInit
			
SerialSetWordandSTOP:

    XOR     AL, AL              ; Clear bits for LCR
    
    OR      AL, WORD_LENTH_BITS ; Turn on bits for proper word length
    OR      AL, STOP_BITS       ; Turn on bits for proper # of stop bits
     
    %OUTPORT8_AL(LCR_ADDRESS)   ; Set those word and stop bit settings to LCR
     
SerialBAUDandParity:
    MOV     DX, div_rate        ; Set the proper div value for baud rate
    CALL    SetBaud             ; 
    MOV     AL, NO_PARITY       ; Set for no parity
    CALL    SetParity           ;
    
SerialMakeQueue:
    LEA     SI, tx_queue        ; Grab address of tx Queue
    MOV     AX, MAX_Q_LENG - 1  ; Prepare to make queue of max length
    MOV     BL, BYTE_QUEUE      ; We want a BYTE tx queue
    CALL    QueueInit           ; Make a Queue of Bytes with length MAX_Q_LENG - 1
    
SerialKickInit:
    MOV     kickstart_flag, TRUE    ; Initialize with kickstart
    
SerialVectorInit:
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Int2Vec), OFFSET(SerialHandler)
        MOV     ES: WORD PTR (4 * Int2Vec + 2), SEG(SerialHandler)
                                 ; We mul by 4 since each vector is comprised
                                ; of a CS:IP (WORD:WORD). Thus each unit is normalized
                                ; to four bytes and we need to jump 4 positions per vector.       
SerialChipIntEnable:
    XOR     AX, AX                   ;  Clear bits for IER
    OR      AL, RXINT_ON             ;  Turn on RX interrupts
    OR      AL, ERRINT_ON            ;  Turn on Error interrupts
   %OUTPORT8_AL(IER_ADDRESS)         ;  Set IER with those RX and ERR settings

    
SerialInt2Enable:

    MOV     DX, INT2Ctrl            ;Setup how hardware INT2 works
    MOV     AX, INT2VAL             ;Turn it on along with proper trigger settings
    OUT     DX, AL
    
SerialInt2MASKENABLE:

    MOV     DX, IMASK_ADDR            ;Make sure IMASK allows fro INT2
    IN      AL, DX
    AND     AL, INT2_MASK_REG         ;By masking OFF INT2 bit of IMASK
    OUT     DX, AL                    ;
    
    
SerialSetEOI:   
    MOV     DX, INTCtrlReg          ;send the EOI to INT2 control
    MOV     AX, INT2EOI
    OUT     DX, AL
    
    RET                                
SerialInit      ENDP

CODE    ENDS
    
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

tx_queue          QUEUESTRUC <>           ; Holds the TX serial queue
kickstart_flag      DB      ?             ; Holds the kickstart flag

DATA    ENDS

        END 