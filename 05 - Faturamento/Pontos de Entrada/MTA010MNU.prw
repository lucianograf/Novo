#include 'protheus.ch'
#include 'parmtype.ch'
/*/{Protheus.doc} MTA010MNU

Adiciona novas opcoes no outras acoes do menu do cadstro de produto

@author CHARLES REITZ
@since 28/05/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function MTA010MNU()

	AAdd(aRotina, {"Magento - Integrar Todos Produtos*", "U_DECA006()", 0, 3, 0, NIL})
	AAdd(aRotina, {"Magento - Integrar Produto Selecionado*", "U_DECA006(SB1->B1_COD)", 0, 3, 0, NIL})

return