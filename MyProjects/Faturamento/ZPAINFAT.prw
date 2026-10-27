#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} ZPAINFAT
Painel de documentos por carga (OMS).

Fluxo:
  1) Faturar a carga normalmente (MATA460B) - botao "Faturar carga" so abre a rotina padrao
  2) A NF-e e transmitida automaticamente
  3) Neste painel: marcar as cargas liberadas e clicar em "Gerar documentos"
     -> XML (TSS) + DANFE + Romaneio com conferencia (TSOMS03/SIROMS02)
     -> Boleto: por enquanto pelo botao "Imprimir boletos" (abre o IMPRIMEBOL)
     -> arquivos na pasta escolhida: 1 PDF com todos os DANFEs, 1 XML por nota,
        1 PDF de romaneio+conferencia por carga

Legenda:
  Branco  = carga montada, ainda sem nota
  Amarelo = faturada, aguardando autorizacao da Sefaz
  Verde   = todas as notas autorizadas (liberada para gerar)
  Azul    = documentos ja gerados nesta sessao

Chamada pelo menu (modulo 39 - OMS): U_ZPAINFAT
@type User Function
/*/

Static oTmpTab  := Nil
Static cAlsTmp  := ""
Static oMark    := Nil
Static dParDe   := CToD("")
Static dParAte  := CToD("")

// Boleto ainda e emitido pela rotina propria (botao "Imprimir boletos").
// Quando o fonte do IMPRIMEBOL for integrado, mudar para .T.
#Define ZP_GERA_BOLETO .F.

User Function ZPAINFAT()

    If !ZPerg()
        Return
    EndIf

    ZCriaTmp()
    Processa({|| ZCarrega()}, "Aguarde", "Buscando cargas...")
    ZBrowse()

    If oTmpTab <> Nil
        oTmpTab:Delete()
        oTmpTab := Nil
    EndIf

Return

//------------------------------------------------------------------
// {Campo, Titulo, Tipo, Tam, Dec, Picture, Visivel}
Static Function ZCampos()

    Local aCpos := {}

    aAdd(aCpos, {"TR_OK"    , "Marca"          , "C", 2                       , 0, ""              , .F.})
    aAdd(aCpos, {"TR_CARGA" , "Carga"          , "C", TamSX3("DAK_COD")[1]    , 0, "@!"            , .T.})
    aAdd(aCpos, {"TR_SEQCAR", "Seq."           , "C", TamSX3("DAK_SEQCAR")[1] , 0, "@!"            , .T.})
    aAdd(aCpos, {"TR_DATA"  , "Data Carga"     , "D", 8                       , 0, ""              , .T.})
    aAdd(aCpos, {"TR_TRANSP", "Transportadora" , "C", TamSX3("A4_NREDUZ")[1]  , 0, "@!"            , .T.})
    aAdd(aCpos, {"TR_QTDNF" , "Qtd Notas"      , "N", 5                       , 0, "@E 99999"      , .T.})
    aAdd(aCpos, {"TR_QTDAUT", "Autorizadas"    , "N", 5                       , 0, "@E 99999"      , .T.})
    aAdd(aCpos, {"TR_PESO"  , "Peso Bruto"     , "N", 14                      , 3, "@E 999,999,999.999", .T.})
    aAdd(aCpos, {"TR_VALOR" , "Valor"          , "N", 16                      , 2, "@E 9,999,999,999.99", .T.})
    aAdd(aCpos, {"TR_STATUS", "Status"         , "C", 1                       , 0, ""              , .F.})

Return aCpos

//------------------------------------------------------------------
Static Function ZPerg()

    Local aPergs := {}
    Local aRet   := {}

    aAdd(aPergs, {1, "Data da carga de" , IIf(Empty(dParDe) , Date() - 7, dParDe) , "", "", "", "", 60, .T.})
    aAdd(aPergs, {1, "Data da carga ate", IIf(Empty(dParAte), Date()    , dParAte), "", "", "", "", 60, .T.})

    If !ParamBox(aPergs, "Painel de Documentos por Carga", @aRet)
        Return .F.
    EndIf

    dParDe  := aRet[1]
    dParAte := aRet[2]

Return .T.

//------------------------------------------------------------------
Static Function ZCriaTmp()

    Local aCpos   := ZCampos()
    Local aFields := {}
    Local nI

    For nI := 1 To Len(aCpos)
        aAdd(aFields, {aCpos[nI,1], aCpos[nI,3], aCpos[nI,4], aCpos[nI,5]})
    Next nI

    oTmpTab := FWTemporaryTable():New(GetNextAlias())
    oTmpTab:SetFields(aFields)
    oTmpTab:AddIndex("01", {"TR_CARGA", "TR_SEQCAR"})
    oTmpTab:Create()

    cAlsTmp := oTmpTab:GetAlias()

Return

//------------------------------------------------------------------
// Carrega as cargas do periodo com a contagem de notas e autorizadas
Static Function ZCarrega()

    Local cAlias := GetNextAlias()
    Local cQry   := ""
    Local cSF2   := RetSqlName("SF2")
    Local cFilF2 := xFilial("SF2")

    TCSqlExec("DELETE FROM " + oTmpTab:GetRealName())
    TCRefresh(oTmpTab:GetRealName())

    cQry += " SELECT DAK.DAK_COD, DAK.DAK_SEQCAR, DAK.DAK_DATA, DAK.DAK_PESO, DAK.DAK_VALOR, "
    cQry += "        COALESCE(SA4.A4_NREDUZ, ' ') AS TRANSP, "
    cQry += "        (SELECT COUNT(*) FROM " + cSF2 + " F2 "
    cQry += "          WHERE F2.F2_FILIAL = '" + cFilF2 + "' AND F2.F2_CARGA = DAK.DAK_COD "
    cQry += "            AND F2.F2_SEQCAR = DAK.DAK_SEQCAR AND F2.D_E_L_E_T_ = ' ') AS QTDNF, "
    cQry += "        (SELECT COUNT(*) FROM " + cSF2 + " F2 "
    cQry += "          WHERE F2.F2_FILIAL = '" + cFilF2 + "' AND F2.F2_CARGA = DAK.DAK_COD "
    cQry += "            AND F2.F2_SEQCAR = DAK.DAK_SEQCAR AND F2.F2_FIMP = 'S' "
    cQry += "            AND F2.D_E_L_E_T_ = ' ') AS QTDAUT "
    cQry += "   FROM " + RetSqlName("DAK") + " DAK "
    cQry += "   LEFT JOIN " + RetSqlName("SA4") + " SA4 "
    cQry += "          ON SA4.A4_FILIAL = '" + xFilial("SA4") + "' AND SA4.A4_COD = DAK.DAK_TRANSP "
    cQry += "         AND SA4.D_E_L_E_T_ = ' ' "
    cQry += "  WHERE DAK.DAK_FILIAL = '" + xFilial("DAK") + "' "
    cQry += "    AND DAK.DAK_DATA BETWEEN '" + DToS(dParDe) + "' AND '" + DToS(dParAte) + "' "
    cQry += "    AND DAK.D_E_L_E_T_ = ' ' "
    cQry += "  ORDER BY DAK.DAK_COD DESC, DAK.DAK_SEQCAR "

    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        RecLock(cAlsTmp, .T.)
            (cAlsTmp)->TR_OK     := "  "
            (cAlsTmp)->TR_CARGA  := (cAlias)->DAK_COD
            (cAlsTmp)->TR_SEQCAR := (cAlias)->DAK_SEQCAR
            (cAlsTmp)->TR_DATA   := SToD((cAlias)->DAK_DATA)
            (cAlsTmp)->TR_TRANSP := (cAlias)->TRANSP
            (cAlsTmp)->TR_QTDNF  := (cAlias)->QTDNF
            (cAlsTmp)->TR_QTDAUT := (cAlias)->QTDAUT
            (cAlsTmp)->TR_PESO   := (cAlias)->DAK_PESO
            (cAlsTmp)->TR_VALOR  := (cAlias)->DAK_VALOR
            (cAlsTmp)->TR_STATUS := ZStatus((cAlias)->QTDNF, (cAlias)->QTDAUT)
        (cAlsTmp)->(MsUnlock())
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    (cAlsTmp)->(DbGoTop())

Return

//------------------------------------------------------------------
Static Function ZStatus(nQtdNf, nQtdAut)

    Do Case
        Case nQtdNf == 0       ; Return "S"   // sem nota
        Case nQtdAut < nQtdNf  ; Return "A"   // aguardando autorizacao
    EndCase

Return "L"                                    // liberada

//------------------------------------------------------------------
Static Function ZBrowse()

    Local aCpos    := ZCampos()
    Local aColumns := {}
    Local oCol     := Nil
    Local nI

    For nI := 1 To Len(aCpos)
        If aCpos[nI,7]
            oCol := FWBrwColumn():New()
            oCol:SetData(&("{|| " + aCpos[nI,1] + " }"))
            oCol:SetTitle(aCpos[nI,2])
            oCol:SetType(aCpos[nI,3])
            oCol:SetSize(aCpos[nI,4])
            oCol:SetDecimal(aCpos[nI,5])
            oCol:SetPicture(aCpos[nI,6])
            aAdd(aColumns, oCol)
        EndIf
    Next nI

    oMark := FWMarkBrowse():New()
    oMark:SetAlias(cAlsTmp)
    oMark:SetTemporary(.T.)
    oMark:SetFieldMark("TR_OK")
    oMark:SetColumns(aColumns)
    oMark:SetDescription("Painel de Documentos por Carga")
    oMark:SetMenuDef("ZPAINFAT")
    oMark:DisableDetails()

    oMark:AddLegend("TR_STATUS == 'S'", "WHITE" , "Carga sem nota (faturar)")
    oMark:AddLegend("TR_STATUS == 'A'", "YELLOW", "Aguardando autorizacao Sefaz")
    oMark:AddLegend("TR_STATUS == 'L'", "GREEN" , "Liberada para gerar documentos")
    oMark:AddLegend("TR_STATUS == 'G'", "BLUE"  , "Documentos gerados")

    oMark:Activate()

Return

//------------------------------------------------------------------
Static Function MenuDef()

    Local aRotina := {}

    ADD OPTION aRotina TITLE "Gerar documentos" ACTION "U_ZPFGER" OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Atualizar"        ACTION "U_ZPFATU" OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Faturar carga"    ACTION "U_ZPFFAT" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Imprimir boletos" ACTION "U_ZPFBOL" OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Parametros"       ACTION "U_ZPFPAR" OPERATION 3 ACCESS 0

Return aRotina

//------------------------------------------------------------------
User Function ZPFATU()
    Processa({|| ZCarrega()}, "Aguarde", "Atualizando cargas...")
    oMark:Refresh(.T.)
Return

User Function ZPFPAR()
    If ZPerg()
        U_ZPFATU()
    EndIf
Return

// Abre a rotina de boletos atual (provisorio, ate integrar o fonte no painel)
User Function ZPFBOL()

    If ExistBlock("IMPRIMEBOL")
        ExecBlock("IMPRIMEBOL", .F., .F.)          // U_IMPRIMEBOL
    ElseIf FindFunction("IMPRIMEBOL")
        &("IMPRIMEBOL()")                           // funcao sem U_
    Else
        MsgStop("Rotina IMPRIMEBOL nao encontrada no RPO.", "Atencao")
    EndIf

Return

// Apenas abre o Documento de Saida por Carga padrao e atualiza ao voltar
User Function ZPFFAT()
    MATA460B()
    U_ZPFATU()
Return

//------------------------------------------------------------------
// Botao "Gerar documentos"
User Function ZPFGER()

    Local aCargas := {}
    Local cMarca  := oMark:Mark()
    Local aArea   := (cAlsTmp)->(GetArea())

    (cAlsTmp)->(DbGoTop())
    While !(cAlsTmp)->(Eof())
        If (cAlsTmp)->TR_OK == cMarca
            aAdd(aCargas, {(cAlsTmp)->TR_CARGA, (cAlsTmp)->TR_SEQCAR, (cAlsTmp)->(Recno())})
        EndIf
        (cAlsTmp)->(DbSkip())
    EndDo
    RestArea(aArea)

    If Empty(aCargas)
        MsgInfo("Marque ao menos uma carga.", "Atencao")
        Return
    EndIf

    Processa({|| ZGerar(aCargas)}, "Aguarde", "Gerando documentos...")
    oMark:Refresh(.T.)

Return

//------------------------------------------------------------------
Static Function ZGerar(aCargas)

    Local cBase    := "\spool\fatcarga\"
    Local cStamp   := DToS(Date()) + "_" + StrTran(Time(), ":", "")
    Local cExec    := cBase + AllTrim(RetCodUsr()) + "_" + cStamp + "\"
    Local aLog     := {}
    Local aFiles   := {}
    Local cIdEnt   := ""
    Local cUrlTss  := AllTrim(SuperGetMV("MV_SPEDURL", .F., ""))
    Local oDanfe   := Nil
    Local nDanfes  := 0
    Local nI

    // Variaveis que o U_DANFEProc (danfeii.prw) espera encontrar
    Private nConsNeg := 0.4
    Private nConsTex := 0.5
    Private oRetNF   := Nil
    Private MV_PAR01 := ""
    Private MV_PAR02 := ""
    Private MV_PAR03 := ""
    Private MV_PAR04 := 2          // Operacao: 2 = saida
    Private MV_PAR05 := 1          // Frente e verso: 1 = sim
    Private MV_PAR06 := 2          // DANFE simplificado: 2 = nao
    Private MV_PAR07 := CToD("")   // Emissao de (vazio = sem filtro)
    Private MV_PAR08 := CToD("")   // Emissao ate

    If !FindFunction("RetIdEnti")
        MsgStop("Funcao RetIdEnti nao encontrada no RPO. Verificar com a TI.", "Atencao")
        Return
    EndIf
    cIdEnt := RetIdEnti()

    ZMkDir(cBase)
    ZMkDir(cExec)

    // Um unico PDF com os DANFEs de todas as notas desta geracao
    If ExistBlock("DANFEProc")
        oDanfe := ZDanfeNew("DANFES_" + cStamp, cExec)
    Else
        aAdd(aLog, "U_DANFEProc nao encontrado no RPO - DANFEs nao gerados.")
    EndIf

    ProcRegua(Len(aCargas))

    For nI := 1 To Len(aCargas)

        IncProc("Carga " + AllTrim(aCargas[nI,1]))

        If ZGeraCarga(aCargas[nI,1], aCargas[nI,2], cExec, cIdEnt, cUrlTss, @aLog, oDanfe, @nDanfes)
            (cAlsTmp)->(DbGoTo(aCargas[nI,3]))
            RecLock(cAlsTmp, .F.)
                (cAlsTmp)->TR_STATUS := "G"
                (cAlsTmp)->TR_OK     := "  "
            (cAlsTmp)->(MsUnlock())
        EndIf
    Next nI

    // Fecha o PDF de DANFEs
    If oDanfe <> Nil
        If nDanfes > 0
            oDanfe:Print()
        EndIf
        FreeObj(oDanfe)
        oDanfe := Nil
    EndIf

    ZListaArq(cExec, @aFiles)

    If !Empty(aFiles)
        ZEntrega(aFiles)
    EndIf

    // Limpa o servidor
    aEval(aFiles, {|x| FErase(x)})
    DirRemove(cExec)

    ZShowLog(aLog)

Return

//------------------------------------------------------------------
// Gera os documentos de uma carga. Retorna .T. se gerou tudo.
//  - XML: um arquivo por nota
//  - DANFE: paginas adicionadas ao PDF unico (oDanfe)
//  - Romaneio + conferencia: um PDF por carga
Static Function ZGeraCarga(cCarga, cSeq, cDir, cIdEnt, cUrlTss, aLog, oDanfe, nDanfes)

    Local cAlias := GetNextAlias()
    Local cQry   := ""
    Local aNotas := {}
    Local lOk    := .T.
    Local cTxt   := ""
    Local nPend  := 0
    Local nI

    cQry := " SELECT F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_FIMP, F2_CHVNFE, F2_DUPL "
    cQry += "   FROM " + RetSqlName("SF2")
    cQry += "  WHERE F2_FILIAL = '" + xFilial("SF2") + "' "
    cQry += "    AND F2_CARGA  = '" + cCarga + "' "
    cQry += "    AND F2_SEQCAR = '" + cSeq + "' "
    cQry += "    AND D_E_L_E_T_ = ' ' "
    cQry += "  ORDER BY F2_DOC "
    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        aAdd(aNotas, {(cAlias)->F2_DOC, (cAlias)->F2_SERIE, (cAlias)->F2_CLIENTE, (cAlias)->F2_LOJA, ;
                      (cAlias)->F2_FIMP, AllTrim((cAlias)->F2_CHVNFE), !Empty((cAlias)->F2_DUPL)})
        If (cAlias)->F2_FIMP <> "S"
            nPend++
        EndIf
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    cTxt := "Carga " + AllTrim(cCarga) + ": "

    If Empty(aNotas)
        aAdd(aLog, cTxt + "sem notas faturadas - ignorada.")
        Return .F.
    EndIf

    If nPend > 0
        aAdd(aLog, cTxt + cValToChar(nPend) + " nota(s) ainda nao autorizada(s) - carga ignorada. Use 'Atualizar' e tente de novo.")
        Return .F.
    EndIf

    For nI := 1 To Len(aNotas)

        // XML (direto do TSS) - um arquivo por nota
        If !ZGeraXml(aNotas[nI,1], aNotas[nI,2], aNotas[nI,6], cIdEnt, cUrlTss, cDir)
            aAdd(aLog, cTxt + "falha no XML da nota " + AllTrim(aNotas[nI,1]))
            lOk := .F.
        EndIf

        // DANFE - entra no PDF unico
        If oDanfe <> Nil
            If ZDanfeAdd(@oDanfe, aNotas[nI,1], aNotas[nI,2], cIdEnt)
                nDanfes++
            Else
                aAdd(aLog, cTxt + "DANFE nao gerado - nota " + AllTrim(aNotas[nI,1]))
                lOk := .F.
            EndIf
        EndIf

        // Boleto: somente notas que geraram duplicata (bonificacao, remessa etc. ficam de fora)
        If ZP_GERA_BOLETO .And. aNotas[nI,7]
            If !ZGeraBol(aNotas[nI,1], aNotas[nI,2], aNotas[nI,3], aNotas[nI,4], cDir)
                aAdd(aLog, cTxt + "boleto nao gerado - nota " + AllTrim(aNotas[nI,1]))
                lOk := .F.
            EndIf
        EndIf
    Next nI

    // Romaneio + conferencia de carga (SIROMS02) - um PDF por carga
    If !U_TSOMS03G(cCarga, cSeq, cDir, .T.)
        aAdd(aLog, cTxt + "romaneio nao gerado.")
        lOk := .F.
    EndIf

    If lOk
        aAdd(aLog, cTxt + "OK - " + cValToChar(Len(aNotas)) + " nota(s).")
    EndIf

Return lOk

//------------------------------------------------------------------
// XML autorizado (nfeProc = NFe + protocolo) buscado no TSS
Static Function ZGeraXml(cNota, cSerie, cChave, cIdEnt, cUrlTss, cDir)

    Local oWs     := Nil
    Local aRet    := {}
    Local cXml    := ""
    Local cProt   := ""
    Local cProc   := ""
    Local nPos    := 0

    oWs := WSNFeSBRA():New()
    oWs:cUSERTOKEN        := "TOTVS"
    oWs:cID_ENT           := cIdEnt
    oWs:_URL              := cUrlTss + "/NFeSBRA.apw"
    oWs:nDIASPARAEXCLUSAO := 0
    oWs:oWSNFEID          := NFESBRA_NFES2():New()
    oWs:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
    aAdd(oWs:oWSNFEID:oWSNotas:oWSNFESID2, NFESBRA_NFESID2():New())
    aTail(oWs:oWSNFEID:oWSNotas:oWSNFESID2):cID := cSerie + cNota   // mesma chave usada pela SPEDNFE

    If !oWs:RetornaNotas()
        ConOut("ZPAINFAT - RetornaNotas: " + GetWSCError())
        Return .F.
    EndIf

    aRet := oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3
    If Empty(aRet)
        Return .F.
    EndIf

    cXml  := aRet[1]:oWSNFe:cXML
    cProt := aRet[1]:oWSNFe:cXMLPROT

    If Empty(cXml) .Or. Empty(cProt)
        Return .F.
    EndIf

    // Remove cabecalho <?xml ... ?> se vier no meio
    If (nPos := At("?>", cXml)) > 0 .And. Left(LTrim(cXml), 5) == "<?xml"
        cXml := SubStr(cXml, nPos + 2)
    EndIf

    cProc := '<?xml version="1.0" encoding="UTF-8"?>'
    cProc += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
    cProc += cXml + cProt
    cProc += '</nfeProc>'

    If Empty(cChave)
        cChave := AllTrim(cSerie) + "_" + AllTrim(cNota)
    EndIf

Return MemoWrite(cDir + cChave + "-procNFe.xml", cProc)

//------------------------------------------------------------------
// DANFE em PDF (retrato) usando o U_DANFEProc do danfeii.prw.
// Chamamos o DANFEProc direto (e nao o U_PrtNfeSef) porque o PrtNfeSef
// executa Pergunte("NFSIGW"), que abre tela ou sobrescreve os MV_PAR
// com os ultimos valores salvos pelo usuario.
//
// Um unico objeto de impressao recebe as paginas de todas as notas,
// gerando um so PDF. O Print() e feito no ZGerar, depois da ultima nota.
Static Function ZDanfeNew(cArq, cDir)

    Local oDanfe := Nil

    // New(cArquivo, nDevice, lAdjustToLegacy, cPathInServer, lDisableSetup,
    //     lTReport, oPrintSetup, cPrinter, lServer, lPDFAsPNG, lRaw, lViewPDF)
    oDanfe := FWMSPrinter():New(cArq, 6 /*IMP_PDF*/, .F., cDir, .T., , , , .T., , , .F.)
    oDanfe:SetResolution(78)
    oDanfe:SetPortrait()
    oDanfe:SetPaperSize(9 /*DMPAPER_A4*/)
    oDanfe:SetMargin(60, 60, 60, 60)
    oDanfe:lServer  := .T.
    oDanfe:nDevice  := 6 /*IMP_PDF*/
    oDanfe:cPathPDF := cDir

Return oDanfe

// Acrescenta o DANFE de uma nota ao PDF unico
Static Function ZDanfeAdd(oDanfe, cNota, cSerie, cIdEnt)

    Local lExistNfe := .F.

    // MV_PAR sao Private do ZGerar; o DANFEProc altera o MV_PAR01, por isso
    // todos sao preenchidos de novo a cada nota
    MV_PAR01 := cNota
    MV_PAR02 := cNota
    MV_PAR03 := cSerie
    MV_PAR04 := 2
    MV_PAR05 := 1
    MV_PAR06 := 2
    MV_PAR07 := CToD("")
    MV_PAR08 := CToD("")

    U_DANFEProc(@oDanfe, .F., cIdEnt, Nil, Nil, @lExistNfe, .F.)

Return lExistNfe

//------------------------------------------------------------------
// Boleto em PDF
// PENDENTE: depende do fonte IMPRIMEBOL (parametros, escolha do banco, saida).
Static Function ZGeraBol(cNota, cSerie, cCliente, cLoja, cDir)
Return .F.

//------------------------------------------------------------------
// Entrega os arquivos: .zip unico para download (navegador) ou copia para pasta local
Static Function ZEntrega(aFiles)

    Local cLib    := ""
    // Somente o tipo do remote decide (5 = SmartClient HTML). O nome da lib
    // contem "HTML" ate no SmartClient desktop, entao nao serve para isso.
    Local lHtml   := (GetRemoteType(@cLib) == 5)
    Local cLocal  := ""
    Local nOk     := 0
    Local nI

    If lHtml
        // Navegador nao permite escolher pasta: cada arquivo vira um download
        For nI := 1 To Len(aFiles)
            If CpyS2TW(aFiles[nI], .T.) == 0
                nOk++
            EndIf
        Next nI
        MsgInfo(cValToChar(nOk) + " arquivo(s) enviados para a pasta de downloads do navegador.", "Concluido")
        Return
    EndIf

    // 16 = GETF_LOCALHARD, 128 = GETF_RETDIRECTORY
    cLocal := cGetFile("", "Pasta para salvar os documentos", 0, "C:\", .F., 16 + 128, .T.)
    If Empty(cLocal)
        MsgInfo("Nenhuma pasta selecionada. Documentos nao foram copiados.", "Atencao")
        Return
    EndIf
    If Right(cLocal, 1) <> "\"
        cLocal += "\"
    EndIf

    // Todos os arquivos direto na pasta escolhida
    For nI := 1 To Len(aFiles)
        If CpyS2T(aFiles[nI], cLocal)
            nOk++
        EndIf
    Next nI

    MsgInfo(cValToChar(nOk) + " de " + cValToChar(Len(aFiles)) + " arquivo(s) salvos em " + cLocal, "Concluido")

Return

//------------------------------------------------------------------
Static Function ZListaArq(cDir, aFiles)

    Local aDir := Directory(cDir + "*.*")
    Local cExt := ""
    Local nI

    // So entram PDF e XML (o FWMSPrinter pode deixar arquivos .rel de spool)
    For nI := 1 To Len(aDir)
        cExt := Upper(Right(AllTrim(aDir[nI,1]), 4))
        If cExt == ".PDF" .Or. cExt == ".XML"
            aAdd(aFiles, cDir + aDir[nI,1])
        Else
            FErase(cDir + aDir[nI,1])
        EndIf
    Next nI

Return

Static Function ZMkDir(cDir)
    If !ExistDir(cDir)
        MakeDir(cDir)
    EndIf
Return

Static Function ZShowLog(aLog)

    Local cMsg := ""

    aEval(aLog, {|x| cMsg += x + CRLF})
    If !Empty(cMsg)
        MsgInfo(cMsg, "Resumo da geracao")
    EndIf

Return
