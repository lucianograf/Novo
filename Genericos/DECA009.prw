#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDEF.ch'

/*/{Protheus.doc} function_method_class_name

Inclusão e Alteração do cadastro de CEP

@author CHARLES REITZ
@since 14/06/2019
@version version
parametersSection
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
user function DECA009()

	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("Z05")
	oBrowse:SetDescription('CEP´s')
	oBrowse:SetMenuDef("DECA009")
	oBrowse:Activate()

return
 
Static Function MenuDef()

	Private aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.DECA009' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.DECA009' OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.DECA009' OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.DECA009' OPERATION 5 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.DECA009' OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.DECA009' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()

	Local oModel
	Local oStruZ05 := FWFormStruct(1,"Z05")

	oModel := MPFormModel():New("DECA009M")
	oModel:addFields('FORMZ05',,oStruZ05)
	oModel:SetPrimaryKey({'Z05_FILIAL','Z05_CODIGO'})
	oModel:SetDescription("Modelo de Dados do Cadatro de Uvas")
	//oModel:getModel('FORMZ05'):SetDescription('Cadastro de CEP´s')

Return oModel

Static Function ViewDef()

	Local oModel := ModelDef()//FwLoadModel()
	Local oView
	Local oStrZ05:= FWFormStruct(2, 'Z05')

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_Z05',oStrZ05,'FORMZ05' )
	oView:CreateHorizontalBox( 'UVA', 100)
	oView:SetOwnerView('VIEW_Z05','UVA')

Return oView

/*/{Protheus.doc} A009Get

Preenche os dados do campod e cep

@author charles.totvs
@since 14/06/2019
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function A009Get(cAliFin)
	Local lRet 	:=	.F.
	Local cCep	:= ""
	Default cAliFin := "SA1"

	Begin Sequence

		If cAliFin == "SA1"
			cCep	:=	STRTRAN(M->A1_CEP, '-', '')
		Else
			cCep	:=	STRTRAN(M->A2_CEP, '-', '')
		EndIf

		dbSelectArea("Z05")
		dbSetOrder(1)
		if !MsSeek(cCep)
			//Help(NIL, NIL, "CEP", NIL, "Não localizado o CEP Informado", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe um CEP válido"})
			//Break
		EndIf

		dbSelectArea("CC2")
		dbSetOrder(1)
		if !MsSeek(FWXFilial("CC2")+Z05->Z05_ESTADO+Right(Z05->Z05_CODIBG,5))
			//Help(NIL, NIL, "CEP", NIL, "Não localizado código do IBGE na tabela do sistema", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Verifique no cadastro de CEP se a informação do código do municipio está correta"})
			//Break
		EndIf

		dbSelectArea("Z05")
		dbSetOrder(1)
		if !MsSeek(cCep)

			If cAliFin == "SA1"
				M->A1_EST		:= 'SC'
				M->A1_END		:= 'ENDERECO PADRAO'
				M->A1_MUN		:= 'CIDADE PADRAO'
				M->A1_BAIRRO	:= 'BAIRRO PADRAO'
				M->A1_COD_MUN	:= '02404
			Else
				M->A2_EST		:= 'SC'
				M->A2_END		:= 'ENDERECO PADRAO'
				M->A2_MUN		:= 'CIDADE PADRAO'
				M->A2_BAIRRO	:= 'BAIRRO PADRAO'
				M->A2_COD_MUN	:= '02404'
			EndIf

		ELSE

			If cAliFin == "SA1"
				M->A1_EST		:= Z05->Z05_ESTADO
				M->A1_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A1_END","X3_TAMANHO"))
				M->A1_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A1_MUN","X3_TAMANHO"))
				M->A1_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A1_BAIRRO","X3_TAMANHO"))
				M->A1_COD_MUN	:= CC2->CC2_CODMUN
			Else
				M->A2_EST		:= Z05->Z05_ESTADO
				M->A2_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A2_END","X3_TAMANHO"))
				M->A2_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A2_MUN","X3_TAMANHO"))
				M->A2_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A2_BAIRRO","X3_TAMANHO"))
				M->A2_COD_MUN	:= CC2->CC2_CODMUN
			EndIf

		EndIf

/*
		If cAliFin == "SA1"
			M->A1_EST		:= Z05->Z05_ESTADO
			M->A1_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A1_END","X3_TAMANHO"))
			M->A1_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A1_MUN","X3_TAMANHO"))
			M->A1_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A1_BAIRRO","X3_TAMANHO"))
			M->A1_COD_MUN	:= CC2->CC2_CODMUN
		Else
			M->A2_EST		:= Z05->Z05_ESTADO
			M->A2_END		:= Padr(Z05->Z05_ENDERE,GetSX3Cache("A2_END","X3_TAMANHO"))
			M->A2_MUN		:= Padr(Z05->Z05_CIDADE,GetSX3Cache("A2_MUN","X3_TAMANHO"))
			M->A2_BAIRRO	:= Padr(Z05->Z05_BAIRRO,GetSX3Cache("A2_BAIRRO","X3_TAMANHO"))
			M->A2_COD_MUN	:= CC2->CC2_CODMUN
		EndIf
*/


		lRet	:=	.T.
	End Sequence

Return lRet

/*/{Protheus.doc} Z05CDIBG

Valida campo código de IBGE

@author TSCB57 - William Farias
@since 17/07/2019
@version 1.0
/*/
User Function Z05CDIBG()

	Local aArea		:= GetArea()
	Local lRet		:= .F.
	Local oMdlZ05	:= fwModelActive()
	Local oZ05Mast	:= oMdlZ05:getModel("FORMZ05")
	Local nPosCodEst := 0
	Local cEstado	:= ""
	Local cCodEst	:= ""
	Local aCodEst	:= {{"AC"	,	"12"},;
		{"AL"	,	"27"},;
		{"AP"	,	"16"},;
		{"AM"	,	"13"},;
		{"BA"	,	"29"},;
		{"CE"	,	"23"},;
		{"DF"	,	"53"},;
		{"ES"	,	"32"},;
		{"GO"	,	"52"},;
		{"MA"	,	"21"},;
		{"MT"	,	"51"},;
		{"MS"	,	"50"},;
		{"MG"	,	"31"},;
		{"PA"	,	"15"},;
		{"PB"	,	"25"},;
		{"PR"	,	"41"},;
		{"PE"	,	"26"},;
		{"PI"	,	"22"},;
		{"RR"	,	"14"},;
		{"RO"	,	"11"},;
		{"RJ"	,	"33"},;
		{"RN"	,	"24"},;
		{"RS"	,	"43"},;
		{"SC"	,	"42"},;
		{"SP"	,	"35"},;
		{"SE"	,	"28"},;
		{"TO"	,	"17"} }
	Begin Sequence
		If Inclui .Or. Altera
			//Carrega e verifica o estado.
			cEstado	:= oZ05Mast:getValue("Z05_ESTADO")
			If Empty(cEstado)
				MsgAlert("Campo Estado não deve estar em branco, verifique!")
				Break
			EndIf
			nPosCodEst	:= Ascan( aCodEst,{ |X| UPPER( AllTrim(X[1]) ) == cEstado } )
			If nPosCodEst <> 0
				cCodEst := alltrim(aCodEst[nPosCodEst][2])
			Else
				MsgAlert("Não encontrado código do estado informado: "+cEstado)
				Break
			EndIf
			//Carrega os dados do código IBGE.
			cCodMunIbg := alltrim(oZ05Mast:getValue("Z05_CODIBG"))
			If Empty(cCodMunIbg)
				MsgAlert("Campo Cód. IBGE não deve estar em branco, verifique!")
				Break
			EndIf
			If Len(cCodMunIbg) <> 5
				MsgAlert("O Cód. IBGE informado deve possuir 5 dígitos, verifique!")
				Break
			EndIf
			oZ05Mast:loadValue("Z05_CODIBG", cCodEst+cCodMunIbg)
			lRet := .T.
		EndIf
	End Sequence

	RestArea(aArea)

Return lRet
