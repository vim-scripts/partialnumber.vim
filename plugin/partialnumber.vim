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
" 	E684: list index out of range: 19
" 	E15: Invalid expression list[idx]
" Even with the use of number and relativenumber options, it is not easy to
" find where those lines of that function are actually displayed in a vim
" window. But by using this plugin, for example,
" 	:g/^function/+1,/^endfunction/-1 SetPNU
" will assign and show the line numbers for each function individually
" so that you can see those line numbers on the sign column.
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
" 	:SetNoPNU *
" will clear all of the groups.
"
" Since the vim's sign feature allows to use just 2 columns, the last 1 or 2
" digits of the partial line number are displayed in front of each line.
" To try to show upper digits, a line number which can be just divided by 100
" is displayed as a circled number until 5000 and an empty circle beyond
" (100/200/.../5000 = circled 1/2/.../50, 5100/5200/... = empty circle).
"
" If some lines are added or deleted while showing the partial line numbers,
" this plugin does not follow those changes.
"
" Commands
" :[range]SetPNU [group] [start]
" 	Show the partial line numbers for [range] with highlight [group].
"	[range] : a line range (default: current line)
" 	[group] : a highlight group (- or default: SignColumn)
" 	[start] : a start line number, or a mark if not a number (default: 1)
" :SetNoPNU [group]
" 	Clear all the partial line numbers shown with highlight [group].
" 	[group] : a highlight group (*: all, - or default: SignColumn)
"
" Update 1.1
" * Added '*' for SetNoPNU highlight group option
" * Changed to display circled line numbers to show upper digits
"
" Author: Rick Howe
" Last Change: 2015/12/22
" Version: 1.1

if exists("g:loaded_partialnumber")
	finish
endif
let g:loaded_partialnumber = 1.1
let s:pnu = 'PNU_'

let s:save_cpo = &cpo
set cpo&vim

command! -range -nargs=* SetPNU call s:SetPartialNU(<line1>, <line2>, <f-args>)
command! -nargs=* SetNoPNU call s:SetNoPartialNU(<f-args>)

function! s:SetPartialNU(fl, ll, ...)
	let hl = (a:0 == 0 || a:1 == '-') ? 'SignColumn' : a:1
	if !hlexists(hl)
		echo 'No highlight exists :' hl
		return
	endif

	let sn = (a:0 < 2) ? 1 : (a:2 =~ '^\d\+$') ? str2nr(a:2) : a:2[:1]
	if type(sn) == type(0)
		for ln in range(a:fl, a:ll)
			let nl = (ln - a:fl + sn) % 100
			if nl == 0
				let nu = (ln - a:fl + sn) / 100
				let nl = (nu == 0) ? nr2char(0xA0) . nl :
					\(nu <= 20) ? nr2char(0x245F + nu) :
					\(nu <= 35) ? nr2char(0x323C + nu) :
					\(nu <= 50) ? nr2char(0x328D + nu) :
							\nr2char(0x25CB)
			elseif nl < 10
				let nl = nr2char(0xA0) . nl
			endif
			let nm = s:pnu . hl . '<' . nl . '>'
			exe 'silent sign define ' . nm . ' text=' . nl .
							\' texthl=' . hl
			exe 'silent sign place ' . hlID(hl) . ' line=' . ln .
				\' name=' . nm . ' buffer=' . bufnr('%')
		endfor
	else
		let nm = s:pnu . hl . '<' . sn . '>'
		exe 'silent sign define ' . nm . ' text=' . sn . ' texthl=' . hl
		for ln in range(a:fl, a:ll)
			exe 'silent sign place ' . hlID(hl) . ' line=' . ln .
				\' name=' . nm . ' buffer=' . bufnr('%')
		endfor
	endif
endfunction

function! s:SetNoPartialNU(...)
	let hl = (a:0 == 0 || a:1 == '-') ? 'SignColumn' :
						\(a:1 == '*') ? '' : a:1
	if !empty(hl) && !hlexists(hl)
		echo 'No highlight exists :' hl
		return
	endif

	redir => sp
	exec 'silent sign place buffer=' . bufnr('%')
	redir END
	for id in map(filter(split(sp, '\n'), 'v:val =~ "=" . s:pnu . hl'),
					\'split(split(v:val)[1], "=")[1]')
		exe 'silent sign unplace ' . id . ' buffer=' . bufnr('%')
	endfor

	for ht in !empty(hl) ? [hl, ''] : ['']
		redir => sp
		exec 'silent sign place'
		redir END
		if empty(filter(split(sp, '\n'), 'v:val =~ "=" . s:pnu . ht'))
			redir => sl
			exec 'silent sign list'
			redir END
			for nm in filter(map(split(sl, '\n'),
				\'split(v:val)[1]'), 'v:val =~ s:pnu . ht')
				exe 'silent sign undefine ' . nm
			endfor
		endif
	endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
