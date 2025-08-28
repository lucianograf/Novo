#include 'protheus.ch'

/*/{Protheus.doc} MA410MNU
Ponto de Entrada: MA410MNU - Adiciona rotinas customizadas no menu do pedido de vendas.
@type function
@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@return return_type, return_description
/*/
User Function MA410MNU()

	aAdd(aRotina,{"Impressao Pedido*","U_ACTVS05R01",0,3,0,NIL}) 
	
	aAdd(aRotina,{"Integrar Magento*","U_DECA099"	,0,3,0,NIL})
	
	aAdd(aRotina,{"Espelho Pedido*","U_MLFATC07",0,2,0,NIL}) 
	
	//aAdd(aRotina,{"Monitor Magento*","U_DECA098",0,3,0,NIL})
	
Return
