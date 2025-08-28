#INCLUDE "totvs.ch"

/*/{Protheus.doc} DECA006T
Função principal de envio dos produtos para o magento, também realiza a sua exclusão
@author charles.totvs
@since 27/05/2019
@type function
/*/
User Function DECA006T()

	RpcSetType(3)
	RpcSetEnv("01")

	U_DECA006("")//('60260418')//('00017631')

	RpcClearEnv()

Return


/*/{Protheus.doc} DECA006
Função principal de envio dos produtos para o magento, também realiza a sua exclusão
@author charles.totvs
@since 27/05/2019
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function DECA006(cParCodProd)

	Local cDescDet		:=	""
	Local lEnd			:= .F.
	Local cLockName		:=	ProcName()+Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL)
	Private lIsBlind	:=	isBlind()
	Private cCodProdAt	:= cParCodProd

	If !LockByName(cLockName,.T.,.F.)
		MsgStop("Rotina está sendo processada por outro usuário")
		U_GetUsrLock(cLockName)
		Return
	EndIf
	U_PutUsrLock(cLockName)

	oActLog	:=	ACTXLOG():New()
	oActLog:Start("DECA006"," Iniciando integração com Magento",)
	FWLogMsg("INFO","",'1',"DECA006",,"MAGENTO"," Iniciando integração com Magento")

	oActLog:Inf("DECA006",If(lIsBlind,"Executado VIA JOB","Executado manualmente com interface"))
	FWLogMsg("INFO","LAST",'1',"DECA006",,"MAGENTO",If(lIsBlind,"Executando via JOB","Executando em tela"))

	If lIsBlind

		U_RunA006()

	Else

		cDescDet	:= "Rotina responsável por realizar o envio a atualização dos produtos para o Magento"
		oGrid		:=	FWGridProcess():New(   "DECA006",  "Enviar Produtos para Magento", cDescDet, {|lEnd| U_RunA006(@lEnd)}, "")
		oGrid:SetMeters(2)
		//oGrid:SetThreadGrid(1)
		oGrid:SetAbort(.T.)
		oGrid:Activate()

	EndIf

	oActLog:Fin()
	FWLogMsg("INFO","LAST",'1',"DECA006",,"MAGENTO","Finalizado integração com Magento")

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
Return { "P", "DECA006", "", {}, "" }

/*/{Protheus.doc} RunA006
description
@type function
@version  
@author luis.balsini
@since 22/05/2019
@param lEnd, logical, param_description
@return return_type, return_description
/*/
User Function RunA006(lEnd)

	Local cSqlWhere		:=	""
	Local oWsdl			:= TWsdlManager():New()
	Local oXml 			:= nil
	Local aOps 			:= {}
	Local aComplexList 	:= {}
	Local aSimple 		:= {}
	Local aComplex 		:= {}
	Local nO
	Local aDados 		:= {}
	Local cXML 			:= ''
	Local cMsgError 	:= ''
	Local cidsession 	:= ''
	Local nIUV
	Local aHashMap		:= {}
	Local nOccurs 		:= 0
	Local nPos   		:= 0
	Local nI      		:= 1
	Local nAttr  		:= 1
	Local cCodRel 		:= ''
	Local cCodRelPai 	:= ''
	Local lRetEx  		:= .F.
	Local oXml			:=	nil
	Local nCount		:=	0
	Local cIdSession	:= ""
	Local nTotSucess	:=	0
	Local nTotError		:= 0
	Private cCdTabPrc 	:= GETMV("MA_CODTABP"	,,"107")
	Private cUrlWSDL  	:= GetMv("MA_URLWSDL"	,,"https://homolog.decanter.com.br/api/v2_soap/?wsdl")
	Private cAuthUser	:= GetMv("MA_USUARIO"	,,"totvs")
	Private cAuthPass	:= GetMv("MA_TOKENAC"	,,"6Dz9lKDlEnIs")
	Private lHttpAuth	:= GetMv("MA_HTTPAUT"	,,.T.)
	Private cHttpUser	:= GetMv("MA_HTTPUSE"	,,"trezo")
	Private cHttpPass	:= GetMv("MA_HTTPPAS"	,,"apolo17")
	Private cAcidez		:= GetMv("MA_ACIDEZ"	,,"FRS=16460;MFR=16459;PFR=16458")
	Private cCorpo		:= GetMv("MA_CORPO"	    ,,"CRP=16452;LEV=16451;RBT=16453")
	Private cTanino		:= GetMv("MA_TANINO"    ,,"MTN=16456;PTN=16455;STN=16454;TNC=16457")
	Private cMadeira	:= GetMv("MA_MADEIRA"   ,,"CMD=16463;PMD=16462;SMD=16461")
	Private cEstEvol	:= GetMv("MA_ESTEVOL"   ,,"BBR=16466;BGR=16465;GRD=16464")
	Private cTpBebida	:= GetMv("MA_TPBEBIDA"  ,,"AZT=16470;DST=16468;LCR=16469;VNH=16467")
	Private cTpProduto  := GetMv("MA_TPPRODUTO" ,,"simple")
	Private cSetGpAttr  := GetMv("MA_TPPRODUTO" ,,"4")
	Private cVisibility := GetMv("MA_TPPRODUTO" ,,"4")
	Private cStoreView  := GetMv("MA_STOREVIEW" ,,"0")
	//Private cStatus     	:= GetMv("MA_STATUS"    ,,"1")// 2 = desabilitado
	Private lVerboseOn	:= GetMv("MA_SAVEXML"	,,.F.)

	Begin Sequence
		//É aberta uma unica sessao para realizar o processamento no magento

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Excluindo Logs antigos")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		//Mantem os logs por apenas 1 semana
		aArqErase := directory("\log\xmpad\deca006*.log")
		For nO := 1 To Len(aArqErase)
			If aArqErase[nO][3] <= dDataBase-7
				FERASE("\log\xmpad\"+aArqErase[nO][1])
			EndIf
		Next

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Realizando autenticação com Magento")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		cidsession := U_MAGEAuth()
		If EmptY(cidsession)
			cMsgError	:=	 "Não foi possível realizar autenticação com o Magento""
			//FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		// Verifica os produtos que foram enviados para o Magento e precisam ser excluidos
		IF !excluir(cidsession)
			Break
		ENDIF

		If !lIsBlind
			oGrid:SetIncMeter(1,"Verificando produtos a serem enviados ao magento")
			oGrid:SetIncMeter(2,"")
			ProcessMessage()
		EndIf


		cSqlWhere	:=	"%"
		If !Empty(cCodProdAt)
			cSqlWhere	+=	" AND B1_COD = '"+cCodProdAt+"' "
		EndIf
		cSqlWhere	+=  "%"

		//realiza varedura de produtos na base do sistema, trazendo todos
		beginSQL Alias "SB1TMP"
			SELECT DISTINCT  SB1.R_E_C_N_O_ RECNOSB1,B1_PESO,B1_ZMAGLOJ,B1_MSBLQL,DA1_ZPESPE,
					B1_COD,B1_DESC,DA1_PRCVEN,
					/*B1_IPI,*/
					/*B2_QATU-B2_QPEDVEN-B2_RESERVA*/ DA1_ZQATU B2_SALDO,B2_TIPO,ZFT_DESCR,
					ZFT_CTDESC,B1_SAFRA,ZFT_CLASSI,
					ZFT_PRODUT,ZFT_UVA1,ZFT_UVA2,
					ZFT_UVA3,ZFT_UVA4,ZFT_UVA5,
					ZFT_UVA6,ZFT_UVA7,ZFT_UVA8,
					ZFT_CORPO,ZFT_TANICO,ZFT_ACIDEZ,
					ZFT_MADEIR,ZFT_EVOLUC,ZFT_DTLREG,
					ZFT_CLALEG,ZFT_CASTA,ZFT_ALCOOL,
					ZFT_AMADUR,ZFT_GUARDA,ZFT_TEMPER,
					ZFT_NOVO,ZFT_ORIGIN,ZFT_ROSCA,
					ZFT_VOLUME,ZFT_ACDTOT,ZFT_ACUCAR,
					ZFT_PRODUC,ZFT_TECPRO,Z04_DESCRI,Z04_TIPBBR,Z04_CODIGO,
					Z04_CODREL,Z03_DESCRI,Z03_PAIS,Z03_CODIGO,
					Z03_CODREL,ZFT_DESCR,B1_ZIDMAGE,
					CAST(ZFT_APLGAS as varchar(2000)) ZFT_APLGAS,
					CAST(ZFT_CHARUT as varchar(2000)) ZFT_CHARUT,
					CAST(ZFT_ENOGAS as varchar(2000)) ZFT_ENOGAS,
					CAST(ZFT_PREMIO as varchar(2000)) ZFT_PREMIO,
					CAST(ZFT_SOBREP as varchar(2000)) ZFT_SOBREP,
					CAST(ZFT_SOBREV as varchar(2000)) ZFT_SOBREV,
					CAST(ZFT_ELABOR as varchar(2000)) ZFT_ELABOR,
					CAST(ZFT_CLIMA as varchar(2000)) ZFT_CLIMA,
					CAST(ZFT_SOLO as varchar(2000)) ZFT_SOLO,
					CAST(ZFT_CULTIV as varchar(2000)) ZFT_CULTIV,
					CAST(ZFT_FRUTA as varchar(2000)) ZFT_FRUTA,
					YA_ZCODREL, Z02_CODREL,Z02_DESCRI, Z02_CODIGO
			   FROM %table:SB1% SB1
			  /*INNER JOIN %table:SB5% SB5
			     ON SB5.%notDel%
			    AND B5_FILIAL  		= %xFilial:SB5%
			    AND B5_COD 			= B1_COD*/
			  LEFT OUTER JOIN %table:ZFT% ZFT
			     ON ZFT.%notDel%
			    AND ZFT_FILIAL  	= %xFilial:ZFT%
			    AND ZFT_COD 			= B1_ZFT
			  INNER JOIN %table:SB2% SB2
			     ON SB2.%notDel%
//			    AND B2_FILIAL 		= %xFilial:SB2%
			    AND B2_FILIAL 		IN ('0101','0104')
			    AND B2_COD			= B1_COD     		
			    AND B2_LOCAL 		= B1_LOCPAD
			  INNER JOIN %table:DA0% DA0
			     ON DA0.%notDel%
			    AND DA0_FILIAL 		= %xFilial:DA0%
			    AND %exp:Date()% BETWEEN DA0_DATDE AND DA0_DATATE
			    AND %exp:time()% BETWEEN DA0_HORADE	AND DA0_HORATE
			    AND DA0_ATIVO  		= '1'
			    AND DA0_CODTAB 		= %exp:cCdTabPrc%
			  INNER JOIN %table:DA1% DA1
			     ON DA1.%notDel%
			    AND DA1_FILIAL 		= %xFilial:DA1%
			    AND DA1_CODTAB		= DA0_CODTAB
			    AND DA1_CODPRO	 	= B1_COD
			    AND DA1_PRCVEN 		<> 0
			    AND ( DA1_DATVIG = '' OR %exp:Date()% >= DA1_DATVIG   )
			    AND DA1_ATIVO  		= '1'
			   LEFT JOIN %table:Z03% Z03
		  	     ON Z03.%notDel%
			    AND Z03_FILIAL 		= %xFilial:Z03%
			    AND ZFT_PRODUT 		= Z03_CODIGO
			   LEFT JOIN %table:Z02% Z02
			     ON Z02.%notDel%
			    AND Z02_CODIGO 		= Z03_REGIAO
			    AND Z02_FILIAL 		= %xFilial:Z02%
			   LEFT JOIN %table:Z04% Z04
			     ON Z04.%notDel%
			    AND ZFT_CLASSI 		= Z04_CODIGO
			    AND Z04_FILIAL 		= %xFilial:Z04%
			   LEFT JOIN %table:SYA% SYA
			     ON SYA.%notDel%
			    AND YA_CODGI		= Z03_PAIS
			    AND YA_FILIAL 		= %xFilial:SYA%
			  WHERE SB1.%notDel%
			    AND B1_FILIAL  		= %xFilial:SB1%
			    AND B1_TIPO 		= 'ME'
			    //AND B1_ZMAGLOJ		<> '' /*Somente envia se tem loja associada*/
			   %exp:cSqlWhere%
			  ORDER BY B1_ZIDMAGE,B1_COD
		EndSQL

/*
		beginSQL Alias "SB1TMP"
			SELECT DISTINCT  SB1.R_E_C_N_O_ RECNOSB1,B1_PESO,B1_ZMAGLOJ,B1_MSBLQL,DA1_ZPESPE,
					B1_COD,B1_DESC,DA1_PRCVEN,
					/*B1_IPI, DA1_ZQATU B2_SALDO,B2_TIPO,B5_ZNMVINH,
					B5_ZCTDESC,B5_ZSAFRA,B5_ZCLASSI,
					B5_ZPRODUT,B5_ZSGUVA1,B5_ZSGUVA2,
					B5_ZSGUVA3,B5_ZSGUVA4,B5_ZSGUVA5,
					B5_ZSGUVA6,B5_ZSGUVA7,B5_ZSGUVA8,
					B5_ZCORPO,B5_ZTANICO,B5_ZACIDEZ,
					B5_ZMADEIR,B5_ZESEVOL,B5_ZDTLREG,
					B5_ZCLALEG,B5_ZCOMPCT,B5_ZGRALCO,
					B5_ZAMADUR,B5_ZESTGUA,B5_ZTEMPER,
					B5_ZPRDNV,B5_ZEMBORI,B5_ZFTROSC,
					B5_ZVLLIQU,B5_ZACTOTA,B5_ZACRESI,
					B5_ZPRODUC,B5_ZTECPRD,Z04_DESCRI,Z04_TIPBBR,Z04_CODIGO,
					Z04_CODREL,Z03_DESCRI,Z03_PAIS,Z03_CODIGO,
					Z03_CODREL,B5_ZNMCMVN,B1_ZIDMAGE,
					CAST(B5_ZAPLGST as varchar(2000)) B5_ZAPLGST,
					CAST(B5_ZARMCRT as varchar(2000)) B5_ZARMCRT,
					CAST(B5_ZDRENGS as varchar(2000)) B5_ZDRENGS,
					CAST(B5_ZPMRLVT as varchar(2000)) B5_ZPMRLVT,
					CAST(B5_ZCVINSN as varchar(2000)) B5_ZCVINSN,
					CAST(B5_ZCRORLE as varchar(2000)) B5_ZCRORLE,
					CAST(B5_ZELABOR as varchar(2000)) B5_ZELABOR,
					CAST(B5_ZCRCLIM as varchar(2000)) B5_ZCRCLIM,
					CAST(B5_ZCRSOLO as varchar(2000)) B5_ZCRSOLO,
					CAST(B5_ZCULTIV as varchar(2000)) B5_ZCULTIV,
					CAST(B5_ZCOMFRU as varchar(2000)) B5_ZCOMFRU,
					YA_ZCODREL, Z02_CODREL,Z02_DESCRI, Z02_CODIGO
			   FROM %table:SB1% SB1
			  INNER JOIN %table:SB5% SB5
			     ON SB5.%notDel%
			    AND B5_FILIAL  		= %xFilial:SB5%
			    AND B5_COD 			= B1_COD
			  INNER JOIN %table:SB2% SB2
			     ON SB2.%notDel%
			    AND B2_FILIAL 		= %xFilial:SB2%
			    AND B2_COD			= B1_COD     		
			    AND B2_LOCAL 		= B1_LOCPAD
			  INNER JOIN %table:DA0% DA0
			     ON DA0.%notDel%
			    AND DA0_FILIAL 		= %xFilial:DA0%
			    AND %exp:Date()% BETWEEN DA0_DATDE AND DA0_DATATE
			    AND %exp:time()% BETWEEN DA0_HORADE	AND DA0_HORATE
			    AND DA0_ATIVO  		= '1'
			    AND DA0_CODTAB 		= %exp:cCdTabPrc%
			  INNER JOIN %table:DA1% DA1
			     ON DA1.%notDel%
			    AND DA1_FILIAL 		= %xFilial:DA1%
			    AND DA1_CODTAB		= DA0_CODTAB
			    AND DA1_CODPRO	 	= B1_COD
			    AND DA1_PRCVEN 		<> 0
			    AND ( DA1_DATVIG = '' OR %exp:Date()% >= DA1_DATVIG   )
			    AND DA1_ATIVO  		= '1'
			   LEFT JOIN %table:Z03% Z03
		  	     ON Z03.%notDel%
			    AND Z03_FILIAL 		= %xFilial:Z03%
			    AND B5_ZPRODUT 		= Z03_CODIGO
			   LEFT JOIN %table:Z02% Z02
			     ON Z02.%notDel%
			    AND Z02_CODIGO 		= Z03_REGIAO
			    AND Z02_FILIAL 		= %xFilial:Z02%
			   LEFT JOIN %table:Z04% Z04
			     ON Z04.%notDel%
			    AND B5_ZCLASSI 		= Z04_CODIGO
			    AND Z04_FILIAL 		= %xFilial:Z04%
			   LEFT JOIN %table:SYA% SYA
			     ON SYA.%notDel%
			    AND YA_CODGI		= Z03_PAIS
			    AND YA_FILIAL 		= %xFilial:SYA%
			  WHERE SB1.%notDel%
			    AND B1_FILIAL  		= %xFilial:SB1%
			    AND B1_TIPO 		= 'ME'
			    AND B1_ZMAGLOJ		<> '' 
			   %exp:cSqlWhere%
			  ORDER BY B1_ZIDMAGE,B1_COD
		EndSQL
*/

		//AND B1_COD 			= '00107613'*/

		//XXX TRATAR VALIDADE DA TABELA DE PREÇO
		Count to nCount
		SB1TMP->(dbGotop())

		If SB1TMP->(Eof())
			//FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Nenhum produto localizado para atualizar ou incluir")
			oActLog:Inf("DECA006","Nenhum produto localizado para atualizar ou incluir")
			lRet	:=	.T.
			Break
		EndIf

		If !lIsBlind
			oGrid:SetMaxMeter(nCount,2)
			ProcessMessage()
		EndIf

		//evita que ao enviar ao servidor seja pedido certificado
		oWsdl:lVerbose 		:= lVerboseOn
		oWsdl:lSSLInsecure 	:= .T.
		oWsdl:nTimeout 		:= 120
		oWsdl:cEncoding 	:= 'ISO-8859-1'
		oWsdl:lRemEmptyTags := .T. // remove elementos complexos para nao serem enviados no xml

		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL(cUrlWSDL)
			cMsgError := "[ERRO parse] Falha ao realizar o parse do xml " + oWsdl:cError
			//FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		// REGRA DE CATEGORIA
		aCategorias	:=	{}


		//Visualiza os webservices disponiveis
		//aOps := oWsdl:ListOperations()

		DBSELECTAREA("Z01")
		dbSetOrder(1)

		nIncrement	:= 0
		nTimeIni	:=	seconds()
		While !SB1TMP->(EOF())
			nIncrement++

			aHashMap	:=	{}
			aadd(aHashMap,{'sessionId',cidsession,'sessionId','P'})

			lUpdaProd	:=	!Empty(SB1TMP->B1_ZIDMAGE)
			cMsgLog		:=	IF(lUpdaProd,"Alterando ","Incluíndo ")+" produto "+SB1TMP->B1_COD
			oActLog:Inf(cMsgLog)
			FWLogMsg("INFO","LAST",'1',"DECA006",,"MAGENTO",cMsgLog)

			If !lIsBlind

				oGrid:SetIncMeter(2,IF(Empty(SB1TMP->B1_ZIDMAGE),"Incluíndo","Alterando")+" "+SB1TMP->B1_COD + "      "+U_TempRest(nCount,nIncrement,nTimeIni)[4])
				ProcessMessage()
				If oGrid:lEnd
					Break
				EndIf
			EndIF

			nAttr := nAttr + 1
			IF lUpdaProd
				// Seta o webservice a ser utilizado
				oWsdl:SetOperation( "catalogProductUpdate" )
//				IF  !oWsdl:SetOperation( "catalogProductUpdate" )
//					cMsgError := '[ERRO UPDATE] Falha ao utilizar webservice' + oWsdl:cError
//					oActLog:Err(cMsgError)
//					FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
//					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
//					Break
//				ENDIF
//				lExecFirI	:=	.F.
			ELSE

				// Seta o webservice a ser utilizado
				oWsdl:SetOperation( "catalogProductCreate" )
//				IF !oWsdl:SetOperation( "catalogProductCreate" )
//					cMsgError := '[ERRO CREATE] Falha ao utilizar webservice' + oWsdl:cError
//					FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
//					oActLog:Err(cMsgError)
//					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
//					Break
//				ENDIF
//				lExecFirU	:=	.F.

			ENDIF
			//aSimple := oWsdl:SimpleInput()
			//Visualiza os tipos complexos disponiveis para o webservice
			//aComplexList := oWsdl:ComplexInput()

			dbSelectArea("Z01")
			dbSetOrder(1)

			aUvas	:=	{}
			For nIUV	:= 1 To 8
				cUvaSql	:=	&("SB1TMP->ZFT_UVA"+cValToChar(nIUV))
				If Z01->(dbSeek(xFilial("Z01")+cUvaSql))
					If !Empty(cUvaSql)
						aadd(aUvas,Alltrim(Z01->Z01_CODREL))
					EndIf
				EndIF
			Next

			// Seta o numero de ocorrencias para cada tipo complexo verificado
			aComplex := oWsdl:NextComplex()
			while ValType( aComplex ) == "A"
				IF aComplex[2] == 'categories'  .AND. aComplex[5] == 'productData#1'
					nOccurs := 0
				ELSEIF aComplex[2] == 'website_ids'  .AND. aComplex[5] == 'productData#1'
					nOccurs := 1
				ELSEIF 	aComplex[2] == 'additional_attributes'  .AND. aComplex[5] == 'productData#1'
					nOccurs := 1
				ELSEIF aComplex[2] == 'multi_data'  .AND. aComplex[5] == 'productData#1.additional_attributes#1'
					If Len(aUvas) > 0
						nOccurs := 1
					Else
						nOccurs := 0
					Endif
				ELSEIF aComplex[2] == 'single_data'  .AND. aComplex[5] == 'productData#1.additional_attributes#1'
					nOccurs := 1
				ELSEIF aComplex[2] == 'associativeMultiEntity'  .AND. aComplex[5] == 'productData#1.additional_attributes#1.multi_data#1'
					If Len(aUvas) > 0
						nOccurs := 1
					Else
						nOccurs := 0
					Endif
				ELSEIF aComplex[2] == 'associativeEntity'  .AND. aComplex[5] == 'productData#1.additional_attributes#1.single_data#1'
					nOccurs := 33 //Numero de atributos
				ELSEIF aComplex[2] == 'stock_data'  .AND. aComplex[5] == 'productData#1'
					nOccurs := 1
				Else
					nOccurs := 0
				ENDIF

				//seta o numero de ocorrencias antes informada
				IF !oWsdl:SetComplexOccurs( aComplex[1], nOccurs )
					cMsgError := "Falha ao setar numero de ocorrencias! Erro do TWSDLMnager: " + oWsdl:cError + "Erro ao definir elemento " + aComplex[2] +	", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrencias"
					SB1->( dbGoTo(SB1TMP->RECNOSB1) )
					SB1->(Reclock("SB1",.F.))
					SB1->B1_ZMMSGIN	:= cMsgError
					SB1->B1_ZMAGSTS	:= '0'
					SB1->(MsUnLock() )
					FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
					Break
				ENDIF

				aComplex := oWsdl:NextComplex()
			EndDO
			aDados := {}
			//aUvas	:=	{}
			For nIUV	:= 1 To 8
				cUvaSql	:=	&("SB1TMP->ZFT_UVA"+cValToChar(nIUV))
				If Z01->(dbSeek(xFilial("Z01")+cUvaSql))
					IF Empty(Z01->Z01_CODREL)
						aDados := {}
						aadd(aDados,cidsession)
						aadd(aDados,'uva')
						aadd(aDados,'0')
						aadd(aDados,AllTrim(Z01->Z01_DESCRI))
						aadd(aDados,'0')
						aadd(aDados,'0')
						aadd(aDados,'4')
						cCodRel := AddOpt(aDados,SB1TMP->RECNOSB1)
						If Empty(cCodRel)
							Break
						EndIf
						Z01->(RecLock("Z01", .F.))
						Z01->Z01_CODREL := cCodRel
						Z01->(MsUnLock())

					ENDIF
				EndIF
			Next

			dbSelectArea("Z02")
			dbSetOrder(1)
			aDados := {}
			IF dbSeek(FWxFilial("Z02")+SB1TMP->Z02_CODIGO) .AND. Empty(Z02->Z02_CODREL)
				aadd(aDados,cidsession)
				aadd(aDados,'regiao')
				aadd(aDados,'0')
				aadd(aDados,AllTrim(Z02->Z02_DESCRI))
				aadd(aDados,'0')
				aadd(aDados,'0')
				aadd(aDados,'4')
				cCodRel := AddOpt(aDados,SB1TMP->RECNOSB1)
				If Empty(cCodRel)
					Break
				EndIf
				DbSelectArea('Z02')
				Z02->(DbSetOrder(1))
				If Z02->(msSeek(xFilial('Z02') +SB1TMP->Z02_CODIGO))
					Z02->(RecLock("Z02", .F.))
					Z02->Z02_CODREL := cCodRel
					Z02->(MsUnLock())
				EndIf

			ENDIF

			dbSelectArea("Z04")
			dbSetOrder(1)
			aDados := {}
			IF dbSeek(FWxFilial("Z04")+SB1TMP->Z04_CODIGO) .AND. Empty(Z04->Z04_CODREL)
				aadd(aDados,cidsession)
				aadd(aDados,'classif')
				aadd(aDados,'0')
				aadd(aDados,AllTrim(Z04->Z04_DESCRI))
				aadd(aDados,'0')
				aadd(aDados,'0')
				aadd(aDados,'4')
				cCodRel := AddOpt(aDados,SB1TMP->RECNOSB1)
				If Empty(cCodRel)
					Break
				EndIf

				Z04->(DbSetOrder(1))
				If Z04->(msSeek(xFilial('Z04') +SB1TMP->Z04_CODIGO))
					Z04->(RecLock("Z04", .F.))
					Z04->Z04_CODREL := cCodRel
					Z04->(MsUnLock())
				EndIf
			ENDIF

			dbSelectArea("Z03")
			dbSetOrder(1)
			aDados := {}
			IF dbSeek(FWxFilial("Z03")+SB1TMP->Z03_CODIGO) .AND. Empty (Z03->Z03_CODREL)
				aadd(aDados,cidsession)
				aadd(aDados,'produtor')
				aadd(aDados,'0')
				aadd(aDados,AllTrim(Z03->Z03_DESCRI))
				aadd(aDados,'0')
				aadd(aDados,'0')
				aadd(aDados,'4')
				cCodRel := AddOpt(aDados,SB1TMP->RECNOSB1)
				If Empty(cCodRel)
					Break
				EndIf

				Z03->(DbSetOrder(1))
				If Z03->(msSeek(xFilial('Z03') + SB1TMP->Z03_CODIGO))
					Z03->(RecLock("Z03", .F.))
					Z03->Z03_CODREL := cCodRel
					Z03->(MsUnLock())
				EndIf
			ENDIF

			dbSelectArea("SYA")
			dbSetOrder(1)
			aDados := {}
			IF dbSeek(FWxFilial("SYA")+SB1TMP->Z03_PAIS) .AND. Empty(SYA->YA_ZCODREL)
				aadd(aDados,cidsession)
				aadd(aDados,'pais')
				aadd(aDados,'0')
				aadd(aDados,AllTrim(SYA->YA_DESCR))
				aadd(aDados,'0')
				aadd(aDados,'0')
				aadd(aDados,'4')
				cCodRelPai := AddOpt(aDados,SB1TMP->RECNOSB1)
				If Empty(cCodRelPai)
					Break
				EndIf
				DbSelectArea('SYA')
				SYA->(DbSetOrder(1))
				If SYA->(msSeek(xFilial('SYA') +SB1TMP->Z03_PAIS))
					SYA->(RecLock("SYA", .F.))
					SYA->YA_ZCODREL := cCodRelPai
					SYA->(MsUnLock())
				EndIf
			ENDIF

			aDados := {}

			//lista de tags simples a ser informadas
			aSimple := oWsdl:SimpleInput()

			IF !Empty(SB1TMP->B1_ZIDMAGE)
				aadd(aHashMap,{'product',AllTrim(SB1TMP->B1_ZIDMAGE),'product','P'})
				aadd(aHashMap,{'identifierType','product','identifierType','P'})
			ENDIF
			aadd(aHashMap,{'string',AllTrim(SB1TMP->B1_ZMAGLOJ),'productData#1.website_ids#1','F'})
			aadd(aHashMap,{'storeView',cStoreView,'storeView','P'})
			aadd(aHashMap,{'type',cTpProduto,'type','P'})//aadd(aHashMap,{'type',cTpProduto,'productData#1','P'})
			aadd(aHashMap,{'set',cSetGpAttr,'set','P'})//aadd(aHashMap,{'set',cSetGpAttr,'productData#1','P'})
			aadd(aHashMap,{'sku',Alltrim(SB1TMP->B1_COD),'sku','P'})//aadd(aHashMap,{'sku',Alltrim(SB1TMP->B1_COD),'productData#1','P'})
			//aadd(aHashMap,{'string','Vinhos','categories#1','F'})
			//aadd(aHashMap,{'string','www.meusite.com','websites#1','F'})
			aadd(aHashMap,{'name',allTrim(sfEncode(SB1TMP->ZFT_DESCR)),'productData#1','F'})
			aadd(aHashMap,{'description',allTrim(sfEncode(SB1TMP->B1_DESC)),'productData#1','F'})
			aadd(aHashMap,{'short_description',alltrim(SB1TMP->ZFT_CTDESC),'productData#1','F'})
			aadd(aHashMap,{'weight',cValtoChar(SB1TMP->B1_PESO),'productData#1','F'})
			aadd(aHashMap,{'status',IF(SB1TMP->B1_MSBLQL=='1','2','1'),'productData#1','F'}) //Somente manda desabilitado se estiver assim no protheus, se nao manda habilitado.
			//aadd(aHashMap,{'url_key','1','productData#1','F'})
			//aadd(aHashMap,{'url_path','1','productData#1','F'})
			aadd(aHashMap,{'visibility',cVisibility,'productData#1','F'})

			aadd(aHashMap,{'price',AllTrim(STR(SB1TMP->DA1_PRCVEN)),'productData#1','F'})

			If SB1TMP->DA1_ZPESPE > 0 .AND.  SB1TMP->DA1_ZPESPE < SB1TMP->DA1_PRCVEN
				aadd(aHashMap,{'special_price',AllTrim(STR(SB1TMP->DA1_ZPESPE)),'productData#1','F'})
			Else
				aadd(aHashMap,{'special_price','','productData#1','F'})
			EndIf


			aadd(aHashMap,{'tax_class_id','0','productData#1','F'})

			//é muito importante manter a paridade entre
			aadd(aHashMap,{'key','safra','productData#1.additional_attributes#1.single_data#1.associativeEntity#1','F'})
			aadd(aHashMap,{'value',AllTrim(SB1TMP->B1_SAFRA),'productData#1.additional_attributes#1.single_data#1.associativeEntity#1','F'})
			aadd(aHashMap,{'key','nome','productData#1.additional_attributes#1.single_data#1.associativeEntity#2','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_DESCR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#2','F'})
			aadd(aHashMap,{'key','detalhamento_regiao','productData#1.additional_attributes#1.single_data#1.associativeEntity#3','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_DTLREG)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#3','F'})
			aadd(aHashMap,{'key','classificacao_legal','productData#1.additional_attributes#1.single_data#1.associativeEntity#4','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_CLALEG)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#4','F'})
			aadd(aHashMap,{'key','composicao_casta','productData#1.additional_attributes#1.single_data#1.associativeEntity#5','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_CASTA)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#5','F'})
			aadd(aHashMap,{'key','amadurecimento','productData#1.additional_attributes#1.single_data#1.associativeEntity#6','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_AMADUR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#6','F'})
			aadd(aHashMap,{'key','estimativa_guarda','productData#1.additional_attributes#1.single_data#1.associativeEntity#7','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_GUARDA)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#7','F'})
			aadd(aHashMap,{'key','temperatura_servico','productData#1.additional_attributes#1.single_data#1.associativeEntity#8','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_TEMPER)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#8','F'})
			aadd(aHashMap,{'key','fechamento_tampa_rosca','productData#1.additional_attributes#1.single_data#1.associativeEntity#9','F'})
			aadd(aHashMap,{'value',IF(SB1TMP->ZFT_ROSCA=='2','Não','Sim'),'productData#1.additional_attributes#1.single_data#1.associativeEntity#9','F'})
			aadd(aHashMap,{'key','aplicacao','productData#1.additional_attributes#1.single_data#1.associativeEntity#10','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_APLGAS)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#10','F'})
			aadd(aHashMap,{'key','harmonizacao_charuto','productData#1.additional_attributes#1.single_data#1.associativeEntity#11','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_CHARUT)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#11','F'})
			aadd(aHashMap,{'key','premiacao_relevante','productData#1.additional_attributes#1.single_data#1.associativeEntity#12','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_PREMIO)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#12','F'})
			aadd(aHashMap,{'key','diretrizes_enogastronomica','productData#1.additional_attributes#1.single_data#1.associativeEntity#13','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_ENOGAS)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#13','F'})
			aadd(aHashMap,{'key','Sobre o produtor','productData#1.additional_attributes#1.single_data#1.associativeEntity#14','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_SOBREP)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#14','F'})
			aadd(aHashMap,{'key','caracteristicas_organolep','productData#1.additional_attributes#1.single_data#1.associativeEntity#15','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_SOBREV)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#15','F'})
			aadd(aHashMap,{'key','elaboracao','productData#1.additional_attributes#1.single_data#1.associativeEntity#16','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_ELABOR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#16','F'})
			aadd(aHashMap,{'key','caracteristica_solo','productData#1.additional_attributes#1.single_data#1.associativeEntity#17','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_SOLO)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#17','F'})
			aadd(aHashMap,{'key','caracteristica_climatica','productData#1.additional_attributes#1.single_data#1.associativeEntity#18','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_CLIMA)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#18','F'})
			aadd(aHashMap,{'key','acidez','productData#1.additional_attributes#1.single_data#1.associativeEntity#19','F'})
			aadd(aHashMap,{'value',listFx(cAcidez,AllTrim(SB1TMP->ZFT_ACIDEZ)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#19','F'})
			aadd(aHashMap,{'key','corpo','productData#1.additional_attributes#1.single_data#1.associativeEntity#20','F'})
			aadd(aHashMap,{'value',listFx(cCorpo,Alltrim(SB1TMP->ZFT_CORPO)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#20','F'})
			aadd(aHashMap,{'key','tanico','productData#1.additional_attributes#1.single_data#1.associativeEntity#21','F'})
			aadd(aHashMap,{'value',listFx(cTanino,aLLtRIM(SB1TMP->ZFT_TANICO)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#21','F'})
			aadd(aHashMap,{'key','madeira','productData#1.additional_attributes#1.single_data#1.associativeEntity#22','F'})
			aadd(aHashMap,{'value',listFx(cMadeira,AllTrim(SB1TMP->ZFT_MADEIR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#22','F'})
			aadd(aHashMap,{'key','estado_evolucao','productData#1.additional_attributes#1.single_data#1.associativeEntity#23','F'})
			aadd(aHashMap,{'value',listFx(cEstEvol,AllTrim(SB1TMP->ZFT_EVOLUC)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#23','F'})
			aadd(aHashMap,{'key','tipo_bebida','productData#1.additional_attributes#1.single_data#1.associativeEntity#24','F'})
			aadd(aHashMap,{'value',listFx(cTpBebida,AllTrim(SB1TMP->Z04_TIPBBR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#24','F'})
			aadd(aHashMap,{'key','classif','productData#1.additional_attributes#1.single_data#1.associativeEntity#25','F'})
			aadd(aHashMap,{'value',AllTrim(StrTran(SB1TMP->Z04_CODREL,'.','')),'productData#1.additional_attributes#1.single_data#1.associativeEntity#25','F'})
			aadd(aHashMap,{'key','produtor','productData#1.additional_attributes#1.single_data#1.associativeEntity#26','F'})
			aadd(aHashMap,{'value',AllTrim(StrTran(SB1TMP->Z03_CODREL,'.','')),'productData#1.additional_attributes#1.single_data#1.associativeEntity#26','F'})
			aadd(aHashMap,{'key','pais','productData#1.additional_attributes#1.single_data#1.associativeEntity#27','F'})
			aadd(aHashMap,{'value',IIf(!EMPTY(SB1TMP->YA_ZCODREL),AllTrim(SB1TMP->YA_ZCODREL),AllTrim(cCodRelPai)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#27','F'})

			aadd(aHashMap,{'key','nome_comercial_vinho','productData#1.additional_attributes#1.single_data#1.associativeEntity#28','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_DESCR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#28','F'})

			aadd(aHashMap,{'key','nome_compacto','productData#1.additional_attributes#1.single_data#1.associativeEntity#29','F'})
			aadd(aHashMap,{'value',Alltrim(sfEncode(SB1TMP->ZFT_CTDESC)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#29','F'})

			aadd(aHashMap,{'key','nome_comercial','productData#1.additional_attributes#1.single_data#1.associativeEntity#30','F'})
			aadd(aHashMap,{'value',Alltrim(sfEncode(SB1TMP->ZFT_DESCR)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#30','F'})

			aadd(aHashMap,{'key','regiao','productData#1.additional_attributes#1.single_data#1.associativeEntity#31','F'})
			aadd(aHashMap,{'value',AllTrim(SB1TMP->Z02_CODREL),'productData#1.additional_attributes#1.single_data#1.associativeEntity#31','F'})

			aadd(aHashMap,{'key','composicao_fruta','productData#1.additional_attributes#1.single_data#1.associativeEntity#32','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_FRUTA)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#32','F'})

			aadd(aHashMap,{'key','alcool','productData#1.additional_attributes#1.single_data#1.associativeEntity#33','F'})
			aadd(aHashMap,{'value',AllTrim(sfEncode(SB1TMP->ZFT_ALCOOL)),'productData#1.additional_attributes#1.single_data#1.associativeEntity#33','F'})

/*			aadd(aHashMap,{'key','percipi','productData#1.additional_attributes#1.single_data#1.associativeEntity#40','F'})
			aadd(aHashMap,{'value',AllTrim(SB1TMP->B1_IPI),'productData#1.additional_attributes#1.single_data#1.associativeEntity#40','F'})
*/	
			If Len(aUvas) > 0
				aadd(aHashMap,{'key','uva','productData#1.additional_attributes#1.multi_data#1.associativeMultiEntity#1','F'})
				aadd(aHashMap,{'string',aUvas,'productData#1.additional_attributes#1.multi_data#1.associativeMultiEntity#1.value#1','A'})
			EndIf

			aadd(aHashMap,{'qty',cValToChar(if(SB1TMP->B2_SALDO<0,0,SB1TMP->B2_SALDO)),'productData#1.stock_data#1','F'})
			aadd(aHashMap,{'is_in_stock','1','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'manage_stock','1','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_manage_stock','1','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'min_qty','0','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_min_qty','1','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'min_sale_qty','50','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_min_sale_qty','1','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_max_sale_qty','1','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'max_sale_qty','100','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'is_qty_decimal','2','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'backorders','1','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_backorders','1','productData#1.stock_data#1','F'})
			//aadd(aHashMap,{'notify_stock_qty','1','productData#1.stock_data#1','F'})
			aadd(aHashMap,{'use_config_notify_stock_qty','1','productData#1.stock_data#1','F'})


			//realiza uma varredura em todos os itens da lista, setando os seus respectivos valores
			For nI:= 1 To Len(aSimple)

				//verifica no hashMap se existe chave correspondente a interação do aSimple
				//caso não seja encontrado uma chave correspondente, será realizado alguns tratamentos
				//no campo para poder setar o valor no XML
				//IF (nPos := aScan( aHashMap, {|aVet| aVet[1] == aSimple[nI][2] .AND. aVet[3] == TextoPos(aSimple[nI][5])})) > 0
				IF (nPos := aScan( aHashMap, {|aVet| aVet[1] == aSimple[nI][2] .AND. Alltrim(aVet[3]) == Alltrim(aSimple[nI][5]) })) > 0
					//verifica na posicao do hashMap se é PAI
					IF aHashMap[nPos][4] = 'P'
						//seta a informação no XML
						IF !oWsdl:SetValue(aSimple[nI][1],aHashMap[nPos][2])
							cMsgError := "[Erro1] Erro ao registrar valor em  geração de XML do campo " + aSimple[nI][2] + " com valor " + aHashMap[nPos][2]  + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
							SB1->( dbGoTo(SB1TMP->RECNOSB1) )
							SB1->(Reclock("SB1",.F.))
							SB1->B1_ZMMSGIN	:= cMsgError
							SB1->B1_ZMAGSTS	:= '0'
							SB1->(MsUnLock() )

							FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
							oActLog:Err(cMsgError)
							MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
							Break
						ENDIF
					ENDIF
					//verifica na posicao do hashMap se é FILHO
					IF aHashMap[nPos][4] = 'F'
						//seta a informação no XML
						IF !oWsdl:SetValPar(aSimple[nI][2],StrTokArr(aSimple[nI][5],'.'),aHashMap[nPos][2])
							cMsgError := "[Erro2] Erro ao registrar valor em  geração de XML do campo " + aSimple[nI][2] + " com valor " + aHashMap[nPos][2]  + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
							SB1->( dbGoTo(SB1TMP->RECNOSB1) )
							SB1->(Reclock("SB1",.F.))
							SB1->B1_ZMMSGIN	:= cMsgError
							SB1->B1_ZMAGSTS	:= '0'
							SB1->(MsUnLock() )
							FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
							oActLog:Err(cMsgError)
							MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
							Break
						ENDIF
					ENDIF
					IF aHashMap[nPos][4] = 'A'
						//seta a informação no XML
						IF !oWsdl:SetValParArray(aSimple[nI][2],StrTokArr(aSimple[nI][5],'.'),aHashMap[nPos][2])
							cMsgError := "[Erro2] Erro ao registrar valor em  geração de XML do campo " + aSimple[nI][2] + " com valor " + aHashMap[nPos][2]  + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
							SB1->( dbGoTo(SB1TMP->RECNOSB1) )
							SB1->(Reclock("SB1",.F.))
							SB1->B1_ZMMSGIN	:= cMsgError
							SB1->B1_ZMAGSTS	:= '0'
							SB1->(MsUnLock() )
							FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
							oActLog:Err(cMsgError)
							MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
							Break
						ENDIF
					ENDIF
				ELSE
					//verifica se o campo da interação é do tipo inteiro ou qualquer outro tipo que não seja string
					//Caso não seja será setado vazio no XML por padrão
					IF	aSimple[nI][6] != 'int'
						IF !oWsdl:SetValPar(aSimple[nI][2],StrTokArr(aSimple[nI][5],'.'),'')
							cMsgError := "[Erro3] Erro ao registrar valor em geração de XML do campo " + aSimple[nI][2] + " com valor vazio"  + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
							SB1->( dbGoTo(SB1TMP->RECNOSB1) )
							SB1->(Reclock("SB1",.F.))
							SB1->B1_ZMMSGIN	:= cMsgError
							SB1->B1_ZMAGSTS	:= '0'
							SB1->(MsUnLock() )
							FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
							oActLog:Err(cMsgError)
							MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
							Break
						ENDIF
					ELSE
						//se a tag da interacao for do tipo 'int' é setado no XML por padrao '0'(ZERO)
						IF !oWsdl:SetValPar(aSimple[nI][2],StrTokArr(aSimple[nI][5],'.'),'0')
							cMsgError := "[Erro4] Erro ao registrar valor em geração de XML do campo " + aSimple[nI][2] + " com valor vazio"  + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
							SB1->( dbGoTo(SB1TMP->RECNOSB1) )
							SB1->(Reclock("SB1",.F.))
							SB1->B1_ZMMSGIN	:= cMsgError
							SB1->B1_ZMAGSTS	:= '0'
							SB1->(MsUnLock() )
							FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
							oActLog:Err(cMsgError)
							MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
							Break
						ENDIF
					ENDIF
				ENDIF
			NEXT

			FWLogMsg("DEBUG","LAST",'1',"LOGIN",,"MAGENTO",oWsdl:GetSoapMsg())
			oActLog:Inf(oWsdl:GetSoapMsg())
			// Envia a mensagem SOAP ao servidor
			IF !oWsdl:SendSoapMsg()
				cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(SB1TMP->RECNOSB1) )
				SB1->(Reclock("SB1",.F.))
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				nTotError	++

				oWsdl:ParseURL(cUrlWsdl)
				SB1TMP->(DbSkip())
				Loop
			ENDIF

			FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapResponse())
			oActLog:Inf(oWsdl:GetSoapResponse())

			cError		:=	""
			cWarning	:= ""
			oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
			If oXML  == NIL
				cMsgError	:=	 "Falha na estrutura do XML de retorno " + chr(13) + chr(10) + cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(SB1TMP->RECNOSB1) )
				SB1->(Reclock("SB1",.F.))
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			EndIf

			If lUpdaProd
				If oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CATALOGPRODUCTUPDATERESPONSE:_RESULT:TEXT == "true"
					cMsgLog	:=	"Produto "+SB1->B1_COD+" atualizado com sucesso!"
					FWLogMsg("INFO","LAST",'1',"DECA006","MAGENTO",cMsgError)
					oActLog:Inf(cMsgLog)

					SB1->(DBGOTO(SB1TMP->RECNOSB1))
					If SB1->B1_ZMAGSTS <> "2"
						SB1->(RecLock("SB1", .F.))
						SB1->B1_ZATZDTM := Date()
						SB1->B1_ZATZHRM := Time()
						SB1->B1_ZMAGSTS	:= '2'
						SB1->B1_ZMMSGIN	:= ''
						SB1->(MsUnLock())
					Endif
				Else
					cMsgError	:=	 "Não foi possível realizar atualização do produto no magento"
					SB1->( dbGoTo(SB1TMP->RECNOSB1) )
					SB1->(Reclock("SB1",.F.))
					SB1->B1_ZMMSGIN	:= cMsgError
					SB1->B1_ZMAGSTS	:= '0'
					SB1->(MsUnLock() )
					FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
					oActLog:Err(cMsgError)
					Break
				EndIf

			Else
				cMsgLog	:=	"Produto "+SB1TMP->B1_COD+" incluído com sucesso!"

				FWLogMsg("INFO","LAST",'1',"DECA006","MAGENTO",cMsgError)
				oActLog:Inf(cMsgLog)
				SB1->(DBGOTO(SB1TMP->RECNOSB1))
				SB1->(RecLock("SB1", .F.))
				SB1->B1_ZIDMAGE := oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CATALOGPRODUCTCREATERESPONSE:_RESULT:TEXT
				SB1->B1_ZDTCTMG := date()
				SB1->B1_ZHRCTMG := Time()
				SB1->B1_ZMAGSTS	:= '1'
				SB1->B1_ZMMSGIN	:=	""
				SB1->(MsUnLock())
			EndIF
			nTotSucess ++


			SB1TMP->(DbSkip())
		EndDo

	End Sequence

	cMsgLog	:=	"Total Produtos Enviados: "+cValToChar(nCount)+"   =>    Sucesso:"+cValToChar(nTotSucess)+"      Erro:"+cValToChar(nTotError)
	FWLogMsg("INFO","LAST",'1',"DECA006","MAGENTO",cMsgError)
	oActLog:Inf(cMsgLog)

	IF Select("SB1TMP")>0
		SB1TMP->(dbCloseArea())
	EndIf
	aSize(aHashMap,0)
	FreeObj(oWsdl)
	FreeObj(oXml)
return nil

/*{Protheus.doc} AddOptionList

@author luis.balsini
@since 22/05/2019
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static function AddOpt(aDados,nRecNOSB1)

	Local lRet := .F.
	Local oWsdl := TWsdlManager():New()
	Local oXml
	Local aSimple := {}
	Local aComplex := {}
	Local aComplexList := {}
	Local aList := {}
	Local aList1 := {}
	Local cXML := ''
	Local cMsgError := ''
	Local nOccurs := 0
	Local nPos    := 0
	Local nX := 1
	Local cValue := ''
	Local oXml	:=	nil

	//evita que ao enviar ao servidor seja pedido certificado
	oWsdl:lVerbose 		:= lVerboseOn
	oWsdl:nTimeout 		:= 120
	oWsdl:lSSLInsecure 	:= .T.
	oWsdl:cEncoding 	:= 'ISO-8859-1'

	//realiza autenticação HTTP
	If lHttpAuth
		oWsdl:SetAuthentication(cHttpUser,cHttpPass)
	EndIf

	// Faz o parse de uma URL
	IF !oWsdl:ParseURL( cUrlWsdl )
		cMsgError := "Erro ao realizar o parse do XML =>"+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	// Seta a operação a ser utilizada
	IF !oWsdl:SetOperation( "catalogProductAttributeAddOption" )
		cMsgError := "Erro ao tentar setar operação do XML =>"+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	// Seleciona o tipo complexo que necessita de definição do número de ocorrências
	aComplex := oWsdl:NextComplex()
	while ValType( aComplex ) == "A"
		IF aComplex[2] == 'catalogProductAttributeOptionLabelEntity'  .AND. aComplex[5] == 'data#1.label#1'
			nOccurs := 1
		ENDIF

		IF !oWsdl:SetComplexOccurs( aComplex[1], nOccurs )
			cMsgError := "Falha ao setar numero de ocorrencias! Erro do TWSDLMnager: " + oWsdl:cError + "Erro ao definir elemento " + aComplex[2] +	", ID " + cValToChar( aComplex[1] ) + ", com " + cValToChar( nOccurs ) + " ocorrencias"+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(nRecNOSB1) )
			SB1->(Reclock("SB1",.F.))
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )
			FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		aComplex := oWsdl:NextComplex()
	EndDO

	aSimple := oWsdl:SimpleInput()

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "sessionId" .AND. aVet[5] == "sessionId" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],aDados[1])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo sessionId não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "attribute" .AND. aVet[5] == "attribute" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],aDados[2])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )

		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "string" .AND. aVet[5] == "data#1.label#1.catalogProductAttributeOptionLabelEntity#1.store_id#1" } )) > 0
		oWsdl:SetValParArray(aSimple[nPos][2],{'data#1','label#1','catalogProductAttributeOptionLabelEntity#1','store_id#1'},{aDados[3]})
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo store_id não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "value" .AND. aVet[5] == "data#1.label#1.catalogProductAttributeOptionLabelEntity#1" } )) > 0
		oWsdl:SetValPar(aSimple[nPos][2],{'data#1','label#1','catalogProductAttributeOptionLabelEntity#1'},aDados[4])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo value não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "order" .AND. aVet[5] == "data#1" } )) > 0
		oWsdl:SetValPar(aSimple[nPos][2],{'data#1'},aDados[5])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo order não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "is_default" .AND. aVet[5] == "data#1" } )) > 0
		oWsdl:SetValPar(aSimple[nPos][2],{'data#1'},aDados[6])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo is_default não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapMsg())
	oActLog:Inf(oWsdl:GetSoapMsg())

	// Envia a mensagem SOAP ao servidor
	IF !oWsdl:SendSoapMsg()
		cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	Else
		cError		:=	""
		cWarning	:= ""
		FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapResponse())
		oActLog:Inf(oWsdl:GetSoapResponse())
		oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno " + chr(13) + chr(10) + cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(nRecNOSB1) )
			SB1->(Reclock("SB1",.F.))
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )

			FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf
		lRet := .T.
	ENDIF

	// Seta a operação a ser utilizada
	IF !oWsdl:SetOperation( "catalogProductAttributeList" )
		cMsgError := "Erro ao tentar setar operação do XML =>"+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	aSimple := oWsdl:SimpleInput()

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "sessionId" .AND. aVet[5] == "sessionId" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],ADados[1])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo sessionId não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "setId" .AND. aVet[5] == "setId" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],aDados[7])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapMsg())
	oActLog:Inf(oWsdl:GetSoapMsg())

	IF !oWsdl:SendSoapMsg()
		cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	Else
		cError		:=	""
		cWarning	:= ""
		FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapResponse())
		oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno " + chr(13) + chr(10) + cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(nRecNOSB1) )
			SB1->(Reclock("SB1",.F.))
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )

			FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		aList :=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CATALOGPRODUCTATTRIBUTELISTRESPONSE:_RESULT:_ITEM

		FOR nX := 1 TO Len(aList)
			aList1 := XmlChildEx(aList[nX],"_CODE")
			cValue := XmlChildEx(aList1,"TEXT")
			IF cValue == aDados[2]
				exit
			ENDIF
		Next
	ENDIF

	// Seta a operação a ser utilizada
	IF !oWsdl:SetOperation( "catalogProductAttributeOptions" )
		cMsgError := "Erro ao tentar setar operação do XML =>"+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	aSimple := oWsdl:SimpleInput()

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "sessionId" .AND. aVet[5] == "sessionId" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],ADados[1])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo sessionId não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "attributeId" .AND. aVet[5] == "attributeId" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],aDados[2])
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "storeView" .AND. aVet[5] == "storeView" } )) > 0
		oWsdl:SetValue(aSimple[nPos][1],'0')
	ELSE
		cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	ENDIF

	FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapMsg())
	oActLog:Inf(oWsdl:GetSoapMsg())

	IF !oWsdl:SendSoapMsg()
		cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
		SB1->( dbGoTo(nRecNOSB1) )
		SB1->(Reclock("SB1",.F.))
		SB1->B1_ZMMSGIN	:= cMsgError
		SB1->B1_ZMAGSTS	:= '0'
		SB1->(MsUnLock() )

		FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
		oActLog:Err(cMsgError)
		MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
		Break
	Else
		cError		:=	""
		cWarning	:= ""
		FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapResponse())
		oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
		If oXML  == NIL
			cMsgError	:=	 "Falha na estrutura do XML de retorno " + chr(13) + chr(10) + cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(nRecNOSB1) )
			SB1->(Reclock("SB1",.F.))
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )

			FWLogMsg("ERROR","LAST",'1',"DECA006",,"MAGENTO",cMsgError)
			oActLog:Err(cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		EndIf

		aList :=	oXML:_SOAP_ENV_ENVELOPE:_SOAP_ENV_BODY:_NS1_CATALOGPRODUCTATTRIBUTEOPTIONSRESPONSE:_RESULT:_ITEM

		FOR nX := 1 TO Len(aList)
			aList1 := XmlChildEx(aList[nX],"_LABEL")
			cValue := XmlChildEx(aList1,"TEXT")
			IF cValue == AllTrim(aDados[4])
				aList1 := XmlChildEx(aList[nX],"_VALUE")
				cValue =  XmlChildEx(aList1,"TEXT")
				exit
			ENDIF
		Next
	ENDIF
	FreeObj(oWsdl)
	FreeObj(oXml)
return cValue

/*{Protheus.doc} TextoPos

@author luis.balsini
@since 22/05/2019
@version undefined
@return return, return_description
@example
(examples)
@see (links_or_references)
*/
static function TextoPos(ctexto)

	Local aArr := {}
	Local cRet := ''

	aArr := StrTokArr(ctexto,'.')
	cRet := aArr[Len(aArr)]

return cRet

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

/*/{Protheus.doc} excluir

Realiza e exclusão dos produtos no site

@author charles.totvs
@since 27/05/2019
@version undefined
@param sessionid, , descricao
@return return, return_description
@example
(examples)
@see (links_or_references)
/*/
Static function excluir(sessionid,lEnd)
	Local  lRet := .F.
	Local  aSimple := {}
	Local  nPos := 0
	Local oWsdl := TWsdlManager():New()
	Local nCount := 0
	Local oXml	:=	nil
	Local nTotalSuc	:= 0
	Local nTotalErr	:=	0

	Begin sequence
		FWLogMsg("INFO","",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Iniciado avaliação para exclusão dos produtos no Magento")

		If !lIsBlind
			oGrid:SetIncMeter(1,"Verificando produtos a serem excluídos")
			ProcessMessage()
			If oGrid:lEnd
				Break
			EndIf
		EndIf

		//realiza varedura de produtos na base do sistema, trazendo todos
		beginSQL Alias "TMP"
			SELECT	SB1.R_E_C_N_O_ RECNOSB1,	B1_ZIDMAGE, B1_COD
			  FROM %table:SB1% SB1
			 INNER JOIN %table:SB2% SB2
			    ON SB2.%notDel%
			   AND B1_COD     = B2_COD
			   AND B1_LOCPAD  = B2_LOCAL
			 INNER JOIN %table:SB5% SB5
			    ON SB5.%notDel%
			   AND B5_FILIAL  = %xFilial:SB5%
			   AND B1_COD     = B5_COD
			  LEFT JOIN %table:DA1% DA1
			    ON DA1.%notDel%
			   AND DA1_FILIAL 		= %xFilial:DA1%
			   AND DA1_CODTAB		= %exp:cCdTabPrc%
			   AND DA1_CODPRO	 	= B1_COD
			 WHERE SB1.%notDel%
			   AND B1_FILIAL  		= %xFilial:SB1%
			   AND B1_ZIDMAGE 		<> ''
			   AND B1_TIPO 		= 'ME'
			   AND DA1_FILIAL IS NULL
			 ORDER BY B1_COD
		EndSQL
		Count to nCount
		TMP->(dbGoTop())

		If TMP->(Eof())
			oActLog:Inf("DECA006","Nenhum produto a ser enviado para exclusão")
			FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",)
			lRet	:=	.T.
			Break
		EndIf

		If !lIsBlind
			oGrid:SetMaxMeter(nCount,2,)
			ProcessMessage()
		EndIf

		//evita que ao enviar ao servidor seja pedido certificado
		oWsdl:lVerbose 		:= lVerboseOn
		oWsdl:lSSLInsecure 	:= .T.
		oWsdl:cEncoding 	:= 'ISO-8859-1'
		oWsdl:nTimeOut		:= 120

		//realiza autenticação HTTP
		If lHttpAuth
			oWsdl:SetAuthentication(cHttpUser,cHttpPass)
		EndIf

		// Faz o parse de uma URL
		IF !oWsdl:ParseURL( cUrlWsdl )
			cMsgError	:=	"Erro ao realizar o parse da URL => "+ oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(TMP->RECNOSB1) )
			SB1->(RecLock("SB1", .F.) )
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )
			oActLog:Err(cMsgError)
			FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		// Seta a operação a ser utilizada
		IF !oWsdl:SetOperation( "catalogProductDelete" )
			cMsgError	:= "Erro ao setar operação catalogProductDelete => "+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
			SB1->( dbGoTo(TMP->RECNOSB1) )
			SB1->(RecLock("SB1", .F.) )
			SB1->B1_ZMMSGIN	:= cMsgError
			SB1->B1_ZMAGSTS	:= '0'
			SB1->(MsUnLock() )
			oActLog:Err(cMsgError)
			FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
			MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
			Break
		ENDIF

		DbSelectArea('DA1')
		DbSelectArea('SB1')
		While TMP->(!EOF())
			If !lIsBlind
				oGrid:SetIncMeter(2,"Excluindo produto "+TMP->B1_COD)
				ProcessMessage()
				If oGrid:lEnd
					Break
				EndIf
			EndIf

			aSimple := oWsdl:SimpleInput()

			IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "sessionId" .AND. aVet[5] == "sessionId" } )) == 0
				cMsgError := "Posição " + nPos + "na lista simples para campo sessionId não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(TMP->RECNOSB1) )
				SB1->(RecLock("SB1", .F.) )
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				oActLog:Err(cMsgError)
				FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			ENDIF
			oWsdl:SetValue(aSimple[nPos][1],sessionid)

			IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "product" .AND. aVet[5] == "product" } )) == 0
				cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(TMP->RECNOSB1) )
				SB1->(RecLock("SB1", .F.) )
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				oActLog:Err(cMsgError)
				FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			ENDIF
			oWsdl:SetValue(aSimple[nPos][1],AllTrim(TMP->B1_ZIDMAGE))

			IF (nPos := aScan( aSimple, {|aVet| aVet[2] == "identifierType" .AND. aVet[5] == "identifierType" } )) == 0
				cMsgError := "Posição " + nPos + "na lista simples para campo attribute não existe " + chr(13)+chr(10) + oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(TMP->RECNOSB1) )
				SB1->(RecLock("SB1", .F.) )
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				oActLog:Err(cMsgError)
				FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				Break
			ENDIF
			oWsdl:SetValue(aSimple[nPos][1],'product')

			FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapMsg())
			oActLog:Inf(oWsdl:GetSoapMsg())

			IF !oWsdl:SendSoapMsg()
				cMsgError	:=	 "Falha no envio dos dados para o servidor do Magento"+chr(13)+chr(10)+oWsdl:cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(TMP->RECNOSB1) )
				SB1->(RecLock("SB1", .F.) )
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				//MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))
				TMP->(DbSkip())
				Loop
			ENDIF

			cError		:=	""
			cWarning	:= ""
			FWLogMsg("DEBUG","LAST",'1',"DECA006",,"MAGENTO",oWsdl:GetSoapResponse())
			oActLog:Inf(oWsdl:GetSoapResponse())

			oXml := XmlParser( oWsdl:GetSoapResponse() , "", @cError, @cWarning )
			If oXML  == NIL
				cMsgError	:=	 "Falha na estrutura do XML de retorno " + chr(13) + chr(10) + cError+" - "+ProcName()+"/"+cValToChar(ProcLine())
				SB1->( dbGoTo(TMP->RECNOSB1) )
				SB1->(RecLock("SB1", .F.) )
				SB1->B1_ZMMSGIN	:= cMsgError
				SB1->B1_ZMAGSTS	:= '0'
				SB1->(MsUnLock() )
				FWLogMsg("ERROR","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO",cMsgError)
				oActLog:Err(cMsgError)
				MsgStop(cMsgError,"Erro - "+ProcName()+"/"+cValToChar(ProcLine()))

				Break
			EndIf

			SB1->( dbGoTo(TMP->RECNOSB1) )
			SB1->(RecLock("SB1", .F.) )
			SB1->B1_ZIDMAGE := ''
			SB1->B1_ZMAGSTS	:= '1'
			SB1->B1_ZMMSGIN	:= ''
			SB1->B1_ZMDTEXC	:= Date()
			SB1->(MsUnLock() )
			FWLogMsg("INFO","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Produto "+SB1->B1_COD+" excluído com sucesso")
			oActLog:Err("DECA006","Produto "+SB1->B1_COD+" excluído com sucesso")

			TMP->(DbSkip())
		EndDo
		lRet := .T.
	End Sequence

	FWLogMsg("INFO","LAST",'1',"EXCLUIR_PRODUTO",,"MAGENTO","Finalizado rotina de exclusão de produtos no magento")
	TMP->(dbCloseArea())
	FreeObj(oWsdl)
	FreeObj(oXml)
return lRet


Static Function sfEncode(cInStr)

	Local 	cOutStr 	:= ""

	If !Empty(cInStr)
		cOutStr := "<![CDATA["
		cOutStr += Alltrim(cInStr)
		cOutStr += "]]>"
	Endif
Return cOutStr
