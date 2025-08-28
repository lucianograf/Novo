/*/{Protheus.doc} MS520DEL
Ponto de entrada no Cancelamento de Nota Fiscal
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/10/2021
@return variant, return_description
/*/
User Function MS520DEL()

//	Local 	lGrvMsg		:= SC5->(FieldPos("C5_ZMSGINT")) > 0 // Garante que o campo existe
	Local 	cMsgInt		:= ""

	DbSelectArea("SC5")
	DbSetOrder(1)
	If SC5->(DbSeek(xFilial("SC5")+SD2->D2_PEDIDO))
		RecLock("SC5",.F.)
		SC5->C5_SITDEC = " "
		If lGrvMsg
			cMsgInt	:= "Cancelamento de nota Fiscal " + SD2->D2_DOC +;
				" emitida em "+ DTOC(SD2->D2_EMISSAO) + " realizado por " +;
				UsrFullName(RetCodUsr()) + " no dia " + DTOC(Date()) + " às " + Time() + "hs - "
			cMsgInt += SC5->C5_ZMSGINT
			SC5->C5_ZMSGINT	:= cMsgInt
		Endif
		MsUnLock()
	EndIf


	//Estorna registro do controle de conta corrente / flex.

	DbSelectArea("ZCC")
	DbSetOrder(1)
	if ZCC->(DbSeek(xFilial("ZCC")+SD2->D2_PEDIDO))
		Do while ZCC->(!eof()) .AND. SD2->D2_FILIAL == ZCC->ZCC_FILIAL .AND. SD2->D2_PEDIDO == ZCC->ZCC_NUM
			RecLock('ZCC',.F.)
			ZCC->ZCC_DOC   := "CANCELADA"
			ZCC->ZCC_SERIE := ""
			MsUnlock()
			dbSkip()
		Enddo
	EndIf

Return
