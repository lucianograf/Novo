#include "totvs.ch"

/*/{Protheus.doc} DCFATG01
Gatilho para retornar percentual de Comiss�o por Cliente/Loja,Vendedor,Emiss�o,Produto,Quantidade ( Valores prontos para futuras Regras )
@type function
@version 
@author Marcelo Alberto Lauschner 
@since 20/08/2020
@param cInCli, character, param_description
@param cInLoja, character, param_description
@param cInVend, character, param_description
@param dInDtEmis, date, param_description
@param cInCodPrd, character, param_description
@param nInQte, numeric, param_description
@return numeric, nPComis - Percentual de comiss�o 
/*/
User Function DCFATG01(cInCli,cInLoja,cInVend,dInDtEmis,cInCodPrd,nInQte,nInOpcAtu)

	Local   aAreaOld    := GetArea()
	Local   lComisMan   := Alltrim(ReadVar())=="M->C5_COMIS1"
	Local   nPComisMan  := Iif(lComisMan,M->C5_COMIS1,0)
	Local   nPComis     := nPComisMan
	Local 	nPAuxCom	:= nPComis
	Local   lAltCabSC5  := .F.
	Default dInDtEmis   := dDataBase
	Default nInOpcAtu	:= 1 // Comiss�o 1 ou 2 

	// Se a edi��o fo apenas do
	If lComisMan
		// 17/09/2020 - Regra - Se o cliente estiver setado para n�o calcular comiss�o - Zera todos os valores poss�veis de comiss�o no pedido.
		If SA1->(FieldPos("A1_ZERACOM")) > 0 .And. SA1->A1_ZERACOM == "1" // 1-Sim/2=N�o
			If nInOpcAtu == 1 
				If Type("M->C5_COMIS1") <> "U"
					// Verifica se por acaso houve algum preenchimento de valor de comiss�o
					If M->C5_COMIS1 > 0
						MsgAlert("A comiss�o para este cliente � Zerada, conforme defini��o de seu cadastro.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					Endif
					// Zera os percentuais de comiss�o
					M->C5_COMIS1    := 0
					nPComisMan      := 0
				Endif
			ElseIf nInOpcAtu == 2 
				If Type("M->C5_COMIS2") <> "U"
					// Verifica se por acaso houve algum preenchimento de valor de comiss�o
					If M->C5_COMIS2 > 0
						MsgAlert("A comiss�o para este cliente � Zerada, conforme defini��o de seu cadastro.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					Endif
					// Zera os percentuais de comiss�o
					M->C5_COMIS2    := 0
					nPComisMan      := 0
				Endif
			Endif 

			// Zero o valor do retorno tamb�m
			nPComis     := 0
		Endif
	Else
		// Pesquiso a comiss�o no Cadastro o Vendedor
		DbSelectArea("SA3")
		DbSetOrder(1)
		DbSeek(xFilial("SA3")+cInVend)

		If SA3->A3_COMIS  > 0
			nPComis     := SA3->A3_COMIS
			lAltCabSC5  := .T.
		Endif

		// Pesquiso a comiss�o no Cadastro do Cliente
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+cInCli+cInLoja)
		If SA1->A1_COMIS > 0
			nPComis     := SA1->A1_COMIS
			lAltCabSC5  := .T.
		Endif

		// 17/09/2020 - Regra - Se o cliente estiver setado para n�o calcular comiss�o - Zera todos os valores poss�veis de comiss�o no pedido.
		If SA1->(FieldPos("A1_ZERACOM")) > 0 .And. SA1->A1_ZERACOM == "1" // 1-Sim/2=N�o
			If Type("M->C5_COMIS1") <> "U"
				// Verifica se por acaso houve algum preenchimento de valor de comiss�o
				If M->C5_COMIS1 > 0
					MsgAlert("A comiss�o para este cliente � Zerada, conforme defini��o de seu cadastro.",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
				Endif
			Endif
			// Zero o valor do retorno tamb�m
			nPComis     := 0
		Else
			// Pesquiso a comiss�o no Cadastro do Produto
			DbSelectArea("SB1")
			DbSetOrder(1)
			DbSeek(xFilial("SB1")+cInCodPrd)
			If SB1->B1_COMIS > 0
				If MsgYesNo("Deseja usar a comiss�o do Produto! Demais produtos do pedidos seguir�o cada um sua regra de comiss�o. ",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					lAltCabSC5  := .F.
					nPComis     := SB1->B1_COMIS
				Endif
			Endif
			nPAuxCom	:= nPComis
		Endif

		// Verifico os c�digos de vendedores e filiais para efetuar o incremento de comiss�o
		If nPComis > 0 .And. cInVend $ GetNewPar("DC_FATG01V","000115#000118#000126#000158#000183#000256#000257#000269")
			If cFilAnt $ "0101#0104#0202"
				nPComis     += 0.6 // Efetua o incremento
			Endif//000163,000259,000157,000143,000173
		elseif 	nPComis > 0 .And. cInVend $ GetNewPar("DC_FATG01X","000259#000157#000143#000173")
			If cFilAnt $ "0107"
				nPComis     -= 1.67 // Efetua o incremento
			Endif//000163,000259,000157,000143,000173
		Endif

		// Verifica se deve alterar o cabe�alho do pedido e se a comiss�o calculada � diferente da comiss�o j� informada no cabe�alho 
		If lAltCabSC5 .And. ((nInOpcAtu == 1 .And. M->C5_COMIS1 <> nPComis) .Or. (nInOpcAtu == 2  .And. M->C5_COMIS2 <> nPComis))
			// Comiss�o calculada � igual a comiss�o do vendedor antes do incremento de comiss�o 
			If nPComis == nPAuxCom
				If MsgYesNo("Deseja usar a comiss�o calculada de " + Transform(nPComis,"@E 999.99") + "% e atribuir no cabe�alho do pedido? Percentual atual � " + Transform(M->C5_COMIS1,"@E 999.99")+ "%"  ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					M->C5_COMIS1    := nPComis
				Endif
			// Se a comiss�o j� digitada � igual a comiss�o do vendedor antes do incremento de comiss�o 
			ElseIf nInOpcAtu == 1 
				If M->C5_COMIS1 == nPAuxCom
					M->C5_COMIS1    := nPComis
				Endif 
			ElseIf nInOpcAtu == 2
				If M->C5_COMIS2 == nPAuxCom
					M->C5_COMIS2    := nPComis
				Endif 			
			Endif
			nPComis         := 0 // Zero o percentual de comiss�o para n�o preencher na C6_COMIS1

		Endif
	Endif

	RestArea(aAreaOld)

Return nPComis
