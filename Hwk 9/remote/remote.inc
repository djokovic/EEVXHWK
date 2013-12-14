;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Remote.INC                         		;
;                               Remote Constants                    	    ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains robot constants
;
; Revision History:
;    11/10/2013			Created - Anjian Wu
;    12/11/2013			Added PRESCALE - Anjian Wu
;    12/12/2013			Updated numOfStatus - Anjian Wu

; General Constants

PRESCALE            EQU    2000    ; How many Millisec per change in display
                                    ; status?
ACTION_LABEL       EQU     0       ;
ACTION_VAL		   EQU	   1	   ;
SPEED_LABEL        EQU     2       ;
ANGLE_LABEL        EQU     4       ;
ERROR_LABEL        EQU     6       ;


; Key Commands  


CMD_LENGTH          EQU     7       ; Standard FIXED CMD length

; Displaying Constants

numOfStatus         EQU     10       ;


;FSM States Definitions

ST_INITIAL	    EQU     0   ;Start state
ST_SPEED        EQU     1   ;Set Abs Speed: wait for digit or '+'
ST_DIR          EQU     2   ;Set Abs Speed: wait for digit
ST_ROBOT        EQU     3   ; Grab Robot Error string

;Token offsets
TOKEN_S         EQU     0; - Set Speed
TOKEN_D         EQU     1;- Set Dir
TOKEN_R         EQU     2;- Set Robot Error
TOKEN_NUM       EQU     3;- A digit
TOKEN_END       EQU     4; - Return
TOKEN_OTHER     EQU     5; Bad char

NUM_TOKEN_TYPES EQU     TOKEN_OTHER + 1; TOKEN_OTHER is always the last Token

; TOken Masks

TOKEN_MASK	EQU	01111111B	;mask high bit of token