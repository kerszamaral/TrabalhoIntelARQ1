;aquina de alan turing
; Ian Kersz Amaral - Cartão: 00338368
;
;====================================================================
;	!!Codigo para o Trabalho do Processador Intel 80x86 de Arquitetura de Computadores 1!!
;	
;	- O usuario deve informar o nome do arquivo que ira ser lido sem a extensao 
;	- O arquivo com a extensao .txt sera carregado para o programa
;
;	- o usuario deve informar a frase que quer criptografar com o arquivi
;	- o programa criptografa a frase com base na localizacao dos caracteres no arquivo
;
;	- Ao final do pograma, um arquivo com o mesmo nome do arquivo de entrada, mas com a extensao .krp
;	sera criado com a frase de forma criptografada
;
;====================================================================
;
	.model		small
	.stack
		
CR		equ		0dh
LF		equ		0ah
StringSize	equ	254
MaxSenSize	equ 100

	.data

;----------------------------------------------------------------------
;	Buffers e Variaveis
;----------------------------------------------------------------------
StringBuffer	db	256 dup (?)				; buffer para leitura de strings
NumBuffer		db	5 dup (?)				; Buffer para leitura de numeros Hexa
FileBuffer		db	10 dup (?)				; Buffer de leitura/escrita do arquivo
FileSizeBuffer	db	5 dup (?)				; Buffer para leitura do tamanho do arquivo
FileSize		dw	0						; Tamanho do arquivo

FileName		db	256 dup (?)				; Nome do arquivo de entrada e saida
FileHandle		dw	0						; Handle do arquivo aberto

Sentence		db	MaxSenSize+1 dup (?)	; Frase a ser criptografada, 100 caracteres + 0 
SenLocVec		dw	MaxSenSize dup (?)		; Vetor de localizacoes ja usadas para a frase

CharSearchStore	db	1 dup (?)				; Letra a ser procurada pela funcao CharSearch

BufferWRWORD	db	10 dup (?)				; Variavel interna usada na rotina printf_w
sw_n			dw	0						; Variavel para uso interno na funcao sprintf_w
sw_f			db	0						; Variavel para uso interno na funcao sprintf_w
sw_m			dw	0						; Variavel para uso interno na funcao sprintf_w

;----------------------------------------------------------------------
;	Mensagens
;----------------------------------------------------------------------
AskForFile		db	"Nome do arquivo: ", 0						; Mensagem para pedir o nome do arquivo
AskForSentence	db	"Frase a ser criptografada: ", 0			; Mensagem para pedir a frase a ser criptografada
MsgErrorOF		db	"Error: Abrir o arquivo.", CR, LF, 0		; Mensagem de erro ao abrir o arquivo
MsgErrorCF		db	"Error: Criar o arquivo.", CR, LF, 0		; Mensagem de erro ao criar o arquivo
MsgErrorRF		db	"Error: Leitura do arquivo.", CR, LF, 0		; Mensagem de erro ao ler o arquivo
MsgErrorWF		db	"Error: Escrita do arquivo.", CR, LF, 0		; Mensagem de erro ao escrever no arquivo
MsgErrorRSF		db	"Error: Reiniciar o arquivo.", CR, LF, 0	; Mensagem de erro ao resetar o arquivo
MsgErrorFTS		db	"Error: Simbolo nao encontrado.", CR, LF, 0	; Mensagem de erro arquivo de tamanho insuficiente
MSgErrorFTL		db	"Error: Arquivo muito grande.", CR, LF, 0	; Mensagem de erro arquivo de tamanho excessivo
MsgErrorSOF		db	"Error: Frase muito grande.", CR, LF, 0		; Mensagem de erro frase muito grande
MsgErrorSE		db	"Error: Frase vazia.", CR, LF, 0			; Mensagem de erro frase nao pode ser vazia
MsgErrorSIC		db	"Error: Caracteres invalidos.", CR, LF, 0	; Mensagem de erro frase com caracteres invalidos
MsgDoneFS		db	"Tamanho do arquivo de entrada (em bytes): ", 0	; Mensagem de tamanho do arquivo
MsgDoneSSize	db	"Tamanho da frase (em bytes): ", 0			; Mensagem de tamanho da frase
MsgDoneFN		db	"Nome do arquivo de saida: ", 0				; Mensagem de nome do arquivo de saida
MsgDone			db	"Processamento realizado sem erro", CR, LF, 0	; Mensagem de sucesso
MsgCRLF			db	CR, LF, 0									; Mensagem de quebra de linha
FETXT			db	".txt", 0									; Extensao do arquivo de entrada
FEKRP			db	".krp", 0									; Extensao do arquivo de saida
HexTable		db  "0123456789ABCDEF",0						; Tabela de conversao de numeros hexadecimais

	.code
	.startup

;====================================================================
;	Funcao MAIN do programa
;====================================================================
Main:
	; Faz o pedido do nome do arquivo
	lea		bx,AskForFile		; Carrega o endereco da mensagem de pedir o nome do arquivo
	lea		ax,FileName			; Carrega o endereco do nome do arquivo
	call	Print_FAndGetS		; Chama a funcao para imprimir a mensagem e ler a string

	; Abre o arquivo de entrada
	lea		ax,FileHandle		; Carrega o endereco do handle do arquivo de entrada
	lea		bx,FileName			; Carrega o endereco do nome do arquivo
	lea		cx,FETXT			; Carrega o endereco da extensao do arquivo de entrada
	mov		dx,0				; Carrega o modo de abertura do arquivo
	call	AEOF				; Chama a funcao para adicionar extensao e abrir o arquivo de entrada

	; Faz o pedido da frase a ser criptografada
	lea		bx,AskForSentence	; Carrega o endereco da mensagem de pedir a frase a ser criptografada
	lea 	ax,Sentence			; Carrega o endereco da frase a ser criptografada
	call 	Print_FAndGetS		; Chama a funcao para imprimir a mensagem e ler a string
	
	; Ajusta os parametros para a funcao de criptografia
	lea		bx,Sentence			; Carrega o endereco da frase a ser criptografada
	mov		di,0				; Carrega o indice para o local da frase a ser lido
	push	bx					; Salva o ponteiro na pilha
	push	di					; Salva o indice na pilha

NextCharInCrypto:
	; Chama a funcao para reiniciar o handle do arquivo
	mov		bx,FileHandle		; Carrega o handle do arquivo de entrada
	mov		dx,1				; Carrega o offset do inicio do arquivo
	call	ResetFile			; Chama a funcao para resetar a posicao no arquivo

	; Pega o proximo caractere da frase a ser criptografada
	pop		bx					; Recupera o ponteiro da pilha
	pop		di					; Recupera o indice da pilha
	mov		al,[bx+di]			; Pega a letra da frase a ser criptografada
	inc 	di					; Incrementa o indice
	push	bx					; Salva o ponteiro na pilha
	push	di					; Salva o indice na pilha

	; Testa se a frase acabou
	cmp		al,0				; Verifica se chegou ao fim da frase
	je		EndCryptoString 	; Se chegou ao fim da frase, pula para o fim da criptografia

	; Verifica se o caractere eh valido
	cmp		al,'!'				; Verifica se o caractere e maior que ponto de exclamacao
	jb		NextCharInCrypto	; Se for menor, pula para o proximo caractere, caractere invalido
	cmp		al,'~'				; Verifica se o caractere e maior que ponto de til
	ja		NextCharInCrypto	; Se for maior, pula para o proximo caractere, caractere invalido

	;!!Nao sei se eh necessario, mas vou deixar aqui, o pdf diz que tem um caso de caracter invalido, mas nao sei qual seria
	; ; Verifica se o caractere eh valido
	; cmp		al,' '				; Verifica se o caractere eh um espaco
	; je		NextCharInCrypto	; Se for um espaco, pula para o proximo caractere
	; cmp		al,'!'				; Verifica se o caractere e maior que ponto de exclamacao
	; jb		CryptoStringInvalid	; Se for menor, caractere invalido
	; cmp		al,'~'				; Verifica se o caractere e maior que ponto de til
	; ja		CryptoStringInvalid	; Se for maior, caractere invalido

	; Chama a funcao para procurar a letra no arquivo
	mov		CharSearchStore,al	; Salva o caractere a ser procurado
	mov		cx,0				; Carrega o indice para o local da frase a ser lido

Search:
	mov		dl,CharSearchStore	; Carrega o caractere a ser procurado
	mov		bx,FileHandle		; Carrega o handle do arquivo de entrada
	call 	SearchCharInFile	; Chama a funcao para procurar a letra no arquivo

	mov		di,0				; Reinicia o indice para testar contra o vetor de localizacoes

Revisar:
	mov		ax,[SenLocVec+di]	; Pega uma localizacao do vetor de localizacoes
	cmp		ax,0				; Verifica se a localizacao e vazia
	je		SetVetor			; Se for vazia, pula para a funcao de colocar no vetor
	cmp		cx,ax				; Verifica se a localizacao ja foi usada
	je		Search				; Se ja foi usada, pula para a funcao de procurar a proxima ocorrencia da letra
	add		di,2				; Incrementa o indice para o proximo elemento do vetor
	jmp		Revisar				; Volta para a funcao de revisar o vetor de localizacoes

SetVetor:
	mov		[SenLocVec+di],cx	; Coloca a localizacao no vetor de localizacoes
	jmp		NextCharInCrypto	; Pula para o proximo caractere da frase a ser criptografada

CryptoStringInvalid:
	lea		bx,MsgErrorSIC
	call	FileErrorHdlr

EndCryptoString:
	mov		bx,FileHandle		; Fecha arquivo origem, ele nao sera mais usado
	call	fclose				

	lea		ax,FileHandle		; Carrega o endereco do handle do arquivo de saida
	lea		bx,FileName			; Carrega o endereco do nome do arquivo
	lea		cx,FEKRP			; Carrega o endereco da extensao do arquivo de saida
	mov		dx,42h				; Carrega o modo de abertura do arquivo (qualquer coisa alem e 0 eh criacao)
	call	AEOF				; Chama a funcao para adicionar extensao e abrir o arquivo de saida

	mov		di,0				; Carrega o indice para o local do vetor a ser lido
	mov		bx,FileHandle		; Carrega o handle do arquivo de saida

EndCryptoStringLoop:
	mov		ax,[SenLocVec+di]	; Pega uma localizacao do vetor de localizacoes
	cmp		ax,0				; Verifica se a localizacao e vazia
	je		MainEnd				; Se for vazia, pula para o fim do arquivo
	call	NumToFile			; Chama a funcao para converter o numero para string e colocar no arquivo
	add		di,2				; Incrementa o indice para o proximo elemento do vetor
	jmp		EndCryptoStringLoop	; Volta para a funcao de revisar o vetor de localizacoes

MainEnd:
	call	NumToFile			; Chama a funcao para converter o numero para string e colocar no arquivo
	
	lea		bx,MsgDoneFS		; Carrega o endereco da mensagem de sucesso
	call	printf_s			; Chama a funcao para imprimir a mensagem de sucesso
	mov		ax,FileSize			; Carrega o tamanho do arquivo
	dec		ax					; Decrementa o tamanho do arquivo para o tamanho real
	call	printf_w			; Chama a funcao para imprimir o tamanho do arquivo
	lea		bx,MsgCRLF			; Carrega o endereco da mensagem de fim de linha
	call	printf_s			; Chama a funcao para imprimir a mensagem de fim de linha

	lea		bx,MsgDoneSSize		; Carrega o endereco da mensagem de sucesso
	call	printf_s			; Chama a funcao para imprimir a mensagem de sucesso
	lea		bx,Sentence			; Carrega o endereco da frase a ser criptografada
	call	Strlen				; Chama a funcao para calcular o tamanho da frase
	mov		ax,di				; Carrega o tamanho da frase
	call	printf_w			; Chama a funcao para imprimir o tamanho da frase
	lea		bx,MsgCRLF			; Carrega o endereco da mensagem de fim de linha
	call	printf_s			; Chama a funcao para imprimir a mensagem de fim de linha

	lea		bx,MsgDoneFN		; Carrega o endereco da mensagem de sucesso
	call	printf_s			; Chama a funcao para imprimir a mensagem de sucesso
	lea		bx,FileName			; Carrega o endereco do nome do arquivo
	call	printf_s			; Chama a funcao para imprimir o nome do arquivo
	lea		bx,FEKRP			; Carrega o endereco da extensao do arquivo de saida
	call	printf_s			; Chama a funcao para imprimir a extensao do arquivo de saida
	lea		bx,MsgCRLF			; Carrega o endereco da mensagem de fim de linha
	call	printf_s			; Chama a funcao para imprimir a mensagem de fim de linha

	mov		bx,FileHandle		; Fecha arquivo destino
	call	fclose
	lea		bx,MsgDone			; Carrega o endereco da mensagem de fim
	call	printf_s			; Chama a funcao para imprimir a mensagem de fim
	.exit	0					; Sai do programa

;===============================================================================
;	!!Subrotinas!!
;===============================================================================	

;###############################################################################
;	Subrotinas criadas para o programa
;###############################################################################

;----------------------------------------------------------------------
;	Subrotina para adicionar extensao e abrir arquivo
;Entrada:
;	ax -> ponteiro para local do handler	
;	bx -> ponteiro para o string do nome do arquivo
;	cx -> ponteiro para o string de extensao
;	dx -> Tipo de abertura do arquivo (0 para open e qualquer outra coisa para create)
;Saida:
;	NULL
;----------------------------------------------------------------------
AEOF	proc	near
	push	ax				; Salva o ponteiro do handler na pilha
	push	bx				; Salva o ponteiro do nome do arquivo
	push	dx				; Salva o modo de abertura do arquivo

	call	Strlen			; Chama a funcao para calcular o tamanho do nome do arquivo
	add		bx,di			; Soma o tamanho do nome do arquivo com o ponteiro do nome do arquivo
	push	bx				; Salva o ponteiro do final do nome do arquivo

	mov		bx,cx			; Carrega o ponteiro para o string de extensao
	mov		si,cx			; Coloca o ponteiro para o string de extensao no si
	
	call	Strlen			; Chama a funcao para calcular o tamanho da extensao
	mov		cx,di			; Carrega o tamanho da extensao no cx

	pop		di				; Carrega o ponteiro para o string do nome do arquivo + tamanho do nome do arquivo no di	

	push	ax				; Salva o ponteiro para o local do handler
	mov		ax,ds			; pega o segmento do ds
	mov		es,ax			; Coloca o segmento do ds no es
	pop		ax				; Carrega o ponteiro para o local do handler no ax

	rep		movsb			; Copia a extensao para o nome do arquivo

	pop		dx				; Carrega o modo de abertura do arquivo

	cmp		dx,0			; Verifica se o modo de abertura e 0
	je		AEOFOpen		; Se for 0, pula para a funcao de abrir o arquivo

AEOFCreate:
	pop		dx				; Carrega o ponteiro para o nome do arquivo no dx
	call	fcreate			; Chama a funcao para criar o arquivo
	mov		cx,bx			; Carrega o Handle do arquivo no cx
	pop		bx				; Carrega o ponteiro para o local do handler no bx
	mov		[bx],cx			; Coloca o handle no local de saida
	jnc		AEOFCleanup		; Se nao houve erro, pula para a funcao de limpeza
	lea		bx, MsgErrorCF	; Carrega o ponteiro para a mensagem de erro
	call	FileErrorHdlr	; Chama a funcao para tratar o erro
	
AEOFOpen:
	pop		dx				; Carrega o ponteiro para o nome do arquivo no dx
	call	fopen			; Chama a funcao para criar o arquivo
	mov		cx,bx			; Carrega o Handle do arquivo no cx
	pop		bx				; Carrega o ponteiro para o local do handler no bx
	mov		[bx],cx			; Coloca o handle no local de saida
	call	CheckFileSize	; Chama a funcao para verificar o tamanho do arquivo
	jnc		AEOFCleanup		; Se nao houve erro, pula para a funcao de limpeza
	lea		bx, MsgErrorOF	; Carrega o ponteiro para a mensagem de erro
	call	FileErrorHdlr	; Chama a funcao para tratar o erro

AEOFCleanup:
	mov		bx,dx			; Carrega o ponteiro para o nome do arquivo no bx
	call	Strlen			; Chama a funcao para calcular o tamanho do nome do arquivo
	mov		cx,4			; Carrega o tamanho da extensao no cx
	dec		di				; Decrementa o ponteiro para o final do nome do arquivo - 1
	mov		al,0			; Coloca 0 no al

AEOFCleanupLoop:
	mov		[bx+di],al		; Coloca 0 no final do nome do arquivo
	dec		di				; Decrementa o ponteiro para o final do nome do arquivo - 1
	loop	AEOFCleanupLoop	; Volta para a funcao de limpeza
	ret
AEOF	endp

;----------------------------------------------------------------------
;	Subrotina para descobrir o tamanho de uma string
;Entrada: 
;	bx -> ponteiro para o string
;Saida: 
;	di -> tamanho da string
;----------------------------------------------------------------------
Strlen	proc	near
	push	dx				; Salva o dx na pilha
	mov		dl,0			; Coloca 0 no dl
	mov		di,0			; Coloca 0 no di

StrlenLoop:
	cmp		[bx+di],dl		; Compara o byte atual com 0
	je		StrlenENd		; Se for igual, pula para o fim da funcao
	inc		di				; Incrementa o tamanho da string
	jmp		StrlenLoop		; Volta para o inicio da funcao

StrlenEnd:
	pop		dx				; Retorna o dx da pilha
	ret
Strlen	endp

;--------------------------------------------------------------------
;	Subrotina que mostra uma string e le o nome do arquivo do teclado
;Entrada:
;	bx -> ponteiro para o string a ser mostrado
;	ax -> ponteiro para onde sera colocado a string lida
;Saida:
;   NULL
;--------------------------------------------------------------------
Print_FAndGetS	proc	near
	push 	ax					; Salva o ponteiro para o local de saida
	call	printf_s			; Chama a funcao para mostrar a string

	mov		ah,0ah				; Carrega o codigo da funcao para ler uma string do teclado
	lea		dx,StringBuffer		; Carrega o ponteiro para o buffer de leitura
	mov		byte ptr StringBuffer,StringSize	; Coloca o tamanho do buffer no primeiro byte
	int		21h					; Chama a funcao para ler a string do teclado

	cmp		StringBuffer+1,MaxSenSize
	ja		PFAGSErrorSOF		; Se o tamanho da string for maior que o maximo, pula para a funcao de erro
	
	cmp		StringBuffer+1,0
	je		PFAGSErrorSE		; Se o tamanho da string for igual a 0, pula para a funcao de erro


	lea		si,StringBuffer+2	; Copia do buffer de teclado para o FileName
	pop		di					; Carrega o ponteiro para o local de saida no di
	mov		cl,StringBuffer+1	; Carrega o tamanho da string no cl
	mov		ch,0				; Coloca 0 no ch
	mov		ax,ds				; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax				; Ajusta ES=DS para poder usar o MOVSB
	rep 	movsb				; Copia a string do buffer para o local de saida

	mov		byte ptr es:[di],0	; Coloca marca de fim de string
		
	lea		bx,MsgCRLF			; Carrega o ponteiro para a string de quebra de linha
	call	printf_s			; Chama a funcao para mostrar a string de quebra de linha
	ret

PFAGSErrorSOF:
	lea		bx,MsgErrorSOF		; Carrega o ponteiro para a mensagem de erro
	call	FileErrorHdlr		; Chama a funcao para tratar o erro

PFAGSErrorSE:
	lea		bx,MsgErrorSE		; Carrega o ponteiro para a mensagem de erro
	call	FileErrorHdlr		; Chama a funcao para tratar o erro
Print_FAndGetS	endp


;--------------------------------------------------------------------
;	Subrotina que retorna o local da ocorrencia de uma letra
;Entrada:
;	bx -> FileHandle
;	dl -> letra a procurar
;Saida:
;	cx -> local da ocorrencia no arquivo
;--------------------------------------------------------------------
SearchCharInFile	proc	near
	; Faz um toUpper na letra de entrada para ser comparada com o arquivo
	cmp		dl,'a'
	jb		SearchCharInFileSave			
	cmp		dl,'z'
	ja		SearchCharInFileSave
	sub		dl,20h	

SearchCharInFileSave:
	mov 	CharSearchStore,dl	; Salva a letra para ser comparada com o arquivo
	mov 	ax,1				; Posiciona o numero de caracteres a serem lidos

loopSearchCharInFile:	
	inc 	cx					; Incrementa o local da ocorrencia
	call 	getChar				; Le um caractere do arquivo
	jc		SearchCharInFileErrorRC	; Se houve erro na leitura do arquivo, pula para a funcao de tratamento de erro
	cmp		ax,0						; Compara o caractere lido com 0 (fim do arquivo)
	je		SearchCharInFileErrorEOF	; Se chegou no fim do arquivo, pula para a funcao de tratamento de erro

	; Faz um toUpper na letra do arquivo
	cmp		dl,'a'
	jb		SearchCharInFileCmp			
	cmp		dl,'z'
	ja		SearchCharInFileCmp
	sub		dl,20h

SearchCharInFileCmp:
	cmp 	dl,CharSearchStore	; Compara a letra do arquivo com a letra de entrada
	jne 	loopSearchCharInFile; Se forem diferentes, continua a leitura do arquivo
	ret 						; Se forem iguais, retorna

SearchCharInFileErrorRC:
	lea		bx, MsgErrorRF		; Carrega o ponteiro para a string de erro
	call	FileErrorHdlr		; Chama a funcao de tratamento de erro

SearchCharInFileErrorEOF:
	lea		bx, MsgErrorFTS		; Carrega o ponteiro para a string de erro
	call	FileErrorHdlr		; Chama a funcao de tratamento de erro
SearchCharInFile	endp

;--------------------------------------------------------------------
;	Subrotina que posiciona o leitor no inicio do arquivo+offset
;Entrada:
;	bx -> FileHandle
;	dx -> offset do inicio do arquivo
;Saida:
;	bx -> FileHandle modificado para o novo offset
;--------------------------------------------------------------------
ResetFile	proc	near
	push 	ax					; Salva o ax
	push	cx					; Salva o cx
	mov		ah,42h				; Funcao Set File Pointer
	mov 	al,0				; Posiciona o ponteiro no inicio do arquivo (Seek_Set)
	mov		cx,0				; Pega o offset do arquivo desejado (parte maior)
	int		21h					; interrupt de arquivo
	jc		ResetFileSrcError	; Se houve erro na leitura do arquivo, pula para a funcao de tratamento de erro
	pop 	cx					; Restaura o cx
	pop		ax					; Restaura o ax
	ret

ResetFileSrcError:
	lea		bx,MsgErrorRSF		; Carrega o ponteiro para a string de erro
	call	FileErrorHdlr		; Chama a funcao de tratamento de erro
ResetFile	endp

;--------------------------------------------------------------------
;	Subrotina que transcreve um numero para Hex e coloca no arquivo aberto
;Entrada:
;	ax -> numero a ser transcrito
;Saida:
;	NULL
;--------------------------------------------------------------------
NumToFile	proc	near
	push	ax					; Salva o ax
	push	bx					; Salva o bx
	push	dx					; Salva o dx
	push	di					; Salva o di
	lea		bx,NumBuffer		; Carrega o ponteiro para o buffer de saida
	call	HexToString			; Chama a funcao para transcricao
	mov		di,0				; Coloca 0 no di

NTFLoop:
	mov		dl,[NumBuffer+di]	; Carrega o caractere do buffer
	cmp 	dl,0				; Compara o caractere com 0 (fim da string)
	je		NTFEnd				; Se for 0, pula para o fim da funcao
	mov		bx,FileHandle		; Carrega o FileHandle
	call	setChar				; Chama a funcao para escrever o caractere no arquivo
	jc		NTFError			; Se houve erro na escrita do arquivo, pula para a funcao de tratamento de erro
	inc		di					; Incrementa o di
	jmp		NTFLoop				; Volta para o inicio do loop
	
NTFEnd:
	pop		di					; Restaura o di
	pop		dx					; Restaura o dx
	pop		bx					; Restaura o bx
	pop		ax					; Restaura o ax
	ret

NTFError:
	lea		bx, MsgErrorWF		; Carrega o ponteiro para a string de erro
	call	FileErrorHdlr		; Chama a funcao de tratamento de erro
NumToFile	endp

;--------------------------------------------------------------------
;	Subrotina que converte um inteiro para string em hexadecimal
;Entrada:
;	ax -> numero a ser transcrito
;	bx -> ponteiro para o buffer de saida
;Saida:
;	NULL
;--------------------------------------------------------------------
HexToString proc near
	push 	ax					; Salva o ax
	push	cx					; Salva o cx
	push	dx					; Salva o dx
	push 	di					; Salva o di

	lea		dx,HexTable			; Carrega o ponteiro para a tabela de conversao
	mov		cx,4				; Coloca 4 no cx
	mov		di,0				; Coloca 0 no di

ByteLoop:
	ror		ax,12				; Rotaciona o ax 12 bits para a direita
	push	ax					; Salva o ax
	and		ax,000Fh			; Pega os 4 bits menos significativos

	xchg	bx,dx				; Troca o conteudo de bx e dx
	xlat						; Converte o byte em ax para o caractere correspondente
	xchg	bx,dx				; Troca o conteudo de bx e dx
	mov		[bx+di],al			; Coloca o caractere convertido no buffer

	inc		di					; Incrementa o di
	pop		ax					; Restaura o ax
	loop	ByteLoop			; Volta para o inicio do loop

	mov		[bx+di],cl			; Coloca o caractere de fim de string no buffer (por causa do loop cl vai ser 0)
	
	pop		di					; Restaura o di
	pop		dx					; Restaura o dx
	pop		cx					; Restaura o cx
	pop		ax					; Restaura o ax
	ret
HexToString endp

;--------------------------------------------------------------------
;	Subrotina que mostra o erro e fecha o arquivo caso ele esteja aberto
;Entrada:
;	bx -> ponteiro para a string de erro
;Saida:
;	NULL 
; 	!!TERMINA O PROGRAMA!!
;--------------------------------------------------------------------
FileErrorHdlr	proc	near
	push	bx					; Salva o bx
	lea		bx,MsgCRLF			; Carrega o ponteiro para a string de quebra de linha
	call	printf_s			; Chama a funcao para mostrar a string de quebra de linha
	pop		bx					; Restaura o bx
	call	printf_s			; Chama a funcao para mostrar a string de erro
	mov		bx,FileHandle		; Carrega o FileHandle
	cmp		bx,0				; Compara o FileHandle com 0
	je		FileErrorHdlrEnd	; Se for 0, pula para o fim da funcao
	call	fclose				; Chama a funcao para fechar o arquivo

FileErrorHdlrEnd:
	.exit 1						; Sai do programa com codigo de erro 1
FileErrorHdlr	endp

;--------------------------------------------------------------------
;	Subrotina que Testa se o tamanho do arquivo e valido
;Entrada:
;	NULL
;Saida:
;	NULL
;--------------------------------------------------------------------
CheckFileSize	proc	near
	push 	ax					; Salva o ax
	push 	bx					; Salva o bx
	push 	cx					; Salva o cx
	push 	dx					; Salva o dx
	pushf
	
	mov		cx,0				; Coloca 0 no cx
	push	cx					; Salva o cx
	mov		bx,FileHandle		; Carrega o FileHandle
	

CheckFileSizeLoop:
	mov		ah,3fh				; Coloca 3fh no ah
	lea		dx,FileSizeBuffer	; Carrega o ponteiro para o buffer de tamanho do arquivo
	mov		cx,1				; Coloca 1 no cx
	int		21h					; Chama a funcao 21h
	mov		dl,FileSizeBuffer	; Coloca o caractere lido em dl
	pop		cx					; Restaura o cx
	inc		cx					; Incrementa o cx
	mov		FileSize,cx			; Coloca o tamanho do arquivo em FileSize
	jc		CheckFileSizeError	; Se houve overflow, pula para a funcao de tratamento de erro, o arquivo e maior que 64kBytes
	cmp		ax,0				; Compara o ax com 0
	je		CheckFileSizeEnd	; Se chegou no final, pula para a funcao de tratamento de erro
	push	cx					; Salva o cx
	jmp		CheckFileSizeLoop	; Volta para o inicio do loop

CheckFileSizeEnd:
	mov		dx,0				; Coloca 0 no dx, offset do arquivo
	call	ResetFile 			; Chama a funcao para resetar o arquivo
	popf
	pop		dx					; Restaura o dx
	pop		cx					; Restaura o cx
	pop		bx					; Restaura o bx
	pop		ax					; Restaura o ax
	ret

CheckFileSizeError:
	lea		bx,MSgErrorFTL		; Carrega o ponteiro para a string de erro
	call	FileErrorHdlr		; Chama a funcao de tratamento de erro
CheckFileSize	endp

;###############################################################################
;	Subrotinas retiradas dos materiais de aula
;###############################################################################

;--------------------------------------------------------------------
;	Subrotina que abre o arquivo de nome apontado por dx em modo de leitura
;Entrada: 
;	dx -> ponteiro para o string com o nome do arquivo
;Saída:   
;	bx -> handle do arquivo
;	cf -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0			; Coloca 0 no al
	mov		ah,3dh			; Coloca 3dh no ah
	int		21h				; Chama a funcao 21h
	mov		bx,ax			; Coloca o handle do arquivo em bx
	ret						; Retorna
fopen	endp

;--------------------------------------------------------------------
;	Subrotina que abre o arquivo de nome apontado por dx em modo de escrita (cria o arquivo se nao existir)
;Entrada: 
;	dx -> ponteiro para o string com o nome do arquivo
;Saída:   
;	bx -> handle do arquivo
;	cf -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0			; Coloca 0 no cx
	mov		ah,3ch			; Coloca 3ch no ah
	int		21h				; Chama a funcao 21h
	mov		bx,ax			; Coloca o handle do arquivo em bx
	ret
fcreate	endp

;--------------------------------------------------------------------
;	Subrotina que fecha o arquivo apontado por bx
;Entrada:	
;	bx -> file handle
;saída:	
;	cf -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;--------------------------------------------------------------------
;	Subrotina que le um caractere no arquivo apontado por bx	
;Entrada:
;	bx -> file handle
;Saida:
;	dl -> caractere
;	ax -> numero de caracteres lidos
;	cf -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	push	cx				; Salva o cx
	mov		ah,3fh			; Coloca 3fh no ah
	mov		cx,1			; Coloca 1 no cx
	lea		dx,FileBuffer	; Carrega o ponteiro para o buffer de leitura
	int		21h				; Chama a funcao 21h
	mov		dl,FileBuffer	; Coloca o caractere lido em dl
	pop		cx				; Restaura o cx
	ret
getChar	endp
		
;--------------------------------------------------------------------
;	Subrotina que escreve um caractere vindo de dl no arquivo apontado por bx
;Entrada:
;	bx -> file handle
;	dl -> caractere
;Saida:
;	ax -> numero de caracteres escritos
;	cf -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	push	cx				; Salva o cx
	mov		ah,40h			; Coloca 40h no ah
	mov		cx,1			; Coloca 1 no cx
	mov		FileBuffer,dl	; Coloca o caractere em dl no buffer de escrita
	lea		dx,FileBuffer	; Carrega o ponteiro para o buffer de escrita
	int		21h				; Chama a funcao 21h
	pop		cx				; Restaura o cx
	ret
setChar	endp

;--------------------------------------------------------------------
;	Subrotina que escreve uma string apontado por bx na tela
;Entrada:
;	bx -> ponteiro para a string
;Saida:
;	NULL
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]			; Coloca o primeiro caractere da string em dl
	cmp		dl,0			; Compara o caractere com 0
	je		ps_1			; Se for 0, pula para o fim da funcao

	push	bx				; Salva o bx
	mov		ah,2			; Coloca 2 no ah
	int		21H				; Chama a funcao 21h
	pop		bx				; Restaura o bx

	inc		bx				; Incrementa o bx
	jmp		printf_s		; Volta para o inicio da funcao
		
ps_1:
	ret						; Retorna
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
	mov		byte ptr [bx],'0'
	inc		bx
sw_continua2:

	mov		byte ptr[bx],0
	ret		
sprintf_w	endp
;===============================================================================
		end
;===============================================================================