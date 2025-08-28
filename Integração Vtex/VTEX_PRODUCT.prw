#INCLUDE "totvs.ch"

User Function VTEX_PRODUCT()

	RpcSetType(3)
	RpcSetEnv("01")

	U_VTEX001("")

	RpcClearEnv()

Return

User Function VTEX001()

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
	oActLog:Start("VTEX001"," Iniciando integração com Vtex",)
	FWLogMsg("INFO","",'1',"VTEX001",,"Vtex"," Iniciando integração com Vtex")

	oActLog:Inf("VTEX001",If(lIsBlind,"Executado VIA JOB","Executado manualmente com interface"))
	FWLogMsg("INFO","LAST",'1',"VTEX001",,"Vtex",If(lIsBlind,"Executando via JOB","Executando em tela"))

	If lIsBlind

		U_RunV001()

	Else

		cDescDet	:= "Rotina responsável por realizar o envio a atualização dos produtos para o Vtex"
		oGrid		:=	FWGridProcess():New(   "VTEX001",  "Enviar Produtos para Vtex", cDescDet, {|lEnd| U_RunV001(@lEnd)}, "")
		oGrid:SetMeters(2)
		//oGrid:SetThreadGrid(1)
		oGrid:SetAbort(.T.)
		oGrid:Activate()

	EndIf

	oActLog:Fin()
	FWLogMsg("INFO","LAST",'1',"VTEX001",,"Vtex","Finalizado integração com Vtex")

	UnLockByName(cLockName,.T.,.F.)
	U_DelUsrLock(cLockName)

Return

User Function RunV001(lEnd)

	Local cSqlWhere		:=	""
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

    Local bObject := {|| JsonObject():New()}
    Local oJson   := Eval(bObject)

    local oRestClient as object
    local cPath := "/api/catalog/pvt/product"
    local aHeadOut as array
    local cBody := ""

	Private cCdTabPrc 	:= GETMV("MA_CODTABP"	,,"107")
	 Private cURL  	    := GetMv("MA_VTEXURL"	,,"https://decantervinhos.myvtex.com")
	// Private cAppKey	    := GetMv("MA_VTEXKEY"	,,"vtexappkey-decantervinhos-JQBAGL")
	// Private cAppToken	:= GetMv("MA_VTEXTOKEN"	,,"KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")

	// Private cAcidez		:= GetMv("MA_ACIDEZ"	,,"FRS=16460;MFR=16459;PFR=16458")
	// Private cCorpo		:= GetMv("MA_CORPO"	    ,,"CRP=16452;LEV=16451;RBT=16453")
	// Private cTanino		:= GetMv("MA_TANINO"    ,,"MTN=16456;PTN=16455;STN=16454;TNC=16457")
	// Private cMadeira	:= GetMv("MA_MADEIRA"   ,,"CMD=16463;PMD=16462;SMD=16461")
	// Private cEstEvol	:= GetMv("MA_ESTEVOL"   ,,"BBR=16466;BGR=16465;GRD=16464")
	// Private cTpBebida	:= GetMv("MA_TPBEBIDA"  ,,"AZT=16470;DST=16468;LCR=16469;VNH=16467")
	// Private cTpProduto  := GetMv("MA_TPPRODUTO" ,,"simple")
	// Private cSetGpAttr  := GetMv("MA_TPPRODUTO" ,,"4")
	// Private cVisibility := GetMv("MA_TPPRODUTO" ,,"4")
	// Private cStoreView  := GetMv("MA_STOREVIEW" ,,"0")
	//Private cStatus     	:= GetMv("MA_STATUS"    ,,"1")// 2 = desabilitado

	Begin Sequence
		//É aberta uma unica sessao para realizar o processamento no Vtex

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Excluindo Logs antigos")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

		//Mantem os logs por apenas 1 semana
		aArqErase := directory("\log\xmpad\VTEX001*.log")
		For nO := 1 To Len(aArqErase)
			If aArqErase[nO][3] <= dDataBase-7
				FERASE("\log\xmpad\"+aArqErase[nO][1])
			EndIf
		Next

		If !lIsBlind
			oGrid:SetMaxMeter(4,1,"Realizando autenticação com Vtex")
			oGrid:SetIncMeter(1)
			ProcessMessage()
		EndIf

        //TODO
		// // Verifica os produtos que foram enviados para o Vtex e precisam ser excluidos
		// IF !excluir(cidsession)
		// 	Break
		// ENDIF

		If !lIsBlind
			oGrid:SetIncMeter(1,"Verificando produtos a serem enviados ao Vtex")
			oGrid:SetIncMeter(2,"")
			ProcessMessage()
		EndIf

		// cSqlWhere	:=	"%"
		// If !Empty(cCodProdAt)
		// 	cSqlWhere	+=	" AND B1_COD = '"+cCodProdAt+"' "
		// EndIf
		// cSqlWhere	+=  "%"

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

		//XXX TRATAR VALIDADE DA TABELA DE PREÇO
		Count to nCount
		SB1TMP->(dbGotop())

		If SB1TMP->(Eof())
			oActLog:Inf("VTEX001","Nenhum produto localizado para atualizar ou incluir")
			lRet	:=	.T.
			Break
		EndIf

		If !lIsBlind
			oGrid:SetMaxMeter(nCount,2)
			ProcessMessage()
		EndIf

        aHeadOut := {} 
        Aadd(aHeadOut, "X-VTEX-API-AppKey: vtexappkey-decantervinhos-JQBAGL")
        Aadd(aHeadOut, "X-VTEX-API-AppToken: KIKYMSITHSGOAKRLOYMUXCLKOUYDFPHFOBUOURPFHXHYTBJPVERJCHRIWAKRTFORLAZYPDQXJGNZUNRMKJIAYXDHKLSUGXLBJQNSCLZRNUAVTRNIIYHKXNSNWSODKWQM")
		
		While !SB1TMP->(EOF())
            oJson["Name"]           := SB1TMP->B1_DESC
            oJson["CategoryId"]     := 1
            oJson["BrandId"]        := 2000000
            oJson["DepartmentId"]   := 1
            oJson["CategoryPath"]   :="Storage/Hard Drive"
            oJson["BrandName"]      :="Sample Brand"
            oJson["LinkId"]         :="stefan-janoski-canvas-varsity-red"
            oJson["RefId"]          :="sr_1_90"
            oJson["IsVisible"]      :=false
            oJson["Description"]    := SB1TMP->ZFT_DESCR
            oJson["DescriptionShort"]:= "TESTE API"
            oJson["ReleaseDate"]    := "2019-01-01T00:00:00"
            oJson["KeyWords"]       := "Zoom,Stefan,Janoski"
            oJson["Title"]          := "TESTE API"
            oJson["IsActive"]       := true
            oJson["TaxCode"]        := "12345"
            oJson["MetaTagDescription"]:= "TESTE API."
            oJson["SupplierId"]     := null
            oJson["ShowWithoutStock"]:= true
            oJson["AdWordsRemarketingCode"]:= "elit Excepteur sunt"
            oJson["LomadeeCampaignCode"]:= "enim consectetur Duis"
            oJson["Score"]:= 1        
            cBody := oJson:ToJson()

            oRestClient := FWRest():New(cUrl)
        
            oRestClient:SetPath(cPath)
            oRestClient:SetPostParams("body")
            oRestClient:SetPostParams(cBody)
        
            if oRestClient:Post(aHeadOut)
                sPostRet := oRestClient:GetResult()
                If FWJsonDeserialize(sPostRet,@oObj)
                    If SubStr(oRestClient:GetLastError(),1,3) == '200' .and. ValType(oObj) == "O"
                        cProdID := oObj:Id
                    Else
                        varinfo("HttpPost Failed.", sPostRet)
                    EndIf
                Else
                    Count("Erro no Deserialize!")
                EndIf
            else
                Conout("Erro")
                conout(oRestClient:GetLastError())
                conout(oRestClient:GetResult())  
            Endif
            
			SB1TMP->(DbSkip())
            FreeObj(oRestClient)
		EndDo

	End Sequence

	cMsgLog	:=	"Total Produtos Enviados: "+cValToChar(nCount)+"   =>    Sucesso:"+cValToChar(nTotSucess)+"      Erro:"+cValToChar(nTotError)
	FWLogMsg("INFO","LAST",'1',"VTEX001","Vtex",cMsgError)
	oActLog:Inf(cMsgLog)

	IF Select("SB1TMP")>0
		SB1TMP->(dbCloseArea())
	EndIf
	aSize(aHashMap,0)
	FreeObj(oWsdl)
	FreeObj(oXml)
return nil

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
Return { "P", "VTEX001'", "", {}, "" }
