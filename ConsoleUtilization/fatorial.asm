
;
;====================================================================
;	- Escrever um programa para calcular o fatorial de um número
;		fornecido através do teclado
;	– Usar a mensagem “Calcular fatorial de “, para pedir o número
;	- Para calcular o fatorial, deve ser usada uma subrotina cuja
;		implementação utilize recursão
;	– A passagem de arâmetros deve ser feita através da pilha
;	- Usar a mensagem "Fatorial:" para apresentar o fatorial
;====================================================================
;
	.model 	small
	.stack

CR		equ		0dh
LF		equ		0ah

	.data
MsgNumeroGrande	db	'Fatorial com mais de 16 bits', CR, LF, 0
MsgPedeNumero	db	'Calcular fatorial de: ', 0
MsgFact		db	'Fatorial: ',0
MsgCrlf		db	CR, LF, 0

; Variáveis para uso interno na função PegarNumero
TecBuffer	db	21 dup (0)

; Variáveis para uso interno na função printf_w
BufferWRWORD	DB	10 DUP(?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0



	.code
	.startup
	
;--------------------------------------------------------------------
;void main(void)
;{
;	if ( (AX=PegarNumero()) == -1)
;		exit();
;	if (AX>8) {
;		printf("Fatorial com mais de 16 bits\r\n");
;		exit();
;	}
;	AX=Fact(AX);
;	printf('Fatorial: %d\r\n', AX);
;	exit();
;	
;--------------------------------------------------------------------	

	mov		ax,ds		; Seta ES = DS
	mov		es,ax
	
	; if ( (AX=PegarNumero()) == -1)
	;	exit();
	call	PegarNumero
	cmp		ax,0ffffh
	jz		Erro

	; if (AX>8) {
	;	printf_s('Fatorial com mais de 16 bits', CR, LF);
	;	exit();
	; }
	cmp		ax,8
	jbe		Calcular
	lea		bx,MsgNumeroGrande
	call	printf_s
	jmp		Erro

Calcular:
	;	AX=Fact(AX);
	push	ax
	call	Fact
	add		sp,2

	;	printf('Fatorial: %d\r\n', AX);
	push	ax
	lea		bx,MsgFact
	call	printf_s
	pop		ax
	call	printf_w

Erro:
	; exit()
	.exit


;
;--------------------------------------------------------------------
;Funcao: COloca mensagem e pega numero para calcular o fatorial
;Ret:	Retorna o valor em AX
;		Se for -1 (0FFFFH) houve erro
;WORD PegarNumero(void)
;{
; 	printf_s('Calcular fatorial de: ');
;
; 	TecBuffer[0] = 20
; 	INT21H(ah=10, dx=&TecBuffer)
; 	printf_s(CR, LF);
; 	TecBuffer[TecBuffer[1]] = '\0';		// Coloca 0x00 no fim do string
; 	return Ascii2Dec(&(TecBuffer[2]);	// Converte ASCII para HEX
;}
;--------------------------------------------------------------------
PegarNumero	proc	near

		; printf('Calcular fatorial de: ');
		lea		bx,MsgPedeNumero
		call	printf_s
		
		; TecBuffer[0] = 20
		; INT21H(ah=10, dx=&TecBuffer)
		mov		ah,0ah
		lea		dx,TecBuffer
		mov		byte ptr TecBuffer,20
		int		21h

		; printf("\r\n");
		lea		bx,MsgCrlf
		call	printf_s
		
		; TecBuffer[TecBuffer[1]] = '\0';	// Coloca 0x00 no fim do string
		mov		bl,TecBuffer+1
		mov		bh,0
		add		bx, 2+offset TecBuffer
		mov		byte ptr [bx],0

		; ax = atoi(&(TecBuffer[2]);
		lea		bx,TecBuffer+2
		call	atoi
		
		; return
		ret
PegarNumero	endp

;
;--------------------------------------------------------------------
;Função Calcula fatorial -> DEVE SER RECURSIVA!
;Entra: [sp+2] -> Numero a ser calculado
;Sai:	AX -> Resultado
;WORD Fact(WORD n)
;{
; 	AX = n;
; 	if (AX==0 || AX==1)
;		return 1
; 	AX = Fact(n-1)
; 	return (AX * n)
;}
;--------------------------------------------------------------------
Fact	proc	near

	; AX = n;
	mov		bp,sp
	mov		ax,[bp+2]

	; if (AX==0 || AX==1)
	;	return 1
	cmp		ax,0
	jz		F_Ret1
	cmp		ax,1
	jnz		F_Continua
F_Ret1:
	mov		ax,1
	ret

F_Continua:
	; AX = Fact(n-1)
	dec		ax
	push	ax
	call	Fact
	add		sp,2

	; return (AX * n)
	mov		bp,sp
	mov		bx,[bp+2]
	mul		bx
	ret	
		
Fact	endp

;====================================================================
; A partir daqui, estão as funções já desenvolvidas
;	1) printf_s
;	2) sprintf_w
;	3) atoi
;	4) printf_w (desenvolvida no Contador.asm)
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


;
;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: DS:BX -> Ponteiro para o string de origem
;Sai:	AX    -> Valor "Hex" resultante
;--------------------------------------------------------------------
atoi	proc near
	mov		ax,0
		
atoi_2:
	cmp		byte ptr[bx], 0
	jz		atoi_1

	mov		cx,10
	mul		cx

	mov		ch,0
	mov		cl,[bx]
	add		ax,cx

	sub		ax,'0'
	inc		bx	
	jmp		atoi_2

atoi_1:
	ret
atoi	endp

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


;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------
