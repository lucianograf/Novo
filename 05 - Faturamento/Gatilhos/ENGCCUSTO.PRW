#Include 'Protheus.ch'
//Gatilho para carregar Centro de Custo ao dar entrada em NF de Bonificação

User Function ENGCCUSTO()

	Local cEmpAnt := " "
	Local aFiliais := {"01","03","05"}
	Local cFilial := xFilial("SD1")
	Local cCFOP := " "
	Local cCCusto := GetNewPar("LG_CCUSTOS","")

	If cEmpAnt == "99" .And. cCFOP == SD1-> D1_CF $ "1910#2910"
		cCCusto == GetNewPar("LG_CCUSTOS","")
	Endif

Return cCCusto





