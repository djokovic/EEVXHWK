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

KeyHandler()

{


    key = 0;
    keytemp = 0;
    
    lastkey = DebouncedKey;
    
    counter = DCounter;
    
    For(row = 0, row < 4, row++)
    {
        keyaddress = row + keyoffset    ; Get the absolute ROW address in I/O
        keytemp = IOREAD(keyaddress)    ; Grab the key code from that row
        
        keytemp = NOT(keytemp)          ; Invert the key code
        keytemp = 0x0F                  ; Mask the bottom nibble
        
        If (keytemp > 0)                ; If true, then a key is held
        {
            key = keytemp + (row << 4)  ; Top nibble is ROW, bottom nibble is Column
        }
    
    }

    
    if(key > 0)                 ; If there was a key detected from before
                                ; This is important, so that a NONE key press doesn't
                                ; trigger a true flag.
    {
        
        if(key == lastkey)      ; If this KEY is equal to previous key
        {
            counter ++;         ; INC the counter
        }
        else
        {
            counter = 0         ; Else this is new key, so clear counter       
        }
        
        DebouncedKey = key      ; Either way, store this new detected key 
    
    }                           ; Notice if key si not detected, Debounced key
    else
    {
        counter = 0             ; Either
                                ;1.The key held from previous cycle is not held
                                ;2.No key has been held
                                ; Regardless, empty the counter;             

        
    }
              
    If (counter >= MILLI_SEC)   ; Did the counter reach the target value?
    {
        counter = 0;            ; Yes, so clear it
        Dflag = true            ; Set the Dflag as true.
    }
    

    DCounter = counter          ; Counter is saved for next time.
                                
    return;
}


;Procedure:			KeyCheck
;
;
;Description:      	This a simple procedure that is called to check on the DFlag.
;                   If the Dflag is true, then the KeyHandler has detected a debounced
;                   key that is ready to be TABLELOOKed up. The table mapped value is
;                   then passed to the EnqueueEvent to be stored and the Dflag is cleared.
;
;                   If no key is detected. The function will simply return.
;
;                   
;                   
;Operation:			*   Check DFlag
;                       * If flag is set, then grab DebouncedKey
;                       * Grab table mapped value for DebouncedKey
;                       * Pass that value to EnqueueEvent
;                       * Clear Dflag
;                   *   Else do nothing
;                   *   Return
;
;Arguments:        	DFlag    - determines whether a key has been debounced or not
;
;
;Return Values:    	None.
;
;Result:            Possibly reset DFlag and new enqueued debounced key
;
;Shared Variables: 	DFlag and DebouncedKey
;
;Local Variables:	flag    - Stores DFlag 
;                   KEYCODE - Stores keycode from KeyHandler and new table arg
;                             to be passed to EnqueueEvent
;
;Global Variables:	None.
;					
;					
;Input:            	None.
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
;Error Handling:    If the debounced key is composed of TWO or more key presses,
;                   then it will mapped to a NOTAKEY code. Of which it will
;                   not be Enqueued.
;                   
;
;Algorithms:       	None.
;
;Limitations:  		None.
;
;
;Author:			Anjian Wu
;History:			11-11-2013: Pseudo code - Anjian Wu
;-------------------------------------------------------------------------------


KeyCheck()
{
    flag = Dflag; Grab the shared flag 
    
    IF(flag == true) ;  was there a key debounced?
    {
        KEYCODE = DebouncedKey; Yes, so grab it
        
        KEYCODE = LOOKUPTABLE(KEYCODE); Grab the mapped KEYCODE
        
        IF(KEYCODE != NOTAKEY)  ; Is this a valid key command
        {
            EnqueueEvent(KEYCODE);  Yes, so pass it
        }
        Dflag = false; Key is now handled, clear the Dflag.
           
    }
    
    
    return;

}	


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


        Dflag = 0           ; Clear the Dflag
        Dcounter = 0        ; Clear the Dcounter 
        DebouncedKey = 0    ; Clear the DebouncedKey
        
        
        ; Bottom left in ASSEMBLY since it stays the same anyways.

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr1Vec), OFFSET(KeyHandlerInit)
        MOV     ES: WORD PTR (4 * Tmr1Vec + 2), SEG(KeyHandlerInit)


        RET                     ;all done, return


KeyHandlerInit  ENDP
				

    
DATA    SEGMENT PUBLIC  'DATA'


    Dflag           DW  ?     ;The shared flag for KeyHandler, KeyCheck, and KeyHandlerInit
                                           
    Dcounter        DW  ?     ;The shared counter for KeyHandler, and KeyHandlerInit

    DebouncedKey    DB  ?     ;The shared KEYCODE for KeyHandler, KeyCheck, and KeyHandlerInit
	
DATA    ENDS

        END 