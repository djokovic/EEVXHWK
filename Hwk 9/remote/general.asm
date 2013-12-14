NAME        general

$INCLUDE(general.inc);

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 General Functions                          ;
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
;   XWORDLAT  -   Sets the motor speed by changing PWM width
;   no_op     -   Does nothing except return.
;
;                                 What's was last edit?
;
;                   Edits by Anjian Wu
;       			11-18-2013 - pseudo code
;       			12-12-2013 - Add no_op function here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Procedure:			XWORDLAT
;
;Description:      	This function performs the WORD equivalent of XLAT instr.
;                   It takes arguments AX as the offset of the Table, BX as the
;                   element pointer, and ES as the location of the where the segment
;                   should be.
;           
;                   It will then return the table lookup value in AX.
;                   
;Operation:			* Adjust element index for WORD look up
;                   * Add in the absolute offset of the table
;                   * Grab the value and store word in AX. Then return that.
;
;Arguments:        	AX     -> Offset of WORD look up table
;                   BX     -> Element Pointer
;                   ES     -> Which segment, CS or DS
;
;Return Values:    	AX     -> The element grabbed.
;
;
;Shared Variables: 	None.
;
;Local Variables:	BX -   absolute pointer for table look up
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
;History:			11-22-2013: Created - Anjian Wu
;------------------------------------------------------------------------------

CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


XWORDLAT		PROC    NEAR
				PUBLIC  XWORDLAT    ; Used by many functions


    
    PUSH    BX;
XWORDLATBODY:    
    SHL     BX, WORD_LOOKUP_ADJUST  ; Adjust relative pointer for WORD entries
    ADD     BX, AX                  ; Grab absolute address by adding offset
    MOV     AX, ES:[BX]             ; Grab the word from table
    
    POP     BX;
    
    RET
    
XWORDLAT ENDP


;Procedure:			no_op
;
;Description:      	Just return (stub function)
;        
;Arguments:        	None.
;Return Values:    	none.
;Shared Variables: 	none.
;Local Variables:	None.
;Global Variables:	None.			
;Input:            	None.
;Output:           	None.
;Registers Used:	None.
;Stack Depth:		none.
;Known Bugs:		None.
;Data Structures:	None.
;Error Handling:   	None
;Algorithms:       	None.
;Limitations:  		None.
;Author:			Anjian Wu
;History:			12-02-2013: Pseudo code - Anjian Wu
;                   12-08-2013: Documentation - Anjian Wu
;------------------------------------------------------------------------------
no_op        PROC    NEAR
            PUBLIC   no_op

    RET
    
no_op   ENDP
			
CODE    ENDS
    

        END 