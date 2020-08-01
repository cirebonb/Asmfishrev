ScaleFuncW	= 1*2
ScaleFuncB	= 256*2
ScaleFuncWB	= (1+256)*2
EvalFunc	= 65536*2

ScaleBStronger	= 256
EvalBSTronger	= 65536
macro	constMaterial namedc, cwQ, cbQ, cwR, cbR, cwBL, cwBD, cbBL, cbBD, cwN, cbN, cwP, cbP
	local	wMat, bMat, diffMat, var1, var2
	namedc#factor1	= (64 shl 32)
	namedc#factor2	= (64 shl 40)
	namedc#factorx1	= (64 shl 32)
	namedc#factorx2	= (64 shl 40)
	wMat	= cwQ*QueenValueMg + cwR*RookValueMg+ cwBL*BishopValueMg + cwBD*BishopValueMg + cwN*KnightValueMg
	bMat	= cbQ*QueenValueMg + cbR*RookValueMg+ cbBL*BishopValueMg + cbBD*BishopValueMg + cbN*KnightValueMg
	if	cwP = 0
		diffMat = wMat - bMat
		if	diffMat <= BishopValueMg
			namedc#factor1	= 14	shl 32
			if bMat <= BishopValueMg
				namedc#factor1	= 4	shl 32
			end if
			if wMat < RookValueMg
				namedc#factor1	= 0
			end if
		end if
	end if
	if	cbP = 0
		diffMat = bMat - wMat
		if	diffMat <= BishopValueMg
			namedc#factor2	= 14	shl 40
			if wMat <= BishopValueMg
				namedc#factor2	= 4	shl 40
			end if
			if bMat < RookValueMg
				namedc#factor2	= 0
			end if
		end if
	end if
	namedc 	= 	cwQ + (cbQ*2) +	(cwR*2*2) + (cbR*2*2*3) + (cwBL*2*2*3*3) + (cwBD*2*2*3*3*2) + (cbBL*2*2*3*3*2*2) +(cbBD*2*2*3*3*2*2*2) + (cwN*2*2*3*3*2*2*2*2) + (cbN*2*2*3*3*2*2*2*2*3) + (cwP*2*2*3*3*2*2*2*2*3*3) + (cbP*2*2*3*3*2*2*2*2*3*3*9)
	if	((((cwBL = 1) & (cbBD =1)) | ((cwBD = 1) & (cbBL =1)) ) & bMat = BishopValueMg & wMat = BishopValueMg)
			if	namedc#factor1 = (64 shl 32)
				namedc#factor1 = (SCALE_FACTOR_BISHOP) shl 32
			end if
			if	namedc#factor2 = (64 shl 40)
				namedc#factor2 = (SCALE_FACTOR_BISHOP) shl 40
			end if
			if	namedc#factorx1 = (64 shl 32)
				namedc#factorx1 = (SCALE_FACTOR_BISHOP) shl 32
			end if
			if	namedc#factorx2 = (64 shl 40)
				namedc#factorx2 = (SCALE_FACTOR_BISHOP) shl 40
			end if
	else
		var1 = 7
		if (((cwBL = 1) & (cbBD =1)) | ((cwBD = 1) & (cbBL =1)) ) 	
			var1 = 2
		end if
			var2	= var1
			var1	= (var1 * cwP) +40
			if	var1 < 	64
				if	namedc#factor1 = (64 shl 32)
					namedc#factor1 = (var1 shl 32)
				end if
				if	namedc#factorx1 = (64 shl 32)
					namedc#factorx1 = (var1 shl 32)
				end if
			end if
			var2	= (var2 * cbP) + 40
			if	var2 < 	64
				if	namedc#factor2 = (64 shl 40)
					namedc#factor2 = (var2 shl 40)
				end if
				if	namedc#factorx2 = (64 shl 40)
					namedc#factorx2 = (var2 shl 40)
				end if
			end if
	end if
	namedc#factor	= 	namedc#factor1	or namedc#factor2
	namedc#factorx	=	namedc#factorx1	or namedc#factorx2
end macro

;	constMaterial namedc		, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	;insufficient
	constMaterial EndgameEval_0_0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;KK
	constMaterial EndgameEval_0_1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	;Kkn1
	constMaterial EndgameEval_0_2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	;Kkn2
	constMaterial EndgameEval_0_3	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;Kkb1
	constMaterial EndgameEval_0_4	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	;Kkb2
	constMaterial EndgameEval_0_5	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	;Kkb3
	constMaterial EndgameEval_0_6	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	;Kkb4
	constMaterial EndgameEval_0_7	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	;Knkn
	constMaterial EndgameEval_0_8	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	;Knkb1
	constMaterial EndgameEval_0_9	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	;Knkb2
	constMaterial EndgameEval_0_10	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	;Knkb3
	constMaterial EndgameEval_0_11	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0	, 0	;Knkb4

	constMaterial EndgameEval_0_12	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 0	, 0	;Kbkb1
	constMaterial EndgameEval_0_13	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	;Kbkb2
	constMaterial EndgameEval_0_14	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	;Kbkb3
	constMaterial EndgameEval_0_15	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 0	;Kbkb4
	constMaterial EndgameEval_0_16	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 1	, 0	, 0	;Knnkn1
	constMaterial EndgameEval_0_17	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 2	, 0	, 0	;Knnkn2

	constMaterial EndgameEval_0_18	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 2	, 0	, 0	, 0	;Knnkb1
	constMaterial EndgameEval_0_19	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 2	, 0	, 0	, 0	;Knnkb2
	constMaterial EndgameEval_0_20	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 2	, 0	, 0	;Knnkb3
	constMaterial EndgameEval_0_21	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 2	, 0	, 0	;Knnkb4
	
	constMaterial EndgameEval_KNNK1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 0	, 0	, 0
	constMaterial EndgameEval_KNNK2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 0	, 0

	constMaterial EndgameEval_KPK1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameEval_KPK2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0
	;white
	constMaterial EndgameEval_KBNK1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0	, 0	, 0
	constMaterial EndgameEval_KBNK2	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 0
	;black
	constMaterial EndgameEval_KBNK3	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0
	constMaterial EndgameEval_KBNK4	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0

	constMaterial EndgameEval_KRKP1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameEval_KRKP2	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0

	;white
	constMaterial EndgameEval_KRKB1	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0
	constMaterial EndgameEval_KRKB2	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0
	;black
	constMaterial EndgameEval_KRKB3	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0
	constMaterial EndgameEval_KRKB4	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0

	constMaterial EndgameEval_KRKN1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0
	constMaterial EndgameEval_KRKN2	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0

;	constMaterial namedc		, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	constMaterial EndgameEval_KQKP1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameEval_KQKP2	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0

	constMaterial EndgameEval_KQKR1	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0
	constMaterial EndgameEval_KQKR2	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0

; these endgame fxns correspond to many material config
;  and are not added to the map
;		lea   eax, [EndgameEval_KXK]
;		mov   r8d, EndgameEval_KXK_index
;		mov   dword[rbx+4*r8], eax

; these endgame fxns correspond to a specific material config
;	constMaterial namedc			, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	constMaterial EndgameScale_KNPK1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0
	constMaterial EndgameScale_KNPK2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1

	constMaterial EndgameEval_KNNKP1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 0	, 0	, 1
	constMaterial EndgameEval_KNNKP2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 1	, 0

	;white
	constMaterial EndgameScale_KNPKB1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 1	, 0
	constMaterial EndgameScale_KNPKB2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 1	, 0
	;black
	constMaterial EndgameScale_KNPKB3	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 1
	constMaterial EndgameScale_KNPKB4	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0	, 1

	constMaterial EndgameScale_KRPKR1	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KRPKR2	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1

	;white
	constMaterial EndgameScale_KRPKB1	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KRPKB2	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0
	;black
	constMaterial EndgameScale_KRPKB3	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1
	constMaterial EndgameScale_KRPKB4	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1

	;white
	constMaterial EndgameScale_KBPKB1	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KBPKB2	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KBPKB3	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KBPKB4	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 1	, 0
	;black
	constMaterial EndgameScale_KBPKB5	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KBPKB6	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KBPKB7	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KBPKB8	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 1

	;white
	constMaterial EndgameScale_KBPKN1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 1	, 0
	constMaterial EndgameScale_KBPKN2	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1	, 1	, 0
	;black
	constMaterial EndgameScale_KBPKN3	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 1
	constMaterial EndgameScale_KBPKN4	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 1

;	constMaterial namedc			, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	;white
	constMaterial EndgameScale_KBPPKB1	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 2	, 0	;x
	constMaterial EndgameScale_KBPPKB2	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 2	, 0	;v
	constMaterial EndgameScale_KBPPKB3	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 2	, 0	;v
	constMaterial EndgameScale_KBPPKB4	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 2	, 0	;x
	;black
	constMaterial EndgameScale_KBPPKB5	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 0	, 2	;x
	constMaterial EndgameScale_KBPPKB6	, 0	, 0	, 0	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 2	;v
	constMaterial EndgameScale_KBPPKB7	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 2	;v
	constMaterial EndgameScale_KBPPKB8	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 1	, 0	, 0	, 0	, 2	;x

	;white
	constMaterial EndgameScale_KRPPKRP1	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 1
	constMaterial EndgameScale_KRPPKRP2	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 1
	;black
	constMaterial EndgameScale_KRPPKRP3	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 2
	constMaterial EndgameScale_KRPPKRP4	, 0	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 2

	; these endgame fxns correspond to many material config   except KPKP
	;  and are not added to the map
;	constMaterial namedc			, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	;white
	constMaterial EndgameScale_KBPsK1	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KBPsK2	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 2	, 0
	constMaterial EndgameScale_KBPsK3	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 3	, 0
	constMaterial EndgameScale_KBPsK4	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 4	, 0
	constMaterial EndgameScale_KBPsK5	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 5	, 0
	constMaterial EndgameScale_KBPsK6	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 6	, 0
	constMaterial EndgameScale_KBPsK7	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KBPsK8	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 2	, 0
	constMaterial EndgameScale_KBPsK9	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 3	, 0
	constMaterial EndgameScale_KBPsK10	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 4	, 0
	constMaterial EndgameScale_KBPsK11	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 5	, 0
	constMaterial EndgameScale_KBPsK12	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 6	, 0
	;black
	constMaterial EndgameScale_KBPsK13	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KBPsK14	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 2
	constMaterial EndgameScale_KBPsK15	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 3
	constMaterial EndgameScale_KBPsK16	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 4
	constMaterial EndgameScale_KBPsK17	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 5
	constMaterial EndgameScale_KBPsK18	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 6
	constMaterial EndgameScale_KBPsK19	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KBPsK20	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 2
	constMaterial EndgameScale_KBPsK21	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 3
	constMaterial EndgameScale_KBPsK22	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 4
	constMaterial EndgameScale_KBPsK23	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 5
	constMaterial EndgameScale_KBPsK24	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 6

;	constMaterial namedc			, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	;white
	constMaterial EndgameScale_KQKRPs1	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1
	constMaterial EndgameScale_KQKRPs2	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2
	constMaterial EndgameScale_KQKRPs3	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 3
	constMaterial EndgameScale_KQKRPs4	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 4
	constMaterial EndgameScale_KQKRPs5	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 5
	constMaterial EndgameScale_KQKRPs6	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 6
	constMaterial EndgameScale_KQKRPs7	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 7
	constMaterial EndgameScale_KQKRPs8	, 1	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 8
	;black
	constMaterial EndgameScale_KQKRPs9	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0
	constMaterial EndgameScale_KQKRPs10	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 0
	constMaterial EndgameScale_KQKRPs11	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 3	, 0
	constMaterial EndgameScale_KQKRPs12	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 4	, 0
	constMaterial EndgameScale_KQKRPs13	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 5	, 0
	constMaterial EndgameScale_KQKRPs14	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 6	, 0
	constMaterial EndgameScale_KQKRPs15	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 7	, 0
	constMaterial EndgameScale_KQKRPs16	, 0	, 1	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 8	, 0
	;white
	constMaterial EndgameScale_KPsK1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2	, 0
	constMaterial EndgameScale_KPsK2	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 3	, 0
	constMaterial EndgameScale_KPsK3	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 4	, 0
	constMaterial EndgameScale_KPsK4	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 5	, 0
	constMaterial EndgameScale_KPsK5	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 6	, 0
	constMaterial EndgameScale_KPsK6	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 7	, 0
	constMaterial EndgameScale_KPsK7	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 8	, 0
	;black
	constMaterial EndgameScale_KPsK8	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 2
	constMaterial EndgameScale_KPsK9	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 3
	constMaterial EndgameScale_KPsK10	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 4
	constMaterial EndgameScale_KPsK11	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 5
	constMaterial EndgameScale_KPsK12	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 6
	constMaterial EndgameScale_KPsK13	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 7
	constMaterial EndgameScale_KPsK14	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 8

	constMaterial EndgameScale_KPKP0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 1

;===============================================================================
;Pawn   = 2	;0010
;Knight = 3	;0011
;Bishop = 4	;0100	---> BL & BD????? make piece converter funcpiece(pi,sq) with table
;Rook   = 5	;0101
;Queen  = 6	;0110
;King   = 7	;0111

;	constMaterial namedc			, cwQ	, cbQ	, cwR	, cbR	, cwBL	, cwBD	, cbBL	, cbBD	, cwN	, cbN	, cwP	, cbP
	constMaterial IndikatorwQ		, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;wQ
	constMaterial IndikatorwR		, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;wR
	constMaterial IndikatorwBL		, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;wBL
	constMaterial IndikatorwBD		, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	;wBD
	constMaterial IndikatorwN		, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	;wN
	constMaterial IndikatorwP		, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	;wP

	constMaterial IndikatorbQ		, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;bQ
	constMaterial IndikatorbR		, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	;bR
	constMaterial IndikatorbBL		, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	, 0	;bBL
	constMaterial IndikatorbBD		, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	, 0	, 0	;bBD
	constMaterial IndikatorbN		, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	, 0	, 0	;bN
	constMaterial IndikatorbP		, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 0	, 1	;bP

	constMaterial MaterialTableSize		, 2	, 2	, 3	, 3	, 2	, 2	, 2	, 2	, 3	, 3	, 9	, 9	;Size


;===============================================================================
macro ComputeValue pieceCountUs, pieceCountThem, SOF_Material, EOFMaterial
	local	loop_lookup_mater, notfound, loop_lookup_done, P1, P2, ColorLoop, Piece1Loop, Piece2Loop, SkipPiece
	local	NotOppBishop, ScaleFactorDone, Scale_Factor_Bishop, not_normal
			;in edi index

		imul	r14d, dword[pieceCountUs+4*(8*White+Knight)], KnightValueMg
		imul	ecx, dword[pieceCountUs+4*(8*White+Bishop)], BishopValueMg
		add	r14d, ecx
		imul	ecx, dword[pieceCountUs+4*(8*White+Rook)], RookValueMg
		add	r14d, ecx
		imul	ecx, dword[pieceCountUs+4*(8*White+Queen)], QueenValueMg
		add	r14d, ecx

		imul	r15d, dword[pieceCountUs+4*(8*Black+Knight)], KnightValueMg
		imul	ecx, dword[pieceCountUs+4*(8*Black+Bishop)], BishopValueMg
		add	r15d, ecx
		imul	ecx, dword[pieceCountUs+4*(8*Black+Rook)], RookValueMg
		add	r15d, ecx
		imul	ecx, dword[pieceCountUs+4*(8*Black+Queen)], QueenValueMg
		add	r15d, ecx

		;	r14d = materialUs
		;	r15d = materialThem
		lea	eax, [r14+r15]
		xor	edx, edx
		mov	ecx, MidgameLimit - EndgameLimit
		sub	eax, EndgameLimit
		cmovs	eax, edx
		cmp	eax, ecx
		cmovae	eax, ecx
		shl	eax, 7
		div	ecx
		mov	rdx, ((SCALE_FACTOR_NORMAL shl 40) or (SCALE_FACTOR_NORMAL shl 32))
		mov	qword[rsi+MaterialEntryEx.scalingFunction], rdx
		mov	byte[rsi+MaterialEntryEx.gamePhase], al
		movzx	edx, al
		shl	rdx, 3*8

;============= set scale & eval func
		lea	rcx, [.ScoringInclude]
.loop_lookup_mater:
		cmp	edi, dword[SOF_Material]
		jne	.notfound
		mov	rax, qword[SOF_Material+8]
		or	rdx, rax
		mov	qword[rsi+MaterialEntryEx.scalingFunction], rdx
		cmp	SOF_Material,rcx
		jge	.ScaleFactorDone
		jmp	.foundfunction	;.loop_lookup_done
.notfound:
		add	SOF_Material, 2*8
		cmp	SOF_Material, EOFMaterial
		jb	.loop_lookup_mater
		;look for EndgameEval_KXK_index
;.Try_KXK_White
		cmp	r15d,0	;Black == 0?
		jne	.O1
		cmp	dword[pieceCountUs+4*(8*Black+Pawn)],r15d	;0?
		jne	.O1
		cmp	r14d, RookValueMg
		jl	.O1
		mov	byte[rsi+MaterialEntryEx.evaluationFunction], 2*(EndgameEval_KXK_index)
		jmp	.foundfunction	;.loop_lookup_done
;.Try_KXK_Black
.O1:
		cmp	r14d,0	;White == 0?
		jne	.O2
		cmp	dword[pieceCountUs+4*(8*White+Pawn)],r14d
		jne	.O2
		cmp	r15d, RookValueMg
		jl	.O2
		mov	byte[rsi+MaterialEntryEx.evaluationFunction], 2*(EndgameEval_KXK_index)+1	;black
		jmp	.foundfunction	;.loop_lookup_done
.O2:
		mov	eax, 0x100
iterate Us, White, Black
  if Us = White
	Them	 equ Black
	npMat	 equ r14d
  else
	Them	 equ White
	npMat	 equ r15d
  end if

.Check_KBPsKs_#Us:
		cmp	npMat, BishopValueMg
		jne	.Check_KQKRPs_#Us
		cmp	ah, byte[rsp+4*(8*Us+Bishop)]
		jne	.Check_KQKRPs_#Us
		cmp	al, byte[rsp+4*(8*Us+Pawn)]
		je	.Check_KQKRPs_#Us
		mov	byte[rsi+MaterialEntryEx.scalingFunction+1*Us], 2*EndgameScale_KBPsK_index+Us
		jmp	.Check_sDone_#Us
.Check_KQKRPs_#Us:
		cmp	npMat, QueenValueMg
		jne	.Check_sDone_#Us
		cmp	al, byte[rsp+4*(8*Us+Pawn)]
		jne	.Check_sDone_#Us
		cmp	ah, byte[rsp+4*(8*Us+Queen)]
		jne	.Check_sDone_#Us
		cmp	ah, byte[rsp+4*(8*Them+Rook)]
		jne	.Check_sDone_#Us
		cmp	al, byte[rsp+4*(8*Them+Pawn)]
		je	.Check_sDone_#Us
		mov	byte[rsi+MaterialEntryEx.scalingFunction+1*Us], 2*EndgameScale_KQKRPs_index+Us
.Check_sDone_#Us:
end iterate
		test	r14d, r14d
		jnz	.NotOnlyPawns
		test	r15d, r15d
		jnz	.NotOnlyPawns
		mov	eax, dword[rsp+4*(8*Black+Pawn)]
		add	eax, dword[rsp+4*(8*White+Pawn)]
		jz	.NotOnlyPawns
.OnlyPawns:
		mov	ecx, dword[rsp+4*(8*Black+Pawn)]
		mov	eax, ((0) shl 16) + ((2*EndgameScale_KPsK_index+White) shl 0)
		test	ecx, ecx
		jz	.OnlyPawnsWrite
		mov	edx, dword[rsp+4*(8*White+Pawn)]
		mov	eax, (((2*EndgameScale_KPsK_index+Black)) shl 8) + ((0) shl 0)
		test	edx, edx
		jz	.OnlyPawnsWrite
		xor	eax, eax
		cmp	ecx, 1
		jne	.OnlyPawnsWrite
		cmp	edx, 1
		jne	.OnlyPawnsWrite
		mov	eax, (((2*EndgameScale_KPKP_index+Black)) shl 8) + ((2*EndgameScale_KPKP_index+White) shl 0)
.OnlyPawnsWrite:
		mov	word[rsi+MaterialEntryEx.scalingFunction], ax  ; write both entries
.NotOnlyPawns:

.loop_lookup_done:
;============= set factor

		mov	eax, dword[pieceCountUs+4*(8*White+Pawn)]
		test	eax, eax
		jnz	.P1
		mov	ecx, r14d
		sub	ecx, r15d
		cmp	ecx, BishopValueMg
		jg	.P1
		mov	eax, 14
		mov	ecx, 4
		cmp	r15d, BishopValueMg
		cmovle	eax, ecx
		mov	ecx, SCALE_FACTOR_DRAW
		cmp	r14d, RookValueMg
		cmovl	eax, ecx
		mov	byte[rsi+MaterialEntryEx.factor+1*White], al
.P1:
		mov	eax, dword[pieceCountUs+4*(8*Black+Pawn)]
		test	eax, eax
		jnz	.P2
		mov	ecx, r15d
		sub	ecx, r14d
		cmp	ecx, BishopValueMg
		jg	.P2
		mov	eax, 14
		mov	ecx, 4
		cmp	r14d, BishopValueMg
		cmovle	eax, ecx
		mov	ecx, SCALE_FACTOR_DRAW
		cmp	r15d, RookValueMg
		cmovl	eax, ecx
		mov	byte[rsi+MaterialEntryEx.factor+1*Black], al
.P2:
;		.wBL	= (rsp + 16*4 +4*0)
;		.bBL	= (rsp + 16*4 +4*1)
;		.wBD	= (rsp + 16*4 +4*2)
;		.bBD	= (rsp + 16*4 +4*3)
		mov	ecx, 7
		mov	r10d, dword[pieceCountUs+4*(8*White+Bishop)]
		mov	edx, dword[pieceCountUs+4*(8*Black+Bishop)]
		cmp	r10d,edx
		jne	.NotOppBishop
		cmp	edx,1
		jne	.NotOppBishop
		mov	edx,dword[rsp + 4*(16 +0)]
		cmp	edx,dword[rsp + 4*(16 +3)]
		jne	.NotOppBishop
		mov	ecx, 2
;		mov	rdx,	((SCALE_FACTOR_BISHOP) shl 32) or ((SCALE_FACTOR_BISHOP) shl 40)
		
		cmp	r14d, BishopValueMg
		sete	ah
		cmp	r15d, BishopValueMg
		sete	al
		and	ah, al
		jnz	.Scale_Factor_Bishop
.NotOppBishop:
		mov	edx, ecx
		imul	ecx, dword[pieceCountUs+4*Pawn]
		add	ecx, 40
		cmp	ecx, SCALE_FACTOR_NORMAL
		jg	@f
		cmp	byte[rsi+MaterialEntryEx.factor+0],SCALE_FACTOR_NORMAL
		jne	@f
		mov	byte[rsi+MaterialEntryEx.factor+0], cl
@@:
		imul	edx, dword[pieceCountUs+4*(8*Black+Pawn)]
		add	edx, 40
		cmp	edx, SCALE_FACTOR_NORMAL
		jg	.ScaleFactorDone
		cmp	byte[rsi+MaterialEntryEx.factor+1*Black],SCALE_FACTOR_NORMAL
		jne	.ScaleFactorDone
		mov	byte[rsi+MaterialEntryEx.factor+1], dl
		jmp	.ScaleFactorDone
		calign	8
.Scale_Factor_Bishop:
		cmp	byte[rsi+MaterialEntryEx.factor+0],SCALE_FACTOR_NORMAL
		jne	.not_normal
		mov	byte[rsi+MaterialEntryEx.factor+0], SCALE_FACTOR_BISHOP
.not_normal:	
		cmp	byte[rsi+MaterialEntryEx.factor+1*Black],SCALE_FACTOR_NORMAL
		jne	.ScaleFactorDone
		mov	byte[rsi+MaterialEntryEx.factor+1], SCALE_FACTOR_BISHOP
.ScaleFactorDone:
;==============
		xor	eax, eax
		xor	r15d, r15d
.ColorLoop:
		xor	r10d, r10d	; partial index into quadratic
		mov	r14d, 1
 .Piece1Loop:
		xor	r11d, r11d
		mov	r13d, 1
		cmp	dword[r8+4*r14], r11d	;0
		je	.SkipPiece
  .Piece2Loop:
		mov	ecx, dword[DoMaterialEval_Data.QuadraticOurs+r10+4*r13]
		mov	edx, dword[DoMaterialEval_Data.QuadraticTheirs+r10+4*r13]
		imul	ecx, dword[r8+4*r13]
		imul	edx, dword[r9+4*r13]
		add	r11d, ecx
		add	r11d, edx
		inc	r13
		cmp	r13d, r14d
		jbe	.Piece2Loop

		lea	edx, [2*r15-1]
		imul	edx, dword[r8+4*r14]
		imul	r11d, edx
		sub	eax, r11d
.SkipPiece:
		inc	r14
		add	r10d, 8*4
		cmp	r14d, Queen
		jbe	.Piece1Loop

		xchg	r8, r9
		inc	r15
		cmp	r15d, 2
		jb	.ColorLoop

	; divide by 16, round towards zero
		cdq
		and	edx, 15
		add	eax, edx
		sar	eax, 4
		mov	word[rsi+MaterialEntryEx.value], ax
.foundfunction:
end macro

CalculateMaterialValue:
	virtual at rsp
		.PieceUs	rq	1
		.wP	rd	1
		.wN	rd	1
		.wB	rd	1
		.wR	rd	1
		.wQ	rd	1
			rd	1	;King
		.PieceThem	rq	1
		.bP	rd	1
		.bN	rd	1
		.bB	rd	1
		.bR	rd	1
		.bQ	rd	1
			rd	1	;King
		.wBL	rd	1
		.bBL	rd	1
		.wBD	rd	1
		.bBD	rd	1
			rd	20
		.lend	rb 0
	end virtual
	.localsize = (.lend-rsp+15) and -16
		
		push	rbx rsi rdi r12 r13 r14 r15
	 _chkstk_ms	rsp, .localsize
		sub	rsp, .localsize

		lea   rsi, [.PushToEdges]
		lea   rdi, [PushToEdges]
		mov   ecx, 64
	  rep movsb
		lea   rsi, [.PushToCorners]
		lea   rdi, [PushToCorners]
		mov   ecx, 64
	  rep movsb
		lea   rsi, [.PushClose]
		lea   rdi, [PushClose]
		mov   ecx, 8
	  rep movsb
		lea   rsi, [.PushAway]
		lea   rdi, [PushAway]
		mov   ecx, 8
	  rep movsb
		xor	eax, eax
		lea	rdi, [VoidPawn]
		mov	ecx, sizeof.PawnEntry
	rep	stosb
		mov	eax, 0xffff4040
		mov	dword[VoidPawn+PawnEntry.kingSquares], eax
		mov	byte[VoidPawn+PawnEntry.openFiles], 8*2
		;PawnEntry.asymmetry = 0
		;PawnEntry.score = 0

;                lea   rsi, [.KRPPKRPScaleFactors]
;                lea   rdi, [KRPPKRPScaleFactors]
;                mov   ecx, 8
;          rep movsb

		lea	rdi, [TableMaterialM]
		lea	rsi, [.TableMaterial]
		xor	edx,edx	;piece
	@1:
		xor	ecx,ecx
		imul	r8d, edx, 64*8	;dim 8x64
		add	r8, rdi
		lea	r9,[rsi+4*rdx]	;dim 4x16
	@2:

		mov	rax, rcx
		shr	rax, 3
		xor	rax, rcx
		and	eax, 0x1	;sq light or dark

		movzx	eax,word[r9+2*rax]
		mov	dword[r8+8*rcx],eax

		inc	ecx
		cmp	ecx,64
		jb	@2b
		inc	edx
		cmp	edx, 16
		jb	@1b

		xor	r8, r8
.loopPieceProm:
		lea	r11,[8*r8]
		lea	r11,[4*r11]	;x2 make it large
		movzx	rax, word[.TableMaterial+4*r8]	;qword[TableMaterialM+r11]
		movzx	rcx, word[.TableMaterial+4*r8+2]	;qword[TableMaterialM+r11+8]
		test	rax, rax
		jz	@f
		mov	r9, IndikatorwP
		mov	r10, IndikatorbP
		cmp	r8, 8
		cmovg	r9, r10
		sub	rax,r9
		sub	rcx,r9
@@:
		mov	dword[TablePromMatM+r11],eax
		mov	dword[TablePromMatM+r11+8],ecx
		inc	r8
		cmp	r8d, 16
		jb	.loopPieceProm

		xor	r8, r8
.loopPieceBound1:
		imul	r11, r8, 32
		xor	r9, r9
		movzx	edx, byte[.PocPiece+r8]
		xor	eax,eax
		mov	ecx,0x80000000
if	0
@@:
end if
.loopPieceBound2:
;		0x80000000
;		3=3
;		4=2
;		5=3
;		6=2
;White  = 0
;Black  = 1
;Pawn   = 2	;0010
;Knight = 3	;0011	poc=2
;Bishop = 4	;0100	poc=2
;Rook   = 5	;0101	poc=2
;Queen  = 6	;0110	poc=1
;King   = 7	;0111
		cmp	r9, rdx
		cmovg	eax, ecx
		mov	dword[CountNormalM+r11+4*r9],eax
		inc	r9
		cmp	r9d, 8
		jb	.loopPieceBound2
		
		inc	r8
		cmp	r8d, 16
		jb	.loopPieceBound1

lea	rsi,[.PocPiece]
lea	rdi,[POC]
xor	ecx,ecx
@@:
movzx	eax,byte[rsi+rcx]
imul	r9d, ecx, 16
or	eax, r9d
mov	dword[rdi+4*rcx],eax
inc	ecx
cmp	ecx,16
jb	@b
;	EndgameEval_FxnTable       rd 10+1
		lea   rsi, [.EndgameEval_FxnTable]
		lea   rdi, [EndgameEval_FxnTable]
		mov   ecx, 11
	  rep movsd
;	EndgameScale_FxnTable      rd 13+1
		lea   rsi, [.EndgameScale_FxnTable]
		lea   rdi, [EndgameScale_FxnTable]
		mov   ecx, 14
	  rep movsd

;
		xor	eax, eax
		mov	qword[.PieceUs], rax
		mov	qword[.PieceThem], rax
		
		mov	dword[.wQ], eax
;for (wQ = 0; wQ < 2; wQ++)
.loopwQ:
		xor	eax, eax
		mov	dword[.bQ], eax
;for (bQ = 0; bQ < 2; bQ++)
.loopbQ:
		xor	eax, eax
		mov	dword[.wR], eax
;for (wR = 0; wR < 3; wR++)
.loopwR:
		xor	eax, eax
		mov	dword[.bR], eax
;for (bR = 0; bR < 3; bR++)
.loopbR:
		xor	eax, eax
		mov	dword[.wBL], eax
;for (wBL = 0; wBL < 2; wBL++)
.loopwBL:
		xor	eax, eax
		mov	dword[.bBL], eax
;for (wBD = 0; wBD < 2; wBD++)
.loopbBL:
		xor	eax, eax
		mov	dword[.wBD], eax
;for (bBL = 0; bBL < 2; bBL++)
.loopwBD:
		xor	eax, eax
		mov	dword[.bBD], eax
;for (bBD = 0; bBD < 2; bBD++)
.loopbBD:
		xor	eax, eax
		mov	dword[.wN], eax
;for (wN = 0; wN < 3; wN++)
.loopwN:
		xor	eax, eax
		mov	dword[.bN], eax
;for (bN = 0; bN < 3; bN++)
.loopbN:
		xor	eax, eax
		mov	dword[.wP], eax
;for (wP = 0; wP < 9; wP++)
.loopwP:
		xor	eax, eax
		mov	dword[.bP], eax
;for (bP = 0; bP < 9; bP++)
.loopbP:
;{	c 	= 	wQ +
;			bQ  * 2  +
;			wR  * 2*2 +
;			bR  * 2*2*3 +
;			wBL * 2*2*3*3 +
;			wBD * 2*2*3*3*2 +
;			bBL * 2*2*3*3*2*2 +
;			bBD * 2*2*3*3*2*2*2 +
;			wN  * 2*2*3*3*2*2*2*2 +
;			bN  * 2*2*3*3*2*2*2*2*3 +
;			wP  * 2*2*3*3*2*2*2*2*3*3 +
;			bP  * 2*2*3*3*2*2*2*2*3*3*9;
;	c	&=	0x7ffff;
		mov	eax,dword[.wQ]
		mov	ecx,dword[.bQ]
		lea	eax,[rax+2*rcx]
		mov	ecx,dword[.wR]
		lea	eax,[rax+4*rcx]
		imul	ecx,dword[.bR], 2*2*3
		add	eax, ecx
		imul	ecx,dword[.wBL], 2*2*3*3
		add	eax, ecx
		imul	ecx,dword[.wBD], 2*2*3*3*2
		add	eax, ecx
		imul	ecx,dword[.bBL], 2*2*3*3*2*2
		add	eax, ecx
		imul	ecx,dword[.bBD], 2*2*3*3*2*2*2
		add	eax, ecx
		imul	ecx,dword[.wN], 2*2*3*3*2*2*2*2
		add	eax, ecx
		imul	ecx,dword[.bN], 2*2*3*3*2*2*2*2*3
		add	eax, ecx
		imul	ecx,dword[.wP], 2*2*3*3*2*2*2*2*3*3
		add	eax, ecx
		imul	ecx,dword[.bP], 2*2*3*3*2*2*2*2*3*3*9
		add	eax, ecx
;		and	eax, 0x7ffff
		mov	edi, eax
		mov	edx,dword[.wBL]
		add	edx,dword[.wBD]
		mov	ecx,dword[.bBL]
		add	ecx,dword[.bBD]

		mov	dword[.wB], edx
		mov	dword[.bB], ecx
		cmp	edx, 2
		sbb	edx, edx
		inc	edx
		cmp	ecx, 2
		sbb	ecx, ecx
		inc	ecx
		mov	dword[.PieceUs+4*(8*White+1)],edx
		mov	dword[.PieceUs+4*(8*Black+1)],ecx



		lea	r8, [.PieceUs]	;  pieceCount[Us]
		lea	r9, [.PieceThem]	;  pieceCount[Them]
		
		lea	rsi, [materialTableExM+8*rdi]
		lea	r11,[.SOF_Material]
		lea	r10,[.EOFMaterial]
		ComputeValue r8, r9, r11, r10

		inc	dword[.bP]
		mov	eax,dword[.bP]
		cmp	eax, 9
		jl	.loopbP
		inc	dword[.wP]
		mov	eax,dword[.wP]
		cmp	eax, 9
		jl	.loopwP
		inc	dword[.bN]
		mov	eax,dword[.bN]
		cmp	eax, 3
		jl	.loopbN
		inc	dword[.wN]
		mov	eax,dword[.wN]
		cmp	eax, 3
		jl	.loopwN
		inc	dword[.bBD]
		mov	eax,dword[.bBD]
		cmp	eax, 2
		jl	.loopbBD
		inc	dword[.wBD]
		mov	eax,dword[.wBD]
		cmp	eax, 2
		jl	.loopwBD
		inc	dword[.bBL]
		mov	eax,dword[.bBL]
		cmp	eax, 2
		jl	.loopbBL
		inc	dword[.wBL]
		mov	eax,dword[.wBL]
		cmp	eax, 2
		jl	.loopwBL
		inc	dword[.bR]
		mov	eax,dword[.bR]
		cmp	eax, 3
		jl	.loopbR
		inc	dword[.wR]
		mov	eax,dword[.wR]
		cmp	eax, 3
		jl	.loopwR
		inc	dword[.bQ]
		mov	eax,dword[.bQ]
		cmp	eax, 2
		jl	.loopbQ
		inc	dword[.wQ]
		mov	eax,dword[.wQ]
		cmp	eax, 2
		jl	.loopwQ

		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi rbx
		ret
;=============================== DATA
.PocPiece:
		db 0,0,9,2,1,2,1,0,0,0,9,2,1,2,1,0
.TableMaterial:
		dw	0			,	0
		dw	0			,	0
		dw	IndikatorwP		, IndikatorwP
		dw	IndikatorwN		, IndikatorwN
		dw	IndikatorwBD		, IndikatorwBL
		dw	IndikatorwR		, IndikatorwR
		dw	IndikatorwQ		, IndikatorwQ
		dw	0			,	0
		dw	0			,	0	;black
		dw	0			,	0
		dw	IndikatorbP		, IndikatorbP
		dw	IndikatorbN		, IndikatorbN
		dw	IndikatorbBD		, IndikatorbBL
		dw	IndikatorbR		, IndikatorbR
		dw	IndikatorbQ		, IndikatorbQ
		dw	0			,	0
.SOF_Material:
dq	EndgameEval_0_0	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_0factorx
dq	EndgameEval_0_1	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_1factorx
dq	EndgameEval_0_2	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_2factorx
dq	EndgameEval_0_3	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_3factorx
dq	EndgameEval_0_4	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_4factorx
dq	EndgameEval_0_5	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_5factorx
dq	EndgameEval_0_6	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_6factorx
dq	EndgameEval_0_7	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_7factorx
dq	EndgameEval_0_8	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_8factorx
dq	EndgameEval_0_9	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_9factorx
dq	EndgameEval_0_10	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_10factorx
dq	EndgameEval_0_11	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_11factorx
dq	EndgameEval_0_12	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_12factorx
dq	EndgameEval_0_13	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_13factorx
dq	EndgameEval_0_14	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_14factorx
dq	EndgameEval_0_15	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_15factorx
dq	EndgameEval_0_16	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_16factorx
dq	EndgameEval_0_17	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_17factorx
dq	EndgameEval_0_18	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_18factorx
dq	EndgameEval_0_19	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_19factorx
dq	EndgameEval_0_20	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_20factorx
dq	EndgameEval_0_21	,	EndgameEval_Draw_index*EvalFunc		;+	EndgameEval_0_21factorx
dq	EndgameEval_KNNK1	,	EndgameEval_KNNK_index*EvalFunc		;+	EndgameEval_KNNK1factorx
dq	EndgameEval_KNNK2	,	EndgameEval_KNNK_index*EvalFunc		;+	EndgameEval_KNNK2factorx
dq	EndgameEval_KPK1	,	EndgameEval_KPK_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KPK1factorx
dq	EndgameEval_KPK2	,	EndgameEval_KPK_index*EvalFunc		;+	EndgameEval_KPK2factorx
dq	EndgameEval_KBNK1	,	EndgameEval_KBNK_index*EvalFunc		;+	EndgameEval_KBNK1factorx
dq	EndgameEval_KBNK2	,	EndgameEval_KBNK_index*EvalFunc		;+	EndgameEval_KBNK2factorx
dq	EndgameEval_KBNK3	,	EndgameEval_KBNK_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KBNK3factorx
dq	EndgameEval_KBNK4	,	EndgameEval_KBNK_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KBNK4factorx
dq	EndgameEval_KRKP1	,	EndgameEval_KRKP_index*EvalFunc		;+	EndgameEval_KRKP1factorx
dq	EndgameEval_KRKP2	,	EndgameEval_KRKP_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KRKP2factorx
dq	EndgameEval_KRKB1	,	EndgameEval_KRKB_index*EvalFunc		;+	EndgameEval_KRKB1factorx
dq	EndgameEval_KRKB2	,	EndgameEval_KRKB_index*EvalFunc		;+	EndgameEval_KRKB2factorx
dq	EndgameEval_KRKB3	,	EndgameEval_KRKB_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KRKB3factorx
dq	EndgameEval_KRKB4	,	EndgameEval_KRKB_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KRKB4factorx
dq	EndgameEval_KRKN1	,	EndgameEval_KRKN_index*EvalFunc		;+	EndgameEval_KRKN1factorx
dq	EndgameEval_KRKN2	,	EndgameEval_KRKN_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KRKN2factorx
dq	EndgameEval_KQKP1	,	EndgameEval_KQKP_index*EvalFunc		;+	EndgameEval_KQKP1factorx
dq	EndgameEval_KQKP2	,	EndgameEval_KQKP_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KQKP2factorx
dq	EndgameEval_KQKR1	,	EndgameEval_KQKR_index*EvalFunc		;+	EndgameEval_KQKR1factorx
dq	EndgameEval_KQKR2	,	EndgameEval_KQKR_index*EvalFunc	+EvalBSTronger	;+	EndgameEval_KQKR2factorx

dq	EndgameEval_KNNKP1	,	EndgameEval_KNNKP_index*EvalFunc	;+	EndgameEval_KNNKP1factorx
dq	EndgameEval_KNNKP2	,	EndgameEval_KNNKP_index*EvalFunc +EvalBSTronger	;+	EndgameEval_KNNKP2factorx
;CPC	tgl 23-2-2019 scalefactor ditambah 'x'
dq	EndgameScale_KNPK1	,	EndgameScale_KNPK_index*ScaleFuncW		+	EndgameScale_KNPK1factorx
dq	EndgameScale_KNPK2	,	EndgameScale_KNPK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KNPK2factorx


dq	EndgameScale_KNPKB1	,	EndgameScale_KNPKB_index*ScaleFuncW		+	EndgameScale_KNPKB1factorx
dq	EndgameScale_KNPKB2	,	EndgameScale_KNPKB_index*ScaleFuncW		+	EndgameScale_KNPKB2factorx
dq	EndgameScale_KNPKB3	,	EndgameScale_KNPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KNPKB3factorx
dq	EndgameScale_KNPKB4	,	EndgameScale_KNPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KNPKB4factorx

dq	EndgameScale_KRPKR1	,	EndgameScale_KRPKR_index*ScaleFuncW		+	EndgameScale_KRPKR1factorx
dq	EndgameScale_KRPKR2	,	EndgameScale_KRPKR_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KRPKR2factorx
dq	EndgameScale_KRPKB1	,	EndgameScale_KRPKB_index*ScaleFuncW		+	EndgameScale_KRPKB1factorx
dq	EndgameScale_KRPKB2	,	EndgameScale_KRPKB_index*ScaleFuncW		+	EndgameScale_KRPKB2factorx
dq	EndgameScale_KRPKB3	,	EndgameScale_KRPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KRPKB3factorx
dq	EndgameScale_KRPKB4	,	EndgameScale_KRPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KRPKB4factorx
dq	EndgameScale_KBPKB1	,	EndgameScale_KBPKB_index*ScaleFuncW		+	EndgameScale_KBPKB1factorx
dq	EndgameScale_KBPKB2	,	EndgameScale_KBPKB_index*ScaleFuncW		+	EndgameScale_KBPKB2factorx
dq	EndgameScale_KBPKB3	,	EndgameScale_KBPKB_index*ScaleFuncW		+	EndgameScale_KBPKB3factorx
dq	EndgameScale_KBPKB4	,	EndgameScale_KBPKB_index*ScaleFuncW		+	EndgameScale_KBPKB4factorx
dq	EndgameScale_KBPKB5	,	EndgameScale_KBPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKB5factorx
dq	EndgameScale_KBPKB6	,	EndgameScale_KBPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKB6factorx
dq	EndgameScale_KBPKB7	,	EndgameScale_KBPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKB7factorx
dq	EndgameScale_KBPKB8	,	EndgameScale_KBPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKB8factorx
dq	EndgameScale_KBPKN1	,	EndgameScale_KBPKN_index*ScaleFuncW		+	EndgameScale_KBPKN1factorx
dq	EndgameScale_KBPKN2	,	EndgameScale_KBPKN_index*ScaleFuncW		+	EndgameScale_KBPKN2factorx
dq	EndgameScale_KBPKN3	,	EndgameScale_KBPKN_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKN3factorx
dq	EndgameScale_KBPKN4	,	EndgameScale_KBPKN_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPKN4factorx
;dq	EndgameScale_KBPPKB1	,	EndgameScale_KBPPKB_index*ScaleFuncW		+	EndgameScale_KBPPKB1factor
dq	EndgameScale_KBPPKB2	,	EndgameScale_KBPPKB_index*ScaleFuncW		+	EndgameScale_KBPPKB2factorx
dq	EndgameScale_KBPPKB3	,	EndgameScale_KBPPKB_index*ScaleFuncW		+	EndgameScale_KBPPKB3factorx
;dq	EndgameScale_KBPPKB4	,	EndgameScale_KBPPKB_index*ScaleFuncW		+	EndgameScale_KBPPKB4factor
;dq	EndgameScale_KBPPKB5	,	EndgameScale_KBPPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPPKB5factor
dq	EndgameScale_KBPPKB6	,	EndgameScale_KBPPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPPKB6factorx
dq	EndgameScale_KBPPKB7	,	EndgameScale_KBPPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPPKB7factorx
;dq	EndgameScale_KBPPKB8	,	EndgameScale_KBPPKB_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPPKB8factor
dq	EndgameScale_KRPPKRP1	,	EndgameScale_KRPPKRP_index*ScaleFuncW		+	EndgameScale_KRPPKRP1factorx
dq	EndgameScale_KRPPKRP2	,	EndgameScale_KRPPKRP_index*ScaleFuncW		+	EndgameScale_KRPPKRP2factorx
dq	EndgameScale_KRPPKRP3	,	EndgameScale_KRPPKRP_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KRPPKRP3factorx
dq	EndgameScale_KRPPKRP4	,	EndgameScale_KRPPKRP_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KRPPKRP4factorx
;scale factor none sosf isfactor
dq	EndgameScale_KBPPKB1	,		EndgameScale_KBPPKB1factorx
dq	EndgameScale_KBPPKB4	,		EndgameScale_KBPPKB4factorx
dq	EndgameScale_KBPPKB5	,		EndgameScale_KBPPKB5factorx
dq	EndgameScale_KBPPKB8	,		EndgameScale_KBPPKB8factorx

.ScoringInclude:
dq	EndgameScale_KBPsK1	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK1factor
dq	EndgameScale_KBPsK2	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK2factor
dq	EndgameScale_KBPsK3	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK3factor
dq	EndgameScale_KBPsK4	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK4factor
dq	EndgameScale_KBPsK5	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK5factor
dq	EndgameScale_KBPsK6	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK6factor
dq	EndgameScale_KBPsK7	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK7factor
dq	EndgameScale_KBPsK8	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK8factor
dq	EndgameScale_KBPsK9	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK9factor
dq	EndgameScale_KBPsK10	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK10factor
dq	EndgameScale_KBPsK11	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK11factor
dq	EndgameScale_KBPsK12	,	EndgameScale_KBPsK_index*ScaleFuncW		+	EndgameScale_KBPsK12factor
dq	EndgameScale_KBPsK13	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK13factor
dq	EndgameScale_KBPsK14	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK14factor
dq	EndgameScale_KBPsK15	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK15factor
dq	EndgameScale_KBPsK16	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK16factor
dq	EndgameScale_KBPsK17	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK17factor
dq	EndgameScale_KBPsK18	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK18factor
dq	EndgameScale_KBPsK19	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK19factor
dq	EndgameScale_KBPsK20	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK20factor
dq	EndgameScale_KBPsK21	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK21factor
dq	EndgameScale_KBPsK22	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK22factor
dq	EndgameScale_KBPsK23	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK23factor
dq	EndgameScale_KBPsK24	,	EndgameScale_KBPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KBPsK24factor

dq	EndgameScale_KQKRPs1	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs1factor
dq	EndgameScale_KQKRPs2	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs2factor
dq	EndgameScale_KQKRPs3	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs3factor
dq	EndgameScale_KQKRPs4	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs4factor
dq	EndgameScale_KQKRPs5	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs5factor
dq	EndgameScale_KQKRPs6	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs6factor
dq	EndgameScale_KQKRPs7	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs7factor
dq	EndgameScale_KQKRPs8	,	EndgameScale_KQKRPs_index*ScaleFuncW		+	EndgameScale_KQKRPs8factor
dq	EndgameScale_KQKRPs9	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs9factor
dq	EndgameScale_KQKRPs10	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs10factor
dq	EndgameScale_KQKRPs11	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs11factor
dq	EndgameScale_KQKRPs12	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs12factor
dq	EndgameScale_KQKRPs13	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs13factor
dq	EndgameScale_KQKRPs14	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs14factor
dq	EndgameScale_KQKRPs15	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs15factor
dq	EndgameScale_KQKRPs16	,	EndgameScale_KQKRPs_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KQKRPs16factor

dq	EndgameScale_KPsK1	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK1factor
dq	EndgameScale_KPsK2	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK2factor
dq	EndgameScale_KPsK3	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK3factor
dq	EndgameScale_KPsK4	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK4factor
dq	EndgameScale_KPsK5	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK5factor
dq	EndgameScale_KPsK6	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK6factor
dq	EndgameScale_KPsK7	,	EndgameScale_KPsK_index*ScaleFuncW		+	EndgameScale_KPsK7factor
dq	EndgameScale_KPsK8	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK8factor
dq	EndgameScale_KPsK9	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK9factor
dq	EndgameScale_KPsK10	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK10factor
dq	EndgameScale_KPsK11	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK11factor
dq	EndgameScale_KPsK12	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK12factor
dq	EndgameScale_KPsK13	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK13factor
dq	EndgameScale_KPsK14	,	EndgameScale_KPsK_index*ScaleFuncB	+ScaleBStronger	+	EndgameScale_KPsK14factor
dq	EndgameScale_KPKP0	,	EndgameScale_KPKP_index*ScaleFuncWB	+ScaleBStronger	+	EndgameScale_KPKP0factor

.EOFMaterial:
		dd 0

.PushToEdges:
db  100, 90, 80, 70, 70, 80, 90, 100
db   90, 70, 60, 50, 50, 60, 70,  90
db   80, 60, 40, 30, 30, 40, 60,  80
db   70, 50, 30, 20, 20, 30, 50,  70
db   70, 50, 30, 20, 20, 30, 50,  70
db   80, 60, 40, 30, 30, 40, 60,  80
db   90, 70, 60, 50, 50, 60, 70,  90
db  100, 90, 80, 70, 70, 80, 90, 100


.PushToCorners:
db    200, 190, 180, 170, 160, 150, 140, 130
db    190, 180, 170, 160, 150, 140, 130, 140
db    180, 170, 155, 140, 140, 125, 140, 150
db    170, 160, 140, 120, 110, 140, 150, 160
db    160, 150, 140, 110, 120, 140, 160, 170
db    150, 140, 125, 140, 140, 155, 170, 180
db    140, 130, 140, 150, 160, 170, 180, 190
db    130, 140, 150, 160, 170, 180, 190, 200


.PushClose: db	0, 0, 100, 80, 60, 40, 20, 10
.PushAway: db  0, 5, 20, 40, 60, 80, 90, 100
;.KRPPKRPScaleFactors: db 0, 9, 10, 14, 21, 44, 0, 0
;EndgameEval_KPK_index	= 1  ; KP vs K
;EndgameEval_KNNK_index	= 2  ; KNN vs K
;EndgameEval_KBNK_index	= 3  ; KBN vs K
;EndgameEval_KRKP_index	= 4  ; KR vs KP
;EndgameEval_KRKB_index	= 5  ; KR vs KB
;EndgameEval_KRKN_index	= 6  ; KR vs KN
;EndgameEval_KQKP_index	= 7  ; KQ vs KP
;EndgameEval_KQKR_index	= 8  ; KQ vs KR
;ENDGAME_EVAL_MAP_SIZE = 8  ; this should be number of functions added to the eval map
;EndgameEval_KXK_index	= 10 ; Generic mate lone king eval
;ENDGAME_EVAL_MAX_INDEX = 16

.EndgameEval_FxnTable:
			dd	0	;, 0
			dd	EndgameEval_KPK		;, EndgameEval_KPK_index
			dd	EndgameEval_KNNK	;, EndgameEval_KNNK_index
			dd	EndgameEval_KBNK	;, EndgameEval_KBNK_index
			dd	EndgameEval_KRKP	;, EndgameEval_KRKP_index
			dd	EndgameEval_KRKB	;, EndgameEval_KRKB_index
			dd	EndgameEval_KRKN	;, EndgameEval_KRKN_index
			dd	EndgameEval_KQKP	;, EndgameEval_KQKP_index
			dd	EndgameEval_KQKR	;, EndgameEval_KQKR_index
			dd	EndgameEval_KNNKP	;, EndgameEval_KNNKP_index
			dd	EndgameEval_KXK		;, EndgameEval_KXK_index
;EndgameScale_KNPK_index    = 1  ; KNP vs K
;EndgameScale_KNPKB_index   = 2  ; KNP vs KB
;EndgameScale_KRPKR_index   = 3  ; KRP vs KR
;EndgameScale_KRPKB_index   = 4  ; KRP vs KB
;EndgameScale_KBPKB_index   = 5  ; KBP vs KB
;EndgameScale_KBPKN_index   = 6  ; KBP vs KN
;EndgameScale_KBPPKB_index  = 7  ; KBPP vs KB
;EndgameScale_KRPPKRP_index = 8  ; KRPP vs KRP
;ENDGAME_SCALE_MAP_SIZE = 8  ; this should be number of functions added to the eval map
;EndgameScale_KBPsK_index   = 10 ; KB and pawns vs K
;EndgameScale_KQKRPs_index  = 11 ; KQ vs KR and pawns
;EndgameScale_KPsK_index    = 12 ; K and pawns vs K
;EndgameScale_KPKP_index    = 13 ; KP vs KP

.EndgameScale_FxnTable:
			dd	0	;, 0
			dd	EndgameScale_KNPK	;, EndgameScale_KNPK_index
			dd	EndgameScale_KNPKB	;, EndgameScale_KNPKB_index
			dd	EndgameScale_KRPKR	;, EndgameScale_KRPKR_index
			dd	EndgameScale_KRPKB	;, EndgameScale_KRPKB_index
			dd	EndgameScale_KBPKB	;, EndgameScale_KBPKB_index
			dd	EndgameScale_KBPKN	;, EndgameScale_KBPKN_index
			dd	EndgameScale_KBPPKB	;, EndgameScale_KBPPKB_index
			dd	EndgameScale_KRPPKRP	;, EndgameScale_KRPPKRP_index
			dd	0	;,0
			dd	EndgameScale_KBPsK	;, EndgameScale_KBPsK_index
			dd	EndgameScale_KQKRPs	;, EndgameScale_KQKRPs_index
			dd	EndgameScale_KPsK	;, EndgameScale_KPsK_index
			dd	EndgameScale_KPKP	;, EndgameScale_KPKP_index
