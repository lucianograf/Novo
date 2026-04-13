#Include 'Protheus.ch'

/*/{Protheus.doc} CRIATBLZ
(Liberação de contra-senha para Central XML)
@author MarceloLauschner
@since 03/07/2014
@version 1.0
@return ${return}, ${return_description}
@example
(examples)
@see (links_or_references)
/*/
User Function CRIATBLZ()

	Local	cRand		:= Space(5)
	Local	dDtLimite	:= Date()+7
	Local	oPerg
	Local	cTipLib		:= "T"
	Local	cLibKey		:= Space(8)

	DEFINE MSDIALOG oPerg FROM 001,001 TO 180,350 OF oMainWnd PIXEL TITLE OemToAnsi("Dados para liberar a central XML")
	@ 028,010 Say "Tipo Liberação" Of oPerg Pixel
	@ 028,053 Combobox cTipLib Items {"T=Trial - Avaliação","P=Produção"} Size 100,10 Of oPerg Pixel
	@ 041,010 Say "Data Limite" Of oPerg Pixel
	@ 041,053 MsGet dDtLimite Size 50,10 Of oPerg Pixel When cTipLib == "T"
	@ 054,010 Say "Caracteres" Of oPerg Pixel
	@ 054,053 MsGet cRand Size 50,10 Of oPerg Pixel Valid (cLibKey := sfRetSenha(cRand+cTipLib,dDtLimite))
	@ 067,010 Say "Senha Liberação" Of oPerg Pixel
	@ 067,053 MsGet cLibKey Size 50,10 Of oPerg Pixel

	ACTIVATE MSDIALOG oPerg ON INIT EnchoiceBar(oPerg,{|| oPerg:End()},{|| oPerg:End()},,) CENTERED


Return


Static Function sfRetSenha(cInText,dDtLimit,lNewVld)

	Local		nSumDv	:= 0
	Local   	nPeso	:= 2
	Local   	nSubr   := Len(cInText)
	Local		nPassw	:= 0
	Local		nAuxVar	:= 0
	Local		nForA	:= 0
	Local		nPesoA	:= 4
	Local		cAuxDig	:= ""
	Local		nDtINi	:= dDtLimit - CTOD("01/01/2000")
	//Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))+Chr(Randomize(65,90))

	If MsgYesNo("Liberação novo modelo R33?") //lNewVld

		For nForA := 1 To 6
			nAuxVar	:= StrZero(Asc(Substr(cInText,nForA,1)),2)
			nAuxVar	:= Val(Substr(nAuxVar,2,1) + Substr(nAuxVar,1,1))
			nPassw	+= nAuxVar * nPesoA * (nPesoA+1) * (nPesoA+2)
			nPesoA++
			nPassw	+= Asc(Substr(cInText,1,1))
		Next

		nPassw += nDtIni * 11
		cAuxDig	:= StrZero(nPassw,7)
		nSubr	:= Len(cAuxDig)
		//MsgAlert(nPassw)
		While .T.
			nSumDv  += Val(Substr(cAuxDig,nSubr--,1)) * nPeso++
			If nPeso > 9
				nPeso := 2
			Endif
			If nSubr <= 0
				Exit
			Endif
		Enddo

		nSumDv	:= Mod(nSumDv,11)
		// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

		If nSumDv > 9   	// Igual a 10
			nSumDv := 1		// Sempre será um
		ElseIf nSumDv <= 1  // Igual a Zero ou Um
			nSumDv := 1 	// Sempre será um
		Else
			nSumDv	:= 11 - nSumDv
		Endif
	Else
		For nForA := 1 To 6
			nAuxVar	:= StrZero(Asc(Substr(cInText,nForA,1)),2)
			nAuxVar	:= Val(Substr(nAuxVar,2,1) + Substr(nAuxVar,1,1))
			nPassw	+= nAuxVar * nPesoA * (nPesoA+1) * (nPesoA+2)
			nPesoA++
			nPassw	+= Asc(Substr(cInText,1,1))
		Next

		// Se houver validação de data de expiracao
		If Substr(cInText,6,1) == "T"
			nPassw += nDtIni * 11
		Endif
		cAuxDig	:= StrZero(nPassw,7)
		nSubr	:= Len(cAuxDig)
		//MsgAlert(nPassw)
		While .T.
			nSumDv  += Val(Substr(cAuxDig,nSubr--,1)) * nPeso++
			If nPeso > 9
				nPeso := 2
			Endif
			If nSubr <= 0
				Exit
			Endif
		Enddo

		nSumDv	:= Mod(nSumDv,11)
		// Se o resto for igual 0,1 ou 10 o digito será = 1(um)

		If nSumDv > 9   	// Igual a 10
			nSumDv := 1		// Sempre será um
		ElseIf nSumDv <= 1  // Igual a Zero ou Um
			nSumDv := 1 	// Sempre será um
		Else
			nSumDv	:= 11 - nSumDv
		Endif

	Endif
Return StrZero(nPassw,7)+StrZero(nSumDv,1)
