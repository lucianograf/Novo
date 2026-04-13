#include "protheus.ch"

User Function ApQryAn( uParm )

	Local oBanner
	Local nI
	
	#IFNDEF TOP
		Return ApMsgInfo("Opção disponível somente para ambiente TopConnect.","Ateção")
	#ENDIF

	Private oDlgQry
	Private __aConnections := {}
	Private __aServers := {}
	Private __aQuery := {}
	Private __nConnect
	Private __nQuery
	Private __cQuery := ""
	Private __oQuery
	Private __lChangeQuery := .T.
	Private __nBuffer := 40

	Public __LocalDriver    := "DBFCDX"
	Public cUserId
	Public cUserName

	

	DEFINE MSDIALOG oDlgQry TITLE "ApQA - Advanced Protheus Query Analyzer" OF oApp:oMainWnd PIXEL;
	FROM oApp:oMainWnd:nTop+22,oApp:oMainWnd:nLeft TO oApp:oMainWnd:nBottom-61,oApp:oMainWnd:nRight-10 STYLE nOR(WS_VISIBLE,WS_POPUP)

	oDlgQry:Owner():lEscClose:= .F. // desabilita o fechamento por ESC da tela

	@000,000 BITMAP oBanner RESNAME "FAIXASUPERIOR4" SIZE 1200,65 NOBORDER PIXEL
	oBanner:align:= CONTROL_ALIGN_TOP
	oBanner:lStretch := .F.

	ACTIVATE MSDIALOG oDlgQry ON INIT (If(ApQrySConnect(),ApQryRunEnv(),oDlgQry:End()))

	For nI:=1 To Len(__aConnections)
		TcUnLink(__aConnections[nI])
	Next nI

	
Return

// -------------------------------------
Static Function ApQryConnect(cDatabase,cServer,oConnect)
	Local nConnect
	Local nAt
	Local lConnect

	cDatabase := AllTrim(cDatabase)
	cServer	  := AllTrim(cServer)

	nAt := Ascan(__aServers,cServer+"/"+cDatabase)
	If nAt > 0
		nConnect := __aConnections[nAt][1]
		__nQuery := nAt
	Else	
		nConnect := TcLink(cDatabase,cServer)
		If nConnect > -1
			Aadd( __aConnections, nConnect)
			Aadd( __aServers,cServer+"/"+cDatabase)
			__nQuery := Len(__aConnections)
		Else
			ApMsgAlert("Connection failed","Connect")
			Return .F.
		EndIf
	EndIf
	__nConnect := nConnect
	lConnect := TcSetConn(__nConnect)
	If lConnect 
		If oConnect <> Nil .And. oConnect:nAt > 0
			__aQuery[oConnect:nAt][2] := __cQuery
		EndIf
		Aadd(__aQuery,{__nConnect,""})
		__cQuery := ""
		If __oQuery <> Nil
			__oQuery:Refresh()
		EndIf
	EndIf
Return lConnect


// -------------------------------------
Static Function ApQryRunEnv()
	Local oToolBar
	Local oPanel
	Local oSep
	Local oDum
	Local aButtons  := {}
	Local nCol		:= -14
	Local cList

	__nQuery := 1

	oDlgQry:ReadClientCoors()

	@ 037, 000 MSPANEL oToolBar OF oDlgQry SIZE __DlgWidth(oDlgQry), 014 RAISED

	@ 001,002 BITMAP oSep RESNAME "BMPSEP2" SIZE 6,11 OF oToolBar NOBORDER PIXEL

	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=26, 25, 25, "RPMNEW2"	,,,, {|| oDum:SetFocus(), ApQryNewQry()}, oToolBar, "New...", {|| __nQuery<>0},,))
	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=26, 25, 25, "RPMOPEN"	,,,, {|| oDum:SetFocus(), ApQryOpenQry()}, oToolBar, "Open...", {|| __nQuery<>0},,))
	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=26, 25, 25, "SALVAR"	,,,, {|| ApQrySvQry()}, oToolBar, "Save...", {|| __nQuery<>0},,))
	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=26, 25, 25, "NEXT"		,,,, {|| oDum:SetFocus(), ApQryRun()}, oToolBar, "Run...", {|| __nQuery<>0},,))

	@ 001,060 BITMAP oSep RESNAME "BMPSEP2" SIZE 6,11 OF oToolBar NOBORDER PIXEL

	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=40, 25, 25, "PMSRELA"	,,,, {|| ApQrySConnect(aButtons[7],aButtons)}, oToolBar, "Connect as...", {|| .T.},,))
	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=26, 25, 25, "NOCONNECT"	,,,, {|| ApQryDisconnect(aButtons[7])}, oToolBar, "Disconnect...", {|| __nQuery<>0},,))
	Aadd( aButtons, TComboBox():New( 001, 095, bSETGET(cList),__aServers, 150, 009, oToolBar,,{|| ApQrySetConn(aButtons[7]:nAt)},,,, .T.,,,,{|| __nQuery<>0},,,))
	Aadd( aButtons, TCheckBox():New( 001, __DlgWidth(oToolBar)-50, "Change Query", bSETGET(__lChangeQuery), oToolBar, 050, 009,,,,,,,, .T.,,,))

	@ 002,260 SAY "Buffer de Leitura" OF oToolBar PIXEL
	Aadd( aButtons, TGet():New( 001, 305, bSETGET(__nBuffer), oToolBar, 025, 008, "9999999999",,,,,,, .T.,,, {|| __nQuery<>0},,.T.,,,,,))

	@ 001,350 BITMAP oSep RESNAME "BMPSEP2" SIZE 6,11 OF oToolBar NOBORDER PIXEL

	Aadd( aButtons, TBtnBmp2():New( 001, nCol+=555, 25, 25, "FINAL"		,,,, {|| oDlgQry:End()}, oToolBar, "Exit...", {|| .T.},,))

	@ 053, 001.5 MSPANEL oPanel OF oDlgQry SIZE __DlgWidth(oDlgQry)-2, __DlgHeight(oDlgQry)-2 RAISED

	@ 000,000 BUTTON oDum PROMPT "ZE" SIZE 050,010 OF oPanel PIXEL
	oDum:bGotFocus := {|| __oQuery:SetFocus()}

	@ 001,001 GET __oQuery VAR __cQuery MULTILINE OF oPanel SIZE __DlgWidth(oPanel)-2, __DlgHeight(oPanel)/3 PIXEL

Return

// -------------------------------------
Static Function ApQryRun()
	Local oDlg
	Local oPanel
	Local oBrowse	:= {}
	Local oTabs
	Local oError	:= ErrorBlock({|e| ApQryError(e,@cError,@lError)})
	Local oTime
	Local oClose
	Local nTop
	Local nBottom
	Local nRight
	Local nI            
	Local nX
	Local nCount	:= 1
	Local nSec1
	Local nSec2
	Local aQuerys	:= {}
	Local aAlias	:= {}
	Local aError	:= {}
	Local aFiles	:= {}
	Local cQuery
	Local cError
	Local cTime		:= "00:00:00"
	Local lError	:= .F.
	Local bSETGET

	If Empty(__cQuery)
		Return
	EndIf

	If __nBuffer < 40
		ApMsgAlert("O Buffer especificado deve ser maior ou igual a 40!","Atenção")
		Return
	EndIf

	cQuery  := StrTran(__cQuery,CRLF," ") + ";"
	aQuerys := StrTokArr(cQuery,";")

	oDlgQry:ReadClientCoors()

	nTop	:= oDlgQry:nClientHeight/3+145
	nBottom	:= oDlgQry:nClientHeight - 4
	nRight  := oDlgQry:nClientWidth - 4

	DEFINE MSDIALOG oDlg FROM nTop,000 TO nBottom,nRight PIXEL STYLE nOR(WS_VISIBLE,WS_POPUP)

	@ 000, 000.5 MSPANEL oPanel OF oDlg SIZE __DlgWidth(oDlg)-5, __DlgHeight(oDlg)-1 RAISED

	@ 000.5,__DlgWidth(oDlg)-68 SAY "Run Time : " SIZE 030,009 OF oPanel PIXEL
	@ 000.5,__DlgWidth(oDlg)-42 SAY oTime VAR cTime SIZE 024,011 OF oPanel PIXEL
	@ 000.5,oPanel:nWidth-23 BTNBMP oClose RESOURCE "XCLOSE" SIZE 018, 014 ACTION oDlg:End() OF oPanel ADJUST

	For nI:=1 To Len(aQuerys)
		cQuery := AllTrim(aQuerys[nI])
		If __lChangeQuery
			cQuery := ChangeQuery(cQuery)
		EndIf
		If !Empty(cQuery)
			Aadd( aAlias, "QRY"+StrZero(nCount,3) )
			nSec1 := Seconds()
			dbUseArea( .T., "TOPCONN", TCGenQry(,,cQuery), aAlias[nCount], .F., .F. )
			nSec2 := Seconds()
			If lError
				Aadd( aError, cError )
				bSETGET := &("{|U| If( PCount() == 0, aError["+Str(Len(aError))+"], aError["+Str(Len(aError))+"] := U ) }")
				Aadd( oBrowse, TMultiGet():New( 8, 3, bSETGET, oPanel, __DlgWidth(oDlg)-10, __DlgHeight(oDlg)-23,,,,,, .T.,,,,,, .T.,,,,, ) )
				lError := .F.
			Else

				Aadd( aFiles, CriaTrab((aAlias[nCount])->(dbStruct())) )
				dbUseArea( .T., "DBFCDX", aFiles[Len(aFiles)], aFiles[Len(aFiles)], .F., .F. )

				Aadd( oBrowse, MsBrGetDBase():New( 8, 3, __DlgWidth(oDlg)-10, __DlgHeight(oDlg)-23,,,, oDlg,,,,,,,,,,,, .F., aFiles[Len(aFiles)], .T.,, .F.,,,) )
				For nX:=1 To (aFiles[Len(aFiles)])->(FCount())
					oBrowse[nCount]:AddColumn( TCColumn():New( (aFiles[Len(aFiles)])->(FieldName(nX)), &("{ || "+aFiles[Len(aFiles)]+"->"+(aFiles[Len(aFiles)])->(FieldName(nX))+"}"),,,,,"LEFT") )
				Next nX

				ApQryPutInFile(aAlias[nCount],aFiles[Len(aFiles)])

				oBrowse[nCount]:lColDrag	:= .T.
				oBrowse[nCount]:lLineDrag	:= .T.
				oBrowse[nCount]:lJustific	:= .T.
				oBrowse[nCount]:nColPos		:= 1
				oBrowse[nCount]:Cargo		:= {|| __NullEditcoll()}
				oBrowse[nCount]:bSkip		:= &("{|N| ApQryPutInFile('"+aAlias[nCount]+"','"+aFiles[Len(aFiles)]+"',N), "+aFiles[Len(aFiles)]+"->(_DBSKIPPER(N))}")
			EndIf
			oBrowse[nCount]:cCaption := APSec2Time(nSec2-nSec1)
			oBrowse[nCount]:Hide()
			If oTabs == Nil
				@ __DlgHeight(oDlg)-15,3 TABS oTabs PROMPT "Query # "+AllTrim(Str(nCount)) OF oPanel PIXEL SIZE __DlgWidth(oDlg)-11,10;
				ACTION ( ApQrySetTabs(oTabs:nOption,oBrowse,oTime))
			Else
				oTabs:AddItem("Query # "+AllTrim(Str(nCount)))
			EndIf
			nCount += 1
		EndIf
	Next nI
	oTabs:SetOption(1)

	ACTIVATE MSDIALOG oDlg

	For nI:=1 To Len(aAlias)
		(aAlias[nI])->(dbCloseArea())
	Next nI
	For nI:=1 To Len(aFiles)
		(aFiles[nI])->(dbCloseArea())
		FErase(aFiles[nI]+GetDbExtension())
	Next nI

	ErrorBlock(oError)
Return

// -------------------------------------
Static Function ApQrySetTabs(nOption,oBrowse,oTime)
	Local nI
	For nI:=1 To Len(oBrowse)
		If ( nI == nOption )
			oBrowse[nI]:Show()
			oTime:SetText(oBrowse[nI]:cCaption)
		Else
			oBrowse[nI]:Hide()
		EndIf
	Next nI
Return

// -------------------------------------
Static Function ApQryError(e,cError,lError)
	cError := e:Description
	lError := .T.
Return .T.

// -------------------------------------
Static Function APSec2Time(nTime,nStr)
	Local nHour
	Local nMinute
	Local nSecond
	Local cTime
	Local nTemp

	DEFAULT nTime := 0
	DEFAULT nStr := 2

	nTemp := Int(nTime/60)

	nHour := Int(nTemp/60)

	nMinute := nTemp - (nHour*60)

	nSecond := nTime - ((nHour*3600)+(nMinute*60))

	cTime := StrZero(nHour,nStr,0)+":"+StrZero(nMinute,2,0)+":"+StrZero(nSecond,2,0)

Return cTime

// -------------------------------------
Static Function APTime2Sec(cTime)
	Local nHour
	Local nMinute
	Local nSecond
	Local nTime

	DEFAULT cTime := "00:00:00"

	nHour := Val(Subs(cTime,1,2))

	nMinute := Val(Subs(cTime,4,2))

	nSecond := Val(Subs(cTime,7,2))

	nTime := (nHour*3600)+(nMinute*60)+nSecond

Return nTime


// -------------------------------------
Static Function ApQrySConnect(oConnect,aButtons)
	Local oDlg
	Local oOk
	Local oCancel
	Local oServer
	Local oDatabase
	Local cServer	:= Space(50)
	Local cDatabase	:= Space(50)
	Local cAlias
	Local cIniFile	:= GetADV97()
	Local lReturn := .F.

	cDataBase := GetPvProfString("TopConnect","DataBase","ERROR",cInIfile )
	cAlias	  := GetPvProfString("TopConnect","Alias","ERROR",cInIfile )
	cServer	  := GetPvProfString("TopConnect","Server","ERROR",cInIfile )
	// Ajuste pelo Environment do Server
	cDataBase := GetSrvProfString("TopDataBase",cDatabase)
	cAlias	  := GetSrvProfString("TopAlias",cAlias)
	cServer	  := GetSrvProfString("TopServer",cServer)

	cDatabase += "/" + cAlias
	cDatabase := Padr(cDatabase,50)
	cServer	  := Padr(cServer,50)

	DEFINE MSDIALOG oDlg FROM 000,000 TO 125,316 PIXEL TITLE "Connect as..."

	@ 003,005 SAY "Server" SIZE 060,007 OF oDlg PIXEL

	@ 012,005 GET oServer VAR cServer PICTURE "@!" SIZE 150,009 PIXEL

	@ 024,005 SAY "DBMS/Data Base" SIZE 060,007 OF oDlg PIXEL

	@ 033,005 GET oDatabase VAR cDatabase PICTURE "@!" SIZE 150,009 OF oDlg PIXEL

	DEFINE SBUTTON oOk FROM 048,097 TYPE 1 ENABLE OF oDlg PIXEL;
	WHEN (!Empty(cServer) .And. !Empty(cDatabase));
	ACTION (If(lReturn:=ApQryConnect(cDatabase,cServer,oConnect),(If(oConnect<>Nil,(oConnect:SetItems(__aServers),oConnect:nAt:=__nQuery,oConnect:Refresh(),oConnect:nAt:=Len(__aServers)),),oDlg:End()),))

	DEFINE SBUTTON oCancel FROM 048,127 TYPE 2 ENABLE OF oDlg PIXEL;
	ACTION ( oDlg:End(), lReturn:=.F.)

	ACTIVATE MSDIALOG oDlg CENTERED

Return lReturn

// -------------------------------------
Static Function ApQrySetConn(nAt)
	Local cDataBase
	Local cServer
	Local nQ

	If nAt == 0
		If Len(__aConnections) == 0
			__nQuery	:= nAt
			
		Else
			__nQuery	:= 1
			__cQuery	:= __aQuery[1][2]
			__oQuery:Refresh()
			__nQuery	:= 1
			__nConnect	:= __aConnections[1]
			cServer		:= Subs(__aServers[1],1,At("/",__aServers[1])-1)
			cDataBase	:= Subs(__aServers[1],At("/",__aServers[1])+1)
			cServer		:= Subs(__aServers[1],1,At("/",__aServers[1])-1)
			cDataBase	:= Subs(__aServers[1],At("/",__aServers[1])+1)
			
		EndIf
	Else
		If TcSetConn(__aConnections[nAt])
			nQ := Ascan(__aQuery,{|x| x[1]==__nConnect})
			If nQ > 0
				__aQuery[nQ][2] := __cQuery
			EndIf
			__cQuery	:= __aQuery[nAt][2]
			__oQuery:Refresh()
			__nQuery	:= nAt
			__nConnect	:= __aConnections[nAt]
			cServer		:= Subs(__aServers[nAt],1,At("/",__aServers[nAt])-1)
			cDataBase	:= Subs(__aServers[nAt],At("/",__aServers[nAt])+1)
			
		EndIf
	EndIf
Return

// -------------------------------------
Static Function ApQryDisconnect(oConnect,aButtons)
	Local nAt := oConnect:nAt
	Local cDatabase
	Local cServer

	If nAt <= Len(__aConnections)
		TCUnLink(__aConnections[nAt])
		Adel(__aConnections,nAt)
		Adel(__aServers,nAt)
		ASize(__aConnections,Len(__aConnections)-1)
		ASize(__aServers,Len(__aServers)-1)

		nAt := Len(__aServers)
		If nAt > 0
			oConnect:nAt := nAt
			TcSetConn(__aConnections[nAt])
			cServer		:= Subs(__aServers[nAt],1,At("/",__aServers[nAt])-1)
			cDataBase	:= Subs(__aServers[nAt],At("/",__aServers[nAt])+1)
			
		Else
			
		EndIf

		oConnect:SetItems(__aServers)
		oConnect:Refresh()
	EndIf
Return


// -------------------------------------
Static Function ApQryPutInFile(cSource,cTarget,n)
	Local nX
	Local nI		:= 1
	Local nRecno	:= (cTarget)->(Recno())

	Default n := __nBuffer

	If (cSource)->(Eof()) .Or. !( n > 0 .And. ( n+(cTarget)->(Recno()) > (cTarget)->(RecCount())-__nBuffer ) )
		Return
	EndIf

	While (cSource)->(!Eof()) .And. nI <= __nBuffer
		(cTarget)->(dbAppend())
		For nX:=1 To (cSource)->(FCount())
			(cTarget)->(FieldPut( nX, (cSource)->(FieldGet(nX)) ))
		Next nX
		nI += 1
		(cSource)->(dbSkip())
	End
	(cTarget)->(dbCommit())
	(cTarget)->(dbGoto(nRecno))
Return

// -------------------------------------
Static Function ApQryOpenQry()
	Local cFile
	Local cBuffer
	Local nLength
	Local nHdl

	cFile := cGetFile('Advanced Protheus Query Analyzer |*.APQ |SQL Query Analyzer |*.SQL |All Files|*.*','Open File',,,.T.,GETF_ONLYSERVER)
	If Empty(cFile)
		Return
	EndIf

	If At(".",cFile) == 0
		cFile += ".APQ"
	EndIf

	nHdl := FOpen(cFile,0)
	If nHdl < 0
		ApMsgAlert("Falha na leitura do arquivo "+cFile )
		Return
	EndIf

	nLength := FSeek(nHdl,0,2)
	cBuffer := Space(nLength)
	FSeek(nHdl,0)
	FRead(nHdl,@cBuffer,nLength)
	FClose(nHdl)
	__cQuery := cBuffer
	__oQuery:Refresh()
Return

// -------------------------------------
Static Function ApQrySvQry()
	Local cFile
	Local nHdl

	cFile := cGetFile('Advanced Protheus Query Analyzer |*.APQ |SQL Query Analyzer |*.SQL |All Files|*.*','Save File',,,.F.,GETF_ONLYSERVER)
	If Empty(cFile)
		Return
	EndIf
	If At(".",cFile) == 0
		cFile += ".APQ"
	EndIf

	If File(cFile) 
		If ApMsgYesNo("Sobrescrever o arquivo existente?","Atenção")
			FErase(cFile)
		Else 
			Return
		EndIf
	EndIf

	nHdl := FCreate(cFile,0)
	If nHdl < 0
		ApMsgAlert("Falha na gravação do arquivo "+cFile )
		Return
	EndIf
	FWrite(nHdl,__cQuery)
	FClose(nHdl)
Return

// -------------------------------------
Static Function ApQryNewQry()
	If !Empty(__cQuery) .And. ApMsgYesNo("Salvar script corrente?","Atenção")
		ApQrySvQry()
	EndIf
	__cQuery := ""
	__oQuery:Refresh()
Return

// -------------------------------------
Static Function __NullEditcoll()
Return