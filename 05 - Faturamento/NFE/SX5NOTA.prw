
/*/{Protheus.doc} SX5NOTA
Ponto de entrada para restringir as séries de Notas liberadas para uso 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/07/2021
@return variant, return_description
/*/
//Adaptado para a empresa Forta - 13/08/2026 - Luciano - Lauschner Consultig
User Function SX5NOTA()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.
//FWGetSX5 A TABELA NAO ESTA POSICIONADA.

	If !FWSX6Util():ExistsParam("MV_ZSX5NOT")
		DbSelectArea("SX6")
		RecLock("SX6",.T.)
		SX6->X6_FIL		:= cFilAnt
		SX6->X6_VAR		:= "MV_ZSX5NOT"
		SX6->X6_TIPO	:= "C"
		SX6->X6_DESCRIC	:= "Usuário e séries liberados para faturamento"
		SX6->X6_DESC1	:= "Id usuário + # + Série "
		SX6->X6_DESC2	:= "Precisa cada usuário X Série"
		SX6->X6_CONTEUD	:= ""
		SX6->X6_PROPRI	:= "S"
		MsUnlock()
	Endif

	DbSelectArea("SX5")
	// Se for Admin - libera todas
	If __cUserId $ "000000"
		lRet	:= .T.
		// Exceção de série por usuário por filial * Criar o parâmetro MV_ZSX5NOT por filial e conteúdo 000000/RPS#000100/RPS por exemplo para liberar a série RPS para alguns usuários
	ElseIf Alltrim(__cUserId)+"#"+Alltrim(SX5->X5_CHAVE) $ GetNewPar("MV_ZSX5NOT","000000#101") // 000000/IS#000002/IS
		lRet	:= .T.
	Endif

	// Se não atendeu valores acima, procura por empresa
	If !lRet
		// Se for empresa Forta
		If cEmpAnt == "01"
			If cFilAnt $ "0101" // Forta Tech
				// Verifica se está na rotina MDFE - Manifesto de Carga para liberar a série 5
				If FwIsInCallStack("SPEDMDFE")
					If Alltrim(SX5->X5_CHAVE) $ "5"
						lRet 	:= .T.
					Endif
				Else
					// Libera a série 1
					If Alltrim(SX5->X5_CHAVE) $ "1"
						lRet 	:= .T.
					Endif
				Endif
			Else
				// Libera a série 1
				If Alltrim(SX5->X5_CHAVE) $ "1"
					lRet 	:= .T.
				Endif
			Endif
		Else
			// Libera a série
			If Alltrim(SX5->X5_CHAVE) $ "1#2#3"
				lRet 	:= .T.
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

Return lRet
