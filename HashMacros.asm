
macro MainHash_Save lcopy, entr, key16, vvalue, bbounder, ddepth, mmove, eev
  local dont_write_move, write_everything, write_after_move, done

;ProfileInc MainHash_Save

  if vvalue eq edx
  else if vvalue eq 0
                xor   edx, edx
  else
    err 'val argument of HashTable_Save is not edx or 0'
  end if

  if mmove eq eax
  else if mmove eq 0
                xor   eax, eax
  else
    err 'move argument of HashTable_Save is not eax or 0'
  end if

		mov   rcx, qword[entr]
		mov   qword[lcopy], rcx

		mov   r11, entr
		shr   r11d, 3  -  1
		and   r11d, 3 shl 1
	     Assert   b, r11d, 3 shl 1, 'index 3 in cluster encountered'
		neg   r11
		lea   r11, [8*3+3*r11]

		cmp   key16, word[r11+entr]
		jne   write_everything

if mmove eq 0
	if bbounder eq BOUND_EXACT
		jmp   write_after_move
	else
	end if
else
		test   eax, eax
	if bbounder eq BOUND_EXACT
		jz   write_after_move
	else
		jz   dont_write_move
	end if
;		shl	eax, 16
		mov	word[lcopy+MainHashEntry.move], ax
end if

dont_write_move:

  if bbounder eq BOUND_EXACT
		jmp	write_after_move
  else
	if bbounder eq dil
		cmp	bbounder, BOUND_EXACT
		je	write_after_move
	else if bbounder eq r10l
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
		mov	word[lcopy+MainHashEntry.move], ax
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
		shl	edx, 16
		mov	dx, eev
		mov	dword[lcopy+MainHashEntry.eval_], edx
done:
		mov	rax, qword[lcopy]
		mov	qword[entr], rax
end macro
