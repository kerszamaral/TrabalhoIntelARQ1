
;
;====================================================================
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
	
; Mensagens
msg10x40	db	'Coord 10x40', 0
msg05x60	db	'Coord 05x60', 0

; Variável interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


	.code
	.startup
	
	call	clearScreen
	
	mov		dh,10
	mov		dl,40
	call	SetCursor	
	lea		bx,msg10x40
	call	printf_s
	
	call	getKey

	mov		dh,5
	mov		dl,60
	call	SetCursor	
	lea		bx,msg05x60
	call	printf_s

	call	getKey
	call	clearScreen

	.exit	0
	

		

;====================================================================
; A partir daqui, estão as funções já desenvolvidas
;	1) printf_s
;	2) printf_w
;	3) sprintf_w
;====================================================================
	
;--------------------------------------------------------------------
;Função Escrever um string na tela
;		printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret
printf_s	endp

;
;--------------------------------------------------------------------
;Função: Escreve o valor de AX na tela
;		printf("%
;--------------------------------------------------------------------
printf_w	proc	near
	; sprintf_w(AX, BufferWRWORD)
	lea		bx,BufferWRWORD
	call	sprintf_w
	
	; printf_s(BufferWRWORD)
	lea		bx,BufferWRWORD
	call	printf_s
	
	ret
printf_w	endp

;
;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string)
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
sprintf_w	proc	near
	mov		sw_n,ax
	mov		cx,5
	mov		sw_m,10000
	mov		sw_f,0
	
sw_do:
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
	mov		sw_n,dx
	
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
	dec		cx
	cmp		cx,0
	jnz		sw_do

	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:

	mov		byte ptr[bx],0
	ret		
sprintf_w	endp



;--------------------------------------------------------------------
;Função: posiciona o cursor
;	mov		dh,linha
;	mov		dl,coluna
;	call	SetCursor
;MS-DOS
;	AH = 02h
;	BH = page number
;		0-3 in modes 2&3
;		0-7 in modes 0&1
;		0 in graphics modes
;	DH = row (00h is top)
;	DL = column (00h is left)
;--------------------------------------------------------------------
SetCursor	proc	near
	mov	ah,2
	mov	bh,0
	int	10h
	ret
SetCursor	endp



;--------------------------------------------------------------------
;Função: Limpa a tela e coloca no formato texto 80x25
;--------------------------------------------------------------------
clearScreen	proc	near
	mov	ah,0	; Seta modo da tela
	mov	al,7	; Text mode, monochrome, 80x25.
	int	10h
	ret
clearScreen	endp


;--------------------------------------------------------------------
;Função: Espera por um caractere do teclado
;Sai: AL => caractere lido do teclado
;Obs:
;	al = Int21(7)
;--------------------------------------------------------------------
getKey	proc	near
	mov		ah,7
	int		21H
	ret
getKey	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------

