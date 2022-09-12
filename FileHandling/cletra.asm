
;
;====================================================================
;	- Escrever um programa para contar o número de letras de um 
;		arquivo.
;	- O usuário devem informar o nome do arquivo, assim que for
;		apresentada a mensagem: "Nome do arquivo: "
;	- O programa deve fornecer como resultado a contagem de cada
;		letra (maiusculas = minusculas)
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
FileName		db		256 dup (?)		; Nome do arquivo a ser lido
FileBuffer		db		10 dup (?)		; Buffer de leitura do arquivo
FileHandle		dw		0				; Handler do arquivo
FileNameBuffer	db		150 dup (?)
caractere		db		0

MsgPedeArquivo		db	"Nome do arquivo: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0
MsgIgual			db	" = ", 0

Contador		dw		26 dup (?)	; A=0, B=1, ..., Z=25

; Variável interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)

; Variaveis para uso interno na função sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


	.code
	.startup
	
;--------------------------------------------------------------------
;void main(void) {
;
;	for (i=0; i<26; ++i)
;		Contador[i] = 0
;	GetFileName();	// Pega o nome do arquivo e coloca em FileName
;	printf ("\r\n");
;		
;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
;		printf("Erro na abertura do arquivo.\r\n");
;		exit(1);
;	}
;	FileHandle = ax
;
;	do {
;		// Lê um caractere do arquivo
;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
;			printf ("Erro na leitura do arquivo.\r\n");
;			fclose(bx=FileHandle)
;			exit(1);
;		}
;
;		// Verifica se terminou o arquivo
;		if (ax==0) {
;			//fclose(bx=FileHandle);
;			break;
;		}
;
;		bl = FileBuffer[0]
;		if ( isLetraMinuscula(bl) )
;			bl -= 0x20;
;		else if ( !isLetraMaiuscula(bl) )
;			continue;
;		bl -= 0x41;
;		Contador[bl]++
;	} while(1);
;
;	for (caractere=0; caractere<26; ++caractere) {
;		AX = Contador[caractere]		
;		if (AX!=0) {
;			printf("%c = %d\r\n", caractere+'A', Contador[caractere]);
;		}
;	}
;	fclose(FileHandle->bx)
;}
;--------------------------------------------------------------------	

	mov		ax,ds				; Seta ES = DS
	mov		es,ax

	;	for (i=0; i<26; ++i)
	;		Contador[i] = 0
	lea		di,Contador
	mov		cx,26
	mov		ax,0
	rep 	stosw
	
	;	GetFileName();	// Pega o nome do arquivo e coloca em FileName
	call	GetFileName

	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s
		
	;	if ( (ax=fopen(ah=0x3d, dx->FileName) ) ) {
	;		printf("Erro na abertura do arquivo.\r\n");
	;		exit(1);
	;	}
	mov		al,0
	lea		dx,FileName
	mov		ah,3dh
	int		21h
	jnc		Continua1
	lea		bx,MsgErroOpenFile
	call	printf_s
	mov		al,1
	jmp		Final
Continua1:

	;	FileHandle = ax
	mov		FileHandle,ax

	;	do {
Again:

	;		// Lê um caractere do arquivo
	;		if ( (ax=fread(ah=0x3f, bx=FileHandle, cx=1, dx=FileBuffer)) ) {
	;			printf ("Erro na leitura do arquivo.\r\n");
	;			fclose(bx=FileHandle)
	;			exit(1);
	;		}
	mov		bx,FileHandle
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	jnc		Continua2		
	lea		bx,MsgErroReadFile
	call	printf_s
	mov		al,1
	jmp		CloseAndFinal
Continua2:

	;		// Verifica se terminou o arquivo
	;		if (ax==0) {
	;			fclose(bx=FileHandle);
	;			exit(0);
	;		}
	cmp		ax,0
	jne		Continua3
	mov		al,0
	jmp		CloseAndFinal
Continua3:

	;		bl = FileBuffer[0]
	;		if ( isLetraMinuscula(bl) )
	;			bl -= 0x20;
	;		else if ( !isLetraMaiuscula(bl) )
	;			continue;
	;		bl -= 0x41;
	mov		bl,FileBuffer
	cmp		bl,'A'
	jb		Again
	cmp		bl,'Z'
	jbe		Dec41
	cmp		bl,'a'
	jb		Again
	cmp		bl,'z'
	ja		Again
	sub		bl,20h
Dec41:
	sub		bl,41h
	
	;		Contador[bl]++
	mov		bh,0
	add		bx,bx
	inc		word ptr [Contador+bx]		; Incrementa contador
	
	;	} while(1);
	jmp		Again
CloseAndFinal:

	;	for (caractere=0; caractere<26; ++caractere) {
	mov		caractere,0
	
ShowResultLoop:		
	;		AX = Contador[caractere]		
	mov		bl,caractere
	add		bl,bl
	mov		bh,0
	mov		ax,[Contador+bx]
		
	;		if (AX!=0) {
	or		ax,ax
	jz		NaoMostra

	;			printf("%c = %d\r\n", caractere+'A', Contador[caractere]);
	mov		dl,caractere
	add		dl,'A'
	mov		ah,2
	int		21h
	
	lea		bx,MsgIgual
	call	printf_s
		
	mov		bl,caractere
	add		bl,bl
	mov		bh,0
	mov		ax,[Contador+bx]
	call	printf_w
	
	lea		bx,MsgCRLF
	call	printf_s
	;		}
NaoMostra:
		
	;	}	// ... caractere<26; ++caractere) {
	mov		al,caractere				; caractere++
	inc		al
	mov		caractere,al
	
	cmp		al,26
	jb		ShowResultLoop
	
	;	fclose(FileHandle->bx)
	mov		bx,FileHandle
	mov		ah,3eh
	int		21h

Final:
	;}
	.exit

		
;
;--------------------------------------------------------------------
;Funcao: Le o nome do arquivo do teclado
;--------------------------------------------------------------------
GetFileName	proc	near
		lea		bx,MsgPedeArquivo			; Coloca mensagem que pede o nome do arquivo
		call	printf_s

		mov		ah,0ah						; Lê uma linha do teclado
		lea		dx,FileNameBuffer
		mov		byte ptr FileNameBuffer,100
		int		21h

		lea		si,FileNameBuffer+2			; Copia do buffer de teclado para o FileName
		lea		di,FileName
		mov		cl,FileNameBuffer+1
		mov		ch,0
		mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
		mov		es,ax
		rep 	movsb

		mov		byte ptr es:[di],0			; Coloca marca de fim de string
		ret
GetFileName	endp


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
		end
;--------------------------------------------------------------------

