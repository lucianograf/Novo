
/*/{Protheus.doc} SX5NOTA
(Valida a série de Nota disponivel para faturamento,Baseado no parametro GM_SX5NOTA composto por Id usuário/Série )
	
@author MarceloLauschner
@since 05/11/2011
@version 1.0		

@return logico, se a série é permitida para o usuário

@example
(User Function SX5NOTA()

Local lRet:= .F.

If Alltrim(SX5->X5_CHAVE) == "A" .Or. Alltrim(SX5->X5_CHAVE) == "B"
    lRet := .T.
Endif

Return lRet
)

@see (http://tdn.totvs.com/pages/releaseview.action?pageId=6784448)
/*/
User Function SX5NOTA()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.
	//FWGetSX5 A TABELA NAO ESTA POSICIONADA.

	If !FWSX6Util():ExistsParam("GM_SX5NOTA")
		DbSelectArea("SX6")
		RecLock("SX6",.T.)
		SX6->X6_FIL		:= cFilAnt
		SX6->X6_VAR		:= "GM_SX5NOTA"
		SX6->X6_TIPO	:= "C"
		SX6->X6_DESCRIC	:= "Usuário e séries liberados para faturamento"
		SX6->X6_DESC1	:= "Id usuário + / + Série "
		SX6->X6_DESC2	:= "Precisa cada usuário X Série"
		SX6->X6_CONTEUD	:= ""
		SX6->X6_PROPRI	:= "S"
		MsUnlock()
	Endif

	DbSelectArea("SX5")
	// Se Admin libera todas opções de séries
	If __cUserId $ "000000"
		lRet	:= .T.
		// Se for Manifesto de carga
		If cEmpAnt == "01"
			If cFilAnt $ "0101" // Forta Tech
			ElseIf FwIsInCallStack("SPEDMDFE")
				// Só série 4 na frimazo Matriz
				If Alltrim(SX5->X5_CHAVE) $ "4"
					lRet 	:= .T.
				Endif
				// Se for TMS
			ElseIf FwIsInCallStack("TMSA200") .Or. nModulo == 43 // Conhecimento de Frete
				// Série 3 para Cte
				If Alltrim(SX5->X5_CHAVE) $ "3"
					lRet 	:= .T.
				Endif
				// FAturamento OS
			ElseIf FwIsInCallStack("OFIXX100") .Or. FwIsInCallStack("OFIXA100")
				// Filial Onix BC
				If cEmpAnt+cFilAnt $ "1106"
					// Série Serviços
					If ("#"+Alltrim(SX5->X5_CHAVE)) $ "#IS1#600#"	// a comparação usando # se faz necesário por conta das séries 1 IS1 ao fazer comparação "1" $ "IS1" tb retorna .T.
						// Verifica se tem variável se é faturamento serviço
						If Alltrim(cOX100Serie) $ "S"
							lRet	:= .T.
						Else
							//MsgAlert("Valores:   cEmpAnt '"+cEmpAnt+"'  cFilAnt '"+cFilAnt + "'  cOX100Serie '" + cOX100Serie + "' valor X5_CHAVE '" + Alltrim(SX5->X5_CHAVE) + "'", "SX5NOTA " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
						Endif
						// Série Peças
					ElseIf ("#"+Alltrim(SX5->X5_CHAVE)) $ "#1" // a comparação usando # se faz necesário por conta das séries 1 IS1 ao fazer comparação "1" $ "IS1" tb retorna .T.
						If Alltrim(cOX100Serie) $ "P"
							lRet	:= .T.
						Else
							//MsgAlert("Valores:   cEmpAnt '"+cEmpAnt+"'  cFilAnt '"+cFilAnt + "'  cOX100Serie '" + cOX100Serie + "' valor X5_CHAVE '" + Alltrim(SX5->X5_CHAVE) + "'", "SX5NOTA " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
						Endif
					Else
						//MsgAlert("Valores:   cEmpAnt '"+cEmpAnt+"'  cFilAnt '"+cFilAnt + "'  cOX100Serie '" + cOX100Serie + "' valor X5_CHAVE '" + Alltrim(SX5->X5_CHAVE) + "'", "SX5NOTA "  + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
					Endif
				Else
					//MsgAlert("Valores:   cEmpAnt '"+cEmpAnt+"'  cFilAnt '"+cFilAnt + "'  cOX100Serie '" + cOX100Serie + "' valor X5_CHAVE '" + Alltrim(SX5->X5_CHAVE) + "'", "SX5NOTA " + ProcName(0)+"."+ Alltrim(Str(ProcLine(0))) )
				Endif
				// Se usuário estiver no parâmetro de combinação - iduser / série;
				ElseIf Alltrim(__cUserId)+"/"+Alltrim(SX5->X5_CHAVE) $ GetMv("GM_SX5NOTA")
				lRet	:= .T.
				// Libera as séries 1 a 5 , e que não seja SPEDMDFE/TMSA200 ou Módulo TMS
			ElseIf ("#"+Alltrim(SX5->X5_CHAVE)) $ "#1#2#3#4#5"
				lRet	:= .T.
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

Return lRet

