NAME        Serial

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
;   SerialHandler   -   Handles all serial chip interrupts  
;   Install_Serial  -   Places Serialhandler into int vector table
;   SetBaud         -   Sets appropriate baud rate into serial chip
;   SetParity       -   Sets appropriate parity into serial chip
;   Serialinit      -   Initializes all serial function variables and chip
;                                 What's was last edit?
;
;       			Pseudo code -> 11-25-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
;                       * Set carryflag FALSE
;                       * Enqueue the passed char
;                       * Check if the kickstart_flag is true
;                       * If so, then read in IER value, mask OFF THRE  bit
;                       * Send out new IER value, then MASK ON THRE bit again
;                       * Finally send out final IER value to complete kickstart
;                       * Reset the kickstart_flag
;
;Arguments:        	c   -> The new char to be placed
;
;Return Values:    	Carry Flag - > indicates of queue was able to accept the char.
;
;Shared Variables: 	kickstart_flag(READ/WRITE)
;
;Local Variables:	Val -> stores the temporary IER val that gets masked.
;                   
;Global Variables:	None.
;								
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	None.
;
;Stack Depth:		None.
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
;------------------------------------------------------------------------------


SerialPutChar(c)
{
    If (QueueFull(serial_queue)== TRUE)
    {
        CarryFlag = TRUE;
        
    }
    else
    {
        CarryFlag = FALSE;
        
        Enqueue(c, serial_queue);
    
        If (kickstart_flag == TRUE)
        {
            ;Turn OFF THRE interrupt in interrupt enable register (IER)
            
            val = IN(IER_ADDRESS)               ; Grab current IER reg val
            
            val = MASKOFF(IER_VAL, THRE_INT_OFF); MASK THRE OFF
            
            OUTPUT(IER_ADDRESS, val)            ; SEnd it out
            
            ;Turn ON THRE interrupt in interrupt enable register (IER)
            
            val = MASKON(val, THRE_INT_ON)  ; Now MASK it back ON
            
            OUTPUT(IER_ADDRESS, val)            ; Send it out again
            
            kickstart_flag = FALSE                  ; Kick start DONE,
        }

    }
    
    RETURN CarryFlag ;
}

;Procedure:			SerialHandler
;
;Description:      	This function is the event handler for serial. It will
;                   take the INT2 hardware interrupt and process which type
;                   of serial chip interrupt is present via the IIR register.
;                   For errors, the error variable take all the error bits,
;                   for RX rdy or TX empty, the handler will enqueue and dequeue
;                   the RX and TX queues respectively. For Modem int, the modem
;                   status is also stored into the modem_status variable.
;
;Operation:			
;                   * Grab IIR address
;                   * IF IIR is a receiver line int
;                       * Then grab the line reg value
;                       * Mask off all bits except the error ones
;                       * Store that as the error var.
;                   * IF IIR is a rx ready int
;                       * Then grab the rx buffer variable
;                       * Enqueue that value
;                   * IF IIR is a tx empty int
;                       * see if queue is empty
;                       * if so, then dequeue and output it to THRE
;                       * else, set kickstart_flag
;                   * IF IIR is a modem int
;                       * Then grab the modem value
;                       * Store that as the modem_status var.
;
;
;Arguments:         None.
;
;Return Values:    	None.
;
;Shared Variables: 	Kickstart_flag(READ/WRITE)
;
;Local Variables:	IIR_VAL -> temporary var for storing IIR reg value.
;                   
;Global Variables:	None.
;						
;Input:            	none.
;
;Output:           	none.
;
;Registers Used:	none.
;
;Stack Depth:		none.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	none.
;
;Algorithms:       	none.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------

SerialHandler
{
    IIR_VAL = IN(IIR_ADDRESS)                       ; Grab all int status bits
    
    IF(IIR_VAL == RECEIVER_LINE_STATUS)             ; Does the IIR contain receiver
                                                    ; error interrupt?
    {
        val = IN(LINE_REG_ADDRESS)         ; Yes, so grab line reg val
        
        error = MASK(val, ERROR_BIT_MASKS) ; Grab only ERROR related bits
        
        
        IIR_VAL = IIR_VAL - RECEIVER_LINE_STATUS    ; Turn off receiver line bit
                                                    ; NOTE this can be done with
                                                    ; Just a subtract
    }
    
    ELSEIF(IIR_VAL == RX_AVAILABLE)                     ; Does we have a data available?
    {
        val = IN(RX_BUFF_ADDRESS)           ; Yes, do grab the val from RX buffer
        
        EnqueuEvent(val)                    ; Enqueue that value.
        

    }
    ELSEIF(IIR_VAL == TX_AVAILABLE)                     ; Can we output something?
    {
        IF(!Queue_Empty(serial_queue))
        {
            val = dequeue(serial_queue)     ; Yes, do grab the val from RX buffer
            OUTPUT(val, TX_REG_ADDRESS)     ; Enqueue that value.
        }
        else
        {
            kickstart_flag = TRUE;
        }

    }
    ELSE                                            ; Only Modem status int left
    {
        val = IN(MODEM_ADDRESS)           ; Yes, do grab the val from RX buffer
        
        Modem_status = val;                   ; Enqueue that value.
        

    }

    RETURN
}

;Procedure:			Install_Serial
;
; Description:      This functions installs the SerialHandler into the
;                   INT2 location of the INT vector table.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      None.
;
; Last Modified:    pseudo -> 11-25-2013 - Anjian Wu


Install_Serial      PROC        NEAR 
                    PUBLIC      Install_Serial
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Int2Vec), OFFSET(SerialHandler)
        MOV     ES: WORD PTR (4 * Int2Vec + 2), SEG(SerialHandler)
        
Install_Serial ENDP


;Procedure:			SetBaud
;
;Description:      	This function sets the BAUD rate. It does this by calculating
;                   the proper div factor and storing that into the div latch MSB
;                   and LSB.
;
;Operation:			* div_rate = CLOCK_FREQ/(baud * 16)
;                   * turn ON DLAB bit of line ctrl reg
;                   * now write LSB div_rate into DIV_LSB_LATCH
;                   * turn OFF DLAB bit of line ctrl reg
;                   * now write MSB div_rate into DIV_MSB_LATCH
;Arguments:        	baud -> the desired baud rate
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
;Algorithms:       	div_rate = CLOCK_FREQ/(baud * 16)
;Limitations:  		None.
;Author:			Anjian Wu
;History:			11-25-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------

SetBaud(baud)
{
    div_rate = CLOCK_FREQ/(baud * 16) ; Calculate baud rate divider
    
    val = IN(LINE_CTRL_ADDR)    ;   Grab line ctrl reg values
    val = MASKON(val, DLAB_BIT) ;   Turn on DLAB so we can write DIV LSB
    OUTPUT(LINE_CTRL_ADDR, val) ;   Now we can write to LSB
  
    OUTPUT(DIV_LSB_LATCH_ADDR, LSB(div_rate));  Set LSB value
       
    val = IN(LINE_CTRL_ADDR)    ;   Turn DLAB back off
    val = MASKOFF(val, DLAB_BIT) ;  
    OUTPUT(LINE_CTRL_ADDR, val) ; Now we can write MSB of DIV factor
    
    OUTPUT(DIV_MSB_LATCH_ADDR, MSB(div_rate));

    
    RETURN
    
}

;Procedure:			SetParity
;
;Description:      	This function sets the parity based on passed parity value.
;                   
;Operation:			* Read in line ctrl value.
;                   * MASK off the parity bits for now
;                   * Then grab proper OR mask by using table with parity value
;                   * OUTPUT the OR of retrieved value back to the line ctrl reg
;
;Arguments:        	parity -> the desired parity
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
;------------------------------------------------------------------------------
SetParity(parity)
{

    val = IN(LINE_CTRL_ADDR)            ;
    
    val = MASKOFF(val, PARITY_BITS)     ;
        
    output = TABLELOOKUP(parity)        ;
    
    OUTPUT(OR(output, val), LINE_CTRL_ADDR);
    

}

;Procedure:			SerialInit
;
;Description:      	This function initializes all local variables of the 
;                   serial functions, and sets up the serial chip.
;                   
;Operation:         * MASK on appropriate word length and stop bits for
;                     the lin ctrl register.
;                   * Output that, and call Setbaud, and SetParity.
;                   * Reset error and kickstart_flag variables
;                   * Initialize the TX serial queue
;                   * Finally send out INT2 a EOI to start interrupts.
;
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	error (WRITE)
;                   kickstart_flag(WRITE)
;Local Variables:	lin_val -> stores the temporary line ctrl val
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
;------------------------------------------------------------------------------

SerialInit
{
    lin_val = 0;
    
    lin_val = OR(lin_val, WORD_LENGTH)  ; Mask ON bits for desired word length
    
    lin_val = OR(lin_val, STOP_BITS)    ; Mask ON bits for desired # of stop bits
    
    OUTPUT(LINE_CTRL_ADDR, lin_val)     ; Output those settings
    
    SetBaud(DEFAULT_RATE)   ; Set the baud rate
    SetParity(NO_PARITY)    ; Set the parity
    
    error = NO_ERROR        ; No errors yet
    
    kickstart_flag = FALSE  ; No kick start
    
    QueueInit(tx_queue, TX_QUEUE_SIZE); Initialize the TX queue
    
    OUTPUT(INT2CTRL_EOI, INT2EOI); Send out INT2 EOI to start interrupts.


}

