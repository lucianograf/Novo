#Include 'Protheus.ch'

//====================================================================================================================\\
/*/{Protheus.doc}CHGX5FIL
  ====================================================================================================================
	@description
	Ponto-de-Entrada: CHGX5FIL - Utiliza Tabela 01 Exclusiva em um SX5 Compartilhado

	Este Ponto de Entrada, localizado no TMSA200.PRW(C�lculo do Frete), foi criado para utilizar uma Tabela 01 exclusiva
	em um SX5 compartilhado.

	@author		TSC681 Thiago Mota
	@version	1.0
	@since		11/08/2015
	@return		Caractere, Padr�o: xFilial("SD9") - Indica qual o conte�do do campo filial que deve ser gravado na SX5

	@obs
	Tamb�m chamado pela fun��o MA461NumNf do programa MATA461.

	http://tdn.totvs.com/display/public/mp/CHGX5FIL+-+Utiliza+Tabela+01+Exclusiva+em+um+SX5+Compartilhado

/*/
//====================================================================================================================\\
User Function CHGX5FIL
	Local xPeRet := xFilial("SD9")

Return ( xPeRet )
// FIM do Ponto de Entrada CHGX5FIL
//====================================================================================================================\\


