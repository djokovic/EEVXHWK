NAME        Keypad

$INCLUDE(Keypad.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW5 Keypad Functions                      ;
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
;   KeyHandler  -   Timer1 event handler that interrupts every MILI_SEC. It will
;                   scan the next keypad ROW OR continue debouncing a current
;                   row. If a key is deemed debounced, then it is stored into
;                   a local shared variable and a debounce flag is raised.
;
;   KeyCheck    -   This is the function accessed by the mainloop to check whether
;                   a key is debounced. It just polls the debounce flag. If 
;                   a debounce is flagged, then it will grab that key and 
;                   CALL EnqueueEvent.
;                   
;
;   KeyHandlerInit - This installs the KeyHandler into vector table and
;                   initializes all values.
;
;
;                                   Data Segment
;
;
;   DCounter(DW)-   The debouncing counter holder for KeyHandler.
;   Dflag       -   The flag used by Handler to signal a key has been debounced.
;   DebouncedKey-   Stores the key that was debounced.
;
;                                 What's was last edit?
;
;       			Pseudo code -> 11-11-2013 - Anjian Wu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			KeyHandler
;
;Description:      	This procedure debounce a key by scanning a all FOUR rows
;                   every interrupt.  This design decision is because then the procedure
;                   will not have ot keep track of a ROW counter.
;           
;                   This function will loop through all 4 rows and save a KEYCODE
;                   if it detects a key pressed. Notice that if more than ONE row's key
;                   is pressed, then the KEYCODE will take the ROW with the LARGEST index.
;                   This is because the loop going from row = 0 to row = 3.
;
;                   The keycode is a byte with TOP nibble = ROW index, bottom nibble = COLUMN
;
;                   It will then check if the KEYCODE is valid (aka > 0). If so it will check
;                   whether this keycode was caught before, which would mean incrementing the counter;
;
;                   If the keycode is NEW, or if no keycode was detected, then the counter is emptied.
;
;                   Lastly, the counter is checked to see if the debounce value MILLI_SEC is reached.
;                   
;                   
;Operation:			*   Grab the debounce counter and the previous key
;                   *   Loop from row = 0 to 4, and save the KEYCODE if key is pressed
;                   *   Check if KEYCODe is even valid
;                       *   If valid, then see if it is same as previous, if so increase counter
;                       *   Else empty counter   
;                   *   If KEYCODe not valid, also empty counter
;                   *   CHeck if counter has reached the proper value
;                       *   If so, then empty counter and set TRUE return flag
;                   *   Store back counter to Data seg.
;
;Arguments:        	DCounter       -> Latest debouncing counter value
;                   DebouncedKey   -> Stores the last key being tested for debouncing.
;
;Return Values:    	DFlag -> FLag used by KeyCheck to see if key is ready to grab.
;
;Result:            New DCounter, and possibly new DebouncedKey
;
;Shared Variables: 	The DFlag and DebouncedKey is shared with KeyCheck.
;
;Local Variables:	key - stores the KEYCODE (can be valid or not)
;                   lastkey - stores the last key used to compare with KEYCODE
;                   counter - Stores the DCounter
;                   keytemp - temporary variable that stores direct keypad values
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	4 x 4 Keypad.
;
;Output:           	None.
;
;Registers Used:	None.
;
;Stack Depth:		None.
;
;Known Bugs:		None.
;
;Data Structures:	None.
;
;Error Handling:   	None.  
;
;Algorithms:       	Loops all rows and checked each row for valid key press.
;
;Limitations:  		Does not check for whether DFlag is already high,
;                   thus there is a chance that a new debounce key might
;                   be pressed and debounced before previous key is fully
;                   handled. However I assume the key is handled much faster
;                   than human user pressing.
;
;
;Author:			Anjian Wu
;History:			11-11-2013: Pseudo code - Anjian Wu
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
    MOV     keytemp, 0      ; Clear temporary variable
    
;------------------------Key Grabbing-----------------------------------------
    
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
    
    CMP     AL, 0           ; Were there any keys even pressed?
    JE      KeyRowLoopEnd   ;
;   JNE     KeyRowLoopAbsCalc;

KeyRowLoopAbsCalc:          ; Lets include information of ROW into AL
    
    MOV     BX, CX          ; Grab the Row value (lower 2 bits of last nibble)
    SHL     BX, nibble_size ; Now Row information is in 2nd to last nibble
    
    ADD     AX, BX          ; Now AL will have xx[R1][R0]-[C3][C2][C1][C0]
                            ;                    Row info Column info  
    MOV     keytemp, AX     ; Store this for checking later
    
KeyRowLoopEnd:

    INC     CX              ;
    JMP     KeyRowLoop      ;
    
KeyRowLoopExit:
;------------------------Key Processing-----------------------------------------

    CMP     keytemp,    0       ; Was there even a key pressed?
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
    
	ADD		BX, AX			        ; Get absolute appropriate seg table addr
    
    MOV		AL,	CS:[BX]		        ;Now seg val is in AX
    
    ;XLAT	CS:KeyHandlerTable		    ;Get that key mapped value to AL 
  
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
;                    Dcounter, and DebouncedKey.
;
; Operation:         First clear Dflag, Dcounter, and DebouncedKey.
;                    THen writes the address of the KeyHandler to the
;                    timer1 location in the interrupt vector table. Notice
;                    need to multiple by 4 since table stores a CS and IP.
;                     
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Used to temporarily store vector table offset for ES
; 
; Shared Variables:  Dflag, Dcounter, and DebouncedKey
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
;-------------------------------------------------------------------------------

KeyHandlerInit  PROC    NEAR
                PUBLIC  KeyHandlerInit


KeyHandlerInitStart:
        MOV     Dflag, 0          	; Clear the Dflag
        MOV     Dcounter, 0       	; Clear the Dcounter 
        MOV     DebouncedKey, 0   	; Clear the DebouncedKey
		MOV		Rcounter, 0			; CLear the Repeat counter
        
KeyHandlerInitVector:
       
        ; Bottom left in ASSEMBLY since it stays the same anyways.

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(KeyHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(KeyHandler)


        RET                     ;all done, return


KeyHandlerInit  ENDP
				
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'


    Dflag           DW  ?     ;The shared flag for KeyHandler, KeyCheck, and KeyHandlerInit
                                           
    Dcounter        DW  ?     ;The shared counter for KeyHandler, and KeyHandlerInit

    Rcounter        DW  ?     ;The shared counter for KeyHandler, and KeyHandlerInit

    DebouncedKey    DW  ?     ;The shared KEYCODE for KeyHandler, KeyCheck, and KeyHandlerInit
	
	keytemp			DW  ?     ;The shared KEYCODE for KeyHandler, KeyCheck, and KeyHandlerInit
	
DATA    ENDS

        END 