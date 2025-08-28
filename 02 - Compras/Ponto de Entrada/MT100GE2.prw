#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} MT100GE2

Localiza��o.: Function A103AtuSE2 - Rotina que efetua a integra��o entre o documento de entrada e os t�tulos financeiros a pagar,ap�s a grava��o de cada parcela.
Finalidade...: Complementar a grava��o na tabela dos t�tulos financeiros a pagar.

@author charles.reitz
@since 28/01/2020
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/

user function MT100GE2()

	If (INCLUI .OR. ALTERA)

		//SE2->(RecLock("SE2",.F.))

		//Grava obsserva��es informadas no documento de entrada no t�tulo gerado para o financeiro
		If Type("cCondicao")=="C" .AND. !Empty(cCondicao)
			SE2->E2_ZCONPAG	:=	cCondicao
		EndIf

		//SE2->(MsUnlock())
	EndIf


return