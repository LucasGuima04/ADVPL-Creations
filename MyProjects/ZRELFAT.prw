#Include "Protheus.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} ZRELFAT
Relacao de notas fiscais de saida (venda, bonificacao, etc.) no padrao da
rotina NF-e Sefaz, exportada para Excel.

Colunas: Dt Faturamento | Carga | Pedido | Cliente (reduzido) | Nota/Serie |
         Cod Vendedor | Vendedor | Situacao da nota | CFOP

Chamada: menu Protheus -> U_ZRELFAT
@type  User Function
/*/
User Function ZRELFAT()

    Local aPergs  := {}
    Local aRet    := {}
    Local aSitu   := {"1=Todas", "2=Autorizadas", "3=Canceladas", "4=Pendentes/Rejeitadas/Denegadas"}
    Local dDe     := FirstDate(Date())
    Local dAte    := Date()

    aAdd(aPergs, {1, "Faturamento de",  dDe,  "", "", "", "", 60, .T.})
    aAdd(aPergs, {1, "Faturamento ate", dAte, "", "", "", "", 60, .T.})
    aAdd(aPergs, {2, "Situacao",        1,    aSitu, 90, "", .T.})

    If !ParamBox(aPergs, "Relacao de Notas Faturadas", @aRet)
        Return
    EndIf

    Processa({|| ZRelProc(aRet[1], aRet[2], Val(cValToChar(aRet[3])))}, ;
             "Aguarde", "Buscando notas fiscais...")

Return

//------------------------------------------------------------------
Static Function ZRelProc(dDe, dAte, nSitu)

    Local cAlias  := GetNextAlias()
    Local cQuery  := ""
    Local cWhere  := ""
    Local oExcel  := Nil
    Local cAba    := "Notas"
    Local cTit    := "Relacao de Notas Faturadas"
    Local cArq    := GetTempPath() + "NotasFaturadas_" + DToS(Date()) + "_" + StrTran(Time(), ":", "") + ".xls"
    Local nTot    := 0

    // Filtro de situacao (ver ZSitCase abaixo)
    Do Case
        Case nSitu == 2 ; cWhere := " AND SF3.F3_DTCANC = ' ' AND SF2.F2_FIMP = 'S' "
        Case nSitu == 3 ; cWhere := " AND SF3.F3_DTCANC <> ' ' "
        Case nSitu == 4 ; cWhere := " AND SF3.F3_DTCANC = ' ' AND SF2.F2_FIMP <> 'S' "
    EndCase

    /*
      Base = SF3 (livros fiscais): a nota cancelada continua la com F3_DTCANC
      preenchido, mesmo quando SF2/SD2 foram excluidos (D_E_L_E_T_ = '*').
      Por isso SF2/SD2 entram SEM filtro de D_E_L_E_T_.
      Uma nota pode ter varios CFOPs (varios itens): agrupamos por nota e
      juntamos os CFOPs distintos em uma unica coluna.
    */
    cQuery += " SELECT SF3.F3_EMISSAO   AS DTFAT, "
    cQuery += "        SF3.F3_NFISCAL   AS NOTA, "
    cQuery += "        SF3.F3_SERIE     AS SERIE, "
    cQuery += "        SF3.F3_CLIEFOR   AS CLIENTE, "
    cQuery += "        SF3.F3_LOJA      AS LOJA, "
    cQuery += "        SF3.F3_DTCANC    AS DTCANC, "
    cQuery += "        MAX(SF2.F2_FIMP)  AS FIMP, "
    cQuery += "        MAX(SF2.F2_VEND1) AS VEND, "
    cQuery += "        MAX(SD2.D2_PEDIDO) AS PEDIDO "
    cQuery += "   FROM " + RetSqlName("SF3") + " SF3 "
    cQuery += "   LEFT JOIN " + RetSqlName("SF2") + " SF2 "
    cQuery += "          ON SF2.F2_FILIAL = SF3.F3_FILIAL "
    cQuery += "         AND SF2.F2_DOC    = SF3.F3_NFISCAL "
    cQuery += "         AND SF2.F2_SERIE  = SF3.F3_SERIE "
    cQuery += "         AND SF2.F2_CLIENTE = SF3.F3_CLIEFOR "
    cQuery += "         AND SF2.F2_LOJA   = SF3.F3_LOJA "
    cQuery += "   LEFT JOIN " + RetSqlName("SD2") + " SD2 "
    cQuery += "          ON SD2.D2_FILIAL = SF3.F3_FILIAL "
    cQuery += "         AND SD2.D2_DOC    = SF3.F3_NFISCAL "
    cQuery += "         AND SD2.D2_SERIE  = SF3.F3_SERIE "
    cQuery += "         AND SD2.D2_CLIENTE = SF3.F3_CLIEFOR "
    cQuery += "         AND SD2.D2_LOJA   = SF3.F3_LOJA "
    cQuery += "  WHERE SF3.F3_FILIAL  = '" + xFilial("SF3") + "' "
    cQuery += "    AND SF3.F3_EMISSAO BETWEEN '" + DToS(dDe) + "' AND '" + DToS(dAte) + "' "
    cQuery += "    AND SF3.F3_ESPECIE = 'SPED' "                    // NF-e
    cQuery += "    AND SUBSTRING(SF3.F3_CFO,1,1) IN ('5','6','7') " // somente saidas
    cQuery += "    AND SF3.D_E_L_E_T_ = ' ' "
    cQuery += cWhere
    cQuery += "  GROUP BY SF3.F3_EMISSAO, SF3.F3_NFISCAL, SF3.F3_SERIE, "
    cQuery += "           SF3.F3_CLIEFOR, SF3.F3_LOJA, SF3.F3_DTCANC "
    cQuery += "  ORDER BY SF3.F3_EMISSAO, SF3.F3_NFISCAL "

    cQuery := ChangeQuery(cQuery)
    DbUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

    oExcel := FWMsExcelEx():New()
    oExcel:AddworkSheet(cAba)
    oExcel:AddTable(cAba, cTit)
    oExcel:AddColumn(cAba, cTit, "Dt Faturamento", 1, 4)
    oExcel:AddColumn(cAba, cTit, "Cod. Carga",     1, 1)
    oExcel:AddColumn(cAba, cTit, "Pedido",         1, 1)
    oExcel:AddColumn(cAba, cTit, "Cliente",        1, 1)
    oExcel:AddColumn(cAba, cTit, "Nota Fiscal",    1, 1)
    oExcel:AddColumn(cAba, cTit, "Cod. Vendedor",  1, 1)
    oExcel:AddColumn(cAba, cTit, "Vendedor",       1, 1)
    oExcel:AddColumn(cAba, cTit, "Situacao",       1, 1)
    oExcel:AddColumn(cAba, cTit, "CFOP",           1, 1)

    While !(cAlias)->(Eof())

        nTot++
        IncProc("Nota " + AllTrim((cAlias)->NOTA))

        oExcel:AddRow(cAba, cTit, { ;
            SToD((cAlias)->DTFAT), ;
            ZGetCarga((cAlias)->NOTA, (cAlias)->SERIE, (cAlias)->PEDIDO), ;
            (cAlias)->PEDIDO, ;
            AllTrim(Posicione("SA1", 1, xFilial("SA1") + (cAlias)->CLIENTE + (cAlias)->LOJA, "A1_NREDUZ")), ;
            AllTrim((cAlias)->NOTA) + "/" + AllTrim((cAlias)->SERIE), ;
            (cAlias)->VEND, ;
            AllTrim(Posicione("SA3", 1, xFilial("SA3") + (cAlias)->VEND, "A3_NOME")), ;
            ZSitNota((cAlias)->DTCANC, (cAlias)->FIMP), ;
            ZGetCfop((cAlias)->NOTA, (cAlias)->SERIE, (cAlias)->CLIENTE, (cAlias)->LOJA) ;
        })

        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    If nTot == 0
        MsgInfo("Nenhuma nota encontrada para os parametros informados.", "Atencao")
        Return
    EndIf

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
// Situacao da nota. CONFIRMAR os valores de F2_FIMP no seu ambiente
// (Configurador -> campo F2_FIMP) e, se quiser o status exato da Sefaz,
// trocar por consulta ao retorno do TSS (SPED054 / cStat).
Static Function ZSitNota(cDtCanc, cFimp)

    Local cRet := ""

    If !Empty(cDtCanc)
        cRet := "CANCELADA"
    Else
        Do Case
            Case cFimp == "S" ; cRet := "AUTORIZADA"
            Case cFimp == "T" ; cRet := "TRANSMITIDA - AGUARDANDO RETORNO"
            Case cFimp == "N" ; cRet := "REJEITADA / NAO AUTORIZADA"
            Case cFimp == "D" ; cRet := "DENEGADA"
            OtherWise         ; cRet := "NAO TRANSMITIDA"
        EndCase
    EndIf

Return cRet

//------------------------------------------------------------------
// CFOPs distintos da nota (se tiver mais de um, separa por "/")
Static Function ZGetCfop(cNota, cSerie, cCli, cLoja)

    Local cRet   := ""
    Local cAlias := GetNextAlias()
    Local cQry   := ""

    cQry := " SELECT DISTINCT F3_CFO FROM " + RetSqlName("SF3") + " "
    cQry += "  WHERE F3_FILIAL  = '" + xFilial("SF3") + "' "
    cQry += "    AND F3_NFISCAL = '" + cNota  + "' "
    cQry += "    AND F3_SERIE   = '" + cSerie + "' "
    cQry += "    AND F3_CLIEFOR = '" + cCli   + "' "
    cQry += "    AND F3_LOJA    = '" + cLoja  + "' "
    cQry += "    AND D_E_L_E_T_ = ' ' "
    cQry += "  ORDER BY F3_CFO "
    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        cRet += IIf(Empty(cRet), "", "/") + AllTrim((cAlias)->F3_CFO)
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

Return cRet

//------------------------------------------------------------------
// AJUSTAR: de onde vem o codigo da carga/romaneio no seu ambiente.
// Aqui esta o padrao do OMS (DAI = itens da carga, ligada ao pedido).
// Se voces usam campo customizado (ex.: C5_XCARGA), troque por:
//   Return Posicione("SC5", 1, xFilial("SC5") + cPedido, "C5_XCARGA")
Static Function ZGetCarga(cNota, cSerie, cPedido)

    Local cRet   := ""
    Local cAlias := GetNextAlias()
    Local cQry   := ""

    cQry := " SELECT MAX(DAI_COD) AS CARGA FROM " + RetSqlName("DAI") + " "
    cQry += "  WHERE DAI_FILIAL = '" + xFilial("DAI") + "' "
    cQry += "    AND DAI_PEDIDO = '" + cPedido + "' "
    cQry += "    AND D_E_L_E_T_ = ' ' "
    DbUseArea(.T., "TOPCONN", TCGenQry(,, ChangeQuery(cQry)), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        cRet := AllTrim((cAlias)->CARGA)
    EndIf
    (cAlias)->(DbCloseArea())

Return cRet
