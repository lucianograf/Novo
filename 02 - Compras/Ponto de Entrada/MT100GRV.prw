#include "topconn.ch"

/*/{Protheus.doc} XMT100GRV
Ponto de entrada durante grava��o do Documento de Entrada - Se exclus�o Doc.Entrada ir� excluir o Lan�amento cont�bil 
@type function
@version 
@author Marcelo Alberto Lauschner
@since 27/08/2020
@return return_type, return_description
@example
(User Function MT100GRV()Local lExp01 := PARAMIXB[1]Local lExp02 := .T.//Valida��es do usu�rioReturn lExp01 )
@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6085394)
/*/
User Function XMT100GRV()
	
	// lRetGrv := ExecBlock("MT100GRV",.F.,.F.,{lDeleta})
	
	Local	aAreaOld		:= GetArea()
	Local	lRetGrv			:= .T.
	Local 	aItens 			:= {}
	Local	aCab   			:= {}
	Local	cQry			:= ""
	Local	lVldDeleta		:= !Empty(SF1->F1_DTLANC) .And. ParamIxb[1]
	Local	aRecSD1			:= {}
	
    Local	iZ
	
	Private lMsErroAuto
	Private lMsHelpAuto 	:= .F.
	
	If lVldDeleta
		
		If Empty(SF1->F1_DTLANC)
			RestArea(aAreaOld)
			Return lRetGrv
		Endif
		
		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)
		While !Eof() .And. xFilial("SD1") == SD1->D1_FILIAL .And. SD1->D1_DOC == SF1->F1_DOC .And. ;
				SD1->D1_SERIE == SF1->F1_SERIE .And. SD1->D1_FORNECE == SF1->F1_FORNECE .And. ;
				SD1->D1_LOJA == SF1->F1_LOJA
			Aadd(aRecSD1,SD1->(Recno()))
			dbSelectArea("SD1")
			dbSkip()
		EndDo 
		
		cQry += "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,"
		cQry += "        CT2_ORIGEM,CT2_HIST,CT2_CLVLDB,CT2_CLVLCR,CT2_CCC,CT2_CCD "
		cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
		cQry += " WHERE (R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SF1' "
		cQry += "                        AND CTK_RECORI = '"+Alltrim(Str(SF1->(Recno())))+"') "
		cQry += "    OR R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SD1' "
		cQry += "                        AND CTK_RECORI IN( "
		
		For iZ := 1 To Len(aRecSD1)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'"+Alltrim(Str(aRecSD1[iZ]))+"' "
		Next
		cQry += "))"
		
		cQry += "  ) AND D_E_L_E_T_ = ' ' "
		
		TCQUERY cQry NEW ALIAS "QCTK"
		
		If !Eof()
			aCab	:=  { 	{'DDATALANC' ,STOD(QCTK->CT2_DATA) 	,NIL},;
				{'CLOTE' 	 	,QCTK->CT2_LOTE 	,NIL},;
				{'CSUBLOTE'  	,QCTK->CT2_SBLOTE	,NIL},;
				{'CDOC' 	 	,QCTK->CT2_DOC		,NIL}}
		Endif
		
		DbSelectArea("QCTK")
		DbGotop()
		While !Eof()
			
			aAdd(aItens,{;
             	{'CT2_FILIAL'  	,QCTK->CT2_FILIAL  	, NIL},;
				{'CT2_LINHA'  	,QCTK->CT2_LINHA   	, NIL},;
				{'CT2_MOEDLC'  	,QCTK->CT2_MOEDLC  	, NIL},;
				{'CT2_DC'   	,QCTK->CT2_DC		, NIL},;
				{'CT2_DEBITO'  	,QCTK->CT2_DEBITO	, NIL},;
				{'CT2_CREDIT'  	,QCTK->CT2_CREDIT	, NIL},;
				{'CT2_VALOR'  	,QCTK->CT2_VALOR	, NIL},;
				{'CT2_HIST'  	,QCTK->CT2_HIST 	, NIL},;
				{'CT2_CCD'  	,QCTK->CT2_CCD		, NIL},;
				{'CT2_CCC'  	,QCTK->CT2_CCC		, NIL},;
				{'CT2_CLVLDB'  	,QCTK->CT2_CLVLDB 	, NIL},;
				{'CT2_CLVLCR' 	,QCTK->CT2_CLVLCR	, NIL} } )
			
			//	Aadd(aItens,{	{"CT2_LINHA"	,QCTK->CT2_LINHA	,NIL				},;
			//		{"LINPOS"		,"CT2_LINHA"		,QCTK->CT2_LINHA	}})
			QCTK->(DbSkip())
		Enddo
		QCTK->(DbCloseArea())
		
		// Se n�o houveram registros retorna antes de tentar excluir o lana�mento cont�bil
		If Len(aItens) == 0
			MsgAlert("N�o foi localizada informa��o de contabiliza��o desta nota fiscal para que fosse feita a exclus�o cont�bil desta nota.","Sem registro de contabiliza��o")
			RestArea(aAreaOld)
			Return .T.
		Endif
		
		// Guardo variaveis publicas
		nModBk	:= nModulo
		cModBk	:= cModulo
		xBkTTS	:= __TTSInUse
		// Altero variaveis publicas
		nModulo	:= 34
		cModulo	:= "CTB"
		__TTSInUse := .F.
		
		// Executa a exclus�o
		CTBA102(aCab ,aItens, 5)
		
		// Restauro as variaveis
		__TTSInUse := xBkTTS
		nModulo	:= nModBk
		cModulo	:= cModBk
		
		// Verifica se o lana�mento efetivamente foi excluido
		cQry := "SELECT CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_FILIAL,CT2_LINHA,CT2_MOEDLC,CT2_DC,CT2_DEBITO,CT2_CREDIT,CT2_VALOR,"
		cQry += "        CT2_ORIGEM,CT2_HIST,CT2_CLVLDB,CT2_CLVLCR,CT2_CCC,CT2_CCD "
		cQry += "  FROM "+RetSqlName("CT2") + " CT2 "
		cQry += " WHERE (R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SF1' "
		cQry += "                        AND CTK_RECORI = '"+Alltrim(Str(SF1->(Recno())))+"') "
		cQry += "    OR R_E_C_N_O_ IN(SELECT CTK_RECDES "
		cQry += "                       FROM "+RetSqlName("CTK") + " CTK "
		cQry += "                      WHERE CTK_LOTE = '8810' "
		cQry += "                        AND CTK_FILIAL = '"+xFilial("CTK")+"' "
		cQry += "                        AND CTK_DATA = '"+DTOS(SF1->F1_DTLANC)+"' "
		cQry += "                        AND D_E_L_E_T_ = ' ' "
		cQry += "                        AND CTK_RECDES != ' ' "
		cQry += "                        AND CTK_TABORI = 'SD1' "
		cQry += "                        AND CTK_RECORI IN( "
		
		For iZ := 1 To Len(aRecSD1)
			If iZ > 1
				cQry += ","
			Endif
			cQry += "'"+Alltrim(Str(aRecSD1[iZ]))+"' "
		Next
		cQry += "))"
		
		cQry += " )  AND D_E_L_E_T_ = ' ' "
		
		TCQUERY cQry NEW ALIAS "QCTK"
		
		If !Eof()
			lRetGrv	:= .F.
			MsgAlert('Erro na exclus�o do Lan�amento Cont�bil',ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
		Else
			MsgInfo('Exclus�o do Lan�amento cont�bil com Sucesso!',ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
			// For�o a atualiza��o do Flag de Contabiliza��o da Nota fiscal para evitar que seja chamada a contabiliza��o de exclus�o do sistema
			RestArea(aAreaOld)
			DbSelectArea("SF1")
			RecLock("SF1",.F.)
			SF1->F1_DTLANC	:= CTOD("")
			MsUnlock()
			
		EndIf
		QCTK->(DbCloseArea())	
	Endif

	RestArea(aAreaOld)
	
Return lRetGrv

