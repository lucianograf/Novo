#include "totvs.ch"
/*/{Protheus.doc} F200X1VLD
(long_description)
@author MarceloLauschner
@since 06/02/2015
@version 1.0
@param nParValid, num�rico, (Descri��o do par�metro)
@param cVldRot, character, (Descri��o do par�metro)
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/


User Function F200X1VLD(nParValid,cVldRot) // Numero do parametro a validar
    // Rotina de pergunta a ser validada
    Local		cArqRet			:= MV_PAR05
    Local		cBanco			:= MV_PAR06
    Local		cAgenc  		:= MV_PAR07
    Local   	cConta			:= MV_PAR08
    Local		cSubCc			:= MV_PAR09
    Local		nModCnab		:= 1
    Local		aAreaOld		:= GetArea()

    Local		lRet			:= .F.
    Default 	cVldRot			:= "AFI200"
    Default		nParValid		:= 6

    dbSelectArea("SEE")
    DbSetOrder(1)

    // Se for valida��o a partir do relatorio de Comunicacao Bancaria
    If cVldRot == "FIN650"
        cArqRet		:= MV_PAR02
        cBanco		:= MV_PAR03
        cAgenc  	:= MV_PAR04
        cConta		:= MV_PAR05
        nModCnab	:= MV_PAR08

        SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )

        cSubCc		:= MV_PAR06
        If nParValid == 2  // Se valida��o do parametro 2-Arquivo de retorno, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta
            lRet 	:= .T.
        Else
            If nParValid == 3 // Se valida��o do c�digo de banco, posiciona na subconta encontrada pois n�o existe retorna dele pelo F3
                cSubCc 		:= SEE->EE_SUBCTA
                MV_PAR06    := cSubCc
                MV_PAR08	:= IIf(SEE->EE_NRBYTES == 240,2,1)
            Endif
            lRet	:= .F.
        Endif

    ElseIf cVldRot == "AFI150" // Rotina de gera��o de arquivo de envio cnab
        cArqRet		:= MV_PAR03 // Arquivo de configuracao .rem
        cBanco		:= MV_PAR05
        cAgenc  	:= MV_PAR06
        cConta		:= MV_PAR07
        nModCnab	:= MV_PAR09
        SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )
        cSubCc		:= MV_PAR08
        If nParValid == 3  // Se valida��o do parametro 3-Arquivo de remessa, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta
            lRet 	:= .T.
        Else
            If nParValid == 5 // Se valida��o do c�digo de banco, posiciona na subconta encontrada pois n�o existe retorna dele pelo F3
                cSubCc 		:= SEE->EE_SUBCTA
                MV_PAR08    := cSubCc
                MV_PAR09	:= IIf(SEE->EE_NRBYTES == 240,2,1)
            Endif

            lRet	:= .F.
        Endif
    Else
        If nParValid == 5  // Se valida��o do parametro 5-Arquivo de retorno, permite continuar mesmo nao coincidindo os dados pois ainda falta alterar banco/agencia/conta
            lRet 	:= .T.
        Else
            If nParValid == 6 // Se valida��o do c�digo de banco, posiciona na subconta encontrada pois n�o existe retorna dele pelo F3
                SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta) )
                cSubCc 		:= SEE->EE_SUBCTA
                MV_PAR09    := cSubCc
                nModCnab	:= IIf(SEE->EE_NRBYTES == 240,2,1)
                MV_PAR12	:= nModCnab
            Endif
            lRet	:= .F.
        Endif
    Endif

    dbSelectArea("SEE")
    DbSetOrder(1)
    If SEE->( dbSeek(xFilial("SEE")+cBanco+cAgenc+cConta+cSubCc) )

        // Verifica se os campos existem 
        If SEE->(FieldPos("EE_ZARQREM")) > 0 .And. SEE->(FieldPos("EE_ZARQRET")) > 0            
            // Caso seja rotina Geracao bordero ira comparar com arquivo de remessa(.rem) ou ent�o arquivo de retorno.
            If !Empty(cArqRet) .And. (Iif(cVldRot == "AFI150",Alltrim(Upper(SEE->EE_ZARQREM)),Alltrim(Upper(SEE->EE_ZARQRET)))) ==  Alltrim(Upper(cArqRet)) // Fa�o upper e trim do texto para evitar erros de caixa alta e espa�o
                RestArea(aAreaOld)
                Return .T.
            Else
                If lRet
                    MsgAlert("Voc� precisa mudar as configura��es de c�digo de Banco/Ag�ncia/Conta!","A T E N � � O!!")
                Else
                    MsgAlert("Arquivo de configura��o de retorno '"+cArqRet+"' inv�lido para este Banco/Ag�ncia/Conta informados!","A T E N � � O!!")
                    If cVldRot == "FIN650"
                        MV_PAR02	:= SEE->EE_ZARQRET
                    ElseIf cVldRot == "AFI150" // Rotina de gera��o de arquivo de envio cnab
                        MV_PAR03	:= SEE->EE_ZARQREM  // Arquivo de configuracao .rem
                    Else
                        MV_PAR05	:= SEE->EE_ZARQRET
                    Endif
                Endif
                RestArea(aAreaOld)
                Return lRet
            Endif
        Endif
    Else
        MsgAlert("N�o existe cadastro de configura��o de Banco para os param�tros informados!","A T E N � � O!!")
        RestArea(aAreaOld)
        Return lRet
    Endif

    RestArea(aAreaOld)
Return .F.
