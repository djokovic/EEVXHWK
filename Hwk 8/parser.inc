;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Parser.INC                         		;
;                              Parser Constants                             ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for Parser
;
; Revision History:
;    12/04/2013			Created - Anjian Wu
;    12/06/2013			Add FSM states and Tokens - Anjian Wu
;    12/08/2013			Documentation - Anjian Wu

;FSM Constants

POS             EQU     1       ; Used for IMUL for conversion
NEGA            EQU     -1      ; Used for IMUL for conversion
MAX_ABS_SPEED   EQU     65534   ; Maximum speed val
MIN_ABS_SPEED	EQU     0       ; minimum speed val
MAX_MAG         EQU     32767   ; Max allowed val excluding sign
MAX_ELEVATION   EQU     60      ; Max ele angle
MIN_ELEVATION   EQU     -60     ; Min ele ang

;FSM States Definitions

ST_INITIAL	    EQU     0   ;Start state
ST_SAS_INIT     EQU     1   ;Set Abs Speed: wait for digit or '+'
ST_SAS_SIGN     EQU     2   ;Set Abs Speed: wait for digit
ST_SAS          EQU     3   ;Set Abs Speed: concat digits
ST_SRS_INIT     EQU     4   ;Set Rel Speed: wait for digit or '+' or '-'
ST_SRS_SIGN     EQU     5   ;Set Rel Speed: wait for digit
ST_SRS          EQU     6   ;Set Rel Speed: concat digits
ST_DIR_INIT     EQU     7   ;Set Direction: wait for digit or '+' or '-'
ST_DIR_SIGN     EQU     8   ;Set Direction: wait for digit
ST_DIR          EQU     9   ;Set Direction: concat digits
ST_RTR_INIT     EQU     10  ;Rot Turret Angle: wait for digit or '+' or '-'
ST_RTR_SIGN     EQU     11  ;Rot Turret Angle: wait for digit
ST_RTA_ABS      EQU     12  ;Rot Turret Angle: concat digits
ST_RTA_REL      EQU     13  ;Rot Turret Angle: concat digits
ST_STEA_INIT    EQU     14  ;Set Turret Elevation Angle: wait for digit or '+' or '-'
ST_STEA_SIGN    EQU     15  ;Set Turret Elevation Angle: wait for digit
ST_STEA         EQU     16  ;Set Turret Elevation Angle: concat digits
ST_LAZON        EQU     17  ;Set Laser ON
ST_LAZOFF       EQU     18  ;Set Laser OFF

;Token offsets
TOKEN_S         EQU     0; - Set Speed
TOKEN_V         EQU     1; - Set Rel Speed
TOKEN_D         EQU     2;- Set Dir
TOKEN_T         EQU     3; - Rot Turr Angl
TOKEN_E         EQU     4; - Set Turr Ele
TOKEN_F         EQU     5;- Laser On
TOKEN_O         EQU     6;- Laser Off
TOKEN_NUM       EQU     7;- A digit
TOKEN_POS       EQU     8;- '+'
TOKEN_NEG       EQU     9; - '-'
TOKEN_IGNORE    EQU     10; Ignore this char
TOKEN_END       EQU     11; - Return
TOKEN_OTHER     EQU     12; Bad char

NUM_TOKEN_TYPES EQU     TOKEN_OTHER + 1; TOKEN_OTHER is always the last Token

; TOken Masks

TOKEN_MASK	EQU	01111111B	;mask high bit of token


