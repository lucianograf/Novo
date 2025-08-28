#include 'protheus.ch'
#Include 'FWMVCDef.ch'
#include 'topconn.ch'

/*/{Protheus.doc} MLFATA12
Browser para impress�o de etiquetas de identifica��o a partir do produto posicionado 
@type function
@version 1.0
@author Marcelo Alberto Lauschner
@since 05/10/2021
@return return_Nil 
/*/
User function MLFATA12()

	Local		aAreaOld	:= GetArea()
	Local		aFields		:= {}
	Private 	oBrowser	:= FWMBrowse():New()
	Private 	aRotina		:= MenuDef()
	//Default cChave		:= ""

	// Atualiza a sequencia correta do SZ1 no SXE e SXF,
	DbSelectArea("SB1")
	DbSetOrder(1)

	//Aadd(aFields,{"C�digo"/*01*/,{|| SB1->B1_COD}/*02*/,"C"/*03*/,PesqPict("SB1","B1_COD")/*04*/,1/*05*/,TamSX3("B1_COD")[1]/*06*/,TamSX3("B1_COD")[2]/*07*/,/*08*/,/*09*/,/*10*/,/*11*/,/*12*/,/*13*/,/*14*/,/*15*/,/*16*/})

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

	oBrowser:SetAlias('SB1')
	oBrowser:SetOnlyFields( { } )
	oBrowser:SetDescription('Impress�o de Etiquetas de Produtos ')


	// Legenda
	//oBrowser:AddLegend( " DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN) .OR. EMPTY(ZX_DTFIN))	" 	, "OK"		, "Vigente"	)
	//oBrowser:AddLegend( "!(	DTOS(dDataBase) >= DTOS(ZX_DTINI) .AND. (DTOS(dDataBase) <= DTOS(ZX_DTFIN)))						"	, "CANCEL"	, "N�o Vigente"	)

	// Filtro
	oBrowser:SetFilterDefault(" B1_MSBLQL <> '1'  ")
	oBrowser:Activate()

	RestArea(aAreaOld)

Return Nil



/*/{Protheus.doc} ModelDef
//Fun��o para obter a estrutura da tabela SB1
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
	oModel := MPFormModel():New('MODEL_MLFATA12',{|oModel| sfBeforeModel(oModel)}/*bPreValidacao*/, { |oModel| sfAfterModel(oModel) }/*bPosValidacao*/, /*bCommit*/,/*bCancel*/ )

	// Monta as estruturas das tabelas
	oStruSC2 := FWFormStruct( 1, 'SB1', ,/*lViewUsado*/ )

	//Adiciona Enchoices
	oModel:AddFields( 'MLFATA12', /*cOwner*/, oStruSC2 )


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
	Local oModel	:= FWLoadModel( 'MLFATA12' )
	Local oStruSD1


	// Monta as estruturas das tabelas
	oStruSD1 := FWFormStruct( 2, 'SB1')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("MLFATA12", oStruSD1, "MLFATA12")
	oView:CreateHorizontalBox( "MASTER" , 100, /*cIDOwner*/, /*lFixPixel*/, /*cIDFolder*/, /*cIDSheet*/ )
	oView:SetOwnerView( "MLFATA12" , "MASTER" )

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
	If __cUserId $ GetNewPar("GF_MLFAT12","000016")
		aAdd( aRotina, { 'Visualizar'	        , 'VIEWDEF.MLFATA12', 0, 2, 0, NIL } )
	Endif
	aAdd( aRotina, { 'Impress�o Etiquetas' 	, 'StaticCall(MLFATA12,sfPrintEtq)', 0, 5, 0, NIL } )


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
	Local		lOk			:= .F. 
	Local       cQry
	Local 		cDescricao		:= Space(30)
	Local 		cPais			:= Space(30)
	Local 		cProdutor		:= Space(50)
	Local 		nPreco			:= 0
	Local 		cB1Cod			:= Space(15)
	Private 	lImprInvent		:= .F.


//	If __cUserId $ GetNewPar("GF_MLFAT12","000016")
	//If MsgNoYes("Gerar apenas relat�rio de impress�o de etiquetas?   Usado para quando n�o houver impressora Argox f�sica.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	//	lIsHomologa	:= .T.
	//Endif
//	Endif



	cQry := "SELECT ISNULL(ZFT_DESCR,'ZFT - FALTA CAD FICHA') AS DESCRICAO, "
	cQry += "       ISNULL(YA_DESCR,'SYA - FALTA CAD PRODUTOR') AS PAIS, "
	cQry += "       ISNULL(Z03_DESCRI,'Z03 - FALTA CAD PRODUTOR') AS PRODUTOR, "
	cQry += "       ISNULL(DA1_PRCVEN,0) AS PRECO,"
	cQry += "       B1_COD "
	cQry += "  FROM " + RetSqlName("SB1") + " SB1 "
	cQry += "  LEFT OUTER JOIN " + RetSqlName("ZFT") + " ZFT "
	cQry += "    ON B1_ZFT = ZFT_COD "
	cQry += "   AND ZFT.D_E_L_E_T_ <> '*' "
	cQry += "  LEFT OUTER JOIN " + RetSqlName("Z03")  + " Z03 "
	cQry += "    ON Z03_CODIGO = ZFT_PRODUT "
	cQry += "   AND Z03.D_E_L_E_T_ <> '*'
	cQry += "  LEFT OUTER JOIN " + RetSqlName("SYA") + " SYA "
	cQry += "    ON Z03_PAIS = YA_CODGI "
	cQry += "   AND SYA.D_E_L_E_T_ <> '*' "
	cQry += "  LEFT OUTER JOIN " + RetSqlName("DA1") + " DA1 "
	cQry += "    ON DA1_CODPRO = B1_COD "
	cQry += "   AND DA1.D_E_L_E_T_ <> '*' "
	cQry += "   AND DA1_CODTAB = '"+GetNewPar("DC_MFT12TB","201") + "' "
	cQry += " WHERE SB1.D_E_L_E_T_ =' ' "
	cQry += "   AND B1_COD = '"  + SB1->B1_COD + "' "
	cQry += "   AND B1_FILIAL = '" + SB1->B1_FILIAL + "' "

	TcQuery cQry New Alias "QRB1"

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
	| DESCRICAO
    | PAIS			    PRODUTOR
    | Cod: CODIGO		Pre�o: R$ PRECO
    |
	|                                                             |
	+-------------------------------------------------------------+
	*/
	If !Eof()

		cDescricao		:= Substr(QRB1->DESCRICAO,1,30)
		cPais			:= Capital(QRB1->PAIS)
		cProdutor		:= Substr(QRB1->PRODUTOR,1,25)
		nPreco			:= QRB1->PRECO
		cB1Cod			:= StrTran(QRB1->B1_COD,"-","")

		DEFINE MSDIALOG oDlgEtq FROM 000,000 TO 270,500 Of oMainWnd Pixel Title OemToAnsi("Dados da etiqueta que ser�o impressa!" )

		oPanelDlg := TPanel():New(0,0,'',oDlgEtq, oDlgEtq:oFont, .T., .T.,, ,200,65,.T.,.T. )
		oPanelDlg:Align := CONTROL_ALIGN_ALLCLIENT

		@ 012,005 Say "Descri��o" of oPanelDlg Pixel
		@ 010,060 MsGet cDescricao	Size 150,10  of oPanelDlg Pixel

		@ 027,005 Say "Pa�s" of oPanelDlg Pixel
		@ 025,060 MsGet cPais	Size 80,10  of oPanelDlg Pixel
		
		@ 042,005 Say "Produtor" of oPanelDlg Pixel
		@ 040,060 MsGet cProdutor	Size 90,10  of oPanelDlg Pixel
		
		@ 057,005 Say "Pre�o" of oPanelDlg Pixel
		@ 055,060 MsGet nPreco	Picture "@E 999,999,999.99" Size 80,10  of oPanelDlg Pixel
		
		@ 072,005 Say "C�digo" of oPanelDlg Pixel
		@ 070,060 MsGet cB1Cod	Size 80,10  of oPanelDlg Pixel
		

		Activate MsDialog oDlgEtq On Init EnchoiceBar(oDlgEtq,{|| lOk := .T., oDlgEtq:End() },{|| oDlgEtq:End()},,)

		If !lOk
			QRB1->(DbCloseArea() )
			Return
		Endif

		If !lIsHomologa
			cPrintMsg   := ""
			_cPorta := Alltrim(GetNewPar("GF_PORLPT2","LPT1" )) //:9600,n,8,1"))
			MSCBPRINTER("ZEBRA",_cPorta,,,.f.,,,,,,.f.,)

			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,6)

			cPrintTxt	:= cDescricao
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

MSCBBOX(02,02,98,30)

			MSCBSAY(03,03,cPrintTxt,"N","0","070,040") //Imprime Texto


			cPrintTxt	:= Alltrim(cProdutor)  + " - " + Capital(Alltrim(cPais))
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(03,11,cPrintTxt,"N","0","050,030") //Imprime Texto


			cPrintTxt	:= "R$ " + Alltrim(Transform(nPreco,"@E 999,999,999.99"))
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			MSCBSAY(50,17,cPrintTxt,"N","0","115,050") //Imprime Texto


			//MSCBSAYBAR(30,03,Alltrim(StrTran(AllTrim(Transform("33442Z","@R 99.99.9.X")),"-","")),"N","MB07",12,.F.,.T.,.F.,,2,2,.F.)
			//MSCBSAYBAR(06,10,AllTrim(cCodBar),,"N","MB04"/*MB04 - EAN 13 */,14,.T./*lDigver*/,.T./*lLinha*/,.F.,,3,2,.F.)

			MSCBSAYBAR(05,19,Alltrim(StrTran(AllTrim(cB1Cod),"-","")),"N","MB07",6,.F.,.T.,.F.,,2,2,.F.)



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
		Else
			cPrintMsg   := ""

			cPrintTxt	:= "Descri��o: " + cDescricao
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "Pa�s: " + cPais
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "Produtor: " + cProdutor
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "C�d.Barras: "+ cB1Cod
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt

			cPrintTxt	:= "Pre�o: " + Alltrim(Transform(nPreco,"@E 999,999,999.99"))
			cPrintMsg 	+= Chr(13)+Chr(10)+cPrintTxt


			If !Empty(cPrintMsg)
				Aviso("Impress�o de etiqueta",cPrintMsg,{"Ok"},3)
			Endif
		Endif
	Endif

	QRB1->(DbCloseArea() )
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
