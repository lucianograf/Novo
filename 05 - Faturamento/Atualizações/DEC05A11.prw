#Include "Totvs.CH"

/*/{Protheus.doc} DEC05A11
Browser para impressão de Etiquetas de Caixas e Pallets 
@type function
@since 14/04/2021
/*///27/08/2025
User Function DEC05A11()

	Private cCadastro   := "Impressao de Etiquetas"
	Private aRotina     := {}

	Aadd(aRotina, {"Etiqueta Caixa"   , "U_decetiq001"  , 0, 3 })
	Aadd(aRotina, {"Etiqueta Caixa - 10x6"   , "U_decetiq6"  , 0, 3 })
	Aadd(aRotina, {"Etiqueta Pallet"  , "U_decetq02"    , 0, 2 })

	Aadd(aRotina, {"Etq Prd Itens NF"  , "U_DecEtq04"   , 0, 3 })

	Aadd(aRotina, {"Etiqueta Produto"  , "U_DecEtq03"   , 0, 3 })

	Aadd(aRotina, {"Etiqueta Entrada"  , "U_DECETQ05"   , 0 ,3 })
	dbSelectArea("SF2")
	DbSetOrder(1)
	mBrowse( 7, 4,20,74,"SF2",,,,,,,,,,,,,,,,,,)

Return
