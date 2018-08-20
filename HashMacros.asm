
macro MainHash_Save lcopy, entr, key16, vvalue, bbounder, ddepth, mmove, eev
  local dont_write_move, write_everything, write_after_move, done, norewrite

;ProfileInc MainHash_Save


  if mmove eq eax
  else if mmove eq 0
                xor   eax, eax
  else
    err 'move argument of HashTable_Save is not eax or 0'
  end if

		mov	r11, entr
		shr	r11d, 3  -  1
		and	r11d, 3 shl 1
	     Assert   b, r11d, 3 shl 1, 'index 3 in cluster encountered'
		neg	r11
		lea	r11, [8*3+3*r11]

		cmp	key16, word[r11+entr]
		jne	write_everything
		mov	rcx, qword[entr]
		mov	qword[lcopy], rcx
if mmove eq 0
else
		test	eax, eax
	if bbounder eq BOUND_EXACT
		jz	write_after_move
	else
		jz	dont_write_move
	end if
		mov	word[lcopy+MainHashEntry.move], ax
end if
	if bbounder eq BOUND_EXACT
		jmp	write_after_move
	else
dont_write_move:
		if bbounder eq r10l
			cmp	bbounder, BOUND_EXACT
			je	write_after_move
		end if
		mov	al, ch	;byte[lcopy+MainHashEntry.depth]
		sub	al, 4
		cmp	al, ddepth
		jl	write_after_move
		jmp	done
	end if

write_everything:
	match size[addr], ddepth
		if bbounder eq BOUND_NONE
			test	eax,eax
			jnz	norewrite
		else
			test	eax, eax
			cmovz	ax,word[rbx+State.ttMove]
		end if
	else
		if ddepth eq DEPTH_NONE
			test	eax,eax
			jnz	norewrite
		else if bbounder eq BOUND_EXACT
			test	eax,eax
			jnz	norewrite
		else
			test	eax, eax
			cmovz	ax,word[rbx+State.ttMove]
		end if
	end match
		mov	word[lcopy+MainHashEntry.move], ax
norewrite:
		mov	word[r11+entr], key16
write_after_move:
	
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
		or	al, bbounder
		mov	word[lcopy+MainHashEntry.genBound], ax
	if vvalue eq edx
		shl	edx, 16
		mov	dx, eev
	else if vvalue eq 0
		if	eev eq VALUE_NONE
			mov	edx, 0x7D02
		else
			movzx	edx, eev
		end if
	else
		err	'val argument of HashTable_Save is not edx or 0'
	end if
		mov	dword[lcopy+MainHashEntry.eval_], edx
done:
		mov	rax, qword[lcopy]
		mov	qword[entr], rax
end macro
