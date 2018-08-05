
	     calign   16
Move_Undo:
	; in: rbp  address of Pos
	;     rbx  address of State
	;     ecx  move

	       push   rsi

Display 2, "Move_Undo(move=%m1)%n"


	      movzx	r11d, byte[rbx+State.capturedPiece]      ; r11 = TO PIECE
	      mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]
		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to

	      movzx   r10d, byte[rbp+Pos.board+r9]	       ; r10 = FROM PIECE
	      mov   esi, dword[rbp+Pos.sideToMove]
		xor   esi, 1

		xor   edx, edx
		bts   rdx, r8
		bts   rdx, r9

		mov   eax, r10d
		and   eax, 7	;used in also castle

		sub   rbx, sizeof.State
		mov   dword[rbp+Pos.sideToMove], esi
		mov   byte[rbp+Pos.board+r8], r10l
		mov   byte[rbp+Pos.board+r9], r11l
		xor   qword[rbp+Pos.typeBB+8*rax], rdx
		xor   qword[rbp+Pos.typeBB+8*rsi], rdx

		cmp   ecx, MOVE_TYPE_PROM shl 12
		jae   .Special

	      movzx   eax, byte[rbp+Pos.pieceIdx+r9]
		mov   byte[rbp+Pos.pieceList+rax], r8l
		mov   byte[rbp+Pos.pieceIdx+r8], al
		mov   eax, r11d 		; save a copy of captured piece

		and   r11d, 7
		jnz   .Captured
		pop   rsi
		ret


	     calign   8
.Captured:
		xor	esi, 1
		btr	rdx, r8			; only square r9 is set
		or	qword[rbp+Pos.typeBB+8*r11], rdx
		or	qword[rbp+Pos.typeBB+8*rsi], rdx

		movzx	edx, byte[rbp+Pos.pieceEnd+rax]
		mov	byte[rbp+Pos.pieceIdx+r9], dl
		mov	byte[rbp+Pos.pieceList+rdx], r9l
		inc	edx
		mov	byte[rbp+Pos.pieceEnd+rax], dl

		pop	rsi
		ret


	     calign   8
.Special:
		shr   ecx, 12
		cmp   ecx, MOVE_TYPE_EPCAP
		 ja   .Castle

	      movzx   ecx, byte[rbp+Pos.pieceIdx+r9]	;dont use edx
		mov   byte[rbp+Pos.pieceList+rcx], r8l
		mov   byte[rbp+Pos.pieceIdx+r8], cl

		 je   .EpCapture
;		xor   edx, edx

.Prom:
	; change promoted piece back to pawn on r8d
;		lea	ecx, [rcx-MOVE_TYPE_PROM+Knight]
		btr	rdx, r9				; only square r8 is set
		or	qword[rbp+Pos.typeBB+8*Pawn], rdx
		xor	qword[rbp+Pos.typeBB+8*rax], rdx
;		lea	eax, [8*rsi+rcx]

;		movzx	eax, byte[rbp+Pos.pieceIdx+r8]	;lookinline 77	;ecx

		movzx	eax, byte[rbp+Pos.pieceEnd+r10]		;eax
		dec	eax					;eax
		mov	byte[rbp+Pos.pieceEnd+r10], al		;al
		movzx	edx, byte[rbp+Pos.pieceList+rax]	;rax


		mov	byte[rbp+Pos.pieceIdx+rdx], cl		;cl
		mov	byte[rbp+Pos.pieceList+rcx], dl		;rcx
		mov	byte[rbp+Pos.pieceList+rax], 64		;rax

		lea	r10d, [8*rsi+Pawn]
		mov	byte[rbp+Pos.board+r8], r10l	;al
		movzx	edx, byte[rbp+Pos.pieceEnd+r10]	;8*rsi+Pawn]
		mov	byte[rbp+Pos.pieceIdx+r8], dl
		mov	byte[rbp+Pos.pieceList+rdx], r8l
		inc	edx
		mov	byte[rbp+Pos.pieceEnd+r10], dl	;8*rsi+Pawn], dl

		mov	eax, r11d	;used in .PromCapture
		and	r11d, 7
		jnz	.PromCapture
		pop	rsi
		ret

.PromCapture:
		xor	esi, 1
		xor	edx, edx
		bts	rdx, r9
		or	qword[rbp+Pos.typeBB+8*r11], rdx
		or	qword[rbp+Pos.typeBB+8*rsi], rdx

		movzx	edx, byte[rbp+Pos.pieceEnd+rax]
		mov	byte[rbp+Pos.pieceIdx+r9], dl
		mov	byte[rbp+Pos.pieceList+rdx], r9l
		inc	edx
		mov	byte[rbp+Pos.pieceEnd+rax], dl
		pop	rsi
		ret


	     calign   8
.EpCapture:
	; place 8*rsi+Pawn on square rcx
		xor	edx, edx
		lea	ecx, [2*rsi-1]
		lea	ecx, [r9+8*rcx]
		xor	esi, 1
		mov	byte[rbp+Pos.board+r9], dl	;0
		mov	byte[rbp+Pos.board+rcx], r11l
		bts	rdx, rcx
		or	qword[rbp+Pos.typeBB+8*Pawn], rdx
		or	qword[rbp+Pos.typeBB+8*rsi], rdx

		movzx	eax, byte[rbp+Pos.pieceEnd+r11]
		mov	byte[rbp+Pos.pieceIdx+rcx], al
		mov	byte[rbp+Pos.pieceList+rax], cl
		inc	eax
		mov	byte[rbp+Pos.pieceEnd+r11], al
		pop	rsi
		ret


	     calign   8
.Castle:
		xor   qword[rbp+Pos.typeBB+8*rax], rdx
		xor   qword[rbp+Pos.typeBB+8*rsi], rdx

		lea   r11d, [8*rsi+Rook]
		lea   r10d, [r11+2]	;[8*rsi+King]
		mov   edx, r8d
		and   edx, 56
		cmp   r9d, r8d
		sbb   eax, eax
		lea   ecx, [rdx+4*rax+FILE_G]
		lea   edx, [rdx+2*rax+FILE_F]

		mov   byte[rbp+Pos.board+rcx], ch	;0
		mov   byte[rbp+Pos.board+rdx], ch	;0
		mov   byte[rbp+Pos.board+r8], r10l
		mov   byte[rbp+Pos.board+r9], r11l

	       push   rdi

	      movzx   eax, byte[rbp+Pos.pieceIdx+rcx]
	      movzx   edi, byte[rbp+Pos.pieceIdx+rdx]
		mov   byte[rbp+Pos.pieceList+rax], r8l
		mov   byte[rbp+Pos.pieceList+rdi], r9l
		mov   byte[rbp+Pos.pieceIdx+r8], al
		mov   byte[rbp+Pos.pieceIdx+r9], dil
	; now move rook to the back of the list
	      movzx   eax, byte[rbp+Pos.pieceEnd+r11]
;		sub   eax, 1
	      dec	eax
	      movzx   r10d, byte[rbp+Pos.pieceList+rax]
	       ;;xchg   byte[rbp+Pos.pieceList+rdi], byte[rbp+Pos.pieceList+rax]
	      movzx   r9d, byte[rbp+Pos.pieceList+rdi]
	      movzx   r11d, byte[rbp+Pos.pieceList+rax]
		mov   byte[rbp+Pos.pieceList+rdi], r11l
		mov   byte[rbp+Pos.pieceList+rax], r9l
	       ;;xchg   byte[rbp+Pos.pieceIdx+rdx], byte[rbp+Pos.pieceIdx+r12]
	      movzx   edi, byte[rbp+Pos.pieceIdx+r9]
	      movzx   r11d, byte[rbp+Pos.pieceIdx+r10]
		mov   byte[rbp+Pos.pieceIdx+r9], r11l
		mov   byte[rbp+Pos.pieceIdx+r10], dil
		pop   rdi

		mov   rax, qword[rbp+Pos.typeBB+8*rsi]
		mov   r10, qword[rbp+Pos.typeBB+8*King]
		mov   r11, qword[rbp+Pos.typeBB+8*Rook]
		btr   rax, rcx
		btr   rax, rdx
		bts   rax, r8
		bts   rax, r9
		btr   r10, rcx
		bts   r10, r8
		btr   r11, rdx
		bts   r11, r9
		mov   qword[rbp+Pos.typeBB+8*rsi], rax
		mov   qword[rbp+Pos.typeBB+8*King], r10
		mov   qword[rbp+Pos.typeBB+8*Rook], r11

		pop   rsi
		ret

