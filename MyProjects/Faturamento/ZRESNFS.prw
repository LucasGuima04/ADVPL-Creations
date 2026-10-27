#Include "TOTVS.ch"

/*/{Protheus.doc} ZRESNFS
Resumo de NFs de saída por grupo de CFOP (sem CT-e / frete)
  - CFOP 5101 / 6101  : Qtd NFs, Qtd itens, Qtd faturada, Valor total
  - CFOP 5910 / 6910  : Qtd NFs, Qtd itens, Qtd faturada, Valor total
  - Demais CFOPs      : Qtd NFs, Qtd itens, Qtd faturada, Valor total
  - Total geral
  - NFs de saída CANCELADAS
@type User Function
@author Lucas Guimarães
@since 26/10/2026
/*/

Static cQryDbg := ""   // guarda as queries executadas (botão "Ver Query")

User Function ZRESNFS()
    Local aPergs := {}
    Local aRet   := {}
    Local aDados := {}
    Local nTamFil := Len(xFilial("SD2"))

    aAdd(aPergs, {1, "Emissão de" , FirstDate(Date())          , "", "", ""   , "", 50, .T.})
    aAdd(aPergs, {1, "Emissão até", Date()                     , "", "", ""   , "", 50, .T.})
    aAdd(aPergs, {1, "Filial de"  , Space(nTamFil)             , "", "", "SM0", "", 50, .F.})
    aAdd(aPergs, {1, "Filial até" , Replicate("Z", nTamFil)    , "", "", "SM0", "", 50, .T.})

    If ParamBox(aPergs, "Resumo de NFs de Saída por CFOP", @aRet)
        If aRet[1] > aRet[2]
            FWAlertWarning("A data inicial é maior que a data final.", "ZRESNFS")
            Return
        EndIf

        FWMsgRun(, {|| aDados := fCarrega(aRet[1], aRet[2], aRet[3], aRet[4]) }, "Aguarde", "Consultando notas de saída...")
        fTela(aDados, aRet[1], aRet[2])
    EndIf
Return

/*/ Espécies de documento que NÃO entram (CT-e / frete) /*/
Static Function fEspExc()
Return "('CTE','CTEOS','CTR','CTA','NFST')"

/*/ Monta as linhas da tabela
    Cada linha: {Descrição, QtdNFs, QtdItens, QtdFaturada, Valor, lCancelada} /*/
Static Function fCarrega(dDe, dAte, cFilDe, cFilAte)
    Local aDados := {}
    Local aGrp   := { {"CFOP 5101 / 6101", 0, 0, 0, 0, .F.}, ;
                      {"CFOP 5910 / 6910", 0, 0, 0, 0, .F.}, ;
                      {"Demais CFOPs"    , 0, 0, 0, 0, .F.} }
    Local oNFs   := JsonObject():New()   // controla NF distinta no total geral
    Local nTotNF := 0
    Local nTotIt := 0
    Local nTotQt := 0
    Local nTotVl := 0
    Local nCanc  := 0
    Local nG     := 0
    Local cChave := ""
    Local cQuery := ""
    Local cAlias := ""


    // ---------------------------------------------------------------
    // 1) NFs de saída válidas (SF2/SD2 não deletadas), por grupo de CFOP
    //    Agrupa por grupo + NF -> cada linha do resultado = 1 NF no grupo
    // ---------------------------------------------------------------
    cQuery := "SELECT GRUPO, D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, "
    cQuery += "       COUNT(*) ITENS, SUM(D2_QUANT) QUANT, SUM(D2_VALBRUT) VALOR "
    cQuery += "  FROM ( SELECT CASE WHEN SD2.D2_CF IN ('5101','6101') THEN '1' "
    cQuery += "                     WHEN SD2.D2_CF IN ('5910','6910') THEN '2' "
    cQuery += "                     ELSE '3' END GRUPO, "
    cQuery += "                SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE, SD2.D2_CLIENTE, SD2.D2_LOJA, "
    cQuery += "                SD2.D2_QUANT, SD2.D2_VALBRUT "
    cQuery += "           FROM " + RetSqlName("SD2") + " SD2 "
    cQuery += "          INNER JOIN " + RetSqlName("SF2") + " SF2 "
    cQuery += "             ON SF2.F2_FILIAL  = SD2.D2_FILIAL "
    cQuery += "            AND SF2.F2_DOC     = SD2.D2_DOC "
    cQuery += "            AND SF2.F2_SERIE   = SD2.D2_SERIE "
    cQuery += "            AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
    cQuery += "            AND SF2.F2_LOJA    = SD2.D2_LOJA "
    cQuery += "            AND SF2.D_E_L_E_T_ = ' ' "
    cQuery += "          WHERE SD2.D2_FILIAL  BETWEEN '" + cFilDe + "' AND '" + cFilAte + "' "
    cQuery += "            AND SD2.D2_EMISSAO BETWEEN '" + DToS(dDe) + "' AND '" + DToS(dAte) + "' "
    cQuery += "            AND SF2.F2_ESPECIE NOT IN " + fEspExc() + " "
    cQuery += "            AND SD2.D_E_L_E_T_ = ' ' ) TMP "
    cQuery += " GROUP BY GRUPO, D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA "

    cQryDbg := "-- NOTAS DE SAIDA" + CRLF + cQuery + CRLF + CRLF

    cAlias := MPSysOpenQuery(cQuery)

    While !(cAlias)->(Eof())
        nG := Val((cAlias)->GRUPO)

        aGrp[nG][2] += 1
        aGrp[nG][3] += (cAlias)->ITENS
        aGrp[nG][4] += (cAlias)->QUANT
        aGrp[nG][5] += (cAlias)->VALOR

        // Total geral: NF com CFOPs de grupos diferentes conta só uma vez
        cChave := (cAlias)->(D2_FILIAL + D2_DOC + D2_SERIE + D2_CLIENTE + D2_LOJA)
        If oNFs[cChave] == Nil
            oNFs[cChave] := .T.
            nTotNF++
        EndIf

        nTotIt += (cAlias)->ITENS
        nTotQt += (cAlias)->QUANT
        nTotVl += (cAlias)->VALOR

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    // ---------------------------------------------------------------
    // 2) NFs de saída canceladas (Livro Fiscal SF3 com F3_DTCANC preenchido)
    // ---------------------------------------------------------------
    cQuery := "SELECT COUNT(DISTINCT SF3.F3_FILIAL + SF3.F3_NFISCAL + SF3.F3_SERIE + SF3.F3_CLIEFOR + SF3.F3_LOJA) QTDCANC "
    cQuery += "  FROM " + RetSqlName("SF3") + " SF3 "
    cQuery += " WHERE SF3.F3_FILIAL  BETWEEN '" + cFilDe + "' AND '" + cFilAte + "' "
    cQuery += "   AND SF3.F3_ENTRADA BETWEEN '" + DToS(dDe) + "' AND '" + DToS(dAte) + "' "
    cQuery += "   AND SF3.F3_DTCANC <> ' ' "
    cQuery += "   AND SUBSTRING(SF3.F3_CFO, 1, 1) IN ('5','6','7') "
    cQuery += "   AND SF3.F3_ESPECIE NOT IN " + fEspExc() + " "
    cQuery += "   AND SF3.D_E_L_E_T_ = ' ' "

    cQryDbg += "-- CANCELADAS" + CRLF + cQuery

    cAlias := MPSysOpenQuery(cQuery)
    If !(cAlias)->(Eof())
        nCanc := (cAlias)->QTDCANC
    EndIf
    (cAlias)->(DbCloseArea())

    // ---------------------------------------------------------------
    // 3) Monta a tabela final
    // ---------------------------------------------------------------
    aAdd(aDados, aGrp[1])
    aAdd(aDados, aGrp[2])
    aAdd(aDados, aGrp[3])
    aAdd(aDados, {"TOTAL GERAL", nTotNF, nTotIt, nTotQt, nTotVl, .F.})
    aAdd(aDados, {"NFs de saída CANCELADAS", nCanc, 0, 0, 0, .T.})

    FreeObj(oNFs)
Return aDados

/*/ Tela com a tabela de resumo /*/
Static Function fTela(aDados, dDe, dAte)
    Local oDlg := Nil
    Local oBrw := Nil
    Local cTit := "Resumo NFs de Saída - " + DToC(dDe) + " a " + DToC(dAte)

    DEFINE MSDIALOG oDlg TITLE cTit FROM 0, 0 TO 300, 800 PIXEL

    oBrw := TWBrowse():New(5, 5, 392, 120, , ;
        {"Descrição", "Qtd NFs", "Qtd Itens", "Qtd Faturada", "Valor Total (R$)"}, ;
        {110, 50, 50, 80, 90}, oDlg, , , , , , , , , , , , .F., , .T., , .F., , , )
    oBrw:SetArray(aDados)
    oBrw:bLine := {|| fLinha(aDados, oBrw:nAt) }

    TButton():New(130, 188, "Ver Query"     , oDlg, {|| fVerQuery() }                , 65, 14, , , .F., .T.)
    TButton():New(130, 260, "Exportar Excel", oDlg, {|| fExcel(aDados, dDe, dAte) }, 65, 14, , , .F., .T.)
    TButton():New(130, 332, "Fechar"        , oDlg, {|| oDlg:End() }               , 65, 14, , , .F., .T.)

    ACTIVATE MSDIALOG oDlg CENTERED
Return

/*/ Mostra as queries executadas (para testar no SSMS) /*/
Static Function fVerQuery()
    Local oDlgQ := Nil
    Local oMemo := Nil

    DEFINE MSDIALOG oDlgQ TITLE "Queries executadas" FROM 0, 0 TO 500, 800 PIXEL
    oMemo := TMultiGet():New(5, 5, {|u| IIf(PCount() > 0, cQryDbg := u, cQryDbg) }, oDlgQ, 390, 240, , , , , , .T.)
    ACTIVATE MSDIALOG oDlgQ CENTERED
Return

/*/ Formata uma linha do browse /*/
Static Function fLinha(aDados, nAt)
    Local aL     := aDados[nAt]
    Local lCanc  := aL[6]
Return { aL[1], ;
         Transform(aL[2], "@E 999,999,999"), ;
         IIf(lCanc, "", Transform(aL[3], "@E 999,999,999")), ;
         IIf(lCanc, "", Transform(aL[4], "@E 999,999,999.9999")), ;
         IIf(lCanc, "", Transform(aL[5], "@E 999,999,999,999.99")) }

/*/ Exporta a tabela para Excel (.xlsx) /*/
Static Function fExcel(aDados, dDe, dAte)
    Local oExcel  := FWMsExcelXlsx():New()
    Local cWS     := "Resumo"
    Local cTab    := "NFs de Saída - " + DToC(dDe) + " a " + DToC(dAte)
    Local cNome   := "ZRESNFS_" + DToS(Date()) + StrTran(Time(), ":", "") + ".xlsx"
    Local cArqSrv := "\spool\" + cNome
    Local cDirLoc := GetTempPath()
    Local nI      := 0
    Local aL      := {}

    oExcel:AddWorkSheet(cWS)
    oExcel:AddTable(cWS, cTab)
    oExcel:AddColumn(cWS, cTab, "Descrição"       , 1, 1)
    oExcel:AddColumn(cWS, cTab, "Qtd NFs"         , 3, 2)
    oExcel:AddColumn(cWS, cTab, "Qtd Itens"       , 3, 2)
    oExcel:AddColumn(cWS, cTab, "Qtd Faturada"    , 3, 2)
    oExcel:AddColumn(cWS, cTab, "Valor Total (R$)", 3, 3)

    For nI := 1 To Len(aDados)
        aL := aDados[nI]
        oExcel:AddRow(cWS, cTab, { aL[1], aL[2], ;
                                   IIf(aL[6], "", aL[3]), ;
                                   IIf(aL[6], "", aL[4]), ;
                                   IIf(aL[6], "", aL[5]) })
    Next nI

    oExcel:Activate()
    oExcel:GetXMLFile(cArqSrv)
    oExcel:DeActivate()
    FreeObj(oExcel)

    If File(cArqSrv)
        CpyS2T(cArqSrv, cDirLoc)
        FErase(cArqSrv)
        ShellExecute("open", cDirLoc + cNome, "", cDirLoc, 1)
    Else
        FWAlertError("Não foi possível gerar o arquivo Excel.", "ZRESNFS")
    EndIf
Return
