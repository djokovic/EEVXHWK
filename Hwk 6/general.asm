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
;
;
;                                 What's was last edit?
;
;       			Pseudo code -> 11-18-2013 - Anjian Wu
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
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

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

				
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'

; Empty for now
    	
DATA    ENDS

        END 