JMP 	;start code
	START
JMP		;interrupt code
	INTERRUPT
0x30
0x00
0x05	;ver quais entradas
0x00	;DIR_A 
0x00    ;DATA_A
0xff    ;DIR_B 
0x00    ;DATA_B
0xff    ;DIR_C 
0x00    ;DATA_C
0x00	;tmp DATA1 0x0d Ases com o dealer
0x00	;tmp DATA2 0x0e	Ases com o player
0x00	;tmp DATA3 0x0f soma dealer
0x00	;tmp DATA4 0x10 soma player
START:	CLR 
			0x0D
		CLR 
			0x0E
		CLR 
			0x0F
		CLR 
			0x10
		LD X, 		;first player card
			0x08
		MOV K
			0x0A
		ST K,
			0x10
		JLT 
			NO_FIG1
		JMP
			CARD2
NO_FIG1: MOV K
			0x01
		ST X,
			0x10
		JGT 
			CARD2
		ST K,
			0x0e
		MOV K
			0x0B
		ST K,
			0x10
CARD2:	CALL 		;first dealer card
			NEXT_CARD
		LD X, 		
			0x08
		ST X
			DATA_B
		MOV K
			0x0A
		ST K,
			0x0f
		JLT 
			NO_FIG2
		JMP
			CARD3
NO_FIG2: MOV K
			0x01
		ST X,
			0x0f
		JGT 
			CARD3
		ST K,
			0x0D
		MOV K
			0x0B
		ST K,
			0x0f
CARD3:	CALL 		;second player card
			NEXT_CARD
		LD X, 		
			0x08	
		LD Y,
			0x10
		MOV K
			0x09
		JGT 
			FIG3
		MOV K
			0x01
		JGT
			AS3		
		JMP
			FIMCARD3
FIG3:	MOV X,
			0x0A
		JMP 
			FIMCARD3		
AS3:	LD X
			0x0E
		JXZ
			FIMCARD3
		MOV X
			0x01			
FIMCARD3: ADD X,Y 
		ST K 
			0x10
		ST K
			DATA_C
CARD4:	CALL 		;second player card
			NEXT_CARD
		LD X, 		
			0x08	
		LD Y,
			0x0F
		MOV K
			0x09
		JGT 
			FIG4
		MOV K
			0x01
		JGT
			AS4		
		JMP
			FIMCARD4
FIG4:	MOV X,
			0x0A
		JMP 
			FIMCARD4		
AS4:	LD X
			0x0D
		JXZ
			FIMCARD4
		MOV X
			0x01			
FIMCARD4: ADD X,Y 
		ST K 
			0x0F
LOOP1:	NOP			
		JMP		
			LOOP1
INTERRUPT: MOV K
				0x10	;0001 0000  mais cartas
		LD Y
			0x08
		AND K,	Y
		MOV X, K		
		JXZ	
			PLAYERPEDE
PAROU:	LD X
			0x0F
		MOV K
			0x11
		JLT 
			BANCAPEDE
		LD K 
			0x10
		JLT	
			BANCAPERDE
		JGT
			BANCAGANHA
EMPATE:	LD X
			DATA_C
		MOV Y 
			0x20
		OR X, Y
		ST K
			DATA_C
		RETI
BANCAGANHA: MOV	K
				0x15
			JGT 
				BANCAPERDEU
BANCAGANHOU: LD K
				DATA_C
			MOV Y 
				0x40
			OR K, Y
			ST K
				DATA_C
			RETI
BANCAPERDE: MOV X
				0x15
			JLT
				BANCAGANHOU
BANCAPERDEU LD K
				DATA_C
			MOV Y 
				0x80
			OR K, Y
			ST K
				DATA_C
			RETI			
BANCAPEDE: CALL
				NEXT_CARD
			LD Y ,
				0x08
			ADD X, Y
			ST K
				0x08
			JMP	
				PAROU
PLAYERPEDE: CALL 
				NEXT_CARD
			LD X
				0x08
			LD Y
				0x10
			ADD X,Y
			ST K
				0x10
			ST K
				DATA_C
			RETI
NEXT_CARD: MOV K,
			0x80
		LD Y
			0x0A
		OR K,Y
		ST K,
			0x0A
		ST Y,
			0x0A
		RET