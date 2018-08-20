macro Move_DoMacro PERUBAHAN

	; in: rbp  address of Pos
	;     rbx  address of State
	;     ecx  move
	;     edx  move is check
	;	r8 from
	;	r9 to
	local	TPDAbortSearch_PlyBigger, TPDCheckDraw_Cold, TPDCheckDraw_ColdRet, TPDCheckNext, TPDKeysDontMatch, SpecialRet2nd
	local	TPDReturn, TPDAbortSearch_PlySmaller, SetCheckInfo_go, Castling, SpecialRet, EpCapture, Promotion, Special, DoublePawn
	local	RightsRet, Rights, ResetEpRet, ResetEp, DoFull, MoveIsCheck, CaptureRet, Capture, SendResult, SendResult0, CheckersDone, copy_static, Return, Before_Return
	       push   rsi rdi r12 r13 r14 r15

        ; stack is unaligned at this point

Display 2, "Move_Do(move=%m1)%n"

;		mov   r8d, ecx
;		shr   r8d, 6
;		and   r8d, 63	; r8d = from
;		mov   r9d, ecx
;		and   r9d, 63	; r9d = to

;ProfileInc moveUnpack
;ProfileInc Move_Do

		mov	esi, dword[rbp+Pos.sideToMove]
		movzx	r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
		movzx	r11d, byte[rbp+Pos.board+r9]     ; r11 = TO PIECE

		_vmovq	xmm15, qword[Zobrist_side]
		_vmovq	xmm5, qword[rbx+State.key]
		_vmovq	xmm4, qword[rbx+State.pawnKey]
		_vmovq	xmm3, qword[rbx+State.materialKey]
		_vmovq	xmm6, qword[rbx+State.psq]       ; psq and npMaterial
		_vpxor	xmm5, xmm5, xmm15

		add	qword[rbp-Thread.rootPos+Thread.nodes], 1

	; update rule50 and pliesFromNull and capturedPiece
		mov	eax, dword[rbx+State.rule50]
		add	eax, 0x010101
		mov	dword[rbx+sizeof.State+State.rule50], eax
		mov	dword[rbx+State.currentMove],	ecx		;+.excludedMove cant exten not zero
		mov	byte[rbx+sizeof.State+State.capturedPiece], r11l

	; castling rights
		movzx	edx, byte[rbx+State.castlingRights]
		movzx	eax, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r8]
		or	al, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r9]
		and	al, dl
		jnz	Rights
RightsRet:
		mov	byte[rbx+sizeof.State+State.castlingRights], dl
	; ep square
		movzx	eax, byte[rbx+State.epSquare]
		cmp	eax, 64
		jb	ResetEp
		mov	byte[rbx+sizeof.State+State.epSquare], al
ResetEpRet:
	; capture
;		mov	eax, r11d		shift down
		shr	ecx, 12
		cmp	ecx, MOVE_TYPE_CASTLE
		je	Castling
		mov	eax, r11d
		and	eax, 7
		jnz	Capture
CaptureRet:
	; move piece
		mov	r11d, r8d
		xor	r11d, r9d

		xor	edx, edx
		mov	byte[rbp+Pos.board+r8], dl	;0
		mov	byte[rbp+Pos.board+r9], r10l
		bts	rdx, r8
		_vmovq   xmm8, rdx
		bts	rdx, r9
		_vmovq   xmm9, rdx
		mov	eax, r10d
		and	eax, 7
		xor	qword[rbp+Pos.typeBB+8*rax], rdx
		xor	qword[rbp+Pos.typeBB+8*rsi], rdx

		movzx	eax, byte[rbp+Pos.pieceIdx+r8]
		mov	byte[rbp+Pos.pieceList+rax], r9l
		mov	byte[rbp+Pos.pieceIdx+r9], al

	      movsx   rax, byte[IsPawnMasks+r10]
		and   r11d, eax
		shl   r10d, 6+3
		mov   rdx, qword[Zobrist_Pieces+r10+8*r8]
		xor   rdx, qword[Zobrist_Pieces+r10+8*r9]
	     _vmovd   xmm1, dword[Scores_Pieces+r10+8*r8]
	     _vmovd   xmm2, dword[Scores_Pieces+r10+8*r9]
	     _vmovq   xmm7, rdx
	     _vpxor   xmm5, xmm5, xmm7
		and   rdx, rax
	     _vmovq   xmm7, rdx
	     _vpxor   xmm4, xmm4, xmm7
	    _vpsubd   xmm6, xmm6, xmm1
	    _vpaddd   xmm6, xmm6, xmm2
		shr   r10d, 6+3

		not   eax
		and   byte[rbx+sizeof.State+State.rule50], al

	; special moves
		cmp   ecx, MOVE_TYPE_PROM
		jae   Special
		cmp   r11d, 16
		 je   DoublePawn
SpecialRet:

	; write remaining data to next state entry

	; r10 = from piece
	; rax = is check
	; ecx = move
	; point of change
		xor   esi, 1
SpecialRet2nd:
		add   rbx, sizeof.State

		mov   dword[rbp+Pos.sideToMove], esi
	     _vmovq   rax, xmm5
;	     _vmovq   qword[rbx+State.key], xmm5
	     _vmovq   qword[rbx+State.pawnKey], xmm4
	     _vmovq   qword[rbx+State.materialKey], xmm3
	     _vmovq   qword[rbx+State.psq], xmm6
		mov   qword[rbx+State.key], rax

                and	rax, qword[mainHash.mask]
                shl	rax, 5
                add	rax, qword[mainHash.table]
        prefetchnta	[rax]


		;SetCheckInfo.AfterPrologue
		mov   r15, qword[rbp+Pos.typeBB+8*rsi]
		xor   esi, 1
		mov   r14, qword[rbp+Pos.typeBB+8*rsi]
		shl   esi, 6+3		; used on .DoFull
		mov   r13, r15		; r13 = our pieces
		mov   r12, r14		; r12 = their pieces
		mov   rdi, r15
		 or   rdi, r14		; rdi = all pieces
		and   r15, qword[rbp+Pos.typeBB+8*King]
		and   r14, qword[rbp+Pos.typeBB+8*King]
             _tzcnt   r15, r15	        ; r15 = our king
             _tzcnt   r14, r14	        ; r14 = their king

		movsx	eax, byte[rbx-1*sizeof.State+State.givesCheck]
		test	eax, eax
		jz	SetCheckInfo_go
MoveIsCheck:
		test	ecx, ecx
		jnz	DoFull
		_vmovq	r11, xmm8	;not initialize in castling so move in here
	; r11 = from		BB
		test	qword[rbx+State.dcCandidates-sizeof.State], r11
		jnz	DoFull
		and	r10d, 7
		mov	rax, qword[rbx+State.checkSq-sizeof.State+8*r10]
		_vmovq	r10, xmm9
	; r10 = to + from	BB
		xor	r10, r11
		and	rax, r10
		jmp	SetCheckInfo_go
DoFull:
		mov	eax, esi
		xor	eax, 1 shl (6+3)

		mov	rax, qword[WhitePawnAttacks+rax+8*r15]
		and	rax, qword[rbp+Pos.typeBB+8*Pawn]

		mov	r11, qword[KnightAttacks+8*r15]
		and	r11, qword[rbp+Pos.typeBB+8*Knight]
		 or	rax, r11

	RookAttacks	r11, r15, rdi, r10
		mov	rdx, qword[rbp+Pos.typeBB+8*Queen]
		mov	r10, qword[rbp+Pos.typeBB+8*Rook]
		 or	r10, rdx
		and	r11, r10
		 or	rax, r11

      BishopAttacks	r11, r15, rdi, r10
		or	rdx, qword[rbp+Pos.typeBB+8*Bishop]
		and	r11, rdx
		 or	rax, r11

		and	rax, r12

		jmp	SetCheckInfo_go
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	     calign   8
Capture:
		mov	r12d, r11d
		and	r12d, 8
	; remove piece r11(=r12+rax) on to square r9

		xor	edx, edx
		bts	rdx, r9
		not	rdx
		and	qword[rbp+Pos.typeBB+r12], rdx
		and	qword[rbp+Pos.typeBB+8*rax], rdx

		movsx	rax, byte[IsPawnMasks+r11]
		movzx	edi, byte[rbp+Pos.pieceEnd+r11]
		dec	edi
		mov	r12d, edi		;let use r12!
		and	r12d, 15
		shl	r11d, 6+3
		mov	rdx, qword[Zobrist_Pieces+r11+8*r9]
	     _vmovq	xmm7, rdx
	     _vpxor	xmm5, xmm5, xmm7
		and	rdx, rax
	     _vmovq	xmm7, rdx
	     _vpxor	xmm4, xmm4, xmm7
	     _vmovq	xmm7, qword[Zobrist_Pieces+r11+8*r12]
	     _vpxor	xmm3, xmm3, xmm7
	     _vmovq	xmm1, qword[Scores_Pieces+r11+8*r9]
	    _vpsubd	xmm6, xmm6, xmm1
		shr	r11d, 6+3
		movzx	edx, byte[rbp+Pos.pieceList+rdi]
		movzx	eax, byte[rbp+Pos.pieceIdx+r9]
		mov	byte[rbp+Pos.pieceEnd+r11], dil
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64
		mov	byte[rbx+sizeof.State+State.rule50], ah	;0
		jmp	CaptureRet

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   8
ResetEp:
		and   eax, 7
	     _vmovq   xmm7, qword[Zobrist_Ep+8*rax]
	     _vpxor   xmm5, xmm5, xmm7

		mov   byte[rbx+sizeof.State+State.epSquare], 64
		jmp   ResetEpRet

	     calign   8
Rights:
		xor   edx, eax
	     _vmovq   xmm7, qword[Zobrist_Castling+8*rax]
	     _vpxor   xmm5, xmm5, xmm7

		jmp   RightsRet

	     calign   8
DoublePawn:
		mov	edx, esi
		shl	edx, 6+3
		lea	r12, [r8+r9]
		shr	r12d, 1
		mov	rax, qword[WhitePawnAttacks+rdx+8*r12]
		xor	esi, 1
		and	rax, qword[rbp+Pos.typeBB+8*Pawn]
	       test	rax, qword[rbp+Pos.typeBB+8*rsi]
		 jz	SpecialRet2nd
		mov	byte[rbx+State.epSquare+sizeof.State], r12l
		and	r12d, 7
	     _vmovq	xmm7, qword[Zobrist_Ep+8*r12]
	     _vpxor	xmm5, xmm5, xmm7
		jmp	SpecialRet2nd


	     calign   8
Special:
		cmp   ecx, MOVE_TYPE_EPCAP
		 je   EpCapture

Promotion:
		lea   r14d, [rcx-MOVE_TYPE_PROM+8*rsi+Knight]

		movzx	edi, byte[rbp+Pos.pieceEnd+r10]
		dec	edi
		movzx	edx, byte[rbp+Pos.pieceList+rdi]
		movzx	eax, byte[rbp+Pos.pieceIdx+r9]
		mov	byte[rbp+Pos.pieceEnd+r10], dil
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64

		movzx	edx, byte[rbp+Pos.pieceEnd+r14]
		mov	byte[rbp+Pos.pieceIdx+r9], dl
		mov	byte[rbp+Pos.pieceList+rdx], r9l
		inc	edx
		mov	byte[rbp+Pos.pieceEnd+r14], dl
		mov	byte[rbp+Pos.board+r9], r14l

	; remove pawn r10 on square r9
		and	edi, 15		;replacing...	and   rdx, qword[rbp+Pos.typeBB+8*rsi];_popcnt   rax, rdx, r12
		shl	r10d, 6+3
	     _vmovq	xmm7, qword[Zobrist_Pieces+r10+8*r9]
	     _vpxor	xmm5, xmm5, xmm7
	     _vpxor	xmm4, xmm4, xmm7
	     _vmovq	xmm7, qword[Zobrist_Pieces+r10+8*rdi]	;ax]
	     _vpxor	xmm3, xmm3, xmm7
	     _vmovq	xmm1, qword[Scores_Pieces+r10+8*r9]
	    _vpsubd	xmm6, xmm6, xmm1
		shr	r10d, 6+3
		; place piece r14 on square r9
		mov	edi, r14d
		and	edi, 7
		
		xor	eax,eax
		bts	rax, r9
		xor	qword[rbp+Pos.typeBB+8*Pawn], rax	;clear pawn bit
		or	qword[rbp+Pos.typeBB+8*rdi], rax	;place bit on piece
		and	edx, 15		;replacing ...	and   rax, qword[rbp+Pos.typeBB+8*rsi]; _popcnt   rax, rax, r12	;was r8
		shl	r14d, 6+3
	     _vmovq	xmm7, qword[Zobrist_Pieces+r14+8*r9]
	     _vpxor	xmm5, xmm5, xmm7
	     _vmovq	xmm7, qword[Zobrist_Pieces+r14+8*(rdx-1)]	;^=  Zobrist::psq[promotion][pieceCount[promotion]-1]; allready ^ Zobrist::psq[pc][pieceCount[pc]];
	     _vpxor	xmm3, xmm3, xmm7
	     _vmovq	xmm1, qword[Scores_Pieces+r14+8*r9]
	    _vpaddd	xmm6, xmm6, xmm1
		jmp	SpecialRet
	     calign   8
EpCapture:
	; remove pawn r10^8 on square r14=r9+8*(2*esi-1)
		lea	r14d, [2*rsi-1]
		lea	r14d, [r9+8*r14]
		xor	r10, 8
		xor	esi, 1
		movzx	edi, byte[rbp+Pos.pieceEnd+r10]

xor	eax, eax
bts	rax, r14
not	rax
and	qword[rbp+Pos.typeBB+8*Pawn], rax
and	qword[rbp+Pos.typeBB+8*rsi], rax

;		mov	rdx, qword[rbp+Pos.typeBB+8*Pawn]
;		mov	rax, qword[rbp+Pos.typeBB+8*rsi]
;		btr	rax, r14
;		btr	rdx, r14
;		mov	qword[rbp+Pos.typeBB+8*Pawn], rdx
;		mov	qword[rbp+Pos.typeBB+8*rsi], rax
		dec	edi
		mov	eax, edi
		and	eax, 15	;replacing...	and   rdi, rdx, _popcnt   rdi, rdi, rdx
		shl	r10d, 6+3
		_vmovq	xmm7, qword[Zobrist_Pieces+r10+8*r14]
		_vpxor	xmm5, xmm5, xmm7
		_vpxor	xmm4, xmm4, xmm7
		_vmovq	xmm7, qword[Zobrist_Pieces+r10+8*rax]	;di]
		_vpxor	xmm3, xmm3, xmm7
		_vmovq	xmm1, qword[Scores_Pieces+r10+8*r14]
		_vpsubd	xmm6, xmm6, xmm1
                shr	r10d, 6+3
		movzx	edx, byte[rbp+Pos.pieceList+rdi]
		movzx	eax, byte[rbp+Pos.pieceIdx+r14]
		mov	byte[rbp+Pos.pieceEnd+r10], dil
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64
		mov	byte[rbp+Pos.board+r14], 0	;moved
		mov	byte[rbx+sizeof.State+State.rule50], ah	;0
		mov	byte[rbx+sizeof.State+State.capturedPiece], r10l
		jmp	SpecialRet2nd


	     calign   8
Castling:
	; r8 = kfrom
	; r9 = rfrom
	; ecx = kto
	; edx = rto
	; r10 = ourking
	; r11 = our rook

	; fix things caused by kingXrook encoding

	; move the pieces
		mov   edx, r8d
		and   edx, 56
		cmp   r9d, r8d
		sbb   eax, eax
		lea   r14d, [rdx+4*rax+FILE_G]
		lea   edx, [rdx+2*rax+FILE_F]
		lea   r11d, [r10-King+Rook]

		mov   byte[rbp+Pos.board+r8], 0
		mov   byte[rbp+Pos.board+r9], 0
		mov   byte[rbp+Pos.board+r14], r10l
		mov   byte[rbp+Pos.board+rdx], r11l

	  ;    movzx   eax, byte[rbp+Pos.pieceIdx+r8]
	  ;    movzx   edi, byte[rbp+Pos.pieceIdx+r9]
	  ;      mov   byte[rbp+Pos.pieceList+rax], r14l
	  ;      mov   byte[rbp+Pos.pieceList+rdi], dl
	  ;      mov   byte[rbp+Pos.pieceIdx+r14], al
	  ;      mov   byte[rbp+Pos.pieceIdx+rdx], dil
	  ; no! above not enough instructions! official stockfish has
	  ;  castling rook moved to the back of the list
	  ;  of course this for absolutely no good reason
	      movzx   eax, byte[rbp+Pos.pieceIdx+r8]
	      movzx   edi, byte[rbp+Pos.pieceIdx+r9]
		mov   byte[rbp+Pos.pieceIdx+r14], al
		mov   byte[rbp+Pos.pieceIdx+rdx], dil
		mov   byte[rbp+Pos.pieceList+rax], r14l
		mov   byte[rbp+Pos.pieceList+rdi], dl
		mov   byte[rbx+sizeof.State+State.capturedPiece], ah	;0
	; now move rook to the back of the list
	      movzx   eax, byte[rbp+Pos.pieceEnd+r11]
;		sub   eax, 1
	      dec	eax
	      movzx   r12d, byte[rbp+Pos.pieceList+rax]
	       ;;xchg   byte[rbp+Pos.pieceList+rdi], byte[rbp+Pos.pieceList+rax]
	      movzx   edx, byte[rbp+Pos.pieceList+rdi]
	      movzx   r13d, byte[rbp+Pos.pieceList+rax]
		mov   byte[rbp+Pos.pieceList+rdi], r13l
		mov   byte[rbp+Pos.pieceList+rax], dl
	       ;;xchg   byte[rbp+Pos.pieceIdx+rdx], byte[rbp+Pos.pieceIdx+r12]
	      movzx   edi, byte[rbp+Pos.pieceIdx+rdx]
	      movzx   eax, byte[rbp+Pos.pieceIdx+r12]
		mov   byte[rbp+Pos.pieceIdx+rdx], al
		mov   byte[rbp+Pos.pieceIdx+r12], dil

		shl   r10d, 6+3
		shl   r11d, 6+3

		mov   rax, qword[Zobrist_Pieces+r10+8*r8]
		xor   rax, qword[Zobrist_Pieces+r11+8*r9]
		xor   rax, qword[Zobrist_Pieces+r10+8*r14]
		xor   rax, qword[Zobrist_Pieces+r11+8*rdx]
	     _vmovq   xmm7, rax
	     _vpxor   xmm5, xmm5, xmm7

	     _vmovd   xmm1, dword[Scores_Pieces+r10+8*r8]
	     _vmovd   xmm2, dword[Scores_Pieces+r11+8*r9]
	    _vpsubd   xmm6, xmm6, xmm1
	    _vpsubd   xmm6, xmm6, xmm2
	     _vmovd   xmm1, dword[Scores_Pieces+r10+8*r14]
	     _vmovd   xmm2, dword[Scores_Pieces+r11+8*rdx]
	    _vpaddd   xmm6, xmm6, xmm1
	    _vpaddd   xmm6, xmm6, xmm2
                shr   r10d, 6+3

		mov   rax, qword[rbp+Pos.typeBB+8*rsi]
		mov   r13, qword[rbp+Pos.typeBB+8*King]
		mov   r11, qword[rbp+Pos.typeBB+8*Rook]
		btr   rax, r8
		btr   rax, r9
		bts   rax, r14
		bts   rax, rdx
		btr   r13, r8
		bts   r13, r14
		btr   r11, r9
		bts   r11, rdx
		mov   qword[rbp+Pos.typeBB+8*rsi], rax
		mov   qword[rbp+Pos.typeBB+8*King], r13
		mov   qword[rbp+Pos.typeBB+8*Rook], r11
		jmp   SpecialRet
	 calign	  8
;end SetCheckInfo_go
SetCheckInfo_go:
;in r14, rsi, rbx, r12, r13, rdi
		mov	qword[rbx+State.checkersBB], rax
		mov	qword[rbx+State.Occupied], rdi
		mov	qword[rbx+State.ourKsq], r15	;include State.flags+improving+drawrep+draw3rep
		mov	byte[rbx+State.ksq], r14l

		mov   rax, qword[WhitePawnAttacks+rsi+8*r14]
		mov   rdx, qword[KnightAttacks+8*r14]
		mov   qword[rbx+State.checkSq+8*Pawn], rax
		mov   qword[rbx+State.checkSq+8*Knight], rdx
		shr   esi, 6+3
      BishopAttacks   rax, r14, rdi, r11
	RookAttacks   rdx, r14, rdi, r11
		xor   r11, r11
		mov   qword[rbx+State.checkSq+8*Bishop], rax
		mov   qword[rbx+State.checkSq+8*Rook], rdx
		 or   rax, rdx
		mov   qword[rbx+State.checkSq+8*Queen], rax
		mov   qword[rbx+State.checkSq+8*King], r11
		mov   qword[rbx+State.tte],r11

	; for their king r14 clobered
;		_vmovq   xmm10, r9
		xor   eax, eax
     SliderBlockers2   rax, r13, r14, r11,\
		      rdi, r12,\
		      rcx, rdx, r10
		mov   qword[rbx+State.pinnersForKing+8*rsi], r11
		mov   qword[rbx+State.blockersForKing+8*rsi], rax
		and   rax, r13
		mov   qword[rbx+State.dcCandidates], rax
;		_vmovq	r9, xmm10

	; for our king	r15 clobered
		xor   r11, r11
		xor   esi, 1
		xor   eax, eax
     SliderBlockers   rax, r12, r15, r11,\
		      rdi, r13,\
		      rcx, rdx, r10
		mov   qword[rbx+State.pinnersForKing+8*rsi], r11
		mov   qword[rbx+State.blockersForKing+8*rsi], rax
		and   rax, r13
		mov   qword[rbx+State.pinned], rax

if PERUBAHAN = 1
;.TestPosDraw:
		mov	edx, dword[rbx+State.rule50]
		cmp	edx, (MAX_PLY-1) shl 16
		ja	TPDAbortSearch_PlyBigger
		cmp	dl, 100
		jae	TPDCheckDraw_Cold
TPDCheckDraw_ColdRet:
		mov	eax, edx
		shr	eax, 8
		cmp	dl, al
		cmova	edx, eax
		cmp	dl, 4
		jb	TPDReturn		; carry flag = 1
		movzx	edx, dl
		movzx	eax, ah
		xor	edi, edi
		mov	r11, qword[rbx+State.key]
		imul	r10, rdx, -sizeof.State	; r10 = end
		mov	r12, -4*sizeof.State	; r9 = i
		sub	eax, 5			; eax = ply-i-2
		xor	ecx, ecx			; ecx = -cnt
TPDCheckNext:
		cdq				; get the sign of ply-i-2
		cmp	r11, qword[rbx+r12+State.key]
		jne	TPDKeysDontMatch
		cmp	ecx, edx			; 1+cnt + (ply-1>i) == 2 is the same as
		 je	TPDAbortSearch_PlySmaller	; -cnt == sign(ply-i-2)
		dec	ecx				; rep counter?
		test	rdi, rdi
		cmovz	rdi, r12
TPDKeysDontMatch:
		sub	r12, 2*sizeof.State
		sub	eax, 2
		cmp	r12, r10
		jge	TPDCheckNext
		;carry flag = 1
		test	rdi, rdi
		jnz	copy_static
TPDReturn:
	if MATERIALDRAW = 1
		mov	rax, qword[rbx+State.materialKey]
		mov	rdx, rax
		and	edx, MATERIAL_HASH_ENTRY_COUNT-1
		shl	edx, 4
		add	rdx, qword[rbp+Pos.materialTable]
		cmp	qword[rdx+MaterialEntry.key], rax
		jne	Before_Return
		xor	eax, eax
		cmp	byte[rdx+MaterialEntry.evaluationFunction], ENDGAME_EVAL_MAX_INDEX
		je	Return
	Before_Return:
	end if
		cmp	byte[signals.stop], -1
Return:
		pop	r15 r14 r13 r12 rdi rsi
		ret
	 calign	  8
TPDAbortSearch_PlySmaller:
		xor	eax, eax	;eax = VALUE_DRAW
		pop	r15 r14 r13 r12 rdi rsi
		ret
	 calign   8
TPDAbortSearch_PlyBigger:
		xor	eax, eax	;eax = VALUE_DRAW
		;Display	0, "info string draw PlyBigger === %i2%n"
		cmp	rax, qword[rbx+State.checkersBB]
		jz	SendResult0
		call	Evaluate
		neg	eax
		xor	ecx, ecx
SendResult0:
		pop	r15 r14 r13 r12 rdi rsi
		ret
	 calign	  8
copy_static:
;		mov	eax, dword[rbx+rdi+State.pawnKey+4]
;		cmp	eax, dword[rbx+State.pawnKey+4]
;		jne	TPDReturn
		mov	rax, qword[rbx+rdi+State.tte]
		mov	qword[rbx+State.tte], rax
		mov	rax, qword[rbx+rdi+State.ltte]
		mov	qword[rbx+State.ltte], rax
		mov	edx, dword[rbx+rdi+State.staticEval]
		mov	al, byte[rbx+rdi+State.flags]
		and	al, JUMP_IMM_2+JUMP_IMM_3
;		or	al,JUMP_IMM_5
		mov	dword[rbx+State.staticEval], edx
		mov	byte[rbx+State.flags], al
		jmp	TPDReturn
	 calign   8
TPDCheckDraw_Cold:
		mov	r11, qword[rbx+State.checkersBB]
		test	r11, r11
		 jz	SendResult	; draw if we are not in check
		push	rdx r8 r9
		sub	rsp, ((MAX_MOVES*sizeof.ExtMove) and (-16))
		mov	rdi, rsp			; rdi = buffer moves
		call	Gen_Legal
		mov	rcx,rsp
		add	rsp, ((MAX_MOVES*sizeof.ExtMove) and (-16))
		pop	r9 r8 rdx
		cmp	rdi, rcx
		je	TPDCheckDraw_ColdRet		; otherwise fall through
		; draw if we have some moves
SendResult:
		xor	eax, eax	;eax = VALUE_DRAW
end if
		pop	r15 r14 r13 r12 rdi rsi
		ret
;end SetCheckInfo_go

end macro
; many bugs can be caught in DoMove
; we catch the caller of DoMove and make sure that the move is legal
;===========================================================================
if MATERIALDRAW = 1
	     calign   16
Move_Do__ProbCut:
	       call	Move_GivesCheck	;.HaveFromTo
		mov	byte[rbx+State.givesCheck], al
		lea	r14d,[rax+1]
		mov	r14,[TableQsearch_NonPv+r14*8]
		movzx	eax, byte[rbp+Pos.board+r8]	;r8 & r9 output from Move_GivesCheck
		shl	eax, 6
		add	eax, r9d
		shl	eax, 2+4+6
		add	rax, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx+State.counterMoves], rax
		mov	r15l, 0
end if
	     calign   16
Move_Do__Root:
Move_Do__QSearch:
Move_Do__Search:
Move_Do1:	Move_DoMacro 1

	     calign   16, Move_Do0
if MATERIALDRAW = 0
Move_Do__ProbCut:
	       call	Move_GivesCheck	;.HaveFromTo
		mov	byte[rbx+State.givesCheck], al
		lea	r14d,[rax+1]
		mov	r14,[TableQsearch_NonPv+r14*8]
		movzx	eax, byte[rbp+Pos.board+r8]	;r8 & r9 output from Move_GivesCheck
		shl	eax, 6
		add	eax, r9d
		shl	eax, 2+4+6
		add	rax, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx+State.counterMoves], rax
		mov	r15l, 0
end if
Move_Do__UciParseMoves:
Move_Do__PerftGen_Root:
Move_Do__PerftGen_Branch:
Move_Do__ExtractPonderFromTT:
Move_Do__EasyMoveMng:
Move_Do__RootMove_InsertPVInTT:
Move_Do__Tablebase_ProbeAB:
Move_Do__Tablebase_ProbeWDL:
Move_Do__Tablebase_ProbeDTZNoEP:
Move_Do__Tablebase_ProbeDTZ:
Move_Do__Tablebase_RootProbe:
Move_Do__Tablebase_RootProbeWDL:
Move_Do0:	Move_DoMacro 0
