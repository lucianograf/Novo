#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MAAVCRPR
Este ponto de entrada pertence � rotina de avaliza��o de cr�dito de clientes, 
MaAvalCred() � FATXFUN(). Ele permite que, ap�s a avalia��o padr�o do sistema, 
o usu�rio possa fazer a sua pr�pria.

Par�metros. 
ParamIxb[1]=C�digo do cliente 
ParamIxb[2]=C�digo da filial 
ParamIxb[3]=Valor da venda
ParamIxb[4]=Moeda da venda 
ParamIxb[5]=Considera acumulados de Pedido de Venda do SA1
ParamIxb[6]=Tipo de cr�dito (�L� - C�digo cliente + Filial; �C� - c�digo do cliente) 
ParamIxb[7]=Indica se o credito ser� liberado ( L�gico ) 
ParamIxb[8]=Indica o c�digo de bloqueio do credito ( Caracter )
Eventos
@type function
@author Jefferson de Souza
@since 
@version 1.0
@param lEndereco,
    @example
    MAAVCRPR
/*/
 
 User Function MAAVCRPR()
 
 //Local aAreaOld	:= GetArea()
 Local lRet     := ParamIxb[7]
 L//ocal cCondPad := GetMV("MV_ZLBCRD") // Condi��o que ao ser usada, o cliente n�o passa pela an�lise de cr�dito.  

//If FunName() <> 'ACTVS05A10'
    //If  M->C5_FILIAL $ ("0101/0102/0103/0104/0105/0107/0201/0202")
//    if  M->C5_CONDPAG $ cCondPad
//        lRet := .T.
//    endif    
    //Endif
//Endif

//RestArea(aAreaOld)

Return lRet
