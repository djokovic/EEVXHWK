NAME        HW3

$INCLUDE(display.inc);
$INCLUDE(general.inc);
$INCLUDE(SEGTABLE.asm);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW4 Queue Functions                        ;
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
;   DisplayHandINIT - This installs the DisplayHandler into vector table
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
;
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


Display		    PROC    NEAR
				PUBLIC  Display

{
    CALL DisplayClear   ; Clear the display

    counter = 0; Reset counter
    fullflag = false; Array not full yet
    
    WHILE(counter < 8 AND !fullflag)
    {
        
        DisplayArray[counter] = ByteRead[ES:SI]; Grab next ascii char
        
        IF(ByteRead[ES:SI] == ASCII_NULL); did we hit the end of string?
        {
            fullflag = true; yes, so set full flag
        }
        
        
        SI = SI + 1; next char address
        counter = counter + 1; update counter
        
    }


    RETURN
}
    
   



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

{

    CALL DisplayClear   ; Clear the display array
    errorflag = false   ; Assume no errors 
    
    a = addressOF(DisplayArray[0]); Get start of address of array
    
    CALL Dec2String(a, AX, errorflag); Let dec2string do all the work



    RETURN
}
       

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

{

    CALL DisplayClear   ; Clear the display array
    
    a = addressOF(DisplayArray[0]); Get start of address of array
    
    CALL Hex2String(a, AX); Let Hex2String do all the work



    RETURN
}
         


; InstallHandler
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

DisplayHandINIT		    PROC    NEAR
				        PUBLIC  DisplayHandINIT

{

    Clear(ES); Empty ES since vector table starts at 0x00
    
    Timer0Vector = address(ES:WORD PTR (4 * Tmr0Vec)); Calc Timer0 location
    
    ValueAt(Timer0Vector) = addressOF(DisplayHandler); Set the location pointed to
    ;                                               ; displayhandler
    
    DHandlerVar.counter = 0; Also reset the counter used by DisplayHandler
    
    RETURN; 
}
        
				
  


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
				
{
    Save_all_Regs();
    
    counter = DHandlerVar.counter; grab the counter value from last time
    
    IF(counter > 7); Check if counter needs to be reset
    {
        counter = 0;
    }
    
    CharOut = ASCII_SEGTABLE(DisplayArray[counter]);Grab ascii value and then
    ;                                               map that to the segment code
    ;                                               needed for display.
    
    
    
    OUTPUT(CharOut, DISPLAYIOADDRESS); Output that segment
    
    counter = counter + 1; Prepare for next index display char
    
    DHandlerVar.counter = counter; store it so next interrupt can use it
    
    
    Restore_all_Regs();
}
        
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

DisplayClear		    PROC    NEAR
				        PUBLIC  DisplayClear
				
{
    i = 0; Clear counter
    
    WHILE(i < 8); Simply clear the whole size 8 array with ASCII_NULLs
    {
        DisplayArray[i] = ASCII_NULL;
        i ++;
    
    }
    
    RETURN
    
}
        
 
 ;-------------------------------------------------------------------------------
   
    
DATA    SEGMENT PUBLIC  'DATA'


DisplayArray       DISPLAYSTRUC <>      ;Where DisplayArray is in data mem

DHandlerVar        DISPLAYHANDLERSTRUC <> ; Where DisplayHandler's counter is stored

DATA    ENDS

        END 