#Include "totvs.ch"
#Include "TopConn.ch"
#include "RPTDEF.CH"

/*/{Protheus.doc} MLCTBR01
Relat�rio de Plano de Contas x Plano Referencial
@type function
@version 
@author Marcelo Alberto Lauschner
@since 30/04/2020
@return return_type, return_description
/*/
User Function MLCTBR01()

	Local aArea   := GetArea()
	Local oReport
	Local lEmail  := .F.
	Local cPara   := ""
	Private cPerg := ""

	//Cria as defini��es do relat�rio
	oReport := fReportDef()

	//Ser� enviado por e-Mail?
	If lEmail
		oReport:nRemoteType := NO_REMOTE
		oReport:cEmail := cPara
		oReport:nDevice := 3 //1-Arquivo,2-Impressora,3-email,4-Planilha e 5-Html
		oReport:SetPreview(.F.)
		oReport:Print(.F., "", .T.)
		//Sen�o, mostra a tela
	Else
		oReport:PrintDialog()
	EndIf

	RestArea(aArea)
Return

/*-------------------------------------------------------------------------------*
 | Func:  fReportDef                                                             |
 | Desc:  Fun��o que monta a defini��o do relat�rio                              |
*-------------------------------------------------------------------------------*/

Static Function fReportDef()

	Local oReport
	Local oSectDad := Nil
	Local oBreak := Nil

	//Cria��o do componente de impress�o
	oReport := TReport():New(	"MLCTBR01",;		//Nome do Relat�rio
		"Rel Plano Contas X Referencial",;		//T�tulo
		cPerg,;		//Pergunte ... Se eu defino a pergunta aqui, ser� impresso uma p�gina com os par�metros, conforme privil�gio 101
		{|oReport| fRepPrint(oReport)},;		//Bloco de c�digo que ser� executado na confirma��o da impress�o
		)		//Descri��o
	oReport:SetTotalInLine(.F.)
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize(9) //Folha A4
	oReport:SetLandscape()

	//Criando a se��o de dados
	oSectDad := TRSection():New(	oReport,;		//Objeto TReport que a se��o pertence
		"Dados",;		//Descri��o da se��o
		{"QRY_AUX"})		//Tabelas utilizadas, a primeira ser� considerada como principal da se��o
	oSectDad:SetTotalInLine(.F.)  //Define se os totalizadores ser�o impressos em linha ou coluna. .F.=Coluna; .T.=Linha

	//Colunas do relat�rio
	TRCell():New(oSectDad, "CT1_CONTA"	, "QRY_AUX", "Cod Conta"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_DESC01"	, "QRY_AUX", "Desc Moeda 1"	, /*Picture*/, 40, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_CLASSE"	, "QRY_AUX", "Classe Conta"	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_BLOQ"	, "QRY_AUX", "Cta Bloq"		, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_CTASUP"	, "QRY_AUX", "Cta Superior"	, /*Picture*/, 20, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_DTEXIS"	, "QRY_AUX", "Dt Ini Exist"	, /*Picture*/, 8, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_SPEDST"	, "QRY_AUX", "SPED Sint."	, /*Picture*/, 1, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CT1_NATCTA"	, "QRY_AUX", "Nat. Conta"	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CVD_CODPLA"	, "QRY_AUX", "Plano Ref."	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
	TRCell():New(oSectDad, "CVD_CTAREF"	, "QRY_AUX", "Conta Ref."	, /*Picture*/, 32, /*lPixel*/,/*{|| code-block de impressao }*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign */,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Return oReport

/*/{Protheus.doc} fRepPrint
Fun��o que imprime o relat�rio 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 30/04/2020
@param oReport, object, param_description
@return return_type, return_description
/*/
Static Function fRepPrint(oReport)
	Local aArea    := GetArea()
	Local cQryAux  := ""
	Local oSectDad := Nil
	Local nAtual   := 0
	Local nTotal   := 0

	//Pegando as se��es do relat�rio
	oSectDad := oReport:Section(1)

	//Montando consulta de dados
	cQryAux := ""
	cQryAux += "SELECT"
	cQryAux += "    CT1_CONTA,"
	cQryAux += "    CT1_DESC01,"
	cQryAux += "    CASE WHEN CT1_CLASSE = '1' THEN '1=SINT�TICA' WHEN CT1_CLASSE = '2' THEN '2=ANAL�TICA' "
	cQryAux += "         ELSE ' ' END CT1_CLASSE,"
	cQryAux += "    CASE WHEN CT1_BLOQ = '1' THEN '1=BLOQUEADA' WHEN CT1_BLOQ = '2' THEN '2=N�O BLOQUEADA' ELSE ' ' END CT1_BLOQ,"
	cQryAux += "    CT1_CTASUP,"
	cQryAux += "    CT1_DTEXIS,"
	cQryAux += "    CT1_SPEDST,"
	cQryAux += "    CASE WHEN CT1_NATCTA = '01' THEN '01=CONTA ATIVO' "
    cQryAux += "         WHEN CT1_NATCTA = '02' THEN '02=CONTA PASSIVO'"
    cQryAux += "         WHEN CT1_NATCTA = '03' THEN '03=PATRIMONIO LIQUIDO'"
    cQryAux += "         WHEN CT1_NATCTA = '04' THEN '04=CONTA DE RESULTADO'"
	cQryAux += "         WHEN CT1_NATCTA = '05' THEN '05=CONTA DE COMPENSA��O'"
    cQryAux += "         WHEN CT1_NATCTA = '09' THEN '09=OUTRAS' ELSE  ' ' END CT1_NATCTA,"
	cQryAux += "    COALESCE(CVD_CODPLA, ' ') CVD_CODPLA,"
	cQryAux += "    COALESCE(CVD_CTAREF, ' ') CVD_CTAREF"
	cQryAux += "  FROM " + RetSqlName("CT1") + " CT1"
	cQryAux += "  LEFT JOIN " + RetSqlName("CVD") + " CVD "
	cQryAux += "    ON CVD.D_E_L_E_T_ = ' '"
	cQryAux += "                            AND CVD_CONTA = CT1_CONTA"
	cQryAux += "                            AND CVD_FILIAL = ' '"
	cQryAux += " WHERE CT1.D_E_L_E_T_ = ' '"
	cQryAux += "   AND CT1_FILIAL = '" + xFilial("CT1")+ "'"
	cQryAux += "ORDER BY 1,2 "
	cQryAux := ChangeQuery(cQryAux)

	//Executando consulta e setando o total da r�gua
	TCQuery cQryAux New Alias "QRY_AUX"
	Count to nTotal
	oReport:SetMeter(nTotal)
	TCSetField("QRY_AUX", "CT1_DTEXIS", "D")

	//Enquanto houver dados
	oSectDad:Init()
	QRY_AUX->(DbGoTop())
	While ! QRY_AUX->(Eof())
		//Incrementando a r�gua
		nAtual++
		oReport:SetMsgPrint("Imprimindo registro "+cValToChar(nAtual)+" de "+cValToChar(nTotal)+"...")
		oReport:IncMeter()

		//Imprimindo a linha atual
		oSectDad:PrintLine()

		QRY_AUX->(DbSkip())
	EndDo
	oSectDad:Finish()
	QRY_AUX->(DbCloseArea())

	RestArea(aArea)
Return
