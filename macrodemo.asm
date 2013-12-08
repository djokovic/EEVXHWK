        NAME  MACRODEMO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    MACDEMO                                 ;
;                            Macro Demonstration Code                        ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains macro calls to test extra credit macro functions.
;
;
; Revision History
;    11/26/2013  Glen George       Created

; local include files
$INCLUDE(macro.INC)



PROGRAM SEGMENT PUBLIC 'CODE'

        ASSUME  CS:PROGRAM, DS:NOTHING, ES:NOTHING


    ; Addresses used in this test
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register

     ;try CLR(reg)
     
	%CLR(AX)    ; Clear AX
    %CLR(BX)    ; Clear BX
    %CLR(CX)    ; Clear CX
    %CLR(DX)    ; Clear DX
    
    MOV AX, CS  ; Prepare to test XLATW
    MOV ES, AX  ; Doing XLATW for CS table
    
    MOV BX, OFFSET(MACRO_TEST_TABLE);
    
    MOV AX, 1   ; Want 2nd letter
    
    %XLATW      ; Grab 'BB' in AX
    
    %WRITEPCB(Tmr0Ctrl, 0C038H)  ; Timer 0 control reg in PCB should have 0C038H now
    %READPCB(Tmr0Ctrl)           ; Check to see if 0C038H is in AX
    


MACRO_TEST_TABLE	    LABEL	BYTE
                        PUBLIC  MACRO_TEST_TABLE
                                    
	DB		'AA' 	    ;First letter of alphabet
	DB		'BB' 	    ;2nd letter of alphabet
	DB		'CC' 	    ;3rd letter of alphabet


PROGRAM	ENDS


	END