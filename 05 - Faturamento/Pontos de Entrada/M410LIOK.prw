#include "protheus.ch"

/*/{Protheus.doc} M410LIOK
description
@type function
@version  
@author Marcelo Alberto Lauschner
@since 14/10/2021
@return variant, return_description
/*/
User Function M410LIOK()
	
	Local	aAreaOld		:= GetArea()
    Local	nPCCusto  		:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CC"})
	Local	nPxCF			:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_CF"})
	Local	lRet			:= .T.
	Local	cCfopVldCC		:= "5910/6910/5949/6949" // Final de CFops que obrigará ter Centro de Custo 
	
	
	// 14/10/2021 - Pedido tipo Normal - Linha não deletada - Cfops de Brinde/Outras Saídas - Centro Custo em branco 
	If lRet .And. nPCCusto > 0 .And. M->C5_TIPO == "N" .And. !aCols[n,Len(aHeader)+1] .And. Alltrim(aCols[n,nPxCF]) $ cCfopVldCC .And. Empty(aCols[n,nPCCusto])
		If !IsBlind()
			MsgAlert("Este tipo de operação requer que seja informado o centro de custo. Favor conferir o campo Centro de Custo e preencher!",ProcName(0)+"."+ Alltrim(Str(ProcLine(0)))+" Validação")
		    lRet := .F.
        Endif
		
	Endif	
	RestArea(aAreaOld)

Return lRet
