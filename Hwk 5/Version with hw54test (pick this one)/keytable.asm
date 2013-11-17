        NAME  KEYTABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   KEYTABLE                                 ;
;                           Tables of 4x4 Keypad Codes                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains tables of the possible 4x4 keypad codes.  
; The tables included:
;
;    KeyHandlerTable - table of codes each possible KEY press for KeyHandler
;
; Revision History:
;    11/15/2013   Anjian Wu              initial revision 



$INCLUDE(keypad.inc);



;setup code group and start the code segment
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'





; KeyHandlerTable
;
; Description:      This table contains all combinations of KEYs (ROW wise)
;                   The way KEYS are mapped physically is...
;                   [0]     [1]   [2]   [3]
;                   [4]     [5]   [6]   [7]
;                   [8]     [9]   [10]  [11]
;                   [12]    [13]  [14]  [15]
;
;                   The values are address mapped to the right key by the bits
;                   0-0-[R1]-[R0]:[C3]-[C2]-[C1]-[C0]
;
;                   Where lower nibble's bits indicates which column is pressed
;                   and the lower TWO bits of the upper nibble.
;                   
;                   Thus the table contains 2^6 entries.
;
;                   Advantage: Easier coding by using a table look up
;                   Can support multiple key presses (in a row) easily.
;
;                   Disadvantage: Used up more code segment, but not that much :)
;
; Author:           Anjian Wu
; Last Modified:    11/15/2013


KeyHandlerTable	LABEL	BYTE
                PUBLIC  KeyHandlerTable
                
                        ;00[R1][R0]:[C3][C2][C1][C0]
                        
	DB		NOTAKEY	;	0	->	00000000	->
	
	DB		KEY0	;	1	->	00000001	-> KEY0
    
	DB		KEY1	;	2	->	00000010	-> KEY1
	
	DB		NOTAKEY	;	3	->	00000011	->
	
	DB		KEY2	;	4	->	00000100	-> KEY2
	
	DB		NOTAKEY	;	5	->	00000101	->
	DB		NOTAKEY	;	6	->	00000110	->
	DB		NOTAKEY	;	7	->	00000111	->
	
	DB		KEY3	;	8	->	00001000	-> KEY3
	
	DB		NOTAKEY	;	9	->	00001001	->
	DB		NOTAKEY	;	10	->	00001010	->
	DB		NOTAKEY	;	11	->	00001011	->
	DB		NOTAKEY	;	12	->	00001100	->
	DB		NOTAKEY	;	13	->	00001101	->
	DB		NOTAKEY	;	14	->	00001110	->
	DB		NOTAKEY	;	15	->	00001111	->
	DB		KEY7	;	16	->	00010000	->
	
	DB		KEY4	;	17	->	00010001	-> KEY4
	DB		KEY5	;	18	->	00010010	-> KEY5
	
	DB		NOTAKEY	;	19	->	00010011	->
	
	DB		KEY6	;	20	->	00010100	-> KEY6
	
	DB		NOTAKEY	;	21	->	00010101	->
	DB		NOTAKEY	;	22	->	00010110	->
	DB		NOTAKEY	;	23	->	00010111	->
	
	DB		KEY7	;	24	->	00011000	-> KEY7
	
	DB		NOTAKEY	;	25	->	00011001	->
	DB		NOTAKEY	;	26	->	00011010	->
	DB		NOTAKEY	;	27	->	00011011	->
	DB		NOTAKEY	;	28	->	00011100	->
	DB		NOTAKEY	;	29	->	00011101	->
	DB		NOTAKEY	;	30	->	00011110	->
	DB		NOTAKEY	;	31	->	00011111	->
	DB		NOTAKEY	;	32	->	00100000	-> 
	
	DB		KEY8	;	33	->	00100001	-> KEY8
	DB		KEY9	;	34	->	00100010	-> KEY9
	
	DB		NOTAKEY	;	35	->	00100011	->
	
	DB		KEY10	;	36	->	00100100	-> KEY10
	
	DB		NOTAKEY	;	37	->	00100101	->
	DB		NOTAKEY	;	38	->	00100110	->
	DB		NOTAKEY	;	39	->	00100111	->
	
	DB		KEY11	;	40	->	00101000	-> KEY11
	
	DB		NOTAKEY	;	41	->	00101001	->
	DB		NOTAKEY	;	42	->	00101010	->
	DB		NOTAKEY	;	43	->	00101011	->
	DB		NOTAKEY	;	44	->	00101100	->
	DB		NOTAKEY	;	45	->	00101101	->
	DB		NOTAKEY	;	46	->	00101110	->
	DB		NOTAKEY	;	47	->	00101111	->
	DB		NOTAKEY	;	48	->	00110000	->
	
	DB		KEY12	;	49	->	00110001	-> KEY12
	DB		KEY13	;	50	->	00110010	-> KEY13
	
	DB		NOTAKEY	;	51	->	00110011	->
	
	DB		KEY14	;	52	->	00110100	-> KEY14
	
	DB		NOTAKEY	;	53	->	00110101	->
	DB		NOTAKEY	;	54	->	00110110	->
	DB		NOTAKEY	;	55	->	00110111	->
	
	DB		KEY15	;	56	->	00111000	-> KEY15
	
	DB		NOTAKEY	;	57	->	00111001	->
	DB		NOTAKEY	;	58	->	00111010	->
	DB		NOTAKEY	;	59	->	00111011	->
	DB		NOTAKEY	;	60	->	00111100	->
	DB		NOTAKEY	;	61	->	00111101	->
	DB		NOTAKEY	;	62	->	00111110	->
	DB		NOTAKEY	;	63	->	00111111	->



CODE    ENDS



        END
