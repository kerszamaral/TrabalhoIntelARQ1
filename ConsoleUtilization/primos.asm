
;
;====================================================================
;	- Escrever um programa para listar todos os número primos entre 1 e 100
;	- Os números devem ser apresentados em 6 colunas de 10 caracteres cada uma
;	- Os números devem estar alinhados à direita das colunas
;====================================================================
;
	.model 	small
	.stack
	
CR		equ		0dh
LF		equ		0ah

	.data
Matriz	db		101 dup (0)
MsgCrlf	db		CR, LF, 0

; Variaveis para uso interno na função DisplayUmPrimo
BufferWRWORD	DB	20 DUP(?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


	.code
	.startup
		
;	void main()
;		PreencheMatriz();
;		DisplayPrimos();
;	}
	mov	ax,ds		; Seta ES = DS
	mov	es,ax

	call	PreencheMatriz
	call	DisplayPrimos
	
	.exit

;
;--------------------------------------------------------------------
;Funcao: Preenche a matriz de numeros primos
;void	PreencheMatriz()
;{
;	for (di->Matriz,cx=101,al=0; cx==0; di++,cx--)
;		*di = 0
;	delta = 2
;	do {
;		k = 2 * delta
;		while (k <= 100) {
;			Matriz[k] = 1
;			k += delta
;		}
;		delta++
;	} while(delta!=11);
;}
;--------------------------------------------------------------------
PreencheMatriz	proc	near

	;	for (di->Matriz,cx=101,al=0; cx==0; di++,cx--)
	;		*di = 0
	lea		di,Matriz
	mov		cx,101
	mov		al,0
	rep 	stosb

	;	delta = 2
	mov		cx,2
	
	;	do {
PM_Loop:
	;		k = 2 * delta
	mov		bx,cx
	add		bx,cx
		
PL_Loop2:
	;		while (k <= 100) {
	;			Matriz[k] = 1
	;			k += delta
	;		}
	cmp		bx,100
	ja		PL_Next
	mov		byte ptr [Matriz+bx],1
	add		bx,cx
	jmp		PL_Loop2

PL_Next:
	;		delta++
	inc		cx
	
	;	} while(delta!=11);
	cmp		cx,11
	jnz		PM_Loop

	ret	
PreencheMatriz	endp


;
;--------------------------------------------------------------------
;Funcao: Apresenta os primos na tela
;void DisplayPrimos(void)
;{
;	for (cont=0,n=2; n<=100; ++n) {
;		if (Matrix[n]==0) {
;			cont++;
;			DisplayUmPrimo(n);
;		}
;		if (cont==6)
;			printf("\r\n");
;	}
;}
;		
;--------------------------------------------------------------------
DisplayPrimos	proc	near

	;	for (cont=0,n=2; ...		// cont->cl, n->bx
	mov		cl,0
	mov		bx,2
		
DP_Loop:
	;		if (Matrix[n]==0) {
	;			cont++;
	;			DisplayUmPrimo(n);
	;		}
	mov		al,[Matriz+bx]
	or		al,al
	jnz		DP_Pula

	inc		cl

	push	bx
	push	cx
	mov		ax,bx
	call	DisplayUmPrimo
	pop		cx
	pop		bx

DP_Pula:
	;		if (cont==6)
	;			printf("\r\n");
	cmp		cl,6
	jnz		DP_NaoCrlf

	mov		cl,0

	push	bx
	push	cx
	lea		bx,MsgCrlf
	call	printf_s
	pop		cx
	pop		bx

DP_NaoCrlf:
	;	... n<=100; ++n) {
	inc		bx
	cmp		bx,100
	jbe		DP_Loop

	ret
DisplayPrimos	endp


;
;--------------------------------------------------------------------
;Funcao: Apresenta um numero primo
;Entra:  AX -> valor a ser colocado na tela
;--------------------------------------------------------------------
DisplayUmPrimo	proc	near

	; HexToDecAscii(AX, BX->BufferWRWORD)
	lea		bx,BufferWRWORD
	call	sprintf_w
		
	; Coloca espaços em branco, antes do numero
	mov		cx,10
	lea		bx,bufferWRWORD
DUP_Loop:		
	cmp		byte ptr[bx],0
	je		DUP_Spaces
	inc		bx
	dec		cx
	jmp		DUP_Loop
DUP_Spaces:
	mov		dl,' '
	mov		ah,2
	int		21H
	dec		cx
	jne		DUP_Spaces

	; printf_s(bx->BufferWRWORD)
	lea		bx,BufferWRWORD
	call	printf_s
	
	ret
		
DisplayUmPrimo	endp

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
	




