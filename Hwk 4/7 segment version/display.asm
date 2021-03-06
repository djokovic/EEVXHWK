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


    PUSH    SI;
    LEA     SI, DHandlerVar.buffer  ; Grab address of display array
    MOV     AL, SEGMENT_NULL ;
    CALL    DisplayBufferFill; Fill display array with ASCII_NULLs
    POP     SI;
    


    MOV     CX, 0           ; Clear the counter
                            ; Counter goes from 0 to DisplaySize - 1

DisplayStrLoop:

    CMP     CX, Display_SIZE ; Is the counter maxed out?
    JGE     DisplayStrDone  ; Yes, exit loop
                            ; No, continue loop
    MOV     AL, ES:[SI]     ; Grab char at address arg, put in AL for XLAT
    CMP     AL, ASCII_NULL  ; Is it ASCII_NULL? Cuz if so, end loop
    JE      DisplayStrDone  ;
    
    
DisplayLoopXLAT:
    MOV	    BX, OFFSET(ASCIISegTable);point into the table of seg table
    XLAT	CS:ASCIISegTable		;Now seg val is in AL
 
    MOV     BX, CX                          ;
    MOV     DHandlerVar.buffer[BX] , AL   ; Stored the return value
        
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


        MOV     DHandlerVar.Digit, 0    ; Clear the Digit counters


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

        MOV     BX, DHandlerVar.Digit       ;get offset for current digit
        CMP     BX, Display_SIZE            ;Is the offset too large?
        JL      DisplayUpdate               ;
        ;JGE     DisplayDigitReset          ;

DisplayDigitReset:

        MOV    BX, 0                        ;        


DisplayUpdate:                              ;update the display

        MOV     DX, LEDDisplay              ;get the display address
                
        ADD     DX, BX                      ; Get digit offset for display
        
        MOV     AL, DHandlerVar.buffer[BX]  ; Grab seg pat from buffer    
        OUT     DX, AL                      ;output segment directly, buffer
                                            ; already in seg code form


DisplayDigitUpdate:                         ;do the next segment pattern

        INC     BX                          ;update segment pattern number
        
        MOV     DHandlerVar.Digit, BX       ;


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
 

; ASCIISegTable
;
; Description:      This is the segment pattern table for ASCII characters.
;                   It contains the active-high segment patterns for all
;                   possible 7-bit ASCII codes.  Codes which do not have a
;                   "reasonable" way of being displayed on a 7-segment display
;                   are left blank.  None of the codes set the decimal point.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           Glen George
; Last Modified:    Nov. 11, 1993

ASCIISegTable   LABEL   BYTE
                PUBLIC  ASCIISegTable


;       DB      .gfedcba                ;ASCII character

        DB      00000000B               ;NUL
        DB      00000000B               ;SOH
        DB      00000000B               ;STX
        DB      00000000B               ;ETX
        DB      00000000B               ;EOT
        DB      00000000B               ;ENQ
        DB      00000000B               ;ACK
        DB      00000000B               ;BEL
        DB      00000000B               ;backspace
        DB      00000000B               ;TAB
        DB      00000000B               ;new line
        DB      00000000B               ;vertical tab
        DB      00000000B               ;form feed
        DB      00000000B               ;carriage return
        DB      00000000B               ;SO
        DB      00000000B               ;SI
        DB      00000000B               ;DLE
        DB      00000000B               ;DC1
        DB      00000000B               ;DC2
        DB      00000000B               ;DC3
        DB      00000000B               ;DC4
        DB      00000000B               ;NAK
        DB      00000000B               ;SYN
        DB      00000000B               ;ETB
        DB      00000000B               ;CAN
        DB      00000000B               ;EM
        DB      00000000B               ;SUB
        DB      00000000B               ;escape
        DB      00000000B               ;FS
        DB      00000000B               ;GS
        DB      00000000B               ;AS
        DB      00000000B               ;US

;       DB      .gfedcba                ;ASCII character

        DB      00000000B               ;space
        DB      00000000B               ;!
        DB      00100010B               ;"
        DB      00000000B               ;#
        DB      00000000B               ;$
        DB      00000000B               ;percent symbol
        DB      00000000B               ;&
        DB      00000010B               ;'
        DB      00111001B               ;(
        DB      00001111B               ;)
        DB      00000000B               ;*
        DB      00000000B               ;+
        DB      00000000B               ;,
        DB      01000000B               ;-
        DB      00000000B               ;.
        DB      00000000B               ;/
        DB      00111111B               ;0
        DB      00000110B               ;1
        DB      01011011B               ;2
        DB      01001111B               ;3
        DB      01100110B               ;4
        DB      01101101B               ;5
        DB      01111101B               ;6
        DB      00000111B               ;7
        DB      01111111B               ;8
        DB      01100111B               ;9
        DB      00000000B               ;:
        DB      00000000B               ;;
        DB      00000000B               ;<
        DB      01001000B               ;=
        DB      00000000B               ;>
        DB      00000000B               ;?

;       DB      .gfedcba                ;ASCII character

        DB      01011111B               ;@
        DB      01110111B               ;A
        DB      01111111B               ;B
        DB      00111001B               ;C
        DB      00111111B               ;D
        DB      01111001B               ;E
        DB      01110001B               ;F
        DB      01111101B               ;G
        DB      01110110B               ;H
        DB      00000110B               ;I
        DB      00011110B               ;J
        DB      00000000B               ;K
        DB      00111000B               ;L
        DB      00000000B               ;M
        DB      00000000B               ;N
        DB      00111111B               ;O
        DB      01110011B               ;P
        DB      00000000B               ;Q
        DB      00000000B               ;R
        DB      01101101B               ;S
        DB      00000000B               ;T
        DB      00111110B               ;U
        DB      00000000B               ;V
        DB      00000000B               ;W
        DB      00000000B               ;X
        DB      01100110B               ;Y
        DB      00000000B               ;Z
        DB      00111001B               ;[
        DB      00000000B               ;\
        DB      00001111B               ;]
        DB      00000000B               ;^
        DB      00001000B               ;_

;       DB      .gfedcba                ;ASCII character

        DB      00100000B               ;`
        DB      00000000B               ;a
        DB      01111100B               ;b
        DB      01011000B               ;c
        DB      01011110B               ;d
        DB      00000000B               ;e
        DB      00000000B               ;f
        DB      01101111B               ;g
        DB      01110100B               ;h
        DB      00000100B               ;i
        DB      00000000B               ;j
        DB      00000000B               ;k
        DB      00110000B               ;l
        DB      00000000B               ;m
        DB      01010100B               ;n
        DB      01011100B               ;o
        DB      00000000B               ;p
        DB      00000000B               ;q
        DB      01010000B               ;r
        DB      00000000B               ;s
        DB      01111000B               ;t
        DB      00011100B               ;u
        DB      00000000B               ;v
        DB      00000000B               ;w
        DB      00000000B               ;x
        DB      01101110B               ;y
        DB      00000000B               ;z
        DB      00000000B               ;{
        DB      00000110B               ;|
        DB      00000000B               ;}
        DB      00000001B               ;~
        DB      00000000B               ;rubout



 ;-------------------------------------------------------------------------------
 
CODE    ENDS 
    
DATA    SEGMENT PUBLIC  'DATA'


DisplayArray       DISPLAYSTRUC <>      ;Where DisplayArray is in data mem

DHandlerVar        DISPLAYVARS <> ; Where DisplayHandler's counter is stored

DATA    ENDS

        END 