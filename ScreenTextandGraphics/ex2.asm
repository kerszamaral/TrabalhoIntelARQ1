
;
;====================================================================
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
	


	.code
	.startup
	
	call	clearScreenGraph	; Limpa a tela e coloca em modo gráfico
	
	mov		bx,20				; Desenha quadrado nas coordenadas (100,200), com lado=20
	mov		cx,100
	mov		dx,200
	call	quadrado
		
	call	getKey				; Aguarda teclado

	mov		bx,50				; Desenha quadrado nas coordenadas (300,100), com lado=50
	mov		cx,300
	mov		dx,100
	call	quadrado

	call	getKey				; Aguarda teclado
	call	clearScreenText		; Limpara a tela

	.exit	0					; Encerra
	

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


;--------------------------------------------------------------------
;Funcao: Desenha um quadrado na tela gráfica
;Entra:	BX -> dimensão do LADO do quadrado
;		CX -> Lado esquerdo
;		DX -> Lado superior
;--------------------------------------------------------------------
quadrado	proc	near

	call	retaH
	call	retaV

	push	cx
	add		cx,bx
	call	retaV
	pop		cx
	
	push	dx
	add		dx,bx
	call	retaH
	pop		dx
	
	ret
quadrado	endp


;--------------------------------------------------------------------
;Funcao: Desenha uma linha horizontal na tela grafica
;Entra:	BX -> tamanho da reta
;		CX -> coluna de inicio
;		DX -> linha de inicio
;--------------------------------------------------------------------
retaH	proc	near
	push	bx
	push	cx

loopRetaH:
	call	setPixel
	inc		cx
	dec		bx
	jnz		loopRetaH
	
	pop		cx
	pop		bx
	ret
retaH	endp


;--------------------------------------------------------------------
;Funcao: Desenha uma linha vertical na tela grafica
;Entra:	BX -> tamanho da reta
;		CX -> coluna de inicio
;		DX -> linha de inicio
;--------------------------------------------------------------------
retaV	proc	near
	push	bx
	push	dx

loopRetaV:
	call	setPixel	
	inc		dx
	dec		bx
	jnz		loopRetaV
	
	pop		dx
	pop		bx
	ret
retaV	endp


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
;Função: Liga o bit das coordenadas dadas
;Entra:
;	DX - linha
;	CX - coluna
; Usar BIOS Write Pixel (INT 10H com AH=0CH)
; AL - Color to set (set bit 10000000b for XOR mode).
; BH - Video page number.
; CX - Pixel column number.
; DX - Pixel row number.
;--------------------------------------------------------------------
SetPixel	proc	near
	push	bx
	push	cx
	push	dx
	
	mov	al,1
	mov	bh,0
	mov	ah,0ch
	int	10h
	
	pop		dx
	pop		cx
	pop		bx
	
	ret
SetPixel	ENDP



;--------------------------------------------------------------------
;Função: Limpa a tela e coloca no formato texto 80x25
;--------------------------------------------------------------------
clearScreenText	proc	near
	mov	ah,0	; Seta modo da tela
	mov	al,7	; Text mode, monochrome, 80x25.
	int	10h
	ret
clearScreenText	endp

;--------------------------------------------------------------------
;Função: Limpa a tela e coloca no formato grafico 640x480
;--------------------------------------------------------------------
clearScreenGraph	proc	near
	mov	ah,5	; Seta a página corrente como sendo a página "0"
	mov	al,0
	int	10h
	mov	ah,0	; Seta modo da tela
	mov	al,11h
	int	10h
	ret
clearScreenGraph	endp


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

