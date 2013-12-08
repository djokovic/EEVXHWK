;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Serial.INC                         		;
;                              Serial Constants                             ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for timers and their interupts
;
; Revision History:
;    12/04/2013			Created - Anjian Wu

;FSM Constants

POS             EQU     1       ;
NEGA            EQU     -1      ;
MAX_ABS_SPEED   EQU     65535   ;
MIN_ABS_SPEED	EQU     0       ;
MAX_MAG         EQU     32767   ;
MAX_ELEVATION   EQU     60      ;
MIN_ELEVATION   EQU     -60     ;

;FSM States Definitions

ST_INITIAL	    EQU     0   ;Start state
ST_SAS_INIT     EQU     1   ;Set Abs Speed
ST_SAS          EQU     2   ;Set Abs Speed
ST_SRS_INIT     EQU     3   ;Set Rel Speed
ST_SRS_WAIT     EQU     4   ;Set Rel Speed
ST_SRS          EQU     5   ;Set Rel Speed
ST_DIR_INIT     EQU     6   ;Set Direction
ST_DIR_WAIT     EQU     7   ;Set Direction
ST_DIR          EQU     8   ;Set Direction
ST_RTR_INIT     EQU     9   ;Rot Turret Rotation rel
ST_RTR_WAIT     EQU     10  ;Rot Turret Rotation rel
ST_RTA_ABS      EQU     11  ;Rot Turret Angle abs
ST_RTA_REL      EQU     12  ;Rot Turret Angle abs
ST_STEA_INIT    EQU     13  ;Set Turret Elevation Angle
ST_STEA_WAIT    EQU     14  ;Set Turret Elevation Angle
ST_STEA         EQU     15  ;Set Turret Elevation Angle
ST_LAZON        EQU     16  ;Set Laser ON
ST_LAZOFF       EQU     17  ;Set Laser OFF
ST_ERROR        EQU     18  ;Set Turret Elevation Angle

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
TOKEN_IGNORE    EQU     10;
TOKEN_END       EQU     11; - Return
TOKEN_OTHER     EQU     12;



