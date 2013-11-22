
        NAME    hw6_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 hw6_main                                   ;
;                            Homework #5 Main Loop                           ;
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
;   ClrIRQVectors   -   This functions installs the IllegalEventHandler for all
;                       interrupt vectors in the interrupt vector table.
;
;   InitCS          -   Initialize the Peripheral Chip Selects on the 80188.
;
;   TimerInit       -   Initializes Timer 0 and Timer 1 for Keypad and Display
;
;   IllegalEventHandler -   This procedure is the event handler for illegal
;                           (uninitialized) interrupts.  It does nothing
;
;
;       			Pseudo code - 11-11-2013 - Anjian Wu
;       			Working - 11-15-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the key functions for Homework
;                   #5, keypad. It does this by:
;                   *   First doing standard main loop chip select and vector table
;                       clearing
;                   *   Calling Keyhandler and display handler initialization functions
;                   *   Initializing Timers
;                   *   Starting interrupts
;                   *   Finally just goes into looping indefinitely so that interrupts
;                       do all the work.
;
; Input:            Keypad is input for Keyhandler (interrupt driven.)
; Output:           14 seg Display is output for DisplayHandler (interrupt driven.)
;
; User Interface:   The output char on 14-seg display which shows key pressed and num times.
;
; Error Handling:   None.
;
; Algorithms:       None.
;
; Data Structures:  Queues in hw6test.obj
;
; Known Bugs:       None.
; Limitations:      Only outputs 8 char strings max.
;
; Revision History:
;History:			11-11-2013: Pseudo code - Anjian Wu
;       			Working - 11-15-2013 - Anjian Wu


$INCLUDE(general.inc); Include files
$INCLUDE(timer.inc);
$INCLUDE(chips.inc);


CGROUP  GROUP   CODE
DGROUP  GROUP   STACK, DATA

CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP


;external function declarations


        EXTRN   MotorInit:NEAR         ;For initializing keyhandler
        EXTRN   MotorTest:NEAR     ;For initializing displayhandler



START:

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        CALL    InitCS                  ; Initialize the chip selects
        CALL    ClrIRQVectors           ;
        
        CALL    InitTimer               ; Initialize timer events, note interrupts

        CALL    MotorInit               ; Initialize keypad handler
        STI                             ; Begin interrupts

        CALL    MotorTest               ; Start Glenn's test code
LOOPING:

        JMP     LOOPING;



; ClrIRQVectors
;
; Description:      This functions installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table.  Note
;                   that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips  (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC. This is taken from Glenn's exmaples
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      1 word
;
; Author:           Glen George
; Last Modified:    Feb. 8, 2002
;              	    Added to Main - 11-09-2013 - Anjian Wu


ClrIRQVectors   PROC    NEAR


InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to bottom of Vector table

        MOV     CX, 256         ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
                                ;check if should store the vector
        CMP     SI, 4 * FIRST_RESERVED_VEC
        JB	    DoStore		     ;if before start of reserved field - store it
        CMP	    SI, 4 * LAST_RESERVED_VEC
        JBE	    DoneStore	     ;if in the reserved vectors - don't store it
        ;JA	DoStore		         ;otherwise past them - so do the store

DoStore:                        ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:			            ;done storing the vector
        ADD     SI, 4           ;update pointer to next vector
                                ; We increment by 4 since each vector is comprised
                                ; of a CS:IP (WORD:WORD). Thus each unit is normalized
                                ; to four bytes and we need to jump 4 positions per vector.

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET


ClrIRQVectors   ENDP


; InitCS
;
; Description:       Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:         Write the initial values to the PACS and MPCS registers.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Oct. 29, 1997
;              	     Pseudo code - 11-02-2013 - Anjian Wu
;              	     Added to Main - 11-09-2013 - Anjian Wu
;       			Working - 11-15-2013 - Anjian Wu



InitCS  PROC    NEAR; Do what we did for HWK1 part 5 :)


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS


        RET                     ;done so return


InitCS  ENDP

; IllegalEventHandler
;
; Description:       This procedure is the event handler for illegal
;                    (uninitialized) interrupts.  It does nothing - it just
;                    returns after sending a non-specific EOI.
;
; Operation:         Send a non-specific EOI and return.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       2 words
;
; Author:            Glen George
; Last Modified:     Dec. 25, 2000
;              	     Added to Main - 11-09-2013 - Anjian Wu


IllegalEventHandler     PROC    NEAR

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-sepecific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP
; InitTimer
;
; Description:       Initialize the 80188 Timers.  The timers 0 & 1 are initialized
;                    to generate interrupts approximately every millisecond.
;
;                    Timer0 counter is cleared, and the interrupt control is
;                    set to be enabled, continuous, and generate interrupts.
;
;                    Timer1 counter is cleared, and the interrupt control is
;                    set to be enabled, continuous, and generate interrupts.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
;                    are reset to zero.  Finally, the interrupt controller is
;                    setup to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Oct. 29, 1997
;              	     Pseudo code - 11-02-2013 - Anjian Wu
;              	     Added to Main - 11-09-2013 - Anjian Wu
;       			 Working - 11-15-2013 - Anjian Wu


InitTimer       PROC    NEAR

;-------------------TIMER 0 Interrupt Setup--------------------------------------
InitTimer0CountSet:
                                ;initialize Timer #0 for 1 ms interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL
InitTimer0MaxSet:

        MOV     DX, Tmr0MaxCntA ;setup max count for milliseconds per segment
        MOV     AX, COUNT_FOR_100HZ  ;   count so can time the segments
        OUT     DX, AL

InitTimer0ControlSet:

        MOV     DX, Tmr0Ctrl    ;setup the control register
        MOV     AX, Tmr0CtrlVal ;Set appropriate bits to timer register
        OUT     DX, AL

InitTimerIntControlSet:

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL
InitTimerDone:

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer       ENDP



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