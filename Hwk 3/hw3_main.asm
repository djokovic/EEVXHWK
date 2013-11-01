
        NAME    hw3_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   hw3_main                                 ;
;                            Homework #3 Main Loop                           ;
;                                  EE/CS  51                                 ;
;                               Anjian Wu                                    ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the conversion functions for Homework
;                   #2.  It calls each conversion function with a number of
;                   test values.  If all tests pass it jumps to the label
;                   AllTestsGood.  If any test fails it jumps to the label
;                   TestFailed.
;
; Input:            None.
; Output:           None.
;
; User Interface:   No real user interface.  The user can set breakpoints at
;                   AllTestsGood and TestFailed to see if the code is working
;                   or not.
; Error Handling:   If a test fails the program jumps to TestFailed.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      The returned strings must be less than MAX_STRING_SIZE
;                   characters.
;
; Revision History:
;    10/31/2013     Initial version -   Anjian Wu

$INCLUDE(queue.inc);

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations

        EXTRN   QueueInit:NEAR          ;convert a number to a decimal string
        EXTRN   QueueEmpty:NEAR         ;convert a number to a hex string
        EXTRN   QueueFull:NEAR          ;convert a number to a decimal string
        EXTRN   Dequeue:NEAR            ;convert a number to a hex string
        EXTRN   Enqueue:NEAR            ;convert a number to a hex string
        EXTRN   QueueTest:NEAR          ; Glenn's Test Code

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX


TestSetup:                             ;a test failed
        LEA     SI, QUEUE              ; Grab address of Queue
        MOV     CX, 512                ; Load queue's max length
TestGO:                                 
        CALL    QueueTest              ;Call Glenn's tests

        
CODE    ENDS




;the data segment

DATA    SEGMENT PUBLIC  'DATA'


QUEUE          QUEUESTRUC <>           ;Holds the String


DATA    ENDS




;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START