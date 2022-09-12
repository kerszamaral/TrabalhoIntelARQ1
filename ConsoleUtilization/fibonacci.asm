
;
;====================================================================
;	- Escrever um programa para gerar a Série de Fibonacci.
;	- O programa deve esperar que o usuário digite o maior 
;	  valor a ser apresentado.
;		Esse valor deve ser menor ou igual a 100
;		Usar a rotina desenvolvidas anteriormente
;	- Tão logo seja fornecido o valor máximo, o programa deve gerar 
;	  a série, separando cada número:
;		Exemplo: 0 – 1 – 1 – 2 – 3 – 5 – 8 – ...
;====================================================================
;
		.model 	small
		.stack

CR		equ		0dh
LF		equ		0ah

		.data
MsgSeparador		db	" - ", 0
MsgSolicitaLimite	db	"Forneca o valor limite da serie: ", 0
MsgErroLimite		db	"O valor deve ser menor que 100", CR, LF, 0
MsgCRLF				db	CR, LF, 0

Serie		dw		0,1,1
Limite		dw		1

; Variáveis para uso interno na função ReadString
BUFTEC_SIZE		equ	5
BufferTec		db		BUFTEC_SIZE+1

; Variáveis para uso interno na função printf_w
BufferWRWORD	DB	10 DUP(?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


; void main() {
;
; 	printf("Forneca o valor limite da serie: ");
; 	ReadString(BufferTec, BUFTEC_SIZE);
; 	printf("\r\n");
;
; 	AX = atoi(BufferTec)
; 	if (AX>100) {
;		printf("O valor deve ser menor que 100\r\n");
; 	}
; 	else {
;		Limite = AX;
;		printf ("%04d - %04d", Serie[0], Serie[1]);
;		while(1) {
; 			Serie[2] = Serie[1] + Serie[0];
; 			if (Serie[2]>Limite)
;				break;
;			printf (" - %04d", Serie[2]);
;
;			Serie[0] = Serie[1];
;			Serie[1] = Serie[2];
;		}
;	}
; 	printf("\r\n");
; }
;

	.code
	.startup	

	; 	printf("Forneca o valor limite da serie: ");
	; 	ReadString(BufferTec, BUFTEC_SIZE);
	; 	printf("\r\n");
	lea		bx,MsgSolicitaLimite
	call	printf_s
	
	lea		bx,BufferTec
	mov		cx,BUFTEC_SIZE
	call	ReadString
	
	lea		bx,MsgCRLF
	call	printf_s

	; 	AX = atoi(BufferTec)
	; 	if (AX>100) {
	;		printf("O valor deve ser menor que 100\r\n");
	; 	}
	lea		bx,BufferTec
	call	atoi
		
	cmp		ax,100					; Verifica se menor ou igual a 100
	jle		GeraSerie
	lea		bx,MsgErroLimite		; Se Maior, envia mensagem de erro e encerra
	call	printf_s
	jmp	Final

GeraSerie:
	; 	else {
	;		Limite = AX;
	mov		Limite,ax

	;		printf ("%04d - %04d", Serie[0], Serie[1]);
	mov		ax,Serie
	call	printf_w

	lea		bx,MsgSeparador
	call	printf_s

	mov		ax,Serie+2
	call	printf_w

NextValue:
	;		while(1) {
	; 			Serie[2] = Serie[1] + Serie[0];
	mov		ax,Serie+2
	add		ax,Serie+0
	mov		Serie+4,ax

	; 			if (Serie[2]>Limite)
	;				break;
	cmp		ax,Limite
	jg		Final

	;			printf (" - %04d", Serie[2]);
	lea		bx,MsgSeparador
	call	printf_s

	mov		ax,Serie+4
	call	printf_w

	;			Serie[0] = Serie[1];
	;			Serie[1] = Serie[2];
	mov		ax,Serie+2
	mov		Serie+0,ax
	mov		ax,Serie+4
	mov		Serie+2,ax
		
	;		}
	jmp		NextValue
	
	;	}
Final:
	; 	printf("\r\n");
	lea		bx,MsgCRLF
	call	printf_s
	
	; }
	.exit


;====================================================================
; A partir daqui, estão as funções já desenvolvidas
;	1) printf_s
;	2) sprintf_w
;	3) ReadString
;	4) atoi
;	5) printf_w (desenvolvida no Contador.asm)
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
;Função: Lê um string do teclado
;Entra: DS:BX -> Ponteiro para o string
;	       CX -> numero maximo de caracteres aceitos
;--------------------------------------------------------------------
ReadString	proc	near
		mov		dx,0
RDSTR_1:
		mov		ah,7
		int		21H

		cmp		al,0DH
		jne		RDSTR_A
		mov		byte ptr[bx],0
		ret
RDSTR_A:

		cmp		al,08H
		jne		RDSTR_B
		cmp		dx,0
		jz		RDSTR_1

		push	dx
		mov		dl,08H
		mov		ah,2
		int		21H
		mov		dl,' '
		mov		ah,2
		int		21H
		mov		dl,08H
		mov		ah,2
		int		21H
		pop		dx

		dec		bx
		inc		cx
		dec		dx
		jmp		RDSTR_1

RDSTR_B:
		cmp		cx,0
		je		RDSTR_1
		cmp		al,' '
		jl		RDSTR_1

		mov		[bx],al

		inc		bx
		dec		cx
		inc		dx

		push	dx
		mov		dl,al
		mov		ah,2
		int		21H
		pop		dx

		jmp		RDSTR_1

ReadString	endp

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
