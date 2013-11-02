
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
;                   #3.  It calls Glenn's mystery functions with two passed
;                   values, the queue struc address and max_queue length.
;                   All test handling and breakpoints is inside QueueTest.
;                   Note the max length allowed is 511, since there is always
;                   a empty ele spot in queue.
;
; Input:            None.
; Output:           None.
;
; User Interface:   No real user interface.  The user can set breakpoints at
;                   QueueGood and QueueError to see if the code is working
;                   or not.
; Error Handling:   If a test fails the program jumps to QueueError.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      The max queue length is limited by Max_Length
;
; Revision History:
;    10/31/2013     Initial version -   Anjian Wu
;    11/01/2013     Debugged and working - Anjian Wu
;    11/02/2013     Fixed bug where queue could go beyond
;                   allocated length - Anjian Wu


$INCLUDE(general.inc);
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
        MOV     CX, MAX_Q_LENG - 1     ; Load queue's max length
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