#include 'totvs.ch'
/*/{Protheus.doc} FA740BRW

O ponto de entrada FA740BRW foi desenvolvido para adicionar itens no menu da mBrowse.
Retorna array com os novas op��es e manda como par�metro o array com as op��es padr�o.

@author TSCB57 - William Farias
@since 13/08/2019
@version 1.0
@return return, return_description
/*/
User Function FA740BRW()

	Local aBotao := {}

	aAdd(aBotao,{'Transf. Lote',"U_DECA150",0,4})

Return(aBotao)
