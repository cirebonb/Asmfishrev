
macro MainHash_Save lcopy, entr, key16, vvalue, bbounder, ddepth, mmove, InCheck
  local dont_write_move, write_everything, write_after_move, exit, done

		mov	r11, entr
		shr	r11d, 3  -  1
		and	r11d, 3 shl 1
	     Assert   b, r11d, 3 shl 1, 'index 3 in cluster encountered'
		neg	r11
		lea	r11, [8*3+3*r11]

		cmp	key16, word[r11+entr]
		jne	write_everything
if mmove eq 0
		;Qsearch :	1. BOUND_UPPER	PvNode=0 at Saving Result (no bestmove)
		;		2. BOUND_NONE	at Saving Staticvalue
		;SearchMacros	1. BOUND_NONE	at Saving Staticvalue
	if bbounder eq BOUND_UPPER
		mov	rcx, qword[entr]
		mov	al, ch			;.depth
		sub	al, 4
		cmp	al, ddepth
		jl	write_after_move
		mov	qword[lcopy], rcx
	else
		mov	rax, qword[entr]
		cmp	rax, qword[lcopy]
		jne	write_after_move	;there is collission...	rewrite
	end if
		jmp	exit
else if bbounder eq BOUND_EXACT			;SearchMacrosSYZYGY
		jmp	write_after_move
else	;mmove eq eax
		;Qsearch :	1. BOUND_LOWER	at Saving Result (found bestmove)
		;		2. r10l		PvNode=1 at Saving Result after last iteration
		;SearchMacros	1. varbounderl	at Saving Result after last iteration
	match size[addr], ddepth
		mov	rcx, qword[entr]
		if	InCheck = 0
			mov	key16, word[lcopy+MainHashEntry.eval_]
		else
			or	cl, byte[rbx+State.pvhit]	;singlereply?
		end if
		mov	qword[lcopy], rcx	;---has case qsearch eval not saved first
		if	InCheck = 0
			mov	word[lcopy+MainHashEntry.eval_], key16
		end if
	else
		mov	rcx, qword[entr]
		mov	qword[lcopy], rcx
	end match
		if bbounder eq r14l	;ON r14l/PvNode = 0 no exact found
			cmp	bbounder, BOUND_EXACT
			je	write_after_move
		end if
		test	eax, eax
		jz	dont_write_move
		mov	word[lcopy+MainHashEntry.move], ax
dont_write_move:
		if bbounder eq r10l | bbounder eq r13l
			cmp	bbounder, BOUND_EXACT
			je	write_after_move
		end if
		mov	al, ch	;byte[lcopy+MainHashEntry.depth]
		sub	al, 4
		cmp	al, ddepth
		jl	write_after_move
		;TT entry depth above
		if	ModifiedHighTT = 1
			match size[addr], ddepth
				if bbounder eq r10l	;on QSearch	in PvNode
					cmp	rcx, qword[lcopy]
					jne	done
				end if
					jmp	exit
			else
				;r10 = on PvNode, r14 on CutNode
				mov	rax, qword[lcopy]
				or	al, byte[rbx+State.pvhit]	;is there any special type
				if	LowDepthTT = 1
					if bbounder eq r10l | bbounder eq r14l	
						xor	key16, key16
					end if
				end if
				cmp	rcx, rax
				if	LowDepthTT = 1
					if bbounder eq r10l | bbounder eq r14l	
						je	write_after_move
					else
						je	exit
					end if
				else
					je	exit
				end if
				mov	qword[entr], rax
				if	LowDepthTT = 1
					if bbounder eq r10l | bbounder eq r14l	
						jmp	write_after_move
					else
						jmp	exit
					end if
				else
					jmp	exit
				end if
			end match
		else
			jmp	done
		end if
end if
write_everything:
	if mmove eq 0 | bbounder eq BOUND_EXACT | bbounder eq BOUND_NONE
		;BOUND_EXACT->SYZYGY
		;BOUND_NONE->store Staticeval
	else if bbounder eq BOUND_LOWER
		mov	word[lcopy+MainHashEntry.move], ax
	else if mmove eq eax
		if	1
			; lossing an cutoff move entry are disadvantage
			match size[addr], ddepth
			; on Qsearchpv after .MovePickDone - upper or exact
				if bbounder eq r10l
					test	eax, eax
					cmovz	ax,word[lcopy+MainHashEntry.move]
					mov	word[lcopy+MainHashEntry.move], ax
				end if
			else
				if bbounder eq r10l | bbounder eq r13l | bbounder eq r14l
					test	eax, eax
					cmovz	ax,word[rbx+State.ttMove]
					mov	word[lcopy+MainHashEntry.move], ax
				end if
			end match
		else
			mov	word[lcopy+MainHashEntry.move], ax
		end if
	end if
		mov	word[r11+entr], key16
write_after_move:
if bbounder eq BOUND_NONE
		;QueenThreats depth allready 0
		;!QueenThreats depthnone
		mov	al, byte[mainHash.date]
		or	al, byte[rbx+State.pvhit]
		or	byte[lcopy+MainHashEntry.genBound],al
else	
	match size[addr], ddepth
		mov	ah, ddepth
	else
		if ddepth eq sil
			mov	al, ddepth
			mov	ah, al
		else
			mov	ah, ddepth
		end if
	end match
		mov	al, byte[mainHash.date]
		or	al, byte[rbx+State.pvhit]
		or	al, bbounder
		mov	word[lcopy+MainHashEntry.genBound], ax
	if vvalue eq edx
		mov	word[lcopy+MainHashEntry.value_], dx
	else if vvalue eq 0
	else
		err	'val argument of HashTable_Save is not edx or 0'
	end if
	if	ModifiedHighTT = 1 & LowDepthTT = 1
		match size[addr], ddepth
		else
			if mmove eq 0 | bbounder eq BOUND_EXACT			;SYZYGY
			else	;mmove eq eax
				if bbounder eq r10l | bbounder eq r14l	;bbounder eq BOUND_LOWER | 
						test	key16,key16
						jz	exit
				end if
			end if
		end match
	end if
end if
done:
		mov	rax, qword[lcopy]
		mov	qword[entr], rax
exit:
end macro

