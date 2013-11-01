
        NAME    HW2TEST

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW2TEST                                  ;
;                            Homework #2 Test Code                           ;
;                                  EE/CS  51                                 ;
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
;    1/24/06  Glen George               initial revision
;    1/26/06  Glen George               fixed a minor bug
;                                       allow lowercase hex digits
;                                       removed DUPs
;    1/22/07  Glen George               updated comments
;    9/29/10  Glen George               updated comments to indicate it is now
;                                          for Homework #2



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


START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX


        CALL    ConvertTest             ;do the conversion tests
        JCXZ    AllTestsGood            ;go to appropriate infinite loop
        ;JMP    TestFailed              ;  based on return value


TestFailed:                             ;a test failed
        JMP     TestFailed              ;just sit here until get interrupted


AllTestsGood:                           ;all tests passed
        JMP     AllTestsGood            ;just sit here until get interrupted

        
CODE    ENDS




;the data segment

DATA    SEGMENT PUBLIC  'DATA'


StringOut       DB      MAX_STRING_SIZE  DUP (?) ;buffer for converted strings


DATA    ENDS




;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START