        NAME    vectors
$INCLUDE(vectors.inc); Include files
$INCLUDE(general.inc)
$INCLUDE(timer.inc)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 vectors.asm                                ;
;                                EE/CS  51                                   ;
;                                 Anjian Wu                                  ;
;                               TA: Pipe-mazo                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 What's in here?
;
;   ClrIRQVectors   -   This functions installs the IllegalEventHandler for all
;                       interrupt vectors in the interrupt vector table.
;
;
;   IllegalEventHandler -   This procedure is the event handler for illegal
;                           (uninitialized) interrupts.  It does nothing
;
;       			Created -> 11-22-2013 - Anjian Wu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
; Stack Depth:      None.
;
; Last Modified:    Working -> 11-22-2013 - Anjian Wu

CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'
        ASSUME  CS:CGROUP
        
ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors

InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to top of Vector table

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
; Last Modified:     Moved here - 11-23-2013 - Anjian Wu


IllegalEventHandler     PROC    NEAR

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-specific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP

CODE    ENDS

END
