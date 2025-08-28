#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} DECA100
Carrega vendedor 2 e comissão 2 do cliente na tela do pedido de venda.

Adicionar chamada na validacao de usuario do campo C5_LOJACLI.

@author TSCB57 - William Farias
@since 29/07/2019
@version 1.0
@return logic
/*/
//Teste Commit 27/08/2025 - 08:34
User Function DECA100()
	
	Local aArea	:= GetArea()
	Local lRet	:= .T.
	
	If FWIsInCallStack("A410Inclui") .Or. FWIsInCallStack("A410Altera")
		
		dbSelectArea("SA1")
		dbSetOrder(1)
		If !dbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
			MsgInfo("Cliente não encontrado na busca do vendedor 2.","ATENÇÃO")
		Else
			M->C5_VEND2 := If(Empty(M->C5_MDCONTR),SA1->A1_ZVEND2,M->C5_VEND2)
		
			dbSelectArea("SA3")
			SA3->(dbSetOrder(1))
			If ( !MsSeek(xFilial("SA3")+M->C5_VEND2) ) 
				M->C5_VEND2 := Space(TamSX3("A1_ZVEND2")[1])
			Else
				If !RegistroOk("SA3",.F.)
					MsgInfo("Código do vendedor 2: "+M->C5_VEND2+" utilizado por este cliente está bloqueado no cadastro de vendedores!","ATENÇÃO")
					M->C5_VEND2 := Space(TamSX3("A1_ZVEND2")[1])
				Else
					//M->C5_COMIS2 := If(Empty(M->C5_MDCONTR),Iif(!Empty(SA1->A1_COMIS),SA1->A1_COMIS,SA3->A3_COMIS),M->C5_COMIS2)
					M->C5_COMIS2 := If(Empty(M->C5_MDCONTR),Iif(!Empty(SA1->A1_ZCOMIS2),SA1->A1_ZCOMIS2,SA3->A3_COMIS),M->C5_COMIS2)
				EndIf
			EndIf
		EndIf
	EndIf
	RestArea(aArea)

Return lRet
