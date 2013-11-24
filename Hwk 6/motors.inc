
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                         	;
;                                  Motors.INC                         		;
;                               Motor Constants                             ;
;                                 Include File                              ;
;                                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the Motor functions
;
; Revision History:
;    11/18/2013			Created - Anjian Wu



; Fx Table Definitions

Fx1             EQU     07FFFH         ; Fx component for Motor 1
Fx2             EQU     0C000H         ; Fx component for Motor 2
Fx3             EQU     0C000H         ; Fx component for Motor 3
Fy1             EQU     0              ; Fy component for Motor 1
Fy2             EQU     09127H         ; Fy component for Motor 2
Fy3             EQU     06ED9H         ; Fy component for Motor 3

FY_offset       EQU     3              ; Fy components are 3 down in table

; Motor Conv. Constants

FULL_ANGLE      EQU     360             ; There are 360 deg in a full circle
NO_ANGLE_CHANGE EQU     -32768          ; NO angle change is denoted by -32768
NO_SPEED_CHANGE EQU     65535           ; No speed change is denoted by 65534;
numOfmotors     EQU     3               ; There are three motors on Robotrike

STOPPED_SPEED   EQU     0               ;
ZERO_ANGLE      EQU     0               ;

SPEED_ADJUST    EQU     1               ;

EXTRA_SIGN_BITS EQU     2               ;

ZERO_SPEED_PWM  EQU     0               ;

PWM_WIDTH_MAX   EQU     127             ;



; Motor PORT Vals
_8255_CNTRL_REG EQU     183H    ;Control Word Address
_8255_CNTRL_VAL EQU     80H     ;Control Word Write val: MODE 0 for BOTH groups A & B

PORTB           EQU     181H    ;Address of port B

; MOtor MASK vals
                                  
FORWARD_M1 	    EQU     00000010B   ;   MASK FORWARD for Motor 1
BACKWARD_M1 	EQU     00000011B   ;   MASK BACKWARD for Motor 1

FORWARD_M2 	    EQU     00001000B   ;   MASK FORWARD for Motor 2
BACKWARD_M2 	EQU     00001100B   ;   MASK BACKWARD for Motor 2

FORWARD_M3 	    EQU     00100000B   ;   MASK FORWARD for Motor 3
BACKWARD_M3 	EQU     00110000B   ;   MASK BACKWARD for Motor 3

STOP_M1 	    EQU     11111101B   ;   MASK STOP for Motor 1 Did not use
STOP_M2 	    EQU     11110111B   ;   MASK STOP for Motor 2 Did not use
STOP_M3 	    EQU     11011111B   ;   MASK STOP for Motor 3 Did not use

LASER_ON        EQU     10000000B   ;   OR MASK for laser ON (PortB)
LASER_OFF       EQU     01111111B   ;   AND MASK for laser OFF (PortB)




