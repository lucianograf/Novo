#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

Static __oModelAut := NIL //variavel oModel para substituir msexecauto em MVC

/*/{Protheus.doc} XMA020BUT
(Adicionar bot�o ao enchoice do cadastro de Fornecedores)

@author Marcelo Lauschner
@since 11/12/2013
@version 1.0

@return Array, Bot�es na tela de cadastro de fornecedores

@example
(User Function MA020BUT()Local aButtons := {} // bot�es a adicionarAAdd(aButtons,{ 'NOTE'      ,{| |  U_MyProg1() }, 'Consulta Financ','Financ' } )AAdd(aButtons,{ 'PEDIDO'   ,{| |  U_MyProg2() }, 'Consulta Pedidos','Ped' } )Return (aButtons))

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6087595)
/*/

User Function MA020BUT()

	Local	aButtRet	:= {}
	Local 	nx := 0

	Aadd(aButtRet,{"AMARELO",{||sfReceita()},"Consulta Receita" })

Return aButtRet




/*/{Protheus.doc} sfReceita
//Fun��o que verifica via HTTPS os dados do cadastro do CNPJ 
@author Marcelo Alberto Lauschner
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function sfReceita()

	// Vari�vel Caractere
	Local	cUrlRec		:=	'https://www.receitaws.com.br/v1/cnpj/' + M->A2_CGC
	Local	cJsonRet	:=  HttpGet(cUrlRec)

	Local	cQry		
	Local	cVarAux
	Local	oModelA2 	:= FWModelActive()//->Carregando Model Ativo
	// Vari�vel L�gica
	Local	lRetCep		:= .T. 
	// Vari�vel Objeto
	Private oParseJSON 	:= Nil

	FWJsonDeserialize(cJsonRet, @oParseJSON)

	If Type("oParseJSON:situacao") <> "U"
		If oParseJSON:situacao <> "ATIVA" 
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"CNPJ com Situa��o Cadastral diferente de 'Ativa'."},;
			5,;
			{"Dados devem ser preenchidos manualmente se necess�rio fazer o cadastro."},;
			5) 
			Return 
		Endif
	Else
		/*	ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
		{"Erro na chamada no endere�o '" + cUrlRec + "'"},;
		5,;
		{"Informar o Departamento de Inform�tica!"},;
		5) 
		Return 
		*/	
	Endif

	If Type("oParseJSON:status") <> "U"
		If oParseJSON:status <> "OK" 
			ShowHelpDlg(ProcName(0)+"."+ Alltrim(Str(ProcLine(0))),;
			{"CNPJ com Status diferente de 'OK'."},;
			5,;
			{"Dados devem ser preenchidos manualmente se necess�rio fazer o cadastro."},;
			5) 
			Return 
		Endif

	Endif


	If Type("oParseJSON:nome") <> "U"
		M->A2_NOME	:= Padr(NoAcento(Upper(oParseJSON:nome)),TamSX3("A2_NOME")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_NOME',M->A2_NOME)
	Endif

	If Type("oParseJSON:fantasia") <> "U"
		M->A2_NREDUZ	:= Padr(NoAcento(Upper(oParseJSON:fantasia)),TamSX3("A2_NREDUZ")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_NREDUZ',M->A2_NREDUZ)
	Endif

	If Type("oParseJSON:email") <> "U"
		M->A2_EMAIL	:= Padr(oParseJSON:email,TamSX3("A2_EMAIL")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_EMAIL',M->A2_EMAIL)
	Endif

	If Type("oParseJSON:cep") <> "U"
		M->A2_CEP	:= Padr(StrTran(StrTran(oParseJSON:cep,".",""),"-",""),TamSX3("A2_CEP")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_CEP',M->A2_CEP)
		// Aciona gatilhos do campo CEP
		If ExistTrigger('A2_CEP')      
			RunTrigger(1,nil,nil,,'A2_CEP')
		Endif
	Endif


	If Type("oParseJSON:abertura") <> "U"
		M->A2_DTNASC	:= CTOD(oParseJSON:abertura)
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_DTNASC',M->A2_DTNASC)
	Endif

	If Type("oParseJSON:logradouro") <> "U" 
		M->A2_END	:= Padr(NoAcento(Upper(oParseJSON:logradouro)),TamSX3("A2_END")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_END',M->A2_END)
	Endif

	If Type("oParseJSON:numero") <> "U"	
		cVarAux		:= Alltrim(M->A2_END)
		M->A2_END	:= Padr(cVarAux + "," + NoAcento(Upper(oParseJSON:numero)),TamSX3("A2_END")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_END',M->A2_END)
	Endif

	If Type("oParseJSON:bairro") <> "U" 
		M->A2_BAIRRO	:= Padr(NoAcento(Upper(oParseJSON:bairro)),TamSX3("A2_BAIRRO")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_BAIRRO',M->A2_BAIRRO)
	Endif

	If Type("oParseJSON:complemento") <> "U" 
		M->A2_COMPLEM	:= Padr(NoAcento(Upper(oParseJSON:complemento)),TamSX3("A2_COMPLEM")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_COMPLEM',M->A2_COMPLEM)
	Endif

	If Type("oParseJSON:municipio") <> "U" 
		M->A2_MUN	:= Padr(NoAcento(Upper(oParseJSON:municipio)),TamSX3("A2_MUN")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_MUN',M->A2_MUN)
	Endif

	If Type("oParseJSON:uf") <> "U" 
		M->A2_EST	:= Padr(NoAcento(Upper(oParseJSON:uf)),TamSX3("A2_EST")[1])
		oModelA2:GetModel('SA2MASTER'):SetValue('A2_EST',M->A2_EST)

		cQry := "SELECT CC2_CODMUN "
		cQry += "  FROM " + RetSqlName("CC2")
		cQry += " WHERE D_E_L_E_T_ =' ' "
		cQry += "   AND CC2_EST = '"+oParseJSON:uf+"' "
		cQry += "   AND CC2_MUN LIKE '%"+ oParseJSON:municipio + "%' "
		cQry += "   AND CC2_FILIAL = '"+xFilial("CC2") + "' "

		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TBLEXIST",.T.,.T.)
		If TBLEXIST->(!Eof())
			M->A2_COD_MUN	:=  TBLEXIST->CC2_CODMUN
			oModelA2:GetModel('SA2MASTER'):SetValue('A2_COD_MUN',M->A2_COD_MUN)
		Endif		
		TBLEXIST->(DbCloseArea())
	Endif


Return 


/*/{Protheus.doc} sfAjust
//Ajusta o texto do JSON 
@author Marcelo Alberto Lauschneer
@since 11/05/2018
@version 1.0
@return ${return}, ${return_description}
@param cInChar, characters, descricao
@param lOutJson, logical, descricao
@type function
/*/
Static Function sfAjust(cInChar,lOutJson)

	Local	cOut		:= DecodeUTF8(cInChar, "iso8859-1")
	Local	aOut		:= {}
	Local	nO
	Default lOutJson	:= .F.
	Aadd(aOut,{"�","\u00e1","a"})
	Aadd(aOut,{"�","\u00e0","a"})
	Aadd(aOut,{"�","\u00e2","a"})
	Aadd(aOut,{"�","\u00e3","a"})
	Aadd(aOut,{"�","\u00e4","a"})
	Aadd(aOut,{"�","\u00c1","a"})
	Aadd(aOut,{"�","\u00c0","a"})
	Aadd(aOut,{"�","\u00c2","a"})
	Aadd(aOut,{"�","\u00c3","a"})
	Aadd(aOut,{"�","\u00c4","a"})
	Aadd(aOut,{"�","\u00e9","e"})
	Aadd(aOut,{"�","\u00e8","e"})
	Aadd(aOut,{"�","\u00ea","e"})
	Aadd(aOut,{"�","\u00ea","e"})
	Aadd(aOut,{"�","\u00c9","e"})
	Aadd(aOut,{"�","\u00c8","e"})
	Aadd(aOut,{"�","\u00ca","e"})
	Aadd(aOut,{"�","\u00cb","e"})
	Aadd(aOut,{"�","\u00ed","i"})
	Aadd(aOut,{"�","\u00ec","i"})
	Aadd(aOut,{"�","\u00ee","i"})
	Aadd(aOut,{"�","\u00ef","i"})
	Aadd(aOut,{"�","\u00cd","i"})
	Aadd(aOut,{"�","\u00cc","i"})
	Aadd(aOut,{"�","\u00ce","i"})
	Aadd(aOut,{"�","\u00cf","i"})
	Aadd(aOut,{"�","\u00f3","o"})
	Aadd(aOut,{"�","\u00f2","o"})
	Aadd(aOut,{"�","\u00f4","o"})
	Aadd(aOut,{"�","\u00f5","o"})
	Aadd(aOut,{"�","\u00f6","o"})
	Aadd(aOut,{"�","\u00d3","o"})
	Aadd(aOut,{"�","\u00d2","o"})
	Aadd(aOut,{"�","\u00d4","o"})
	Aadd(aOut,{"�","\u00d5","o"})
	Aadd(aOut,{"�","\u00d6","o"})
	Aadd(aOut,{"�","\u00fa","u"})
	Aadd(aOut,{"�","\u00f9","u"})
	Aadd(aOut,{"�","\u00fb","u"})
	Aadd(aOut,{"�","\u00fc","u"})
	Aadd(aOut,{"�","\u00da","u"})
	Aadd(aOut,{"�","\u00d9","u"})
	Aadd(aOut,{"�","\u00db","u"})
	Aadd(aOut,{"�","\u00e7","c"})
	Aadd(aOut,{"�","\u00c7","c"})
	Aadd(aOut,{"�","\u00f1","n"})
	Aadd(aOut,{"�","\u00d1","n"})
	Aadd(aOut,{"&","\u0026"," "})
	Aadd(aOut,{"'","\u0027"," "})
	Aadd(aOut,{"�","\u00b4"," "})
	Aadd(aOut,{Chr(13),"\u0013"," "})
	Aadd(aOut,{Chr(10),"\u0010"," "})
	//ConOut("+------------------------------------+")
	//ConOut(cOut)
	If lOutJson
		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,2])
		Next nO	

	Else
		cOut	:= DecodeUTF8(cOut)
		//ConOut(cOut)

		For nO := 1 To Len(aOut)
			cOut	:= StrTran(cOut,aOut[nO,1],aOut[nO,3])
		Next nO

		cOut	:= Alltrim(Upper(cOut))
	Endif
	//ConOut(cInChar)
	//ConOut(cOut)
	//ConOut("+++------------------------------------+")

Return cOut
