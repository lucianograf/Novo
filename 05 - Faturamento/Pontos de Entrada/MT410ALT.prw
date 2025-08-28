#include 'protheus.ch'
#include "Rwmake.ch"
#include "Topconn.ch"
 
/*
+----------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! MT410ALT                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada criado para atender a necessidade de   !
!                  ! criar uma reserva a cada pedido gerado. Esta sendo utili!
!                  ! zada a mesma função do Ecommerce para atender a demanda !
+------------------+---------------------------------------------------------+
!Autor             ! TSCB56 - Rafael de Souza                                !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/09/19                                                !
+------------------+---------------------------------------------------------+
*/
User Function MT410ALT()
//TSCB57 - william.farias em 17/12/2019 - INICIO
//Comentado regra de reserva, conforme solicitação do André.
/*
	Local cPedido	:= SC5->C5_NUM
	Local lRet 		:= FWIsInCallStack("U_DECA099")
	Local aItens 	:= {}
	Local aItemPV 	:= {}

	If !lRet

		DbSelectArea("SC6")
		DbSetOrder(1)
		DbGoTop()
		If DbSeek(xFilial("SC6")+SC5->C5_NUM)

			//Adiciona itens no array
			While !Eof() .AND. SC6->C6_NUM == SC5->C5_NUM
				aItemPV:={	{"C6_ITEM",SC6->C6_ITEM		,Nil},;
				{"C6_PRODUTO"	,SC6->C6_PRODUTO		,Nil},;
				{"C6_OPER"		,SC6->C6_OPER			,Nil},;
				{"C6_TES"		,SC6->C6_TES			,Nil},;
				{"C6_QTDVEN"	,SC6->C6_QTDVEN			,Nil},;
				{"C6_UM"		,SC6->C6_UM				,Nil},;
				{"C6_PRCVEN"	,SC6->C6_PRCVEN			,Nil},;
				{"C6_VALDESC"	,SC6->C6_VALDESC		,Nil},;
				{"C6_ENTREG"	,SC6->C6_ENTREG			,Nil},;
				{"C6_LOCAL"		,SC6->C6_LOCAL			,Nil},;
				{"C6_NUM"		,SC6->C6_NUM			,Nil},;
				{"C6_LOCALIZ"	,SC6->C6_LOCALIZ		,Nil}}
				AADD(aItens,aItemPV)

				DbSkip()

			EndDo
			
			cNumPed := aItens[1][11][2]
			
			If !Empty(aItens)
				U_DECARESERV(aItens)
				
				//Query de consulta SC0
				U_QrySC0(cNumPed)

				If !cAliasSC0->(eof())
					cQryUPD := "UPDATE "+RetSqlName("SC6")+" "
					cQryUPD += "SET C6_RESERVA = '"+cAliasSC0->C0_NUM+"' "
					cQryUPD += "WHERE "
					cQryUPD += "C6_FILIAL = '"+cAliasSC0->C0_FILIAL+"' AND "
					cQryUPD += "C6_NUM = '"+cNumPed+"' AND "
					cQryUPD += "D_E_L_E_T_ = '' "
					TCSqlExec(cQryUPD)
				EndIf

			Else
				MsgAtert("Não foi possível encontrar o registro de reserva para o item >>>MT410ALT<<< ","Atenção")
			EndIf

			If Select("cAliasSC0") <> 0
				cAliasSC0->(DbCloseArea())
			EndIf

		EndIf
	Endif
*/
Return