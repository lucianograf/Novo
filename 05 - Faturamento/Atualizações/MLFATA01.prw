#include "totvs.ch"
/*/{Protheus.doc} U_MLFATA01
Fun��o para altera��o de Vendedor em Pedido de Venda ( SC5 ) / Nota Fiscal ( SF2 ) / T�tulos a Receber ( SE1 )  / Comiss�es ( SE3 )
@type function
@version
@author Marcelo Alberto Lauschner
@since 29/10/2020
@return return_type, return_description
/*/
Function U_MLFATA01()


	Local   cLoad           := "MLFATA01"

	Local   aParamBox		:=	{}
	Local   aRet			:=	{}
	Local   bOk 			:=	{|| .T.}
	Local   aButtons 		:=	{}
	Local   lCentered 	    :=	.T.
	Local   nPosx
	Local   nPosy
	Local   lCanSave 		:=	.T.
	Local   lUserSave		:=	.T.
	Private aRetTipo    := {}


	Aadd( aParamBox, { 1/*nTipo*/, "N�mero Pedido", Space(TamSX3("C5_NUM")[1]), PesqPict("SC5","C5_NUM") ,'StaticCall(MLFATA01,sfVldPed)'/*cValid*/ ,  /*cF3*/,/*cWhen*/, 45 /*nTam*/,.T. /*lObrigatorio*/})

	Aadd( aParamBox, { 1/*nTipo*/, "Novo Vendedor 1", Space(TamSX3("C5_VEND1")[1]), PesqPict("SC5","C5_VEND1") , /*cValid*/ , "SA3" /*cF3*/,/*cWhen*/, 50 /*nTam*/,.T. /*lObrigatorio*/})

	Aadd( aParamBox, { 1/*nTipo*/, "Comiss�o Vendedor 1", 0 , PesqPict("SC5","C5_COMIS1") , /*cValid*/ , /*cF3*/,/*cWhen*/, 50 /*nTam*/,.F. /*lObrigatorio*/})

	Aadd( aParamBox, { 1/*nTipo*/, "Novo Vendedor 2", Space(TamSX3("C5_VEND2")[1]), PesqPict("SC5","C5_VEND2") , /*cValid*/ , "SA3" /*cF3*/,/*cWhen*/, 50 /*nTam*/,.F. /*lObrigatorio*/})

	Aadd( aParamBox, { 1/*nTipo*/, "Comiss�o Vendedor 2", 0 , PesqPict("SC5","C5_COMIS2") , /*cValid*/ , /*cF3*/,/*cWhen*/, 50 /*nTam*/,.F. /*lObrigatorio*/})

	Aadd( aParamBox, { 2/*nTipo*/, "Atualiza Percentual?"	,"N",{"N=N�o","S=Sim"},060,".T.",.T.})

	If ParamBox(aParamBox,"Alterar Vendedor - Filial: " + cFilAnt ,@aRet,bOk,aButtons,lCentered,nPosx,nPosy,/*oDlgWizard*/,cLoad,lCanSave,lUserSave)
		sfAtuComis(aRet)
	EndIf

Return

/*/{Protheus.doc} sfVldPed
Fun��o para validar o pedido digitado e preencher os campos de vendedor e comiss�o j� existentes
@type function
@version
@author Marcelo Alberto Lauschner
@since 12/11/2020
@return return_type, return_description
/*/
Static Function sfVldPed()

	Local 	lRet 	:= .F.

	DbSelectArea("SC5")
	DbSetOrder(1)
	If DbSeek(xFilial("SC5")+MV_PAR01)

		If SC5->C5_TIPO == "N"
			MV_PAR02	:= SC5->C5_VEND1
			MV_PAR03	:= SC5->C5_COMIS1
			MV_PAR04	:= SC5->C5_VEND2
			MV_PAR05 	:= SC5->C5_COMIS2
			lRet	:= .T.

			DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI) )

			If !MsgYesNo("Pedido: " + SC5->C5_NUM + " Cliente: " + SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI + "-" + Alltrim(SA1->A1_NOME) + " Cidade: " + Alltrim(SA1->A1_MUN) + CRLF + "Continua?" ,ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
				lRet	:= .F.
			Endif
		Else
			MsgAlert("Somente pedido tipo N-Normal podem ser editados por esta rotina!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
			lRet 	:= .F.

		Endif
	Else
		MsgAlert("Pedido n�o existe!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0))))
	Endif

Return lRet

/*/{Protheus.doc} sfAtuComis
Fun��o que executa a atualiza��o
@type function
@version
@author marcelo
@since 29/10/2020
@param aRet, array, param_description
@return return_type, return_description
/*/
Static Function sfAtuComis(aRet)

	Local   aVend       := {{"","",0},{"","",0}}
	Local   lAtuSC5     := .T.

	// Valida e posiciona no pedido de venda,
	DbSelectArea("SC5")
	DbSetOrder(1)
	If !dbSeek(xFilial("SC5")+aRet[1])
		MsgAlert("O pedido nao e valido","N�o h� Dados!")
		Return
	Endif

	// Gera um vetor com o De/para de vendedores
	aVend[1][1] := SC5->C5_VEND1
	aVend[1][2] := aRet[2] // Novo Vendedor 1
	aVend[1][3] := aRet[3] // Nova Comiss�o 1
	aVend[2][1] := SC5->C5_VEND2
	aVend[2][2] := aRet[4] // Novo Vendedor 2
	aVend[2][3] := aRet[5] // Nova Comiss�o 2

	If !MsgYesNo("De V1: "+SC5->C5_VEND1+" p/ v2 "+aRet[2]+" ? e V2: "+aRet[4],"Continua?")
		MsgAlert("Troca Abortada!!","Abandono")
		Return
	Endif

	// Verifica se houve faturamento do pedido e inicia as atualiza��es na SF2 / SE1 / SE3
	cNextAlias  := GetNextAlias()

	BeginSql alias cNextAlias
        SELECT DISTINCT D2_SERIE,D2_DOC
          FROM %Table:SD2% D2
         WHERE D2.%NotDel%
           AND D2_PEDIDO = %Exp:aRet[1]%
           AND D2_FILIAL = %xFilial:SD2%
	EndSql

	While !Eof()

		// Posiciona na nota fiscal
		DbSelectArea("SF2")
		DbSetOrder(1)
		If dbSeek(xFilial("SF2")+(cNextAlias)->D2_DOC+(cNextAlias)->D2_SERIE)

			// Posiciona na Comiss�o
			DbSelectArea("SE3")
			DbSetOrder(1) // E3_FILIAL+E3_PREFIXO+E3_NUM+E3_PARCELA+E3_SEQ+E3_VEND
			If dbSeek(xFilial("SE3")+SF2->F2_PREFIXO+SF2->F2_DUPL)


				While !Eof() .And. SE3->(E3_FILIAL+E3_PREFIXO+E3_NUM) == xfilial("SE3") + SF2->(F2_PREFIXO+F2_DUPL)
					// Se a comiss�o j� foi paga, aborta o registro da SE3 e atualiza Status de que n�o dever� atualizar o vendedor na SF2 / SE1 / SC5
					If !Empty(SE3->E3_DATA)
						MsgAlert("A comiss�o j� foi paga para o representante"+ SE3->E3_VEND + " Informe Financeiro!","Comiss�o Paga!")
						lAtuSC5     := .F.
						DbSelectArea ("SE3")
						DbSkip()     // salta para proxima nota
						Loop
					Endif

					Reclock("SE3",.F.)
					If E3_VEND == aVend[1][1]
						Replace E3_VEND with aVend[1][2]
					ElseIf E3_VEND == aVend[2][1]
						Replace E3_VEND with aVend[2][2]
					Endif
					MSUnLock()
					// Se ao menos um registro passou sem ajuste na SE3 atualiza flag de que poder� ser feita a atualiza��o na SC5 / SF2 / SE1
					lAtuSC5     := .T.

					MsgInfo("Comiss�o " + SE3->E3_NUM + "Alterada!!","Altera��o de Comiss�o.")

					DbSelectArea ("SE3")
					DbSkip()     // salta para proxima nota
				EndDo
			Endif

			If lAtuSC5
				DbSelectArea("SF2")
				Reclock("SF2",.F.)
				Replace F2_VEND1 with aVend[1][2]
				Replace F2_VEND2 with aVend[2][2]
				MSUnLock()
				MsgInfo("Nota Fiscal " + (cNextAlias)->D2_DOC + "Alterada!!","Altera��o de Nota.")

				DbSelectArea("SE1")
				DbSetOrder(1)
				If !DbSeek(xFilial("SE1")+SF2->F2_PREFIXO+SF2->F2_DUPL)
					MsgAlert("N�o foi encontrado t�tulo de Contas a Receber para este pedido!","N�o existe T�tulo a Receber")
				Endif
				While SE1->(!Eof()) .And. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM) ==  xfilial("SE1")  +  SF2->(F2_PREFIXO+F2_DUPL)
					Reclock("SE1",.F.)
					Replace E1_VEND1 with aVend[1][2]
					Replace E1_VEND2 with aVend[2][2]
					MSUnLock()

					MsgInfo("Duplicata " + SE1->E1_NUM+"-"+SE1->E1_PARCELA + "Alterada!!","Altera��o de T�tulo.")

					DbSelectArea ("SE1")
					DbSkip()     // salta para proxima nota
				EndDo

				If aRet[6] == "S"
					DbSelectArea("SD2")
					DbSetOrder(3) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
					If dbSeek(xFilial("SD2")+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA))


						While SD2->(!Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == xFilial("SD2")+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)

							Reclock("SD2",.F.)
							Replace D2_COMIS1 with aVend[1][3]
							Replace D2_COMIS2 with aVend[2][3]
							MSUnLock()

							DbSelectArea("SC6")
							DbSetOrder(1)
							If DbSeek(xFilial("SC6")+SD2->D2_PEDIDO+SD2->D2_ITEMPV)
								RecLock("SC6",.F.)
								Replace C6_COMIS1 with aVend[1][3]
								Replace C6_COMIS2 with aVend[2][3]
								MsUnlock()
							Endif
							DbSelectArea ("SD2")
							DbSkip()     // salta para proximo item
						EndDo
					Endif
				Endif
			Endif
		Else
			MsgAlert("A NF n�o � v�lida! Comunique o TI","Erro de nota fiscal")
		Endif

		dbSelectArea(cNextAlias)
		dbSkip()
	End
	(cNextAlias)->(DbCloseArea())

	If lAtuSC5
		DbSelectArea("SC5")
		Reclock("SC5",.F.)
		Replace C5_VEND1  with aVend[1][2]
		Replace C5_VEND2  with aVend[2][2]
		If aRet[6] == "S"
			Replace C5_COMIS1 with aVend[1][3]
			Replace C5_COMIS2 with aVend[2][3]
		Endif
		MSUnLock()
		MsgInfo("Pedido " + SC5->C5_NUM + "Alterado!!","Altera��o de Pedido")
	Endif

Return
