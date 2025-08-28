#Include 'Totvs.ch'

/*/{Protheus.doc} decetiq001
Impress�o de etiquetas de Volumes de nota 
@type function
@version 1
@author Marcelo Alberto Lauschner
@since 28/04/2021
/*/
User Function decetiq001()

	Local    cPerg    := "ETIQC001"

	If Pergunte(cPerg,.T.)
		MsAguarde({|| sfExec()},"Aguarde","Imprimindo Etiquetas.....")
	EndIf

Return

/*/{Protheus.doc} DECIMPR
Impress�o das etiquetas 
@type function
@version  1
@author Marcelo Alberto Lauschner
@since 28/04/2021
/*/
Static Function sfExec()

	Local nVol  	:= 0
	Local nX 

	If mv_par01 == 1
		nVol := SF2->F2_VOLUME1
		nIni := 1
	Else
		nVol := mv_par02
		nIni := mv_par03
	EndIf

	If nVol =  0
		MSGALERT( "Nota fiscal sem volume ", "Mensagem" )
	Else
		For nX := 1 To nVol

			MSCBPRINTER("ZEBRA","LPT1",,,.f.,,,,,,.f.,)

			MSCBCHKSTATUS(.F.)
			MSCBBEGIN(1,6)

			SA1->(DbSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA))
			SA4->(DbSeek(xFilial("SA4")+SF2->F2_TRANSP))
			SD2->(DbSetOrder(3))
			SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE))

			MSCBSAY(03,05,SA1->A1_NREDUZ, "N","0","090,080")

			MSCBSAY(03,15,SA1->A1_NOME  , "N","0","050,030")
			MSCBSAY(03,20,SA1->A1_END   , "N","0","050,030")
			MSCBSAY(03,25,SA1->A1_BAIRRO, "N","0","050,030")
			MSCBSAY(03,30,Transform(SA1->A1_CEP,"@R 99999-999")+" - "+AllTrim(SA1->A1_MUN)+" - "+SA1->A1_EST, "N","0","060,030")

			MSCBSAY(03,40,SA4->A4_NOME          , "N","0","090,040")
			MSCBSAY(03,50,"NOTA FISCAL"         , "N","0","080,035")
			MSCBSAY(30,50,STRZERO(VAL(SF2->F2_DOC),6)   , "N","0","220,190")
			MSCBSAY(03,65,"PDV "+SD2->D2_PEDIDO , "N","0","045,040")

			//MSCBSAY(03,85,"VOLUME: "+Transform(nX,"@R 9999") + "/" + Transform(nVol,"@R 9999"), "N","0","100,090")
			If mv_par01 == 1
				MSCBSAY(03,75,"VOLUME: "+Transform(nX,"@R 9999") + "/" + Transform(nVol,"@R 9999"), "N","0","100,090")
			Else
				MSCBSAY(03,75,"VOLUME: "+Transform(nIni,"@R 9999") + "/" + Transform(mv_par04,"@R 9999"), "N","0","100,090")
				nIni := nIni + 1
			EndIf

			MSCBSAY(10,095,SM0->M0_NOMECOM , "N","0","035,040")

			_Tel := "("+SubStr(SM0->M0_TEL,1,2)+") "+Transform(SubStr(SM0->M0_TEL,3,8),"@R 9999-9999")
			MSCBSAY(20,090,Transform(SM0->M0_CEPCOB,"@R 99999-999")+" - "+AllTrim(SM0->M0_CIDCOB)+" - "+AllTrim(SM0->M0_ESTCOB)+" - "+_Tel,"N","0","035,020")

			MSCBEND()
			MSCBCLOSEPRINTER()

		NEXT

	EndIf

Return
