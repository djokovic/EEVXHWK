NAME        Keypad

$INCLUDE(motors.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW6 Motor Functions                       ;
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
;   SetMotorSpeed  -   Timer0 event handler that interrupts every milisecond.
;   GetMotorSpeed  -   Timer0 event handler that interrupts every milisecond.
;   GetMotorDirection  -   Timer0 event handler that interrupts every milisecond.
;   SetLaser  -   Timer0 event handler that interrupts every milisecond.
;   GetLaser  -   Timer0 event handler that interrupts every milisecond.
;
;
;
;                                   Data Segment
;
;
;   DCounter    -   The debouncing counter holder for KeyHandler.
;   RCounter    -   The auto_repeat counter holder for KeyHandler.
;   Dflag       -   The flag used by Handler to signal a key has been debounced.
;   DebouncedKey-   Stores the key that was/in process of being debounced
;   Keytemp     -   Stores the temporary variable in KeyHandler (also helps debugging)
;
;                                 What's was last edit?
;
;       			Pseudo code -> 11-11-2013 - Anjian Wu
;       			Working     -> 11-15-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			KeyHandler
;
;Description:      	This procedure debounce a key by scanning a all FOUR rows
;                   every interrupt. It is divided into the following sections:
;
;                   Key Detection -> Loop numOfRows times by grabbing
;                   each ROW by increasing order from port address KEYOFFSET
;                   to KEYOFFSET + numOfRows - 1. After grabbing each row BYTE
;                   , invert the BYTE (since active low) and then mask off 
;                   unused upper nibble of that byte. Then combine the row
;                   and column information into one BYTE where low nibble is
;                   the column (from before) and the UPPER nibble is just the
;                   row index. This is stored in keytemp which will 
;                   have xx[R1][R0]-[C3][C2][C1][C0].
;                   
;                   Key Processing -> Now we have keytemp, which I use to check
;                   if a key was even pressed. 
;                   There are three possible paths of key processing
;                   1. No Key
;                   2. Different key than the DebounceKey from before
;                   3. SAME key, which gets treated in two differnt ways
;                           a)  Same key, but hasn't been debounced yet
;                           b)  Same key, but HAS been debounced and needs
;                               auto-repeat.
;                   4. If either 3a or 3b's debouncekey is deemed ready then 
;                      access the KeyTable and grabbed the key value.
;
;                   When a key has been debounced, the Dflag is set high, the 
;                   Dcounter has hit DEBOUNCE_TARGET and needs to be reset,
;                   and the value in DebounceKey is considered VALID.
;
;                   Afterwards, the Dflag will remain high if the same key is HELD
;                   indicating that this needs to use Rcounter instead to hit
;                   the AUTO_REPEAT value before the key is debounced again.
;
;                   Otherwise if there is any diff key or NO key detected in 
;                   between the Dflag will be reset and the value inside
;                   DebounceKey is considered invalid on again.
;                                    
;                   
;Operation:			Key Detection -> 
;                   *   Loop numOfRows times by grabbing
;                       each ROW by increasing order from port address KEYOFFSET
;                       to KEYOFFSET + numOfRows - 1. 
;                       *   Invert the BYTE (since active low) and then mask off 
;                           unused upper nibble of that byte.
;                       *   If a key is detected (aka keytemp > 0) then move on
;                           to add in ROW bits into upper nibble, else keytemp = 0
;                   *   When the loop terminated, only the key from the HIGHER
;                       index is ultimately recorded. Thus if a user pressed a
;                       key at address KEYOFFSET and another at KEYOFFSET +
;                       numOfRows - 1, then only the LATTER key is saved.
;
;
;                   Key Processing -> Now we have keytemp, which I use to check
;                   if a key was even pressed. 
;
;                   There are three possible paths of key processing
;
;                   *   No key
;                           * Reset DCounter, Dflag, and RCounter
;
;                   *   Different key than the DebounceKey from before   
;                           * Store NEW key in debouncedkey
;                           * Reset DCounter, Dflag, and RCounter
;
;                   * SAME key, which gets treated in two differnt ways
;                           a)  If the DFlag is LOW
;                               * Increment Dcounter
;                               * Check if counter is full
;                               * If full then grab mapped key value from Keytable
;                                 and pass to EnqueueEvent. Also set Dflag true.
;
;                   * Different key, which gets treated in two differnt ways
;                           a)  If the DFlag is HIGH
;                               * Increment Rcounter
;                               * Check if Rcounter is full
;                               * If full then grab mapped key value from Keytable
;                                 and pass to EnqueueEvent. Also set Dflag true.
;
;                   * Finally send out end of interrupt
;
;Arguments:        	DCounter     -> Latest debouncing counter value
;                   Rcounter     -> Latest auto repeat counter (usually much larger)
;                   DebouncedKey -> Stores the last key being tested for debouncing.
;                   DFlag        -> Shows whether debounced has occured
;
;Return Values:    	DFlag -> FLag used by KeyCheck to see if key is ready to grab.
;                   DebouncedKey -> Stores the last key being tested for debouncing.

;
;Result:            Possibly new DCounter, Rcounter, DebouncedKey, and DFlag
;
;Shared Variables: 	The DFlag, DebounceKey, Keytemp, RCounter, and Dcounter are
;                   only shared with KeyHandlerInit.
;
;Local Variables:	keytemp -   temporary variable that stores direct keypad values
;                   AX      -   Used to store values for CMP
;                   BX      -   Used for talke look up
;                   CX      -   Counter
;                   DX      -   PORT addressing and interrupt EOI
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	4 x 4 Keypad.
;
;Output:           	14-seg display (via EnqueueEvent)
;
;Registers Used:	AX, BX, CX, DX
;
;Stack Depth:		8 Words
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	If a key is pressed that does not Map to a key function
;                   then the KeyTable will return a NOTAKEY cmd written to 
;                   EnqueueEvent which indicated to ignore this action.
;
;Algorithms:       	Loops all rows and checked each row for valid key press.
;
;Limitations:  		1.  Only detects keys pressed in a single ROW, not an issue
;                       if only designed for 1 key functionality.
;
;                   2.  Only considers the higher indexed ROW's keys, thus if
;                       key is pressed at KEYOFFSET and KEYOFFSET + 1, then only
;                       the latter is recognized. 
;
;                   3.  Since DebounceKey is not reset, functionally it 
;                       takes ONE less interrupt count to debounce the same
;                       key pressed consecutively (not key being held), as opposed
;                       to debouncing a NEW key. However the difference is 
;                       indistinguishable from the users perspective. 
;
;
;Author:			Anjian Wu
;History:			11-11-2013: Pseudo code - Anjian Wu
;       			11-15-2013: Working     - Anjian Wu

;------------------------------------------------------------------------------

CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;-------------------------------------------------------------------------------
        EXTRN   EnqueueEvent:NEAR          ; Used to convert passed AX into hex ASCII
        EXTRN   KeyHandlerTable:NEAR   ;


    
KeyHandler		PROC    NEAR
				PUBLIC  KeyHandler
				
	PUSHA;  Save all regs
	
KeyHandInit:

    XOR     CX, CX          ; Clear CX
    MOV     keytemp, NOKEYPRESS ; Assume no key pressed so far
    
;------------------------Key Detection-----------------------------------------
    
KeyRowLoop:

    CMP     CX, numOfRows   ; Check to see if counter is done with all rows
    JGE     KeyRowLoopExit  ; If so, then exit loop
    ;JLE    KeyRowLoopBody  ; Else, continue
    
KeyRowLoopBody:
    
    MOV     DX, CX          ; Prepare to get absolute keypad value from PORT
    ADD     DX, KEYOFFSET   ; Abs address = offset + current row
    IN      AL, DX          ; Grab the next row's column values
    
    NOT     AX              ; Keys are 'active' low   
    AND     AX, lownibblemask   ; Mask off the unused bits (only lowest nibble needed)
    
;Now we have AL = xxxx-xxxx-xxxx-[][][][], where [] -> valid column value
    
    CMP     AL, NOKEYPRESS  ; Were there any keys even pressed?
    JE      KeyRowLoopEnd   ;
;   JNE     KeyRowLoopAbsCalc;

KeyRowLoopAbsCalc:          ; Lets include information of ROW into AL
    
    MOV     BX, CX          ; Grab the Row value (lower 2 bits of last nibble)
    SHL     BX, nibble_size ; Now Row information is in 2nd to last nibble
    
    ADD     AX, BX          ; Now AL will have xx[R1][R0]-[C3][C2][C1][C0]
                            ;                    Row info Column info  
    MOV     keytemp, AX     ; Store this for checking later
    
KeyRowLoopEnd:

    INC     CX              ; Update counter
    JMP     KeyRowLoop      ; Loop
    
KeyRowLoopExit:
;------------------------Key Processing-----------------------------------------

    CMP     keytemp,NOKEYPRESS  ; Was there even a key pressed after loop?
    JE      KeyHandResetAll     ; Nope, so reset every data variable. Fresh start :)
                                ; Notice that DebouncedKey is not reset, but should
                                ; already have been reset from previous states.
                                
    ;JNE    KeyHandKeySort      ; Yes, continue
    
KeyHandKeySort:; Determines if it is SAME key as before or NEW key
    
    MOV     AX, keytemp         ; Store local keytemp variable for COMPAREs
    CMP     AX, DebouncedKey    ; Is this the same key as before?
                                ; used AX since (No mem2mem CMP allowed)
                                
    JE      KeyHandSameKey      ; Yes it is same key as previous interrupt
    ;JNE    KeyHandDiffKey      ; No, this is different key
    
KeyHandDiffKey:

    MOV     DebouncedKey, AX    ; Store that key with AX (mem2mem MOV not allowed)
    JMP     KeyHandResetAll        ; Still reset all other variables though
    

KeyHandSameKey:

    CMP     DFlag,  TRUE           ; Was this key pressed/debounced before?
    
    ; The DFLag also provides protection against two same key presses WITH no key
    ; press in between. This is because even though the DebouncedKey stored is same
    ; DFlag is always reset if no key was pressed. Thus we still will process as
    ; a FIRST time debounce.
    
    JE      KeyHandSameKeyAutoRepeat;
    ;JNE    KeyHandSameKeyNOTDebouncedYet; 
    
KeyHandSameKeyNOTDebouncedYet:

    INC     Dcounter                    ; Increment Debounce counter
    CMP     Dcounter, DEBOUNCE_TARGET   ; Reached debounce target?
    JE      KeyHandFirstRepDone         ; If so, then the first debounce is done
    JNE     KeyHandlerDONE              ; Done until next time
     
KeyHandSameKeyAutoRepeat:

    INC     Rcounter                ; Increment the repeat counter
    CMP     Rcounter, AUTO_REPEAT   ; Is the repeat counter maxed?
    JGE     KeyHandAUTODone         ; If so then time for another debounce
    JNE     KeyHandlerDONE          ; Else done
    
KeyHandFirstRepDone:
    MOV     Dflag,  TRUE            ; First time debouncing -> Dflag set
    MOV     Rcounter, 0             ; Reset Repeat counter
    JMP     KeyHandEnqueue          ; Time to enqueue
    
KeyHandAUTODone:
    MOV     Rcounter, 0         ;   Reset Rcounter to be ready for another auto repeat
    ;JMP    KeyHandEnqueue      ;   Time to enqueue again
    
KeyHandEnqueue:

    ;MOV     AX, keytemp        ; Not used since AX should still have keytemp...
    
    MOV	    BX, OFFSET(KeyHandlerTable);point into the table of Keys
    
	ADD		BX, AX			    ; Get absolute appropriate seg table addr
    
    MOV		AL,	CS:[BX]		    ;Now key code val is in AL
      
    MOV     AH, KEYEVENT        ;Set the keyevent to AH
    
    CALL    EnqueueEvent        ;Passing AX into enqueue
    
    JMP     KeyHandlerDONE      ;Finished!

    
KeyHandResetAll:; The only way all vars are reset is if no key or a new key pressed.
                ; This makes sense since the only other case is if the same
                ; KEY was pressed, meaning we would want to retain vars.
                
    MOV     Dflag, 0            ; Clear flag, and both repeat and regualr debounce
    MOV     Dcounter, 0         ; counters.
    MOV     Rcounter, 0         ;
    ;jmp    KeyHandlerDONE      ;

KeyHandlerDONE:; Send out EOI as usual

    MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
    MOV     AX, TimerEOI
    OUT     DX, AL
    
        
    POPA; restore all regs
    
    IRET
    

    KeyHandler  ENDP




; KeyHandlerInit
;
; Description:       Does all initializations for KeyHandler.
;
;                    Installs the displayhandler for the timer0 interrupt at 
;                    interrupt table index Tmr0Vec. ALso clears the Dflag,
;                    Rcounter, Dcounter, and DebouncedKey.
;
; Operation:         First clear Dflag, Dcounter, Rcounter and DebouncedKey.
;                    Then writes the address of the KeyHandler to the
;                    timer0 location in the interrupt vector table. Notice
;                    need to multiple by 4 since table stores a CS and IP.
;                     
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Used to temporarily store vector table offset for ES
; 
; Shared Variables:  Dflag, Rcounter, Dcounter, and DebouncedKey.
;
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Used:    AX, ES
;
; Stack Depth:       0 words
;
;Author:			Anjian Wu
;History:			11-11-2013: Pseudo code - Anjian Wu
;       			11-15-2013: Working     - Anjian Wu
;-------------------------------------------------------------------------------

KeyHandlerInit  PROC    NEAR
                PUBLIC  KeyHandlerInit


KeyHandlerInitStart:
        MOV     Dflag, 0          	; Clear the Dflag
        MOV     Dcounter, 0       	; Clear the Dcounter 
        MOV     DebouncedKey, 0   	; Clear the DebouncedKey
		MOV		Rcounter, 0			; CLear the Repeat counter
        
KeyHandlerInitVector:
       
        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(KeyHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(KeyHandler)


        RET                     ;all done, return


KeyHandlerInit  ENDP
				
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'


    Dflag           DW  ?     ;Flag to show that a Key was debounced recently
                                           
    Dcounter        DW  ?     ;Debounce count for single key press

    Rcounter        DW  ?     ;Debounce count for auto-repeat key press

    DebouncedKey    DW  ?     ;Stores key pressed 
	
	keytemp			DW  ?     ;Temporary variable used in Keyhandler
	
DATA    ENDS

        END 