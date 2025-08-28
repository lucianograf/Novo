#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'FWMBrowse.ch'
#include 'FWMVCDef.ch'

User Function DECA099T()

	RpcSetType(3)
	RpcSetEnv("01")
	//	RPCSETENV("01","0101")

	U_DECA099()

	RpcClearEnv()

Return

/*/{Protheus.doc} DECA099

Função de chamada para os pedidos e clientes da integração com o Magento

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
User Function DECA099()
	Local cDescDet	:=	""
	Local lEnd		:= .F.
	Local cLockName	:=	ProcName()+Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL)
	Private lIsBlind	:=	isBlind()

	If !LockByName(cLockName,.T.,.F.)
		MsgStop("Rotina está sendo processada por outro usuário")
		U_GetUsrLock(cLockName)
		Return
	EndIf
	U_PutUsrLock(cLockName)

	oActLog	:=	ACTXLOG():New()
	oActLog:Start("DECA099"," Iniciando integração com Magento",)
	FWLogMsg("INFO","",'1',"DECA099",,"MAGENTO"," Iniciando integração com Magento")

	oActLog:Inf("DECA099",If(lIsBlind,"Executado VIA JOB","Executado manualmente com interface"))
	FWLogMsg("INFO","LAST",'1',"DECA099",,"MAGENTO",If(lIsBlind,"Executando via JOB","Executando em tela"))

	If lIsBlind
		U_DECA099P()
	Else
		cDescDet	:= "Rotina responsável por realizar o consumo de clientes e pedidos do Magento"
		oGrid		:=	FWGridProcess():New(   "DECA099",  "Buscar Clientes e Pedidos do Magento", cDescDet, {|lEnd| U_DECA099P(@lEnd)}, "")
		oGrid:SetMeters(2)
		//oGrid:SetThreadGrid(1)
		oGrid:SetAbort(.T.)
		oGrid:Activate()
	EndIf

	oActLog:Fin()
	FWLogMsg("INFO","LAST",'1',"DECA099",,"MAGENTO","Finalizada integração com Magento")

	UnLockByName(cLockName,.T.,.F.)
	U_DelUsrLock(cLockName)

Return

/*/{Protheus.doc} SchedDef

Função responsavel por disponibilizar a rotina via Schedule

@author charles.totvs
@since 27/05/2019
@version undefined

@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function SchedDef()
	// aReturn[1] - Tipo
	// aReturn[2] - Pergunte
	// aReturn[3] - Alias
	// aReturn[4] - Array de ordem
	// aReturn[5] - Titulo
Return { "P", "DECA099", "", {}, "" }

/*/{Protheus.doc} DECA099P

Função principal de pedidos e clientes da integração com o Magento

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
User Function DECA099P(lEnd)

	Local aAreaAnt := GETAREA()
	Local lRet			:= .F.
	Local aLstPed		:= {}
	Local aLstPedCCl	:= {}
	Local aLstPedSCl	:= {}
	Local aCliDad		:= {}
	Local nX			:= 0
	Local cPedId		:= ""
	Local cCliId		:= ""
	Local aDadCli		:= {}
	Local aDadEndCli	:= {}
	Local aPedDad		:= {}
	Local lCadPed		:= .F.
	Local lRetCliDad	:= .F.
	Local lRetPedDad	:= .F.
	Private cIdSession		:= ""
	Private cUrlWSDL  		:= GetMv("MA_URLWSDL"	,,"https://homolog.decanter.com.br/api/v2_soap/?wsdl")
	Private lHttpAuth		:= GetMv("MA_HTTPAUT"	,,.T.)
	Private cHttpUser		:= GetMv("MA_HTTPUSE"	,,"trezo")
	Private cHttpPass		:= GetMv("MA_HTTPPAS"	,,"apolo17")
	Private lVerboseOn		:= GetMv("MA_SAVEXML"	,,.T.)		//Salva request e response
	Private cCdTabPrc 		:= GETMV("MA_CODTABP"	,,"107")	//Tab Preço
	Private cCdNatu 		:= GETMV("MA_CODNAT"	,,"10109")	//Natureza
	Private cCondPag		:= GETMV("MA_CONDPAG"  	,,"pagueveloz_boleto=005;braspag_cc1=008;braspag_cc2=007;braspag_cc3=001") //Condição Pagto
	Private cVendEcm		:= GETMV("MA_VENDECM"  	,,"000138") //Vendedor
	Private cTranspEcm		:= "" //GETMV("MA_TRANECM"  	,,"")	//"378") //Transportadora
	Private cTpOper			:= GETMV("MV_ZTOPER"  	,,"02")		//Tipo operação fiscal
	Private nDiasFil		:= GETMV("MA_DIASBUS"  	,,1)		//Quantidade de dias atras que irá efetuar a busca
	Private cCliRisco		:= GETMV("MA_CRISCO"  	,,"E")		//Fator de risco do cliente
	Private aEstado := {{"ACRE"					,	"AC"},;
		{"ALAGOAS"				,	"AL"},;
		{"AMAPA"				,	"AP"},;
		{"AMAZONAS"				,	"AM"},;
		{"BAHIA"				,	"BA"},;
		{"CEARA"				,	"CE"},;
		{"DISTRITO FEDERAL"		,	"DF"},;
		{"ESPIRITO SANTO"		,	"ES"},;
		{"GOIAS"				,	"GO"},;
		{"MARANHAO"				,	"MA"},;
		{"MATO GROSSO"			,	"MT"},;
		{"MATO GROSSO DO SUL"	,	"MS"},;
		{"MINAS GERAIS"			,	"MG"},;
		{"PARA"					,	"PA"},;
		{"PARAIBA"				,	"PB"},;
		{"PARANA"				,	"PR"},;
		{"PERNAMBUCO"			,	"PE"},;
		{"PIAUI"				,	"PI"},;
		{"RORAIMA"				,	"RR"},;
		{"RONDONIA"				,	"RO"},;
		{"RIO DE JANEIRO"		,	"RJ"},;
		{"RIO GRANDE DO NORTE"	,	"RN"},;
		{"RIO GRANDE DO SUL"	,	"RS"},;
		{"SANTA CATARINA"		,	"SC"},;
		{"SAO PAULO"			,	"SP"},;
		{"SERGIPE"				,	"SE"},;
		{"TOCANTINS"			,	"TO"} }


	Begin Sequence
		//É aberta uma unica sessao para realizar o processamento no magento
		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Realizando autenticação com Magento")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		cIdSession := U_MAGEAuth()
		If EmptY(cIdSession)
			cMsgError	:=	 "Não foi possível realizar autenticação com o Magento""
			//FWLogMsg("ERROR","LAST",'1',"DECA099",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		If !lIsBlind
			oGrid:SetIncMeter(1,"Importando Pedidos e clientes")
			//oGrid:SetIncMeter(2,"")
			ProcessMessage()
		EndIf

		aLstPed := DECALSTPED(nDiasFil)

		If Len(aLstPed) == 0
			//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
			oActLog:Inf("DECA099","Nenhum pedido encontrado para incluir")
			lRet	:=	.F.
			Break
		EndIf

		//		If !lIsBlind
		//			oGrid:SetMaxMeter(nCount,2)
		//			ProcessMessage()
		//		EndIf

		//Pega os IDs de Pedidos e Clientes.
		nX := 0
		FOR nX := 1 TO Len(aLstPed)
			nPosPedId	:= Ascan( aLstPed[nX],{ |X| UPPER( AllTrim(X[1]) )=="_INCREMENT_ID" } )
			nPosCliId	:= Ascan( aLstPed[nX],{ |X| UPPER( AllTrim(X[1]) )=="_CUSTOMER_ID" } )

			If nPosCliId == 0
				aAdd( aLstPedSCl, { aLstPed[nX][nPosPedId][2]:TEXT, aLstPed[nX] }) //Pedidos sem id de cliente (Em produção isso não deverá ocorrer)
			Else
				aAdd( aLstPedCCl, { aLstPed[nX][nPosPedId][2]:TEXT, aLstPed[nX][nPosCliId][2]:TEXT, aLstPed[nX] })
			EndIf
		NEXT nX

		FWLogMsg("INFO","LAST",'1',"SALESORDERLIST",,"MAGENTO","Pedidos e Clientes adicionados no array!")

		If !lIsBlind
			oGrid:SetMaxMeter(Len(aLstPedCCl)*5,2)
		Endif

		//Chama função de listar clientes
		nX := 0
		For nX := 1 TO Len(aLstPedCCl)
			cPedId		:= aLstPedCCl[nX][1]//"100005634"//"100005735"//"100005726"//"100005725"//"100005634"//"100005722"//"100005218"//"100005715"//aLstPedCCl[nX][1]
			cCliId		:= aLstPedCCl[nX][2]//"4857"//"4857"//"4856"//"4848"//"4844"//aLstPedCCl[nX][2]

			// TSC679 - CHARLES REITZ - 30/01/2020 - Ajustado para zerar variaveis a cada passagem, estava incluindo pedido com o cliente errado
			aCliDad		:= {}
			aDadCli		:= {}
			aDadEndCli	:= {}
			aPedDad		:= {}

			//Busca dados do cliente
			If !lIsBlind
				//oGrid:SetIncMeter(1,"")
				oGrid:SetIncMeter(2,"Buscando dados do cliente")
				ProcessMessage()
			EndIf

			aDadCli		:= DECALSTCLI(cCliId)

			If Len(aDadCli) == 0
				//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
				oActLog:Inf("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Nenhum dado do cliente encontrado")
				lRetDadCli := .F.
				//Break
			Else
				lRetDadCli := .T.
			EndIf


			//Busca dados dos endereços do cliente
			If !lIsBlind
				//	oGrid:SetIncMeter(1,"")
				oGrid:SetIncMeter(2,"Buscando dados dos endereços do cliente")
				ProcessMessage()
			EndIf

			If lRetDadCli
				aDadEndCli	:= DECALSTEND(cCliId)
			EndIf

			If Len(aDadEndCli) == 0
				//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
				oActLog:Err("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Nenhum dado de endereço do cliente encontrado")
				lRetEndCli := .F.
				//Break
			Else
				lRetEndCli := .T.
			EndIf


			//Chama funcao que verifica e inclui/altera cliente
			If !lIsBlind
				//oGrid:SetIncMeter(1,"")
				oGrid:SetIncMeter(2,"Incluindo/Alterando o cliente")
				ProcessMessage()
			EndIf

			//Chama somente se dados de cliente e endereço foram coletados
			If lRetDadCli .And. lRetEndCli
				aCliDad := DECACADCLI(aDadCli, aDadEndCli)
			EndIf

			If Len(aCliDad) == 0
				//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
				oActLog:Err("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Não foi possível incluir/alterar o cliente.")
				lRetCliDad	:=	.F.
			ElseIf aCliDad[1]
				oActLog:Inf("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Cliente incluído/alterado com sucesso. Código: "+aCliDad[2]+" Loja: "+aCliDad[3])
				lRetCliDad	:=	.T.
			Else
				oActLog:Inf("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Cliente sem alterações, já estava incluído na base. Código: "+aCliDad[2]+" Loja: "+aCliDad[3])
				lRetCliDad	:=	.T.
			EndIf

			//Busca dados do pedido
			If !lIsBlind
				//oGrid:SetIncMeter(1,"")
				oGrid:SetIncMeter(2,"Buscando informações do pedido")
				ProcessMessage()
			EndIf

			//Busca informações do pedido somente se possuir informações do cliente
			If lRetCliDad
				aPedDad	:= DECADADPED(cPedId)
			EndIf

			If Len(aPedDad) == 0
				//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
				oActLog:Err("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Nenhuma informação do pedido encontrado")
				lRetPedDad	:=	.F.
				//Break
			Else
				//oActLog:Inf("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Coletado informações do pedido.")
				lRetPedDad	:=	.T.
			EndIf

			//Chama funcao que verifica e inclui pedido
			If !lIsBlind
				//oGrid:SetIncMeter(1,"")
				oGrid:SetIncMeter(2,"Incluindo o pedido")
				ProcessMessage()
			EndIf

			If lRetCliDad .And. lRetPedDad
				lCadPed := DECACADPED(cPedId,aPedDad,aCliDad)
			EndIf
			If !lCadPed
				//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
				oActLog:Err("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Não foi possível incluir/alterar o pedido")
				//lRetCadPed	:=	.F.
				//Break
			Else
				oActLog:Inf("DECA099","Pedido: "+cPedId+ " Cliente: "+cCliId+ " - Pedido incluído com sucesso.")
			EndIf

		Next nX

	End Sequence

	RESTAREA(aAreaAnt)

Return lRet

/*/{Protheus.doc} DECALSTPED

Função responsavel por buscar os dados dos pedidos no Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return Retorna um array com os dados dos pedidos.
/*/
Static Function DECALSTPED(nInDiasFiltro)

	Local aAreaAnt := GETAREA()
	Local oWsdl
	Local aOps 		:= {}, nX
	Local aSimple 	:= {}
	Local aComplex 	:= {}
	Local cXML 		:= ""
	Local nPos		:= 0
	Local aLstPed	:= {}
	//Variaveis para filtro de listar pedidos (salesOrderList)
	Local cTipFil		:= "C"							//Define tipo de filtro usado no webservice. C - Complex, S - Simples, N - Nenhum
	Local nFilOccSim	:= Iif(cTipFil == "S", 1, 0)	//Define se terá filtro simples ou não. 0 - Não ou 1 - Sim
	Local nFilOccCom	:= Iif(cTipFil == "C", 1, 0)	//Define se terá filtro complexo ou não. 0 - Não ou 1 - Sim
	Local cParentS		:= "filters#1.filter#1.associativeEntity#1"		//Define o nome do filtro que sera enviado no objeto do WS
	Local cParentCK1	:= "filters#1.complex_filter#1.complexFilter#1"	//Define o nome do filtro de key que sera enviado no objeto do WS
	Local cParentCV1	:= "filters#1.complex_filter#1.complexFilter#1.value#1" //Define o nome do filtro de value que sera enviado no objeto do WS
	//teste para tratar caracter no pedido 100003283
	//	Local cParentCK2	:= "filters#1.complex_filter#1.complexFilter#2"	//Define o nome do filtro de key que sera enviado no objeto do WS
	//	Local cParentCV2	:= "filters#1.complex_filter#1.complexFilter#2.value#1" //Define o nome do filtro de value que sera enviado no objeto do WS
	//	//fim teste
	Local cFilSiKey		:= "status"							//key filtro simples
	Local cFilSiVal		:= "pending"						//value filtro simples
	Local cFilC1Key1	:= "created_at"						//key1 filtro complexo
	Local cFilC1Key2	:= "gteq" //gt:maior eq:igual		//key2 filtro complexo
	Local cDataFil		:= Date()-nInDiasFiltro
	Local cFilData		:= Substr(Dtos(cDataFil),1,4)+"-"+Substr(Dtos(cDataFil),5,2)+"-"+Substr(Dtos(cDataFil),7,2)+" "+Time()
	Local cFilC1Val		:= cFilData //"2016-01-01 00:00:00"	//value filtro complexo
	//teste para tratar caracter no pedido 100003283
	//	Local cFilC2Key1	:= "created_at"					//key1 filtro complexo
	//	Local cFilC2Key2	:= "lteq" //lt:maior eq:igual	//key2 filtro complexo
	//	Local cFilC2Val		:= "2019-05-16 16:15:52"		//value filtro complexo
	//fim teste
	cMsgLog	:=	"Iniciando coleta de dados de pedidos e clientes"
	FWLogMsg("INFO","LAST",'1',"DECALSTPED","MAGENTO",cMsgLog)
	oActLog:Inf(cMsgLog)
	Begin Sequence

		oWsdl := TWsdlManager():New()
		oWsdl:lVerbose 		:= lVerboseOn
		oWsdl:lSSLInsecure 	:= .T.
		oWsdl:nTimeout 		:= 120
		//oWsdl:cEncoding := 'ISO-8859-1'
		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL(cUrlWSDL)
			cMsgError	:=	 "[ERRO parse] Falha ao realizar o parse do xml " + oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			//			MsgAlert(cMsgError,Procname())
			//		    Return
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		//aOps := oWsdl:ListOperations()

		// Seta a operação a ser utilizada
		If !oWsdl:SetOperation( "salesOrderList" )
			cMsgError := '[ERRO UPDATE] Falha ao utilizar webservice' + oWsdl:cError
			oActLog:Err(cMsgError)
			Break
			//	  		cMsgError := "Não foi possível setar a operação salesOrderList (SetOperation)"+chr(13)+chr(10)+oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			//			Return
		EndIf

		aComplex := oWsdl:NextComplex()

		While ValType( aComplex ) == "A"
			If aComplex[2] == "filter" .AND. aComplex[5] == "filters#1"
				nOccurs := nFilOccSim
			ElseIf aComplex[2] == "associativeEntity" .AND. aComplex[5] == "filters#1.filter#1"
				nOccurs := nFilOccSim
			ElseIf aComplex[2] == "complex_filter" .AND. aComplex[5] == "filters#1"
				nOccurs := nFilOccCom
			ElseIf aComplex[2] == "complexFilter" .AND. aComplex[5] == "filters#1.complex_filter#1"
				nOccurs := nFilOccCom
			Else
				nOccurs := 0
			Endif

			//Se for zero ocorrências e o mínimo de ocorrências do tipo for 1, então define como 1 para não dar erro na definição dos complexos
			If nOccurs == 0 .AND. aComplex[3] == 1
				nOccurs := 1
				cMsgError	:=	 "Elemento obrigatório não tratado, definido como 1 ocorrência: " + aComplex[5]
				FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				//MsgAlert(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Endif

			If !oWsdl:SetComplexOccurs( aComplex[1], nOccurs )
				cMsgError	:=	 "Falha ao definir elemento " + aComplex[2] + ", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrências."+chr(13)+chr(10)+oWsdl:cError
				FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			Endif

			aComplex := oWsdl:NextComplex()
		EndDo

		aSimple  := oWsdl:SimpleInput()

		// Define o valor do parâmeto session obrigatório
		if !oWsdl:SetValue( 0, cIdSession)
			cMsgError	:=	 "Não foi possível definir um token para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		//Somente adiciona quando tiver mais parametros obrigatorios (Ocorrencias <> 0 em NEXTCOMPLEX()).
		If !Len(aSimple) > 1
			cMsgError	:=	 "Não foi possível definir a quantidade de parâmetros"
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		Else
			If cTipFil == "S"
				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParentS } ) ) > 0
					If !oWsdl:SetValue( aSimple[nPos][1], cFilSiKey )
						cMsgError	:=	 "Não foi possível definir o paramêtro 1 do filtro: "+cFilSiKey+chr(13)+chr(10)+oWsdl:cError
						FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Endif
				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "value" .AND. aVet[5] == cParentS } ) ) > 0
					If !oWsdl:SetValue( aSimple[nPos][1], cFilSiVal )
						cMsgError	:=	 "Não foi possível definir o paramêtro 2 do filtro: "+cFilSiVal+chr(13)+chr(10)+oWsdl:cError
						FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Endif
			Else
				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParentCK1 } ) ) > 0
					If !oWsdl:SetValue( aSimple[nPos][1], cFilC1Key1 )
						cMsgError	:=	 "Não foi possível definir o paramêtro 3 do filtro: "+cFilC1Key1+chr(13)+chr(10)+oWsdl:cError
						FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Endif
				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParentCK1 } )+1 ) > 0
					If !oWsdl:SetValue( aSimple[nPos][1], cFilC1Key2 )
						cMsgError	:=	 "Não foi possível definir o paramêtro 4 do filtro: "+cFilC1Key2+chr(13)+chr(10)+oWsdl:cError
						FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Endif
				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "value" .AND. aVet[5] == cParentCV1 } ) ) > 0
					If !oWsdl:SetValue( aSimple[nPos][1], cFilC1Val )
						cMsgError	:=	 "Não foi possível definir o paramêtro 5 do filtro: "+cFilC1Val+chr(13)+chr(10)+oWsdl:cError
						FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Endif
				//teste para tratar caracter no pedido 100003283
				//				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParentCK2 } ) ) > 0
				//					oWsdl:SetValue( aSimple[nPos][1], cFilC2Key1 )
				//				Endif
				//				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParentCK2 } )+1 ) > 0
				//					oWsdl:SetValue( aSimple[nPos][1], cFilC2Key1 )
				//				Endif
				//				If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "value" .AND. aVet[5] == cParentCV2 } ) ) > 0
				//					oWsdl:SetValue( aSimple[nPos][1], cFilC2Val )
				//				Endif
				//fim teste
			EndIf
		EndIf

		cXML := oWsdl:GetSoapMsg()
		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",cXML)

		// Envia a mensagem SOAP ao servidor
		if !oWsdl:SendSoapMsg()
			cMsgError	:=	"Não foram encontrados pedidos pendentes no Magento no(s) último(s) "+cValToChar(nDiasFil)+" dia(s)."+chr(13)+chr(10)+;
				"Abortando envio dos dados para o servidor do Magento."+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgAlert(cMsgError,"Info - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		cError		:= ""
		cWarning	:= ""
		cGetRSub	:=	StrTran( oWsdl:GetSoapResponse(), "ï¿½", "")//Remove caracter especial
		If ValType(cGetRSub) == "U"
			cMsgError := "Falha no retorno do XML, não foi possível remover caracteres"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cGetResp	:=	DecodeUTF8(cGetRSub, "cp1252")
		If ValType(cGetResp) == "U"
			cMsgError := "Falha ao fazer o decode de UTF8 no XML"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oXml := XmlParser( /*oWsdl:GetSoapResponse()*/ cGetResp , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oLstPed	:=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_SALESORDERLISTRESPONSE:_RESULT:_ITEM//:_ITEM[1]:_CUSTOMERID:TEXT
		If ValType(oLstPed) == "O"
			aLstPed := {ClassDataAr(oLstPed,.T.)}
		ElseIf ValType(oLstPed) == "A"
			nX := 0
			FOR nX := 1 TO Len(oLstPed)
				aAdd(aLstPed, ClassDataAr(oLstPed[nX],.T.))
			Next nX
		Else
			cMsgError	:=	 "Não foi possível buscar a lista de pedidos no Magento"
			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cMsgLog	:=	"Lista de pedidos adicionada ao array (aLstPed) com sucesso"
		FWLogMsg("INFO","LAST",'1',"DECALSTPED","MAGENTO",cMsgLog)
		oActLog:Inf(cMsgLog)
	End Sequence


	oXML := NIL
	FreeObj(oWsdl)
	FreeObj(oXML)

	RESTAREA(aAreaAnt)

return aLstPed


/*/{Protheus.doc} DECALSTCLI

Função responsavel por buscar os dados dos clientes no Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
Static Function DECALSTCLI(cCliId)

	Local aAreaAnt := GETAREA()
	Local oWsdl
	Local aOps 		:= {}
	Local aSimple 	:= {}
	Local aComplex 	:= {}, nX
	Local cXML 		:= ""
	Local nPos		:= 0
	Local aDadCli	:= {}
	//Variaveis para filtro de listar dados do cliente (customerCustomerList)
	Local nFilOcc	:= 1										//Define se terá filtro ou não. 0 - Não ou 1 - Sim
	Local cParent 	:= "filters#1.filter#1.associativeEntity#1" //Define o nome do filtro que sera enviado no objeto
	Local cFilKey	:= "customer_id"							//key
	Local cFilVal	:= cCliId									//value

	cMsgLog	:=	"Iniciando coleta de dados de cliente"
	FWLogMsg("INFO","LAST",'1',"DECALSTPED","MAGENTO",cMsgLog)
	oActLog:Inf(cMsgLog)

	Begin Sequence

		oWsdl := TWsdlManager():New()
		oWsdl:lVerbose := lVerboseOn
		oWsdl:lSSLInsecure := .T.
		oWsdl:nTimeout 		:= 120
		//oWsdl:cEncoding := 'ISO-8859-1'
		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL(cUrlWSDL)
			cMsgError	:=	 "[ERRO parse] Falha ao realizar o parse do xml " + oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			//			MsgAlert(cMsgError,Procname())
			//		    Return
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		//aOps := oWsdl:ListOperations()

		// Seta a operação a ser utilizada
		IF !oWsdl:SetOperation( "customerCustomerList" )
			cMsgError := '[ERRO UPDATE] Falha ao utilizar webservice' + oWsdl:cError
			oActLog:Err(cMsgError)
			Break
			//	  		cMsgError := "Não foi possível setar a operação customerCustomerList (SetOperation)"+chr(13)+chr(10)+oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			//			Return
		ENDIF

		aComplex := oWsdl:NextComplex()

		While ValType( aComplex ) == "A"
			If aComplex[2] == "filter" .AND. aComplex[5] == "filters#1"
				nOccurs := nFilOcc
			ElseIf aComplex[2] == "associativeEntity" .AND. aComplex[5] == "filters#1.filter#1"
				nOccurs := 1
			Else
				nOccurs := 0
			Endif

			//Se for zero ocorrências e o mínimo de ocorrências do tipo for 1, então define como 1 para não dar erro na definição dos complexos
			If nOccurs == 0 .AND. aComplex[3] == 1
				nOccurs := 1
				cMsgError	:=	 "Elemento obrigatório não tratado, definido como 1 ocorrência: " + aComplex[5]
				FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				//MsgAlert(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Endif

			If !oWsdl:SetComplexOccurs( aComplex[1], nOccurs )
				cMsgError	:=	 "Falha ao definir elemento " + aComplex[2] + ", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrências."+chr(13)+chr(10)+oWsdl:cError
				FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			Endif

			aComplex := oWsdl:NextComplex()
		EndDo

		aSimple  := oWsdl:SimpleInput()

		// Define o valor de cada parâmeto necessário
		if !oWsdl:SetValue( 0, cIdSession)	//SessionID
			cMsgError	:=	 "Não foi possível definir um token para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		//Somente adiciona quando tiver mais parametros obrigatorios (Ocorrencias 1 em NEXTCOMPLEX()).
		If !Len(aSimple) > 1
			cMsgError	:=	 "Não foi possível definir a quantidade de parâmetros"
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		Else
			If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "key" .AND. aVet[5] == cParent } ) ) > 0
				If !oWsdl:SetValue( aSimple[nPos][1], cFilKey )
					cMsgError	:=	 "Não foi possível definir o paramêtro 1 do filtro: "+cFilKey+chr(13)+chr(10)+oWsdl:cError
					FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break
				EndIf
			Endif

			If ( nPos := aScan( aSimple, {|aVet| aVet[2] == "value" .AND. aVet[5] == cParent } ) ) > 0
				If !oWsdl:SetValue( aSimple[nPos][1], cFilVal )
					cMsgError	:=	 "Não foi possível definir o paramêtro 1 do filtro: "+cFilVal+chr(13)+chr(10)+oWsdl:cError
					FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break
				EndIf
			Endif
		EndIf

		cXML := oWsdl:GetSoapMsg()
		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",cXML)

		// Envia a mensagem SOAP ao servidor
		if !oWsdl:SendSoapMsg()
			cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		cError		:= ""
		cWarning	:= ""
		cGetRSub	:=	StrTran( oWsdl:GetSoapResponse(), "ï¿½", "")//Remove caracter especial
		If ValType(cGetRSub) == "U"
			cMsgError := "Falha no retorno do XML, não foi possível remover caracteres"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cGetResp	:=	DecodeUTF8(cGetRSub, "cp1252")
		If ValType(cGetResp) == "U"
			cMsgError := "Falha ao fazer o decode de UTF8 no XML"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oXml := XmlParser( /*oWsdl:GetSoapResponse()*/ cGetResp , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oDadCli	:=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CUSTOMERCUSTOMERLISTRESPONSE:_STOREVIEW:_ITEM//:_ITEM[1]:_CUSTOMERID:TEXT
		If ValType(oDadCli) == "O"
			aDadCli := ClassDataAr(oDadCli,.T.)
		ElseIf ValType(oDadCli) == "A"
			nX := 0
			FOR nX := 1 TO Len(oDadCli)
				aAdd(aDadCli, oDadCli[nX])
			Next nX
		Else
			cMsgError	:=	 "Não foi possível buscar os dados do cliente no Magento"
			FWLogMsg("ERROR","LAST",'1',"DECALSTCLI",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//cMsgLog	:=	"Dados do cliente adicionados ao array (aDadCli) com sucesso"
		//FWLogMsg("INFO","LAST",'1',"DECALSTCLI","MAGENTO",cMsgLog)
		//oActLog:Inf(cMsgLog)
	End Sequence

	oXML := NIL
	FreeObj(oWsdl)
	FreeObj(oXML)

	RESTAREA(aAreaAnt)

Return aDadCli


/*/{Protheus.doc} DECALSTEND

Função responsavel por buscar os dados de endereços dos clientes no Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
Static Function DECALSTEND(cCliId)

	Local aAreaAnt := GETAREA()
	Local oWsdl, nX
	Local aOps 		:= {}
	Local aSimple 	:= {}
	Local aComplex 	:= {}
	Local cXML 		:= ""
	Local nPos		:= 0
	Local aDadEndCli := {}
	//Variaveis para filtro de listar dados do cliente (customerCustomerList)
	//	Local nFilOcc	:= 1										//Define se terá filtro ou não. 0 - Não ou 1 - Sim
	//	Local cParent 	:= "filters#1.filter#1.associativeEntity#1" //Define o nome do filtro que sera enviado no objeto
	//	Local cFilKey	:= "customer_id"							//key
	//	Local cFilVal	:= cCliId									//value

	FWLogMsg("INFO","",'1',"DECALSTEND",,"MAGENTO","Iniciando coleta de dados de cliente: " + cCliId)

	Begin Sequence

		oWsdl := TWsdlManager():New()
		oWsdl:lVerbose := lVerboseOn
		oWsdl:lSSLInsecure := .T.
		oWsdl:nTimeout 		:= 120
		//oWsdl:cEncoding := 'ISO-8859-1'
		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL(cUrlWSDL)
			cMsgError	:=	 "[ERRO parse] Falha ao realizar o parse do xml " + oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			//			MsgAlert(cMsgError,Procname())
			//		    Return
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		//aOps := oWsdl:ListOperations()

		// Seta a operação a ser utilizada
		IF !oWsdl:SetOperation( "customerAddressList" )
			cMsgError := '[ERRO UPDATE] Falha ao utilizar webservice' + oWsdl:cError
			oActLog:Err(cMsgError)
			Break
			//	  		cMsgError := "Não foi possível setar a operação customerAddressList (SetOperation)"+chr(13)+chr(10)+oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			//			Return
		ENDIF

		aSimple  := oWsdl:SimpleInput()

		// Define o valor de cada parâmeto necessário
		if !oWsdl:SetValue( 0, cIdSession) //SessionID
			cMsgError	:=	 "Não foi possível definir um token para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		if !oWsdl:SetValue( 1, cCliId)		//CustomerID
			cMsgError	:=	 "Não foi possível definir o ID do cliente: "+cCliId+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		cXML := oWsdl:GetSoapMsg()
		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",cXML)

		// Envia a mensagem SOAP ao servidor
		if !oWsdl:SendSoapMsg()
			cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		cError		:= ""
		cWarning	:= ""
		cGetRSub	:=	StrTran( oWsdl:GetSoapResponse(), "ï¿½", "")//Remove caracter especial
		If ValType(cGetRSub) == "U"
			cMsgError := "Falha no retorno do XML, não foi possível remover caracteres"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cGetResp	:=	DecodeUTF8(cGetRSub, "cp1252")
		If ValType(cGetResp) == "U"
			cMsgError := "Falha ao fazer o decode de UTF8 no XML"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oXml := XmlParser( /*oWsdl:GetSoapResponse()*/ cGetResp , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oDadEndCli	:=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CUSTOMERADDRESSLISTRESPONSE:_RESULT:_ITEM//:_ITEM[1]:_CUSTOMERID:TEXT
		If ValType(oDadEndCli) == "O"
			aDadEndCli := {ClassDataAr(oDadEndCli,.T.)}
		ElseIf ValType(oDadEndCli) == "A"
			nX := 0
			FOR nX := 1 TO Len(oDadEndCli)
				aAdd(aDadEndCli, oDadEndCli[nX])
			Next nX
		Else
			cMsgError	:=	 "Não foi possível buscar a lista de endereços do cliente no Magento"
			FWLogMsg("ERROR","LAST",'1',"DECALSTEND",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//cMsgLog	:=	"Dados dos endereços do cliente adicionados ao array (aDadEndCli) com sucesso"
		//FWLogMsg("INFO","LAST",'1',"DECALSTPED","MAGENTO",cMsgLog)
		//oActLog:Inf(cMsgLog)
	End Sequence

	oXML := NIL
	FreeObj(oWsdl)
	FreeObj(oXML)

	RESTAREA(aAreaAnt)

Return aDadEndCli

/*/{Protheus.doc} DECACADCLI

Função responsavel alimentar o Protheus com os dados dos clientes no Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
Static Function DECACADCLI(aDadCli,aDadEndCli)

	Local aAreaAnt	:= GETAREA()
	//Local lRet		:= .F.
	Local aCliRet	:= {}, nX
	Local _cObs		:= ""
	Local cAliasSA1	:= GetNextAlias()
	Local aRotAuto 	:= {}
	Local cECodEst := ''
	//Private lMsHelpAuto 	:= .T. // se .t. direciona as mensagens de help
	//Private lAutoErrNoFile 	:= .T. //Utilizado em conjunto com a funcaoGetAutoGRLog .A variável __aErrAuto só é alimentada se a variável lAutoErrNoFile estiver declarada como .T.
	Private lMsErroAuto 	:= .F. //necessario a criacao, pois sera atualizado quando houver
	Private aAutoErro		:= {}

	Begin Sequence

		//Pega a posição dos dados dos Clientes.
		nPosCId		:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_CUSTOMER_ID" } )	//Cod Magento (ID)
		nPosCEmail	:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_EMAIL" } )		//Email
		nPosCFName	:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_FIRSTNAME" } )	//Nome
		nPosCLName	:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_LASTNAME" } )		//Sobrenome
		nPosCCgc	:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_TAXVAT" } )		//CNPJ/CPF (CGC)
		//nPosCDtNas	:= Ascan( aDadCli,{ |X| UPPER( AllTrim(X[1]) )=="_DOB" } )			//Data Nascimento

		//Pega a posição dos dados do endereço do Cliente.
		nX := 0
		FOR nX := 1 TO Len(aDadEndCli)
			aDadEndClX := {}
			If ValType(aDadEndCli[nX]) == "O"
				aDadEndClX := ClassDataAr(aDadEndCli[nX],.T.)
			Else
				aDadEndClX := aDadEndCli[nX]
			EndIf

			nPosEPri	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_IS_DEFAULT_BILLING" } )	//End Principal (Cobrança)
			nPosEEnt	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_IS_DEFAULT_SHIPPING" } )	//End Cobrança

			If aDadEndClX[nPosEPri][2]:TEXT == "true"
				nPosEId		:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_CUSTOMER_ADDRESS_ID" } )//Cod Magento (ID)
				nPosECid	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_CITY" } )				//Cidade
				nPosEPai	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_COUNTRY_ID" } )		//País
				nPosECep	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_POSTCODE" } )			//CEP
				nPosEEst	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_REGION" } )			//Estado
				nPosEEnd	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_STREET" } )			//Endereco
				nPosETel	:= Ascan( aDadEndClX,{ |X| UPPER( AllTrim(X[1]) )=="_TELEPHONE" } )			//Telefone

				//Salva dados nas variaveis
				//ID Cliente (Cod Magento)
				If nPosCId <> 0
					cCId := aDadCli[nPosCId][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o ID do cliente. Posição: "+cValToChar(nPosCId)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Email Cliente
				If nPosCEmail <> 0
					cCEmail := aDadCli[nPosCEmail][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o email do cliente. Posição: "+cValToChar(nPosCEmail)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Nome Cliente
				If nPosCFName <> 0
					cCFName := aDadCli[nPosCFName][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o nome do cliente. Posição: "+cValToChar(nPosCFName)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Sobrenome Cliente
				If nPosCLName <> 0
					cCLName := aDadCli[nPosCLName][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o sobrenome do cliente. Posição: "+cValToChar(nPosCLName)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//CGC Cliente
				If nPosCCgc <> 0
					cCCgc := StrTran(aDadCli[nPosCCgc][2]:TEXT,'.')
					cCCgc := StrTran(cCCgc,'-')
					cCCgc := StrTran(cCCgc,'/')
				Else
					cMsgError	:=	 "Falha ao buscar o CGC do cliente. Posição: "+cValToChar(nPosCCgc)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Data Nascimento Cliente
//				If nPosCDtNas <> 0
//					cCDtNasc := aDadCli[nPosCDtNas][2]:TEXT
//					dCDtNasc := STOD(Substr(cCDtNasc,1,4)+Substr(cCDtNasc,6,2)+Substr(cCDtNasc,9,2))
//				Else
//					cMsgError	:=	 "Falha ao buscar a data de nascimento do cliente. Posição: "+cValToChar(nPosCDtNas)
//					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
//					MsgAlert(cMsgError,Procname())
//					Break
//				EndIf
				//ID Endereço Cliente (Cod Magento)
				If nPosEId <> 0
					cEId := aDadEndClX[nPosEId][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o ID do endereço do cliente. Posição: "+cValToChar(nPosEId)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Cidade Endereço Cliente
				//				If nPosECid <> 0
				//					cECid := aDadEndClX[nPosECid][2]:TEXT
				//				Else
				//					cMsgError	:=	 "Falha ao buscar a cidade do endereço do cliente. Posição: "+cValToChar(nPosECid)
				//					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
				//					MsgAlert(cMsgError,Procname())
				//					Break
				//				EndIf
				//País Endereço Cliente
				If nPosEPai <> 0
					cEPai := aDadEndClX[nPosEPai][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar o país do endereço do cliente. Posição: "+cValToChar(nPosEPai)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//CEP Endereço Cliente
				If nPosECep <> 0
					cECep := aDadEndClX[nPosECep][2]:TEXT
					cECep := StrTran(cECep,"-")

					dbSelectArea("Z05")
					dbSetOrder(1)
					If dbSeek(cECep)
						cECid := NoAcento(Z05->Z05_CIDADE)
						cECodEst := NoAcento(Z05->Z05_ESTADO)
						cEBairro := NoAcento(Z05->Z05_BAIRRO)
						//cECodCid := Z05->Z05_CODMUN
					EndIf
				Else
					cMsgError	:=	 "Falha ao buscar o CEP do endereço do cliente. Posição: "+cValToChar(nPosECep)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf

				//Estado Endereço Cliente
				//				If nPosEEst <> 0
				//					cEEstX := UPPER(NoAcento(aDadEndClX[nPosEEst][2]:TEXT))
				//					nPosAEst	:= Ascan( aEstado,{ |X| UPPER( AllTrim(X[1]) )==cEEstX } )			//Estado
				//					If nPosAEst <> 0
				//						cEEst := aEstado[nPosAEst][2]
				//					Else
				//						cMsgError	:=	 "Falha ao buscar o estado do endereço do cliente no array de estados. Estado Magento: "+cEEstX
				//						FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
				//						MsgAlert(cMsgError,Procname())
				//						Break
				//					EndIf
				//				Else
				//					cMsgError	:=	 "Falha ao buscar o estado do endereço do cliente. Posição: "+cValToChar(nPosEEst)
				//					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
				//					MsgAlert(cMsgError,Procname())
				//					Break
				//				EndIf
				//Endereço Cliente
				If nPosEEnd <> 0
					cEEndSTrat	:= StrTran(aDadEndClX[nPosEEnd][2]:TEXT,chr(10),", ")
					nPosEndBai 	:= RAT(",",cEEndSTrat)
					cEEnd 		:= SubStr(cEEndSTrat,1,nPosEndBai-1)
					//cEBairro 	:= NoAcento(SubStr(cEEndSTrat,nPosEndBai+2))
				Else
					cMsgError	:=	 "Falha ao buscar o logradouro do endereço do cliente. Posição: "+cValToChar(nPosEEnd)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Telefone Endereço Cliente
				If nPosETel <> 0
					cETel := aDadEndClX[nPosETel][2]:TEXT
					cETel := StrTran(cETel,"(")
					cETel := StrTran(cETel,")")
					cETel := StrTran(cETel,"-"," ")
				Else
					cMsgError	:=	 "Falha ao buscar o telefone do endereço do cliente. Posição: "+cValToChar(nPosETel)
					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
				//Tipo pessoa
				If Len(cCCgc) == 11
					cCTipPes := "F"
				Else
					cCTipPes := "J"
				EndIf

				//				//Busca Cidade e Estado
				//				dbSelectArea("CC2")
				//				dbSetOrder(4)
				//				If dbSeek(FWxFilial("CC2")+PadR(cECodEst,TamSx3("CC2_EST")[1])+PadR(UPPER(NoAcento(cECid)),TamSx3("CC2_MUN")[1]))
				//					cECodCid := CC2->CC2_CODMUN
				//					//cENomCid := CC2->CC2_MUN
				//					//cECodEst := CC2->CC2_EST
				//				Else
				//					cMsgError	:=	 "Falha ao buscar a cidade no cadastro da CC2. Cidade no Magento: "+UPPER(NoAcento(cECid)) + " - Estado no Magento: "+UPPER(NoAcento(cEEst))
				//					FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
				//					MsgAlert(cMsgError,Procname())
				//					Break
				//				EndIf
				//				dbCloseArea()

				//Busca os registros na base pelo CGC
				BeginSql alias cAliasSA1
					SELECT A1_COD,A1_LOJA,A1_NOME,A1_ZBOLETO,A1_CONTRIB,A1_IENCONT,A1_RISCO,A1_TRANSP,A1_TEL,A1_CEP,A1_END,A1_EMAIL 
				  	  FROM %table:SA1% SA1
					 WHERE SA1.D_E_L_E_T_ <> '*'
					   AND SA1.A1_FILIAL = %exp:FWxFilial("SA1")%
					   AND SA1.A1_CGC 	  = %exp:cCCgc%
					   AND ( (A1_TIPO = 'F' AND A1_LOJA = '9999') OR A1_TIPO = 'J')
					 ORDER BY A1_LOJA 
				EndSql
				// A ordenação pelo campo A1_LOJA se faz 

				If (cAliasSA1)->(Eof()) //Inclusão
					aadd(aRotAuto,{"A1_PESSOA"		,upper(cCTipPes),NIL})
					aadd(aRotAuto,{"A1_NOME"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
					aadd(aRotAuto,{"A1_NREDUZ"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
					aadd(aRotAuto,{"A1_CEP"			,cECep			,NIL})
					aadd(aRotAuto,{"A1_END"			,upper(cEEnd)	,NIL})
					aadd(aRotAuto,{"A1_TIPO"		,upper("F")		,NIL})		//OBRIGATORIO					//TODO: Verificar
					//aadd(aRotAuto,{"A1_BAIRRO"	,upper(cEBairro),NIL})
					//aadd(aRotAuto,{"A1_EST"		,upper(cECodEst),NIL})
					//aadd(aRotAuto,{"A1_COD_MUN"	,alltrim(cECodCid),NIL})
					If cECodEst $ "SP,MG,RJ,ES"
						//aadd(aRotAuto,{"A1_REGIAO","008",Nil})
						aadd(aRotAuto,{"A1_DSCREG"	,"SUDESTE"		,Nil})
					ElseIf cECodEst $ "PR,SC,RS"
						//aadd(aRotAuto,{"A1_REGIAO","002"			,Nil})
						aadd(aRotAuto,{"A1_DSCREG"	,"SUL"			,Nil})
					ElseIf cECodEst $ "AL,BA,CE,PI,SE,PE,PB,RN,MA"
						//aadd(aRotAuto,{"A1_REGIAO","007"			,Nil})
						aadd(aRotAuto,{"A1_DSCREG"	,"NORDESTE"		,Nil})
					ElseIf cECodEst $ "AC,AM,RR,RO,AP,PA,TO"
						//aadd(aRotAuto,{"A1_REGIAO","001"			,Nil})
						aadd(aRotAuto,{"A1_DSCREG"	,"NORTE"		,Nil})
					ElseIf cECodEst $ "GO,DF,MT,MS"
						//aadd(aRotAuto,{"A1_REGIAO","006"			,Nil})
						aadd(aRotAuto,{"A1_DSCREG"	,"CENTRO OESTE"	,Nil})
					EndIf
					//aadd(aRotAuto,{"A1_LC"		,1				,NIL})//LIMITE DE CREDITO			//TODO: Verificar
					//aadd(aRotAuto,{"A1_VENCLC"	,CTOD("01/01/1999"),NIL})//VENC LIMITE DE CREDITO	//TODO: Verificar
					//aadd(aRotAuto,{"A1_TABELA"	,"001"			,NIL} )//TABELA DE PRECO			//TODO: Verificar
					aadd(aRotAuto,{"A1_CGC"			,cCCgc			,NIL})
					//aadd(aRotAuto,{"A1_INSCR"		,upper("ISENTO"),NIL})						//TODO: Verificar
					aadd(aRotAuto,{"A1_TEL"			,cETel			,NIL})

					aadd(aRotAuto,{"A1_EMAIL"		,cCEmail		,NIL})
					aadd(aRotAuto,{"A1_VEND"		,cVendEcm		,NIL})					
					//aadd(aRotAuto,{"A1_NATUREZ"	,"01.1"			,NIL}) //TODO: VERIFICA QUAL VAI SER REGRA
					//aadd(aRotAuto,{"A1_DTNASC"		,dCDtNasc		,NIL})
					aadd(aRotAuto,{"A1_PAIS"		,"105"			,NIL})
					aadd(aRotAuto,{"A1_CODPAIS"		,"01058"		,NIL})
					aadd(aRotAuto,{"A1_SIMPLES"		,"2"			,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_SIMPNAC"		,"2"			,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_TRANSP"		,cTranspEcm		,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_TPFRET"		,'C'			,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_RISCO"		,cCliRisco		,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_IENCONT"		,"2"			,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_CONTRIB"		,"2"			,NIL})//OBRIGATÓRIO
					aadd(aRotAuto,{"A1_ZBOLETO"		,"N"			,NIL})//OBRIGATÓRIO

					MSExecAuto({|x,y| Mata030(x,y)},aRotAuto,3) //3- Inclusão, 4- Alteração, 5- Exclusão

					If lMsErroAuto
						_cObs := MostraErro() //TODO: Verificar melhor maneira de tratar o erro.V
						cMsgError	:=	 "Falha ao INCLUIR cliente pela rotina Mata030. [ERRO]: "+_cObs
						FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
						MsgAlert(cMsgError,Procname())
						Break
					Else
						//						SA1->(RecLock("SA1",.F.))
						//						SA1->A1_MSBLQL	:=	"1"
						//						SA1->(msUnlock())
						//lRet := .T.
						aCliRet := {.T.,SA1->A1_COD, SA1->A1_LOJA} //Inclusao = .T., Cod Cli, Loja Cli
					EndIf

				Else
					//Alteração
					//Primeiro verifica se precisa alterar
					lChgCli := .F.
					While !Eof()
						If PadR(UPPER(rtrim(cCFName)+" "+ltrim(cCLName)),TamSx3("A1_NOME")[1]) <> UPPER((cAliasSA1)->A1_NOME)
							lChgCli := .T.
						EndIf
						//Verifica Email
						If PadR(UPPER(cCEmail),TamSx3("A1_EMAIL")[1]) <> UPPER((cAliasSA1)->A1_EMAIL)
							lChgCli := .T.
						EndIf
						//Verifica Cidade e Estado pelo Código IBGE
						//						If PadR(UPPER(cECodCid),TamSx3("A1_CODMUN")[1]) <> UPPER((cAliasSA1)->A1_COD_MUN)
						//							lChgCli := .T.
						//						EndIf
						//Verifica Endereço
						If PadR(UPPER(cEEnd),TamSx3("A1_END")[1]) <> UPPER((cAliasSA1)->A1_END)
							lChgCli := .T.
						EndIf
						//Verifica Bairro
						//						If PadR(UPPER(cEBairro),TamSx3("A1_END")[1]) <> UPPER((cAliasSA1)->A1_BAIRRO)
						//							lChgCli := .T.
						//						EndIf
						//Verifica CEP
						If PadR(UPPER(cECep),TamSx3("A1_CEP")[1]) <> UPPER((cAliasSA1)->A1_CEP)
							lChgCli := .T.
						EndIf
						//Verifica Telefone
						If PadR(UPPER(cETel),TamSx3("A1_TEL")[1]) <> UPPER((cAliasSA1)->A1_TEL)
							lChgCli := .T.
						EndIf
						//Verifica Data Nascimento
						//						If PadR(DTOS(dCDtNasc),TamSx3("A1_DTNASC")[1]) <> (cAliasSA1)->A1_DTNASC
						//							lChgCli := .T.
						//						EndIf

						//Adicionado validacao para lojas 9999 apenas a pedido do André em 31/05/2020.
						//Pois o cliente pode ter cadastros de outros estados e gera atualizacao em todos eles.
						If AllTrim((cAliasSA1)->A1_LOJA) <> '9999'
							lChgCli := .F.
						EndIf

						If lChgCli
							aAdd(aRotAuto,{"A1_COD"			,(cAliasSA1)->A1_COD	,Nil})
							aAdd(aRotAuto,{"A1_LOJA"		,(cAliasSA1)->A1_LOJA	,Nil})
							aadd(aRotAuto,{"A1_PESSOA"		,upper(cCTipPes)		,NIL})
							aadd(aRotAuto,{"A1_NOME"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
							aadd(aRotAuto,{"A1_NREDUZ"		,upper(rtrim(cCFName)+" "+ltrim(cCLName)),NIL})
							aadd(aRotAuto,{"A1_END"			,upper(cEEnd)			,NIL})
							aadd(aRotAuto,{"A1_TIPO"		,upper("F")				,NIL})	//OBRIGATORIO	//TODO: Verificar
							//aadd(aRotAuto,{"A1_BAIRRO"	,upper(cEBairro)		,NIL}) //Desativado pois possui gatilho do CEP
							//aadd(aRotAuto,{"A1_EST"		,upper(cECodEst)		,NIL}) //Desativado pois possui gatilho do CEP
							//aadd(aRotAuto,{"A1_COD_MUN"	,alltrim(cECodCid)		,NIL}) //Desativado pois possui gatilho do CEP
							If cECodEst $ "SP,MG,RJ,ES"
								//aadd(aRotAuto,{"A1_REGIAO","008"					,Nil})
								aadd(aRotAuto,{"A1_DSCREG","SUDESTE"				,Nil})
							ElseIf cECodEst $ "PR,SC,RS"
								//aadd(aRotAuto,{"A1_REGIAO","002"					,Nil})
								aadd(aRotAuto,{"A1_DSCREG","SUL"					,Nil})
							ElseIf cECodEst $ "AL,BA,CE,PI,SE,PE,PB,RN,MA"
								//aadd(aRotAuto,{"A1_REGIAO","007"					,Nil})
								aadd(aRotAuto,{"A1_DSCREG","NORDESTE"				,Nil})
							ElseIf cECodEst $ "AC,AM,RR,RO,AP,PA,TO"
								//aadd(aRotAuto,{"A1_REGIAO","001"					,Nil})
								aadd(aRotAuto,{"A1_DSCREG","NORTE"					,Nil})
							ElseIf cECodEst $ "GO,DF,MT,MS"
								//aadd(aRotAuto,{"A1_REGIAO","006"					,Nil})
								aadd(aRotAuto,{"A1_DSCREG","CENTRO OESTE"			,Nil})
							EndIf
							//aadd(aRotAuto,{"A1_LC"		,1						,NIL})//LIMITE DE CREDITO		//TODO: Verificar
							//aadd(aRotAuto,{"A1_VENCLC"	,CTOD("01/01/1999")		,NIL})//VENC LIMITE DE CREDITO	//TODO: Verificar
							//aadd(aRotAuto,{"A1_TABELA"	,"001"					,NIL})//TABELA DE PRECO			//TODO: Verificar
							//aadd(aRotAuto,{"A1_INSCR"		,upper("ISENTO")		,NIL})//OBRIGATORIO				//TODO: Verificar
							aadd(aRotAuto,{"A1_TEL"			,cETel					,NIL})
							aadd(aRotAuto,{"A1_CEP"			,cECep					,NIL})
							aadd(aRotAuto,{"A1_EMAIL"		,cCEmail				,NIL})
							//aadd(aRotAuto,{"A1_NATUREZ"	,"01.1"					,NIL}) //TODO: VERIFICA QUAL VAI SER REGRA
							//aadd(aRotAuto,{"A1_DTNASC"	,dCDtNasc				,NIL})
							aadd(aRotAuto,{"A1_VEND"		,cVendEcm				,NIL})
							aadd(aRotAuto,{"A1_PAIS"		,"105"					,NIL})
							aadd(aRotAuto,{"A1_CODPAIS"		,"01058"				,NIL})
							aadd(aRotAuto,{"A1_SIMPLES"		,"2"					,NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_SIMPNAC"		,"2"					,NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_TRANSP"		,Iif(!EMPTY((cAliasSA1)->A1_TRANSP)	,(cAliasSA1)->A1_TRANSP	,cTranspEcm),NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_RISCO"		,Iif(!EMPTY((cAliasSA1)->A1_RISCO)	,(cAliasSA1)->A1_RISCO	,cCliRisco)	,NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_IENCONT"		,Iif(!EMPTY((cAliasSA1)->A1_IENCONT),(cAliasSA1)->A1_IENCONT,"2")		,NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_CONTRIB"		,Iif(!EMPTY((cAliasSA1)->A1_CONTRIB),(cAliasSA1)->A1_CONTRIB,"2")		,NIL})//OBRIGATÓRIO
							aadd(aRotAuto,{"A1_ZBOLETO"		,Iif(!EMPTY((cAliasSA1)->A1_ZBOLETO),(cAliasSA1)->A1_ZBOLETO,"N")		,NIL})//OBRIGATÓRIO

							If GetNewPar("MA_XALTCLI",.F.) // Somente será ativada a alteração de clientes mediante criação do parâmetro e ativação do mesmo
								MSExecAuto({|x,y| Mata030(x,y)},aRotAuto,4) //3- Inclusão, 4- Alteração, 5- Exclusão

								If lMsErroAuto
									//aAutoErro := GETAUTOGRLOG()
									//_cObs := alltrim(date()+time())+"[ERRO]"+MostraErro()
									_cObs := MostraErro()
									cMsgError	:=	 "Falha ao ALTERAR cliente pela rotina Mata030. [ERRO]: "+_cObs
									FWLogMsg("ERROR","LAST",'1',"DECACADCLI",,"MAGENTO",cMsgError)
									MsgAlert(cMsgError,Procname())
									Break
								EndIf
							Endif
						EndIf
						
						aCliRet := {.F.,(cAliasSA1)->A1_COD, (cAliasSA1)->A1_LOJA}  //Alteração = .F., CodCli, LojCli
						
						dbSelectArea(cAliasSA1)
						dbSkip()
					EndDo
				EndIf
				(cAliasSA1)->(dbCloseArea())
			EndIf
		NEXT nX

	End Sequence

	RESTAREA(aAreaAnt)

Return aCliRet

/*/{Protheus.doc} DECADADPED

Função responsável por buscar os dados do pedido no Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
Static Function DECADADPED(cPedId)

	Local aAreaAnt := GetArea()
	Local oWsdl, nX
	Local aOps 		:= {}
	Local aSimple 	:= {}
	Local cXML 		:= ""
	Local aDadPed	:= {}

	FWLogMsg("INFO","",'1',"DECADADPED",,"MAGENTO","Iniciando coleta de dados de pedidos e clientes!")

	Begin Sequence

		oWsdl := TWsdlManager():New()
		oWsdl:lVerbose := lVerboseOn
		oWsdl:lSSLInsecure := .T.
		oWsdl:nTimeout 		:= 120
		//oWsdl:cEncoding := 'ISO-8859-1'
		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL(cUrlWSDL)
			cMsgError	:=	 "[ERRO parse] Falha ao realizar o parse do xml " + oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECALSTPED",,"MAGENTO",cMsgError)
			//			MsgAlert(cMsgError,Procname())
			//		    Return
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		//aOps := oWsdl:ListOperations()

		// Seta a operação a ser utilizada
		IF !oWsdl:SetOperation( "salesOrderInfo" )
			cMsgError := '[ERRO UPDATE] Falha ao utilizar webservice' + oWsdl:cError
			oActLog:Err(cMsgError)
			Break
			//	  		cMsgError := "Não foi possível setar a operação salesOrderInfo (SetOperation)"+chr(13)+chr(10)+oWsdl:cError
			//			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			//			Return
		ENDIF

		aSimple  := oWsdl:SimpleInput()

		// Define o valor do parâmeto session obrigatório
		If !oWsdl:SetValue( 0, cIdSession)
			cMsgError	:=	 "Não foi possível definir um token para montagem do xml"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		// Define o valor do parâmeto session obrigatório
		If !oWsdl:SetValue( 1, cPedId)
			cMsgError	:=	 "Não foi possível definir o ID do pedido: "+cPedId+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cXML := oWsdl:GetSoapMsg()
		FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",cXML)

		// Envia a mensagem SOAP ao servidor
		if !oWsdl:SendSoapMsg()
			cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		endif

		cError		:= ""
		cWarning	:= ""
		cGetRSub	:=	StrTran( oWsdl:GetSoapResponse(), "ï¿½", "")//Remove caracter especial
		If ValType(cGetRSub) == "U"
			cMsgError := "Falha no retorno do XML, não foi possível remover caracteres"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		cGetResp	:=	DecodeUTF8(cGetRSub, "cp1252")
		If ValType(cGetResp) == "U"
			cMsgError := "Falha ao fazer o decode de UTF8 no XML"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oXml := XmlParser( /*oWsdl:GetSoapResponse()*/ cGetResp , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno"+chr(13)+chr(10)+cError
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		oDadPed	:=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_SALESORDERINFORESPONSE:_RESULT
		If ValType(oDadPed) == "O"
			aDadPed := ClassDataAr(oDadPed,.T.)
		ElseIf ValType(oDadPed) == "A"
			nX := 0
			FOR nX := 1 TO Len(oLstPed)
				aAdd(aDadPed, ClassDataAr(oDadPed[nX],.T.))
			Next nX
		Else
			cMsgError	:=	 "Não foi possível buscar os dados do pedido no Magento"
			FWLogMsg("ERROR","LAST",'1',"DECADADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//cMsgLog	:=	"Dados do pedido "1+cPedId+" adicionados ao array (aDadPed) com sucesso"
		//FWLogMsg("INFO","LAST",'1',"DECALSTPED","MAGENTO",cMsgLog)
		//oActLog:Inf(cMsgLog)
	End Sequence

	oXML := NIL
	FreeObj(oWsdl)
	FreeObj(oXML)

	RESTAREA(aAreaAnt)

Return aDadPed

/*/{Protheus.doc} DECACADPED

Função responsável por alimentar o Protheus com os dados dos pedidos do Magento.

@author TSCB57 - WILLIAM FARIAS
@since 14/05/2019
@version 1.0

@example example
@return return
/*/
Static Function DECACADPED(cPedId, aPedDad, aCliDad)

	Local aAreaAnt := GetArea()
	Local lRet := .F.
	Local lRetTran := .F.
	Local _cObs		:= ""
	Local cAliasSC5	:= GetNextAlias()
	Local aRotAuto	:= {}
	Local aCabPV	:= {}
	Local aItemPV	:= {}
	Local aItens	:= {}
	Local aItensWS	:= {}
	Local lIncCli	:= aCliDad[1]
	Local cCodCli	:= aCliDad[2]
	Local cLojCli	:= aCliDad[3]
	Local cItem		:= "00"
	Local cTipoCli	:= ""
	Local cMoedaWS	:= ""
	Local cMoeda	:= "3"
	Local cStatMgtWS	:= ""
	Local cStatMgt	:= ""
	Local nVlrFrt	:= 0
	Local cObsEnt	:= ""
	Local cEObsEnd	:= "", nX
	Local cEObsBai	:= ""
	Local cObsEntCep := ""
	Local cObsEntCid := ""
	Local cObsEntEst := ""
	Local cBandCC	:= ""
	Local nRetVTot	:= 0
	Local nVlrDesc	:= 0
	Local cTes		:= ""
	Private lMsHelpAuto 	:= .T. // se .t. direciona as mensagens de help
	Private lAutoErrNoFile 	:= .T. //Utilizado em conjunto com a funcaoGetAutoGRLog .A variável __aErrAuto só é alimentada se a variável lAutoErrNoFile estiver declarada como .T.
	Private lMsErroAuto 	:= .F. //necessario a criacao, pois sera atualizado quando houver
	Private aAutoErro		:= {}
	Private nSomDif := 0
	Private cNumReserv := ""

	Begin Sequence

		//Pega a posição dos dados de cabeçalho do Pedido.
		//ID Pedido (Cod Pedido Magento)
		nPosPId		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_INCREMENT_ID" } )
		If nPosPId <> 0
			cPId := aPedDad[nPosPId][2]:TEXT
		Else
			cMsgError	:=	 "Falha ao buscar o ID do pedido. Posição: "+nPosPId
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Loja do Magento
		nPosLojId		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_STORE_ID" } )
		If nPosLojId <> 0
			cLojId := aPedDad[nPosLojId][2]:TEXT
		Else
			cMsgError	:=	 "Falha ao buscar o ID da loja do pedido. Posição: "+cValToChar(nPosLojId)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Data Emissao Magento
		nPosDTEmi		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_CREATED_AT" } )
		If nPosDTEmi <> 0
			cDTEmiWS := aPedDad[nPosDTEmi][2]:TEXT
			dDTEmi := STOD(Substr(cDTEmiWS,1,4)+Substr(cDTEmiWS,6,2)+Substr(cDTEmiWS,9,2))
		Else
			cMsgError	:=	 "Falha ao buscar a data de emissão do pedido do Magento. Posição: "+cValToChar(nPosDTEmi)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Status Magento
		nPosStatusMag		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )== "_STATUS" } )
		//ID Pedido (Cod Pedido Magento)
		If nPosStatusMag <> 0
			cStatMgtWS := aPedDad[nPosStatusMag][2]:TEXT
			If cStatMgtWS == "processing"
				cStatMgt := "3"
			ElseIf cStatMgtWS == "boleto_paid"
				cStatMgt := "2"
			ElseIf cStatMgtWS == "clearsale_approved"
				cStatMgt := "1"
			ElseIf cStatMgtWS == "clearsale_reproved"
				cStatMgt := "4"
			ElseIf cStatMgtWS == "pending"
				cStatMgt := "3"
			ElseIf cStatMgtWS == "holded"
				cStatMgt := "5"
			ElseIf cStatMgtWS == "canceled"
				cStatMgt := "6"
			Else
				//cMsgError	:=	 "Falha ao obter status do magento. Posição: "+cValToChar(nPosMoeda)+" Moeda: "+cMoedaWS
				//FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				//oActLog:Err(cMsgError)
				//MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				//Break
				cStatMgt := "3"
			EndIf
		Else
			//cMsgError	:=	 "Falha ao buscar a moeda do pedido. Posição: "+nPosMoeda
			//FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			//oActLog:Err(cMsgError)
			//MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			//Break7
			cStatMgt := "3"
		EndIf



		//Moeda
		nPosMoeda		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )== "_GLOBAL_CURRENCY_CODE" } )
		//ID Pedido (Cod Pedido Magento)
		If nPosMoeda <> 0
			cMoedaWS := aPedDad[nPosMoeda][2]:TEXT
			If cMoedaWS == "BRL"
				cMoeda := 1
			ElseIf cMoedaWS == "USD"
				cMoeda := 2
			ElseIf cMoedaWS == "EUR"
				cMoeda := 4
			Else
				cMsgError	:=	 "Falha ao identificar a moeda do pedido. Posição: "+cValToChar(nPosMoeda)+" Moeda: "+cMoedaWS
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
		Else
			cMsgError	:=	 "Falha ao buscar a moeda do pedido. Posição: "+nPosMoeda
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Pagamento
		nPosPag		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_PAYMENT" } )
		If nPosPag <> 0
			aPagWS := ClassDataAr(aPedDad[nPosPag][2])
			//Metodo
			nPosPagMtd		:= Ascan( aPagWS,{ |X| UPPER( AllTrim(X[1]) )=="_METHOD" } )
			If nPosPagMtd <> 0
				cCodPagMGT := aPagWS[nPosPagMtd][2]:TEXT
			Else
				cMsgError	:=	 "Falha ao buscar o metodo da forma de pagamento do pedido. Posição: "+cValToChar(nPosPagMtd)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			//Cartão
			If cCodPagMGT == "braspag_cc"
				//Bandeira
				nPosPagBan		:= Ascan( aPagWS,{ |X| UPPER( AllTrim(X[1]) )=="_CC_TYPE" } )
				If nPosPagBan <> 0
					cBandCC := aPagWS[nPosPagBan][2]:TEXT
				Else
					cMsgError	:=	 "Falha ao buscar a bandeira do cartão no método da forma de pagamento do pedido. Posição: "+cValToChar(nPosPagBan)
					FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break
				EndIf
				//Numero de Parcelas
				nPosPagAdI	:= Ascan( aPagWS,{ |X| UPPER( AllTrim(X[1]) )=="_ADDITIONAL_INFORMATION" } )
				If nPosPagAdI <> 0
					aPagParWS := ClassDataAr(aPagWS[nPosPagAdI][2])
					nPosPagIns	:= Ascan( aPagParWS,{ |X| UPPER( AllTrim(X[1]) )=="_INSTALLMENTS" } )
					If nPosPagIns <> 0
						cNumParc := aPagParWS[nPosPagIns][2]:TEXT
						cCodPagMGT += cNumParc
					Else
						cMsgError	:=	 "Falha ao buscar o numero de parcelas no método da forma de pagamento do pedido. Posição: "+cValToChar(nPosPagIns)
						FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
						oActLog:Err(cMsgError)
						MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
				Else
					cMsgError	:=	 "Falha ao buscar os dados adicionais de parcelas no método da forma de pagamento do pedido. Posição: "+cValToChar(nPosPagAdI)
					FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break
				EndIf
			EndIf
		Else
			cMsgError	:=	 "Falha ao buscar a forma de pagamento do pedido. Posição: "+cValToChar(nPosPag)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Valor Frete
		nPosVlrFrt		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_SHIPPING_AMOUNT" } )
		If nPosVlrFrt <> 0
			nVlrFrt := Val(aPedDad[nPosVlrFrt][2]:TEXT)
		Else
			cMsgError	:=	 "Falha ao buscar o valor do frete do pedido. Posição: "+cValToChar(nPosVlrFrt)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Valor Total do Pedido
		nPosVlrTot		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_GRAND_TOTAL" } )
		If nPosVlrTot <> 0
			nVlrTot := Val(aPedDad[nPosVlrTot][2]:TEXT)
		Else
			cMsgError	:=	 "Falha ao buscar o valor total do pedido. Posição: "+cValToChar(nPosVlrTot)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Descrição de entrega
		nPosEntDes		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_SHIPPING_DESCRIPTION" } )
		If nPosEntDes <> 0
			cObsEnt		+= "FORMA DE ENTREGA: " + aPedDad[nPosEntDes][2]:TEXT+chr(13)+chr(10)
		Else
			cMsgError	:=	 "Falha ao buscar o valor total do pedido. Posição: "+cValToChar(nPosVlrTot)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Endereço de Entrega
		nPosObsEnt		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_SHIPPING_ADDRESS" } )
		If nPosObsEnt <> 0
			aObsEnt := ClassDataAr(aPedDad[nPosObsEnt][2])

			//Nome no Endereço Entrega
			nPosObsNom	:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_FIRSTNAME" } )
			nPosObsSob	:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_LASTNAME" } )
			If nPosObsNom <> 0 .And. nPosObsSob <> 0
				cObsEntNom	:= aObsEnt[nPosObsNom][2]:TEXT
				cObsEntSob	:= aObsEnt[nPosObsSob][2]:TEXT
				cObsEnt		+= "DESTINATARIO: " + upper(rtrim(cObsEntNom)+" "+ltrim(cObsEntSob))+chr(13)+chr(10)
			Else
				cMsgError	:=	 "Falha ao buscar o nome e sobrenome do cliente do endereço de entrega do pedido. Posição: "+cValToChar(nPosObsNom) + " e " + cValToChar(nPosObsSob)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				MsgAlert(cMsgError,Procname())
				Break
			EndIf

			//Estado Endereço Entrega
			nPosObsEst		:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_REGION" } )
			If nPosObsEst <> 0
				cObsEntUFX := UPPER(NoAcento(aObsEnt[nPosObsEst][2]:TEXT))
				nPosObsUFX	:= Ascan( aEstado,{ |X| UPPER( AllTrim(X[1]) )==cObsEntUFX } )	//Estado
				If nPosObsUFX <> 0
					cObsEntEst := aEstado[nPosObsUFX][2]
				Else
					cMsgError	:=	 "Falha ao buscar o estado do endereço de entrega do pedido no array de estados. Estado Magento: "+cValToChar(nPosObsUFX)
					FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
					MsgAlert(cMsgError,Procname())
					Break
				EndIf
			Else
				cMsgError	:=	 "Falha ao buscar o estado do endereço de entrega do pedido. Posição: "+cValToChar(nPosObsEst)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				MsgAlert(cMsgError,Procname())
				Break
			EndIf

			//Cidade Endereço Entrega
			nPosObsCid		:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_CITY" } )
			If nPosObsCid <> 0
				cObsEntCid := aObsEnt[nPosObsCid][2]:TEXT
			Else
				cMsgError	:=	 "Falha ao buscar a cidade do endereço do pedido. Posição: "+cValToChar(nPosObsCid)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				MsgAlert(cMsgError,Procname())
				Break
			EndIf

			//CEP Endereço Entrega
			nPosObsCep		:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_POSTCODE" } )
			If nPosObsCep <> 0
				cObsEntCep := aObsEnt[nPosObsCep][2]:TEXT
			Else
				cMsgError	:=	 "Falha ao buscar o CEP do endereço de entrega do pedido. Posição: "+cValToChar(nPosObsCep)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				MsgAlert(cMsgError,Procname())
				Break
			EndIf

			//Endereço Cliente
			nPosObsEnd		:= Ascan( aObsEnt,{ |X| UPPER( AllTrim(X[1]) )=="_STREET" } )
			If nPosObsEnd <> 0
				cEObsSTrat	:= StrTran(aObsEnt[nPosObsEnd][2]:TEXT,chr(10),", ")
				nPosEBaiOb 	:= RAT(",",cEObsSTrat)
				cEObsEnd 	:= SubStr(cEObsSTrat,1,nPosEBaiOb-1)
				cEObsBai 	:= NoAcento(SubStr(cEObsSTrat,nPosEBaiOb+2))
			Else
				cMsgError	:=	 "Falha ao buscar o logradouro do endereço de entrega do pedido. Posição: "+cValToChar(nPosObsEnd)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				MsgAlert(cMsgError,Procname())
				Break
			EndIf

			cObsEnt += "ENDERECO DE ENTREGA: " + cEObsEnd + " - " + cEObsBai + " - CEP: " + cObsEntCep + " - " + cObsEntCid + " - " + cObsEntEst +chr(13)+chr(10)

		Else
			cMsgError	:=	 "Falha ao buscar o endereço de entrega. Posição: "+nPosEndEnt
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Verifica cliente
		DbSelectArea("SA1")
		DbSetOrder(1)
		If dbSeek(FWxFilial("SA1")+cCodCli+cLojCli)
			cTipoCli	:= SA1->A1_TIPO
			cTransPed	:= SA1->A1_TRANSP
		Else
			cMsgError	:=	 "Não foi possível encontrar o cliente do pedido "+cPedId+". Cliente: "+cCodCli+" Loja: "+cLojCli
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		If SA1->A1_MSBLQL == "1"
			cMsgError	:=	 "Cliente ainda não revisado/liberado, cadastro está bloqueado no Protheus. Pedido "+cPedId+" do magento não será importado."+chr(13)+chr(10)+"Cliente: "+cCodCli+" Loja: "+cLojCli
			FWLogMsg("INFO","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			//MsgAlert(cMsgError,"Info - "+ProcName()+"/"+cValToChar(ProcLine()))
			lRet := .F.
			Return lRet
		EndIf

		cCodCondP	:= listFx(cCondPag,cCodPagMGT)
		If Empty(cCodCondP)
			cMsgError	:=	 "Código da condição de pagamento não localizado no DE/PARA. Código Magento:"+cCodPagMGT+" Conteúdo parâmetro MA_CONDPAG: "+cCondPag
			FWLogMsg("INFO","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			//MsgAlert(cMsgError,"Info - "+ProcName()+"/"+cValToChar(ProcLine()))
			lRet := .F.
			Return lRet
		EndIf


		//Verifica se é presente pelo destinatario do endereço X cliente
		If !(alltrim(SA1->A1_NOME) == (upper(rtrim(cObsEntNom)+" "+ltrim(cObsEntSob))))
			cObsEnt += "MERCADORIA PARA PRESENTE, RETIRAR NF NO ATO DA ENTREGA."
		EndIf

		//VERIFICA SE O PEDIDO JÁ FOI INCLUIDO ATRAVÉS DO CODIGO DO PEDIDO DO CLIENTE
		// o D_E_L_E_T_ foi removido da query para que pedidos excluídos no Erp não sejam integrados novamente. 
		
		// 10/06/2021 os campos C5_CLIENTE e C5_LOJACLI foram removidos pois a loja do cliente era alterada depois de importar o pedido e acaba por reimportar o pedido
		// AND SC5.C5_CLIENTE	= %exp:cCodCli%   AND SC5.C5_LOJACLI	= %exp:cLojCli%
			  
		BeginSql alias cAliasSC5
			SELECT C5_NUM  
			  FROM %table:SC5% SC5
			 WHERE SC5.C5_FILIAL	= %exp:FWxFilial("SC5")%
			   AND SC5.C5_ZNUMMGT	= %exp:cPedId%
		EndSql

		If !(cAliasSC5)->(Eof())


			// 01/06/2021 - Verifica se o pedido já integrado teve alteração de Status 
			DbSelectArea("SC5")
			DbSetOrder(1)
			If DbSeek(xFilial("SC5")+(cAliasSC5)->C5_NUM)
				If C5_ZSTATMG	<> cStatMgt
					cMsgWf	:= "Pedido de Venda " + SC5->C5_NUM + " sofreu mudança de Status de '" +SC5->C5_ZSTATMG + "' para '" + cStatMgt + "' no dia " + DTOC(Date()) 
					U_WFGERAL("grupo.magento@decanter.com.br"/*cEmail*/,"Alteração Status Pedido Magento '"+cPedId+"' "/*cTitulo*/,cMsgWf/*cTexto*/,"DECA099"/*cRotina*/,/*cAnexo*/)
					RecLock("SC5",.F.)
					SC5->C5_ZSTATMG	:= cStatMgt
					MsUnlock()
				Endif 
			Endif 

			cMsgError	:=	 "Pedido já importado para o Protheus ("+(cAliasSC5)->C5_NUM+"). Número: "+cPedId+" Cliente: "+cCodCli+" Loja: "+cLojCli
			FWLogMsg("INFO","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			(cAliasSC5)->(DbCloseArea())
			//MsgStop(cMsgError,"Info - "+ProcName()+"/"+cValToChar(ProcLine()))
			lRet := .F.
			Return lRet
		Else
			//////////////////////////////////////////
			////		INICIO CABEÇALHO		  ////
			//////////////////////////////////////////
			aCabPV:={	{"C5_TIPO"   	,"N"        				,Nil},;
				{"C5_CLIENTE"	,cCodCli					,Nil},;
				{"C5_LOJACLI"	,cLojCli					,Nil},;
				{"C5_CLIENT"	,cCodCli   					,Nil},;
				{"C5_LOJAENT"	,cLojCli		   			,Nil},;
				{"C5_TRANSP"	,cTransPed        			,Nil},;
				{"C5_TIPOCLI"	,cTipoCli					,Nil},;
				{"C5_CONDPAG"	,cCodCondP,Nil},;
				{"C5_TABELA"	,cCdTabPrc					,Nil},;
				{"C5_VEND1"		,'000138'					,Nil},;
				{"C5_DESC1"		,0					        ,Nil},;
				{"C5_EMISSAO"	,Date() 					,Nil},;
				{"C5_MOEDA"   	,cMoeda						,Nil},;//{"C5_REDESP" ,SA1->A1_REDESP ,Nil},; //{"C5_ESPECI1" ,"CX. PAPELAO" ,Nil},; //{"C5_TIPLIB"	,"1"  	   					,Nil},;//TODO: Verificar regra. //{"C5_TXMOEDA"	,1 ,Nil},;//{"C5_TPCARGA"	,"2"			  	   		,Nil},;
				{"C5_NATUREZ"	,cCdNatu					,Nil},;
				{"C5_FRETE"		,nVlrFrt					,Nil},;
				{"C5_TPFRETE"	,'C'						,Nil},;				
				{"C5_ZOBSENT"	,cObsEnt					,Nil},;
				{"C5_ZNUMMGT"	,cPedId						,Nil},;
				{"C5_ZDTEMGT"	,dDTEmi						,Nil},;
				{"C5_ZBCCMGT"	,cBandCC					,Nil},;
				{"C5_ZSTATMG"	,cStatMgt					,Nil},;
				{"C5_ZCEPMGT"	,StrTran(cObsEntCep,"-","")	,Nil},;
				{"C5_ZBOLETO"	,'N'						,Nil},;//Pedidos Ecommerce não geram boletos
			{"C5_ZLOJMGT"	,cLojID						,Nil}}
		EndIf
		//////////////////////////////////////////
		////		   FIM CABEÇALHO		  ////
		//////////////////////////////////////////

		//////////////////////////////////////////
		////		 	INICIO ITEM			  ////
		//////////////////////////////////////////
		//Itens
		nPosItens		:= Ascan( aPedDad,{ |X| UPPER( AllTrim(X[1]) )=="_ITEMS" } )
		If nPosItens <> 0
			oItensWS := aPedDad[nPosItens][2]:_ITEM
			If ValType(oItensWS) == "O"
				aItensWS := {ClassDataAr(oItensWS)}
			ElseIf ValType(oItensWS) == "A"
				nX := 0
				FOR nX := 1 TO Len(oItensWS)
					aAdd(aItensWS, ClassDataAr(oItensWS[nX],.T.))
				Next nX
			Else
				cMsgError	:=	 "Falha ao identificar tipo de retorno ao buscar os itens do pedido. Posição: "+cValToChar(nPosItens)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
		Else
			cMsgError	:=	 "Falha ao buscar os itens do pedido. Posição: "+cValToChar(nPosItens)
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		//Inicia função para calcular valor unit do item
		MaFisEnd()
		MaFisIni(cCodCli,;			// 1-Codigo Cliente
		cLojCli,;			// 2-Loja do Cliente
		"C",;				// 3-C:Cliente , F:Fornecedor
		"N",;				// 4-Tipo da NF
		cTipoCli,;			// 5-Tipo do Cliente/Fornecedor
		Nil,;
			Nil,;
			Nil,;
			Nil,;
			"MATA410")

		nX := 0
		For nX := 1 to Len(aItensWS)

			cItem := Soma1(cItem)
			//Produto
			nPosProd		:= Ascan( aItensWS[nX],{ |X| UPPER( AllTrim(X[1]) )=="_SKU" } )
			If nPosProd <> 0
				cProd := aItensWS[nX][nPosProd][2]:TEXT
			Else
				cMsgError	:=	 "Falha ao buscar o produto do pedido. Posição: "+(nPosProd)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			//Quantidade
			nPosQtdVen		:= Ascan( aItensWS[nX],{ |X| UPPER( AllTrim(X[1]) )=="_QTY_ORDERED" } )
			If nPosQtdVen <> 0
				nQtdVen := Val(aItensWS[nX][nPosQtdVen][2]:TEXT)
			Else
				cMsgError	:=	 "Falha ao buscar a quantidade do produto do pedido. Posição: "+cValToChar(nPosQtdVen)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			//Preço
			nPosPrcVen		:= Ascan( aItensWS[nX],{ |X| UPPER( AllTrim(X[1]) )=="_PRICE" } )
			If nPosPrcVen <> 0
				nPrcVen := Val(aItensWS[nX][nPosPrcVen][2]:TEXT)
			Else
				cMsgError	:=	 "Falha ao buscar o preço do produto do ped?ido. Posição: "+cValToChar(nPosPrcVen)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			//Desconto
			nPosVlrDes		:= Ascan( aItensWS[nX],{ |X| UPPER( AllTrim(X[1]) )=="_DISCOUNT_AMOUNT" } )
			If nPosVlrDes <> 0
				nVlrDesc := Val(aItensWS[nX][nPosVlrDes][2]:TEXT)
			Else
				cMsgError	:=	 "Falha ao buscar o preço do produto do pedido. Posição: "+cValToChar(nPosVlrDes)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			//Data Pedido
			nPosDtEntr		:= Ascan( aItensWS[nX],{ |X| UPPER( AllTrim(X[1]) )=="_CREATED_AT" } )
			If nPosDtEntr <> 0
				cDtEntrWS	:= aItensWS[nX][nPosDtEntr][2]:TEXT
				dDtEntr		:= STOD(Substr(cDtEntrWS,1,4)+Substr(cDtEntrWS,6,2)+Substr(cDtEntrWS,9,2))
			Else
				cMsgError	:=	 "Falha ao buscar a data de entrega do produto do pedido. Posição: "+cValToChar(nPosDtEntr)
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			dbSelectArea("SB1")
			dbSetOrder(1)//Codigo do Produto
			dbGoTop()
			If !dbSeek(xFilial("SB1")+cProd)
				cMsgError	:=	 "Produto do pedido no Magento não encontrado no Protheus. Cód. Produto (SKU): "+cProd
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			//Busca a TES conforme o tipo de operação. //TODO: Verificar
			If cTpOper <> ""
//							MaTesInt(nEntSai,cTpOper,cClieFor,cLoja,cTipoCF,cProduto,cCampo,cTipoCli) --> cTesRet
				cTes	:=	MaTESInt(2,cTpOper,cCodCli,cLojCli,"C",SB1->B1_COD/*,"C6_TES",cTipoCli*/)
			Else
				//				cTes := "506"
				cMsgError	:=	 "Tipo de operação não encontrada no parametro (MV_ZTPOPER). Tipo Operação: "+cTpOper
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			dbSelectArea("SF4")
			dbSetOrder(1)
			If Empty(cTes)
				cMsgError	:=	 "Tes não localizada com a operação (TES Int.) informada. Item: "+cItem+" Produto: "+SB1->B1_COD+" Cliente: "+cCodCli+" Loja: "+cLojCli+" Operação: "+cTpOper
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			If !SF4->(dbSeek(FwXFilial("SF4")+cTes))
				cMsgError	:=	 "Tes não localizada. Item:"+cItem+" Produto:"+SB1->B1_COD+" Cliente: "+cCodCli+" Loja: "+cLojCli+" Operação: "+cTpOper
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			If SF4->F4_DUPLIC <> "S"
				cMsgError	:=	 "TES deve ser configurada para gerar financeiro: "+cTes
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			//			If SF4->F4_ESTOQUE <> "N"
			//				cMsgError	:=	 "TES não deve atualizar estoque: "+cTes
			//				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			//				oActLog:Err(cMsgError)
			//				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			//				Break
			//			EndIf

			//Calcula valor liquido unitario (sem imposto)
			//nValLiq	:= DECACVLI(nPrcVen, nQtdVen, SB1->B1_COD, cTes,nX,nVlrDesc)

			//Adiciona itens no array
			aItemPV:={	{"C6_ITEM"		,cItem					,Nil},;
				{"C6_PRODUTO"	,SB1->B1_COD			,Nil},;
				{"C6_OPER"		,cTpOper				,Nil},;
				{"C6_TES"		,cTes					,Nil},;
				{"C6_QTDVEN"	,nQtdVen				,Nil},;
				{"C6_UM"		,SB1->B1_UM				,Nil},;
				{"C6_VALDESC"	,0	   					,Nil},;
				{"C6_ENTREG"	,dDtEntr				,Nil},;
				{"C6_LOCAL"		,"01"			,Nil},;
				{"C6_XUPRCVE"	,nPrcVen - (nVlrDesc / nQtdVen)				,Nil}} //nValLiq(nPrcVen - (nVlrDesc / nQtdVen))
			AADD(aItens,aItemPV)
		
		CPRODUTO := SB1->B1_COD

		If cFilAnt == "0101"
			CPRODUTO := Padr(CPRODUTO,TamSX3("B2_COD")[1])
			DbSelectArea("SB2")
			SB2->(DbSetOrder(1))
			If DbSeek("0101"+CPRODUTO+"02")
				//ALERT("já existe sb2 de: "+CPRODUTO+"/"+cFilAnt)
			Else 
	  			CriaSb2(CPRODUTO,"02")
			Endif
		EndIf


		Next nX

		//Verifica valor total magento x protheus
		nRetVTot := MaFisRet(,"NF_TOTAL")
		nValTotFun := (nRetVTot - nSomDif) + nVlrFrt //Total da função + frete
		MaFisEnd()
		If nValTotFun <> nVlrTot
			//cMsgError	:=	 "Valor total do pedido do magento: "+cValToChar(nVlrTot)+" é diferente do valor total do pedido calculado: "+cValToChar(nValTotFun)
			//FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			//oActLog:Err(cMsgError)
			//MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			//Break
		EndIf

		If LEN(aCabPV)>0 .AND. LEN(aItens)>0
			Begin Transaction

				//If DECARESERV(@aItens)
					//TSC679 - CHARLES REITZ - 03/03/2020 - REMOVIDO, AJUSTADO APRA FAZER DENTRO DA FUCAO
					// POIS TEM ITENS QUE TEM ESTOQUE DEVE FAZER A RESERVAR
					//For nX:= 1 To Len(aItens)
					//	aAdd( aItens[nX], {"C6_RESERVA"		,cNumReserv			,Nil})
					//Next
					DbSelectArea("SA1"); DbSetOrder(1)
					DbSelectArea("SA3"); DbSetOrder(1)
					DbSelectArea("SA4"); DbSetOrder(1)
					DbSelectArea("SB1"); DbSetOrder(1)
					DbSelectArea("SE4"); DbSetOrder(1)
					DbSelectArea("SC5"); DbSetOrder(1)

					MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabPV,aItens,3)

					If lMSErroAuto
						DisarmTransaction()
						aAutoErro 	:= GETAUTOGRLOG()
						cMsgErr 	:= "Erro na execução da rotina MATA410: "+chr(13)+chr(10)+alltrim(ArrTokStr(aAutoErro))
						oActLog:Err(cMsgErr)
						MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
						Break
					EndIf
					lRetTran := .T.
				/*Else
					DisarmTransaction()
					aAutoErro 	:= GETAUTOGRLOG()
					cMsgErr 	:= "Erro na execução da rotina de controle de reserva. "+chr(13)+chr(10)+alltrim(ArrTokStr(aAutoErro))
					oActLog:Err(cMsgErr)
					MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break 
				EndIf*/
			End Transaction
			If !lRetTran
				cMsgErr 	:= "Erro na transação, saindo da sequência de inclusão do pedido."
				oActLog:Err(cMsgErr)
				MsgStop(cMsgErr,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
		EndIf
		//Somente bloqueia cliente para revisão quando for inclusão.
		If lIncCli
			SA1->(RecLock("SA1",.F.))
			SA1->A1_MSBLQL	:=	"2"
			SA1->(msUnlock())
		EndIf

		lRet := .T.

	End Sequence

	RESTAREA(aAreaAnt)

Return lRet

/*/{Protheus.doc} DECACVLI

Função responsável por calcular o valor liquido do item (IPI e ICMS-ST).

@author TSCB57 - WILLIAM FARIAS
@since 13/06/2019
@version 1.0

@example example
@return return
/*/
Static Function DECACVLI(nPrcVen,nQtdVen,cCodProd,cTes,nX,nVlrDesc)
	Local nRetVliq	 := 0
	Local nDifere	 := 0
	Local nValorTot	 := 0
	Local nValTotIte := 0
	Local nValMerc	 := A410Arred(nPrcVen*nQtdVen,"C6_VALOR")
	Local nPrcLista	 := A410Arred(nPrcVen,"C6_PRCVEN")

	nVlrDesc := 0//A410Arred(nVlrDesc,"C6_VALDESC")

	MaFisAdd(cCodProd,;   		// 1-Codigo do Produto ( Obrigatorio )
	cTes,;	   			// 2-Codigo do TES ( Opcional )
	nQtdVen,;  			// 3-Quantidade ( Obrigatorio )
	nPrcLista,;		  	// 4-Preco Unitario ( Obrigatorio )
	nVlrDesc,; 			// 5-Valor do Desconto ( Opcional )
	"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
	"",;				// 7-Serie da NF Original ( Devolucao/Benef )
	0,;					// 8-RecNo da NF Original no arq SD1/SD2
	0,;					// 9-Valor do Frete do Item ( Opcional )
	0,;					// 10-Valor da Despesa do item ( Opcional )
	0,;					// 11-Valor do Seguro do item ( Opcional )
	0,;					// 12-Valor do Frete Autonomo ( Opcional )
	nValMerc,;			// 13-Valor da Mercadoria ( Obrigatorio )
	0)					// 14-Valor da Embalagem ( Opcional )

	nValTotIte	:= MaFisRet(nX,"IT_TOTAL")	//Total do item + Impostos
	nValorTot	:= nValMerc - nVlrDesc		//Total do item recebido - Desconto

	nDifere		:= nValTotIte - nValorTot	//Diferença de total c/ impostos e total recebido
	nSomDif		+= nDifere					//Soma as diferenças para comparar no final

	nRetVLiq	:= (nValorTot - nDifere)/nQtdVen	//Preço liquido unitario (sem impostos)

Return nRetVLiq

/*/{Protheus.doc} DECARESERV

Função responsável por fazer o controle de reserva de estoque.

@author TSCB57 - WILLIAM FARIAS
@since 17/06/2019
@version 1.0

@example example
@return return
/*/
Static Function DECARESERV(aItens)
	Local lRet			:=	.T., nX
	Local oModelRes, oSC0M, oSC0G, nPosProdIt, nPosQntdIt, cNumReserv, nPosLoc, cLocalPr

	Begin Sequence
		lOpcAuto	:= .F.
		nPergRepl	:= 0
		oModelRes := FWLoadModel("MATA430")//Carrega estrutura do model
		oModelRes:SetOperation(MODEL_OPERATION_INSERT)//Define operacao de inclusao
		oModelRes:Activate()//Ativa o model

		oSC0M	:=  oModelRes:GetModel("MASTER")
		oSC0G	:=	oModelRes:GetModel("SC0GRID")

		oSC0M:SetValue("C0_TIPO"	, "PD"	)
		oSC0M:SetValue("C0_SOLICIT"	, "Magento"		)
		SB2->(dbSetOrder(1))

		For nX := 1 TO Len(aItens)
			//Produto
			nPosProdIt		:= Ascan( aItens[nX],{ |X| UPPER( AllTrim(X[1]) )=="C6_PRODUTO" } )
			nPosLoc		:= Ascan( aItens[nX],{ |X| UPPER( AllTrim(X[1]) )=="C6_LOCAL" } )
			//Quantidade
			nPosQntdIt		:= Ascan( aItens[nX],{ |X| UPPER( AllTrim(X[1]) )=="C6_QTDVEN" } )

			If nPosProdIt <> 0 .And. nPosQntdIt <> 0 .And. nPosLoc <> 0
				cProduto := aItens[nX][nPosProdIt][2]
				nQuantid := aItens[nX][nPosQntdIt][2]
				cLocalPr	:=	aItens[nX][nPosLoc][2]
			Else
				cMsgError	:=	 "Falha ao buscar o produto e a quantidade no controle de reserva."
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			SB2->(MsSeek(fwxFilial("SB2")+cProduto+cLocalPr))
			If SaldoMov() < nQuantid
				cMsgError	:=	 "Produto sem saldo, não será feito a reserva"
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				Loop
			EndIf

			If !oSC0G:IsEmpty()
				oSC0G:AddLine()
			EndIf


			If !oSC0G:SetValue("C0_PRODUTO"	, cProduto	)
				cMsgError := "Falha ao validar dados do controle de reserva de estoque! Produto: "+alltrim(cProduto)+" Quantidade: "+cValToChar(nQuantid)+chr(13)+chr(10)
				aEval( oModelRes:GetErrorMessage(), {|x| cMsgError += Alltrim(x) + CRLF })
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf
			If !oSC0G:SetValue("C0_QUANT"	, nQuantid	)
				oSC0G:DeleteLine()
				//oSC0G:LoadValue("C0_QUANT"	, 0	)
				//oSC0G:LoadValue("C0_PRODUTO",''	)
				cMsgError := "Não foi feito a reserva do produto "+alltrim(cProduto)+" Quantidade: "+cValToChar(nQuantid)+chr(13)+chr(10)
				aEval( oModelRes:GetErrorMessage(), {|x| cMsgError += Alltrim(x) + CRLF })
				FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
				oActLog:Inf(cMsgError)
				Break
			EndIf
			aAdd( aItens[nX], {"C6_RESERVA"		,"",Nil})

		Next

		If oModelRes:VldData()
			cNumReserv	:= oSC0M:GetValue("C0_NUM")

			//TSC679 - CHARLES REITZ - 03/03/2020 - AJUSTADO PARA GRAVAR A RESERVA SOMENTE DOS ITENS QUE TEM ESTOQUE
			// Grava a reserva nos itens que consegui fazer
			For nX := 1 TO Len(aItens)
				nPosRes		:= Ascan( aItens[nX],{ |X| UPPER( AllTrim(X[1]) )=="C6_RESERVA" } )
				If nPosRes > 0
					aItens[nX][nPosRes][2]	:=	cNumReserv
				EndIf
			Next
			oModelRes:CommitData()
			lRet	:=	.T.
		Else
			aLog := oModelRes:GetErrorMessage()
			cMsgError := "Falha ao validar dados do controle de reserva de estoque! Produto: "+alltrim(cProduto)+" Quantidade: "+cValToChar(nQuantid)+chr(13)+chr(10)
			For nX := 1 to Len(aLog)
				If !Empty(aLog[nX])
					cMsgError += Alltrim(aLog[nX]) + CRLF
				EndIf
			Next nX
			lMsErroAuto := .T.
			FWLogMsg("ERROR","LAST",'1',"DECACADPED",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			//lRet := .F.
		EndIf


	End Sequence

	IF oModelRes <> nil
		oModelRes:DeActivate()
		oModelRes:Destroy()
		oModelRes := NIL
	eNDiF


Return lRet



/*/{Protheus.doc} DECAPEDLOG

Função para adicionar os logs na tabela Z06.

@author .
@since 17/06/2019
@version 1.0

@example example
@return return
/*/
Static Function DECAPEDLOG(cNumPed,cMsg)
	Local lRet := .F.

Return lRet

/*/{Protheus.doc} listFx

.

@author .
@since 00/00/0000
@version 1.0

@example example
@return return
/*/
Static Function listFx(cParam,cChave)

	Local aArr  := StrTokArr(cParam,";")
	Local aArr2 := {}
	Local nPos  := 0
	Local cRet  := ''

	aEval(aArr, {|x| aadd(aArr2,StrTokArr2(x,"="))} )
	IF (nPos := aScan(aArr2,{|aVet| aVet[1] == AllTrim(cChave)})) > 0
		cRet := aArr2[nPos][2]
	ELSE
		cRet := ''
	ENDIF

Return cRet


/*

		//Adiciona status magento ao pedido André em 10/05/2021
        cZSTATUSMGT	:= Ascan( aLstPed[nX],{ |X| UPPER( AllTrim(X[1]) )=="_STATUS" } )
		
		Do Case
			Case cZSTATUSMGT == "CLEARSALE_APPROVED"
				 cZSTATUS := "1" 
			Case cZSTATUSMGT == "BOLETO_PAID"
				 cZSTATUS := "2" 
			Case cZSTATUSMGT == "PROCESSING"
				 cZSTATUS := "3" 
			Case cZSTATUSMGT == "PENDING"
				 cZSTATUS := "3"
			Case cZSTATUSMGT == "CLEARSALE_REPROVED"
				 cZSTATUS := "4" 
			Case cZSTATUSMGT == "HOLDED"
				 cZSTATUS := "5" 
			Case cZSTATUSMGT == "CANCELED"
				 cZSTATUS := "6" 
		EndCase


*/
