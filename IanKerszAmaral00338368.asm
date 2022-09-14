;Abacate
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

LetraAProcurar		db	1 dup (?)		; Letra a ser procurada

Letterbuffer		db	10 dup (?)		; Buffer para leitura de letras

UsedLocations		dw	156 dup (?)		; Vetor de localizacoes ja usadas, bem maior do que as 100 necessarias por agr

MAXSTRING	equ		196		; Tamanho maximo da string - 4 para extensoes
String	db		MAXSTRING dup (?)		; Usado na funcao gets

; Vari�vel interna usada na rotina printf_w
BufferWRWORD	db		10 dup (?)

; Variaveis para uso interno na fun��o sprintf_w
sw_n	dw	0
sw_f	db	0
sw_m	dw	0

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

	;Setup location of string
	lea		bx,CriptoWord	; bx = CriptoWord
	mov		di,0			; di = CriptoLocation
	push	bx				; 	salva o ponteiro
	push	di				;	salva o indice

NextCharInCrypto:
	call	ResetFileSrc
	pop		bx
	pop		di
	mov		al,[bx+di]	; 	Get char
	inc 	di			; 	incrementa o indice
	push	bx			; 	salva o ponteiro
	push	di			;	salva o indice

	cmp		al,0
	je		TerminouCriptoString ;String terminada

	cmp		al,'!'
	jb		NextCharInCrypto
	cmp		al,'~'
	ja		NextCharInCrypto
	mov		LetraAProcurar,al
	mov		cx,0
	jmp 	Procurar	; 	Se for um char valido, procura a letra

Procurar:
	mov		dl,LetraAProcurar
	mov		bx,FileHandleSrc
	
	call 	SearchCharInFile
	mov		di,0

Revisar:
	mov		ax,[UsedLocations+di]
	cmp		ax,0
	je		ColocaVetor
	cmp		cx,ax
	je		Procurar
	add		di,2
	jmp		Revisar

ColocaVetor:
	mov		[UsedLocations+di],cx
	jmp		NextCharInCrypto

TerminouCriptoString:
	mov		di,0
	mov		bx,FileHandleDst

TerminouCriptoStringLoop:
	mov		cx,[UsedLocations+di]
	cmp		cx,0
	je		TerminouArquivo
	call	NumToFile
	add		di,2
	jmp		TerminouCriptoStringLoop

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
	push	cx
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	pop		cx
	ret
getChar	endp
		
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	push	cx
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	pop		cx
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
;Funcao que retorna o local da ocorrencia de uma letra
;Input:
;bx -> FileHandle
;dl -> letra
;Output:
;cx -> local da ocorrencia no arquivo
;--------------------------------------------------------------------
SearchCharInFile	proc	near
	cmp		dl,'a'				; Faz um toUpper na letra de entrada para ser comparada com o arquivo
	jb		SearchCharInFile_1			
	cmp		dl,'z'
	ja		SearchCharInFile_1
	sub		dl,20h	

SearchCharInFile_1:
	mov 	LetraAProcurar,dl	; Salva a letra para ser comparada com o arquivo
	mov 	ax,1				; Posiciona o numero de caracteres a serem lidos

loopSearchCharInFile:	
	inc 	cx
	call 	getChar				; Le um caractere do arquivo
	jc		SearchCharInFile_Error		; Se houve erro na leitura do arquivo, retorna com erro
	cmp		dl,0
	je		SearchCharInFile_Error		; Se chegou no fim do arquivo, retorna com erro

	cmp		dl,'a'				; Faz um toUpper na letra do arquivo
	jb		SearchCharInFile_2			
	cmp		dl,'z'
	ja		SearchCharInFile_2
	sub		dl,20h

SearchCharInFile_2:
	cmp 	dl,LetraAProcurar	; Compara a letra do arquivo com a letra de entrada
	je 		FimSearchCharInFile		; Se forem iguais, termina a funcao
	jmp 	loopSearchCharInFile		; Se forem diferentes, continua a leitura do arquivo

SearchCharInFile_Error:
	mov 	cx,0				; Se houve erro na leitura do arquivo, retorna com erro
	ret	

FimSearchCharInFile:
	ret

SearchCharInFile	endp

;--------------------------------------------------------------------
;Coloca o arquivo lido no local correto para a leitura
;--------------------------------------------------------------------
ResetFileSrc	proc	near
	; Salva os registradores usados
	push 	ax
	push	bx
	push	cx
	push 	dx

	mov		ah,42h				; Funcao Set File Pointer
	mov 	al,0				; Posiciona o ponteiro no inicio do arquivo (Seek_Set)
	mov		bx,FileHandleSrc	; Pega o Handle do arquivo desejado
	mov		dx,1				; Pega o offset do arquivo desejado (parte menor), começamos pela segunda posição
	mov		cx,0				; Pega o offset do arquivo desejado (parte maior)

	int		21h					; interrupt de arquivo
	jc		ResetFileSrc_error

	; Recupera os registradores usados
	pop 	dx
	pop 	cx
	pop 	bx
	pop		ax
	ret

ResetFileSrc_error:
	mov		bx,FileHandleSrc
	call	fclose
	mov		bx,FileHandleDst
	call	fclose
	.exit 1

ResetFileSrc	endp

;--------------------------------------------------------------------
;Escreve o numero vindo em cx no arquivo
;--------------------------------------------------------------------
NumToFile	proc	near

	push	di
	cmp		cx,1000
	jae		cent
	mov		dl,'0'
	call 	setChar

cent:
	cmp		cx,100
	jae		dez
	mov		dl,'0'
	call 	setChar

dez:
	cmp		cx,10
	ja		escreve
	mov		dl,'0'
	call 	setChar

escreve:
	lea		bx,Letterbuffer
	mov		ax,cx
	call 	sprintf_w
	mov		di,0

LoopPrintString:
	mov		dl,[Letterbuffer+di]
	cmp 	dl,0
	je		FimPrintString
	mov		bx,FileHandleDst
	call	setChar
	inc		di
	jmp		LoopPrintString
	
FimPrintString:
	mov		bx,FileHandleDst
	mov		dl,' '
	call 	setChar
	pop		di
	
	ret
NumToFile	endp
;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------