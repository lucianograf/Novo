
/*/{Protheus.doc} MTA410
Ponto de entrada no final do pedido de venda 
@type function
@version  
@author Marcelo Alberto Lauschner
@since 17/05/2021
@return return_type, return_description
/*/
User Function MTA410()

	Local   aAreaOld    := GetArea()
	Local   x
	Local   nBlq        := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_BLQ"})
	Local   nQtdLib   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDLIB"})
	Local 	nQtdVen   	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local 	nItem     	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local 	nProduto  	:= aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local   lRet        := .T.

    // Somente pedidos tipo Normal e Oriundos do Máxima 
	If M->C5_TIPO == "N" .And. !Empty(M->C5_XXPEDMA) 

		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
		
		If SA1->(FieldPos("A1_ZAUTO")) > 0 .And. SA1->A1_ZAUTO == "1" .And. cEmpAnt $ "01#02" .And. INCLUI 

			For x := 1 To Len(aCols)
				aCols[x][nBlq]  := "N"
				// Forço a quantidade liberada
				If aCols[x][nQtdLib] == 0
					aCols[x][nQtdLib] := aCols[x][nQtdVen]
				Endif

				DbSelectArea("SC6")
				DbSetOrder(1)
				If DbSeek(xFilial("SC6")+M->C5_NUM+aCols[x][nItem]+aCols[x][nProduto])
					aCols[x][nQtdLib]	-= SC6->C6_QTDENT
				Endif
			Next

		Else
			For x := 1 To Len(aCols)
				//aCols[x][nBlq]  	:= "S"
				aCols[x][nQtdLib] 	:= 0
			Next
		Endif
	Endif
	
    RestArea(aAreaOld)

Return lRet
