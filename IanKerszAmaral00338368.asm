;aquina de alan turing
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

FileHandleSrc	dw		0				; Handler do arquivo origem
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

AEOFStore			dw	0				; Armazena o valor usado em AEOF
AEOFStore1			dw	0				; Armazena o valor usado em AEOF

HexTable			db  "0123456789ABCDEF",0

	.code
	.startup

	;GetFileName();	// Pega o nome do arquivo de origem -> FileNameSrc
	lea		bx,MsgPedeArquivo
	lea		ax,FileName
	call	PrintStringAndGetString

;ax -> local de saida do handler	
;bx -> ponteiro para o string do nome do arquivo
;cx -> extensao do string
;dx -> Tipo de abertura do arquivo

CriaHandles:
	lea		ax,FileHandleSrc
	lea		bx,FileName
	lea		cx,FileExtensionTXT
	mov		dx,0
	call	AddExtensionAndOpenFile

	lea		ax,FileHandleDst
	lea		bx,FileName
	lea		cx,FileExtensionKRP
	mov		dx,42h
	call	AddExtensionAndOpenFile

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
;ax -> local de saida do handler	
;bx -> ponteiro para o string do nome do arquivo
;cx -> extensao do string
;dx -> Tipo de abertura do arquivo 0 para open e qualquer outra coisa para create
;----------------------------------------------------------------------
AddExtensionAndOpenFile proc near

	push	ax
	push	dx

	call	Strlen

	mov		AEOFStore,di
	mov		di,0
	mov		AEOFStore1,di

AEOF_1Loop:
	push	bx

	mov		di,AEOFStore1
	mov		bx,cx
	mov		al,[bx+di]
	inc		di
	mov		AEOFStore1,di
	
	pop		bx
	mov		di,AEOFStore
	inc		di
	mov		AEOFStore,di

	cmp		al,0
	je		AEOF_2

	mov		[bx+di],al
	jmp		AEOF_1Loop

AEOF_2:
	mov		[bx+di],dl			;Temos o nome do arquivo com a extensao, adicionamos o 0 para finalizar
	
	pop		dx

	cmp		dx,0
	je		AEOF_open

	mov		dx,bx
	call	fcreate
	mov		cx,bx
	pop		ax
	mov		bx,ax
	mov		[bx],cx
	jnc		AEOF_Cleanup
	lea		bx, MsgErroCreateFile
	call	printf_s
	call	FileErrorHandler
	
AEOF_open:
	mov		dx,bx
	call	fopen
	mov		cx,bx
	pop		ax
	mov		bx,ax
	mov		[bx],cx
	jnc		AEOF_Cleanup
	lea		bx, MsgErroOpenFile
	call	printf_s
	call	FileErrorHandler

AEOF_Cleanup:
	mov		bx,dx
	call	Strlen
	mov		cx,4
	mov		al,0

AEOF_CleanupLoop:
	mov		[bx+di],al
	dec		di
	loop	AEOF_CleanupLoop

	ret

AddExtensionAndOpenFile endp

;----------------------------------------------------------------------
;Entrada: bx -> ponteiro para o string
;Saida: di -> tamanho da string
;----------------------------------------------------------------------
Strlen proc near

	push	dx
	mov		dl,0
	mov		di,0

StrlenLoop:
	cmp		[bx+di],dl
	je		StrlenENd
	inc		di
	jmp		StrlenLoop

StrlenEnd:
	dec		di
	pop		dx
	ret

Strlen endp

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
	call	FileErrorHandler

ResetFileSrc	endp

;--------------------------------------------------------------------
;Escreve o numero vindo em cx no arquivo
;--------------------------------------------------------------------
NumToFile	proc	near

	push	ax
	push	bx
	push	dx
	push	di

	lea		bx,Letterbuffer
	mov		ax,cx
	call	HexToString

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
	pop		dx
	pop		bx
	pop		ax
	
	ret
NumToFile	endp

;--------------------------------------------------------------------
;Fun��o: Converte um inteiro (n) para (string) como hexadecimal
;		 sprintf(string->BX, "%d", n->AX)
;--------------------------------------------------------------------
HexToString proc near

	push 	ax
	push	cx
	push 	di

	mov		dx,ax
	mov		ch,4
	mov		cl,12
	mov		di,0

ByteLoop:
	shr		ax,cl
	and		ax,000Fh

	push	di
	mov		di,ax

	mov		al,[HexTable+di]
	pop		di
	mov		[bx+di],al

	sub		cl,4
	mov		ax,dx
	inc		di

	dec		ch
	jnz		ByteLoop

	mov		[bx+di],ch
	
	pop		di
	pop		cx
	pop		ax

	ret

HexToString endp

FileErrorHandler	proc	near

	mov		bx,FileHandleSrc
	cmp		bx,0
	je		FileErrorHandler_1
	call	fclose

FileErrorHandler_1:
	mov		bx,FileHandleDst
	cmp		bx,0
	je		FileErrorHandler_2
	call	fclose

FileErrorHandler_2:
	.exit 1

FileErrorHandler	endp
;--------------------------------------------------------------------
		end
;--------------------------------------------------------------------