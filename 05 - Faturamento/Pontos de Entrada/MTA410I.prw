#INCLUDE "topconn.ch"
#INCLUDE "rwmake.ch"

/*/{Protheus.doc} MTA410I
(Ponto de entrada na inclusão de pedido de venda)
	Este ponto de entrada pertence à rotina de pedidos de venda, MATA410(). 
	Está localizado na rotina de gravação do pedido, A410GRAVA().
	 É executado durante a gravação do pedido, após a atualização de cada item.
	
@author MarceloLauschner
@since 04/12/2013
@version 1.0		

@return Sem retorno esperado

@example
(examples)

@see (links_or_references)
/*/
User Function MTA410I()

	// Efetua chamda da função controlada no PE MT410ABN
	U_MLF3KATU()

Return
