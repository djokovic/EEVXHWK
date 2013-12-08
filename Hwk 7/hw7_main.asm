
        NAME    hw7_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 hw7_main                                   ;
;                            Homework #7 Main Loop                           ;
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
;                                 What's was last edit?
;
;       			Pseudo code ->  11-25-2013 - Anjian Wu
;                   Working     ->  11-30-2013 - Anjian Wu
;                   Documentation-> 12-01-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the motor functions with HW6test.obj
;
;                   *   First set up chip select for keypad and display.
;                   *   Clear all interrupt vectors, and setting up Illegaleventhandler
;                   *   Initialize all Serial Functions and Serial Chip settings
;                   *   Starting interrupts
;                   *   Call hw7 test code
;
; Input:            None.
; Output:           None.
;
; User Interface:   Serial port.
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
;       			Pseudo code ->  11-25-2013 - Anjian Wu
;                   Working     ->  11-30-2013 - Anjian Wu
;                   Documentation-> 12-01-2013 - Anjian Wu
;----------------------------------------------------------------------------------------

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
        EXTRN   SerialInit:NEAR             ;For initializing motor handler
        EXTRN   SerialIOTest:NEAR           ;To test Motor function
START:

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        CALL    InitUserInterfaceCS     ; Initialize the UI chip selects
        CALL    ClrIRQVectors           ;
        
        CALL    SerialInit              ; Initialize Serial functions and chip
        STI                             ; Begin interrupts

        CALL    SerialIOTest               ; Start Glenn's test code
LOOPING:

        JMP     LOOPING                 ; Hopefully never hit here




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