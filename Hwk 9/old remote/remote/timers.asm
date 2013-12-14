        NAME    timers
$INCLUDE(timer.inc); Include files
$INCLUDE(general.inc)
$INCLUDE(vectors.inc)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 timers.asm                                 ;
;                                EE/CS  51                                   ;
;                                 Anjian Wu                                  ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;   Timer0Init       -   Initializes Timer 0 for motors.
;
;       			Created -> 11-22-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Timer0Init
;
; Description:       Initialize the 80188 Timers.  The timer 0 is initialized
;                    to generate interrupts approximately everytime the counter
;                    hits COUNT_FOR_30HZ.
;
;                    Timer0 counter is cleared, and the interrupt control is
;                    set to be enabled, continuous, and generate interrupts.
;
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
; Last Modified:     Working -> 11-22-2013 - Anjian Wu

CGROUP  GROUP   CODE


CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

Timer0Init       PROC    NEAR
                 PUBLIC Timer0Init
;-------------------TIMER 0 Interrupt Setup--------------------------------------
Timer0InitCountSet:
                                ;initialize Timer #0 for interrupt every COUNT_FOR_30HZ
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AX
Timer0InitMaxSet:

        MOV     DX, Tmr0MaxCntA      ;  setup max count at COUNT_FOR_30HZ
        MOV     AX, CTS_PER_MILSEC  ;  count so can time the segments
        OUT     DX, AX

Timer0InitControlSet:

        MOV     DX, Tmr0Ctrl    ;setup the control register
        MOV     AX, Tmr0CtrlVal ;Set appropriate bits to timer register
        OUT     DX, AX

Timer0InitIntControlSet:

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL
Timer0InitDone:

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


Timer0Init       ENDP

; Timer1Init
;
; Description:       Initialize the 80188 Timers.  The timer 0 is initialized
;                    to generate interrupts approximately everytime the counter
;                    hits COUNT_FOR_30HZ.
;
;                    Timer0 counter is cleared, and the interrupt control is
;                    set to be enabled, continuous, and generate interrupts.
;
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
; Last Modified:     Working -> 11-22-2013 - Anjian Wu

Timer1Init       PROC    NEAR
                 PUBLIC Timer1Init
;-------------------TIMER 0 Interrupt Setup--------------------------------------
Timer1InitCountSet:
                                ;initialize Timer #0 for interrupt every COUNT_FOR_30HZ
        MOV     DX, Tmr1Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AX
Timer1InitMaxSet:

        MOV     DX, Tmr1MaxCntA     ;  setup max count at COUNT_FOR_30HZ
        MOV     AX, CTS_PER_MILSEC  ;  count so can time the segments
        OUT     DX, AX

Timer1InitControlSet:

        MOV     DX, Tmr1Ctrl    ;setup the control register
        MOV     AX, Tmr1CtrlVal ;Set appropriate bits to timer register
        OUT     DX, AX

Timer1InitIntControlSet:

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AX
Timer1InitDone:

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


Timer1Init       ENDP

; Timer2Init
;
; Description:       Initialize the 80188 Timers.  The timer 0 is initialized
;                    to generate interrupts approximately everytime the counter
;                    hits COUNT_FOR_30HZ.
;
;                    Timer0 counter is cleared, and the interrupt control is
;                    set to be enabled, continuous, and generate interrupts.
;
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
; Last Modified:     Working -> 11-22-2013 - Anjian Wu

Timer2Init       PROC    NEAR
                 PUBLIC Timer2Init
;-------------------TIMER 0 Interrupt Setup--------------------------------------
Timer2InitCountSet:
                                ;initialize Timer 2 for interrupt every COUNT_FOR_30HZ
        MOV     DX, Tmr2Count   ;initialize the count register 
        XOR     AX, AX
        OUT     DX, AX
Timer2InitMaxSet:

        MOV     DX, Tmr2MaxCnt          ;  setup max count at COUNT_FOR_30HZ
        MOV     AX, CTS_PER_MILSEC      ;  count so can time the segments
        OUT     DX, AX

Timer2InitControlSet:

        MOV     DX, Tmr2Ctrl    ;setup the control register
        MOV     AX, Tmr2CtrlVal ;Set appropriate bits to timer register
        OUT     DX, AX

Timer2InitIntControlSet:

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL
Timer2InitDone:

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


Timer2Init       ENDP

CODE    ENDS

END
