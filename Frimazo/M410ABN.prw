#include "totvs.ch"
/*/{Protheus.doc} M410ABN
(Ponto Entrada ao abandonar pedido de venda ,Se abandonar inclusão desfaz reserva de Tambores     )
	
@author MarceloLauschner
@since 06/08/2013
@version 1.0		

@return Sem retorno 

@example
(examples)

@see (http://tdn.totvs.com/display/public/mp/M410ABN+-+Cancelamento+de+pedido)
/*/
User Function M410ABN()

	Local		aAreaOld	:= GetArea()
	Local		iW
	Local		nPxPA2NUM	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2NUM"})
	Local		nPxPA2LIN	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_XPA2LIN"})
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxItem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})


	sfAtuaF3k1()


	// Efetua verificação se esta validação deve ser executada para esta empresa/filial
	If !U_BFCFGM25("M410ABN")
		Return .T.
	Endif


	// Limpa os dados da Produção somente se for inclusão abandonada
	If INCLUI
		For iW := 1 To Len(aCols)
			// Somente produtos sujeitos a envasamento.
			// Não deve filtrar linhas deletadas, por que todos os itens digitados estão sendo abandonados e deverão restaurar a reserva
			If aCols[iW,nPxProd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
				// Evita erro de não existir os campos ainda na base de produção
				If nPxPA2NUM > 0
					DbSelectArea("PA2")
					DbSetOrder(3)
					If DbSeek(xFilial("PA2")+aCols[iW,nPxPA2NUM]+aCols[iW,nPxPA2LIN])
						RecLock("PA2",.F.)
						PA2->PA2_RESERV	:= " "
						PA2->PA2_PEDIDO	:= " "
						MsUnlock()
					Endif
				Endif
			Endif
		Next
	ElseIf ALTERA
		For iW := 1 To Len(aCols)
			// Somente produtos sujeitos a envasamento.
			// Somente se o item ainda não estava digitado no pedido anteriormente
			DbSelectArea("SC6")
			DbSetOrder(1)
			If !DbSeek(xFilial("SC6")+M->C5_NUM+aCols[iW,nPxItem]+aCols[iW,nPxProd])
				If aCols[iW,nPxProd]  $ GetNewPar("BF_PRODPCP","43170.000159   #02153.000159   ")  // Parametro precisa ter o tamanho do código do produto
					// Evita erro de não existir os campos ainda na base de produção
					If nPxPA2NUM > 0
						DbSelectArea("PA2")
						DbSetOrder(3)
						If DbSeek(xFilial("PA2")+aCols[iW,nPxPA2NUM]+aCols[iW,nPxPA2LIN])
							RecLock("PA2",.F.)
							PA2->PA2_RESERV	:= " "
							PA2->PA2_PEDIDO	:= " "
							MsUnlock()
						Endif
					Endif
				Endif
			Endif
		Next

	Endif



	RestArea(aAreaOld)

Return


/*/{Protheus.doc} sfAtuaF3k1
// Função para gravar Produtos na tabela de Ajustes de Códigos
// Foi usado neste ponto de entrada só para fazer uma carga a partir de pedidos já encerrados.  
@author Marcelo Alberto Lauschner
@since 18/04/2019
@version 1.0
@return Nil
@type function
/*/
Static Function sfAtuaF3k1

	Local	iW
	Local		nPxProd		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	Local		nPxItem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})

	For iW := 1 To Len(aCols)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+M->C5_NUM+aCols[iW,nPxItem]+aCols[iW,nPxProd])
		//DbSeek(xFilial("SC6")+"002793")
		//While !Eof()

		DbSelectArea("SF4")
		DbSetOrder(1)
		DbSeek(xFilial("SF4") + SC6->C6_TES)
		sfAtuF3k2(SC6->C6_PRODUTO/*cInProduto*/,SC6->C6_CF/*cInCf*/,SC6->C6_CLASFIS/*cInClasFis*/)

		//DbSelectArea("SC6")
		//DbSkip()
		//Enddo
	Next

Return



User Function XXF3KFORCE(cInPedido)

	Local 	cKeyC5		:= xFilial("SC6")+ cInPedido
	Private ALTERA	:= .T.
	Private INCLUI	:= .F.

	//RPCSetType(3)
	//RPCSetEnv("02","04","","","","",{"SC5","SC6","F3K"}) // Abre todas as tabelas.


	DbSelectArea("SC5")
	DbSetOrder(1)
	//Set Filter To C5_NUM $ "216240#"
	//While SC5->(!Eof())
	If DbSeek(xFilial("SC5")+cInPedido)


		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSeek(xFilial("SC6")+SC5->C5_NUM)
		While SC6->(!Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == cKeyC5

			FWLogMsg("INFO", /*cTransactionId*/, Funname() /*cCategory*/, /*cStep*/, /*cMsgId*/, "Pedido: " + SC6->C6_NUM + " Item: " + SC6->C6_ITEM/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4") + SC6->C6_TES)
			sfAtuF3k2(SC6->C6_PRODUTO/*cInProduto*/,SC6->C6_CF/*cInCf*/,SC6->C6_CLASFIS/*cInClasFis*/)

			DbSelectArea("SC6")
			DbSkip()
		Enddo
	Endif
	//	DbSelectArea("SC5")
	//	SC5->(DbSkip())
	//Enddo

Return
/*/{Protheus.doc} ONFATMF3
Função para acionamento externo 
@type function
@version  
@author Lauschner Consulting - Marcelo Alberto Lauschner
@since 02/05/2025
@param cInProduto, character, param_description
@param cInCf, character, param_description
@param cInClasFis, character, param_description
@return variant, return_description
/*/
User Function ONFATMF3(cInProduto,cInCf,cInClasFis)

Return sfAtuF3k2(cInProduto,cInCf,cInClasFis)

/*/{Protheus.doc} sfAtuF3k2
Função que valida a criação de registros na F3K 
@type function
@version  
@author Lauschner Consulting - Marcelo Alberto Lauschner
@since 02/05/2025
@param cInProduto, character, param_description
@param cInCf, character, param_description
@param cInClasFis, character, param_description
@return variant, return_description
/*/
Static Function sfAtuF3k2(cInProduto,cInCf,cInClasFis)

	Local	aAreaOld	:= GetArea()
	Local	cCodProd	:= ""
	Local	cCfopPv		:= ""
	Local	cCodVlDec	:= ""
	Local	cCodAjust	:= ""
	Local	cTipValor	:= "9"
	Local	cClasFis	:= ""
	Local	lGrvF3K		:= .F.
	Local 	cPosIpi		:= ""
	Default cInProduto	:= ""
	Default cInCf		:= ""
	Default cInClasFis	:= ""

	cCodProd	:= cInProduto
	cPosIpi		:= Posicione("SB1",1,xFilial("SB1")+cInProduto,"B1_POSIPI")
	cClasFis	:= Substr(cInClasFis,2,2)
	cCfopPv		:= Alltrim(cInCf)
	// Se a CST estiver em Branco assume do TES
	If Empty(cClasFis) .Or. Len(Alltrim(cInClasFis)) <> 3
		cClasFis	:= SF4->F4_SITTRIB
	Endif

	If cEmpAnt+cFilAnt $ "0501"		//FRIMAZO
		// Validações já existente
		If Alltrim(cCfopPv) $ "5663" .And. cClasFis == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "SC810032"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf Alltrim(cCfopPv) $ "6101" .And. cClasfis == "40"
			cCodAjust	:= "SC810176"
			cCodVlDec	:= "0000200" // icms imune ou não tribuato - valor mercadoria
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf Alltrim(cCfopPv) $ "5907" .And. cClasFis == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif

		// Validações revisadas em maio/2025
		//CFOP			CST	CÓDIGO AJUSTE	TIPO VALOR
		//5901/6901		50	SC840007	Contábil
		If cCfopPv $ "5901#6901" .And. cClasFis == "50"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5915			50	SC840007	Contábil
		ElseIf cCfopPv $ "5915" .And. cClasFis == "50"
			cCodAjust	:= "SC840007"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5902/6902		50	SC840008	Contábil
		ElseIf cCfopPv $ "5902#6902" .And. cClasFis == "50"
			cCodAjust	:= "SC840008"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//6910			20	SC800016	Valor do ICMS
		ElseIf cCfopPv $ "6910" .And. cClasFis == "20"
			cCodAjust	:= "SC800016"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5912/6912		50	SC840021	Contábil
		ElseIf cCfopPv $ "5912#6912" .And. cClasFis == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5913/6913		50	SC840021	Contábil
		ElseIf cCfopPv $ "5913#6913" .And. cClasFis == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5914/6914		40	SC810165	Contábil
		ElseIf cCfopPv $ "5914#6914" .And. cClasFis == "40"
			cCodAjust	:= "SC810165"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5551/5553		40	SC810192	Contábil
		ElseIf cCfopPv $ "5551#5553" .And. cClasFis == "40"
			cCodAjust	:= "SC810192"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5554			50	SC840012	Contábil
		ElseIf cCfopPv $ "5554" .And. cClasFis == "50"
			cCodAjust	:= "SC840012"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5908			41	SC800006	Contábil
		ElseIf cCfopPv $ "5908" .And. cClasFis == "41"
			cCodAjust	:= "SC800006"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5101			40	SC810176	Contábil
		ElseIf cCfopPv $ "5101" .And. cClasFis == "40"
			cCodAjust	:= "SC810176"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			// Aguardando definição do cfop 5101 x 00
			//5101			00	SC820032	Valor do ICMS - Saídas interestaduais, com ICMS "com redução"
			//If cCfopPv $ "5101" .And. cClasFis == "00"
			//	cCodAjust	:= "SC820032"
			//	cCodVlDec	:= "0000190"
			//	lGrvF3K		:= .T.
			//	cTipValor	:= "9"
			//5101			00	SC850099	Valor do ICMS - Aqui é em relação as saídas dentro de SC, adquiridas em SC
			//ElseIf cCfopPv $ "5101" .And. cClasFis == "00"
			//	cCodAjust	:= "SC850099"
			//	cCodVlDec	:= "0000190"
			//	lGrvF3K		:= .T.
			//	cTipValor	:= "9"
			//6101			20	SC820032	Valor do ICMS - Redução de Base de Cálculo
		ElseIf cCfopPv $ "6101" .And. cClasFis == "20"
			cCodAjust	:= "SC820032"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5905/5906		50	SC840005	Contábil
		ElseIf cCfopPv $ "5905#5906" .And. cClasFis == "50"
			cCodAjust	:= "SC840005"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0502"		//FRIMAZO FILIAL 02
		//CFOP			CST	CÓDIGO AJUSTE	TIPO VALOR
		//5907			50	SC840004	Contábil
		//5102  		20 	SC820033 	 000190
		//6108 		 	20  SC820033  	 000190
		If cCfopPv $ "5907" .And. cClasFis == "50"
			cCodAjust	:= "SC840004"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "5102" .And. cClasFis == "20"
			cCodAjust	:= "SC820033"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "6108" .And. cClasFis == "20"
			cCodAjust	:= "SC820033"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif
	ElseIf cEmpAnt+cFilAnt $ "0503"		//FRIMAZO FILIAL 03 SÃO PAULO - ADICIONADO EM 10/04/2026 - LUCIANO
		//CFOP			CST	CÓDIGO AJUSTE	TIPO VALOR
		//5102/6152 20 SP020740	Contábil - CÓD. DECLARATÓRIO = 0000200
		//5910/6910 20 SP020740	Contábil - CÓD. DECLARATÓRIO = 0000200
		//6102  	20 SP020450 Contábil - CÓD. DECLARATÓRIO = 0000200
		//5905	 	41 SP010070 Contábil - CÓD. DECLARATÓRIO = 0000180
		If cCfopPv $ "5905" .And. cClasFis == "41"
			cCodAjust	:= "SP010070"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "5102#6152" .And. cClasFis == "20"
			cCodAjust	:= "SP020740"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "5910#6910" .And. cClasFis == "20"
			cCodAjust	:= "SP020740"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "6102" .And. cClasFis == "20"
			cCodAjust	:= "SP020450"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif
	ElseIf cEmpAnt+cFilAnt $ "1102"		//ONIX FILIAL 02 SC
		//CFOP			CST	CÓDIGO AJUSTE	TIPO VALOR
		//5912			50	SC840021	Contábil
		If cCfopPv $ "5912" .And. cClasFis == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5913			50	SC840021	Contábil
		ElseIf cCfopPv $ "5913" .And. cClasFis == "50"
			cCodAjust	:= "SC840021"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5552			40	SC810193	Contábil
		ElseIf cCfopPv $ "5552" .And. cClasFis == "40"
			cCodAjust	:= "SC810193"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5551/5553		40	SC810192	Contábil
		ElseIf cCfopPv $ "5551#5553" .And. cClasFis == "40"
			cCodAjust	:= "SC810192"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5151/5152		51	SC830073	Contábil
		ElseIf cCfopPv $ "5151#5152" .And. cClasFis == "51"
			cCodAjust	:= "SC830073"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5554			50	SC840012	Contábil
		ElseIf cCfopPv $ "5554" .And. cClasFis == "50"
			cCodAjust	:= "SC840012"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5908			41	SC800006	Contábil
		ElseIf cCfopPv $ "5908" .And. cClasFis == "41"
			cCodAjust	:= "SC800006"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5905/5906		50	SC840005	Contábil
		ElseIf cCfopPv $ "5905#5906" .And. cClasFis == "50"
			cCodAjust	:= "SC840005"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif
	ElseIf cEmpAnt+cFilAnt $ "1103"		//ONIX FILIAL 03 PR
		// Chamado 28.996 - NCM + cfop + cst +( NCM Especifica - VENDA DIFERIMENTO PARCIAL)
		If Alltrim(cPosIpi) $ "33074900" .And. Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "PR830003"
			cCodVlDec	:= "0000170"
			lGrvF3K		:= .T.
			cTipValor	:= "8"
			// VENDA DIFERIMENTO PARCIAL
		ElseIf Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170"
			lGrvF3K		:= .T.
			cTipValor	:= "8"
			// REMESSA BRINDE
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "41"
			cCodAjust	:= "PR809999"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// BONIFICAÇÃO DIFERIMENTO PARCIAL
		ElseIf Alltrim(cCfopPv) $ "5910" .And. cClasFis == "51"
			cCodAjust	:= "PR830001"
			cCodVlDec	:= "0000170"
			lGrvF3K		:= .T.
			cTipValor	:= "8"
			// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5905" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			// REM. ARMAZENAGEM
		ElseIf Alltrim(cCfopPv) $ "5663" .And. cClasFis == "50"
			cCodAjust	:= "PR840009"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			// REMESSA VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// TRANSF. ATIVO
		ElseIf Alltrim(cCfopPv) $ "5555" .And. cClasFis == "41"
			cCodAjust	:= "PR800014"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REM. EXPOSIÇÃO OU FEIRA
		ElseIf Alltrim(cCfopPv) $ "5914" .And. cClasFis == "40"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// RET. VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5921" .And. cClasFis == "40"
			cCodAjust	:= "PR810171"
			cCodVlDec	:= "0000180"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REMESSA COMODATO
		ElseIf Alltrim(cCfopPv) $ "5908" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REMESSA TROCA - ATIVO
		ElseIf Alltrim(cCfopPv) $ "5949" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REMESSA USO FORA DA EMPRESA
		ElseIf Alltrim(cCfopPv) $ "5554" .And. cClasFis == "41"
			cCodAjust	:= "PR800013"
			cCodVlDec	:= "0000200"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5915" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// REMESSA CONSERTO
		ElseIf Alltrim(cCfopPv) $ "5916" .And. cClasFis == "50"
			cCodAjust	:= "PR840014"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
			// Remessa de mercadoria ou bem para demonstração.
		ElseIf Alltrim(cCfopPv) $ "5912" .And. cClasFis == "50"
			cCodAjust	:= "PR840026"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "3"
		Endif
	ElseIf cEmpAnt+cFilAnt $ "1105" 	//ONIX FILIAL 05 RS

		// Chamado 25993 - REvisão dos códigos de Ajuste x cfop x cst
		// 5114	Remessa consignação			90	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS
		// 5405	VENDA MERC ST				60	OUTROS			RS052427	ANEXO V.B - AP.II,S.III,XX-PECAS,COMP.E ACES.P/PROD.AUTOP.
		// 5655	VENDA LUBRIFICANTE ST		60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS
		// 5656	VENDA LUB - Consumidor Fina 60	OUTROS			RS052411	ANEXO V.B - AP.II,S.III,IV -COMBUSTIVEIS
		// 5663	Remessa Armazenagem			41	NÃO-INCIDÊNCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL
		// 5905	Remessa Armazenagem			41	NÃO-INCIDÊNCIA	RS051510	ANEXO V.A - LIVRO I,11,XI -ARMAZEM-GERAL

		// VENDA DIFERIMENTO PARCIAL
		// Chamado 25816 - 19/04/2021
		If Alltrim(cCfopPv) $ "5102" .And. cClasFis == "51"
			cCodAjust	:= "RS052158"
			cCodVlDec	:= "0000170"
			cTipValor	:= "4"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5114" .And. cClasFis == "90"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5554#5908#6552#5910" .And. cClasFis == "41"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "6659" .And. cClasFis == "41"
			cCodAjust	:= "RS051502"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905#5663" .And. cClasFis == "41"
			cCodAjust	:= "RS051510"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5905"
			cCodAjust	:= "RS051511"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
			// VENDA/BAIXA ATIVO
		ElseIf Alltrim(cCfopPv) $ "5551" .And. cClasFis == "40"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5911" .And. cClasFis == "40"
			cCodAjust	:= "RS051004"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5906#5907#5665"
			cCodAjust	:= "RS051512"
			cCodVlDec	:= "0001001"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5920" .And. cClasFis == "40"
			cCodAjust	:= "RS051011"
			cCodVlDec	:= "0001002" // Remessa de Vasilhames e Sacarias
			lGrvF3K		:= .T.
			// RET. VASILHAME
		ElseIf Alltrim(cCfopPv) $ "5921#6921" .And. cClasFis == "40"
			cCodAjust	:= "RS051012"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5405" .And. cClasFis == "60" .And. cEmpAnt == "02"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5405" .And. cClasFis == "60" .And. cEmpAnt == "11"
			cCodAjust	:= "RS052412"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5656#5655" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "84213990#84219999#84814000#84212100#84212300" .And.  Alltrim(cCfopPv) $ "5927#5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052427"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf cEmpAnt == "11" .And. Alltrim(cPosIpi) $ "27101932#27101931" .And.  Alltrim(cCfopPv) $ "5910" .And. cClasFis == "60"
			cCodAjust	:= "RS052411"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5119#5656#5655#5910#5912#5923#5927#5949" .And. cClasFis == "60"
			cCodAjust	:= "RS052001"
			cCodVlDec	:= "0001002"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5927" .And. cClasFis == "41"
			cCodAjust	:= "RS051514"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		ElseIf Alltrim(cCfopPv) $ "5206" .And. cClasFis == "40"
			cCodAjust	:= "RS051408"
			cCodVlDec	:= "0001003"
			lGrvF3K		:= .T.
		Endif
	ElseIf cEmpAnt+cFilAnt $ "1106"		//ONIX FILIAL 06
		//CFOP			CST	CÓDIGO AJUSTE	TIPO VALOR
		//5551/5553		40	SC810192	Contábil
		If cCfopPv $ "5551#5553" .And. cClasFis == "40"
			cCodAjust	:= "SC810192"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5656			40	SC810214	Contábil	Para notas de resíduo de óleo
		ElseIf cCfopPv $ "5656" .And. cClasFis == "40"
			cCodAjust	:= "SC810214"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5554			50	SC840012	Contábil
		ElseIf cCfopPv $ "5554" .And. cClasFis == "50"
			cCodAjust	:= "SC840012"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5949			51	SC830085	Contábil	Para notas de sucatas
		ElseIf cCfopPv $ "5949" .And. cClasFis == "51"
			cCodAjust	:= "SC830085"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
			//5151/5152		51	SC830073	Contábil
		ElseIf cCfopPv $ "5151#5152" .And. cClasFis == "51"
			cCodAjust	:= "SC830073"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		ElseIf cCfopPv $ "5949" .And. cClasFis == "51"
			cCodAjust	:= "SC830085"
			cCodVlDec	:= "0000190"
			lGrvF3K		:= .T.
			cTipValor	:= "9"
		Endif
	Endif

	DbSelectArea("F3K")
	DbSetOrder(1)
	If DbSeek(xFilial("F3K")+cCodProd+cInCf+cCodAjust+cClasFis)
		// Não faz nada por que já existe o cadastro

	ElseIf lGrvF3K // Se encontrou situações que deve gravar os ajustes
		DbSelectArea("F3K")
		RecLock("F3K",.T.)
		F3K->F3K_FILIAL		:= xFilial("F3K")
		F3K->F3K_PROD		:= cCodProd
		F3K->F3K_CFOP		:= cInCf
		F3K->F3K_CODAJU		:= cCodAjust
		F3K->F3K_CST		:= cClasFis
		F3K->F3K_VALOR		:= Iif(!Empty(cTipValor),cTipValor,"9")	// 9-Valor Contábil
		F3K->F3K_CODREF		:= cCodVlDec
		F3K->(MsUnlock())

		U_WFGERAL("marcelo@centralxml.com.br","Cadastrado novo registro F3K "+ cEmpAnt+"/"+ cFilAnt,"Produto: " + cCodProd + " Cfop:" + cCfopPv + " Cód.Ajuste: " + cCodAjust + " CST: " + cClasFis + " Cód.Valor:" + cCodVlDec,"M410ABN")
	Endif

	RestArea(aAreaOld)

Return
