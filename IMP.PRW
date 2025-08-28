#Include 'Protheus.ch'
#include "fileio.ch"

user Function IMPNEW()
	Local cAliasAdd	:= "SB5"

	RpcSetType(3)
	RpcSetEnv("01","01") 

	dbSelectArea("SX3")
	DbSetOrder(2)


	cLocDir	:= "C:\TOTVS12_DEV\Microsiga\protheus_data\cprova\sb50101_ficha_tecnica.csv"//cGetFile("TXT(*.txt)|*.txt","Selecione",1,"C:\",.T.,GETF_LOCALHARD,.F.,.T.)
	If !File(cLocDir)
		MsgInfo("Problema: Arquivo não localizado. Solução: Certifique-se que o arquivo está no caminho informado","Atenção [UNIM030002]")
		Break
	EndIf

	oFile := FWFileReader():New(cLocDir)
	if (oFile:Open())
	   //while (oFile:hasLine())
	   //   Conout(oFile:GetLine())
	   //end
	   aData	:=	oFile:getAllLines()
	   oFile:Close()
	endif

	conout("Total de registros =>"+cvaltochar(len(aData)))

	nCount		:=	0
	aCamposCab	:=	{}
	For nIss := 1 to Len(aData)
		nCount++
		conout(nCount)

		aDados:=StrTokArr2(aData[nIss],";",.T.)

		//Desconsiderar linhas em branco e
		If  Len(aDados)==0
			Loop
		EndIf

		//cab
		If nCount == 1
			For Ni:=1 To Len(aDados)
				if at(',',aDados[Ni]) >0
					aadd(aCamposCab,SubStr(aDados[Ni],0,at(',',aDados[Ni])-1))
				Else
					aadd(aCamposCab,aDados[Ni])
				EndIf
			Next

			dbSelectArea("SX3")
			DbSetOrder(2)
			lCpoOK	:=	 .T.
			For Ni := 1 To Len(aCamposCab)
				If !SX3->(dbSeek(aCamposCab[Ni]))
					Conout("Campo não localizado na sx3=> "+aCamposCab[Ni])
					lCpoOK	:= .F.
				EndIf
			Next

			//If !lCpoOK
			//	Return
			//EndIf

			Loop
		EndIf

		(cAliasAdd)->(Reclock(cAliasAdd,.T.))
		For nI := 1 To Len(aCamposCab)
			iF SX3->(dbSeek(aCamposCab[Ni]))


				if SX3->X3_TIPO == 'N'
					xValue		:=	val(aDados[nI])
				ElseIf SX3->X3_TIPO == 'D'
					xValue		:=	stod("")
				ElseIf SX3->X3_TIPO == 'L'
					xValue		:=	.F.
				Else
					xValue		:=	aDados[nI]
				EndIf

				nFieldPos	:=	(cAliasAdd)->(FieldPos( aCamposCab[nI]))
				if nFieldPos > 0
					(cAliasAdd)->(FieldPut(nFieldPos,xValue))
				EndIf
			eNDiF


		Next
		(cAliasAdd)->(msUnlock())

	Next

	RpcClearEnv()
return


user Function IMPCEP()
	Local cAliasAdd	:= "Z05"

	RpcSetType(3)
	RpcSetEnv("01","01")

	dbSelectArea("SX3")
	DbSetOrder(2)


	cLocDir	:= "C:\TOTVS12_DEV\Microsiga\protheus_data\cprova\CEP.csv"//cGetFile("TXT(*.txt)|*.txt","Selecione",1,"C:\",.T.,GETF_LOCALHARD,.F.,.T.)
	If !File(cLocDir)
		MsgInfo("Problema: Arquivo não localizado. Solução: Certifique-se que o arquivo está no caminho informado","Atenção [UNIM030002]")
		Break
	EndIf

	oFile := FWFileReader():New(cLocDir)
	if (oFile:Open())
	   //while (oFile:hasLine())
	   //   Conout(oFile:GetLine())
	   //end
	   aData	:=	oFile:getAllLines()
	   oFile:Close()
	endif

	conout("Total de registros =>"+cvaltochar(len(aData)))
	nTotal	:=	Len(aData)
	nCount		:=	0
	aCamposCab	:=	{}
	For nIss := 1 to nTotal
		nCount++
		conout(cValToChar(nIss)+"/"+cValToChar(nTotal))

		aDados:=StrTokArr2(aData[nIss],";",.T.)

		//Desconsiderar linhas em branco e
		If  Len(aDados)==0
			Loop
		EndIf

		//cab
		If nCount == 1
			For Ni:=1 To Len(aDados)
				if at(',',aDados[Ni]) >0
					aadd(aCamposCab,SubStr(aDados[Ni],0,at(',',aDados[Ni])-1))
				Else
					aadd(aCamposCab,aDados[Ni])
				EndIf
			Next

			dbSelectArea("SX3")
			DbSetOrder(2)
			lCpoOK	:=	 .T.
			For Ni := 1 To Len(aCamposCab)
				If !SX3->(dbSeek(aCamposCab[Ni]))
					Conout("Campo não localizado na sx3=> "+aCamposCab[Ni])
					lCpoOK	:= .F.
				EndIf
			Next

			Loop
		EndIf

		(cAliasAdd)->(Reclock(cAliasAdd,.T.))
		For nI := 1 To Len(aCamposCab)
			iF SX3->(dbSeek(aCamposCab[Ni]))


				if SX3->X3_TIPO == 'N'
					xValue		:=	val(aDados[nI])
				ElseIf SX3->X3_TIPO == 'D'
					xValue		:=	stod("")
				ElseIf SX3->X3_TIPO == 'L'
					xValue		:=	.F.
				Else
					xValue		:=	aDados[nI]
				EndIf

				nFieldPos	:=	(cAliasAdd)->(FieldPos( aCamposCab[nI]))
				if nFieldPos > 0
					(cAliasAdd)->(FieldPut(nFieldPos,xValue))
				EndIf
			eNDiF


		Next
		(cAliasAdd)->(msUnlock())

	Next

	RpcClearEnv()
return
