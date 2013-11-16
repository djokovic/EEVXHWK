        NAME  KEYTABLE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   KEYTABLE                                 ;
;                           Tables of 4x4 Keypad Codes                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains tables of 14-segment codes.  The segment ordering is a to
; p followed by the decimal point with segment a in the low bit (bit 0) and
; segment p in bit 14 (the decimal point is in bit 7 for backward
; compatibility with 7-segment displays).  Bit 15 (high bit) is always zero
; (0).  The tables included are:
;    KeyHandlerTable - table of codes for 7-bit ASCII characters
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
;                   The way KEYS are arranged is...
;                   [0]     [1]   [2]   [3]
;                   [4]     [5]   [6]   [7]
;                   [8]     [9]   [10]  [11]
;                   [12]    [13]  [14]  [15]
;
; Author:           Anjian Wu
; Last Modified:    11/15/2013


KeyHandlerTable	LABEL	BYTE
                        ;xx[R1][R0]:[C3][C2][C1][C0]
                        
	DB		NOTAKEY	;	0	->	00000000	->
	
	DB		KEY3	;	1	->	00000001	-> KEY3
	DB		KEY2	;	2	->	00000010	-> KEY3
	
	DB		NOTAKEY	;	3	->	00000011	->
	
	DB		KEY1	;	4	->	00000100	-> KEY1
	
	DB		NOTAKEY	;	5	->	00000101	->
	DB		NOTAKEY	;	6	->	00000110	->
	DB		NOTAKEY	;	7	->	00000111	->
	
	DB		KEY0	;	8	->	00001000	-> KEY0
	
	DB		NOTAKEY	;	9	->	00001001	->
	DB		NOTAKEY	;	10	->	00001010	->
	DB		NOTAKEY	;	11	->	00001011	->
	DB		NOTAKEY	;	12	->	00001100	->
	DB		NOTAKEY	;	13	->	00001101	->
	DB		NOTAKEY	;	14	->	00001110	->
	DB		NOTAKEY	;	15	->	00001111	->
	DB		KEY7	;	16	->	00010000	->
	
	DB		KEY6	;	17	->	00010001	-> KEY7
	DB		NOTAKEY	;	18	->	00010010	-> KEY6
	
	DB		NOTAKEY	;	19	->	00010011	->
	
	DB		KEY5	;	20	->	00010100	-> KEY5
	
	DB		NOTAKEY	;	21	->	00010101	->
	DB		NOTAKEY	;	22	->	00010110	->
	DB		NOTAKEY	;	23	->	00010111	->
	
	DB		KEY4	;	24	->	00011000	-> KEY4
	
	DB		NOTAKEY	;	25	->	00011001	->
	DB		NOTAKEY	;	26	->	00011010	->
	DB		NOTAKEY	;	27	->	00011011	->
	DB		NOTAKEY	;	28	->	00011100	->
	DB		NOTAKEY	;	29	->	00011101	->
	DB		NOTAKEY	;	30	->	00011110	->
	DB		NOTAKEY	;	31	->	00011111	->
	DB		NOTAKEY	;	32	->	00100000	-> 
	
	DB		KEY11	;	33	->	00100001	-> KEY11
	DB		KEY10	;	34	->	00100010	-> KEY10
	
	DB		NOTAKEY	;	35	->	00100011	->
	
	DB		KEY9	;	36	->	00100100	-> KEY9
	
	DB		NOTAKEY	;	37	->	00100101	->
	DB		NOTAKEY	;	38	->	00100110	->
	DB		NOTAKEY	;	39	->	00100111	->
	
	DB		KEY8	;	40	->	00101000	-> KEY8
	
	DB		NOTAKEY	;	41	->	00101001	->
	DB		NOTAKEY	;	42	->	00101010	->
	DB		NOTAKEY	;	43	->	00101011	->
	DB		NOTAKEY	;	44	->	00101100	->
	DB		NOTAKEY	;	45	->	00101101	->
	DB		NOTAKEY	;	46	->	00101110	->
	DB		NOTAKEY	;	47	->	00101111	->
	DB		NOTAKEY	;	48	->	00110000	->
	
	DB		KEY15	;	49	->	00110001	-> KEY15
	DB		KEY14	;	50	->	00110010	-> KEY14
	
	DB		NOTAKEY	;	51	->	00110011	->
	
	DB		KEY13	;	52	->	00110100	-> KEY13
	
	DB		NOTAKEY	;	53	->	00110101	->
	DB		NOTAKEY	;	54	->	00110110	->
	DB		NOTAKEY	;	55	->	00110111	->
	
	DB		KEY12	;	56	->	00111000	-> KEY12
	
	DB		NOTAKEY	;	57	->	00111001	->
	DB		NOTAKEY	;	58	->	00111010	->
	DB		NOTAKEY	;	59	->	00111011	->
	DB		NOTAKEY	;	60	->	00111100	->
	DB		NOTAKEY	;	61	->	00111101	->
	DB		NOTAKEY	;	62	->	00111110	->
	DB		NOTAKEY	;	63	->	00111111	->


    
CODE ENDS




CODE    ENDS



        END
