
/*/{Protheus.doc} SX5NOTA
Ponto de entrada para restringir as s�ries de Notas liberadas para uso 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 15/07/2021
@return variant, return_description
/*/
User Function SX5NOTA()

	Local	aAreaOld	:= GetArea()
	Local	lRet		:= .F.


	DbSelectArea("SX5")
    // Se for Admin - libera todas 
	If __cUserId $ "000000"
		lRet	:= .T.
    // Exce��o de s�rie por usu�rio por filial * Criar o par�metro MV_ZSX5NOT por filial e conte�do 000000/RPS#000100/RPS por exemplo para liberar a s�rie RPS para alguns usu�rios 
	ElseIf Alltrim(__cUserId)+"/"+Alltrim(SX5->X5_CHAVE) $ GetNewPar("MV_ZSX5NOT","000000#RPS") // 000000/IS#000002/IS
		lRet	:= .T.
    Endif

    // Se n�o atendeu valores acima, procura por empresa 
	If !lRet
        // Se for empresa Decanter 
		If cEmpAnt == "01"
			If cFilAnt $ "0102" // Logistica Floripa 
                // Verifica se est� na rotina MDFE - Manifesto de Carga para liberar a s�rie 5 
				If FwIsInCallStack("SPEDMDFE")
					If Alltrim(SX5->X5_CHAVE) $ "5"
						lRet 	:= .T.
					Endif
				Else
                    // Libera a s�rie 1 
					If Alltrim(SX5->X5_CHAVE) $ "1"
						lRet 	:= .T.
					Endif
				Endif
            Else 
                // Libera a s�rie 1 
                If Alltrim(SX5->X5_CHAVE) $ "1"
					lRet 	:= .T.
				Endif
			Endif
		Else
            // Libera a s�rie 
			If Alltrim(SX5->X5_CHAVE) $ "1"
				lRet 	:= .T.
			Endif
		Endif
	Endif

	RestArea(aAreaOld)

Return lRet
