#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

//Vari�veis Est�ticas
Static cTitulo := "Controle Descontos"
 
/*/{Protheus.doc} DECAZCC
Fun��o para cadastrar manualmente o Flex.
@author Jefferson de Souza
@since 19/07/2021
@version 1.0
    @return Nil, Fun��o n�o tem retorno
    @example
    u_DECAZCC()
    @obs N�o se pode executar fun��o MVC dentro do f�rmulas
/*/ // 25/08/2025
 
User Function DECAZCC()

Private oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZCC")
	oBrowse:SetDescription('Cadastro Flex')
	oBrowse:SetMenuDef("DECAZCC")

	oBrowse:AddLegend("ZCC_TIPO == '1' " ,"GREEN"	, "AUTOM�TICO"	)	//Inclus�o via ponto de entrada
	
	oBrowse:AddLegend(" ZCC_TIPO == '2' .or. Empty(ZCC_TIPO)","BLUE", "MANUAL"	)	
	
 //Opera��o Brinde ou Venda - Venda - 8 % e brinde 0
 //TIPO, Manual ou Atom�tico; 6910 5910 B

	oBrowse:Activate()

return Nil



/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Jefferson de Souza                                                |
 | Data:  19/07/2021                                                   |
 | Desc:  Cria��o do menu MVC                                          |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function MenuDef()

	Private aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'	 ACTION 'VIEWDEF.DECAZCC' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    	 ACTION 'VIEWDEF.DECAZCC' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'   	 ACTION 'VIEWDEF.DECAZCC' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'   	 ACTION 'VIEWDEF.DECAZCC' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'      ACTION 'VIEWDEF.DECAZCC' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'    	 ACTION 'VIEWDEF.DECAZCC' OPERATION 9 ACCESS 0
	ADD OPTION aRotina TITLE 'Sld Inicial'   ACTION   'U_GRVSALDO()'  OPERATION 2 ACCESS 0

Return aRotina

 
 
/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Jefferson de Souza                                           |
 | Data:  19/07/2021                                                   |
 | Desc:  Cria��o do modelo de dados MVC                               |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/                                                                                                                                           
Static Function ModelDef()
    Private oModel
	Private oStruZCC := FWFormStruct(1,"ZCC")

	oModel := MPFormModel():New("DECAZCCA")
	oModel:addFields('FORMZCC',,oStruZCC)
	oModel:SetPrimaryKey({'ZCC_FILIAL','ZCC_NUM'})
	oModel:SetDescription("Modelo de dados FLEX")
	

Return oModel

/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Jefferson de Souza                                                |
 | Data:  19/07/2021                                                   |
 | Desc:  Cria��o da vis�o MVC                                         |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/
 
Static Function ViewDef()

	Private oModel := ModelDef()//FwLoadModel()
	Private oView
	Private oStruZCC:= FWFormStruct(2, 'ZCC')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_ZCC',oStruZCC,'FORMZCC' )
	oView:CreateHorizontalBox( 'FLEX', 100)
	oView:SetOwnerView('VIEW_ZCC','FLEX')

Return oView
 
/*/{Protheus.doc} zLEGZCC
Fun��o para mostrar a legenda das rotinas MVC com grupo de produtos
@author Atilio
@since 19/07/2021
@version 1.0
    @example
    u_zLEGZCC()
/*/
 
User Function zLEGZCC()
    Private aLegenda := {}
     
    //Monta as cores
    AADD(aLegenda,{"BR_VERDE",        "Original"  })
    AADD(aLegenda,{"BR_VERMELHO",    "N�o Original"})
     
    BrwLegenda("STATUS FLEX", "Procedencia", aLegenda)

Return

/*/{Protheus.doc} DECAZCC
Fun��o para cadastrar o Flex, com preenchimento autom�tico de alguns campos.
@author Jefferson de Souza
@since 27/07/2021
@version 1.0
    @return Nil, Fun��o n�o tem retorno
    @example
    GRVSALDO()
    @obs N�o se pode executar fun��o MVC dentro do f�rmulas
/*/

User Function GRVSALDO()      

Private cCodVend
Private cLoja
Private cNmVen
Private cValor
Private oBtGrv
Private oGCodVen
Private cGCodVen    := SPACE(6)
Private oGNmVen
Private cGNmVen     := ''
Private cPict       :=  PesqPict("SC6","C6_PRCVEN")
Private oGVlrIni
Private nGVlrIni    := 0
Private oMsCalen1

Static oDlg

    DEFINE MSDIALOG oDlg TITLE "Saldo Inicial" FROM 000, 000  TO 234, 402 COLORS 0, 14078933 PIXEL
   
    @ 005, 009 SAY cCodVend PROMPT "C�d Vendedor:" SIZE 039, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 004, 050 MSGET oGCodVen VAR cGCodVen SIZE 029, 009 OF oDlg VALID(fGrvNome()) COLORS 0, 16777215 F3 "SA3" PIXEL
    @ 024, 009 SAY cNmVen PROMPT "Nome:" SIZE 017, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 025, 029 MSGET oGNmVen VAR cGNmVen SIZE 173, 010 OF oDlg  When .F. COLORS 0, 16777215 PIXEL
    
    @ 005, 099 SAY cValor PROMPT "Valor Inicial:" SIZE 031, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 004, 133 MSGET oGVlrIni VAR nGVlrIni Picture PesqPict('SC6','C6_PRCVEN')  SIZE 059, 010 OF oDlg COLORS 14884102, 16777215 PIXEL
    oMsCalen1 := MsCalend():New(042, 008, oDlg, .F.)
    oMsCalen1:dDiaAtu := DDATABASE//CtoD(dData)
    @ 097, 165 BUTTON oButton1 PROMPT "Gravar" SIZE 027, 014  ACTION Processa({||fProcessa()}) OF oDlg PIXEL 

  ACTIVATE MSDIALOG oDlg CENTERED

Return


Static Function fGrvNome()

DbSelectArea("SA3")
DbSetOrder(1)
if DbSeek(xFilial('SA3')+cGCodVen)
    cGNmVen := SA3->A3_NOME
else
    MsgInfo("Vendedor n�o cadastrado.")
endif

Return

Static Function fProcessa()

if Empty(cGCodVen)
    MsgInfo("O campo C�digo do Vendedor n�o foi preenchido")
    oGCodVen:SetFocus()
endif

if nGVlrIni = 0 
    MsgInfo("O campo Valor Inicial n�o foi preenchido.")
    oGVlrIni:SetFocus()
endif

If MsgYesNo("Deseja efetuar a grava��o do saldo Inicial ?")

    DbSelectArea("ZCC")
    Reclock("ZCC",.T.)
        ZCC_FILIAL := cFilAnt
        ZCC_NUM    := 'INICIA'
        ZCC_VEND   := cGCodVen
        ZCC_OPER   := 'I'
        ZCC_VALOR  := nGVlrIni
        ZCC_ISENTO := 'N'
        ZCC_TIPO   := '2'
        ZCC_DATA   := DDATABASE
        ZCC_USER   := CUSERNAME
        ZCC_MESREF := AnoMes(DDATABASE)
    ZCC->(MsUnlock())

else
     oGVlrIni:SetFocus()
     return   
Endif

MsgInfo("Grava��o conclu�da com sucesso")
oDlg:End()

Return
