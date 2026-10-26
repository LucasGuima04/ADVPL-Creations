#Include "TOTVS.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} ZRELFAT
Tela (browse) com a relacao de notas fiscais de saida (venda, bonificacao,
etc.) - mesmo universo da rotina NF-e Sefaz.

- Uma unica consulta SQL traz todos os dados (sem consultas por nota).
- Tabela temporaria (FWTemporaryTable): nao precisa criar nada no dicionario.
- Filtro, pesquisa e legenda nativos do FWMBrowse.
- Outras Acoes: "Parametros" (recarrega o periodo) e "Exportar Excel".

Chamada pelo menu: U_ZRELFAT
@type User Function
/*/

Static oTmpTab := Nil
Static cAlsTmp := ""
Static oBrowse := Nil
Static dParDe  := CToD("")
Static dParAte := CToD("")
Static nParSit := 1

User Function ZRELFAT()

    If !ZPerg()
        Return
    EndIf

    ZCriaTmp()
    Processa({|| ZCarrega()}, "Aguarde", "Buscando notas fiscais...")
    ZBrowse()

    // Ao fechar a tela, apaga a tabela temporaria
    If oTmpTab <> Nil
        oTmpTab:Delete()
        oTmpTab := Nil
    EndIf

Return

//------------------------------------------------------------------
// Definicao unica das colunas: {Campo, Titulo, Tipo, Tam, Dec, Picture, Visivel}
// Usada para criar a tabela, as colunas do browse, o filtro e o Excel.
Static Function ZCampos()

    Local aCpos := {}

    aAdd(aCpos, {"TR_DTFAT" , "Dt Faturamento", "D", 8                       , 0, ""  , .T.})
    aAdd(aCpos, {"TR_CARGA" , "Cod. Carga"    , "C", 10                      , 0, "@!", .T.})
    aAdd(aCpos, {"TR_PEDIDO", "Pedido"        , "C", TamSX3("C5_NUM")[1]     , 0, "@!", .T.})
    aAdd(aCpos, {"TR_NREDUZ", "Cliente"       , "C", TamSX3("A1_NREDUZ")[1]  , 0, "@!", .T.})
    aAdd(aCpos, {"TR_NOTA"  , "Nota Fiscal"   , "C", TamSX3("F2_DOC")[1]     , 0, "@!", .T.})
    aAdd(aCpos, {"TR_SERIE" , "Serie"         , "C", TamSX3("F2_SERIE")[1]   , 0, "@!", .T.})
    aAdd(aCpos, {"TR_VEND"  , "Cod. Vendedor" , "C", TamSX3("A3_COD")[1]     , 0, "@!", .T.})
    aAdd(aCpos, {"TR_NOMVEN", "Vendedor"      , "C", TamSX3("A3_NOME")[1]    , 0, "@!", .T.})
    aAdd(aCpos, {"TR_SITUAC", "Situacao"      , "C", 35                      , 0, "@!", .T.})
    aAdd(aCpos, {"TR_CFOP"  , "CFOP"          , "C", 30                      , 0, "@!", .T.})
    aAdd(aCpos, {"TR_CODSIT", "Cod. Situacao" , "C", 1                       , 0, "@!", .F.}) // usado na legenda

Return aCpos

//------------------------------------------------------------------
Static Function ZPerg()

    Local aPergs := {}
    Local aRet   := {}
    Local aSitu  := {"1=Todas", "2=Autorizadas", "3=Canceladas", "4=Pendentes/Rejeitadas/Denegadas"}

    // Na primeira vez sugere o mes atual; depois, os ultimos valores usados
    aAdd(aPergs, {1, "Faturamento de",  IIf(Empty(dParDe) , FirstDate(Date()), dParDe) , "", "", "", "", 60, .T.})
    aAdd(aPergs, {1, "Faturamento ate", IIf(Empty(dParAte), Date()           , dParAte), "", "", "", "", 60, .T.})
    aAdd(aPergs, {2, "Situacao",        nParSit, aSitu, 90, "", .T.})

    If !ParamBox(aPergs, "Relacao de Notas Faturadas", @aRet)
        Return .F.
    EndIf

    // Variaveis Static: ficam na sessao do usuario (nao compartilha com outros)
    dParDe  := aRet[1]
    dParAte := aRet[2]
    nParSit := Val(cValToChar(aRet[3]))

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
    oTmpTab:AddIndex("01", {"TR_NOTA", "TR_SERIE"})
    oTmpTab:AddIndex("02", {"TR_PEDIDO"})
    oTmpTab:AddIndex("03", {"TR_NREDUZ"})
    oTmpTab:AddIndex("04", {"TR_CARGA"})
    oTmpTab:Create()

    cAlsTmp := oTmpTab:GetAlias()

Return

//------------------------------------------------------------------
// Monta a consulta unica. Tudo vem em uma ida ao banco:
// nota + CFOPs agrupados + pedido + carga + cliente + vendedor.
Static Function ZQuery()

    Local cQry   := ""
    Local cDb    := AllTrim(Upper(TcGetDb()))
    Local cDe    := DToS(dParDe)
    Local cAte   := DToS(dParAte)
    Local cFil3  := xFilial("SF3")
    Local cAgg   := ""
    Local cBase  := ""

    // Junta os CFOPs da nota em uma string "5102/5910" (sintaxe varia por banco)
    Do Case
        Case cDb == "ORACLE"
            cAgg := "LISTAGG(X.CFO, '/') WITHIN GROUP (ORDER BY X.CFO)"
        Case "POSTGRES" $ cDb
            cAgg := "STRING_AGG(X.CFO, '/' ORDER BY X.CFO)"
        OtherWise // MSSQL (SQL Server 2017 ou superior)
            cAgg := "STRING_AGG(X.CFO, '/') WITHIN GROUP (ORDER BY X.CFO)"
    EndCase

    // Filtro base da SF3, repetido nas duas subconsultas.
    // F3_ENTRADA = data da saida nas notas de saida; e o campo do indice 1
    // da SF3 (F3_FILIAL+F3_ENTRADA...), por isso filtramos por ele.
    cBase := " F3_FILIAL = '" + cFil3 + "' "
    cBase += " AND F3_ENTRADA BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cBase += " AND F3_ESPECIE = 'SPED' "
    cBase += " AND F3_CFO >= '5' AND F3_CFO < '8' "   // somente saidas (5, 6 e 7)
    // Somente estes CFOPs (CT-e, frete e demais saidas ficam de fora):
    //   x1xx       = venda (5101, 6102, 7101...)
    //   x40x       = venda com ST (5401, 5405, 6403...)
    //   5910/6910  = bonificacao
    //   5922/6922  = debito / simples faturamento
    cBase += " AND F3_ESPECIE NOT IN ('CTE', 'CTEOS') "
    cBase += " AND ( SUBSTRING(F3_CFO, 2, 1) = '1' "
    cBase += "    OR SUBSTRING(F3_CFO, 2, 2) = '40' "
    cBase += "    OR SUBSTRING(F3_CFO, 2, 3) IN ('910', '922') ) "
    cBase += " AND D_E_L_E_T_ = ' ' "

    cQry += " SELECT NF.F3_EMISSAO AS DTFAT, NF.F3_NFISCAL AS NOTA, NF.F3_SERIE AS SERIE, "
    cQry += "        NF.F3_DTCANC AS DTCANC, "
    cQry += "        COALESCE(F2.FIMP, ' ')      AS FIMP, "
    cQry += "        COALESCE(F2.VEND, ' ')      AS VEND, "
    cQry += "        COALESCE(D2.PEDIDO, ' ')    AS PEDIDO, "
    cQry += "        COALESCE(D2.CARGA, ' ')     AS CARGA, "
    cQry += "        COALESCE(SA1.A1_NREDUZ,' ') AS NREDUZ, "
    cQry += "        COALESCE(SA3.A3_NOME, ' ')  AS NOMVEN, "
    cQry += "        COALESCE(CF.CFOPS, ' ')     AS CFOPS "

    // 1) Uma linha por nota (a SF3 tem uma linha por CFOP/aliquota)
    cQry += "   FROM (SELECT F3_NFISCAL, F3_SERIE, F3_CLIEFOR, F3_LOJA, "
    cQry += "                MAX(F3_EMISSAO) AS F3_EMISSAO, MAX(F3_DTCANC) AS F3_DTCANC "
    cQry += "           FROM " + RetSqlName("SF3")
    cQry += "          WHERE " + cBase
    cQry += "          GROUP BY F3_NFISCAL, F3_SERIE, F3_CLIEFOR, F3_LOJA) NF "

    // 2) CFOPs distintos da nota, agrupados
    cQry += "   LEFT JOIN (SELECT X.F3_NFISCAL, X.F3_SERIE, X.F3_CLIEFOR, X.F3_LOJA, "
    cQry += "                     " + cAgg + " AS CFOPS "
    cQry += "                FROM (SELECT DISTINCT F3_NFISCAL, F3_SERIE, F3_CLIEFOR, F3_LOJA, "
    cQry += "                             RTRIM(F3_CFO) AS CFO "
    cQry += "                        FROM " + RetSqlName("SF3")
    cQry += "                       WHERE " + cBase + ") X "
    cQry += "               GROUP BY X.F3_NFISCAL, X.F3_SERIE, X.F3_CLIEFOR, X.F3_LOJA) CF "
    cQry += "          ON CF.F3_NFISCAL = NF.F3_NFISCAL AND CF.F3_SERIE = NF.F3_SERIE "
    cQry += "         AND CF.F3_CLIEFOR = NF.F3_CLIEFOR AND CF.F3_LOJA  = NF.F3_LOJA "

    // 3) Status de transmissao e vendedor (SF2 SEM filtro de deletado:
    //    a nota cancelada tem a SF2 excluida)
    cQry += "   LEFT JOIN (SELECT F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, "
    cQry += "                     MAX(F2_FIMP) AS FIMP, MAX(F2_VEND1) AS VEND, MAX(F2_TIPO) AS TIPO "
    cQry += "                FROM " + RetSqlName("SF2")
    cQry += "               WHERE F2_FILIAL = '" + xFilial("SF2") + "' "
    cQry += "                 AND F2_EMISSAO BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQry += "               GROUP BY F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA) F2 "
    cQry += "          ON F2.F2_DOC = NF.F3_NFISCAL AND F2.F2_SERIE = NF.F3_SERIE "
    cQry += "         AND F2.F2_CLIENTE = NF.F3_CLIEFOR AND F2.F2_LOJA = NF.F3_LOJA "

    // 4) Pedido (SD2) e carga (DAI) - SD2 tambem sem filtro de deletado.
    //    AJUSTAR A CARGA se no seu ambiente ela vier de outro lugar. Exemplos:
    //    - campo customizado no pedido: trocar o JOIN da DAI por SC5 e usar C5_XCARGA
    //    - carga ligada direto a nota: DAI_NFISCAL/DAI_SERIE em vez de DAI_PEDIDO
    cQry += "   LEFT JOIN (SELECT SD2.D2_DOC, SD2.D2_SERIE, SD2.D2_CLIENTE, SD2.D2_LOJA, "
    cQry += "                     MAX(SD2.D2_PEDIDO) AS PEDIDO, MAX(DAI.DAI_COD) AS CARGA "
    cQry += "                FROM " + RetSqlName("SD2") + " SD2 "
    cQry += "                LEFT JOIN " + RetSqlName("DAI") + " DAI "
    cQry += "                       ON DAI.DAI_FILIAL = '" + xFilial("DAI") + "' "
    cQry += "                      AND DAI.DAI_PEDIDO = SD2.D2_PEDIDO "
    cQry += "                      AND DAI.D_E_L_E_T_ = ' ' "
    cQry += "               WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "' "
    cQry += "                 AND SD2.D2_EMISSAO BETWEEN '" + cDe + "' AND '" + cAte + "' "
    cQry += "               GROUP BY SD2.D2_DOC, SD2.D2_SERIE, SD2.D2_CLIENTE, SD2.D2_LOJA) D2 "
    cQry += "          ON D2.D2_DOC = NF.F3_NFISCAL AND D2.D2_SERIE = NF.F3_SERIE "
    cQry += "         AND D2.D2_CLIENTE = NF.F3_CLIEFOR AND D2.D2_LOJA = NF.F3_LOJA "

    // 5) Nome reduzido do cliente e nome do vendedor
    cQry += "   LEFT JOIN " + RetSqlName("SA1") + " SA1 "
    cQry += "          ON SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
    cQry += "         AND SA1.A1_COD = NF.F3_CLIEFOR AND SA1.A1_LOJA = NF.F3_LOJA "
    cQry += "         AND SA1.D_E_L_E_T_ = ' ' "
    cQry += "   LEFT JOIN " + RetSqlName("SA3") + " SA3 "
    cQry += "          ON SA3.A3_FILIAL = '" + xFilial("SA3") + "' "
    cQry += "         AND SA3.A3_COD = F2.VEND "
    cQry += "         AND SA3.D_E_L_E_T_ = ' ' "

    // Filtro de situacao
    cQry += "  WHERE 1 = 1 "
    // Somente notas do tipo Normal (N), exceto as de debito (CFOP x922), que
    // podem ter outro tipo. Fora: devolucao (D), beneficiamento (B), complementos.
    cQry += "    AND ( COALESCE(F2.TIPO, 'N') = 'N' OR CF.CFOPS LIKE '%922%' ) "
    Do Case
        Case nParSit == 2 ; cQry += " AND NF.F3_DTCANC = ' ' AND F2.FIMP = 'S' "
        Case nParSit == 3 ; cQry += " AND NF.F3_DTCANC <> ' ' "
        Case nParSit == 4 ; cQry += " AND NF.F3_DTCANC = ' ' AND COALESCE(F2.FIMP, ' ') <> 'S' "
    EndCase

    cQry += "  ORDER BY NF.F3_EMISSAO, NF.F3_NFISCAL "

    // Obs.: sem ChangeQuery de proposito - a query ja esta escrita de forma
    // portavel e o ChangeQuery pode nao reconhecer STRING_AGG/LISTAGG.

Return cQry

//------------------------------------------------------------------
// Executa a consulta e grava na tabela temporaria
Static Function ZCarrega()

    Local cAlias := GetNextAlias()
    Local aSit   := {}
    Local nTot   := 0

    // Limpa a tabela antes de (re)carregar
    TCSqlExec("DELETE FROM " + oTmpTab:GetRealName())
    TCRefresh(oTmpTab:GetRealName())

    DbUseArea(.T., "TOPCONN", TCGenQry(,, ZQuery()), cAlias, .F., .T.)

    While !(cAlias)->(Eof())

        nTot++
        If nTot % 100 == 0
            IncProc("Notas carregadas: " + cValToChar(nTot))
        EndIf

        aSit := ZSitNota((cAlias)->DTCANC, (cAlias)->FIMP)

        RecLock(cAlsTmp, .T.)
            (cAlsTmp)->TR_DTFAT  := SToD((cAlias)->DTFAT)
            (cAlsTmp)->TR_CARGA  := (cAlias)->CARGA
            (cAlsTmp)->TR_PEDIDO := (cAlias)->PEDIDO
            (cAlsTmp)->TR_NREDUZ := (cAlias)->NREDUZ
            (cAlsTmp)->TR_NOTA   := (cAlias)->NOTA
            (cAlsTmp)->TR_SERIE  := (cAlias)->SERIE
            (cAlsTmp)->TR_VEND   := (cAlias)->VEND
            (cAlsTmp)->TR_NOMVEN := (cAlias)->NOMVEN
            (cAlsTmp)->TR_CODSIT := aSit[1]
            (cAlsTmp)->TR_SITUAC := aSit[2]
            (cAlsTmp)->TR_CFOP   := (cAlias)->CFOPS
        (cAlsTmp)->(MsUnlock())

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    (cAlsTmp)->(DbGoTop())

Return

//------------------------------------------------------------------
Static Function ZBrowse()

    Local aCpos    := ZCampos()
    Local aColumns := {}
    Local aFilter  := {}
    Local aSeek    := {}
    Local oCol     := Nil
    Local nI

    For nI := 1 To Len(aCpos)
        // Campos disponiveis no filtro do Protheus
        aAdd(aFilter, {aCpos[nI,1], aCpos[nI,2], aCpos[nI,3], aCpos[nI,4], aCpos[nI,5], aCpos[nI,6]})

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

    // Pesquisa (na mesma ordem dos indices da tabela temporaria)
    aAdd(aSeek, {"Nota Fiscal", {{"", "C", TamSX3("F2_DOC")[1]   , 0, "Nota Fiscal", "@!"}}})
    aAdd(aSeek, {"Pedido"     , {{"", "C", TamSX3("C5_NUM")[1]   , 0, "Pedido"     , "@!"}}})
    aAdd(aSeek, {"Cliente"    , {{"", "C", TamSX3("A1_NREDUZ")[1], 0, "Cliente"    , "@!"}}})
    aAdd(aSeek, {"Cod. Carga" , {{"", "C", 10                    , 0, "Cod. Carga" , "@!"}}})

    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cAlsTmp)
    oBrowse:SetTemporary(.T.)
    oBrowse:SetDescription("Relacao de Notas Faturadas")
    oBrowse:SetMenuDef("ZRELFAT")
    oBrowse:SetColumns(aColumns)
    oBrowse:SetFieldFilter(aFilter)
    oBrowse:SetSeek(.T., aSeek)
    oBrowse:DisableDetails()

    oBrowse:AddLegend("TR_CODSIT == 'A'", "GREEN" , "Autorizada")
    oBrowse:AddLegend("TR_CODSIT == 'C'", "RED"   , "Cancelada")
    oBrowse:AddLegend("TR_CODSIT == 'T'", "YELLOW", "Transmitida - aguardando retorno")
    oBrowse:AddLegend("TR_CODSIT == 'R'", "ORANGE", "Rejeitada / nao autorizada")
    oBrowse:AddLegend("TR_CODSIT == 'D'", "BLACK" , "Denegada")
    oBrowse:AddLegend("TR_CODSIT == 'N'", "WHITE" , "Nao transmitida")

    oBrowse:Activate()

Return

//------------------------------------------------------------------
Static Function MenuDef()

    Local aRotina := {}

    ADD OPTION aRotina TITLE "Atualizar"      ACTION "U_ZRFATU" OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar datas"  ACTION "U_ZRFPAR" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Exportar Excel" ACTION "U_ZRFXLS" OPERATION 2 ACCESS 0

Return aRotina

//------------------------------------------------------------------
// Botao "Atualizar": recarrega com os mesmos parametros (sem sair da tela)
User Function ZRFATU()

    Processa({|| ZCarrega()}, "Aguarde", "Atualizando notas fiscais...")
    oBrowse:Refresh(.T.)

Return

//------------------------------------------------------------------
// Botao "Parametros": muda o periodo/situacao e recarrega a tela
User Function ZRFPAR()

    If ZPerg()
        Processa({|| ZCarrega()}, "Aguarde", "Buscando notas fiscais...")
        oBrowse:Refresh(.T.)
    EndIf

Return

//------------------------------------------------------------------
// Botao "Exportar Excel": exporta os registros da tela
// (percorre o alias do browse, entao deve respeitar o filtro aplicado)
User Function ZRFXLS()

    Local aCpos     := ZCampos()
    Local aArea     := (cAlsTmp)->(GetArea())
    Local oExcel    := FWMsExcelEx():New()
    Local oExcelApp := Nil
    Local cAba      := "Notas"
    Local cTit      := "Relacao de Notas Faturadas"
    Local cNome     := "NotasFaturadas_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".xls"
    Local cDirSrv   := "\spool\"   // pasta no servidor (usada no SmartClient HTML)
    Local cLib      := ""
    Local lHtml     := .F.
    Local cArq      := ""
    Local aLinha    := {}
    Local nI

    // SmartClient HTML (navegador) nao acessa o Excel da maquina:
    // gera no servidor e manda como download. Nos demais, gera na pasta temp local.
    lHtml := (GetRemoteType(@cLib) == 5)   // 5 = SmartClient HTML (o nome da lib nao serve)
    If lHtml
        If !ExistDir(cDirSrv)
            MakeDir(cDirSrv)
        EndIf
        cArq := cDirSrv + cNome
    Else
        cArq := GetTempPath() + cNome
    EndIf

    oExcel:AddworkSheet(cAba)
    oExcel:AddTable(cAba, cTit)
    For nI := 1 To Len(aCpos)
        If aCpos[nI,7]
            oExcel:AddColumn(cAba, cTit, aCpos[nI,2], 1, IIf(aCpos[nI,3] == "D", 4, 1))
        EndIf
    Next nI

    (cAlsTmp)->(DbGoTop())
    While !(cAlsTmp)->(Eof())
        aLinha := {}
        For nI := 1 To Len(aCpos)
            If aCpos[nI,7]
                aAdd(aLinha, IIf(aCpos[nI,3] == "C", AllTrim((cAlsTmp)->&(aCpos[nI,1])), (cAlsTmp)->&(aCpos[nI,1])))
            EndIf
        Next nI
        oExcel:AddRow(cAba, cTit, aLinha)
        (cAlsTmp)->(DbSkip())
    EndDo

    RestArea(aArea)

    oExcel:Activate()
    oExcel:GetXMLFile(cArq)

    If lHtml
        // Envia o arquivo do servidor para o navegador (download) e apaga do servidor
        If CpyS2TW(cArq, .T.) == 0
            FErase(cArq)
        Else
            MsgStop("Nao foi possivel enviar o arquivo para o navegador. Arquivo no servidor: " + cArq, "Atencao")
        EndIf
    ElseIf ApOleClient("MsExcel")
        oExcelApp := MsExcel():New()
        oExcelApp:WorkBooks:Open(cArq)
        oExcelApp:SetVisible(.T.)
    Else
        MsgInfo("Arquivo gerado em: " + cArq, "Concluido")
    EndIf

Return

//------------------------------------------------------------------
// Situacao da nota -> {codigo da legenda, descricao}
// CONFIRMAR os valores de F2_FIMP no seu ambiente (Configurador).
Static Function ZSitNota(cDtCanc, cFimp)

    If !Empty(cDtCanc)
        Return {"C", "CANCELADA"}
    EndIf

    Do Case
        Case cFimp == "S" ; Return {"A", "AUTORIZADA"}
        Case cFimp == "T" ; Return {"T", "TRANSMITIDA - AGUARDANDO RETORNO"}
        Case cFimp == "N" ; Return {"R", "REJEITADA / NAO AUTORIZADA"}
        Case cFimp == "D" ; Return {"D", "DENEGADA"}
    EndCase

Return {"N", "NAO TRANSMITIDA"}
