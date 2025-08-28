#include 'protheus.ch'

/*/{Protheus.doc} M410PVNF
Ponto de entrada na validação para Faturamento de Pedidos na rotina MATA410
@type function
@version 
@author Marcelo Alberto Lauschner
@since 15/12/2020
@return return_type, return_description
/*/
User Function M410PVNF()

	Local	lRet := .T.


	If Funname() == "MATA410"
		lRet := .F.
		MsgStop("Rotina Nao Autorizada!!! Utilize a Rotina de Monitor de Pedidos!!!")
	Else
		If SC5->C5_SITDEC # "1"
			lRet := .F.
			MsgStop("Pedido Ainda Nao Liberado!!! Utilize a Rotina de Monitor de Pedidos!!!")
		EndIf
	EndIf

	If lRet 
		// Verifica o status do Pedido antes de poder faturar 
		//U_MLFATC07(@lRet)
	Endif 

Return lRet
