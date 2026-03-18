#include 'protheus.ch'
#include 'topconn.ch'
Static aCxEnderAdd

/*/{Protheus.doc} XMLCTE08
// Ponto de entrada para preencher automaticamente número de Lote para lançamento de notas da Frimazo e Redelog
@author Marcelo Alberto Lauschner
@since 07/09/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function XMLCTE08()

	Local	aAreaOld	:= GetArea()

	Local	nPosItem		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ITEM"} )
	Local	nPosCodPr		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_COD"} )
	Local	nPosTes			:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_TES"} )
	Local	nPosLocal		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_LOCAL"} )
	Local	nPosLtCtl		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_LOTECTL"} )
	Local	nPosNumLt		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_NUMLOTE"} )
	Local	nPosDFabr		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_DFABRIC"} )
	Local	nPosDtVald		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_DTVALID"} )
	Local	nPosQte 		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_QUANT"} )
	Local	nPosEnderc		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ENDEREC"} )
	Local	nPosQtSeg		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_QTSEGUM"} )
	Local   cQry        	:= ""
	Local 	iQ
	Local 	cAtuEstoque 	:= "N"

	If cEmpAnt == "05" .And. Rastro(aLinha[nPosCodPr][2]) .And. CONDORXML->XML_TIPODC == "N" .And. !Empty(SA2->A2_FILTRF)

		If nPosTes > 0
			DbSelectArea("SF4")
			DbSetOrder(1)
			If DbSeek(xFilial("SF4") + aLinha[nPosTes,2])
				cAtuEstoque	:= SF4->F4_ESTOQUE
			Endif
		Endif
		If cAtuEstoque == "S"
			cQry := "SELECT C6_LOCALIZ,D2_LOCALIZ,D2_DTVALID,D2_DFABRIC,D2_NUMLOTE,D2_LOTECTL,D2_TOTAL,D2_PRCVEN,D2_QTSEGUM,D2_QUANT,D2_UM,D2_COD,D2_ITEM"
			cQry += "  FROM " + RetSqlName("SF2") + " F2 "
			cQry += " INNER JOIN " + RetSqlName("SD2") + " D2 "
			cQry += "    ON D2.D_E_L_E_T_ = ' ' "
			// Filtro caixas já usadas
			If aCxEnderAdd <> Nil .And. Len(aCxEnderAdd) > 0 
				cQry += "   AND D2_LOCALIZ NOT IN("
				For iQ := 1 To Len(aCxEnderAdd)
					If iQ > 1
						cQry += ","
					Endif
					cQry += "'" + aCxEnderAdd[iQ] + "'"
				Next
				cQry += "   )"
			Endif
			cQry += "   AND D2_LOJA = F2_LOJA "
			If nPosLtCtl > 0
				cQry += "   AND D2_LOTECTL = '" + aLinha[nPosLtCtl][2] + "' "
			Endif
			cQry += "   AND D2_CLIENTE = F2_CLIENTE "
			cQry += "   AND D2_SERIE = F2_SERIE "
			cQry += "   AND D2_QUANT  = " + cValToChar(aLinha[nPosQte][2])
			If nPosQtSeg > 0
				cQry += "   AND D2_QTSEGUM = "+ cValToChar(aLinha[nPosQtSeg][2])
			Endif
			cQry += "   AND D2_COD = '" + aLinha[nPosCodPr][2] +  "' "			// Produto
			cQry += "   AND D2_DOC = F2_DOC "
			cQry += "   AND D2_FILIAL = '" + SA2->A2_FILTRF + "' "
			cQry += " INNER JOIN " + RetSqlName("SC6") + " C6 "
			cQry += "    ON C6.D_E_L_E_T_ =' ' "
			cQry += "   AND C6_ITEM = D2_ITEMPV "
			cQry += "   AND C6_PRODUTO = D2_COD "
			cQry += "   AND C6_NUM = D2_PEDIDO "
			cQry += "   AND C6_FILIAL = '" + IIf(!Empty(xFilial("SC6")),SA2->A2_FILTRF,xFilial("SC6")) + "' "
			cQry += " WHERE F2.D_E_L_E_T_  = ' ' "
			cQry += "   AND F2_TIPO = 'N' "
			cQry += "   AND F2_CHVNFE = '" + aArqXml[oArqXml:nAt,nPosChvNfe] + "' " // Chave da nota de saída da Devolução
			cQry += "   AND F2_FILIAL = '" + SA2->A2_FILTRF + "' "

			TCQUERY cQry NEW ALIAS "QRSD2"

			If !Eof()

				//aFill  	Preenche os elementos de um array com um determinado	aFill( <aDados>, <xInfo>, <nPos>, <nQtd> )
				//aIns  	Insere um novo elemento, com conteúdo (Nil), em uma posição específicada do array	aIns( <aDados, )

				// Quantidade Segunda unidade medida
				If nPosQtSeg > 0 .And. Empty(aLinha[nPosQtSeg][2])
					aLinha[nPosQtSeg][2]	:=  QRSD2->D2_QTSEGUM
				ElseIf nPosQtSeg == 0
					aIns(aLinha, nPosQte + 1) // Insere o registro na posição do array logo depois da quantidade
					If QRSD2->D2_QTSEGUM > 0 
						aLinha[nPosQte+1] := {"D1_QTSEGUM"	, QRSD2->D2_QTSEGUM		,Nil,Nil}// Atribui valor ao elemento inserido
					Else 
						aLinha[nPosQte+1] := {"D1_QTSEGUM"	, Val(FwInputBox("Produto "+aLinha[nPosCodPr][2]+" Digite a quantidade Segunda Unidade","0"))		,Nil,Nil}// Atribui valor ao elemento inserido
					Endif 
					
					nPosItem		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ITEM"} )
					nPosCodPr		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_COD"} )
					nPosTes			:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_TES"} )
					nPosLocal		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_LOCAL"} )
					nPosLtCtl		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_LOTECTL"} )
					nPosNumLt		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_NUMLOTE"} )
					nPosDFabr		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_DFABRIC"} )
					nPosDtVald		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_DTVALID"} )
					nPosQte 		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_QUANT"} )
					nPosEnderc		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_ENDEREC"} )
					nPosQtSeg		:= aScan(aLinha,{ |x| Alltrim(x[1]) =="D1_QTSEGUM"} )					
				Endif

				// Lote
				If nPosLtCtl > 0 .And. Empty(aLinha[nPosLtCtl][2])
					aLinha[nPosLtCtl][2]	:=  QRSD2->D2_LOTECTL
				ElseIf nPosLtCtl == 0
					Aadd(aLinha,{"D1_LOTECTL"	, QRSD2->D2_LOTECTL		,Nil,Nil})
				Endif

				// Fabricação do Lote
				If nPosDFabr > 0 .And. Empty(aLinha[nPosDFabr][2])
					aLinha[nPosDFabr][2]	:=  STOD(QRSD2->D2_DFABRIC)
				ElseIf nPosDFabr == 0
					Aadd(aLinha,{"D1_DFABRIC"	, STOD(QRSD2->D2_DFABRIC)		,Nil,Nil})
				Endif

				// Validade do Lote
				If nPosDtVald > 0 .And. Empty(aLinha[nPosDtVald][2])
					aLinha[nPosDtVald][2]	:=  STOD(QRSD2->D2_DTVALID)
				ElseIf nPosDtVald == 0
					Aadd(aLinha,{"D1_DTVALID"	, STOD(QRSD2->D2_DTVALID)		,Nil,Nil})
				Endif

				If aCxEnderAdd == Nil
					aCxEnderAdd	:= {}
				Endif

				// Número Caixa - Endereço
				If nPosEnderc > 0 .And. Empty(aLinha[nPosEnderc][2]) .And. !Empty(QRSD2->D2_LOCALIZ)
					aLinha[nPosEnderc][2]	:=  QRSD2->D2_LOCALIZ
				ElseIf nPosEnderc == 0 .And. !Empty(QRSD2->D2_LOCALIZ)
					Aadd(aLinha,{"D1_ENDER"	, QRSD2->D2_LOCALIZ		,Nil,Nil})
				Endif
				// Controlo que a caixa já foi usada
				If !Empty(QRSD2->D2_LOCALIZ)
					Aadd(aCxEnderAdd,QRSD2->D2_LOCALIZ)
				Endif 

				// Cria o registro na SZ1
				sfGrvSZ1( SA2->A2_FILTRF/*cInFilial*/,QRSD2->D2_LOCALIZ	/*cInIdCaixa*/,aLinha[nPosLocal,2]/*cInLocPad*/)

			Else
				MsgAlert("Para o item '" +aLinha[nPosItem,2] + "' /Produto '" + aLinha[nPosCodPr][2] + "' não foi possível localizar automaticamente informação de Número de Caixa para endereçamento. Favor avisar o TI.'")
			Endif
			QRSD2->(DbCloseArea())
		Endif
	Endif

	RestArea(aAreaOld)

Return


Static Function sfGrvSZ1(cInFilial,cInIdCaixa,cInLocPad)

	Local 	cQry 		:= ""

	cQry := "SELECT Z1_QUANT,Z1_QUANT2,Z1_QUANT3,Z1_QUANTE,Z1_PRODUTO, Z1_LOTE,Z1_DTVALID, Z1_IDCAIXA,Z1_DTAPONT"
	cQry +="   FROM " + RetSqlName("SZ1") + " Z1 "
	cQry += " WHERE Z1.D_E_L_E_T_ = ' ' "
	cQry += "   AND Z1_IDCAIXA = '" + cInIdCaixa + "' "
	cQry += "   AND Z1_FILIAL = '" + cInFilial + "' "

	TcQuery cQry New Alias "QSZ1"

	If !Eof()
		nPesoCx		:= QSZ1->Z1_QUANT
		nPesoCx2	:= QSZ1->Z1_QUANT2
		nQteMt		:= QSZ1->Z1_QUANT3
		nQteCx		:= QSZ1->Z1_QUANTE
		cCodPrd		:= QSZ1->Z1_PRODUTO
		cLotProd	:= QSZ1->Z1_LOTE
		dDtVldLote	:= STOD(QSZ1->Z1_DTVALID)
		cIdCaixa	:= QSZ1->Z1_IDCAIXA
		dDatPrd		:= STOD(QSZ1->Z1_DTAPONT)

		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+cCodPrd)

		// Cria o Endereço do produto
		If sfCriaSBE(cInLocPad,cCodPrd,cIdCaixa,nPesoCx,nQteMt)

			DbSelectArea("SZ1")
			RecLock("SZ1",.T.)
			SZ1->Z1_FILIAL		:= xFilial("SZ1")			//    CHAR(2)           '  '
			SZ1->Z1_QUANT  		:= nPesoCx
			SZ1->Z1_QUANT2  	:= nPesoCx2
			SZ1->Z1_QUANTE  	:= nQteCx
			SZ1->Z1_QUANT3		:= nQteMt
			SZ1->Z1_PRODUTO  	:= cCodPrd
			SZ1->Z1_LOTE   		:= cLotProd
			SZ1->Z1_DTVALID 	:= dDtVldLote
			SZ1->Z1_IDCAIXA 	:= cIdCaixa
			SZ1->Z1_DTAPONT 	:= dDatPrd
			SZ1->Z1_HORA   		:= 	Time()
			MsUnlock()
		Endif
	Endif
	QSZ1->(DbCloseArea())

Return



/*/{Protheus.doc} sfCriaSBE
//Função que cria os novos endereços na SBE
@author Marcelo Alberto Lauschner
@since 16/06/2018
@version 1.0
@return ${return}, ${return_description}
@param cLocPad, characters, descricao
@param cCodPrd, characters, descricao
@param cIdCaixa, characters, descricao
@param nInQte, numeric, descricao
@type function
/*/
Static Function sfCriaSBE(cLocPad,cCodPrd,cInIdCaixa,nInQte,nInQteMt)

	Local		aAreaOld	:= GetArea()
	Local		cDescEnd	:= ""
	Local		nCapacidade	:= nInQte
	Local		dDatPrd		:= dDataBase
	Local		lRet		:= .F.
	Local		aVetor		:= {}
	Private 	lMsErroAuto := .F.
	Private 	lMsHelpAuto	:= .T.

	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+cCodPrd)


	DbSelectArea("SBE")
	DbSetOrder(1)
	If DbSeek(xFilial("SBE")+cLocPad+cInIdCaixa)

	Else
		cDescEnd	:= "CX: " + cInIdCaixa + " PROD: " + cCodPrd


		aVetor := 	{;
			{"BE_FILIAL" 	,xFilial("SBE") 		,Nil},;		// Filial
		{"BE_LOCAL"  	,cLocPad				,Nil},;		// Armazém
		{"BE_LOCALIZ"	,Padr(cInIdCaixa,TamSX3("BE_LOCALIZ")[1])				,NIL},;		// Endereço
		{"BE_DESCRIC"	,Padr(cDescEnd,TamSX3("BE_DESCRIC")[1])				,NIL},;		// Descrição
		{"BE_CAPACID"	,nCapacidade * 1.2		,NIL},;		// Capacidade - Quantidade informado + 20% de segurança para evitar erros
		{"BE_PRIOR"		,"ZZZ"					,NIL},;		// Prioridade
		{"BE_ALTURLC"	,99						,NIL},;		// Altura
		{"BE_LARGLC"	,99						,NIL},;		// Largura
		{"BE_COMPRLC"	,99						,NIL},; 	// Comprimento
		{"BE_PERDA"		,0						,NIL},;		// Indice Perda
		{"BE_CODPRO"	,cCodPrd				,Nil},;		// Código Produto
		{"BE_DATGER" 	,dDatPrd				,Nil},;		// Data da Geração
		{"BE_STATUS"	,"1"					,NIL} }		// Status 1-Desocupado 2-Ocupado

		MSExecAuto({|x,y| MATA015(x,y)},aVetor, 3)

		If lMsErroAuto
			lRet	:= .F.
			MsgAlert("Erro na geração do endereço " + cInIdCaixa ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
			MostraErro()
			DisarmTransaction()
		Else
			lRet 	:= .T.
		EndIf

	Endif

	RestArea(aAreaOld)

Return lRet
