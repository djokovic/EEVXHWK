
        NAME    hw4_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 hw4_main                                   ;
;                            Homework #4 Main Loop                           ;
;                                EE/CS  51                                   ;
;                                 Anjian Wu                                  ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;   Mainloop        -   This is the mainloop that initializes chip selects,
;                       timer interrupts, and display.
;
;   ClrIRQVectors   -   This functions installs the IllegalEventHandler for all
;                       interrupt vectors in the interrupt vector table.
;
;   InitCS          -   Initialize the Peripheral Chip Selects on the 80188.
;
;   InitTimer       -   Initialize the 80188 Timers. Only uses Timer0 for now
;
;   IllegalEventHandler -   This procedure is the event handler for illegal
;                           (uninitialized) interrupts.  It does nothing 
;
;
;       			Pseudo code - 11-02-2013 - Anjian Wu
;              	    Added to Main - 11-09-2013 - Anjian Wu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the display functions for Homework
;                   #4.  It calls Glenn's test functions that display
;                   test strings into the Display, and then loops between
;                   DisplayNum and DisplayHex
;
; Input:            None.
; Output:           Display, 7-segment 8 chars.
;
; User Interface:   Display, 7-segment 8 chars.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  Arrays.
;
; Known Bugs:       None.
; Limitations:      Only outputs 8 char strings max.
;
; Revision History:
;History:			11-04-2013: Pseudo code - Anjian Wu


$INCLUDE(general.inc);
$INCLUDE(timer.inc);
$INCLUDE(chips.inc);


CGROUP  GROUP   CODE
DGROUP  GROUP   STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP


;external function declarations


        EXTRN   DisplayHandlerInit:NEAR          ;convert a number to a decimal string

        EXTRN   DisplayTest:NEAR          ; Glenn's Test Code

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        CALL    InitCS                   ; Initialize the chip selects
        CALL    ClrIRQVectors           ;
        
        CALL    DisplayHandlerInit       ; Initialize display handler

        CALL    InitTimer                ; Initialize timer events, note interrupts
        
        STI                              ; start NOW
        CALL    DisplayTest              ;Call Glenn's tests
        
        

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
        MOV     SI, 0           ;initialize SI to skip RESERVED_VECS (4 bytes each)

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



InitCS  PROC    NEAR; Do what we did for HWK1 part 5 :)


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


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
; Description:       Initialize the 80188 Timers.  The timers are initialized
;                    to generate interrupts every MS_PER_SEG milliseconds.
;                    Timer0 counter is also clear, and the interrupt control is
;                    set.
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


InitTimer       PROC    NEAR

InitTimerCountSet:
                                ;initialize Timer #0 for MS_PER_SEG ms interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL
InitTimerMaxSet:

        MOV     DX, Tmr0MaxCntA ;setup max count for milliseconds per segment
        MOV     AX, CTS_PER_MILSEC  ;   count so can time the segments
        OUT     DX, AL
        
InitTimerControlSet:

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



;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END     START