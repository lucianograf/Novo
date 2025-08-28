#Include 'Protheus.ch'

/*/{Protheus.doc} XMLCTE09
(Ponto de entrada Central XML - no lan�amento de Frete sobre Vendas - permite customiza��o)
@type function
@author Marcelo Alberto Lauschner 
@since 03/11/2018
@version 06/06/2020
/*/
User Function XMLCTE09()

	// Vari�vel aItem  Private dentro da Central XML e cont�m o vetor da SD1 para lan�amento de cada CTE
	// Vari�vel aCab  Private dentro da Central XML e cont�m o vetor da SF1 para o lan�amento de cada CTE

	// Recebe o registro posicionada da SF2
	Local	aNfOri		:= ParamIxb

	Local	aAreaOld	:= GetArea()
	Local	nPosTes		:= aScan(aItem,{|x| AllTrim(x[1]) == "D1_TES"})
	Local	nPosOper	:= aScan(aItem,{|x| AllTrim(x[1]) == "D1_OPER"})
	Local	nPosPrd		:= aScan(aItem,{|x| AllTrim(x[1]) == "D1_COD"})
	Local	nPosNaturez	:= aScan(aCab,{|x| AllTrim(x[1])  == "E2_NATUREZ"})
	Local 	nPosCC		:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_CC"	})
	Local 	nPosConta	:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_CONTA"})
	Local 	nPosItCta	:=  aScan(aItem,{|x| AllTrim(x[1]) == "D1_ITEMCTA"	})
	Local	nLenItem	:= Len(aItem)
	Local	aTesOri		:= {}
	Local	nPxTes		:= 0
	//Local 	lAltNat		:= .F.
	Local	cTesRetPe	:= "281"
	Local 	cTesRetTI	:= "   "
	Local 	cTpOperFV 	:= GetNewPar("XM_FMPADFR"," ")
	Local	cCustoRet	:= Iif(cFilAnt=="0104","10013",Iif(cFilAnt=="0105","10014",Iif(cFilAnt=="0107","10008",Iif(cFilAnt$"0201#0202","10005","10013"))))  // Define um valor padr�o
	Local 	cContaRet	:= Iif(cEmpAnt=="01","420103008",Iif(cEmpAnt=="02","420101028",""))	// FRETE SOBRE VENDAS
	Local	aCfopTes	:= &(GetNewPar("DC_CFTES09",'{{"280","XXXX"}}')) //5116/5949/5915/5916/5912/5913/5910/5901/5902/5913/5914/5920/5921/6116/6949/6915/6916/6912/6913/6910/6901/6902/6913/6914/6920/6921"}}'))
	Local	nPosCfTes	:= 0
	Local 	cUfDes		:= IIf( Type("oIdent:_UFFim") <> "U" , oIdent:_UFFim:TEXT , Space(TamSX3("F1_UFDESTR")[1]) )
	Local 	lIsFilTTD	:= cFilAnt $ "0101#0104" // Identifica se a filial tem TTD
	Local 	lIsHerm01	:= cFilAnt $ "0201"
	Local 	lIsHerm02 	:= cFilAnt $ "0202"
	Local 	lIsSimpNac	:= SA2->A2_SIMPNAC == "1" // Verifica se o fornecedor/transportadora � do Simples

	// Decanter Matriz e Logistica (0101 e 0104 )
	// - 280 - Cr�dito Pis/Cofins Sem Icms
	// - 281 - Sem Pis/Cofins Sem Icms

	// Decanter Filiais
	// - 280 - Cr�dito Pis/Cofins Sem Icms
	// - 281 - Sem Pis/Cofins Sem Icms
	// - 282 - Cr�dito Pis/Cofins Com Icms
	// - 283 - Sem Pis/Cofins com Icms


	// Vari�vel aInfIcmsCte existe por causa da fun��o sfVldAlqIcms que alimenta o array Private
	//aInfIcmsCte	:= {{"ICM","ICMS",nBaseIcms,nAliqIcms,nValIcms}}
	// Esta vari�vel pode ser usada caso tenha que ser identificada alguma situa��o que avalie o valor do ICMS no CTe
	//e interfira no retorno do TES a ser usada
	// Se o vetor veio zerado, efetua um ajuste
	If Len(aInfIcmsCte) == 0
		Aadd(aInfIcmsCte,{"ICM","ICMS",0,0,0})
	Endif

	DbSelectArea("SF2")
	DbSetOrder(1)
	If DbSeek(aNfOri[1]+aNfOri[2]+aNfOri[3]+aNfOri[4]+aNfOri[5])

		// Percorre todos os itens da nota para montar um vetor somando por TES o valor das mercadorias
		DbSelectArea("SD2")
		DbSetOrder(3) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		DbGotop()
		DbSeek(xFilial("SD2")+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA))
		While !Eof() .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == xFilial("SD2") + SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)

			nPxTes	:= aScan(aTesOri,{|x| x[1] == SD2->D2_TES})

			//  Se o TES de sa�da ainda n�o foi adicionado ao vetor
			If nPxTes == 0
				// Cria vetor
				// 1 - TES de sa�da
				// 2 - Valor da mercadoria
				// 3 - Valor do ICMS destacado
				// 4 - Valor do Pis Destacado
				// 5 - Valor do Cofins Destacado
				// 6 - UF de destino
				// 7 - CFOP
				// 8 - Centro Custo NF Origem
				Aadd(aTesOri,{SD2->D2_TES,SD2->D2_TOTAL,SD2->D2_VALICM,SD2->D2_VALIMP6,SD2->D2_VALIMP5,SD2->D2_EST,SD2->D2_CF,SD2->D2_CCUSTO})
			Else
				aTesOri[nPxTes][2] += SD2->D2_TOTAL
				aTesori[nPxTes][3] += SD2->D2_VALICM
				aTesori[nPxTes][4] += SD2->D2_VALIMP6
				aTesori[nPxTes][5] += SD2->D2_VALIMP5
			Endif

			DbSelectArea("SD2")
			DbSkip()
		Enddo

		// Ordena por valor Decrescente, para assumir apenas uma TES com maior participa��o na nota
		aSort(aTesOri,,,{|x,y| x[2] > y[2] })
		//VarInfo("aTesOri",aTesOri)
		If Len(aTesOri) > 0

			If !Empty(aTesOri[1,8]	)
				cCustoRet	:= aTesOri[1,8]				// O Centro de custo ser� do agrupamento da SD2
			Endif


			nPosCfTes	:=  aScan(aCfopTes,{|x| Alltrim(aTesOri[1][7]) $ x[2]})

			If nPosCfTes > 0  // Se encontrada exce��o de CFOP x TES espec�fica
				cTesRetPe	:= aCfopTes[nPosCfTes,1] 	// TES conforme array que relaciona TES x CFOP sa�da
			Else
				DbSelectArea("SF4")
				DbSetOrder(1)
				DbSeek(xFilial("SF4")+aTesOri[1][1]) // Posiciona no primeiro registro de TES ordenado pelo maior valor

				// Se for bonifica��o -
				If Alltrim(aTesOri[1,7]) $ "5910#6910"
					cContaRet	:= Iif(cEmpAnt=="01","410101001",Iif(cEmpAnt=="02","410101006","")) // FRETE SOBRE BONIFICA��O
					//lAltNat		:= .T.
				ElseIf Alltrim(aTesOri[1,7]) $ "xxxxxx" // Industrializa��o
					cContaRet	:= Iif(cEmpAnt=="01","410101001",Iif(cEmpAnt=="02","410202008","")) // FRETE SOBRE INDUSTRIALIZA��O
					//lAltNat		:= .T.
				ElseIf SF4->F4_DUPLIC == "N"
					cContaRet	:= Iif(cEmpAnt=="01","420102037",Iif(cEmpAnt=="02","410101005","")) // FRETE OUTRAS SA�DAS/DEMAIS
					//lAltNat		:= .T.
				Endif

				// Destinat�rio fora do Estado
				If aTesOri[1][6] <> GetMv("MV_ESTADO")
					// ICMS destacado no CTe
					If aInfIcmsCTe[1,5] > 0
						// Se tiver ICMS destacado na Nota Referencia
						If aTesOri[1][3] > 0
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesREtPE 	:= "280"
								Else
									cTesRetPe 	:= "282"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "283"
								Endif
							Endif
						Else
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPE 	:= "280"
								Else
									cTesRetPe 	:= "280"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "281"
								Endif
							Endif
						Endif
						// Se n�o houver ICMS destacado no CTE, n�o poder tomar cr�dito, mesmo que a mercadoria Transpotada tenha ICMS
					Else
						// Se tiver Pis/Cofins
						If aTesOri[1][3] > 0
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "282"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "283"
								Endif
							Endif
						Else
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "280"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									lIsSimpNac	:= "281"
								Else
									cTesRetPe 	:= "281"
								Endif
							Endif
						Endif
					Endif
					// Dentro do Estado
				Else
					// ICMS destacado no CTe
					If aInfIcmsCTe[1,5] > 0
						// Se tiver ICMS destacado na Nota Referencia
						If aTesOri[1][3] > 0
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "282"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "283"
								Endif
							Endif
						Else
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "282"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "281"
								Endif
							Endif
						Endif
						// Se n�o houver ICMS destacado no CTE, n�o poder tomar cr�dito, mesmo que a mercadoria Transpotada tenha ICMS
					Else
						// Se tiver Pis/Cofins
						If aTesOri[1][3] > 0
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "282"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "283"
								Endif
							Endif
						Else
							// Se tiver Pis/Cofins
							If aTesOri[1][4] > 0 .And. aTesOri[1][5] > 0
								If lIsFilTTD
									cTesRetPe	:= "280"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T5"
								ElseIf lIsHerm02
									cTesRetPe	:= "2T5"
								ElseIf lIsSimpNac
									cTesRetPe	:= "280"
								Else
									cTesRetPe 	:= "280"
								Endif
							Else
								If lIsFilTTD
									cTesRetPe	:= "281"
								ElseIf lIsHerm01
									cTesRetPe	:= "2T2"
								ElseIf lIsHerm02
									cTesRetPe	:= "22T"
								ElseIf lIsSimpNac
									cTesRetPe	:= "281"
								Else
									cTesRetPe 	:= "281"
								Endif
							Endif
						Endif
					Endif
				Endif

			Endif

			// Verifica TES Inteligente e se tiver alguma exce��o ir� sobrepor o que est� neste rdmake
			If !Empty(cTpOperFV)
				cTesRetTI := MaTesInt(1/*nEntSai*/,cTpOperFV,cCodForn,cLojForn,"F"/*cTipoCF*/,aItem[nPosPrd,2])
				If !Empty(cTesRetTI)
					cTesRetPe	:= cTesRetTI
				Endif
			Endif

			// Se o TES j� existe no Vetor - substitui
			If nPosTes <> 0
				aItem[nPosTes,2] := cTesRetPe
			Else
				// Adiciona
				Aadd(aItem,{"D1_TES"	,cTesRetPe,Nil})
			Endif

		Endif

		/*  C�digo de Produto do FRETE deve ser configurado nestes 3 parametros caso seja sempre o mesmo c�digo de produto.
		Esta configura�o de c�digo de produto para o Frete CIF pode ser feito pelo Wizard da Central XML  
		XM_CDPFRET
		XM_CDPEDAG
		XM_CDPMALT

		Exemplo se houver necessidade for�ar o ajuste do c�digo de produto conforme alguma regra.
		aItem[nPosPrd,2]	:= "PRODUTO FRETE"
		*/

		// Exemplo se houver necessidade for�ar o ajuste da Natureza em fun��o de alguma condi��o originada no frete.
		//If lAltNat
		//	If nPosNaturez > 0
		//		aCab[nPosNaturez,2]	:= "20369"
		//	Else
		//		Aadd(aCab,{"E2_NATUREZ"   ,"20369" 		,NIL,NIL})
		//	Endif
		//Endif

		// Remove o campo D1_OPER pois como foi calculado o TES por este ponto de entrada, n�o ser� mais necess�rio chamar o TES inteligente.
		If nPosOper <> 0
			aDel(aItem,nPosOper)
			aSize(aItem,nLenItem-1)
		Endif
		// Tratamento para quando n�o encontrar a nota de origem referenciada, pega dados s� do CTE
	Else
		// Destinat�rio fora do Estado
		// Vari�vel cUfDes  Private com informa��o da UF de destino
		If cUfDes <> GetMv("MV_ESTADO")
			// ICMS destacado no CTe
			If aInfIcmsCTe[1,5] > 0
				If lIsFilTTD
					cTesRetPe	:= "280"
				ElseIf lIsHerm01
					cTesRetPe	:= "2T5"
				ElseIf lIsHerm02
					cTesRetPe	:= "2T5"
				ElseIf lIsSimpNac
					cTesRetPe	:= "280"
				Else
					cTesRetPe 	:= "280"
				Endif

				// Se n�o houver ICMS destacado no CTE, n�o poder tomar cr�dito, mesmo que a mercadoria Transpotada tenha ICMS
			Else
				If lIsFilTTD
					cTesRetPe	:= "280"
				ElseIf lIsHerm01
					cTesRetPe	:= "2T5"
				ElseIf lIsHerm02
					cTesRetPe	:= "2T5"
				ElseIf lIsSimpNac
					cTesRetPe	:= "280"
				Else
					cTesRetPe 	:= "280"
				Endif

			Endif

		Else
			// ICMS destacado no CTe
			If aInfIcmsCTe[1,5] > 0
				If lIsFilTTD
					cTesRetPe	:= "280"
				ElseIf lIsHerm01
					cTesRetPe	:= "2T5"
				ElseIf lIsHerm02
					cTesRetPe	:= "2T5"
				ElseIf lIsSimpNac
					cTesRetPe	:= "280"
				Else
					cTesRetPe 	:= "280"
				Endif

				// Se n�o houver ICMS destacado no CTE, n�o poder tomar cr�dito, mesmo que a mercadoria Transpotada tenha ICMS
			Else
				If lIsFilTTD
					cTesRetPe	:= "280"
				ElseIf lIsHerm01
					cTesRetPe	:= "2T5"
				ElseIf lIsHerm02
					cTesRetPe	:= "2T5"
				ElseIf lIsSimpNac
					cTesRetPe	:= "280"
				Else
					cTesRetPe 	:= "280"
				Endif
			Endif
		Endif

		// Verifica TES Inteligente e se tiver alguma exce��o ir� sobrepor o que est� neste rdmake
		If !Empty(cTpOperFV)
			cTesRetTI := MaTesInt(1/*nEntSai*/,cTpOperFV,cCodForn,cLojForn,"F"/*cTipoCF*/,aItem[nPosPrd,2])
			If !Empty(cTesRetTI)
				cTesRetPe	:= cTesRetTI
			Endif
		Endif

		// Se o TES j� existe no Vetor - substitui
		If nPosTes <> 0
			aItem[nPosTes,2] := cTesRetPe
		Else
			// Adiciona
			Aadd(aItem,{"D1_TES"	,cTesRetPe,Nil})
		Endif

		// Remove o campo D1_OPER pois como foi calculado o TES por este ponto de entrada, n�o ser� mais necess�rio chamar o TES inteligente.
		If nPosOper <> 0
			aDel(aItem,nPosOper)
			aSize(aItem,nLenItem-1)
		Endif
	Endif

	nPosConta  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_CONTA"})
	// For�a o preenchimento da Item Conta Cont�bil
	If nPosConta == 0			//Se n�o preencheu campo Item Conta cont�bil
		Aadd(aItem,{"D1_CONTA"   ,cContaRet  ,Nil})
		nPosConta  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_CONTA"})
		nLenItem := Len(aItem)
	Else
		aItem[nPosConta,2] := cContaRet
	Endif

	nPosCC  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_CC"})
	// For�a o preenchimento do Centro de custo
	If nPosCC == 0			//Se n�o preencheu campo Centro de custo
		Aadd(aItem,{"D1_CC"   ,cCustoRet  ,Nil})
		nPosCC  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_CC"})
		nLenItem := Len(aItem)
	Else
		aItem[nPosCC,2] := cCustoRet
	Endif

	nPosItCta  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_ITEMCTA"})
	// For�a o preenchimento da Item Conta Cont�bil
	If nPosItCta == 0			//Se n�o preencheu campo Item Conta cont�bil
		Aadd(aItem,{"D1_ITEMCTA"   ,cFilAnt  ,Nil})
		nPosItCta  := aScan(aItem,{|x| AllTrim(x[1]) == "D1_ITEMCTA"})
		nLenItem := Len(aItem)
	Else
		aItem[nPosItCta,2] := cFilAnt
	Endif

	RestArea(aAreaOld)
Return

