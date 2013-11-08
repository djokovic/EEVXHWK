
        NAME    hw4_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   hw4_main                                 ;
;                            Homework #3 Main Loop                           ;
;                                  EE/CS  51                                 ;
;                               Anjian Wu                                    ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;   Mainloop    -   This is the mainloop that initializes chip selects,
;                   timer interrupts, and display.
;
;   InitCS      -   This function sets up the chip select
;
;   InitTimer  -    This function initializes the timer interrupts
;
;
;       			Pseudo code - 11-02-2013 - Anjian Wu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:      This program tests the display functions for Homework
;                   #4.  It calls Glenn's mystery functions that display
;                   test strings into the Display.
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

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations

        EXTRN   DisplayHex:NEAR          ;convert a number to a decimal string
        EXTRN   DisplayNum:NEAR         ;convert a number to a hex string
        EXTRN   Display:NEAR          ;convert a number to a decimal string
        EXTRN   DisplayHINIT:NEAR          ;convert a number to a decimal string

        EXTRN   DisplayTest:NEAR          ; Glenn's Test Code

START:  

MAIN:
        MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        CALL    InitCS                   ; Initialize the chip selects
        CALL    DisplayHINIT             ; Initialize display handler

        CALL    InitTimer                ; Initialize timer events, note interrupts
                                         ; start NOW
        CALL    DisplayTest              ;Call Glenn's tests


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


InitCS  PROC    NEAR

{
        Address = PACSreg     ;setup to write to PACS register
        Value = PACSval
        
        OUTPUT(Address, Value);write PACSval to PACS (base at 0, 3 wait states)

        Address = MPCSreg     ;setup to write to MPCS register
        Value = MPCSval
        OUTPUT(Address, Value);write MPCSval to MPCS (I/O space, 3 wait states)


        RETURN                     ;done so return
}


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


InitTimer       PROC    NEAR


                                ;initialize Timer #0 for MS_PER_SEG ms interrupts
        Address = Tmr0Count     ;initialize the count register to 0
        ValueOF(Tmr0Count) = 0  ;
        
        Address = Tmr0MaxCntA ;setup max count for milliseconds per segment
        Value   = MS_PER_SEG  ;   count so can time the segments
        ValueOF(Address) = Value

        Address = Tmr0Ctrl    ;setup the control register, interrupts on
        Value   = Tmr0CtrlVal
        ValueOF(Address) = Value

                                ;initialize interrupt controller for timers
        Address = INTCtrlrCtrl;setup the interrupt control register
        Value   = INTCtrlrCVal
        ValueOF(Address) = Value

        Address = INTCtrlrEOI ;send a timer EOI (to clear out controller)
        Value   = TimerEOI
        ValueOF(Address) = Value


        RETURN                     ;done so return


InitTimer       ENDP

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