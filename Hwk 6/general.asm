NAME        Motors

$INCLUDE(motors.inc);
$INCLUDE(general.inc);
$INCLUDE(timer.inc);

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
;Description:      	This interrupt performs the holonomic calculations for each
;           
;                   
;Operation:			* Check if angle needs to be changed
;                       * If not, then used previous angle
;
;Arguments:        	AX     -> Offset of WORD look up table
;                   BX     -> Element Pointer
;                   ES     -> Which segment, CS or DS
;
;Return Values:    	None.
;
;Result:            Possibly new values in S[0 to 2], speedstored, and anglestored
;
;Shared Variables: 	S[0 to 2] (WRITE)
;                   SpeedStored (WRITE/READ) 
;                   AngleStored (WRITE/READ)
;
;Local Variables:	Angletemp -   temporary variable that stores angle values
;                   Speedtemp -   temporary variable that stores angle values
;                   counter   -   stores counter index
;                   Fx        -   stores x component
;                   Fy        -   stores y component
;                   
;
;Global Variables:	None.
;					
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
;History:			11-18-2013: Pseudo code - Anjian Wu
;------------------------------------------------------------------------------

CGROUP  GROUP   CODE
DGROUP GROUP    DATA

CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

XWORDLAT		PROC    NEAR
				PUBLIC  XWORDLAT    ; Used by many functions


    
    PUSH    BX;
XWORDLATBODY:    
    SHL     BX, 1                   ; Adjust pointer for WORD entries
    ADD     BX, AX                  ; Grab absolute address
    MOV     AX, ES:[BX]             ; Grab the word from table
    
    POP     BX;
    
    RET
    
XWORDLAT ENDP

				
CODE    ENDS
    
DATA    SEGMENT PUBLIC  'DATA'

; Empty for now
    	
DATA    ENDS

        END 