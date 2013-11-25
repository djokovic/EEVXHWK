
        NAME    hw6_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 hw6_main                                   ;
;                            Homework #6 Main Loop                           ;
;                                EE/CS  51                                   ;
;                                 Anjian Wu                                  ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;   Mainloop        -   This is the mainloop that initializes chip selects,
;                       timer interrupts, and then LOOPS key functions.
;
;
;
;       			Pseudo code - 11-11-2013 - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the motor functions with HW6test.obj
;
;                   *   First set up chip select for keypad and display.
;                   *   Clear all interrupt vectors, and setting up Illegaleventhandler
;                   *   Initialize Timer0
;                   *   Calling Motor initialization function
;                   *   Starting interrupts
;                   *   Finally just goes into looping indefinitely so that interrupts
;                       do all the work.
;
; Input:            Keypad is input for MotorTest (interrupt driven.)
; Output:           14 seg Display from MotorTest, and PWM outputs from parallel chip for motors.
;
; User Interface:   The output char on 14-seg display which shows test number and PWM from parallel
;                   chip pins. Each time a key is pressed, a new test is set.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
; History:			11-11-2013: Pseudo code - Anjian Wu
;       			Working -> 11-22-2013 - Anjian Wu


$INCLUDE(general.inc); Include files
$INCLUDE(timer.inc);
$INCLUDE(chips.inc);


CGROUP  GROUP   CODE
DGROUP  GROUP   STACK, DATA

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP
        
;external function declarations
        EXTRN   ClrIRQVectors:NEAR          ;For initializing vector table
        EXTRN   InitUserInterfaceCS:NEAR    ;For initializing UI chip selects
        EXTRN   Timer0Init:NEAR             ;For initializing Timer 0 (motors)
        EXTRN   MotorInit:NEAR              ;For initializing motor handler
        EXTRN   MotorTest:NEAR              ;To test Motor function
START:

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        CALL    InitUserInterfaceCS     ; Initialize the UI chip selects
        CALL    ClrIRQVectors           ;
        
        CALL    Timer0Init              ; Initialize timer events, note interrupts

        CALL    MotorInit               ; Initialize motor handler
        STI                             ; Begin interrupts

        CALL    MotorTest               ; Start Glenn's test code
LOOPING:

        JMP     LOOPING                 ; Hopefulyl never hit here




CODE    ENDS


DATA    SEGMENT PUBLIC  'DATA'

; For setting up data seg.

DATA    ENDS

;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START