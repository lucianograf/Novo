#include 'protheus.ch'
#include "Rwmake.ch"
#include "Topconn.ch"

/*
+----------------------------------------------------------------------------+
!                             FICHA TECNICA DO PROGRAMA                      !
+----------------------------------------------------------------------------+
!Programa          ! A410EXC                                                !
+------------------+---------------------------------------------------------+
!Descricao         ! Ponto de entrada criado para atender a necessidade de   !
!                  ! excluir uma reserva realizada pelo pedido de venda inclu!
!                  ! ido no protheus                                         !
+------------------+---------------------------------------------------------+
!Autor             ! TSCB56 - Rafael de Souza                                !
+------------------+---------------------------------------------------------+
!Data de Criacao   ! 04/09/19                                                !
+------------------+---------------------------------------------------------+
*/
User Function A410EXC()

//	Local cPedido	:= SC5->C5_NUM
	Local lRet 		:= .T.

	cQry := "DELETE FROM " + RetSqlName("ZCC")
	cQry += " WHERE D_E_L_E_T_ =' ' "
	cQry += "   AND ZCC_NUM  = '"+SC5->C5_NUM + "' "
	cQry += "   AND ZCC_FILIAL = '" + xFilial("ZCC") + "' "
	Begin Transaction
		Iif(TcSqlExec(cQry) < 0,ConOut(TcSqlError()),TcSqlExec("COMMIT"))
	End Transaction

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
				{"C6_NUM"		,SC6->C6_NUM			,Nil}}
				AADD(aItens,aItemPV)

				DbSkip()

			EndDo
			
			If !Empty(aItens)
				U_DECARESERV(aItens)
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
