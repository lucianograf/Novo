# include "protheus.ch"

/*/{Protheus.doc} F200PORT
(Ponto de entrada que com retorno T/F se a baixa ser� pelo portador do Titulo ou pelo parametro)
@author MarceloLauschner
@since 20/08/2010 
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function F200PORT()

Return .F. //!MsgYesNo("Considerar Banco/Ag�ncia/Conta informados nos param�tros? " + chr(13)+chr(13) +"Se a op��o for 'N�o' os t�tulos ser�o baixados o Banco/Ag�ncia/Conta que estiver transferido cada t�tulo!","A T E N � � O!!")
