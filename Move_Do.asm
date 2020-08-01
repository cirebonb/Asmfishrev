macro Move_DoMacro PERUBAHAN

	; in: rbp  address of Pos
	;     rbx  address of State
	;     ecx  move
	;     edx  move is check
	;	r8 from
	;	r9 to
	local	TPDAbortSearch_PlyBigger, TPDCheckDraw_Cold, TPDCheckDraw_ColdRet, TPDCheckNext, TPDKeysMatch, SpecialRet2nd
	local	TPDAbortSearch_PlySmaller, SetCheckInfo_go, Castling, SpecialRet, EpCapture, Promotion, Special, SetEnPassant
	local	RightsRet, Rights, ResetEpRet, ResetEp, DoFull, MoveIsCheck, CaptureRet, Capture
	local	retcopy_static, checkmaterial, nonzerorule, TestLegalMove
	local	loopcheck, yescyclefound, nocyclefound, detectcycle, Done, exit_draw, ExitnPop, yescycleconfirm, cyclesearchfail, intocycle
	       push   rsi rdi r12 r13 r14 r15
Display 2, "Move_Do(move=%m1)%n"

;		mov   r8d, ecx
;		shr   r8d, 6
;		and   r8d, 63	; r8d = from
;		mov   r9d, ecx
;		and   r9d, 63	; r9d = to

	; load
		mov	esi, dword[rbp+Pos.sideToMove]
		movzx	r10d, byte[rbp+Pos.board+r8]	; r10 = FROM PIECE
		movzx	r11d, byte[rbp+Pos.board+r9]	; r11 = TO PIECE
		mov	r15, qword[Zobrist_side]
		xor	r15, qword[rbx+State.key]
		mov	r14, qword[rbx+State.pawnKey]
		mov	r12d, dword[rbx+State.rule50]
		mov	r13d, dword[rbx+State.materialIdx]
		_vmovq	xmm6, qword[rbx+State.psq]	; psq and npMaterial
;MaterialTabelSet	= 1
	; increment
		add	qword[rbp-Thread.rootPos+Thread.nodes], 1
		add	r12d, 0x010101
	; castling rights
		movzx	edx, word[rbx+State.epSquare]	; .epSquare + .castlingRights
		movzx	eax, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r8]
		or	al, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r9]
		and	al, dh
		jnz	Rights
RightsRet:
	; ep square
		cmp	dl, 64
		jb	ResetEp
ResetEpRet:
		mov	word[rbx+sizeof.State+State.epSquare], dx
		mov	byte[rbx+sizeof.State+State.capturedPiece], r11l
		mov	dword[rbx+State.currentMove],	ecx
	; capture
		shr	ecx, 12
		cmp	ecx, MOVE_TYPE_CASTLE
		je	Castling
		mov	eax, r11d
		and	eax, 7
		jnz	Capture
CaptureRet:
		xor	edx, edx
		movzx	eax, byte[rbp+Pos.pieceIdx+r8]
		mov	byte[rbp+Pos.pieceList+rax], r9l
		mov	byte[rbp+Pos.pieceIdx+r9], al
		mov	byte[rbp+Pos.board+r8], dl	;0
		mov	byte[rbp+Pos.board+r9], r10l
		bts	rdx, r8
		bts	rdx, r9
		mov	eax, r10d
		and	eax, 7
		xor	qword[rbp+Pos.typeBB+8*rax], rdx
		xor	qword[rbp+Pos.typeBB+8*rsi], rdx


		movsx   rax, byte[IsPawnMasks+r10]
	; move piece
		mov	r11d, r8d
		xor	r11d, r9d
		and	r11d, eax
		shl	r10d, 6+3
		mov	rdx, qword[Zobrist_Pieces+r10+8*r8]
		xor	rdx, qword[Zobrist_Pieces+r10+8*r9]
	     _vmovd	xmm1, dword[Scores_Pieces+r10+8*r8]
	     _vmovd	xmm2, dword[Scores_Pieces+r10+8*r9]
		xor	r15, rdx
		and	rdx, rax
		xor	r14, rdx
	    _vpsubd	xmm6, xmm6, xmm1
	    _vpaddd	xmm6, xmm6, xmm2
		shr	r10d, 6+3

		not	eax
		and	r12w, ax

	; special moves
		cmp	ecx, MOVE_TYPE_PROM
		jae	Special
		cmp	r11d, 16
		je	SetEnPassant
SpecialRet:
	; write remaining data to next state entry
	; r10 = from piece
	; ecx = move extension
	; point of change
		xor	esi, 1
SpecialRet2nd:
		add	rbx, sizeof.State
;MaterialTabelSet	= 1
		mov	dword[rbx+State.materialIdx], r13d
		mov	dword[rbp+Pos.sideToMove], esi
		mov	qword[rbx+State.key], r15
		mov	qword[rbx+State.pawnKey], r14
		_vmovq	qword[rbx+State.psq], xmm6
		mov	qword[rbx+State.rule50], r12
;==== repetition check
if PERUBAHAN = 1
	if MATERIALDRAW = 1
		_vmovq	xmm8, r13
	end if
		mov	r11, r15
		and	r15, qword[mainHash.mask]	;shl	r15, 5
                add	r15, qword[mainHash.table]
        prefetchnta	[r15]
	if MATERIALDRAW = 1
		test	r12l, r12l
		jz	.nonzerorule
	end if
		mov	eax, r12d
		cmp	ah, 4
	if USE_GAMECYCLE = 1
		jl	intocycle
	else
		jl	retcopy_static
	end if
		lea	r15, [rbx-4*sizeof.State+State.key]	; r9 = i
		mov	edx, 4
TPDCheckNext:
		cmp	r11, qword[r15]
		je	TPDKeysMatch
		sub	r15, 2*sizeof.State
		add	edx, 2
		cmp	dl, ah
		jle	TPDCheckNext
		jmp	@2f
TPDKeysMatch:
		cmp	byte[r15-State.key+State.onerep], 0
		je	@1f
		neg	edx
	@1:
		shr	eax, 16			; State.ply
		cmp	edx, eax
		jl	TPDAbortSearch_PlySmaller
		mov	byte[rbx+State.onerep], dl	;edx
	if USE_GAMECYCLE = 1
		mov	eax, r12d
	end if
	@2:

	if USE_GAMECYCLE = 1
intocycle:
		cmp	ah, 3
		jl	retcopy_static
		cmp	word[rsp+3*8], 0	;r12w alpha>=0
		jge	detectcycle
	end if
		jmp	retcopy_static
	if MATERIALDRAW = 1
		calign 8
	.nonzerorule:
		test	r13d, r13d
		js	retcopy_static
		cmp	byte[materialTableExM+MaterialEntryEx.evaluationFunction+8*r13], EndgameEval_Draw_index*2
		jne	retcopy_static
		xor	eax, eax
		_vmovq	xmm8, rax
		or	byte[rbx-1*sizeof.State+State.pvhit], JUMP_IMM_8
		cmp	byte[rbx-1*sizeof.State+State.givesCheck], al
		jne	retcopy_static
		jmp	exit_draw
	end if
		calign 8
else
		mov	eax, r12d
		cmp	ah, 4
		jl	retcopy_static
		lea	r11, [rbx-4*sizeof.State+State.key]
		mov	edx, 4
TPDCheckNext:
		cmp	r15, qword[r11]
		je	TPDKeysMatch
		add	edx, 2
		sub	r11, 2*sizeof.State
		cmp	dl, ah
		jle	TPDCheckNext
		jmp	retcopy_static
TPDKeysMatch:
		cmp	byte[r11-State.key+State.onerep], 0
		je	@1f
		neg	edx
	@1:
		mov	byte[rbx+State.onerep], dl	;edx
end if
retcopy_static:
		mov	r15, qword[rbp+Pos.typeBB+8*rsi]
		xor	esi, 1
		mov	r12, qword[rbp+Pos.typeBB+8*rsi]	; r12 = their pieces
		mov	r14, qword[rbp+Pos.typeBB+8*King]
		shl	esi, 6+3		; used on .DoFull & .SetCheckInfo_go
		mov	r13, r15		; r13 = our pieces
		lea	rdi, [r12+r13]		; rdi = all pieces
		and	r15, r14
		xor	r14, r15
             _tzcnt	r15, r15	        ; r15 = our king
             _tzcnt	r14, r14	        ; r14 = their king

		movsx	eax, byte[rbx-1*sizeof.State+State.givesCheck]
		test	eax, eax
		jz	SetCheckInfo_go
MoveIsCheck:
		test	ecx, ecx
		jnz	DoFull			;if Castle, Prom, EnPassant
		mov	rax, qword[rbx-1*sizeof.State+State.dcCandidates]
		bt	rax, r8
		jc	DoFull
		and	r10d, 7
		xor	rax, rax
		bts	rax, r9
		and	rax, qword[rbx-1*sizeof.State+State.checkSq+8*r10]
		jmp	SetCheckInfo_go
		calign 8
.DoFull:
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
; in eax
		mov	edi, r11d
		and	edi, 8
	; remove piece r11(=rdi+rax) on to square r9

		xor	edx, edx
		mov	r12w, dx	;plyfromnul update!
		bts	rdx, r9
		not	rdx
		and	qword[rbp+Pos.typeBB+rdi], rdx
		and	qword[rbp+Pos.typeBB+8*rax], rdx

		movzx	edi, byte[rbp+Pos.pieceEnd+r11]
		movzx	edx, byte[rbp+Pos.pieceList+rdi-1]
		movzx	eax, byte[rbp+Pos.pieceIdx+r9]
		dec	edi
		mov	byte[rbp+Pos.pieceEnd+r11], dil
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64

		movsx	rax, byte[IsPawnMasks+r11]
		shl	r11d, 6+3
		mov	rdx, qword[Zobrist_Pieces+r11+8*r9]
		xor	r15, rdx
		and	rdx, rax
		xor	r14, rdx
;MaterialTabelSet	= 1
		sub	r13d, dword[TableMaterialM+r11+8*r9]
	     _vmovq	xmm1, qword[Scores_Pieces+r11+8*r9]
	    _vpsubd	xmm6, xmm6, xmm1

if PERUBAHAN = 1 & MATERIALDRAW = 1
	not	eax
	and	eax, r13d
	jns	CaptureRet
	shr	r11d,9-2
	cmp	edi,dword[POC+r11]
	jne	CaptureRet
		mov	eax, dword[rbp+Pos.pieceEnd+8*White+Knight]
		and	eax, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)
		cmp	al,3
		jge	CaptureRet
		cmp	ah,3
		jge	CaptureRet
		mov	dl,ah	;push...
		shr	eax, 16
		cmp	al,3
		jge	CaptureRet
		cmp	ah,2
		jge	CaptureRet
		mov	eax, dword[rbp+Pos.pieceEnd+8*Black+Knight]
		and	eax, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)
		cmp	al,3
		jge	CaptureRet
		cmp	ah,3
		jge	CaptureRet
		mov	dh,ah	;push again
		shr	eax, 16
		cmp	al,3
		jge	CaptureRet
		cmp	ah,2
		jge	CaptureRet
		cmp	dl,2
		jne	@1f
		mov	rax, LightSquares
		mov	r11, qword[rbp+Pos.typeBB+8*Bishop]
		and	r11, qword[rbp+Pos.typeBB+8*White]
		test	r11, rax
		jz	CaptureRet
		not	rax	;mov	rax, DarkSquares
		test	r11, rax
		jz	CaptureRet
@1:
		cmp	dh,2
		jne	@2f
		mov	rax, LightSquares
		mov	r11, qword[rbp+Pos.typeBB+8*Bishop]
		and	r11, qword[rbp+Pos.typeBB+8*Black]
		test	r11, rax
		jz	CaptureRet
		not	rax	;mov	rax, DarkSquares
		test	r11, rax
		jz	CaptureRet
@2:
		and	r13d, 0x7fffffff
end if
		jmp	CaptureRet
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   8
ResetEp:
		movzx	eax, dl
		and	al, 7
		xor	r15, qword[Zobrist_Ep+8*rax]
		mov	dl, 64
		jmp	ResetEpRet
	     calign   8
Rights:
		xor	dh, al
		xor	r15, qword[Zobrist_Castling+8*rax]
		jmp	RightsRet
	     calign   8
SetEnPassant:
		mov	edx, esi
		xor	esi, 1
		shl	edx, 6+3
		lea	r11, [r8+r9]
		shr	r11d, 1
		mov	rax, qword[WhitePawnAttacks+rdx+8*r11]
		and	rax, qword[rbp+Pos.typeBB+8*Pawn]
	       test	rax, qword[rbp+Pos.typeBB+8*rsi]
		 jz	SpecialRet2nd
		mov	byte[rbx+sizeof.State+State.epSquare], r11l
		and	r11d, 7
		xor	r15, qword[Zobrist_Ep+8*r11]
		jmp	SpecialRet2nd
	     calign   8
Special:
		cmp	ecx, MOVE_TYPE_EPCAP
		je	EpCapture

Promotion:
		lea   r11d, [rcx-MOVE_TYPE_PROM+8*rsi+Knight]

		movzx	edi, byte[rbp+Pos.pieceEnd+r10]
		dec	edi
		movzx	edx, byte[rbp+Pos.pieceList+rdi]
		movzx	eax, byte[rbp+Pos.pieceIdx+r9]
		mov	byte[rbp+Pos.pieceEnd+r10], dil

		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64

		movzx	edx, byte[rbp+Pos.pieceEnd+r11]
		mov	byte[rbp+Pos.pieceIdx+r9], dl
		mov	byte[rbp+Pos.pieceList+rdx], r9l
		inc	edx
		mov	byte[rbp+Pos.pieceEnd+r11], dl
		mov	byte[rbp+Pos.board+r9], r11l

	; remove pawn r10 on square r9
		shl	r10d, 6+3
		mov	rax, qword[Zobrist_Pieces+r10+8*r9]
	     _vmovq	xmm1, qword[Scores_Pieces+r10+8*r9]
	    _vpsubd	xmm6, xmm6, xmm1
		xor	r15, rax
		xor	r14, rax
		shr	r10d, 6+3
		; place piece r11 on square r9
		lea	edi, [rcx-MOVE_TYPE_PROM+Knight]	; piece
		xor	eax, eax
		bts	rax, r9
		xor	qword[rbp+Pos.typeBB+8*Pawn], rax	;clear pawn bit
		or	qword[rbp+Pos.typeBB+8*rdi], rax	;place bit on piece

		and	edx, 15
		shl	r11d, 6+3
		xor	r15, qword[Zobrist_Pieces+r11+8*r9]
	     _vmovq	xmm1, qword[Scores_Pieces+r11+8*r9]
	    _vpaddd	xmm6, xmm6, xmm1
;MaterialTabelSet	= 1
		lea	eax, [8*r9]
		xor	eax, r9d
		and	eax, 8
		shr	r11, 9-5	;=5	;5
		add	r13d, dword[TablePromMatM+r11+rax]	;32
		or	r13d, dword[CountNormalM+r11+4*rdx]	;64 v
if PERUBAHAN = 1 & MATERIALDRAW = 1
	jns	SpecialRet

	if	1
		cmp	edi, Bishop
		jne	SpecialRet
		cmp	edx, 2
		jne	SpecialRet
	else
		lea	edx,[rdx+8*rdi]
		cmp	edx, ((Bishop*8)+2)
		jne	SpecialRet
	end if
		mov	eax, dword[rbp+Pos.pieceEnd+8*White+Knight]
		and	eax, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)
		cmp	al,3
		jge	SpecialRet
		cmp	ah,3
		jge	SpecialRet
		mov	dl,ah	;push...
		shr	eax, 16
		cmp	al,3
		jge	SpecialRet
		cmp	ah,2
		jge	SpecialRet
		mov	eax, dword[rbp+Pos.pieceEnd+8*Black+Knight]
		and	eax, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)
		cmp	al,3
		jge	SpecialRet
		cmp	ah,3
		jge	SpecialRet
		mov	dh,ah	;push again
		shr	eax, 16
		cmp	al,3
		jge	SpecialRet
		cmp	ah,2
		jge	SpecialRet
		cmp	dl,2
		jne	@1f
		mov	rax, LightSquares
		mov	r11, qword[rbp+Pos.typeBB+8*Bishop]
		and	r11, qword[rbp+Pos.typeBB+8*White]
		test	r11, rax
		jz	SpecialRet
		not	rax	;mov	rax, DarkSquares
		test	r11, rax
		jz	SpecialRet
@1:
		cmp	dh,2
		jne	@2f
		mov	rax, LightSquares
		mov	r11, qword[rbp+Pos.typeBB+8*Bishop]
		and	r11, qword[rbp+Pos.typeBB+8*Black]
		test	r11, rax
		jz	SpecialRet
		not	rax	;mov	rax, DarkSquares
		test	r11, rax
		jz	SpecialRet
@2:
		and	r13d, 0x7fffffff
end if
		jmp	SpecialRet
	     calign   8
EpCapture:
	; remove pawn r10^8 on square r11=r9+8*(2*esi-1)
		lea	r11d, [2*rsi-1]
		lea	r11d, [r9+8*r11]
		xor	r10, 8
		xor	esi, 1
		movzx	edi, byte[rbp+Pos.pieceEnd+r10]

		xor	eax, eax
		bts	rax, r11
		not	rax
		and	qword[rbp+Pos.typeBB+8*Pawn], rax
		and	qword[rbp+Pos.typeBB+8*rsi], rax

		dec	edi

		movzx	edx, byte[rbp+Pos.pieceList+rdi]
		movzx	eax, byte[rbp+Pos.pieceIdx+r11]
		mov	byte[rbp+Pos.pieceEnd+r10], dil
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceList+rax], dl
		mov	byte[rbp+Pos.pieceList+rdi], 64
		mov	byte[rbp+Pos.board+r11], 0
		mov	byte[rbx+sizeof.State+State.capturedPiece], r10l

		shl	r10d, 6+3
		mov	rdx, qword[Zobrist_Pieces+r10+8*r11]
		_vmovq	xmm1, qword[Scores_Pieces+r10+8*r11]
;MaterialTabelSet	= 1
		sub	r13d, dword[TableMaterialM+r10];+8*r11]
		xor	r15, rdx
		xor	r14, rdx
		_vpsubd	xmm6, xmm6, xmm1
		
		shr	r10d, 9
		jmp	SpecialRet2nd

	     calign   8
Castling:
		mov   edx, r8d
		and   edx, 56
		cmp   r9d, r8d
		sbb   eax, eax
		lea   ecx, [rdx+4*rax+FILE_G]		;king sq
		lea   edx, [rdx+2*rax+FILE_F]		;rook sq
		lea   r11d, [r10-King+Rook]		;rook piece

		mov   byte[rbp+Pos.board+r8], 0
		mov   byte[rbp+Pos.board+r9], 0
		mov   byte[rbp+Pos.board+rcx], r10l
		mov   byte[rbp+Pos.board+rdx], r11l

		movzx   eax, byte[rbp+Pos.pieceIdx+r8]	;idx king
		movzx   edi, byte[rbp+Pos.pieceIdx+r9]	;idx rook
		mov	byte[rbp+Pos.pieceIdx+rcx], al
		mov	byte[rbp+Pos.pieceList+rax], cl
		mov	byte[rbx+sizeof.State+State.capturedPiece], ah	;0

		movzx   eax, byte[rbp+Pos.pieceEnd+r11]	;rook piece
		movzx   r11d, byte[rbp+Pos.pieceList+rax-1]
		mov	byte[rbp+Pos.pieceList+rdi], r11l
		mov	byte[rbp+Pos.pieceList+rax-1], dl
		movzx   eax, byte[rbp+Pos.pieceIdx+r11]
		mov	byte[rbp+Pos.pieceIdx+rdx], al
		mov	byte[rbp+Pos.pieceIdx+r11], dil

		shl	r10d, 6+3
		xor	r15, qword[Zobrist_Pieces+r10+8*r8]
		xor	r15, qword[Zobrist_Pieces+r10-((King-Rook) shl 9)+8*r9]
		xor	r15, qword[Zobrist_Pieces+r10+8*rcx]
		xor	r15, qword[Zobrist_Pieces+r10-((King-Rook) shl 9)+8*rdx]

	     _vmovd	xmm1, dword[Scores_Pieces+r10+8*r8]
	     _vmovd	xmm2, dword[Scores_Pieces+r10-((King-Rook) shl 9)+8*r9]
	    _vpsubd	xmm6, xmm6, xmm1
	    _vpsubd	xmm6, xmm6, xmm2
	     _vmovd	xmm1, dword[Scores_Pieces+r10+8*rcx]
	     _vmovd	xmm2, dword[Scores_Pieces+r10-((King-Rook) shl 9)+8*rdx]
	    _vpaddd	xmm6, xmm6, xmm1
	    _vpaddd	xmm6, xmm6, xmm2
                shr	r10d, 6+3

		mov	rax, qword[rbp+Pos.typeBB+8*rsi]
		mov	rdi, qword[rbp+Pos.typeBB+8*King]
		mov	r11, qword[rbp+Pos.typeBB+8*Rook]
		btr	rax, r8
		btr	rax, r9
		bts	rax, rcx
		bts	rax, rdx
		btr	rdi, r8
		bts	rdi, rcx
		btr	r11, r9
		bts	r11, rdx
		mov	qword[rbp+Pos.typeBB+8*rsi], rax
		mov	qword[rbp+Pos.typeBB+8*King], rdi
		mov	qword[rbp+Pos.typeBB+8*Rook], r11
		mov	ecx, MOVE_TYPE_CASTLE
		jmp	SpecialRet
	 calign	  8

SetCheckInfo_go:
;in r14, rsi, rbx, r12, r13, rdi
		mov	qword[rbx+State.checkersBB], rax
		mov	qword[rbx+State.Occupied], rdi
		mov	qword[rbx+State.ourKsq], r15	;include State.flags+improving+depthpruned+movelead
		mov	byte[rbx+State.ksq], r14l

		mov	rax, qword[WhitePawnAttacks+rsi+8*r14]
		mov	rdx, qword[KnightAttacks+8*r14]
		mov	qword[rbx+State.checkSq+8*Pawn], rax
		mov	qword[rbx+State.checkSq+8*Knight], rdx
		shr	esi, 6+3
      BishopAttacks   rax, r14, rdi, r11
	RookAttacks   rdx, r14, rdi, r11
		xor	r11, r11
		mov	qword[rbx+State.checkSq+8*Bishop], rax
		mov	qword[rbx+State.checkSq+8*Rook], rdx
		 or	rax, rdx
		mov	qword[rbx+State.checkSq+8*Queen], rax
		mov	qword[rbx+State.checkSq+8*King], r11
		mov	qword[rbx+State.tte],r11
	; for their king r14 clobered
     SliderBlockers2	rax, r13, r14, r11,\
			rdi, r12,\
			rcx, rdx, r10
		mov	qword[rbx+State.pinnersForKing+8*rsi], r11
		mov	qword[rbx+State.blockersForKing+8*rsi], rax
		and	rax, r13
		mov	qword[rbx+State.dcCandidates], rax

	; for our king	r15 clobered
		xor	r11, r11
		xor	esi, 1
     SliderBlockers	rax, r12, r15, r11,\
			rdi, r13,\
			rcx, rdx, r10
		mov	qword[rbx+State.pinnersForKing+8*rsi], r11
		mov	qword[rbx+State.blockersForKing+8*rsi], rax
		and	rax, r13
		mov	qword[rbx+State.pinned], rax

if PERUBAHAN = 1
	if MATERIALDRAW = 1
		_vmovq	rax, xmm8
		test	eax, eax
		jz	TestLegalMove
	end if
		mov	edx, dword[rbx+State.rule50]
		cmp	edx, (MAX_PLY-1) shl 16
		ja	TPDAbortSearch_PlyBigger
		cmp	dl, 100
		jl	ExitnPop
		mov	r11, qword[rbx+State.checkersBB]
		test	r11, r11
	if MATERIALDRAW = 1
		jz	exit_draw
TestLegalMove:
	else
		jz	TPDAbortSearch_PlySmaller	; draw if we are not in check
	end if
		push	r8 r9
		sub	rsp, ((MAX_MOVES*sizeof.ExtMove) and (-16))
		mov	rdi, rsp			; rdi = buffer moves
		call	Gen_Legal
		mov	rcx, rsp
		add	rsp, ((MAX_MOVES*sizeof.ExtMove) and (-16))
		pop	r9 r8
		cmp	rdi, rcx
	if MATERIALDRAW = 1
		jne	exit_draw
	else
		jne	TPDAbortSearch_PlySmaller	; draw if we are not in check
	end if
		mov	dword[rbx-1*sizeof.State+State.ltte+MainHashEntry.eval_], 0x7cff7cff	;(((VALUE_MATE-1) shl 16) or (VALUE_MATE-1))
		movzx	eax, byte[rbx+State.ply]
;		lea	eax, [rax-VALUE_MATE]
		sub	eax, VALUE_MATE
		neg	eax
		xor	ecx, ecx
ExitnPop:
		pop	r15 r14 r13 r12 rdi rsi
		ret
	calign   8
TPDAbortSearch_PlyBigger:
		xor	eax, eax
		cmp	rax, qword[rbx+State.checkersBB]
	if MATERIALDRAW = 1
		jz	exit_draw
	else
		jz	ExitnPop
	end if
		call	Evaluate
		cmp	eax, VALUE_MATE-1
		cmove	eax, edi
		neg	eax
		xor	ecx, ecx	;draw flags
		pop	r15 r14 r13 r12 rdi rsi
		ret
	if MATERIALDRAW = 1
		calign	8
exit_draw:
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]
		mov	word[rbx-1*sizeof.State+State.movelead1], cx		;node with multicut zero
		pop	r15 r14 r13 r12 rdi rsi
		mov	edi, VALUE_NONE	;-)
		xor	eax, eax
		ret
	end if
	if USE_GAMECYCLE = 1
		calign 8
detectcycle:	;not used	r13
		movzx	edx, ah
		shr	eax, 16
		neg	eax
		add	eax, edx
		lea	r14d, [rdx-3]
		mov	rdi, qword[rbp+Pos.typeBB+8*0]
		or	rdi, qword[rbp+Pos.typeBB+8*1]
		lea	r15, [rbx-3*sizeof.State+State.key]
	loopcheck:
		mov	r13, r11
		xor	r13, qword[r15]
		mov	edx, r13d
		and	edx, 0x1fff	;H1
		cmp	r13, qword[cuckoo+rdx*8]
		je	yescyclefound
		mov	edx, r13d
		shr	edx, 16
		and	edx, 0x1fff	;H2
		cmp	r13, qword[cuckoo+rdx*8]
		je	yescyclefound
	nocyclefound:
		sub	r15, 2*sizeof.State
		sub	r14d, 2
		jns	loopcheck
		jmp	retcopy_static
	calign 8
	yescyclefound:
		movzx	r13, word[cuckooMove+rdx*2]
		test	rdi, qword[BetweenBB+r13*8]
		jnz	nocyclefound
		cmp	eax, r14d
		jl	yescycleconfirm

		mov	edx, r10d
		and	edx, 63
		cmp	byte[rbp+Pos.board+rdx],dh
		jne	.Yespiece
		mov	edx, r10d
		shr	edx, 6
		and	edx, 63
	.Yespiece:
		movzx	edx, byte[rbp+Pos.board+rdx]
		shr	edx, 3
		cmp	edx, esi
		jne	nocyclefound
		cmp	byte[r15-State.key+State.onerep],0
		je	retcopy_static
;		or	byte[rbx-1*sizeof.State+State.cycNextFound],-1
		jmp	yescycleconfirm
	end if
	calign	8
TPDAbortSearch_PlySmaller:
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]
		mov	word[rbx-1*sizeof.State+State.movelead0], cx
yescycleconfirm:
		xor	eax, eax
end if
Done:
		pop	r15 r14 r13 r12 rdi rsi
		ret


end macro
