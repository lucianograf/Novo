#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
/*/{Protheus.doc} SF2460I
Ponto de Entrada - Final da geração da nota fiscal / Ajusta grupo de perguntas para impressão do Danfe / 
@type function
@version 
@author William Farias
@since 28/08/2019
@return return_type, return_description
/*/
User Function SF2460I()
	Local	aAreaOld		:= GetArea()


	// Atualiza status do Pedido faturado - Monitor Pedidos
	If SC5->(DbSeek(xFilial("SC5")+SD2->D2_PEDIDO))
		RecLock("SC5",.F.)
		SC5->C5_SITDEC = "5"
		MsUnLock()
	EndIf

	//Atualiza o controle do conta corrente - FLEX
	DbSelectArea("ZCC")
	DbSetOrder(1)
	if DbSeek(SF2->F2_FILIAL+SD2->D2_PEDIDO)
		Do while ZCC->(!eof()) .AND. SF2->F2_FILIAL == ZCC->ZCC_FILIAL .AND. SD2->D2_PEDIDO == ZCC->ZCC_NUM
			RecLock('ZCC',.F.)
			ZCC->ZCC_DOC   := SF2->F2_DOC
			ZCC->ZCC_SERIE := SF2->F2_SERIE
			ZCC->ZCC_DATA  := SF2->F2_EMISSAO
			MsUnlock()
			dbSkip()
		Enddo
	EndIf


	//Atualiza o controle do conta corrente - FLEX
	//DbSelectArea("ZCC")
	//DbSetOrder(1)
	//if DbSeek(SF2->F2_FILIAL+SD2->D2_PEDIDO)
	//	RecLock('ZCC',.F.)
	//		ZCC->ZCC_DOC   := SF2->F2_DOC
	//		ZCC->ZCC_SERIE := SF2->F2_SERIE
	//		ZCC->ZCC_DATA  := SF2->F2_EMISSAO
	//	ZCC->(MsUnlock())
	//EndIf

	// 06/10/2020 - Atualizar flag no cadastro do Cliente para integração Máxima
	If !(SF2->F2_TIPO $ "D#B")
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)
			If GetNewPar("DC_INMAXOK",.F.)
				U_XFLAG("SA1")
			Endif 
		Endif
	Endif

	// Atualiza Grupo de perguntas
	Dbselectarea("SX1")
	DbsetOrder(1)
	If SX1->(Dbseek("NFSIGW    "+"01"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= SF2->F2_DOC
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"02"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= SF2->F2_DOC
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"03"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= SF2->F2_SERIE
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"04"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= "2"
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"05"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= "2"
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"06"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= "2"
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"07"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= DToS(SF2->F2_EMISSAO)
		SX1->(MsUnlock())
	EndIf
	If SX1->(Dbseek("NFSIGW    "+"08"))
		Reclock("SX1",.F.)
		SX1->X1_CNT01:= DToS(SF2->F2_EMISSAO)
		SX1->(MsUnlock())
	EndIf

	RestArea(aAreaOld)

Return
