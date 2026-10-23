#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} ZRELFAT
Tela (browse) com a relacao de notas fiscais de saida (venda, bonificacao,
etc.) - mesmo universo da rotina NF-e Sefaz.

- Usa tabela temporaria (FWTemporaryTable): nao precisa criar nada no dicionario.
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
// Busca as notas e grava na tabela temporaria
Static Function ZCarrega()

    Local cAlias := GetNextAlias()
    Local cQuery := ""
    Local cWhere := ""
    Local dDe    := dParDe
    Local dAte   := dParAte
    Local nSitu  := nParSit
    Local aSit   := {}

    // Limpa a tabela antes de (re)carregar
    TCSqlExec("DELETE FROM " + oTmpTab:GetRealName())
    TCRefresh(oTmpTab:GetRealName())

    Do Case
        Case nSitu == 2 ; cWhere := " AND SF3.F3_DTCANC = ' ' AND SF2.F2_FIMP = 'S' "
        Case nSitu == 3 ; cWhere := " AND SF3.F3_DTCANC <> ' ' "
        Case nSitu == 4 ; cWhere := " AND SF3.F3_DTCANC = ' ' AND (SF2.F2_FIMP IS NULL OR SF2.F2_FIMP <> 'S') "
    EndCase

    /*
      Base = SF3 (livros fiscais): a nota cancelada continua la com F3_DTCANC
      preenchido mesmo quando SF2/SD2 foram excluidos. Por isso SF2/SD2
      entram SEM filtro de D_E_L_E_T_ (para o pedido aparecer nas canceladas).
    */
    cQuery += " SELECT SF3.F3_EMISSAO AS DTFAT, SF3.F3_NFISCAL AS NOTA, SF3.F3_SERIE AS SERIE, "
    cQuery += "        SF3.F3_CLIEFOR AS CLIENTE, SF3.F3_LOJA AS LOJA, SF3.F3_DTCANC AS DTCANC, "
    cQuery += "        MAX(SF2.F2_FIMP) AS FIMP, MAX(SF2.F2_VEND1) AS VEND, MAX(SD2.D2_PEDIDO) AS PEDIDO "
    cQuery += "   FROM " + RetSqlName("SF3") + " SF3 "
    cQuery += "   LEFT JOIN " + RetSqlName("SF2") + " SF2 "
    cQuery += "          ON SF2.F2_FILIAL = SF3.F3_FILIAL AND SF2.F2_DOC = SF3.F3_NFISCAL "
    cQuery += "         AND SF2.F2_SERIE = SF3.F3_SERIE AND SF2.F2_CLIENTE = SF3.F3_CLIEFOR "
    cQuery += "         AND SF2.F2_LOJA = SF3.F3_LOJA "
    cQuery += "   LEFT JOIN " + RetSqlName("SD2") + " SD2 "
    cQuery += "          ON SD2.D2_FILIAL = SF3.F3_FILIAL AND SD2.D2_DOC = SF3.F3_NFISCAL "
    cQuery += "         AND SD2.D2_SERIE = SF3.F3_SERIE AND SD2.D2_CLIENTE = SF3.F3_CLIEFOR "
    cQuery += "         AND SD2.D2_LOJA = SF3.F3_LOJA "
    cQuery += "  WHERE SF3.F3_FILIAL  = '" + xFilial("SF3") + "' "
    cQuery += "    AND SF3.F3_EMISSAO BETWEEN '" + DToS(dDe) + "' AND '" + DToS(dAte) + "' "
    cQuery += "    AND SF3.F3_ESPECIE = 'SPED' "
    cQuery += "    AND SUBSTRING(SF3.F3_CFO,1,1) IN ('5','6','7') "
    cQuery += "    AND SF3.D_E_L_E_T_ = ' ' "
    cQuery += cWhere
    cQuery += "  GROUP BY SF3.F3_EMISSAO, SF3.F3_NFISCAL, SF3.F3_SERIE, SF3.F3_CLIEFOR, SF3.F3_LOJA, SF3.F3_DTCANC "
    cQuery += "  ORDER BY SF3.F3_EMISSAO, SF3.F3_NFISCAL "

    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQuery)), cAlias, .F., .T.)

    While !(cAlias)->(Eof())

        IncProc("Nota " + AllTrim((cAlias)->NOTA))
        aSit := ZSitNota((cAlias)->DTCANC, (cAlias)->FIMP)

        RecLock(cAlsTmp, .T.)
            (cAlsTmp)->TR_DTFAT  := SToD((cAlias)->DTFAT)
            (cAlsTmp)->TR_CARGA  := ZGetCarga((cAlias)->PEDIDO)
            (cAlsTmp)->TR_PEDIDO := (cAlias)->PEDIDO
            (cAlsTmp)->TR_NREDUZ := Posicione("SA1", 1, xFilial("SA1") + (cAlias)->CLIENTE + (cAlias)->LOJA, "A1_NREDUZ")
            (cAlsTmp)->TR_NOTA   := (cAlias)->NOTA
            (cAlsTmp)->TR_SERIE  := (cAlias)->SERIE
            (cAlsTmp)->TR_VEND   := (cAlias)->VEND
            (cAlsTmp)->TR_NOMVEN := Posicione("SA3", 1, xFilial("SA3") + (cAlias)->VEND, "A3_NOME")
            (cAlsTmp)->TR_CODSIT := aSit[1]
            (cAlsTmp)->TR_SITUAC := aSit[2]
            (cAlsTmp)->TR_CFOP   := ZGetCfop((cAlias)->NOTA, (cAlias)->SERIE, (cAlias)->CLIENTE, (cAlias)->LOJA)
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

    ADD OPTION aRotina TITLE "Parametros"     ACTION "U_ZRFPAR" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Exportar Excel" ACTION "U_ZRFXLS" OPERATION 2 ACCESS 0

Return aRotina

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
    Local cArq      := GetTempPath() + "NotasFaturadas_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".xls"
    Local aLinha    := {}
    Local nI

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

    If ApOleClient("MsExcel")
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

//------------------------------------------------------------------
// CFOPs distintos da nota (mais de um separados por "/")
Static Function ZGetCfop(cNota, cSerie, cCli, cLoja)

    Local cRet   := ""
    Local cAlias := GetNextAlias()
    Local cQry   := ""

    cQry := " SELECT DISTINCT F3_CFO FROM " + RetSqlName("SF3") + " "
    cQry += "  WHERE F3_FILIAL = '" + xFilial("SF3") + "' AND F3_NFISCAL = '" + cNota + "' "
    cQry += "    AND F3_SERIE = '" + cSerie + "' AND F3_CLIEFOR = '" + cCli + "' "
    cQry += "    AND F3_LOJA = '" + cLoja + "' AND D_E_L_E_T_ = ' ' "
    cQry += "  ORDER BY F3_CFO "
    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cRet += IIf(Empty(cRet), "", "/") + AllTrim((cAlias)->F3_CFO)
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return cRet

//------------------------------------------------------------------
// AJUSTAR: de onde vem a carga/romaneio no seu ambiente.
// Padrao OMS = DAI (itens da carga) ligada ao pedido.
// Se for campo customizado (ex.: C5_XCARGA), troque por:
//   Return Posicione("SC5", 1, xFilial("SC5") + cPedido, "C5_XCARGA")
Static Function ZGetCarga(cPedido)

    Local cRet   := ""
    Local cAlias := GetNextAlias()
    Local cQry   := ""

    If Empty(cPedido)
        Return cRet
    EndIf

    cQry := " SELECT MAX(DAI_COD) AS CARGA FROM " + RetSqlName("DAI") + " "
    cQry += "  WHERE DAI_FILIAL = '" + xFilial("DAI") + "' AND DAI_PEDIDO = '" + cPedido + "' "
    cQry += "    AND D_E_L_E_T_ = ' ' "
    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        cRet := AllTrim((cAlias)->CARGA)
    EndIf
    (cAlias)->(DbCloseArea())

Return cRet
