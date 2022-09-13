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

StringBuffer	db		150 dup (?)		; buffer para leitura de strings

FileName		db		256 dup (?)		; Nome do arquivo a ser lido
FileNameLength db		1 dup (?)		; Tamanho do nome do arquivo

FileNameSrc		db		256 dup (?)		; Nome do arquivo a ser lido com ext
FileHandleSrc	dw		0				; Handler do arquivo origem

FileNameDst		db		256 dup (?)		; Nome do arquivo a ser escrito com ext
FileHandleDst	dw		0				; Handler do arquivo destino

FileBuffer		db		10 dup (?)		; Buffer de leitura/escrita do arquivo

CriptoWord		db		256 dup (?)		; Frase a ser criptografada

MsgPedeCripto		db	"Frase a ser criptografada: ", 0
MsgPedeArquivo		db	"Nome do arquivo: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroCreateFile	db	"Erro na criacao do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro na escrita do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0

FileExtensionTXT	db	".txt", 0
FileExtensionKRP	db	".krp", 0

MAXSTRING	equ		196		; Tamanho maximo da string - 4 para extensoes
String	db		MAXSTRING dup (?)		; Usado na funcao gets

	.code
	.startup

	;GetFileName();	// Pega o nome do arquivo de origem -> FileNameSrc
	lea		bx,MsgPedeArquivo
	lea		ax,FileName
	call	PrintStringAndGetString

ModificaNomes:
	lea		ax,FileNameSrc
	lea		bx,FileExtensionTXT
	call	ModifyNameWithExtension

	lea		ax,FileNameDst
	lea		bx,FileExtensionKRP
	call	ModifyNameWithExtension


	; Abre o arquivo de origem
	;if (fopen(FileNameSrc)) {
	;	printf("Erro na abertura do arquivo.\r\n")
	;	exit(1)
	;}
	;FileHandleSrc = BX
	lea		dx,FileNameSrc
	call	fopen
	mov		FileHandleSrc,bx
	jnc		Continua1
	lea		bx, MsgErroOpenFile
	call	printf_s
	.exit	1

Continua1:
	
	;if (fcreate(FileNameDst)) {
	;	fclose(FileHandleSrc);
	;	printf("Erro na criacao do arquivo.\r\n")
	;	exit(1)
	;}
	;FileHandleDst = BX
	lea		dx,FileNameDst
	call	fcreate
	mov		FileHandleDst,bx
	jnc		PegaFraseCripto
	mov		bx,FileHandleSrc
	call	fclose
	lea		bx, MsgErroCreateFile
	call	printf_s
	.exit	1

PegaFraseCripto:
	lea		bx,MsgPedeCripto
	lea 	ax,CriptoWord
	call 	PrintStringAndGetString

Continua2:

	;do {
	;	if ( (CF,DL,AX = getChar(FileHandleSrc)) ) {
	;		printf("");
	;		fclose(FileHandleSrc)
	;		fclose(FileHandleDst)
	;		exit(1)
	;	}
	mov		bx,FileHandleSrc
	call	getChar
	jnc		Continua3
	lea		bx, MsgErroReadFile
	call	printf_s
	mov		bx,FileHandleSrc
	call	fclose
	mov		bx,FileHandleDst
	call	fclose
	.exit	1

Continua3:

	;	if (AX==0) break;
	cmp		ax,0
	jz		TerminouArquivo
	
	;	dl = toUpper(dl)
	cmp		dl,'a'
	jb		Continua4
	cmp		dl,'z'
	ja		Continua4
	sub		dl,20h		

Continua4:

	;	if ( setChar(FileHandleDst, DL) == 0) continue;
	mov		bx,FileHandleDst
	call	setChar
	jnc		Continua2

	;	printf ("Erro na escrita....;)")
	;	fclose(FileHandleSrc)
	;	fclose(FileHandleDst)
	;	exit(1)
	lea		bx, MsgErroWriteFile
	call	printf_s
	mov		bx,FileHandleSrc		; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst		; Fecha arquivo destino
	call	fclose
	.exit	1
	
	;} while(1);
		
TerminouArquivo:
	;fclose(FileHandleSrc)
	;fclose(FileHandleDst)
	;exit(0)
	mov		bx,FileHandleSrc	; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst	; Fecha arquivo destino
	call	fclose
	.exit	0

;===============================================================================
;	Subrotinas
;===============================================================================	

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
;Fun��o	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp
		
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp	

;
;--------------------------------------------------------------------
;Funcao Le um string do teclado e coloca no buffer apontado por BX
;		gets(char *s -> bx)
;--------------------------------------------------------------------
gets	proc	near
	push	bx

	mov		ah,0ah						; L� uma linha do teclado
	lea		dx,String
	mov		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	int		21h

	lea		si,String+2					; Copia do buffer de teclado para o FileName
	pop		di
	mov		cl,String+1
	mov		ch,0
	mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	mov		byte ptr es:[di],0			; Coloca marca de fim de string
	ret
gets	endp

;====================================================================
; A partir daqui, est�o as fun��es j� desenvolvidas
;	1) printf_s
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

;----------------------------------------------------------------------
; strcat(char *s1 -> ax, char *s2 -> bx)
; Pega a extensao salva em bx, pega o nome do arquivo e coloca na string apontada por ax
;----------------------------------------------------------------------
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
;Funcao: Le o nome do arquivo do string do teclado
; lea		bx,Msg do printf
; lea		ax,LocaldeOutput
;--------------------------------------------------------------------
PrintStringAndGetString	proc	near
	push 	ax
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
		
	;	printf ("\r\n");
	lea		bx,MsgCRLF
	call	printf_s
	ret
PrintStringAndGetString	endp

;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------


	




