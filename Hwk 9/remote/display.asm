NAME        Display

$INCLUDE(display.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);
$INCLUDE(vectors.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW4 Display Functions                      ;
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
;   Display   -     This is pass a string to be displayed. The string is at
;                   ES:SI and is null terminated. 
;
;   DisplayNum  -   This function is passed a 16-bit signed value to be outputted
;                   to the display. The number is in AX, with at most 5 digits
;
;   DisplayHex   -  This function is passed a 16-bit HEX value to be outputted
;                   to the display. The number is in AX with at most 4 digits; 
;
;   DisplayHandlerInit - This installs the DisplayHandler into vector table
;
;   DisplayHandler - This is the interrupt function that multiplexes the display
;                    by grabbing the next char value to be outputted.
;
;   DisplayBufferFill - This function clears the display array with all ASCII_NULL
;
;                                   Data Segment
;
;   DisplayArray(DISPLAYSTRUC)  - Where DisplayArray's buffer is. This is only for
;                                 storing ASCII, which is then translated into seg.
;                                 (Easier to debug DisplayHex and DisplayNum)
;
;   DHandlerVarLow(DISPLAYSTRUC)  - Where DisplayHandler's high byte buffer is stored;
;
;   DHandlerVarHigh(DISPLAYSTRUC)  - Where DisplayHandler's low byte buffer is stored;
;
;   digitchar (DW)                  - The shared Handler pointer to next digitchar
;
;                                 What's was last edit?
;
;       			11-02-2013 Pseudo code - Anjian Wu
;       			11-08-2013 Initial Version - Anjian Wu
;       			11-08-2013 Working 7 seg version - Anjian Wu
;       			11-09-2013 Working 14 seg version - Anjian Wu
;                   12-10-2013 Renamed Digit to DigitChar - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			Display
;
;Description:      	This procedure will take the address of the string at ES:SI, and
;                   place that string into the Dhandler buffers. This display buffers
;                   is shared with DisplayHandler.
;
;                   DHandlerVarHigh.buffer  - Stores upper byte of 14-seg code
;                   DHandlerVarLow.buffer   - Stores lower byte of 14-seg code 
;                   (Both buffer elements share same index)
;
;                   This function does this by first clearing BOTH buffers using the
;                   DisplayBufferFill to fill up buffers with SEGMENT_NULL. This helps
;                   avoid displaying left over chars from previous strings.
;
;                   The function will then loop grabbing the ASCII_CHAR from ES:SI, and
;                   mapping the character to it's 14-segment code. The code is then stored
;                   into both the high and low buffer.
;
;                   If the loop hits a ASCII_NULL before the full Display_SIZE is reached,
;                   the loop will terminate early. This is ok since we already cleared the
;                   buffers beforehand.
;                   
;                   
;Operation:			*   Call DisplayBufferFill(low byte buffer)
;                   *   Call DisplayBufferFill(high byte buffer)
;                   *   Clear Counter
;                   *   Loop grabbing each char at ES:SI until counter hits Display_size
;                       or ASCII_NULL was hit.
;                       * Check counter
;                       * Grab next char, is this ASCII_NULL? Yes -> terminate, no->keep going
;                       * Grab segtable offset, double char index to get absolute WORD ptr
;                       * Grab the WORD and split storing high and low byte into buffers
;                       * update counter and char (source) byte ptr.
;
;                   *   DONE
;
;Arguments:        	SI   -> starting point of string ptr
;                   ES   -> Can be either Data segment or Code segment
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the Dhander buffers.
;
;Shared Variables: 	The buffer arrays is shared with DisplayHandler and DisplayBuffFill
;
;Local Variables:	AX - Used as arg, store char, 
;                   SI - Used to store ptr arg
;                   BX - Used as ptr to access code segment
;                   CX - Used as counter
;                   
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX, SI, BX, CX
;
;Stack Depth:		4 words
;
;Known Bugs:		None.
;
;Data Structures:	DHandlerVarLow, DHandlerVarHigh (8 byte arrays)
;
;Error Handling:   	None.  
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars in the same array while DisplayHandler interrupt 
;                   is running which also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast.
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;-------------------------------------------------------------------------------

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

;-------------------------------------------------------------------------------

        EXTRN   Dec2String:NEAR          ; Used to convert passed AX into dec ASCII
        EXTRN   Hex2String:NEAR          ; Used to convert passed AX into hex ASCII
        EXTRN   ASCIISegTable:NEAR          ; Used to convert passed AX into hex ASCII


Display		    PROC    NEAR
				PUBLIC  Display
				
	
	PUSH    CX;                     ; Store all Used Regs
	PUSH    AX;
	PUSH    BX;

DisplayStrInit:

    PUSH    SI;						; Save the original string pointer arg
DisplayClearLowbyte:

    LEA     SI, DHandlerVarLow.buffer   ; Grab address of lower byte seg buff
    MOV     AL, SEGMENT_NULL            ; Want to fill with SEGMENT_NULLs
    CALL    DisplayBufferFill           ; Fill display array with SEGMENT_NULLs


DisplayClearHighbyte:	

    LEA     SI, DHandlerVarHigh.buffer  ; Grab address of high byte seg buff
    MOV     AL, SEGMENT_NULL            ; Want to fill with SEGMENT_NULLs
    CALL    DisplayBufferFill           ; Fill display array with SEGMENT_NULLs
	
DisplayBufferClearDone:  
  
	POP     SI				; Get that original string pointer back from stack
    MOV     CX, 0           ; Clear the counter
                           

DisplayStrLoop: ; Counter goes from 0 to DisplaySize - 1 or ends early if ASCII_NULL found

    CMP     CX, Display_SIZE    ; Is the counter maxed out?
    JGE     DisplayStrDone      ; Yes, exit loop
                                ; No, continue loop
	XOR		AX, AX			    ; Clear AX
	
    MOV     AL, ES:[SI]         ; Grab char at address arg, put in AL
    CMP     AL, ASCII_NULL      ; Is it ASCII_NULL? Cuz if so, end loop
    JE      DisplayStrDone      ; Yes, end loop
    ;JNE    DisplayLoopSegtable ; No, continue
    
DisplayLoopSegtable:
    MOV	    BX, OFFSET(ASCIISegTable);point into the table of seg table
	SHL		AX, SegPTRAdjust	    ;Get absolute value from table by mul 2^(SegPTRAdjust)
	ADD		BX, AX			        ; Get absolute appropriate seg table addr
    
    MOV		AX,	CS:[BX]		        ;Now seg val is in AX
 
    MOV     BX, CX                  ; Move counter (which also acts as index) to
                                    ; BX as data seg ptr.
                                     
                                     
    MOV     DHandlerVarLow.buffer[BX]   , AL   ; Split AX into low and high byte
    MOV     DHandlerVarHigh.buffer[BX]  , AH  
        
    INC     CX                          ; Update Counter
    INC     SI                          ; Update char pointer (Str source)
    
    JMP     DisplayStrLoop  ; 
    
DisplayStrDone:

	POP    BX;
	POP    AX;
	POP    CX               ;    Restore all used regs          
	
    RET                     
    
Display  ENDP 



;Procedure:			DisplayNum
;
;
;Description:      	This procedure will take the value at AX, and convert that decimal
;                   value into a string placed inside DisplayArray (a buffer) and then
;                   finally call Display to convert the stored string of ASCII's.
;
;                   This buffer is not directly accessed by DisplayHandler, but is
;                   used to convert to seg pattern code if passed to Display.
;
;                   First it will clear the display buffer with ASCII_NULLs with DisplayBufferFill,
;                   call Dec2String, which already places the a passed value into 
;                   the passed address accordingly into the display array. 
;                   
;                   The purpose of the separate Displayarray buffer is to help debugging
;                   reasons, such that the user doesn't have to decode the segment buff.
;
;                   
;                   
;Operation:			*   Load address of DisplayArray buffer 
;                   *   Call DisplayBufferFill with ASCII-NULLs
;                   *   Pass address and value to Dec2String
;                   *   Prepare to pass ES:SI, by making ES = DS
;                   *   Call Display
;
;Arguments:        	AX - Num to be displayed
;
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the display array and in DHandler buffers
;
;Shared Variables: 	DisplayArray buffer is  shared with Dec2String and Display
;
;Local Variables:	AX - Used as arg, store char, 
;                   SI - Used to store ptr arg
;                   ES - Used as ptr to pass data segmentp
;                   DisplayArray.buffer - stores new ASCII string to be passed to Display
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX, ES, SI, DS
;
;Stack Depth:		4 Words;
;
;Known Bugs:		None.
;
;Data Structures:	DisplayArray.buffer (8 byte buffer)
;
;Error Handling:   	If passed decimal length is too large, then DisplayArray is not
;                   places and errorflag is raised. NOTE THIS FEATURE IS INSIDE
;                   DEC2STRING, thus the flags raised should also be passed back.
;                   
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars (after calling Display) in the same array 
;                   while DisplayHandler interrupt 
;                   is running which also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast.
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;-------------------------------------------------------------------------------


DisplayNum		PROC    NEAR
				PUBLIC  DisplayNum
                
                
	PUSH    AX;                     Save all Used regs
    PUSH    SI
    PUSH    ES
    
DisplayNumStrInit:
    PUSH    AX                      ; DisplayBufferFill also uses AX as arg, so save that
    
    LEA     SI, DisplayArray.buffer ; Grab address of display array buffer
    MOV     AL, ASCII_NULL          ; Fill with ASCII_NULL
    CALL    DisplayBufferFill       ; 
    
    POP     AX                      ; Restore the arg  
DisplayNumPlace:

    CALL    Dec2String              ; Dec2String chars at DS:SI
    
    MOV     AX, DS
    MOV     ES, AX                  ; Prepare to access DS for display
        
    CALL    Display                 ; Translate ES:SI aka. DS:SI into Seg code
    
DisplayNumDONE:

	POP    ES
    POP    SI
    POP    AX;                      Restore all used Regs

    RET                             
    
DisplayNum  ENDP      

;Procedure:			DisplayHex
;
;
;Description:      	This procedure will take the value at AX, and convert that hex
;                   value into a string placed inside DisplayArray (a buffer) and then
;                   finally call Display to convert the stored string of ASCII's.
;
;                   This buffer is not directly accessed by DisplayHandler, but is
;                   used to convert to seg pattern code if passed to Display.
;
;                   First it will clear the display buffer with ASCII_NULLs with DisplayBufferFill,
;                   call Hex2String, which already places the a passed value into 
;                   the passed address accordingly into the display array. 
;                   
;                   The purpose of the separate Displayarray buffer is for debugging
;                   reasons, such that the user doesn't have to decode the segment buff.
;
;                   
;                   
;Operation:			*   Load address of DisplayArray buffer 
;                   *   Call DisplayBufferFill with ASCII-NULLs
;                   *   Pass address and value to Hex2String
;                   *   Prepare to pass ES:SI, by making ES = DS
;                   *   Call Display
;
;Arguments:        	AX - Hex to be displayed
;
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the display array and in DHandler buffers
;
;Shared Variables: 	DisplayArray buffer is  shared with Dec2String and Display
;
;Local Variables:	AX - Used as arg, store char, 
;                   SI - Used to store ptr arg
;                   ES - Used as ptr to pass data segmentp
;                   DisplayArray.buffer - stores new ASCII string to be passed to Display
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	AX, ES, SI, DS
;
;Stack Depth:		4 Words;
;
;Known Bugs:		None.
;
;Data Structures:	DisplayArray.buffer (8 byte buffer)
;
;Error Handling:   	If passed decimal length is too large, then DisplayArray is not
;                   places and errorflag is raised. NOTE THIS FEATURE IS INSIDE
;                   DEC2STRING, thus the flags raised should also be passed back.
;                   
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars (after calling Display) in the same array 
;                   while DisplayHandler interrupt 
;                   is running which also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast.
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;-------------------------------------------------------------------------------


DisplayHex		PROC    NEAR
				PUBLIC  DisplayHex
				
	PUSH    AX;                     Save all Used regs
    PUSH    SI
    PUSH    ES
    
DisplayHexInit:

    PUSH    AX                       ; DisplayBufferFill also uses AX as arg, so save that
    
    LEA     SI, DisplayArray.buffer  ; Grab address of display array
    MOV     AL, ASCII_NULL           ;
    CALL    DisplayBufferFill        ; Fill display array with ASCII_NULLs
    
    POP     AX                       ;  Restore the ARG
    
DisplayHexPlace:

    CALL    Hex2String              ; Hex2String chars at DS:SI, with AX
    
    MOV     AX, DS
    MOV     ES, AX                  ; Prepare to access DS for display
        
    CALL    Display                 ; Translate ES:SI aka. DS:SI
DisplayhexDONE:

	POP    ES
    POP    SI
    POP    AX;                      Restore all used Regs

    RET       
         
DisplayHex  ENDP   

; DisplayHandlerInit
;
; Description:       Does all initializations for DispalyHandler.
;
;                    Installs the displayhandler for the timer0 interrupt at 
;                    interrupt table index Tmr0Vec. ALso clears the digitchar
;                    used to index the segment digitchar to be displayed in
;                    in DisplayHandler.
;
; Operation:         *	First clear the digitchar to 0.
;					 *	Then calls DisplayBuffFill, passing SEG_NULLs to be filled
;					 	for DHandlerVarHigh and DHandlerVarLow buffers. That way
;					 	the display will not output random stuff initially.
;                    *	Then writes the address of the displayhandler to the
;                    *	imer0 location in the interrupt vector table. Notice
;                    	need to multiple by 4 since table stores a CS and IP.
;                     
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   AX - Used to temporarily store vector table offset for ES
; 
; Shared Variables:  digitchar (WORD) - Stores segment ptr for DisplayHandler
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
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;       			Added buffer clearing   - 11-10-2013 - Anjian Wu
;-------------------------------------------------------------------------------

DisplayHandlerInit  PROC    NEAR
                    PUBLIC  DisplayHandlerInit
                    
                    


        MOV     digitchar, 0    ; Clear the digitchar counters
		
DisplayInitClearLowbyte:	; Also important to clear buffer in the beginning

		LEA     SI, DHandlerVarLow.buffer   ; Grab address of lower byte seg buff
		MOV     AL, SEGMENT_NULL            ; Want to fill with SEGMENT_NULLs
		CALL    DisplayBufferFill           ; Fill display array with SEGMENT_NULLs
        CALL    Scroll_Reset                ; Make sure scrolling starts with
                                            ; chars in original position before
                                            ; moving
        MOV     ScrollFlag, FALSE           ; Turn scrolling OFF

DisplayInitClearHighbyte:	

		LEA     SI, DHandlerVarHigh.buffer  ; Grab address of high byte seg buff
		MOV     AL, SEGMENT_NULL            ; Want to fill with SEGMENT_NULLs
		CALL    DisplayBufferFill           ; Fill display array with SEGMENT_NULLs
        
DispalyBrightnessInit:
        MOV     brightnessCTR, 0                ; Reset counter
        MOV     brightnessSetting, MAX_BRIGHT   ; Initial State with highest brightness

DisplayInitVectorSetting:

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr2Vec), OFFSET(DisplayHandler)
        MOV     ES: WORD PTR (4 * Tmr2Vec + 2), SEG(DisplayHandler)


        RET                     ;all done, return


DisplayHandlerInit  ENDP


				
ScrollControl       PROC    NEAR
                    PUBLIC  ScrollControl

    CMP     ScrollFlag, TRUE   ; Is the flag already true?
    JE      ScrollOFF          ; If so, switch it to false
    ;JNE    ScrollON           ;
ScrollON:   
    MOV     ScrollFlag, TRUE   ; Else it is NOT true (ToggleHandler will
                               ; STOP immediately)
    
    JMP     ScrollDone         ; In which we switch TO true
    
ScrollOFF:
    MOV     ScrollFlag, FALSE  ; Turn serial debug off
    ;JMP    ScrollDone         ;
ScrollDone:

    RET                             ;                    

ScrollControl   ENDP

;Procedure:			DisplayHandler
;
;
;Description:      	Does all necessary functions to display to 14-segment.
;                   This procedure will grab the next counter index. It will then use
;                   this to index for the next char to be output to the display. 
;
;                   If the counter is beyond the number of characters available to the display
;                   the counter will reset back to 0. Thus the display is effectively
;                   looping over all the chars as each interrupt comes.
;
;                   Since the counter value needs to be saved, I use a local variable 
;                   allocated in the data memory. Also since 14-seg requires two byte writes,
;                   I have two Dhandler buffers for the HIGH and LOW byte array storage.
;
;                   
;                   
;Operation:			*   Save all regs
;                   *   Grab stored segment digitchar to be outputted, see if it is maxed out
;                       * If so, then reset to 0 and keep going
;                       * If not, then use it and keep going
;                   *   Grab HIGH byte to AL and LOW byte to AH (This order matters)
;                   *   Grab the I/O address for UPPER byte write for 14-seg
;                   *   Use the digitchar as offset for I/O write location (ADD)
;                   *   OUT the AL (HIGH BYTE), this MUST be first to be outputted.
;                   *   Since LOW byte is in AH, just swap AH with AL.
;                   *   Again OUT AL (LOW BYTE), and update digitchar++
;                   *   Send appropriate EOI
;
;                   
;Arguments:         digitchar - stores counter 
;
;Return Values:    	digitchar - updated counter for next interrupt
;
;Result:            New ASCII char in the display. Updated counter value
;
;Shared Variables: 	digitchar - shared with DispalyHandlerInit (just accessed once to reset)
;                   DHandlerVarLow  (8 byte arrays) - Shared with Display
;                   DHandlerVarHigh (8 byte arrays) - Shared with Display
;
;Local Variables:	AX - stores all seg pattern codes. Also stores EOI value
;                   BX - stores counter and acts as seg ptr
;                   DX - stores seg pat right before output. stores I/O offsets
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	New ASCII char in the display at next offset.
;
;Registers Used:	AX, BX, DX
;
;Stack Depth:		3 Words.
;
;Known Bugs:		None.
;
;Data Structures:	DHandlerVarLow, DHandlerVarHigh (8 byte arrays)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		Outputs new chars in the same array Display might bechanging
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;                   12-13-2013  -> Added Brightness Setting
;-------------------------------------------------------------------------------


DisplayHandler		    PROC    NEAR
				        PUBLIC  DisplayHandler

        PUSHA
        
DisplayScrollControl:
        CMP     ScrollFlag, TRUE         ;
        JNE     DisplayBrightnessControl ; 
        
        INC     scrollcounter            ;
        CMP     scrollcounter, SCROLLRATE;
        JL      DisplayBrightnessControl ;
        ;JGE    DisplayScrollUpdate      ;
DisplayScrollUpdate:
        MOV     scrollcounter, 0         ;
        INC     scrollindex              ;
        CMP     scrollindex, Display_SIZE;
        JL      DisplayBrightnessControl ;
        MOV     scrollindex, 0           ;
        
DisplayBrightnessControl:
        MOV     AX, brightnessCTR        ; Grab brightness counter
        CMP     AX, brightnessSetting    ; Has the display been dimmed long enough?
        JL      DisplayClearFirstChar    ; No, need to wait longer
        ;JGE    DisplayHInit             ; Yes, so output the chars
        
;\/\/\/\/\/\/\/\/\/\/\/Regular DisplayHandler From Before (below)\/\/\/\/\/\/\/\/\/\/\/
DisplayHInit:

        MOV     BX, digitchar               ;get offset for current digitchar
        CMP     BX, Display_SIZE            ;Is the offset too large?
        JL      DisplayHUpdate              ;no it isn't keep going
        ;JGE     DisplayDigitReset          ;yes it is, reset it

DisplayDigitReset:

        MOV    BX, 0                        ; Clear the digitchar index
        MOV   brightnessCTR, 0              ; Clear brightness counter (in effect
                                            ; the display muxes all chars and takes

DisplayHUpdate:                                 ; update the display

        MOV     AX, BX                          ; Copy the digitchar index
        ADD     AX, scrollindex                 ; Calc the scroll offset
        MOV     CX, Display_SIZE                ; We need to WRAP around after Display_SIZE
        XOR     DX, DX
        DIV     CX                              ; MOD(digitindex + scrollindex, Display_SIZE)
                                                ; -> MOD is in DX
Check:                                               
        MOV     AL, DHandlerVarHigh.buffer[BX]  ; Grab HIGH byte seg pat from buffer    
        MOV     AH, DHandlerVarLow.buffer[BX]   ; Grab LOW byte seg pat from buffer    

        PUSH    DX
        ADD     DX, LEDDisplay2                 ; ADD digitchar offset for display
        OUT     DX, AL                          ; output segment directly
        
        POP     DX
        ADD     DX, LEDDisplay                          ; ADD digitchar offset for display
        
        XCHG    AL, AH						; Only AL is allowed for OUT-ing bytes 
                                            ; (also a nifty operation)
                                            
        OUT     DX, AL                      ;output segment directly
		


DisplayDigitUpdate:                         ;Update digitchar

        INC     BX                          ;update segment digitchar
        
        MOV     digitchar, BX                   ;save it for next time
        
        JMP     EndDisplayHandler           ;
;\/\/\/\/\/\/\/\/\/\/\/Regular DisplayHandler From Before (above)\/\/\/\/\/\/\/\/\/\/\/

DisplayClearFirstChar:                  ;done taking care displaying

        INC     brightnessCTR           ;increment the brightness 
        XOR     AL, AL                  ;
        MOV     DX, LEDDisplay2         ; get the display address for UPPER seg pat   
        OUT     DX, AL                  ; Clear first char

        MOV     DX, LEDDisplay          ;get the display address for LOW seg pat                                                
        OUT     DX, AL                  ; Clear first char

EndDisplayHandler:

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POPA

        IRET                            ;and return (Event Handlers end with IRET not RET)


DisplayHandler       ENDP

;Procedure:			Inc_Bright
;
;Description:      	Determines which Serial error occurred at the chip,
;                   and informs the user to the issue. Note this is
;                   serial errors from Remote Serial Chip.
;
;Operation:         * Table offset = AX = Display_SIZE*AL + OFFSET(SerErrTable)
;                   * Just store that into Error_Buff_PTR.
;                
;Arguments:        	AL  -> Event Val
;Return Values:    	none.
;Shared Variables: 	Error_Buff_PTR (WRITE).
;Local Variables:	AX  -> abs pointer address.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		Only displays error to user, does not fix the error.
;Author:			Anjian Wu
;Revision History:
;                   Edits by Anjian Wu:
;       			12-06-2013 -> Initial Version
;                   12-13-2013 -> Working and documentation
;------------------------------------------------------------------------------
Inc_Bright      PROC    NEAR
                PUBLIC  Inc_Bright

        MOV     AX, brightnessSetting   ;  
        SUB     AX, DELTA_BRIGHT        ;
        CMP     AX, MAX_BRIGHT          ;
        JLE     Inc_BrightMax           ;
        ;JL     Inc_BrightGoodToGo      ;
        
Inc_BrightGoodToGo:      
        MOV     brightnessSetting, AX   ;
        JMP     Inc_BrightDone          ;
Inc_BrightMax:
        MOV     brightnessSetting, MAX_BRIGHT;
        
Inc_BrightDone:

        RET
    
Inc_Bright    ENDP   

;Procedure:			Dec_Bright
;
;Description:      	Determines which Serial error occurred at the chip,
;                   and informs the user to the issue. Note this is
;                   serial errors from Remote Serial Chip.
;
;Operation:         * Table offset = AX = Display_SIZE*AL + OFFSET(SerErrTable)
;                   * Just store that into Error_Buff_PTR.
;                
;Arguments:        	AL  -> Event Val
;Return Values:    	none.
;Shared Variables: 	Error_Buff_PTR (WRITE).
;Local Variables:	AX  -> abs pointer address.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		Only displays error to user, does not fix the error.
;Author:			Anjian Wu
;Revision History:
;                   Edits by Anjian Wu:
;       			12-06-2013 -> Initial Version
;                   12-13-2013 -> Working and documentation
;------------------------------------------------------------------------------
Dec_Bright      PROC    NEAR
                PUBLIC  Dec_Bright

        MOV     AX, brightnessSetting   ;  
        ADD     AX, DELTA_BRIGHT        ;
        CMP     AX, MIN_BRIGHT          ;
        JGE     Dec_BrightMin           ;
        ;JL     	Dec_BrightGoodToGo  ;
        
Dec_BrightGoodToGo:      
        MOV     brightnessSetting, AX   ;
        JMP     Dec_BrightDone          ;
Dec_BrightMin:
        MOV     brightnessSetting, MIN_BRIGHT;
        
Dec_BrightDone:

        RET
    
Dec_Bright    ENDP   
;Procedure:			DisplayBufferFill
;
;
;Description:      	This procedure will fill the any Display_SIZE byte buffer 
;                   with the PASSED arg value (AL).
;
;                   It does this by simply looping through 0 to Display_SIZE - 1
;                   and writing AL to each char in DS:SI
;
;                   This function is used often to empty a buffer.
;                   
;Operation:			*   Reset counter
;                   *   Loop Display_SIZE times and fill each char with AL.
;                   *   Update counter and Data seg ptr (SI)
;                   *   DONE
;
;                   
;Arguments:         AL -    The char to be filled with
;                   DS:SI - Location of buffer to be filled
;
;Return Values:    	None.
;
;Result:            ASCII_NULL empty DisplayArray
;
;Shared Variables: 	This function may fill buffers used by DisplayNum, DusplayHex,
;                   and Display. (DisplayArray, DHandler1, Dhandler2 Display_SIZE byte buffers)
;
;Local Variables:	SI - Pointer to DS:SI's char
;                   CX - Counter
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	None.
;
;Registers Used:	CX, SI, AL
;
;Stack Depth:		4 Words.
;
;Known Bugs:		None.
;
;Data Structures:	Display_SIZE sized buffers
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		Outputs new chars in the same array that DisplayHandler touches.
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;       			Working 7 seg version   - 11-08-2013 - Anjian Wu
;       			Working 14 seg version  - 11-09-2013 - Anjian Wu
;-------------------------------------------------------------------------------

DisplayBufferFill		PROC    NEAR
				        PUBLIC  DisplayBufferFill
				        
    PUSH    CX;             Save all Used Regs
    PUSH    BX;             Important since many functions use this
    PUSH    AX;
    PUSH    SI;
				
DisplayClrInit:


    MOV     CX, 0           ; Clear the counter
                            ; Counter goes from 0 to DisplaySize - 1

DisplayClrLoop:

    CMP     CX, Display_SIZE ; Is the counter maxed out?
    JGE     DisplayClrDone  ; Yes, exit loop
                            ; No, continue loop
                            
    MOV     [SI] , AL       ; Fill that byte with ARG
        
    INC     CX              ; Update Counter
    INC     SI              ; Update Data seg ptr
    
    JMP     DisplayClrLoop  ; 
    
DisplayClrDone:

    POP    SI;
    POP    AX;
    POP    BX;
    POP    CX;              Restore all used regs

    RET                     
    
DisplayBufferFill  ENDP   
        
;Procedure:			Scroll_Reset
;
;Description:      	Determines which Serial error occurred at the chip,
;                   and informs the user to the issue. Note this is
;                   serial errors from Remote Serial Chip.
;
;Operation:         * Table offset = AX = Display_SIZE*AL + OFFSET(SerErrTable)
;                   * Just store that into Error_Buff_PTR.
;                
;Arguments:        	AL  -> Event Val
;Return Values:    	none.
;Shared Variables: 	Error_Buff_PTR (WRITE).
;Local Variables:	AX  -> abs pointer address.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None.
;Algorithms:       	None.
;Limitations:  		Only displays error to user, does not fix the error.
;Author:			Anjian Wu
;Revision History:
;                   Edits by Anjian Wu:
;       			12-06-2013 -> Initial Version
;                   12-13-2013 -> Working and documentation
;------------------------------------------------------------------------------
Scroll_Reset    PROC    NEAR
                PUBLIC  Scroll_Reset

        MOV     scrollindex, 0      ;
        MOV     scrollcounter, 0    ;
        
        RET
    
Scroll_Reset    ENDP

CODE    ENDS 
    
DATA    SEGMENT PUBLIC  'DATA'


    DisplayArray       DISPLAYSTRUC <>      ;Where DisplayArray's buffer is. Use this only for
                                            ;storing ASCII so that debugging is easier.

    DHandlerVarLow       DISPLAYSTRUC <>      ;Where DisplayHandler's high byte buffer is stored

    DHandlerVarHigh       DISPLAYSTRUC <>      ;Where DisplayHandler's low byte buffer is stored

    digitchar               DW      ?           ;The shared Handler pointer to next digitchar
    
    brightnessSetting       DW      ?       ;
    
    brightnessCTR           DW      ?       ;
    
    scrollindex         DW      ?           ; The current scrolling index 
    
    scrollcounter       DW      ?           ; Counter to control scrolling speed
    
    ScrollFlag          DW      ?
	
DATA    ENDS

        END 