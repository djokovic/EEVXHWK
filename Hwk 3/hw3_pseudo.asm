NAME        HW3



;Procedure:			QueueInit
;
;Description:      	This procedure will intialize the queue of passed length 'l',
;                   size ''s', and pointed address 'a'. It does this by simply
;                   setting the queue head and tail pinters to the same (zero).
;                   It will also store the length 'l' of the queue and size 's'
;                   on the data memory. 
;Operation:			
;
;Arguments:        	
;
;Return Values:    	None;
;
;Shared Variables: 	None.
;
;Local Variables:	i -> INT sign flag
;					temp -> INT current power of 10
;
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	None.
;
;Registers Used:	AX, SI (probably a lot others, but not sure yet)
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	None;
;
;Algorithms:       	Repeatedly mask off next hex digit and store.
;
;Limitations:  		Will always allocate 5 characters worth space in mem for 
;					return value (e.g. 0xF -> 0x000F).
;
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------




;Procedure:			QueueEmpty
;
;Description:      	This procedure will check the queue at address 'a' and 
;                   see if it is empty. It does this by checking whether
;                   The headpointer is equal to the tail pointer.
;                   If it is empty zeroflag -> true
;                   If it is not empty zeroflag -> reset
;
;Operation:			This code will convert a bin number from AX (n) and store 
;					the signed decimal value at 'a'.
;
;Arguments:        	n (AX) -> 16 - bit signed value
;					a (DS:SI) -> location in memory (DS:SI)
;
;Return Values:    	error -> INT Error flag
;
;Shared Variables: 	None.
;
;Local Variables:	Sign -> INT sign flag
;					pwr10 -> INT current power of 10
;					error ->  INT Error flag
;					digit -> BCD each digit from algorithm
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Used:	AX, SI (probably a lot others, but not sure yet)
;
;Stack Depth:		None for now.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;Algorithms:       	Repeatedly divide by powers of 10 and get the remainders
;                   (which are the BCD digits).
;
;Limitations:  		Only handles numbers less than 5 digits. Will always 			
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------




;Procedure:			QueueFull
;
;Description:       This function take the address of the queue at 'a' to
;                   see if it is FULL. It does this by looking at the
;                   head/tailed pointers and queue length of address 'a'
;                   doing the following calculation.
;                   (Tail + 1) % length = X. If X = H then it is FULL,
;                   else it is not full.
;
;                   If it is full zeroflag -> true
;                   If it is not full; zeroflag -> reset
;
;Operation:         The passed integer is looked up in a table containing the
;                   square root of every integer (a 256 entry table).
;
; Arguments:         AL - unsigned value for which to compute the square root.
; Return Value:      AL - integer square root of the passed argument.
;
;
;Shared Variables: 	None.
;
;Local Variables:	Sign -> INT sign flag
;					pwr10 -> INT current power of 10
;					error ->  INT Error flag
;					digit -> BCD each digit from algorithm
;Global Variables:	None.
;					
;					
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Changed: flags, BX.
;
;Stack Depth:		None.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;
;Algorithms:       	 Table lookup.
;
;Limitations:  		Only handles numbers less than 5 digits. Will always 			
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------


;Procedure:			Dequeue
;
;Description:       This function take the address of the queue at 'a' to
;                   see if it is FULL. It does this by looking at the
;                   head/tailed pointers and queue length of address 'a'
;                   doing the following calculation.
;                   (Tail + 1) % length = X. If X = H then it is FULL,
;                   else it is not full.
;
;                   If it is full zeroflag -> true
;                   If it is not full; zeroflag -> reset
;
;Operation:         The passed integer is looked up in a table containing the
;                   square root of every integer (a 256 entry table).
;
; Arguments:         AL - unsigned value for which to compute the square root.
; Return Value:      AL - integer square root of the passed argument.
;
;
;Shared Variables: 	None.
;
;Local Variables:	Sign -> INT sign flag
;					pwr10 -> INT current power of 10
;					error ->  INT Error flag
;					digit -> BCD each digit from algorithm
;Global Variables:	None.
;
;
;Input:            	None.
;Output:           	String in (DS:SI). Fixed size of 5 bytes.
;
;Registers Changed: flags, BX.
;
;Stack Depth:		None.
;
;Known Bugs:		None for now.
;
;Data Structures:	None.
;
;Error Handling:   	The program has an error flag that is raised if the Dec2BCD
;					runs into error. If so, the stored value is undefined.
;
;Algorithms:       	 Table lookup.
;
;Limitations:  		Only handles numbers less than 5 digits. Will always
;					allocate 5 characters worth space in mem for return
;					value (e.g. 1 -> +0001).
;Author:			Anjian Wu
;History:			Pseudo code - 10-21-2013
;-------------------------------------------------------------------------------


