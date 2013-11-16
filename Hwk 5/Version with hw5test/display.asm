NAME        Display

$INCLUDE(display.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW4 Display Functions                        ;
;                                 Code Outline                            	 ;
;                                 Anjian Wu                                  ;
;                                                                            ;
;                                 TA: Pipe-Mazo                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
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
;   DisplayClear - This function clears the display array with all ASCII_NULL
;
;                                 What's was last edit?
;
;       			Pseudo code - 11-02-2013 - Anjian Wu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			Display
;
;Description:      	This procedure will take the address of the string at ES:SI, and
;                   place that string into the display array, which is shared with the
;                   outputchar interrupt routine. 
;                   This function does this by first clearing the display array
;                   and then looping
;                   starting at SI until it either hits ASCII_NULL, or detects leng
;                   of string greater than 8 characters of which only the first 8
;                   char in that string will be put into display array.  
;                   The reason the display array is CLEARED first using the 
;                   function 'DisplayClear' is so that if the string is less
;                   than 8 char, the function wouldn't need to fill in extra ACII_NULLs.
;                   Note that char is left justified.
;                   
;                   
;Operation:			*   Call DisplayClear
;                   *   Loop (conditions for loop is either counter is less than 8
;                       or ASCII_NULL has already been seen (using CMP).
;                       * In the loop, keep grabbing the ASCII char and placing to 
;                         the display array.
;                   *   DONE
;
;Arguments:        	SI   -> starting point of string
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the display array.
;
;Shared Variables: 	The display array created is shared with DisplayHandler
;
;Local Variables:	fullflag = flag for early termination of char loop
;                   counter = main counter for while loop
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
;Data Structures:	DisplayArray (8 bytes)
;
;Error Handling:   	If passed string length is too large, then only output
;                   first 8 chars.
;                   
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars in the same array while DisplayHandler interrupt 
;                   is running and also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast :).
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu

;-------------------------------------------------------------------------------
CGROUP  GROUP   CODE

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DATA

;-------------------------------------------------------------------------------

        EXTRN   Dec2String:NEAR          ; 
        EXTRN   Hex2String:NEAR          ; 


Display		    PROC    NEAR
				PUBLIC  Display
				
	
	PUSH    CX;
	PUSH    AX;
	PUSH    BX;

DisplayStrInit:

    PUSH    SI;						; Save the original string pointer
DisplayClearLowbyte:

    LEA     SI, DHandlerVar1.buffer  ; Grab address of display array
    MOV     AL, SEGMENT_NULL ;
    CALL    DisplayBufferFill; Fill display array with ASCII_NULLs


DisplayClearHighbyte:	

    LEA     SI, DHandlerVar2.buffer  ; Grab address of display array
    MOV     AL, SEGMENT_NULL ;
    CALL    DisplayBufferFill; Fill display array with ASCII_NULLs
	
DisplayBufferClearDone:  
  
	POP     SI				; Get that original string pointer back from stack
    MOV     CX, 0           ; Clear the counter
                            ; Counter goes from 0 to DisplaySize - 1

DisplayStrLoop:

    CMP     CX, Display_SIZE ; Is the counter maxed out?
    JGE     DisplayStrDone  ; Yes, exit loop
                            ; No, continue loop
	XOR		AX, AX			; Clear AX
	
    MOV     AL, ES:[SI]     ; Grab char at address arg, put in AL for XLAT
    CMP     AL, ASCII_NULL  ; Is it ASCII_NULL? Cuz if so, end loop
    JE      DisplayStrDone  ;
    
    
DisplayLoopXLAT:
    MOV	    BX, OFFSET(ASCIISegTable);point into the table of seg table
	SHL		AX, 1			; Get absolute value from table
	ADD		BX, AX			;
    MOV		AX,	CS:[BX]		;Now seg val is in AX
 
    MOV     BX, CX                          ;
    MOV     DHandlerVar1.buffer[BX] , AL   ; Stored the return value
    MOV     DHandlerVar2.buffer[BX] , AH   ; Stored the return value
        
    INC     CX                          ; Update Counter
    INC     SI                          ; Update char pointer (Str source)
    
    JMP     DisplayStrLoop  ; 
    
DisplayStrDone:

	POP    BX;
	POP    AX;
	POP    CX;
	
    RET                     ;
    
Display  ENDP 



;Procedure:			DisplayNum
;
;
;Description:      	This procedure will take the value at AX, and convert that decimal
;                   value into a string placed inside DisplayArray. It does this byte simply
;                   calling Dec2String, which already places the a passed value into 
;                   the passed address accordingly into the display array. Thus the DisplayArray
;                   is shared with Dec2String. Also before Dec2String is called, the display
;                   is also cleared with DisplayClear, in that way Dec2String will just
;                   stored the fixed 5 chars into the array w/o worrying about clearing
;                   any remaining chars into ASCII_NULLS.
;
;
;                   
;                   
;Operation:			*   Call DisplayClear
;                   *   Load address of DisplayArray
;                   *   Pass address and value to Dec2String
;                   *   DONE
;
;Arguments:        	AX   ->  Value of decimal that is passed
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the display array.
;
;Shared Variables: 	The display array created is shared with DisplayHandler. DisplayArray
;                   is also shared with Dec2String
;
;Local Variables:	a = address of DisplayArray
;                   counter = main counter for while loop
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
;Data Structures:	DisplayArray (8 bytes)
;
;Error Handling:   	If passed decimal length is too large, then DisplayArray is not
;                   places and errorflag is raised. NOTE THIS FEATURE IS INSIDE
;                   DEC2STRING, thus the flags raised should also be passed back.
;                   
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars in the same array while DisplayHandler interrupt 
;                   is running and also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast :).
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu


DisplayNum		PROC    NEAR
				PUBLIC  DisplayNum
				
DisplayNumStrInit:
    PUSH    AX              ;
    
    LEA     SI, DisplayArray.array  ; Grab address of display array
    MOV     AL, ASCII_NULL  ;
    CALL    DisplayBufferFill; Fill display array with ASCII_NULLs
    
    POP     AX              ;
DisplayNumPlace:

    LEA     SI, DisplayArray.array  ; Grab address of display array
    CALL    Dec2String              ; Dec2String chars at DS:SI
    
    
    MOV     AX, DS
    MOV     ES, AX                  ; Prepare to access DS for display
    
    LEA     SI, DisplayArray.array  ; Prepare segment pointer
    
    CALL    Display                 ; Translate ES:SI aka. DS:SI into Seg code


    RET                             ;
    
DisplayNum  ENDP      

;Procedure:			DisplayHex
;
;
;Description:      	This procedure will take the value at AX, and convert that hexadecimal
;                   value into a string placed inside DisplayArray. It does this byte simply
;                   calling Hex2String, which already places the a passed value into 
;                   the passed address accordingly into the display array. Thus the DisplayArray
;                   is shared with Hex2String. Also before Dec2String is called, the display
;                   is also cleared with DisplayClear, in that way Dec2String will just
;                   stored the fixed 5 chars into the array w/o worrying about clearing
;                   any remaining chars into ASCII_NULLS.
;
;
;                   
;                   
;Operation:			*   Call DisplayClear
;                   *   Load address of DisplayArray
;                   *   Pass address and value to Hex2String
;                   *   DONE
;
;Arguments:        	AX   ->  Value of hex that is passed
;
;Return Values:    	None.
;
;Result:            New ASCII chars in the display array.
;
;Shared Variables: 	The display array created is shared with DisplayHandler. DisplayArray
;                   is also shared with Dec2String
;
;Local Variables:	a = address of DisplayArray
;                   counter = main counter for while loop
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
;Data Structures:	DisplayArray (8 bytes)
;
;Error Handling:   	None since AX is fixed to 4 hex chars.
;
;Algorithms:       	None.
;
;Limitations:  		Stores new chars in the same array while DisplayHandler interrupt 
;                   is running and also grabbing the chars out of same array.
;                   However it should not really affect user experience since
;                   interrupts will be very fast :).
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu


DisplayHex		PROC    NEAR
				PUBLIC  DisplayHex
				
DisplayHexInit:

    PUSH    AX              ;
    
    LEA     SI, DisplayArray.array  ; Grab address of display array
    MOV     AL, ASCII_NULL  ;
    CALL    DisplayBufferFill; Fill display array with ASCII_NULLs
    
    POP     AX              ;
    
DisplayHexPlace:

    LEA     SI, DisplayArray.array  ; Grab address of display array
    CALL    Hex2String              ; Dec2String chars at DS:SI, with AX
    
    MOV     AX, DS
    MOV     ES, AX                  ; Prepare to access DS for display
    
    LEA     SI, DisplayArray.array  ; Prepare segment pointer
    
    CALL    Display                 ; Translate ES:SI aka. DS:SI


    RET       
         
DisplayHex  ENDP   

; DisplayHandlerInit
;
; Description:       Install the displayhandler for the timer0 interrupt.
;
; Operation:         Simply writes the address of the displayhandler to the
;                    timer0 location in the interrupt vector table 
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   Timer0Vector = calculated absolute address of timer0 vector
; Shared Variables:  None.
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
; Registers Changed: flags, ES for now
;
; Stack Depth:       0 words
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-27-2013
;                   Debugged,Documented, and working - 11/01/2013 - Anjian Wu
;-------------------------------------------------------------------------------

DisplayHandlerInit  PROC    NEAR
				PUBLIC  DisplayHandlerInit


        MOV     Digit, 0    ; Clear the Digit counters


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(DisplayHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(DisplayHandler)


        RET                     ;all done, return


DisplayHandlerInit  ENDP
				
  


;Procedure:			DisplayHandler
;
;
;Description:      	This procedure will grab the next counter index. It will then use
;                   this to index for the next char to be output to the display. If the
;                   counter is beyond the number of characters available to the display
;                   the counter will reset back to 0. Thus the display is effectively
;                   looping over all the chars as many interrupts occur over time.
;
;                   Since the counter value needs to be saved, I use a local variable 
;                   allocated in the data memory.
;
;                   The proper values to actually output it mapped from a ASCII_SEGTABLE.
;
;
;                   
;                   
;Operation:			*   Save all regs
;                   *   Check to see if counter is too large
;                   *   Grab next char value based on counter offset
;                   *   OUTPUT that char to display
;                   *   increment the counter
;                   *   Save that counter value for next time
;                   *   DONE
;
;                   
;Arguments:        	DHandlerVar.counter - stores counter, NOT ACCESSED ANYWHERE ELSE
;
;Return Values:    	DHandlerVar.counter - stores next counter, NOT ACCESSED ANYWHERE ELSE.
;
;Result:            New ASCII char in the display. Updated counter value
;
;Shared Variables: 	The display array created is shared with DisplayHandler. 
;
;Local Variables:	CharOut = ASCII char
;                   counter = main counter for char indexing
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;
;Output:           	New ASCII char in the display at next offset.
;
;Registers Used:	None.
;
;Stack Depth:		None.
;
;Known Bugs:		None.
;
;Data Structures:	DisplayArray (8 bytes), DHandlerVar.counter (1 byte)
;
;Error Handling:   	None.
;
;Algorithms:       	None.
;
;Limitations:  		Outputs new chars in the same array Display, DisplayHex, and 
;                   DisplayNum might be changing.
;
;
;Author:			Anjian Wu
;History:			11-04-2013: Pseudo code - Anjian Wu
;-------------------------------------------------------------------------------


DisplayHandler		    PROC    NEAR
				        PUBLIC  DisplayHandler

        PUSH    AX                          ;save the registers
        PUSH    BX                          ;Event Handlers should NEVER change
        PUSH    DX                          ;   any register values

DisplayHInit:

        MOV     BX, Digit       ;get offset for current digit
        CMP     BX, Display_SIZE            ;Is the offset too large?
        JL      DisplayHUpdate               ;
        ;JGE     DisplayDigitReset          ;

DisplayDigitReset:

        MOV    BX, 0     


		;        
DisplayHUpdate:                     ;update the display
        MOV     AL, DHandlerVar2.buffer[BX]  ; Grab seg pat from buffer    
        MOV     AH, DHandlerVar1.buffer[BX]  ; Grab seg pat from buffer    
										; already in seg code form
        MOV     DX, LEDDisplay2              ;get the display address     
        ADD     DX, BX                      ; Get digit offset for display
        OUT     DX, AL                      ;output segment directly, buffer
                                            ; already in seg code form
        MOV     DX, LEDDisplay              ;get the display address        
        ADD     DX, BX                      ; Get digit offset for display
        SHR		AX, 8						;
        OUT     DX, AL                      ;output segment directly, buffer
		


DisplayDigitUpdate:                         ;do the next segment pattern

        INC     BX                          ;update segment pattern number
        
        MOV     Digit, BX       ;


EndDisplayHandler:                   ;done taking care of the timer

        MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
        MOV     AX, TimerEOI
        OUT     DX, AL

        POP     DX                      ;restore the registers
        POP     BX
        POP     AX


        IRET                            ;and return (Event Handlers end with IRET not RET)


DisplayHandler       ENDP
        
;Procedure:			DisplayClear
;
;
;Description:      	This procedure will fill the DisplayArray with ASCII_NULL.
;                   It does this by simply looping through all Display[0 to 7]
;                   and writing ASICC_NULL to them.
;
;                   
;                   
;Operation:			*   Reset counter
;                   *   Loop 8 times and clear each char into ASCII_NULL
;                   *   DONE
;
;                   
;Arguments:         None.
;
;Return Values:    	None.
;
;Result:            ASCII_NULL empty DisplayArray
;
;Shared Variables: 	The display array created is shared with DisplayHandler, Display,
;                   DisplayHex, and DisplayNum
;
;Local Variables:	DisplayArray - 8 BYTES of chars
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
;Data Structures:	DisplayArray (8 bytes).
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
;-------------------------------------------------------------------------------

DisplayBufferFill		PROC    NEAR
				        PUBLIC  DisplayBufferFill
				        
    PUSH    CX;
    PUSH    BX;
				
DisplayClrInit:


    MOV     CX, 0           ; Clear the counter
                            ; Counter goes from 0 to DisplaySize - 1

DisplayClrLoop:

    CMP     CX, Display_SIZE ; Is the counter maxed out?
    JGE     DisplayClrDone  ; Yes, exit loop
                            ; No, continue loop
                            
    MOV     [SI] , AL       ; Stored the return value
        
    INC     CX              ; Update Counter
    INC     SI              ;
    
    JMP     DisplayClrLoop  ; 
    
DisplayClrDone:

    POP    BX;
    POP    CX;

    RET                     ;
    
DisplayBufferFill  ENDP           
 
ASCIISegTable   LABEL   BYTE
                PUBLIC  ASCIISegTable


;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000000000B               ;NUL
        DW      0000000000000000B               ;SOH
        DW      0000000000000000B               ;STX
        DW      0000000000000000B               ;ETX
        DW      0000000000000000B               ;EOT
        DW      0000000000000000B               ;ENQ
        DW      0000000000000000B               ;ACK
        DW      0000000000000000B               ;BEL
        DW      0000000000000000B               ;backspace
        DW      0000000000000000B               ;TAB
        DW      0000000000000000B               ;new line
        DW      0000000000000000B               ;vertical tab
        DW      0000000000000000B               ;form feed
        DW      0000000000000000B               ;carriage return
        DW      0000000000000000B               ;SO
        DW      0000000000000000B               ;SI
        DW      0000000000000000B               ;DLE
        DW      0000000000000000B               ;DC1
        DW      0000000000000000B               ;DC2
        DW      0000000000000000B               ;DC3
        DW      0000000000000000B               ;DC4
        DW      0000000000000000B               ;NAK
        DW      0000000000000000B               ;SYN
        DW      0000000000000000B               ;ETB
        DW      0000000000000000B               ;CAN
        DW      0000000000000000B               ;EM
        DW      0000000000000000B               ;SUB
        DW      0000000000000000B               ;escape
        DW      0000000000000000B               ;FS
        DW      0000000000000000B               ;GS
        DW      0000000000000000B               ;AS
        DW      0000000000000000B               ;US

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000000000B               ;space
        DW      0000000000000000B               ;!
        DW      0000001000000010B               ;"
        DW      0000000000000000B               ;#
        DW      0001001101101101B               ;$
        DW      0000000000000000B               ;percent symbol
        DW      0000000000000000B               ;&
        DW      0000000000000010B               ;'
        DW      0000000000111001B               ;(
        DW      0000000000001111B               ;)
        DW      0111111101000000B               ;*
        DW      0001001101000000B               ;+
        DW      0000000000000000B               ;,
        DW      0000000101000000B               ;-
        DW      0000000000000000B               ;.
        DW      0010010000000000B               ;/
        DW      0000000000111111B               ;0
        DW      0001001000000000B               ;1
        DW      0000000101011011B               ;2
        DW      0000000001001111B               ;3
        DW      0000000101100110B               ;4
        DW      0000000101101101B               ;5
        DW      0000000101111101B               ;6
        DW      0010010000000001B               ;7
        DW      0000000101111111B               ;8
        DW      0000000101100111B               ;9
        DW      0000000000000000B               ;:
        DW      0000000000000000B               ;;
        DW      0000110000000000B               ;<
        DW      0000000101001000B               ;=
        DW      0110000000000000B               ;>
        DW      0001000001000011B               ;?

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0001000001011111B               ;@
        DW      0000000101110111B               ;A
        DW      0001001001001111B               ;B
        DW      0000000000111001B               ;C
        DW      0001001000001111B               ;D
        DW      0000000100111001B               ;E
        DW      0000000100110001B               ;F
        DW      0000000001111101B               ;G
        DW      0000000101110110B               ;H
        DW      0001001000001001B               ;I
        DW      0000000000011110B               ;J
        DW      0000110100110000B               ;K
        DW      0000000000111000B               ;L
        DW      0100010000110110B               ;M
        DW      0100100000110110B               ;N
        DW      0000000000111111B               ;O
        DW      0000000101110011B               ;P
        DW      0000100000111111B               ;Q
        DW      0000100101110011B               ;R
        DW      0000000101101101B               ;S
        DW      0001001000000001B               ;T
        DW      0000000000111110B               ;U
        DW      0100100000000110B               ;V
        DW      0010100000110110B               ;W
        DW      0110110000000000B               ;X
        DW      0101010000000000B               ;Y
        DW      0010010000001001B               ;Z
        DW      0000000000111001B               ;[
        DW      0100100000000000B               ;\
        DW      0000000000001111B               ;]
        DW      0000000000000000B               ;^
        DW      0000000000001000B               ;_

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000100000B               ;`
        DW      0001000100011000B               ;a
        DW      0000000101111100B               ;b
        DW      0000000101011000B               ;c
        DW      0000000101011110B               ;d
        DW      0000000101111011B               ;e
        DW      0000000100110001B               ;f
        DW      0000000101101111B               ;g
        DW      0000000101110100B               ;h
        DW      0001000000000000B               ;i
        DW      0000000000001110B               ;j
        DW      0000110100110000B               ;k
        DW      0001001000000000B               ;l
        DW      0001000101010100B               ;m
        DW      0000000101010100B               ;n
        DW      0000000101011100B               ;o
        DW      0000000101110011B               ;p
        DW      0000000101100111B               ;q
        DW      0000000101010000B               ;r
        DW      0000000101101101B               ;s
        DW      0000000100111000B               ;t
        DW      0000000000011100B               ;u
        DW      0000100000000100B               ;v
        DW      0001000000011100B               ;w
        DW      0110110000000000B               ;x
        DW      0000000101101110B               ;y
        DW      0010010000001001B               ;z
        DW      0000000000000000B               ;{
        DW      0001001000000000B               ;|
        DW      0000000000000000B               ;}
        DW      0000000000000001B               ;~
        DW      0000000000000000B               ;rubout

CODE    ENDS 
    
DATA    SEGMENT PUBLIC  'DATA'


DisplayArray       DISPLAYSTRUC <>      ;Where DisplayArray is in data mem

DHandlerVar1       DISPLAYVARS <> ; Where DisplayHandler's counter is stored

DHandlerVar2       DISPLAYVARS <>      ;Where DisplayArray is in data mem

    digit       DW      ?
	
DATA    ENDS

        END 