#Include 'Protheus.ch'
//Gatilho para carregar Centro de Custo ao dar entrada em NF de Bonificação

/*User Function ENGCCUSTO()

	Local cCFOP := AllTrim(M->D1_CF)
	Local cCCusto := ""

	If cCFOP $ "1910#2910"
		cCCusto := "018150001"
	EndIf
Return cCCusto*/

/*User Function ENGCCUSTO()

Local cCFOP := AllTrim(M->D1_CF)

Local cCCusto := ""
If cCFOP == "1910" .Or. cCFOP == "2910"

cCCusto := "018150001"

EndIf

Return cCCusto*/

/*User Function ENGCCUSTO()


Local cCFOP := AllTrim(M->D1_CF)

MsgInfo("CFOP: " + cCFOP)

Return ""*/

User Function ENGCCUSTO()

Local cCFOP := AllTrim(M->D1_CF)
Local cCCusto := ""

If cCFOP == "1910" .Or. cCFOP == "2910"

cCCusto := GetNewPar("LG_CCUSTOS"," ")

EndIf

Return cCCusto



/*User Function ENGCCUSTO()

Local cCFOP   := AllTrim(M->D1_CF)
Local cCCusto := ""

Do Case
    Case cCFOP == "1910"
        cCCusto := GetNewPar("LG_CCUSTOS","")

    Case cCFOP == "2910"
        cCCusto := GetNewPar("LG_CCUSTOS","")
EndCase

Return cCCusto
*/






