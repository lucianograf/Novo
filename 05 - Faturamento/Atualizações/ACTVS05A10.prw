#include 'totvs.ch'
#INCLUDE "Topconn.ch"
#Include "FWMVCDEF.CH"

/*/{Protheus.doc} ACTVS05A10 - 1
Monitor de Pedidos
@author -
@since 07/01/2020
@version undefined

@return return, return_description 1653
@example
(examples)
@see (links_or_references)
/*/
//27/08/2025 - 10:40 - teste - teste - teste
User Function ACTVS05A10()

	Local oBrowse
	Private cCadastro	:= 'Monitor de Pedidos'
	Private aRotina		:= MenuDef()
	Private l410Auto	:= .F.  // Vari�vel necess�ria para exclus�o 

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SC5')
	oBrowse:SetDescription(cCadastro)

	oBrowse:AddLegend("C5_SITDEC == '2'"						,"WHITE"	, "Em Montagem"			)	// Em Montagem
	oBrowse:AddLegend("C5_SITDEC == '6'"						,"PINK"		, "Rejeitado"			)	// Rejeitado
	oBrowse:AddLegend("C5_SITDEC == ' '.And. Empty(C5_LIBEROK)"	,"ORANGE"	, "Em Aberto"			)	// Em Aberto
	oBrowse:AddLegend("C5_SITDEC == '1'"						,"GREEN"	, "Lib. Faturamento"	)	// Liberado Faturamento
	oBrowse:AddLegend("C5_SITDEC == '5'"						,"RED"		, "Faturado"			)	// Faturado
	oBrowse:AddLegend("U_PEDLIB() == 0 .And. C5_SITDEC == ' '.And. C5_LIBEROK == 'S'.And. C5_BLQ == ' '"	,"YELLOW"	, "Aguardando Montagem"	)	// Aguardando Montagem
	oBrowse:AddLegend("U_PEDLIB() == 0 .And. C5_SITDEC == ' '.And. C5_LIBEROK == 'S'.And. C5_BLQ == '1'"	,"BROWN"	, "Bloqueio Comercial"	)	// Bloqueio Comercial Andr� 12/05/2021
	oBrowse:AddLegend("C5_SITDEC == '7'"						,"BR_CANCEL"	, "Rejei��o Comercial"	)	// REJEI��O Comercial Andr� 10/03/2022
	oBrowse:AddLegend("U_PEDLIB() == 2"							,"BLUE"		, "Bloqueio Estoque"	)	// Bloqueio Estoque
	oBrowse:AddLegend("U_PEDLIB() == 1"							,"BLACK"	, "Bloqueio Credito"	)	// Bloqueio Credito

	oBrowse:Activate()

Return Nil

/////////////////////////////////////////////////
// FUNCAO PARA CRIAR MENU PERSONALIZADO
/////////////////////////////////////////////////

Static Function MenuDef()

	Local 	aRotina 	:= {}
	

	ADD OPTION aRotina TITLE 'Montar Pedido'	ACTION 'U_MONPED'		OPERATION 2 	ACCESS 0
	ADD OPTION aRotina TITLE 'Impr. Pick List'	ACTION 'U_DEC05R02'		OPERATION 2 	ACCESS 0
	ADD OPTION aRotina TITLE 'Rejeitar Ped.'	ACTION 'U_REJPED'		OPERATION 4 	ACCESS 0
	ADD OPTION aRotina TITLE 'Lib.Faturamento'	ACTION 'U_LIBFAT'		OPERATION 5 	ACCESS 0
	ADD OPTION aRotina TITLE 'Dados Complem.'	ACTION 'U_COMPPED2'		OPERATION 6 	ACCESS 0
	ADD OPTION aRotina TITLE 'Prep.Docs'		ACTION 'Ma410PvNfs'		OPERATION 7 	ACCESS 0
	ADD OPTION aRotina TITLE 'Visualiza��o'		ACTION 'a410Visual'		OPERATION 2 	ACCESS 0
//	ADD OPTION aRotina TITLE 'Incluir'			ACTION 'a410Inclui'		OPERATION 3 	ACCESS 0
//	ADD OPTION aRotina TITLE 'Alterar'			ACTION 'a410Altera'		OPERATION 4 	ACCESS 0
//	ADD OPTION aRotina TITLE 'C�pia' 			ACTION "a410PCopia('SC5',SC5->(RecNo()),4)" OPERATION 6 ACCESS 0 
//	ADD OPTION aRotina TITLE 'Retornar'			ACTION "A410Devol('SC5',SC5->(RecNo()),4)" OPERATION 3 ACCESS 0 
//	ADD OPTION aRotina TITLE 'Excluir'			ACTION 'A410Deleta'		OPERATION 5 	ACCESS 0 
//	ADD OPTION aRotina TITLE 'Integrar Magento' ACTION 'U_DECA099'		OPERATION 3 	ACCESS 0
	ADD OPTION aRotina TITLE 'Impress�o Pedido'	ACTION 'U_ACTVS05R01'	OPERATION 9 	ACCESS 0
	ADD OPTION aRotina TITLE 'Espelho Pedido'	ACTION 'U_MLFATC07'		OPERATION 2 	ACCESS 0
	ADD OPTION aRotina TITLE 'Lib. Pedido'		ACTION 'U_A440LDec'		OPERATION 10	ACCESS 0
	ADD OPTION aRotina TITLE "Legenda"			ACTION "U_LEGPED()"		OPERATION 12 	ACCESS 0 	DISABLE MENU

Return aRotina

/////////////////////////////////////////////////
// FUNCAO PARA RETORNAR A LEGENDA
/////////////////////////////////////////////////

User Function LEGPED()

	Local aLegenda := {}

	aAdd(aLegenda,{"BR_AMARELO"		,"Aguardando Montagem"	})
	aAdd(aLegenda,{"BR_MARROM"		,"Bloq.Comercial"	}) //Andr� 12/05/2021
	aAdd(aLegenda,{"BR_CANCEL"		,"Rejei.Comercial"	}) //Andr� 10/03/2022
	aAdd(aLegenda,{"BR_PRETO"		,"Bloq.Credito"			})
	aAdd(aLegenda,{"BR_AZUL"		,"Bloq.Estoque"			})
	aAdd(aLegenda,{"BR_LARANJA" 	,"Em Aberto"			})
	aAdd(aLegenda,{"BR_BRANCO"		,"Em Montagem"			})
	aAdd(aLegenda,{"BR_VERMELHO"	,"Faturado"				})
	aAdd(aLegenda,{"BR_VERDE"		,"Lib.Faturamento"		})
	aAdd(aLegenda,{"BR_PINK"		,"Rejeitado"			})

	BrwLegenda(cCadastro, "Legenda", aLegenda)

Return Nil

/////////////////////////////////////////////////
// FUNCAO PARA LEGENDAS/FILTROS
/////////////////////////////////////////////////
User Function PEDLIB()

	Local _RetPed := 0

	If SC5->C5_SITDEC == ' '.And. SC5->C5_LIBEROK == 'S'
		If SC9->(DbSeek(/*xFilial("SC9")*/SC5->C5_FILIAL+SC5->C5_NUM))
			While SC9->C9_FILIAL == SC5->C5_FILIAL/*xFilial("SC9")*/ .And. SC9->C9_PEDIDO == SC5->C5_NUM .And. !SC9->(Eof())
				If !Empty(SC9->C9_BLCRED)
					_RetPed := 1 //.F.
				ElseIf !Empty(SC9->C9_BLEST)
					_RetPed := 2 //.F.
				EndIf
				SC9->(DbSkip())
			End
		EndIf
	EndIf

Return _RetPed

/*/{Protheus.doc} MONPED
Fun��o para iniciar montagem 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 03/12/2020
@return return_type, return_description
/*/
User Function MONPED()

	If SC5->C5_BLQ == "1" //Andr� 12/05/2021
		Alert("Pedido com bloqueio comercial!!!")
		Return
	EndIf

	If SC5->C5_SITDEC == "5"
		Alert("Pedido J� Faturado!!!")
		Return
	EndIf

	If SC5->C5_SITDEC == "1"
		Alert("Pedido J� Liberado para Faturamento!!!")
		Return
	EndIf

	If SC5->C5_SITDEC == "2"
		Alert("Pedido J� Em Processo de Montagem!!!")
		Return
	EndIf

	If SC5->C5_SITDEC == '6' .Or. !Empty(SC5->C5_ZMOTREJ)
		MsgAlert("Pedido anteriormente rejeitado."+ CRLF +;
			Iif(!Empty(SC5->C5_ZMOTREJ),"Motivo: "+SC5->C5_ZMOTREJ,"N�o foi informado o motivo de rejei��o."),"Aten��o - "+ProcName())
	EndIf

	_RetLib := .t.
	If SC9->(DbSeek(SC5->C5_FILIAL/*xFilial("SC9")*/+SC5->C5_NUM))
		While SC9->C9_FILIAL == SC5->C5_FILIAL/*xFilial("SC9")*/ .And. SC9->C9_PEDIDO == SC5->C5_NUM .And. !SC9->(Eof())
			If !Empty(SC9->C9_BLCRED)
				_RetLib := .f.
			EndIf
			If !Empty(SC9->C9_BLEST)
				_RetLib := .f.
			EndIf
			SC9->(DbSkip())
		End
	Else
		_RetLib := .F.
	EndIf

	If !_RetLib
		Alert("N�o � Poss�vel Iniciar Montagem Para Pedidos Com Bloqueio!!!")
		Return
	EndIf

	If MsgYesNo("Deseja Iniciar Montagem do Pedido "+SC5->C5_NUM+"?")
		RecLock("SC5",.f.)
		SC5->C5_SITDEC := "2"
		MsUnLock()
		
		If ALLTRIM(SC5->C5_FILIAL) $ "0104#0101"
			if MsgYesNo("Deseja imprimir o PickList ? ")
				U_DEC05R02()
			endIf
			if MsgYesNo("Deseja Imprimir o Pedido ? ")
				U_ACTVS05R01()
			endIf
		else
			if MsgYesNo("Deseja Imprimir o Pedido ? ")
				U_ACTVS05R01()
			endIf
		Endif
	EndIf

Return

/////////////////////////////////////////////////
// FUNCAO PARA REJEITAR O PEDIDO
/////////////////////////////////////////////////

User Function REJPED()

	// Usu�rios com permiss�es para Rejeitar o pedido: Idezio, Expedic�o, Joseane, Priscila, Luciano, Admin, Andre
	Local cBlqPed := GETMV("MV_ZBLQPED") 
	Local cCodUsr := RetCodUsr()
	Local lBlq := .F.
	lRet := .T.
	
	//	DV* JS  Dt: 15/07/2021
	if !(cCodUsr $ cBlqPed)
		lBlq := .F.
		if SC5->C5_SITDEC == '1' .AND. SC5->C5_FILIAL $ "0104#0101"
			MsgInfo("Pedido se encontra no status Liberado Faturamento e n�o pode ser rejeitado.","Aten��o - "+ProcName())
			lBlq := .T.
		elseif SC5->C5_SITDEC == '2' .AND. SC5->C5_FILIAL $ "0104#0101"
			MsgInfo("Pedido se encontra no status Em montagem e n�o pode ser rejeitado.","Aten��o - "+ProcName())
			lBlq := .T.
		elseif SC5->C5_SITDEC == '6' .AND. SC5->C5_FILIAL $ "0104#0101"
			MsgInfo("Pedido j� se encontra no status rejeitado.","Aten��o - "+ProcName())
			lBlq := .T.
		endIf
	Endif
	
	If !lBlq 
		If SC5->C5_SITDEC == "5"
			Alert("Pedido J� Faturado!!!")
			Return
		EndIf

		If MsgYesNo("Deseja Rejeitar o Pedido "+SC5->C5_NUM+"?")
			lRet := LIBPV()

			If lRet
				MsgInfo("Pedido alterado para o Status 'Rejeitado'.","Aten��o - "+ProcName())
			EndIf
		EndIf
	Endif
	
Return

/////////////////////////////////////////////////
// FUNCAO PARA LIBERAR O PEDIDO
/////////////////////////////////////////////////

User Function LIBFAT()

	if !Empty(SC5->C5_ZPDRELA)
		cAliasPR := ''
		BeginSql Alias "cAliasPR"
			SELECT C5_NOTA AS NF
			FROM %Table:SC5% SC5
			WHERE 
			C5_NUM = SUBSTRING(%Exp:SC5->C5_ZPDRELA%,5,6)
			AND C5_FILIAL = SUBSTRING(%Exp:SC5->C5_ZPDRELA%,1,4)
			AND SC5.%notDel%
		EndSql
		if Empty(cAliasPR->NF)
			MsgAlert("Este pedido possui um relacionamento, fature o pedido: "+TRIM(SC5->C5_ZPDRELA)+" antes","Pedido relacionado")
			cAliasPR->(DbCloseArea())
			Return
		EndIf
		cAliasPR->(DbCloseArea())
	EndIf

	If ALLTRIM(SC5->C5_TRANSP) == "9999" 
		MsgAlert("Corrija a transportadora na rotina 'Dados Complem.'","Transportadora Invalida")
		Return
	EndIf

	If SC5->C5_BLQ == "1" //Andr� 12/05/2021
		Alert("Pedido com bloqueio comercial!!!")
		Return
	EndIf

	If SC5->C5_SITDEC == "5"
		Alert("Pedido J� Faturado!!!")
		Return
	EndIf

	_RetLib := .t.
	If SC9->(DbSeek(SC5->C5_FILIAL/*xFilial("SC9")*/+SC5->C5_NUM))
		While SC9->C9_FILIAL == SC5->C5_FILIAL/*xFilial("SC9")*/ .And. SC9->C9_PEDIDO == SC5->C5_NUM .And. !SC9->(Eof())
			If !Empty(SC9->C9_BLCRED)
				_RetLib := .f.
			EndIf
			If !Empty(SC9->C9_BLEST)
				_RetLib := .f.
			EndIf
			SC9->(DbSkip())
		End
	Else
		_RetLib := .f.
	EndIf

	If !_RetLib
		Alert("N�o � Poss�vel Liberar Pedidos Com Bloqueio!!!")
		Return
	EndIf

	If MsgYesNo("Deseja Liberar o Pedido "+SC5->C5_NUM+" Para Faturamento?")
		RecLock("SC5",.f.)
		SC5->C5_SITDEC := "1"
		MsUnLock()
		U_COMPPED2()
	EndIf

Return

/////////////////////////////////////////////////
// FUNCAO PARA LIBERAR NOVAMENTE PV REJEITADO
/////////////////////////////////////////////////

Static Function LIBPV()

	Local lRet		 := .T.	
	Local cMotRej	 := ''
	Local cMotRejTmp := ''
	Local cMsgInt	 := Alltrim(SC5->C5_ZMSGINT)
	Local cOldMem	 := Alltrim(SC5->C5_ZMOTREJ)

	PRIVATE lMsErroAuto := .F.

	Begin Sequence

		While Empty(cMotRejTmp)
			cMotRejTmp := FWInputBox("Informe o motivo de rejei��o: ")
			If Empty(cMotRejTmp)
				Alert("Voc� n�o informou o motivo de rejei��o.")
			EndIf
		EndDo
		If Empty(cOldMem)
			cMotRej := "["+Alltrim(cUserName)+"]["+cValToChar(DATE())+"]"+"["+cValToChar(TIME())+"]: "+cMotRejTmp
		Else
			cMotRej := "["+Alltrim(cUserName)+"]["+cValToChar(DATE())+"]"+"["+cValToChar(TIME())+"]: "+cMotRejTmp+CRLF+cOldMem
		EndIf

		cMsgInt	:= cMotRej + CRLF + cMsgInt 


		//FWMsgRun(/*oComponent*/,{|| MsExecAuto({|a,b,c| MATA410(a,b,c)}, aCabec, aItens,4)  },,"Alterando pedido de venda" )
		//Extorna SC9 caso possuir liberado
		//BEGIN TRANSACTION
		dbSelectArea("SC9")
		dbSetOrder(1)
		If dbSeek(fwxFilial("SC9")+SC5->C5_NUM)

			While SC9->(!EOF()) .AND. SC9->(C9_FILIAL + C9_PEDIDO) == FWxFilial("SC9") +SC5->C5_NUM
				SC6->(dbSeek(FWxFilial('SC6')+SC5->C5_NUM+SC9->C9_ITEM))
				SC9->(a460Estorna())
				SC9->(dbSkip())
			Enddo
		EndIf

		
		DbSelectArea("SC5")
		If !Eof()
			RecLock("SC5",.F.)
			//SC5->C5_SITDEC  := " "
			SC5->C5_SITDEC  := '6'
			SC5->C5_ZMOTREJ	:= cMotRej
			SC5->C5_ZMSGINT := cMsgInt 
			MsUnLock()
		Endif
		//Refaz a libera��o do pedido
		DbSelectArea("SC6")
		SC6->(DbSetOrder(1))
		If SC6->(DbSeek(xFilial("SC6")+SC5->C5_NUM))
			While SC6->(!Eof()) .And. xFilial("SC6")+SC5->C5_NUM == SC6->(C6_FILIAL+C6_NUM)
				// Para liberar os itens para a SC9
				If !MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN,.T.,.T.)
					lRet := .F.
					MsgAlert("N�o foi poss�vel efetuar a libera��o autom�tica do item "+alltrim(SC6->C6_ITEM)+" do pedido "+alltrim(SC5->C5_NUM),"Aten��o - "+ProcName())
					Break
				EndIf
				SC6->(dbSkip())
			EndDo
			// Para marcar o pedido como liberado
			If lRet
				MaLiberOk({ SC5->C5_NUM },.T.)
			EndIf
		EndIf
		//END TRANSACTION

	End Sequence

Return lRet

/*/{Protheus.doc} COMPPED2

Fun��o criada para chamar a nova tela de dados complementares.

@author TSCB57 - WILLIAM FARIAS
@since 30/07/2019
@version 1.0
@example example
@return return
/*/
User Function COMPPED2()

	If SC5->C5_SITDEC == "5"
		MsgStop("Dados Complementares Somente Para Pedidos N�o Faturados!!!")
		Return
	Else
		//U_FAT002()
		// TSC679 - CHARLES REITZ - 15/01/2019
		// ALTERADO PARA O MODELO MVC
		nOpcRt:= FWExecView('Dados Complementares','CALA026',4,/*oBrowse:_oOwner*/,/*bCloseOnOk*/, /*bOk*/, /*nPercReducao*/,/*aEnableButtons*/, /*bCancel*/ )
	EndIf

Return

User Function COMPPED() // funcao recursiva para controlar as chamadas da tela

// Variaveis Locais da Funcao
	Private cEspecie	 := "VOLUME(S)" //Space(25)
	Private cTransp		 := SC5->C5_TRANSP
	Private cGet1	     := SC5->C5_PESOL
	Private cGet2	     := SC5->C5_PBRUTO
	Private nVolumes	 := SC5->C5_VOLUME1
	Private ocEspecie
	Private ocTransp     := SC5->C5_TRANSP
	Private oGet1		 := SC5->C5_PESOL
	Private oGet2		 := SC5->C5_PBRUTO
	Private onVolumes	 := SC5->C5_VOLUME1

// Variaveis Private da Funcao
	Private oDlg1				// Dialog Principal
// Variaveis que definem a Acao do Formulario
	Private VISUAL := .F.
	Private INCLUI := .F.
	Private ALTERA := .F.
	Private DELETA := .F.

	If SC5->C5_SITDEC # "1"
		MsgStop("Dados Complementares Somente Para Pedidos N�o Faturados COMPED!!!")
		Return
	EndIf

	DEFINE MSDIALOG oDlg1 TITLE "Dados Complementares" FROM C(178),C(181) TO C(420),C(742) PIXEL

	// Cria Componentes Padroes do Sistema
	@ C(009),C(021) Say "Transportadora" Size C(039),C(008) COLOR CLR_BLACK PIXEL OF oDlg1
	@ C(009),C(063) MsGet ocTransp Var cTransp F3 "SA4" Size C(033),C(009) COLOR CLR_BLACK Picture "@!" PIXEL OF oDlg1
	@ C(029),C(021) Say "Volumes" Size C(039),C(008) COLOR CLR_BLACK PIXEL OF oDlg1
	@ C(029),C(063) MsGet onVolumes Var nVolumes Size C(032),C(009) COLOR CLR_BLACK Picture "@E 9,999.99" PIXEL OF oDlg1
	@ C(048),C(063) MsGet ocEspecie Var cEspecie Size C(060),C(009) COLOR CLR_BLACK Picture "@!" PIXEL OF oDlg1
	@ C(051),C(021) Say "Especie" Size C(037),C(008) COLOR CLR_BLACK PIXEL OF oDlg1
	@ C(067),C(063) MsGet oGet1 Var cGet1 Size C(033),C(009) COLOR CLR_BLACK Picture "@E 9,999.99" PIXEL OF oDlg1
	@ C(069),C(021) Say "Peso Liquido" Size C(033),C(008) COLOR CLR_BLACK PIXEL OF oDlg1
	@ C(087),C(063) MsGet oGet2 Var cGet2 Size C(033),C(009) COLOR CLR_BLACK Picture "@E 9,999.99" PIXEL OF oDlg1
	@ C(089),C(021) Say "Peso Bruto" Size C(033),C(008) COLOR CLR_BLACK PIXEL OF oDlg1
	@ C(104),C(184) Button "OK" Size C(037),C(012) PIXEL OF oDlg1 ACTION MsgRun("Dados Complementares","Gravando",{|| GRVDC() })
	@ C(104),C(225) Button "Cancelar" Size C(037),C(012) PIXEL OF oDlg1 ACTION oDlg1:End()

	// Cria ExecBlocks dos Componentes Padroes do Sistema

	ACTIVATE MSDIALOG oDlg1 CENTERED

Return(.T.)

Static Function C(nTam)
	Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor
	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
		nTam *= 0.8
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600
		nTam *= 1
	Else	// Resolucao 1024x768 e acima
		nTam *= 1.28
	EndIf

Return Int(nTam)

Static Function GRVDC

	RecLock("SC5",.f.)
	SC5->C5_VOLUME1 := nVolumes
	SC5->C5_ESPECI1 := cEspecie
	SC5->C5_TRANSP  := cTransp
	SC5->C5_PESOL   := cGet1
	SC5->C5_PBRUTO  := cGet2
	MsUnLock()

	oDlg1:End()

Return

/*/{Protheus.doc} A440LDec
Executa a rotina padrao de liberacao do pedido (Mata440)
@author TSCB57 - william.farias
@since 17/12/2019
@version 1.0
@example
(examples)
@see (links_or_references)
/*/
User Function A440LDec()

	Local aAreaAnt 	:= GETAREA()

	//Verifica as perguntas selecionadas
	If !Pergunte("MTA440",.T.)
		Return
	EndIf
	//Transfere locais para a liberacao
	PRIVATE lTransf:=MV_PAR01==1
	//Libera Parcial pedidos de vendas
	PRIVATE lLiber :=MV_PAR02==1
	//Sugere quantidade liberada
	PRIVATE lSugere:=MV_PAR03==1

	// Verifica o status do Pedido
	U_MLFATC07()

	//Executa libera�� de pedido

	a440Libera("SC5", SC5->(RecNo()), 6)

	RestArea(aAreaAnt)

Return
