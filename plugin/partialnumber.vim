" partialnumber.vim - yet another line number option
" 
" This plugin shows line numbers or a mark for the specified range with an
" optional highlight group, by using the vim's sign feature, without modifying
" the buffer contents.
"
" While running some plugin or your vimrc, you might have seen such an error
" message:
" 	Error detected while processing function MyFunc:
" 	line   37:
" 	E706: Variable type mismatch for: abc
" 	line   61:
" 	E684: list index out of range: 37
" 	E15: Invalid expression list[idx]
" Even with the use of number and relativenumber options, it is not easy to
" find where those lines of that function are actually displayed in a vim
" window. But by using this plugin, for example,
" 	:g/^function/+1,/^endfunction/-1 SetPNU
" will assign and show the line numbers for each function individually. And
" 	:SetNoPNU
" will clear all the partial line numbers in the current buffer.
" 
" The highlight group option (default: SignColumn) can be used to show the
" partial line numbers with its highlight and to identify those line numbers
" as a group of each highlight. For example,
" 	:g/^{/,/^}/ SetPNU ToDo
" 	:.,+12 SetPNU - 0
" 	:'<,'> SetPNU ToDo @@
" 	:g/printf/ SetPNU Title ++
" can show and make 3 different groups. And then,
" 	:SetNoPNU ToDo
" will clear all the partial line numbers of 'ToDo' group but leave others.
" 
" Since the vim's sign feature allows to use just 2 columns, the last 1 or 2
" digits of the partial line number are displayed in front of each line
" (e.g. 100 = 0, 2345 = 45).
" 
" If some lines are added or deleted while showing the partial line numbers,
" this plugin does not follow those changes.
" 
" Commands
" :[range]SetPNU [group] [start]
" 	Show the partial line numbers for [range] with highlight [group].
"	[range] : a line range (default: current line)
" 	[group] : a highlight group ('-' or default: SignColumn)
" 	[start] : a start line number, or a mark if not a number (default: 1)
" :SetNoPNU [group]
" 	Clear all the partial line numbers shown with highlight [group].
" 	[group] : a highlight group ('-' or default: SignColumn)
" 
" Author: Rick Howe
" Last Change: 2015/12/20
" Version: 1.0

if exists("g:loaded_partialnumber")
	finish
endif
let g:loaded_partialnumber = 1.0

let s:save_cpo = &cpo
set cpo&vim

command! -range -nargs=* SetPNU <line1>,<line2>call s:PartialNU(1, <f-args>)
command! -nargs=* SetNoPNU call s:PartialNU(0, <f-args>)

function! s:PartialNU(on, ...) range
	let hl = (a:0 == 0 || a:0 > 0 && a:1 == '-') ? 'SignColumn' : a:1
	if !hlexists(hl)
		echo 'No highlight exists :' hl
		return
	endif

	if a:on
		let sy = (a:0 < 2) ? 1 :
			\(a:2 =~ '^\d\+$') ? str2nr(a:2) : '@' . a:2[-2:]
		if sy[0] == '@'
			let nm = hl . '<' . sy[1:] . '>'
			exe 'silent sign define ' . nm . ' text=' . sy[1:] .
							\' texthl=' . hl
			for ln in range(a:firstline, a:lastline)
				exe 'silent sign place ' . hlID(hl) .
					\' line=' . ln . ' name=' . nm .
					\' buffer=' . bufnr('%')
			endfor
		else
			for ln in range(a:firstline, a:lastline)
				let nr = (ln - a:firstline + sy) % 100
				let nr = (nr < 10 ? nr2char(0xA0) : '') . nr
				let nm = hl . '<' . nr . '>'
				if ln - a:firstline < 100
					exe 'silent sign define ' . nm .
							\' text=' . nr .
							\' texthl=' . hl
				endif
				exe 'silent sign place ' . hlID(hl) .
					\' line=' . ln . ' name=' . nm .
					\' buffer=' . bufnr('%')
			endfor
		endif
	else
		redir => sp
		exec 'silent sign place buffer=' . bufnr('%')
		redir END
		for ct in range(len(filter(split(sp, '\n'),
						\'v:val =~ "=" . hl')))
			exe 'silent sign unplace ' . hlID(hl) .
						\' buffer=' . bufnr('%')
		endfor

		redir => sp
		exec 'silent sign place'
		redir END
		if !empty(filter(split(sp, '\n'), 'v:val =~ "=" . hl'))
			return
		endif

		redir => sl
		exec 'silent sign list'
		redir END
		for nm in filter(map(split(sl, '\n'), 'split(v:val)[1]'),
						\'v:val =~ hl')
			exe 'silent sign undefine ' . nm
		endfor
	endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
