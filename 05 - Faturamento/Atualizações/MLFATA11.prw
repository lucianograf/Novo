#include 'protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} MLFATA11
Browser para impress�o de etiquetas de identifica��o a partir de itens de notas de entrada 
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 15/12/2020
@return return_Nil 
/*/
User function MLFATA11()

	Local		aAreaOld	:= GetArea()
	Local		aFields		:= {}
	Private 	oBrowser	:= FWMBrowse():New()
	Private 	aRotina		:= MenuDef()
	//Default cChave		:= ""

	// Atualiza a sequencia correta do SZ1 no SXE e SXF,
	DbSelectArea("SD1")
	DbSetOrder(1)

	Aadd(aFields,{"Nota"/*01*/,{|| SD1->D1_DOC}/*02*/,"C"/*03*/,PesqPict("SD1","D1_DOC")/*04*/,1/*05*/,TamSX3("D1_DOC")[1]/*06*/,TamSX3("D1_DOC")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	Aadd(aFields,{"Data Entrada"/*01*/,{|| SD1->D1_DTDIGIT}/*02*/,"D"/*03*/,PesqPict("SD1","D1_DTDIGIT")/*04*/,1/*05*/,TamSX3("D1_DTDIGIT")[1]/*06*/,TamSX3("D1_DTDIGIT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Produto"/*01*/,{|| SD1->D1_COD}/*02*/,"C"/*03*/,PesqPict("SD1","D1_COD")/*04*/,1/*05*/,TamSX3("D1_COD")[1]/*06*/,TamSX3("D1_COD")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Quantidade"/*01*/,{|| SD1->D1_QUANT}/*02*/,"N"/*03*/,PesqPict("SD1","D1_QUANT")/*04*/,1/*05*/,TamSX3("D1_QUANT")[1]/*06*/,TamSX3("D1_QUANT")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//Aadd(aFields,{"Etq.Impressas"/*01*/,{|| SD1->D1_XPRTETQ}/*02*/,"N"/*03*/,PesqPict("SD1","D1_XPRTETQ")/*04*/,1/*05*/,TamSX3("D1_XPRTETQ")[1]/*06*/,TamSX3("D1_XPRTETQ")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})
	//D1_XPRTETQ
	//[n][01] T�tulo da coluna
	//[n][02] Code-Block de carga dos dados
	//[n][03] Tipo de dados
	//[n][04] M�scara
	//[n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
	//[n][06] Tamanho
	//[n][07] Decimal
	//[n][08] Indica se permite a edi��o
	//[n][09] Code-Block de valida��o da coluna ap�s a edi��o
	//[n][10] Indica se exibe imagem
	//[n][11] Code-Block de execu��o do duplo clique
	//[n][12] Vari�vel a ser utilizada na edi��o (ReadVar)
	//[n][13] Code-Block de execu��o do clique no header
	//[n][14] Indica se a coluna est� deletada
	//[n][15] Indica se a coluna ser� exibida nos detalhes do Browse
	//[n][16] Op��es de carga dos dados (Ex: 1=Sim, 2=N�o)

	oBrowser:SetFields(aFields)

	oBrowser:SetAlias('SD1')
	oBrowser:SetOnlyFields( { 'D1_FILIAL', 'D1_DOC', 'D1_DTDIGIT' , 'D1_COD' , 'D1_QUANT'  } )
	oBrowser:SetDescription('Impress�o de Etiquetas de Produtos ')


	// Legenda
	//oBrowser:AddLegend( " DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN) .OR. EMPTY(ZX_DTFIN))	" 	, "OK"		, "Vigente"	)
	//oBrowser:AddLegend( "!(	DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN)))						"	, "CANCEL"	, "N�o Vigente"	)

	// Filtro
	// Comentado o filtro pois a rotina de apontamento ir� gerar e encerrar a OP a cada apontamento, n�o ficando mais OP em aberto
	If GetNewPar("GFMLFAT11X",.T.)
		oBrowser:SetFilterDefault(" D1_TIPO $ 'D#N' .And. !(D1_CF $ '1353 #2353 #1933 #2202 #2933 #1253 #1907 #1407 #1303 #1949 #2949 ') ")
	Else 
		oBrowser:SetFilterDefault(" D1_XPRTETQ < D1_QUANT .And. D1_DTDIGIT > dDatabase-30 .And. D1_TIPO $ 'D#N' .And. !(D1_CF $ '1353 #2353 #1933 #2202 #2933 #1253 #1907 #1407 #1303 #1949 #2949 ') ")
	Endif 
	oBrowser:Activate()

	RestArea(aAreaOld)

Return Nil



/*/{Protheus.doc} ModelDef
//Fun��o para obter a estrutura da tabela SC2 
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return oModel, Objeto MPFormModel
@type function
/*/
Static Function ModelDef()

	Local oStruSC2
	Local oModel

	// Cria o objeto do Modelo de Dados - Tem que ser diferente do nome do Fonte.
	oModel := MPFormModel():New('MODEL_MLFATA11',{|oModel| sfBeforeModel(oModel)}/*bPreValidacao*/, { |oModel| sfAfterModel(oModel) }/*bPosValidacao*/, /*bCommit*/,/*bCancel*/ )

	// Monta as estruturas das tabelas
	oStruSC2 := FWFormStruct( 1, 'SD1', ,/*lViewUsado*/ )

	//Adiciona Enchoices
	oModel:AddFields( 'MLFATA11', /*cOwner*/, oStruSC2 )


Return ( oModel )



/*/{Protheus.doc} ViewDef
// Fun��o para retornar interface da edi��o/visualiza��o do Registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return oView, Objeto FWFormView

@type function
/*/
Static Function ViewDef()
	Local oView		:= nil
	Local oModel	:= FWLoadModel( 'MLFATA11' )
	Local oStruSD1


	// Monta as estruturas das tabelas
	oStruSD1 := FWFormStruct( 2, 'SD1')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("MLFATA11", oStruSD1, "MLFATA11")
	oView:CreateHorizontalBox( "MASTER" , 100, /*cIDOwner*/, /*lFixPixel*/, /*cIDFolder*/, /*cIDSheet*/ )
	oView:SetOwnerView( "MLFATA11" , "MASTER" )

Return oView
 


/*/{Protheus.doc} MenuDef
// Fun��o que retorna os bot�es do Menu do Browser
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return aRotina, Array com os bot�es 

@type function
/*/
Static Function MenuDef()

	Local aRotina	:= {}
	If __cUserId $ GetNewPar("GF_MLFAT11","000016")
		aAdd( aRotina, { 'Visualizar'	        , 'VIEWDEF.MLFATA11', 0, 2, 0, NIL } )
	Endif 
	aAdd( aRotina, { 'Impress�o Etiquetas' 	, 'StaticCall(MLFATA11,sfPrintEtq)', 0, 5, 0, NIL } )


Return ( aRotina )


/*/{Protheus.doc} sfBeforeModel
// Fun��o a ser executada antes de abrir a tela do Registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return lRet, L�gico
@param oModel, object, descricao
@type function
/*/
Static Function sfBeforeModel(oModel)
	Local 	nOpc		:= oModel:nOperation
	Local	lRet		:= .T.


Return lRet


/*/{Protheus.doc} sfAfterModel
// Fun��o que valida a tela do registro ap�s confirmar a tela do registro
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return lRet, L�gico 
@param oModel, object, descricao
@type function
/*/
Static Function sfAfterModel(oModel)

	Local nOpc		:= oModel:nOperation
	Local nRecNo	:= Iif(nOpc == 3,0,SD1->(Recno())) //Se for INCLUS�O Ignora Recno
	Local lRet		:= .T.

Return lRet


/*/{Protheus.doc} sfPrintEtq
//Fun��o respons�vel pela impress�o das etiquetas de R�tulos
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return  Nil 
@type function
/*/
Static Function sfPrintEtq()

	Local		aAreaOld	:= GetArea()
	Local		lIsHomologa	:= .F.
	Local		cPrintMsg	:= ""
	Local		cPrintTxt	:= ""
	Local		oPanelDlg
	Local		oDlgEtq
	Local		lOk
	Local		nQteEtq		:= SD1->D1_QUANT - SD1->D1_XPRTETQ
	Local		ix
	Local       cCodBar
	Private 	lImprInvent		:= .F. 

	If GetNewPar("GFMLFAT11X",.T.)
		lImprInvent		:= .T.
		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSeek(xFilial("SB2")+SD1->D1_COD+SD1->D1_LOCAL) 
		nQteEtq			:= SB2->B2_QATU 
		MsgInfo("Impress�o de etiquetas para invent�rio. Quantidade exibida � o estoque fisico do item")
	Endif 
	// Posiciona no cadastro de Produto
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+SD1->D1_COD)

	cCodBar     := SB1->B1_CODBAR


	If __cUserId $ GetNewPar("GF_MLFAT11","000016")
		If MsgNoYes("Gerar apenas relat�rio de impress�o de etiquetas?   Usado para quando n�o houver impressora Argox f�sica.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			lIsHomologa	:= .T.
		Endif
	Endif

	DEFINE MSDIALOG oDlgEtq FROM 000,000 TO 230,400 Of oMainWnd Pixel Title OemToAnsi("Informe o n�mero de etiquetas que ser�o impressas!" )

	oPanelDlg := TPanel():New(0,0,'',oDlgEtq, oDlgEtq:oFont, .T., .T.,, ,200,65,.T.,.T. )
	oPanelDlg:Align := CONTROL_ALIGN_ALLCLIENT

	@ 010,005 Say "N�mero de Etiquetas" of oPanelDlg Pixel
	@ 010,060 MsGet nQteEtq	Size 40,10 Valid (nQteEtq > 0  .And. nQteEtq <= ( Iif(lImprInvent,9999,SD1->D1_QUANT - SD1->D1_XPRTETQ) ) ) Size 30,10 of oPanelDlg Pixel

	@ 026,005 Say "C�digo de Barras" of oPanelDlg Pixel
	@ 025,060 MsGet cCodBar	Size 60,10  Size 30,10 of oPanelDlg Pixel When .F.

	Activate MsDialog oDlgEtq On Init EnchoiceBar(oDlgEtq,{|| lOk := .T., oDlgEtq:End() },{|| oDlgEtq:End()},,)

	If !lOk
		Return
	Endif

	//Inicio da Imagem da Etiqueta

	//1  nXmm 		Array of Record		Posi��o X em Mil�metros				X
	//2  nYmm		Array of Record		Posi��o Y em Mil�metros				X
	//3  cTexto		Array of Record		String a ser impresso ou itens especificando uma vari�vel "@".(Ex: "@2").
	//Obs: quando for especificado uma vari�vel, o seu conte�do dever� ser apenas o caractere "@" seguido de um n�mero, "@1" ou "@2" e assim por diante.
	//4  cRota��o Array of Record 	String com o tipo de Rota��o (N,R,I,B): N - Normal R - Cima para baixo  I - Invertido B - Baixo para cima
	//5  cFonte 	Array of Record		String com os tipos de Fonte:
	//Zebra - (A,B,C,D,E,F,G,H,0) 0(zero)- fonte escalar
	//Datamax - (0,1,2,3,4,5,6,7,8,9) 9 � fonte escalar
	//Eltron - (0,1,2,3,4,5)
	//Intermec - (0,1,7,20,21,22,27)
	//6  cTam		Array of Record		String com o tamanho da Fonte
	//7  *lReverso 	Array of Record	Imprime em reverso quando tiver sobre um box preto
	//8  lSerial	Array of Record		Serializa o c�digo
	//9  cIncr		Array of Record		Incrementa quando for serial positivo ou negativo
	//10 *lZerosL	Array of Record		Coloca zeros a esquerda no numero serial
	//11 lNoAlltrim	Array of Record		Permite brancos a esquerda e direi

	/*
	+-------------------------------------------------------------+
	|Dt.Ent.: 00/00/0000  N.NF.: 000000000                        |
	|                                                            |
	|Produto: 1234567890123456                                                             |
	| +----------------------------+                              |            
	| | C�digo de barras Ean13     |                              |
	| +----------------------------+                              |
	|                                                             |
	+-------------------------------------------------------------+
	*/

	DbSelectArea("CB0")
	RecLock("CB0",.T.)
	CB0->CB0_FILIAL	:= xFilial("CB0")
	CB0->CB0_CODETI := GetSXENum("CB0","CB0_CODETI")            //Cod.Etiqueta
	CB0->CB0_TIPO   := "01"                                     //Tipo da Etiq  01=Produto;02=Endereco;03=Unitizador;04=Usuario;05=Volume
	CB0->CB0_CODPRO := SD1->D1_COD                              //Produto
	CB0->CB0_QTDE   := nQteEtq                                  //Quantidade
	CB0->CB0_USUARI := cUserName                                //Usuario
	CB0->CB0_DISPID := ComputerName()                           //Dispositivo
	CB0->CB0_LOCAL  := SD1->D1_LOCAL                            //Almoxarifado
	//CB0->CB0_LOCALI                     //Endereco
	CB0->CB0_FORNEC := SD1->D1_FORNECE                          //Cod fornece
	CB0->CB0_LOJAFO := SD1->D1_LOJA                             //Loja fornece
	CB0->CB0_NFENT  := SD1->D1_DOC                              //NF de entrad
	CB0->CB0_SERIEE := SD1->D1_SERIE                            //Serie NF ent
	CB0->CB0_STATUS := "3"                                      //Status Etiq. 1=Encerrada Requisicao;2=Encerrada Inventario;3=Encerrada Mov. Interno.
	CB0->CB0_ITNFE  := SD1->D1_ITEM                             //Item NFE
	MsUnlock()

	ConfirmSX8()


	For iX := 1 To nQteEtq
		If !lIsHomologa
			cPrintMsg   := ""
			_cPorta := Alltrim(GetNewPar("GF_PORLPT2","LPT1:9600,n,8,1"))

			MSCBPRINTER("ALLEGRO",_cPorta,Nil,) 	//Seta tipo de impressora

			MSCBCHKSTATUS(.F.)

			MSCBBEGIN(1,4)

			
			cPrintTxt	:= " Produto: "
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(05,30,cPrintTxt,"N","2","001,001") //Imprime Texto

			cPrintTxt	:= SB1->B1_COD
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(20,27,cPrintTxt,"N","9","004,003") //Imprime Texto


			cPrintTxt	:= Substr(SB1->B1_DESC,1,24)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(06,23,cPrintTxt,"N","9","003,002") //Imprime Texto


			cPrintTxt	:= Substr(SB1->B1_DESC,25,16)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(06,19,cPrintTxt,"N","9","003,002") //Imprime Texto

			cPrintTxt	:= cCodBar
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(33,1,cPrintTxt,"N","9","003,002") //Imprime Texto


			//MSCBSAYBAR(30,03,Alltrim(StrTran(AllTrim(Transform("33442Z","@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
			//MSCBSAYBAR(06,10,AllTrim(cCodBar),,"N","MB04"/*MB04 - EAN 13 */,14,.T./*lDigver*/,.T./*lLinha*/,.F.,,3,2,.F.)

			MSCBSAYBAR(33,05.5,Alltrim(StrTran(AllTrim(cCodBar),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)

			/*MSCBSAY(	nXmm 		Posi��o X em Mil�metros
			nYmm 		Posi��o Y em Mil�metros
			cTexto 		String a ser impresso 
			cRota��o 	String com o tipo de Rota��o (N,R,I,B): N - Normal R - Cima para baixo I - Invertido B - Baixo para cima
			cFonte 		String com os tipos de Fonte: Datamax - (0,1,2,3,4,5,6,7,8,9) 9 � fonte escalar
			cTam 		String com o tamanho da Fonte
			lReverso	Imprime em reverso quando tiver sobre um box preto
			*/ 



			cResult := MSCBEND()
			//MsgInfo(cResult)
			MSCBCLOSEPRINTER()

			// Atualiza a contagem de etiquetas impressas
			DbSelectArea("SD1")
			RecLock("SD1",.F.)
			SD1->D1_XPRTETQ += nQteEtq
			MsUnlock()

		Else
			cPrintMsg   := ""

			cPrintTxt	:= " Produto: "
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= SB1->B1_COD
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= Substr(SB1->B1_DESC,1,24)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= Substr(SB1->B1_DESC,25,16)
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "C�d.Bar: " + cCodBar
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			If !Empty(cPrintMsg)
				Aviso("Impress�o de etiqueta",cPrintMsg,{"Ok"},3)
			Endif
		Endif
	Next

	//MSCBSAYBAR(23,;	// 1 - Posi��o X em Mil�metros
	//22,;			// 2 - Posi��o Y em Mil�metros
	//Strzero(1,10),; // 3 - String a ser impressa especificando uma vari�vel "@" ou array somente quando o par�metro cTypePrt for igual � MB07.  cConteudo :={{"01","07893316010411"},; {"10","0000970100"+MSCB128B()+"1"+MSCB128C()},; {"37","0004"},; {"21","000494"}} � A possi��o 1 do array (ex: �01�) informa o AI utilizadado (que ser� visto no item 3.6.1. �Utiliza��o do c�digo de barras 128�).� J� a possi��o 2 do array (ex: "07893316010411�) � o conte�do do AI.
	//"MB07",;		// 4 - String com o Modelo de C�digo de Barras: MB01 - Interleaved 2 of 5 / EAN14 MB02 - Code 39  MB03 - EAN 8 MB04 - EAN 13 MB05 - UPC A MB06 - UPC E MB07 - CODE 128 Obs: Caso o leitor queira utilizar o modelo do padr�o de programa��o da impressora, o mesmo dever� consultar documenta��o do fabricante.
	//"C",;			// 5
	//8.36,;			// 6 - Altura do c�digo de Barras em Mil�metros
	//.F.,;
		//.T.,;
		//.F.,;
		//,;
		//2,;
		//1)

	//MemoWrit('FZPCPA01',cResult)


	RestArea(aAreaOld)

Return



/*/{Protheus.doc} sfNoAcento
//Fun��o que remove caracteres especiais digitados. 
@author Marcelo Alberto Lauschner
@since 21/01/2019
@version 1.0
@return cString , Caractere 
@param cString, characters, descricao
@type function
/*/
Static Function sfNoAcento(cString)

	Local cChar  := ""
	Local nX     := 0
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "�����"+"�����"
	Local cCircu := "�����"+"�����"
	Local cTrema := "�����"+"�����"
	Local cCrase := "�����"+"�����"
	Local cTio   := "����"
	Local cCecid := "��"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"
	Local cGrau	 := "��"

	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cAgudo)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCircu)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cTrema)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr(cVogal,nY,1),cCrase)
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTio)
			If nY > 0
				//MsgAlert(cValToChar(nY) + "|"+ cChar+"|"+SubStr("aoAO",nY,1),cTio)
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf

			nY:= At(cChar,cGrau)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("oa",nY,1))
			EndIf

		Endif
	Next

	If cMaior$ cString
		cString := strTran( cString, cMaior, "" )
	EndIf
	If cMenor$ cString
		cString := strTran( cString, cMenor, "" )
	EndIf

	cString := StrTran( cString, CRLF, " " )

	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|'
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString
