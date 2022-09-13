; Ian Kersz Amaral - Cartão: 00338368
;
;====================================================================
;	- .
;	- O usuario devem informar o nome do arquivo, assim que for
;		apresentada a mensagem: "Nome do arquivo: "
;	- 
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah

	.data
StringBuffer	db		150 dup (?)

FileName		db		256 dup (?)		; Nome do arquivo a ser lido
FileNameLength db		1 dup (?)		; Tamanho do nome do arquivo

InputFileName	db		256 dup (?)		; Nome do arquivo de input
InputFileHandle	dw		0				; Handler do arquivo de input
InputFileBuffer	db		10 dup (?)		; Buffer de leitura do arquivo

OutputFileName	db		256 dup (?)		; Nome do arquivo de output
OutputFileHandle dw		0				; Handler do arquivo de output
OutputFileBuffer db		10 dup (?)		; Buffer de leitura do arquivo

MsgPedeArquivo		db	"Nome do arquivo: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0
MsgIgual			db	" = ", 0

FileExtensionTXT	db	".txt", 0
FileExtensionKRP	db	".krp", 0

OkayMessage			db 	"Files Okay", 0

Contador		dw		26 dup (?)	; A=0, B=1, ..., Z=25

; Vari�vel interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)

; Variaveis para uso interno na fun��o sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0


    .code
    .startup

    ;	GetFileName();	// Pega o nome do arquivo e coloca em FileName
	lea		bx,MsgPedeArquivo
	lea		ax,FileName
	call	PrintStringAndGetString

	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s

ModificaNomes:
	lea		ax,InputFileName
	lea		bx,FileExtensionTXT
	call	ModifyNameWithExtension

	lea		ax,OutputFileName
	lea		bx,FileExtensionKRP
	call	ModifyNameWithExtension

	;	Mostra se os nomes foram copiados corretamente
	lea     bx,InputFileName
    call    printf_s
	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s

	lea     bx,OutputFileName
    call    printf_s
	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s

CriaOSArquivos:
	call 	CreateFileHandles

	;	Verifica se os arquivos foram abertos corretamente
	lea     bx,OkayMessage
    call    printf_s
	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s

FechaArquivoOutput:
	;	fclose(OutputFileHandle->bx)
	mov		bx,OutputFileHandle
	call 	fclose

FechaArquivoInput:
	;	fclose(InputFileHandle->bx)
	mov		bx,InputFileHandle
	call 	fclose

Final:
	.exit

ModifyNameWithExtension proc near

	; salva a extensao de bx
		push 	bx
	;	strcpy (InputFileName, FileName)
		lea		si,FileName			; Copia do buffer de teclado para o FileName
		mov		di,ax				; Copia do FileName para o InputFileName
		mov		cl,FileNameLength
		mov		ch,0
		mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
		mov		es,ax
		rep 	movsb

	;	strcat (InputFileName, FileExtensionTXT)
	;   Como o local já está apontando para o endereço correto
		pop		bx
		mov    	si,bx
		mov    	cl,4
		mov    	ch,0
		mov    	ax,ds
		mov    	es,ax
		rep    	movsb

		mov		byte ptr es:[di],0			; Coloca marca de fim de string

		ret

ModifyNameWithExtension endp


;--------------------------------------------------------------------
;Funcao: Modifica o nome dos arquivos e abre eles
;--------------------------------------------------------------------
CreateFileHandles proc 	near

	;	if ( (ax=fopen(ah=0x3d, dx->InputFileName) ) ) {
	;		printf("Erro na abertura do arquivo.\r\n");
	;		exit(1);
	;	}
	lea		dx,InputFileName
	call 	fopen
	jnc		ContinuaCreateFiles1
	lea		bx,MsgErroOpenFile
	call	printf_s
	mov		al,1
	jmp		Final

ContinuaCreateFiles1:
	;	FileHandle = ax
	mov		InputFileHandle,bx


	;	if ( (ax=fopen(ah=0x3d, dx->OutputFileName) ) ) {
	;		printf("Erro na abertura do arquivo.\r\n");
	;		exit(1);
	;	}
	lea		dx,OutputFileName
	call	fcreate
	jnc		ContinuaCreateFiles2
	lea		bx,MsgErroOpenFile
	call	printf_s
	mov		al,1
	jmp		FechaArquivoInput

ContinuaCreateFiles2:
		;	FileHandle = ax
	mov		OutputFileHandle,bx

	ret

CreateFileHandles endp

;--------------------------------------------------------------------
;Funcao: Le o nome do arquivo do string do teclado
; lea		bx,Msg do printf
; lea		ax,LocaldeOutput
;--------------------------------------------------------------------
PrintStringAndGetString	proc	near
		push 	ax
		;lea		bx,MsgPedeArquivo			; Coloca mensagem que pede o nome do arquivo
		call	printf_s

		mov		ah,0ah						; Le uma linha do teclado
		lea		dx,StringBuffer
		mov		byte ptr StringBuffer,100
		int		21h

		mov		cl,StringBuffer+1			; Coloca o tamanho do nome do arquivo em FileNameLength
		mov		FileNameLength,cl

		lea		si,StringBuffer+2			; Copia do buffer de teclado para o FileName
		pop		di
		mov		cl,StringBuffer+1
		mov		ch,0
		mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
		mov		es,ax
		rep 	movsb

		mov		byte ptr es:[di],0			; Coloca marca de fim de string
		ret
PrintStringAndGetString	endp


;====================================================================
; A partir daqui, est�o as fun��es j� desenvolvidas
;	1) printf_s
;	2) printf_w
;	3) sprintf_w
;====================================================================
	
;--------------------------------------------------------------------
;Fun��o Escrever um string na tela
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
;Fun��o: Escreve o valor de AX na tela
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
;Fun��o: Converte um inteiro (n) para (string)
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
;Fun��o	Abre o arquivo cujo nome est� no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp

;--------------------------------------------------------------------
;Fun��o Cria o arquivo cujo nome est� no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------

