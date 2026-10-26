#Include "Protheus.ch"

//==================================================================================
// COLAR NO FINAL DO TSOMS03.prw (precisa ficar no mesmo fonte para acessar as
// Static Functions ImpRel, qryRom1 etc.). Nao altera nada do que ja existe.
// Funciona tanto na versao original quanto na alterada em 16/10/2026
// (nao depende da coluna QTDNF do qryRom1).
//==================================================================================

/*/{Protheus.doc} TSOMS03G
	Gera o romaneio de UMA carga sem tela de parametros (usado pelo ZPAINFAT).
	Gera 1 PDF por carga: romaneio + conferencia de carga (SIROMS02), na mesma
	ordem da rotina original (romaneio primeiro, conferencia depois).
	@param cCarga, Caracter, codigo da carga (DAK_COD)
	@param cSeq,   Caracter, sequencia (DAK_SEQCAR) - vazio = todas
	@param cDir,   Caracter, pasta NO SERVIDOR onde o PDF deve ser gravado
	@param lConf,  Logico,   .T. = imprime tambem a conferencia de carga (SIROMS02)
	@return Logico, .T. se encontrou a carga e gerou
	@history 26/10/2026, Lucas Guimaraes - Criacao para o painel de documentos por carga (ZPAINFAT)
/*/
User Function TSOMS03G(cCarga, cSeq, cDir, lConf)
	Local lBold          := .T.
	Local lNotBold       := .F.
	Local lSublinhado    := .T.
	Local lNotSublinhado := .F.
	Local cQryRomaneio   := ""
	Local cQryNF         := GetNextAlias()
	Local lAchou         := .F.
	Local lTemNF         := .F.

	Default cSeq  := ""
	Default lConf := .F.

	Public cArquivo := ""
	Public oRel     := Nil

	Private o10Arial    := tFont():New("Arial",,10,,lNotBold,,,,,lNotSublinhado)
	Private o10BArial   := tFont():New("Arial",,10,,lBold   ,,,,,lNotSublinhado)
	Private o10BSArial  := tFont():New("Arial",,12,,lBold   ,,,,,lSublinhado)
	Private o12Arial    := tFont():New("Arial",,12,,lNotBold,,,,,lNotSublinhado)
	Private o12BArial   := tFont():New("Arial",,12,,lBold   ,,,,,lNotSublinhado)
	Private o14BArial   := tFont():New("Arial",,14,,lBold   ,,,,,lNotSublinhado)
	Private o14Arial    := tFont():New("Arial",,14,,lNotBold,,,,,lNotSublinhado)
	Private o18BArial   := tFont():New("Arial",,18,,lBold   ,,,,,lNotSublinhado)
	Private lRet        := .F.
	Private cRomaneio   := cCarga
	Private cTsDeCarga  := cCarga
	Private cTsAteCarga := cCarga
	Private nVlrTtl     := {}
	Private aImpostos   := {}
	Private cImpCarga   := IIf(lConf, 1, 2)

	// As consultas do fonte leem MV_PAR01..MV_PAR08: preenchidos aqui no lugar do ParamBox
	Private MV_PAR01 := cCarga
	Private MV_PAR02 := cCarga
	Private MV_PAR03 := IIf(Empty(cSeq), Space(TamSX3("DAK_SEQCAR")[1]), cSeq)
	Private MV_PAR04 := IIf(Empty(cSeq), "ZZ", cSeq)
	Private MV_PAR05 := SToD("20010101")
	Private MV_PAR06 := SToD("20491231")
	Private MV_PAR07 := Space(TamSX3("A1_MUN")[1])
	Private MV_PAR08 := cImpCarga

	// A carga existe?
	cQryRomaneio := qryRom1()
	lAchou := (cQryRomaneio)->(!Eof())
	(cQryRomaneio)->(dbCloseArea())

	If !lAchou
		Return .F.
	Endif

	// A carga tem nota faturada? (conferencia so faz sentido se tiver)
	BeginSql Alias cQryNF
		SELECT COUNT(*) AS QTD
		FROM %Table:SC9% SC9
		WHERE SC9.C9_FILIAL = %xFilial:SC9%
		  AND SC9.C9_CARGA = %Exp:cCarga%
		  AND SC9.C9_NFISCAL <> ' '
		  AND SC9.%NotDel%
	EndSql
	lTemNF := (cQryNF)->QTD > 0
	(cQryNF)->(dbCloseArea())

	cArquivo := "relCargas1_" + AllTrim(cCarga) + "_" + RetCodUSR() + StrTran(Time(), ":", "")

	// New(cFile, lLandscape, lImpPDF, cPathInServer, lDisableSetup, oPrintSetup, cPrinter, lViewPDF)
	// lDisableSetup = .T. -> sem tela e grava NO SERVIDOR em cDir
	// lViewPDF      = .F. -> nao abre/baixa o PDF (o painel copia para a pasta escolhida)
	oRel := IpFwMsPrinter():New(cArquivo,,, cDir, .T.,,, .F.)

	oRel:StartPage()
	Processa({|| ImpRel()}, 'Gerando romaneio da carga ' + AllTrim(cCarga) + '...')
	oRel:EndPage()

	// Conferencia de carga no mesmo PDF (mesma ordem da rotina original)
	If lConf .and. (lRet .or. lTemNF)
		u_SIROMS02(cCarga, cCarga)
	Endif

	oRel:print()
	oRel := Nil   // o print() do IPFwMsPrinter ja libera o objeto

Return .T.
