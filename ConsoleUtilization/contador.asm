
;
;====================================================================
;	- Colocar na tela do computador uma contagem de 1 até 20.
;		Cada número deve ser colocado em uma linha
;	- O contador, que deverá estar em memória, deve ter largura 
;		de 16 bits e estar representado em binário
;	- O contador deverá ser convertido de binário para ASCII de 
;		maneira a ser colocado na tela
;	- Usar as funções sprintf_w e a printf_s
;====================================================================
;
	.model small
	.stack

	.data
Contador		dw	0

; Variáveis para uso interno na função printf_w
BufferWRWORD	DB	10 DUP(?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


; void main() {
;	Contador = 0;
;	do {
;		printf ("%04d\r\n", Contador);
;		Contador++;
;	} while (Contador!=21);
; }

	.code
	.startup

	;	Contador = 0;
	mov		ax,0
	mov		Contador,ax

	;	do {
Again:
	;		printf ("%04d\r\n", Contador);
	mov		ax,Contador
	call	printf_w
	
	mov		ah,2
	mov		dl,13
	int		21H
	mov		ah,2
	mov		dl,10
	int		21H
	
	;		Contador++;
	inc		Contador
	
	;	} while (Contador!=21);
	cmp		Contador,21
	jnz		Again
	
	.exit

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

;====================================================================
; A partir daqui, estão as funções já desenvolvidas
;	1) printf_s
;	2) sprintf_w
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
	end
;--------------------------------------------------------------------
	