#Include "TOTVS.CH"
#Include "FWPRINTSETUP.CH"
#Include "RPTDEF.CH"

//-- Bancos suportados
#Define FXBOL_BB      "001"
#Define FXBOL_SANT    "033"
#Define FXBOL_BANRI   "041"
#Define FXBOL_CAIXA   "104"
#Define FXBOL_BRADE   "237"
#Define FXBOL_ITAU    "341"
#Define FXBOL_SAFRA   "422"
#Define FXBOL_SICRED  "748"
#Define FXBOL_SICOOB  "756"

//-- Indices do array aBanco
#Define BCO_COD     1
#Define BCO_DVBCO   2
#Define BCO_AGE     3
#Define BCO_DVAGE   4
#Define BCO_CTA     5
#Define BCO_DVCTA   6
#Define BCO_NOME    7
#Define BCO_SUBC    8
#Define BCO_CEMP    9
#Define BCO_CART    10
#Define BCO_LOC1    11
#Define BCO_LOC2    12
#Define BCO_MSG1    13
#Define BCO_MSG2    14
#Define BCO_MSG3    15
#Define BCO_MSG4    16
#Define BCO_AGECTA  17
#Define BCO_POSTO   18
#Define BCO_ACEITE  19
#Define BCO_BCOFORM 20
#Define TAM_BCO     20

//-- Indices do array aTitulo
#Define TIT_REC     1
#Define TIT_NUM     2
#Define TIT_DTEMI   3
#Define TIT_DTVCTO  4
#Define TIT_VALOR   5
#Define TIT_NNUM    6
#Define TIT_DVNNUM  7
#Define TIT_NNUMF   8
#Define TIT_CODBAR  9
#Define TIT_LINDIG  10
#Define TIT_ESPECI  11
#Define TAM_TIT     11

//-- Indices do array aCedente
#Define CED_NOME    1
#Define CED_CNPJ    2
#Define CED_END     3
#Define CED_BAIRRO  4
#Define CED_CIDADE  5
#Define CED_EST     6
#Define CED_CEP     7
#Define TAM_CED     7

//-- Indices do array aSacado
#Define SAC_NOME    1
#Define SAC_CNPJ    2
#Define SAC_END     3
#Define SAC_BAIRRO  4
#Define SAC_CIDADE  5
#Define SAC_CEP     6
#Define TAM_SAC     6

//-- Indices do array _aDados (grade de selecao)
#Define DAD_MARC    1
#Define DAD_PREF    2
#Define DAD_NUM     3
#Define DAD_PARC    4
#Define DAD_TIPO    5
#Define DAD_CLI     6
#Define DAD_LOJA    7
#Define DAD_NOME    8
#Define DAD_VALOR   9
#Define DAD_VCTO    10

/*/{Protheus.doc} FXBOL002
Emissao de boletos bancarios. Exibe tela de parametros, grade de selecao
de titulos e imprime em PDF via FWMSPrinter.
Bancos: BB (001), Santander (033), Banrisul (041), Caixa (104),
Bradesco (237), Itau (341), Safra (422), Sicredi (748), Sicoob (756).
@type User Function
@author BMTEC
@since 01/07/2025
@param oDuplic, Object, Objeto FWMSPrinter (modo automatico)
@param cBancoAuto, Character, Codigo do banco (modo automatico)
@param cDocAuto, Character, Numero do titulo (modo automatico)
/*/
User Function FXBOL002(oDuplic, cBancoAuto, cDocAuto)

    Local oOK   := Nil
    Local oNO   := Nil
    Local nDlgH := 0
    Local nDlgW := 0
    Local oWebChn := Nil
    Local oPnlTop := Nil
    Local oPnlBot := Nil

    Private _oDlg      := Nil
    Private _oBrw      := Nil
    Private _oWebEng   := Nil
    Private _aDados    := {}
    Private cPerg      := "FXBOL00002"
    Private _lAuto     := ValType(cDocAuto) == "C"
    Private _aBancoSup := {}

    Default oDuplic    := Nil
    Default cBancoAuto := ""
    Default cDocAuto   := ""

    aAdd(_aBancoSup, FXBOL_BB)
    aAdd(_aBancoSup, FXBOL_SANT)
    aAdd(_aBancoSup, FXBOL_BANRI)
    aAdd(_aBancoSup, FXBOL_CAIXA)
    aAdd(_aBancoSup, FXBOL_BRADE)
    aAdd(_aBancoSup, FXBOL_ITAU)
    aAdd(_aBancoSup, FXBOL_SAFRA)
    aAdd(_aBancoSup, FXBOL_SICRED)
    aAdd(_aBancoSup, FXBOL_SICOOB)

    //-- Cria parametros SX1 automaticamente se ainda nao existirem
    _BolCriaSX1()

    If _lAuto
        dbSelectArea("SEE")
        SEE->(dbSetOrder(1))
        If SEE->(MsSeek(xFilial("SEE") + cBancoAuto))
            MV_PAR01 := cBancoAuto
            MV_PAR02 := AllTrim(SEE->EE_AGENCIA)
            MV_PAR03 := AllTrim(SEE->EE_CONTA)
            MV_PAR04 := AllTrim(SEE->EE_SUBCTA)
            MV_PAR05 := ""
            MV_PAR06 := "ZZZ"
            MV_PAR07 := cDocAuto
            MV_PAR08 := cDocAuto
            MV_PAR09 := ""
        Else
            MsgAlert("Banco " + cBancoAuto + " nao encontrado no SEE.")
            Return
        EndIf
    Else
        If !Pergunte(cPerg, .T.)
            Return
        EndIf
        If aScan(_aBancoSup, MV_PAR01) == 0
            MsgAlert("Banco " + MV_PAR01 + " nao suportado nesta rotina.")
            Return
        EndIf
    EndIf

    _BolCarrega()

    If _lAuto
        _BolImprime()
    Else
        oOK   := LoadBitmap(GetResources(), "LBTIK")
        oNO   := LoadBitmap(GetResources(), "LBNO")
        nDlgH := oMainWnd:nClientHeight / 1.3
        nDlgW := oMainWnd:nClientWidth  / 1.3

        DEFINE MSDIALOG _oDlg TITLE "Emissao de Boletos Bancarios" From 0, 0 To nDlgH, nDlgW OF oMainWnd PIXEL

        //-- Cabecalho: banner HTML (somente exibicao) via TWebEngine
        oPnlTop := TPanel():New(0, 0, "", _oDlg, , , , , RGB(255, 255, 255), nDlgW, 46)
        oPnlTop:Align := CONTROL_ALIGN_TOP

        oWebChn := TWebChannel():New()
        _oWebEng := TWebEngine():New(oPnlTop, 0, 0, 46, nDlgW, , oWebChn:connect())
        _oWebEng:Align := CONTROL_ALIGN_ALLCLIENT
        _oWebEng:SetHtml(_BolHtmlCab())

        //-- Rodape: botoes de acao
        oPnlBot := TPanel():New(0, 0, "", _oDlg, , , , , RGB(255, 255, 255), nDlgW, 24)
        oPnlBot:Align := CONTROL_ALIGN_BOTTOM

        TButton():New(005, 010, "Imprimir",   oPnlBot, {|| Processa({|| _BolImprime()})}, 80, 14,,,,.T.)
        TButton():New(005, 100, "Sel. Todos", oPnlBot, {|| _BolMarkAllArr()},             80, 14,,,,.T.)
        TButton():New(005, 190, "Sair",       oPnlBot, {|| _BolSair()},                   80, 14,,,,.T.)

        //-- Grade de selecao de titulos (TCBrowse nativa - logica inalterada)
        _oBrw := TCBrowse():New(0, 0, 0, 0, , {}, {}, _oDlg, , , , , {||}, , , , , , , .F., , .T., , .F., , , )
        _oBrw:Align := CONTROL_ALIGN_ALLCLIENT
        _oBrw:SetArray(_aDados)

        _oBrw:AddColumn(TCColumn():New("",           {|| _BolMarcaBmp(_aDados[_oBrw:nAt, DAD_MARC], oOK, oNO)},  ,,,  "CENTER",,.T.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Prefixo",    {|| AllTrim(_aDados[_oBrw:nAt, DAD_PREF])},                  ,,,  "LEFT",  ,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Titulo",     {|| AllTrim(_aDados[_oBrw:nAt, DAD_NUM])},                   ,,,  "LEFT",  ,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Parcela",    {|| AllTrim(_aDados[_oBrw:nAt, DAD_PARC])},                  ,,,  "CENTER",,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Tipo",       {|| AllTrim(_aDados[_oBrw:nAt, DAD_TIPO])},                  ,,,  "LEFT",  ,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Nome",       {|| AllTrim(_aDados[_oBrw:nAt, DAD_NOME])},                  ,,,  "LEFT",  ,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Valor",      {|| _aDados[_oBrw:nAt, DAD_VALOR]},   "@E 9,999,999.99",,,   "RIGHT",,.F.,.F.,,,,.F.,))
        _oBrw:AddColumn(TCColumn():New("Vencimento", {|| DToC(_aDados[_oBrw:nAt, DAD_VCTO])},                     ,,,  "CENTER",,.F.,.F.,,,,.F.,))

        _oBrw:bLDblClick := {|| _BolMarkArr()}
        _oBrw:bKeyDown   := {|nKey| If(nKey == 32, _BolMarkArr(), Nil)}
        _oBrw:Refresh()

        ACTIVATE MSDIALOG _oDlg CENTERED
    EndIf

Return

/*/{Protheus.doc} _BolHtmlCab
Monta o HTML do banner de cabecalho da tela (somente exibicao). Mostra o
banco, agencia/conta e o resumo do lote (qtde de titulos e valor total).
@type Static Function
@author BMTEC
@since 24/07/2026
@return Character, HTML do cabecalho
/*/
Static Function _BolHtmlCab()

    Local cHtml  := ""
    Local nTot   := 0
    Local nQtd   := Len(_aDados)
    Local nSel   := 0
    Local nI     := 0
    Local cBco   := MV_PAR01
    Local cNomeB := _BolNomeBanco(cBco)
    Local cAge   := AllTrim(MV_PAR02)
    Local cCta   := AllTrim(MV_PAR03)

    For nI := 1 To Len(_aDados)
        If _aDados[nI][DAD_MARC]
            nTot += _aDados[nI][DAD_VALOR]
            nSel++
        EndIf
    Next nI

    cHtml += "<!DOCTYPE html><html><head><meta charset='utf-8'><style>"
    cHtml += "*{margin:0;padding:0;box-sizing:border-box;}"
    cHtml += "html,body{height:100%;font-family:'Segoe UI',Tahoma,Arial,sans-serif;}"
    cHtml += ".hd{display:flex;align-items:center;justify-content:space-between;height:100%;"
    cHtml += "background:linear-gradient(135deg,#0c4a6e 0%,#0c9abe 100%);color:#fff;padding:0 22px;}"
    cHtml += ".lf{display:flex;align-items:center;gap:14px;}"
    cHtml += ".ic{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,0.18);"
    cHtml += "display:flex;align-items:center;justify-content:center;font-size:20px;}"
    cHtml += ".ti{font-size:15px;font-weight:700;letter-spacing:.3px;}"
    cHtml += ".sb{font-size:11px;opacity:.85;margin-top:2px;}"
    cHtml += ".rg{text-align:right;}"
    cHtml += ".vl{font-size:18px;font-weight:700;line-height:1.1;}"
    cHtml += ".lb{font-size:10px;text-transform:uppercase;opacity:.8;letter-spacing:.5px;}"
    cHtml += "</style></head><body>"
    cHtml += "<div class='hd'>"
    cHtml += "<div class='lf'><div class='ic'>&#128179;</div>"
    cHtml += "<div><div class='ti'>Emiss&atilde;o de Boletos Banc&aacute;rios</div>"
    cHtml += "<div class='sb'>" + cBco + " - " + cNomeB + " &nbsp;&bull;&nbsp; Ag " + cAge + " / Cc " + cCta + "</div>"
    cHtml += "</div></div>"
    cHtml += "<div class='rg'><div class='vl'>R$ " + AllTrim(Transform(nTot, "@E 9,999,999.99")) + "</div>"
    cHtml += "<div class='lb'>" + cValToChar(nSel) + " de " + cValToChar(nQtd) + " selecionados</div></div>"
    cHtml += "</div></body></html>"

Return cHtml

/*/{Protheus.doc} _BolCriaSX1
Cria automaticamente os parametros do grupo FXBOL00002 no SX1 caso ainda
nao existam. Chamada uma unica vez na entrada da rotina.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolCriaSX1()

    //-- {ordem, descricao, tipo, tamanho, decimais, F3, default}
    Local aDef := {}
    Local aAreaOld := GetArea()
    Local i    := 0

    AAdd(aDef, {"01", "Banco           ", "C", 3,  0, "SA6", ""             })
    AAdd(aDef, {"02", "Agencia         ", "C", 5,  0, "",    ""             })
    AAdd(aDef, {"03", "Conta           ", "C", 10, 0, "",    ""             })
    AAdd(aDef, {"04", "Sub-Conta       ", "C", 3,  0, "",    ""             })
    AAdd(aDef, {"05", "Prefixo De      ", "C", 3,  0, "",    ""             })
    AAdd(aDef, {"06", "Prefixo Ate     ", "C", 3,  0, "",    "ZZZ"          })
    AAdd(aDef, {"07", "Titulo De       ", "C", 9,  0, "",    ""             })
    AAdd(aDef, {"08", "Titulo Ate      ", "C", 9,  0, "",    Replicate("9", 9)})
    AAdd(aDef, {"09", "Mensagem Extra  ", "C", 60, 0, "",    ""             })

    dbSelectArea("SX1")
    dbSetOrder(1)

    For i := 1 To Len(aDef)
        If !SX1->(dbSeek(cPerg + aDef[i][1]))
            Reclock("SX1", .T.)
            SX1->X1_GRUPO   := cPerg
            SX1->X1_ORDEM   := aDef[i][1]
            SX1->X1_PERGUNT := aDef[i][2]
            SX1->X1_TIPO    := aDef[i][3]
            SX1->X1_TAMANHO := aDef[i][4]
            SX1->X1_DECIMAL := aDef[i][5]
            SX1->X1_F3      := aDef[i][6]
            SX1->X1_DEF01   := aDef[i][7]
            SX1->X1_PYME    := "N"
            SX1->X1_GSC     := "G"
            MSUnlock()
        EndIf
    Next i

    RestArea(aAreaOld)

Return

/*/{Protheus.doc} _BolCarrega
Carrega titulos do SE1 (saldo > 0) no array _aDados para a grade TCBrowse.
Filtra por banco, prefixo e numero conforme parametros da tela.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolCarrega()

    Local cQuery  := ""
    Local cAlias  := GetNextAlias()

    cQuery := " SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO, "
    cQuery += "        SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_VALOR, SE1.E1_VENCTO, "
    cQuery += "        SA1.A1_NOME "
    cQuery += " FROM " + RetSqlName("SE1") + " SE1 "
    cQuery += " INNER JOIN " + RetSqlName("SA1") + " SA1 "
    cQuery += "    ON SA1.A1_FILIAL  = SE1.E1_FILIAL "
    cQuery += "   AND SA1.A1_COD     = SE1.E1_CLIENTE "
    cQuery += "   AND SA1.A1_LOJA    = SE1.E1_LOJA "
    cQuery += "   AND SA1.D_E_L_E_T_ = ' ' "
    cQuery += " WHERE SE1.E1_FILIAL   = '" + xFilial("SE1") + "' "
    cQuery += "   AND SE1.D_E_L_E_T_  = ' ' "
    cQuery += "   AND SE1.E1_SALDO    > 0 "
    cQuery += "   AND SE1.E1_VENCTO   > '20260101' "
    cQuery += "   AND SE1.E1_TIPO    <> 'DP' "
    cQuery += "   AND SE1.E1_PREFIXO  BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "' "
    cQuery += "   AND SE1.E1_NUM      BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR08 + "' "
    cQuery += " ORDER BY SE1.E1_NUM "

    cQuery := ChangeQuery(cQuery)

    dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAlias, .F., .T.)

    _aDados := {}

    While !(cAlias)->(EoF())
        aAdd(_aDados, {;
            .F.,;
            (cAlias)->E1_PREFIXO,;
            (cAlias)->E1_NUM,;
            (cAlias)->E1_PARCELA,;
            (cAlias)->E1_TIPO,;
            (cAlias)->E1_CLIENTE,;
            (cAlias)->E1_LOJA,;
            Left(AllTrim((cAlias)->A1_NOME), 40),;
            (cAlias)->E1_VALOR,;
            SToD((cAlias)->E1_VENCTO);
        })
        (cAlias)->(dbSkip())
    EndDo

    (cAlias)->(dbCloseArea())

Return

/*/{Protheus.doc} _BolMarkArr
Alterna a marcacao do titulo posicionado no TCBrowse.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolMarkArr()

    If Len(_aDados) == 0 .Or. _oBrw:nAt < 1
        Return
    EndIf

    _aDados[_oBrw:nAt, DAD_MARC] := !_aDados[_oBrw:nAt, DAD_MARC]
    _oBrw:Refresh()
    _BolAtuCab()

Return

/*/{Protheus.doc} _BolMarkAllArr
Marca todos os titulos se nenhum estiver marcado; desmarca todos caso contrario.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolMarkAllArr()

    Local lMarcar := .T.
    Local nI      := 0

    For nI := 1 To Len(_aDados)
        If _aDados[nI][DAD_MARC]
            lMarcar := .F.
            Exit
        EndIf
    Next nI

    For nI := 1 To Len(_aDados)
        _aDados[nI][DAD_MARC] := lMarcar
    Next nI

    _oBrw:Refresh()
    _BolAtuCab()

Return

/*/{Protheus.doc} _BolAtuCab
Reatualiza o banner HTML de cabecalho conforme a selecao de titulos muda.
@type Static Function
@author BMTEC
@since 24/07/2026
/*/
Static Function _BolAtuCab()

    If _oWebEng != Nil
        _oWebEng:SetHtml(_BolHtmlCab())
    EndIf

Return

/*/{Protheus.doc} _BolMarcaBmp
Retorna o bitmap de marcado (oOK) ou desmarcado (oNO) para a coluna de check.
@type Static Function
@author BMTEC
@since 01/07/2025
@param lMarcado, Logical, Estado de marcacao do titulo
@param oOK, Object, Bitmap de marcado
@param oNO, Object, Bitmap de desmarcado
@return Object, Bitmap correspondente ao estado
/*/
Static Function _BolMarcaBmp(lMarcado, oOK, oNO)

    If lMarcado
        Return oOK
    EndIf

Return oNO

/*/{Protheus.doc} _BolSair
Fecha o dialogo de selecao de titulos.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolSair()

    If _oDlg != Nil
        _oDlg:End()
    EndIf

Return

/*/{Protheus.doc} _BolImprime
Inicializa o FWMSPrinter e itera os titulos marcados no array _aDados para impressao.
@type Static Function
@author BMTEC
@since 01/07/2025
/*/
Static Function _BolImprime()

    Local oDuplic   := Nil
    Local aBanco    := {}
    Local aCedente  := {}
    Local aSacado   := {}
    Local aTitulo   := {}
    Local nContBol  := 0
    Local cNomeArq  := "BOLETO_" + DTOS(MsDate()) + StrTran(Time(), ":", "")
    Local lImprimiu := .F.
    Local nI        := 0

    oDuplic := FWMSPrinter():New(cNomeArq, IMP_PDF, .F., "", , , @oDuplic, , , , , .T.)
    oDuplic:SetResolution(72)
    oDuplic:SetPortrait()
    oDuplic:SetPaperSize(DMPAPER_A4)
    oDuplic:SetMargin(10, 10, 10, 10)

    _BolSetBanco(@aBanco)

    If Len(aBanco) == 0
        //oDuplic:Destroy()
        Return
    EndIf

    _BolSetCedente(@aCedente)

    For nI := 1 To Len(_aDados)

        If _aDados[nI][DAD_MARC] .Or. _lAuto

            dbSelectArea("SE1")
            dbSetOrder(1)

            If !SE1->(dbSeek(xFilial("SE1") + _aDados[nI][DAD_PREF] + _aDados[nI][DAD_NUM] + _aDados[nI][DAD_PARC] + _aDados[nI][DAD_TIPO]))
                MsgAlert("Titulo " + AllTrim(_aDados[nI][DAD_NUM]) + " nao encontrado no SE1.")
                Loop
            EndIf

            //-- Se ja impresso, confirma reimpressao
            If SE1->E1_BOLIMP == "S" .And. !Empty(SE1->E1_NUMBCO)
                If !IsBlind()
                    If !MsgYesNo("Boleto " + AllTrim(SE1->E1_NUMBCO) + " (Titulo " + AllTrim(SE1->E1_NUM) + ") ja impresso. Reimprimir?")
                        Loop
                    EndIf
                EndIf
            EndIf

            //-- Calcula Nosso Numero e atualiza SE1
            _BolNossoNum(aBanco)

            //-- Monta array de dados do sacado
            _BolSetSacado(@aSacado)

            //-- Monta array do titulo
            aTitulo := AFill(Array(TAM_TIT), "")
            aTitulo[TIT_REC]    := SE1->(RecNo())
            aTitulo[TIT_NUM]    := AllTrim(SE1->E1_PREFIXO) + Right(AllTrim(SE1->E1_NUM), 9) + "-" + SE1->E1_PARCELA
            aTitulo[TIT_DTEMI]  := SubStr(DTOS(SE1->E1_EMISSAO), 7, 2) + "/" + SubStr(DTOS(SE1->E1_EMISSAO), 5, 2) + "/" + SubStr(DTOS(SE1->E1_EMISSAO), 1, 4)
            aTitulo[TIT_DTVCTO] := SubStr(DTOS(SE1->E1_VENCTO), 7, 2) + "/" + SubStr(DTOS(SE1->E1_VENCTO), 5, 2) + "/" + SubStr(DTOS(SE1->E1_VENCTO), 1, 4)
            aTitulo[TIT_VALOR]  := SE1->E1_SALDO + SE1->E1_ACRESC - SE1->E1_DECRESC
            aTitulo[TIT_NNUM]   := AllTrim(SE1->E1_NUMBCO)
            aTitulo[TIT_DVNNUM] := ""
            aTitulo[TIT_NNUMF]  := AllTrim(SE1->E1_NUMBCO)
            aTitulo[TIT_ESPECI] := "DM"

            //-- Gera codigo de barras e linha digitavel
            _BolCodBar(aBanco, @aTitulo)

            If Len(AllTrim(aTitulo[TIT_CODBAR])) == 44
                _BolLinDig(aBanco, @aTitulo)
                _BolImpTit(oDuplic, aBanco, aCedente, aSacado, aTitulo)
                nContBol++
                lImprimiu := .T.

                //-- Marca como impresso
                Reclock("SE1", .F.)
                SE1->E1_BOLIMP  := "S"
                SE1->E1_PORTADO := aBanco[BCO_COD]
                MSUnlock()
            EndIf

        EndIf

    Next nI

    If lImprimiu
        If !_lAuto
            oDuplic:Preview()
        EndIf
    Else
        MsgAlert("Nenhum titulo selecionado ou nenhum boleto gerado.")
        //oDuplic:Destroy()
    EndIf

Return

/*/{Protheus.doc} _BolSetBanco
Carrega o array aBanco com dados do banco a partir do SEE e SA6.
@type Static Function
@author BMTEC
@since 01/07/2025
@param aBanco, Array, Array de dados do banco (por referencia)
/*/
Static Function _BolSetBanco(aBanco)

    Local cAgeFmt  := ""
    Local cCtaFmt  := ""
    Local cAgeCta  := ""
    Local cBcoFmt  := ""
    Local cLocPag  := ""
    Local cBco     := MV_PAR01
    Local cAge     := MV_PAR02
    Local cCta     := MV_PAR03
    Local cSub     := MV_PAR04

    aBanco := AFill(Array(TAM_BCO), "")

    dbSelectArea("SEE")
    dbSetOrder(1)

    If !SEE->(dbSeek(xFilial("SEE") + cBco + cAge + cCta + cSub))
        MsgAlert("Parametros bancarios nao encontrados no SEE para banco " + cBco + " / " + cAge + " / " + cCta)
        aBanco := {}
        Return
    EndIf

    dbSelectArea("SA6")
    dbSetOrder(1)
    SA6->(dbSeek(xFilial("SA6") + cBco + cAge + cCta))

    aBanco[BCO_COD]    := cBco
    aBanco[BCO_AGE]    := AllTrim(SEE->EE_AGENCIA)
    aBanco[BCO_DVAGE]  := AllTrim(SEE->EE_DVAGE)
    aBanco[BCO_CTA]    := AllTrim(SEE->EE_CONTA)
    aBanco[BCO_DVCTA]  := AllTrim(SEE->EE_DVCTA)
    aBanco[BCO_SUBC]   := AllTrim(SEE->EE_SUBCTA)
    aBanco[BCO_CEMP]   := AllTrim(SEE->EE_CODEMP)
    aBanco[BCO_CART]   := AllTrim(SEE->EE_CODCART)
    aBanco[BCO_ACEITE] := "N"
    If SEE->(FieldPos("EE_POSTO")) > 0
        aBanco[BCO_POSTO] := AllTrim(SEE->EE_POSTO)
    EndIf

    //-- Mensagens do boleto (avaliadas dinamicamente se tiverem macros)
    If !Empty(AllTrim(SEE->EE_FORMEN1))
        aBanco[BCO_MSG1] := &(AllTrim(SEE->EE_FORMEN1))
    EndIf
    If !Empty(AllTrim(SEE->EE_FORMEN2))
        aBanco[BCO_MSG2] := &(AllTrim(SEE->EE_FORMEN2))
    EndIf
    If !Empty(AllTrim(SEE->EE_FOREXT1))
        aBanco[BCO_MSG3] := &(AllTrim(SEE->EE_FOREXT1))
    EndIf
    If !Empty(AllTrim(SEE->EE_FOREXT2))
        aBanco[BCO_MSG4] := &(AllTrim(SEE->EE_FOREXT2))
    EndIf

    //-- Nome do banco
    If SA6->(Found())
        aBanco[BCO_NOME] := AllTrim(SA6->A6_NREDUZ)
    Else
        aBanco[BCO_NOME] := _BolNomeBanco(cBco)
    EndIf

    //-- DV do banco e formato padrao
    aBanco[BCO_DVBCO] := _BolDvBanco(cBco)
    cBcoFmt := cBco + "-" + aBanco[BCO_DVBCO]
    aBanco[BCO_BCOFORM] := cBcoFmt

    //-- Agencia/Conta formatadas
    cAgeFmt := aBanco[BCO_AGE]
    If !Empty(aBanco[BCO_DVAGE])
        cAgeFmt += "-" + aBanco[BCO_DVAGE]
    EndIf

    cCtaFmt := aBanco[BCO_CTA]
    If !Empty(aBanco[BCO_DVCTA])
        cCtaFmt += "-" + aBanco[BCO_DVCTA]
    EndIf

    //-- Agencia/Codigo beneficiario formatado por banco
    If cBco == FXBOL_SICRED
        cAgeCta := SubStr(aBanco[BCO_CEMP], 1, 4) + "." + ;
                   SubStr(aBanco[BCO_CEMP], 5, 2) + "." + ;
                   SubStr(aBanco[BCO_CEMP], 7, 5)
    ElseIf cBco == FXBOL_BB .Or. cBco == FXBOL_BRADE .Or. cBco == FXBOL_SAFRA
        cAgeCta := cAgeFmt + "/" + cCtaFmt
    Else
        cAgeCta := cAgeFmt + "/" + AllTrim(aBanco[BCO_CEMP])
    EndIf
    aBanco[BCO_AGECTA] := cAgeCta

    //-- Local de pagamento por banco
    cLocPag := _BolLocalPag(cBco)
    aBanco[BCO_LOC1] := cLocPag

Return

/*/{Protheus.doc} _BolSetCedente
Carrega o array aCedente com dados da empresa (SM0).
@type Static Function
@author BMTEC
@since 01/07/2025
@param aCedente, Array, Array de dados do cedente (por referencia)
/*/
Static Function _BolSetCedente(aCedente)

    aCedente := AFill(Array(TAM_CED), "")

    aCedente[CED_NOME]   := AllTrim(SM0->M0_NOMECOM)
    aCedente[CED_CNPJ]   := Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")
    aCedente[CED_END]    := AllTrim(SM0->M0_ENDCOB)
    aCedente[CED_BAIRRO] := AllTrim(SM0->M0_BAIRCOB)
    aCedente[CED_CIDADE] := AllTrim(SM0->M0_CIDCOB)
    aCedente[CED_EST]    := SM0->M0_ESTCOB
    aCedente[CED_CEP]    := SubStr(SM0->M0_CEPCOB, 1, 5) + "-" + SubStr(SM0->M0_CEPCOB, 6, 3)

Return

/*/{Protheus.doc} _BolSetSacado
Carrega o array aSacado com dados do cliente (SA1) a partir do SE1 atual.
@type Static Function
@author BMTEC
@since 01/07/2025
@param aSacado, Array, Array de dados do sacado (por referencia)
/*/
Static Function _BolSetSacado(aSacado)

    Local cCGCCPF  := ""
    Local cEndeco  := ""
    Local cBairro  := ""
    Local cCidade  := ""
    Local cCEP     := ""

    aSacado := AFill(Array(TAM_SAC), "")

    dbSelectArea("SA1")
    dbSetOrder(1)
    SA1->(dbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))

    If SA1->(Found()) .And. SA1->A1_COD == SE1->E1_CLIENTE .And. SA1->A1_LOJA == SE1->E1_LOJA

        If Len(AllTrim(SA1->A1_CGC)) < 14
            cCGCCPF := Transform(SA1->A1_CGC, "@R 999.999.999-99")
        Else
            cCGCCPF := Transform(SA1->A1_CGC, "@R 99.999.999/9999-99")
        EndIf

        If !Empty(SA1->A1_ENDCOB)
            cEndeco  := AllTrim(SA1->A1_ENDCOB)
            cBairro  := AllTrim(SA1->A1_BAIRROC)
            cCidade  := AllTrim(SA1->A1_MUNC)
            cCEP     := SubStr(SA1->A1_CEPC, 1, 5) + "-" + SubStr(SA1->A1_CEPC, 6, 3)
        Else
            cEndeco  := AllTrim(SA1->A1_END)
            cBairro  := AllTrim(SA1->A1_BAIRRO)
            cCidade  := AllTrim(SA1->A1_MUN)
            cCEP     := SubStr(SA1->A1_CEP, 1, 5) + "-" + SubStr(SA1->A1_CEP, 6, 3)
        EndIf

        aSacado[SAC_NOME]   := AllTrim(SA1->A1_NOME)
        aSacado[SAC_CNPJ]   := cCGCCPF
        aSacado[SAC_END]    := cEndeco
        aSacado[SAC_BAIRRO] := cBairro
        aSacado[SAC_CIDADE] := cCidade
        aSacado[SAC_CEP]    := cCEP

    Else
        aSacado[SAC_NOME] := AllTrim(SE1->E1_NOMCLI)
    EndIf

Return

/*/{Protheus.doc} _BolNossoNum
Calcula e grava o Nosso Numero em SE1->E1_NUMBCO para o banco informado.
Incrementa SEE->EE_FAXATU com RecLock.
@type Static Function
@author BMTEC
@since 01/07/2025
@param aBanco, Array, Array de dados do banco
/*/
Static Function _BolNossoNum(aBanco)

    Local nSeq    := 0
    Local cSeq    := ""
    Local cDV     := ""
    Local cNNum   := ""
    Local cBco    := aBanco[BCO_COD]

    dbSelectArea("SEE")
    dbSetOrder(1)

    If !SEE->(dbSeek(xFilial("SEE") + MV_PAR01 + MV_PAR02 + MV_PAR03 + MV_PAR04))
        Return
    EndIf

    //-- Se ja tem Nosso Numero gravado e banco igual, mantem
    dbSelectArea("SE1")
    If SE1->E1_BOLIMP == "S" .And. !Empty(SE1->E1_NUMBCO) .And. SE1->E1_PORTADO == cBco
        Return
    EndIf

    //-- Obtem proximo sequencial do SEE
    dbSelectArea("SEE")
    nSeq := Val(SEE->EE_FAXATU)

    Reclock("SEE", .F.)
    SEE->EE_FAXATU := Soma1(SEE->EE_FAXATU)
    MSUnlock()

    cSeq := StrZero(nSeq, Len(SEE->EE_FAXATU))

    //-- Monta Nosso Numero por banco
    If cBco == FXBOL_BB
        //-- Banco do Brasil: convenio + sequencial
        If Len(aBanco[BCO_CEMP]) == 7
            cNNum := StrZero(nSeq, 10)
        ElseIf Len(aBanco[BCO_CEMP]) == 6
            cNNum := StrZero(nSeq, 5)
        Else
            cNNum := StrZero(nSeq, 7)
        EndIf
        cDV   := BlM11B92(aBanco[BCO_CEMP] + cNNum)
        cNNum := aBanco[BCO_CEMP] + cNNum
        If cDV == "10"
            cDV := "X"
        EndIf

    ElseIf cBco == FXBOL_SANT
        //-- Santander: 12 digitos + DV (DV calculado via Mod11CB)
        cSeq  := StrZero(nSeq, 12)
        cDV   := BlM11CB(cSeq, .F.)
        cNNum := cSeq + "-" + cDV

    ElseIf cBco == FXBOL_BANRI
        //-- Banrisul: 8 digitos + duplo DV (mod10 + mod11)
        cSeq  := StrZero(nSeq, 8)
        cDV   := BolMod10(cSeq)
        cDV   += BlM11B27B(cSeq + cDV)
        cNNum := cSeq + "-" + cDV

    ElseIf cBco == FXBOL_CAIXA
        //-- Caixa: carteira(2) + "4" + sequencial(15) + DV (mod11b29)
        cSeq  := StrZero(nSeq, 15)
        cDV   := BlM11B29(aBanco[BCO_CART] + "4" + cSeq)
        cNNum := aBanco[BCO_CART] + "4" + cSeq + cDV

    ElseIf cBco == FXBOL_BRADE
        //-- Bradesco: carteira(2) + sequencial(11) + DV (mod11b7)
        cSeq  := StrZero(nSeq, 11)
        cDV   := BlM11B7(aBanco[BCO_CART] + cSeq)
        cNNum := aBanco[BCO_CART] + cSeq + "-" + cDV

    ElseIf cBco == FXBOL_ITAU
        //-- Itau: sequencial(8) + DV = mod10(agencia+conta+carteira+seq)
        cSeq  := StrZero(nSeq, 8)
        cDV   := BolMod10(aBanco[BCO_AGE] + aBanco[BCO_CTA] + aBanco[BCO_CART] + cSeq)
        cNNum := cSeq

    ElseIf cBco == FXBOL_SAFRA
        //-- Safra cart 01/02: sequencial(8) + DV (mod11b29)
        cSeq  := StrZero(nSeq, 8)
        cDV   := BlM11B29(cSeq)
        cNNum := cSeq + "-" + cDV

    ElseIf cBco == FXBOL_SICRED
        //-- Sicredi: sequencial(8) + DV (mod11cb) ? 8 chars usados no campo livre do barcode
        cSeq  := StrZero(nSeq, 8)
        cDV   := BlM11CB(cSeq, .F.)
        cNNum := cSeq + "-" + cDV

    ElseIf cBco == FXBOL_SICOOB
        //-- Sicoob: sequencial(7) + DV modulo 11 pesos 3,1,9,7 sobre agencia(4)+conta(10)+seq(7)
        cSeq  := StrZero(nSeq, 7)
        cDV   := BlSicoobDV(StrZero(Val(aBanco[BCO_AGE]), 4) + StrZero(Val(aBanco[BCO_CTA]), 10) + cSeq)
        cNNum := cSeq + "-" + cDV

    Else
        cNNum := cSeq

    EndIf

    //-- Grava Nosso Numero no SE1
    dbSelectArea("SE1")
    Reclock("SE1", .F.)
    IF cBco == FXBOL_SICOOB
        SE1->E1_NUMBCO  := StrTran(cNNum, "-","")
    Else
        SE1->E1_NUMBCO  := cNNum
    EndIf
    SE1->E1_PORTADO := cBco
    SE1->E1_CODCART := aBanco[BCO_CART]
    SE1->E1_AGEDEP  := aBanco[BCO_AGE]
    SE1->E1_CONTA   := aBanco[BCO_CTA]
    MSUnlock()

Return

/*/{Protheus.doc} _BolCodBar
Gera o codigo de barras (44 digitos) e atualiza aTitulo[TIT_CODBAR].
Algoritmo: banco(3)+moeda(1)+DV(1)+fatorVcto(4)+valor(10)+campoLivre(25).
@type Static Function
@author BMTEC
@since 01/07/2025
@param aBanco, Array, Array de dados do banco
@param aTitulo, Array, Array de dados do titulo (por referencia)
/*/
Static Function _BolCodBar(aBanco, aTitulo)

    Local cBco        := aBanco[BCO_COD]
    Local cFatorVcto  := ""
    Local cValor      := ""
    Local cCodBar     := ""
    Local cCampoLiv   := ""
    Local cDV1        := ""
    Local cDV2        := ""
    Local dVcto       := CtoD(aTitulo[TIT_DTVCTO])
    Local nValor      := aTitulo[TIT_VALOR]
    Local cNNum       := ""
    Local cNNumPuro   := ""

    //-- Fator de vencimento com ajuste para datas apos 22/02/2025 (circular BACEN)
    If dVcto >= CtoD("22/02/2025")
        cFatorVcto := StrZero(1000 + (dVcto - CtoD("22/02/2025")), 4)
    Else
        cFatorVcto := StrZero(dVcto - CtoD("07/10/1997"), 4)
    EndIf

    cValor  := StrZero(nValor * 100, 10)

    //-- Prefixo padrao (posicoes 1-4 e 6-19)
    cCodBar := cBco + "9" + "" + cFatorVcto + cValor

    //-- Remove DV e sinais do Nosso Numero para usar no campo livre
    cNNum     := AllTrim(SE1->E1_NUMBCO)
    cNNumPuro := StrTran(StrTran(cNNum, "-", ""), "/", "")

    //-- Campo livre (posicoes 20-44) por banco
    If cBco == FXBOL_BB
        //-- cNNumPuro = convenio+seq (conv7=17chars, conv6/4=11chars)
        //-- SubStr pula os chars do convenio para extrair somente o sequencial
        If Len(aBanco[BCO_CEMP]) == 7
            //-- zeros(6)+convenio(7)+seq(10)+carteira(2) = 25
            cCampoLiv := Replicate("0", 6) + aBanco[BCO_CEMP] + ;
                         SubStr(cNNumPuro, 8, 10) + aBanco[BCO_CART]
        ElseIf Len(aBanco[BCO_CEMP]) == 6
            //-- convenio(6)+seq(5)+agencia(4)+conta(8)+carteira(2) = 25
            cCampoLiv := aBanco[BCO_CEMP] + SubStr(cNNumPuro, 7, 5) + ;
                         aBanco[BCO_AGE] + StrZero(Val(aBanco[BCO_CTA]), 8) + aBanco[BCO_CART]
        Else
            //-- Conv 4: convenio(4)+seq(7)+agencia(4)+conta(8)+carteira(2) = 25
            cCampoLiv := aBanco[BCO_CEMP] + SubStr(cNNumPuro, 5, 7) + ;
                         aBanco[BCO_AGE] + StrZero(Val(aBanco[BCO_CTA]), 8) + aBanco[BCO_CART]
        EndIf

    ElseIf cBco == FXBOL_SANT
        //-- Santander: "9"+cod.beneficiario(7)+NN(12)+DV(1)+"0"+carteira(3)
        cCampoLiv := "9" + Left(aBanco[BCO_CEMP], 7) + ;
                     Left(cNNumPuro, 12) + ;
                     BlM11CB(Left(cNNumPuro, 12), .F.) + "0" + aBanco[BCO_CART]

    ElseIf cBco == FXBOL_BANRI
        //-- Banrisul: produto(1)+"1"+agencia(4)+cedente(7)+NN(8)+"40"+DV(2)
        cCampoLiv := "2" + "1" + aBanco[BCO_AGE] + ;
                     Left(SubStr(aBanco[BCO_CEMP], 5, 9), 7) + ;
                     Left(cNNumPuro, 8) + "40"
        cDV1 := BolMod10(cCampoLiv)
        cDV2 := BlM11B27B(cCampoLiv + cDV1)
        cCampoLiv += cDV2

    ElseIf cBco == FXBOL_CAIXA
        //-- Caixa: cod.benef.(6)+DV(1)+posNN(3-5)+"2"+posNN(6-8)+"4"+posNN(9-17)+DV-campo(1)
        cCampoLiv := Left(aBanco[BCO_CEMP], 6)
        cDV1 := BlM11B29(Left(aBanco[BCO_CEMP], 6))
        cCampoLiv += cDV1
        cCampoLiv += SubStr(cNNumPuro, 3, 3)
        If aBanco[BCO_CART] == "RG"
            cCampoLiv += "1"
        Else
            cCampoLiv += "2"
        EndIf
        cCampoLiv += SubStr(cNNumPuro, 6, 3) + "4" + SubStr(cNNumPuro, 9, 9)
        cDV2 := BlM11B29(cCampoLiv)
        cCampoLiv += cDV2

    ElseIf cBco == FXBOL_BRADE
        //-- Bradesco: agencia(4)+carteira(2)+NN_puro(11)+conta(7)+"0" = 25
        //-- cNNumPuro = cart(2)+seq(11)+dv(1) => SubStr(,3,11) extrai so o seq
        cCampoLiv := aBanco[BCO_AGE] + aBanco[BCO_CART] + ;
                     SubStr(cNNumPuro, 3, 11) + ;
                     StrZero(Val(aBanco[BCO_CTA]), 7) + "0"

    ElseIf cBco == FXBOL_ITAU
        //-- Itau: carteira(3)+NN(8)+DV(1)+agencia(4)+conta(5)+DV-cta(1)+"000" = 25
        //-- E1_NUMBCO pode estar gravado com zeros a esquerda (15 posicoes,
        //-- padrao do IMPRIMEBOL): o nosso numero do Itau sao os 8 digitos finais
        cNNumPuro := Right(cNNumPuro, 8)
        cDV1 := BolMod10(aBanco[BCO_AGE] + aBanco[BCO_CTA] + aBanco[BCO_CART] + cNNumPuro)
        cCampoLiv := aBanco[BCO_CART] + cNNumPuro + cDV1 + ;
                     aBanco[BCO_AGE] + aBanco[BCO_CTA] + aBanco[BCO_DVCTA] + "000"

    ElseIf cBco == FXBOL_SAFRA
        //-- Safra: "7"+agencia(5)+conta(9)+seq(8)+DV(1)+"2" = 25
        //-- cNNumPuro = seq(8)+dv(1) => Left(,8) para seq puro, recomputa DV
        cDV1 := BlM11B29(Left(cNNumPuro, 8))
        cCampoLiv := "7" + StrZero(Val(aBanco[BCO_AGE]), 5) + ;
                     StrZero(Val(aBanco[BCO_CTA]), 9) + Left(cNNumPuro, 8) + cDV1 + "2"

    ElseIf cBco == FXBOL_SICRED
        //-- Sicredi: "1"+carteira(1)+seq(8)+DV(1)+agencia(4)+posto(2)+conta(5)+"0"+"0"+DV-campo(1) = 25
        //-- cNNumPuro = seq(8)+dv(1): Left(,8)=seq, Right(,1)=dv
        cCampoLiv := "1" + aBanco[BCO_CART] + Left(cNNumPuro, 8) + ;
                     Right(cNNumPuro, 1) + aBanco[BCO_AGE] + ;
                     aBanco[BCO_POSTO] + aBanco[BCO_CTA] + "00"
        cDV1 := BlM11CB(cCampoLiv, .F.)
        cCampoLiv += cDV1

    ElseIf cBco == FXBOL_SICOOB
        //-- Sicoob: "1"+agencia(4)+"01"+cod.benef.(7)+seq(7)+DV(1)+parcela(3) = 25
        //-- cNNumPuro = seq(7)+dv(1): Left(,7)=seq, Right(,1)=dv
        //-- posicoes 23-25 = numero da parcela do titulo (E1_PARCELA); avulso/branco = "000"
        cCampoLiv := "1" + aBanco[BCO_AGE] + "01" + aBanco[BCO_CEMP] + ;
                     Left(cNNumPuro, 7) + Right(cNNumPuro, 1) + StrZero(Val(SE1->E1_PARCELA), 3)

    EndIf

    cCodBar += cCampoLiv

    //-- Remove separadores ("-" e "/") ANTES de calcular o DV geral. Campos como
    //-- EE_CODEMP podem vir formatados (ex.: "269705-0") e o traco contamina a base
    //-- do DV. Sem esta limpeza, os campos saem corretos mas o DV geral sai errado.
    cCodBar := StrTran(StrTran(cCodBar, "-", ""), "/", "")

    //-- DV geral do codigo de barras (posicao 5) - padrao Febraban para todos os bancos
    cDV1 := BlM11CB(SubStr(cCodBar, 1, 4) + SubStr(cCodBar, 5), .T.)

    //-- Insere DV na posicao 5
    cCodBar := SubStr(cCodBar, 1, 4) + cDV1 + SubStr(cCodBar, 5)

    If Len(cCodBar) == 44
        aTitulo[TIT_CODBAR] := cCodBar
    Else
        FWLogMsg("LOG", ProcName(), "FXBOL002", "Codigo de barras invalido para titulo " + aTitulo[TIT_NUM] + ": " + cCodBar)
        aTitulo[TIT_CODBAR] := ""
    EndIf

Return

/*/{Protheus.doc} _BolLinDig
Gera a linha digitavel a partir do codigo de barras de 44 digitos.
Formato: 3 campos de 10 digitos + DV geral + fator+valor (5 grupos).
@type Static Function
@author BMTEC
@since 01/07/2025
@param aBanco, Array, Array de dados do banco
@param aTitulo, Array, Array de dados do titulo (por referencia)
/*/
Static Function _BolLinDig(aBanco, aTitulo)

    Local cCodBar  := aTitulo[TIT_CODBAR]
    Local cCampo1  := ""
    Local cCampo2  := ""
    Local cCampo3  := ""
    Local cCampo4  := ""
    Local cCampo5  := ""
    Local cLinDig  := ""

    cCampo1 := SubStr(cCodBar, 01, 03) + SubStr(cCodBar, 04, 01) + SubStr(cCodBar, 20, 05)
    cCampo1 += BolMod10(cCampo1)

    cCampo2 := SubStr(cCodBar, 25, 10)
    cCampo2 += BolMod10(cCampo2)

    cCampo3 := SubStr(cCodBar, 35, 10)
    cCampo3 += BolMod10(cCampo3)

    cCampo4 := SubStr(cCodBar, 05, 01)
    cCampo5 := SubStr(cCodBar, 06, 04) + SubStr(cCodBar, 10, 10)

    cLinDig := cCampo1 + cCampo2 + cCampo3 + cCampo4 + cCampo5

    aTitulo[TIT_LINDIG] := Transform(cLinDig, "@R 99999.99999  99999.999999  99999.999999  9  99999999999999")

Return

/*/{Protheus.doc} _BolImpTit
Imprime as 3 vias do boleto (Comprovante Entrega, Recibo Pagador, Ficha Compensacao).
@type Static Function
@author BMTEC
@since 01/07/2025
@param oDuplic, Object, Objeto FWMSPrinter
@param aBanco, Array, Dados do banco
@param aCedente, Array, Dados do cedente
@param aSacado, Array, Dados do sacado
@param aTitulo, Array, Dados do titulo
/*/
Static Function _BolImpTit(oDuplic, aBanco, aCedente, aSacado, aTitulo)

    Local oF07  := TFont():New("Arial",  07, 07,, .F.,,,, .T., .F.)
    Local oF07N := TFont():New("Arial",  07, 07,, .T.,,,, .T., .F.)
    Local oF09  := TFont():New("Arial",  09, 09,, .F.,,,, .T., .F.)
    Local oF09N := TFont():New("Arial",  09, 09,, .T.,,,, .T., .F.)
    Local oF10  := TFont():New("Arial",  10, 10,, .T.,,,, .T., .F.)
    Local oF13  := TFont():New("Arial",, 13,, .T.,,,,, .F.)
    Local oF20  := TFont():New("Arial",, 20,, .T.,,,,, .F.)
    Local cBco  := aBanco[BCO_COD]
    Local cBcoTit := cBco + "-" + aBanco[BCO_DVBCO]
    Local i     := 0
    Local cValFmt := ""
    Local cVctoFmt := aTitulo[TIT_DTVCTO]
    Local cMsgFin := MV_PAR09
    Local cPathBmp := AllTrim(GetSrvProfString("StartPath", "")) + "banco" + cBco + ".bmp"

    //-- Logo informado pela chamada automatica (FXBOL02A)
    If Type("_cBolLogo") == "C" .And. !Empty(_cBolLogo)
        cPathBmp := _cBolLogo
    EndIf

    cValFmt := "R$ " + AllTrim(Transform(aTitulo[TIT_VALOR], "@E 9,999,999.99"))

    oDuplic:StartPage()

    //=================================================================
    // SECAO 1 ? Comprovante de Entrega (linhas 30 a 130)
    //=================================================================
    oDuplic:Box(0030, 0015, 0130, 0550)
    oDuplic:Line(0030, 0120, 0013, 0120)
    oDuplic:Line(0030, 0170, 0013, 0170)
    oDuplic:Line(0105, 0350, 0105, 0550)
    oDuplic:Line(0030, 0350, 0130, 0350)
    oDuplic:Line(0105, 0430, 0130, 0430)

    oDuplic:SayBitMap(0008, 0018, cPathBmp, 90, 20)
    oDuplic:Say(0020, 0125, cBcoTit, oF20)
    oDuplic:Say(0025, 0470, "Comprovante de Entrega", oF07N)

    oDuplic:Say(0040, 0018, "Beneficiario", oF07)
    oDuplic:Say(0050, 0018, aCedente[CED_NOME] + " - " + aCedente[CED_CNPJ], oF09)
    oDuplic:Say(0060, 0018, "Pagador", oF07)
    oDuplic:Say(0070, 0018, Left(aSacado[SAC_NOME], 55) + " - CPF/CNPJ: " + aSacado[SAC_CNPJ], oF09)
    oDuplic:Say(0080, 0018, "Data de Vencimento", oF07)
    oDuplic:Say(0090, 0018, cVctoFmt, oF09)
    oDuplic:Say(0080, 0110, "Numero do Documento", oF07)
    oDuplic:Say(0090, 0110, aTitulo[TIT_NUM], oF09)
    oDuplic:Say(0080, 0245, "Valor", oF07)
    oDuplic:Say(0090, 0245, cValFmt, oF09)
    oDuplic:Say(0100, 0018, "Agencia / Cod. Beneficiario", oF07)
    oDuplic:Say(0110, 0018, aBanco[BCO_AGECTA], oF09)
    oDuplic:Say(0100, 0155, "Nosso Numero", oF07)
    oDuplic:Say(0110, 0155, aTitulo[TIT_NNUMF], oF09)

    oDuplic:Say(0040, 0355, "MOTIVOS DE NAO ENTREGA", oF07N)
    oDuplic:Say(0055, 0355, "[  ] Mudou-se",   oF07)
    oDuplic:Say(0065, 0355, "[  ] Recusado",   oF07)
    oDuplic:Say(0075, 0355, "[  ] Ausente",    oF07)
    oDuplic:Say(0085, 0355, "[  ] Desconhecido", oF07)
    oDuplic:Say(0055, 0430, "[  ] Nao Procurado",  oF07)
    oDuplic:Say(0065, 0430, "[  ] Nao Existe o Nr", oF07)
    oDuplic:Say(0075, 0430, "[  ] Falecido",   oF07)
    oDuplic:Say(0085, 0430, "[  ] Outros",     oF07)

    oDuplic:Say(0100, 0355, "Recebi(emos) o bloqueto", oF07N)
    oDuplic:Say(0113, 0355, "Data:", oF07)
    oDuplic:Say(0113, 0435, "Assinatura:", oF07)

    //-- Linha digitavel na parte superior
    oDuplic:Say(0027, 0173, aTitulo[TIT_LINDIG], oF10)

    //-- Picote 1
    For i := 15 To 550 Step 2
        oDuplic:Say(0135, i, "-", oF07)
    Next i

    //=================================================================
    // SECAO 2 ? Recibo do Pagador (linhas 160 a 430)
    //=================================================================
    oDuplic:Box(0160, 0015, 0430, 0550)
    oDuplic:Line(0143, 0120, 0160, 0120)
    oDuplic:Line(0143, 0170, 0160, 0170)

    //-- Regra de posicionamento: Say usa Y como linha de base do texto (desenha para cima).
    //-- Rotulo (oF07) = topo da celula + 8; valor (oF09) = topo da celula + 17.

    //-- Grade: linhas horizontais de largura total
    oDuplic:Line(0180, 0015, 0180, 0550)
    oDuplic:Line(0208, 0015, 0208, 0550)
    oDuplic:Line(0228, 0015, 0228, 0550)
    oDuplic:Line(0248, 0015, 0248, 0550)
    oDuplic:Line(0348, 0015, 0348, 0550)

    //-- Grade: divisores verticais das linhas de dados (mesmas colunas nas duas linhas)
    oDuplic:Line(0208, 0100, 0248, 0100)
    oDuplic:Line(0208, 0210, 0248, 0210)
    oDuplic:Line(0208, 0320, 0248, 0320)
    oDuplic:Line(0228, 0150, 0248, 0150)

    //-- Grade: coluna direita de valores
    oDuplic:Line(0160, 0420, 0348, 0420)
    oDuplic:Line(0268, 0420, 0268, 0550)
    oDuplic:Line(0288, 0420, 0288, 0550)
    oDuplic:Line(0308, 0420, 0308, 0550)
    oDuplic:Line(0328, 0420, 0328, 0550)

    oDuplic:SayBitMap(0140, 0017, cPathBmp, 80, 16)
    oDuplic:Say(0150, 0125, cBcoTit, oF20)
    oDuplic:Say(0140, 0470, "Recibo do Pagador", oF07N)

    //-- Linha digitavel no Recibo
    oDuplic:Say(0158, 0173, aTitulo[TIT_LINDIG], oF10)

    //-- Celula 160-180: Local de Pagamento / Vencimento
    oDuplic:Say(0168, 0018, "Local de Pagamento", oF07)
    oDuplic:Say(0177, 0018, aBanco[BCO_LOC1], oF09)
    oDuplic:Say(0168, 0423, "Vencimento", oF07)
    oDuplic:Say(0177, 0423, cVctoFmt, oF09N)

    //-- Celula 180-208: Beneficiario (3 linhas) / Agencia
    oDuplic:Say(0188, 0018, "Beneficiario", oF07)
    oDuplic:Say(0197, 0018, aCedente[CED_NOME] + "  " + aCedente[CED_CNPJ], oF09)
    oDuplic:Say(0205, 0018, aCedente[CED_END] + ", " + aCedente[CED_BAIRRO] + " - " + aCedente[CED_CIDADE] + "/" + aCedente[CED_EST] + "  CEP: " + aCedente[CED_CEP], oF07)
    oDuplic:Say(0188, 0423, "Agencia/Cod. Beneficiario", oF07)
    oDuplic:Say(0197, 0423, aBanco[BCO_AGECTA], oF09)

    //-- Celula 208-228: dados do documento
    oDuplic:Say(0216, 0018, "Data Emissao", oF07)
    oDuplic:Say(0225, 0018, aTitulo[TIT_DTEMI], oF09)
    oDuplic:Say(0216, 0103, "Numero do Documento", oF07)
    oDuplic:Say(0225, 0103, aTitulo[TIT_NUM], oF09)
    oDuplic:Say(0216, 0213, "Especie", oF07)
    oDuplic:Say(0225, 0213, aTitulo[TIT_ESPECI], oF09)
    oDuplic:Say(0216, 0323, "Aceite", oF07)
    oDuplic:Say(0225, 0323, aBanco[BCO_ACEITE], oF09)
    oDuplic:Say(0216, 0423, "Data Processamento", oF07)
    oDuplic:Say(0225, 0423, SubStr(DTOS(Date()), 7, 2) + "/" + SubStr(DTOS(Date()), 5, 2) + "/" + SubStr(DTOS(Date()), 1, 4), oF09)

    //-- Celula 228-248: uso do banco / carteira / moeda
    oDuplic:Say(0236, 0018, "Uso do Banco", oF07)
    oDuplic:Say(0236, 0103, "Carteira", oF07)
    oDuplic:Say(0245, 0103, aBanco[BCO_CART], oF09)
    oDuplic:Say(0236, 0153, "Especie Moeda", oF07)
    oDuplic:Say(0245, 0153, "R$", oF09)
    oDuplic:Say(0236, 0213, "Qtde Moeda", oF07)
    oDuplic:Say(0236, 0323, "Valor", oF07)
    oDuplic:Say(0236, 0423, "Nosso Numero", oF07)
    oDuplic:Say(0245, 0423, aTitulo[TIT_NNUMF], oF09N)

    //-- Instrucoes (248-348)
    oDuplic:Say(0256, 0018, "Instrucoes (Texto de responsabilidade do cedente)", oF07)
    If !Empty(aBanco[BCO_MSG1])
        oDuplic:Say(0268, 0018, aBanco[BCO_MSG1], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG2])
        oDuplic:Say(0280, 0018, aBanco[BCO_MSG2], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG3])
        oDuplic:Say(0292, 0018, aBanco[BCO_MSG3], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG4])
        oDuplic:Say(0304, 0018, aBanco[BCO_MSG4], oF09)
    EndIf
    If !Empty(cMsgFin)
        oDuplic:Say(0316, 0018, cMsgFin, oF09)
    EndIf

    //-- Coluna direita: valor do documento e deducoes (celulas de 20px a partir de 248)
    oDuplic:Say(0256, 0423, "(=) Valor do Documento",    oF07)
    oDuplic:Say(0265, 0423, cValFmt,                     oF09N)
    oDuplic:Say(0276, 0423, "(-) Descontos/Abatimentos", oF07)
    oDuplic:Say(0296, 0423, "(-) Outras Deducoes",       oF07)
    oDuplic:Say(0316, 0423, "(+) Multa/Mora",            oF07)
    oDuplic:Say(0336, 0423, "(+) Outros Acrescimos",     oF07)

    //-- Dados do pagador (348-430)
    oDuplic:Say(0358, 0018, "Pagador: " + aSacado[SAC_NOME] + "   CPF/CNPJ: " + aSacado[SAC_CNPJ], oF09)
    oDuplic:Say(0370, 0018, "Endereco: " + aSacado[SAC_END] + " - " + aSacado[SAC_BAIRRO], oF09)
    oDuplic:Say(0382, 0018, aSacado[SAC_CIDADE] + "  CEP: " + aSacado[SAC_CEP], oF09)

    oDuplic:Say(0424, 0423, "Autenticacao Mecanica", oF07)

    //-- Picote 2 (afastado do cabecalho da Ficha, que comeca em 473)
    For i := 15 To 550 Step 2
        oDuplic:Say(0455, i, "-", oF07)
    Next i

    //=================================================================
    // SECAO 3 ? Ficha de Compensacao (linhas 490 a 765)
    //=================================================================
    oDuplic:Box(0490, 0015, 0765, 0550)
    oDuplic:Line(0473, 0120, 0490, 0120)
    oDuplic:Line(0473, 0170, 0490, 0170)

    oDuplic:SayBitMap(0470, 0017, cPathBmp, 80, 16)
    oDuplic:Say(0480, 0125, cBcoTit, oF20)
    oDuplic:Say(0488, 0173, aTitulo[TIT_LINDIG], oF10)

    //-- Grade: linhas horizontais de largura total
    oDuplic:Line(0510, 0015, 0510, 0550)
    oDuplic:Line(0538, 0015, 0538, 0550)
    oDuplic:Line(0558, 0015, 0558, 0550)
    oDuplic:Line(0578, 0015, 0578, 0550)
    oDuplic:Line(0698, 0015, 0698, 0550)

    //-- Grade: divisores verticais das linhas de dados (mesmas colunas nas duas linhas)
    oDuplic:Line(0538, 0100, 0578, 0100)
    oDuplic:Line(0538, 0210, 0578, 0210)
    oDuplic:Line(0538, 0320, 0578, 0320)
    oDuplic:Line(0558, 0150, 0578, 0150)

    //-- Grade: coluna direita de valores (divisor vertical ate o bloco do pagador)
    oDuplic:Line(0490, 0420, 0698, 0420)
    oDuplic:Line(0598, 0420, 0598, 0550)
    oDuplic:Line(0618, 0420, 0618, 0550)
    oDuplic:Line(0638, 0420, 0638, 0550)
    oDuplic:Line(0658, 0420, 0658, 0550)
    oDuplic:Line(0678, 0420, 0678, 0550)

    //-- Celula 490-510: Local de Pagamento / Vencimento
    oDuplic:Say(0498, 0018, "Local de Pagamento", oF07)
    oDuplic:Say(0507, 0018, aBanco[BCO_LOC1], oF09)
    oDuplic:Say(0498, 0423, "Vencimento", oF07)
    oDuplic:Say(0507, 0423, cVctoFmt, oF09N)

    //-- Celula 510-538: Beneficiario (3 linhas) / Agencia
    oDuplic:Say(0518, 0018, "Beneficiario", oF07)
    oDuplic:Say(0527, 0018, aCedente[CED_NOME] + "  " + aCedente[CED_CNPJ], oF09)
    oDuplic:Say(0535, 0018, aCedente[CED_END] + ", " + aCedente[CED_BAIRRO] + " - " + aCedente[CED_CIDADE] + "/" + aCedente[CED_EST] + "  CEP: " + aCedente[CED_CEP], oF07)
    oDuplic:Say(0518, 0423, "Agencia/Cod. Beneficiario", oF07)
    oDuplic:Say(0527, 0423, aBanco[BCO_AGECTA], oF09)

    //-- Celula 538-558: dados do documento
    oDuplic:Say(0546, 0018, "Data Emissao", oF07)
    oDuplic:Say(0555, 0018, aTitulo[TIT_DTEMI], oF09)
    oDuplic:Say(0546, 0103, "Numero do Documento", oF07)
    oDuplic:Say(0555, 0103, aTitulo[TIT_NUM], oF09)
    oDuplic:Say(0546, 0213, "Especie", oF07)
    oDuplic:Say(0555, 0213, aTitulo[TIT_ESPECI], oF09)
    oDuplic:Say(0546, 0323, "Aceite", oF07)
    oDuplic:Say(0555, 0323, aBanco[BCO_ACEITE], oF09)
    oDuplic:Say(0546, 0423, "Data Processamento", oF07)
    oDuplic:Say(0555, 0423, SubStr(DTOS(Date()), 7, 2) + "/" + SubStr(DTOS(Date()), 5, 2) + "/" + SubStr(DTOS(Date()), 1, 4), oF09)

    //-- Celula 558-578: uso do banco / carteira / moeda
    oDuplic:Say(0566, 0018, "Uso do Banco", oF07)
    oDuplic:Say(0566, 0103, "Carteira", oF07)
    oDuplic:Say(0575, 0103, aBanco[BCO_CART], oF09)
    oDuplic:Say(0566, 0153, "Especie Moeda", oF07)
    oDuplic:Say(0575, 0153, "R$", oF09)
    oDuplic:Say(0566, 0213, "Qtde Moeda", oF07)
    oDuplic:Say(0566, 0323, "Valor", oF07)
    oDuplic:Say(0566, 0423, "Nosso Numero", oF07)
    oDuplic:Say(0575, 0423, aTitulo[TIT_NNUMF], oF09N)

    //-- Instrucoes Ficha (578-698)
    oDuplic:Say(0586, 0018, "Instrucoes (Texto de responsabilidade do cedente)", oF07)
    If !Empty(aBanco[BCO_MSG1])
        oDuplic:Say(0598, 0018, aBanco[BCO_MSG1], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG2])
        oDuplic:Say(0610, 0018, aBanco[BCO_MSG2], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG3])
        oDuplic:Say(0622, 0018, aBanco[BCO_MSG3], oF09)
    EndIf
    If !Empty(aBanco[BCO_MSG4])
        oDuplic:Say(0634, 0018, aBanco[BCO_MSG4], oF09)
    EndIf
    If !Empty(cMsgFin)
        oDuplic:Say(0646, 0018, cMsgFin, oF09)
    EndIf

    //-- Coluna direita Ficha: valor do documento e deducoes (celulas de 20px a partir de 578)
    oDuplic:Say(0586, 0423, "(=) Valor do Documento",    oF07)
    oDuplic:Say(0595, 0423, cValFmt,                     oF09N)
    oDuplic:Say(0606, 0423, "(-) Descontos/Abatimentos", oF07)
    oDuplic:Say(0626, 0423, "(-) Outras Deducoes",       oF07)
    oDuplic:Say(0646, 0423, "(+) Multa/Mora",            oF07)
    oDuplic:Say(0666, 0423, "(+) Outros Acrescimos",     oF07)
    oDuplic:Say(0686, 0423, "(=) Valor Cobrado",         oF07)

    //-- Dados do Pagador (698-765)
    oDuplic:Say(0708, 0018, "Pagador: " + aSacado[SAC_NOME] + "   CPF/CNPJ: " + aSacado[SAC_CNPJ], oF09)
    oDuplic:Say(0720, 0018, aSacado[SAC_END] + " - " + aSacado[SAC_BAIRRO], oF09)
    oDuplic:Say(0732, 0018, aSacado[SAC_CIDADE] + "  CEP: " + aSacado[SAC_CEP], oF09)

    oDuplic:Say(0755, 0340, "Autenticacao Mecanica / FICHA DE COMPENSACAO", oF07N)

    //-- Codigo de barras
    oDuplic:FwMsBar("INT25", 63.5, 1.3, aTitulo[TIT_CODBAR], oDuplic, .F.,, .T., 0.02, 0.8, .F., "Arial",, .F., 1, 1, .F.)

    oDuplic:EndPage()

Return

//=================================================================
// FUNCOES AUXILIARES
//=================================================================

/*/{Protheus.doc} _BolNomeBanco
Retorna o nome do banco pelo codigo.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cBco, Character, Codigo do banco (3 digitos)
@return Character, Nome do banco
/*/
Static Function _BolNomeBanco(cBco)

    Local cNome := ""

    If cBco == FXBOL_BB
        cNome := "BANCO DO BRASIL S/A"
    ElseIf cBco == FXBOL_SANT
        cNome := "BANCO SANTANDER S/A"
    ElseIf cBco == FXBOL_BANRI
        cNome := "BANCO BANRISUL S/A"
    ElseIf cBco == FXBOL_CAIXA
        cNome := "CAIXA ECONOMICA FEDERAL"
    ElseIf cBco == FXBOL_BRADE
        cNome := "BANCO BRADESCO S/A"
    ElseIf cBco == FXBOL_ITAU
        cNome := "BANCO ITAU S/A"
    ElseIf cBco == FXBOL_SAFRA
        cNome := "BANCO SAFRA S/A"
    ElseIf cBco == FXBOL_SICRED
        cNome := "BANCO SICREDI S/A"
    ElseIf cBco == FXBOL_SICOOB
        cNome := "BANCO SICOOB S/A"
    Else
        cNome := "BANCO " + cBco
    EndIf

Return(cNome)

/*/{Protheus.doc} _BolDvBanco
Retorna o digito verificador oficial do banco.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cBco, Character, Codigo do banco (3 digitos)
@return Character, DV do banco
/*/
Static Function _BolDvBanco(cBco)

    Local cDV := "0"

    If cBco == FXBOL_BB
        cDV := "9"
    ElseIf cBco == FXBOL_SANT
        cDV := "7"
    ElseIf cBco == FXBOL_BANRI
        cDV := "8"
    ElseIf cBco == FXBOL_CAIXA
        cDV := "0"
    ElseIf cBco == FXBOL_BRADE
        cDV := "2"
    ElseIf cBco == FXBOL_ITAU
        cDV := "7"
    ElseIf cBco == FXBOL_SAFRA
        cDV := "7"
    ElseIf cBco == FXBOL_SICRED
        cDV := "X"
    ElseIf cBco == FXBOL_SICOOB
        cDV := "0"
    EndIf

Return(cDV)

/*/{Protheus.doc} _BolLocalPag
Retorna o texto de local de pagamento para o banco informado.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cBco, Character, Codigo do banco (3 digitos)
@return Character, Texto local de pagamento
/*/
Static Function _BolLocalPag(cBco)

    Local cLocal := ""

    If cBco == FXBOL_BB
        cLocal := "Pagavel preferencialmente no Banco do Brasil ou qualquer banco ate o vencimento."
    ElseIf cBco == FXBOL_SANT
        cLocal := "Pagavel preferencialmente no Grupo Santander."
    ElseIf cBco == FXBOL_BANRI
        cLocal := "SAC BANRISUL: 0800.646.1515  Pagavel preferencialmente no Banrisul."
    ElseIf cBco == FXBOL_CAIXA
        cLocal := "SAC CAIXA: 0800 726 0101  Pagavel preferencialmente na Caixa Economica Federal."
    ElseIf cBco == FXBOL_BRADE
        cLocal := "Pagavel preferencialmente nas agencias Bradesco ate o vencimento."
    ElseIf cBco == FXBOL_ITAU
        cLocal := "Ate o vencimento, preferencialmente no Itau. Apos o vencimento, somente no Itau."
    ElseIf cBco == FXBOL_SAFRA
        cLocal := "Pagavel em qualquer banco do sistema de compensacao bancaria."
    ElseIf cBco == FXBOL_SICRED
        cLocal := "Pagavel preferencialmente nas Cooperativas de Credito do Sicredi."
    ElseIf cBco == FXBOL_SICOOB
        cLocal := "Pagavel preferencialmente nas Cooperativas Sicoob ou qualquer banco ate o vencimento."
    Else
        cLocal := "Pagavel em qualquer banco do sistema de compensacao bancaria."
    EndIf

Return(cLocal)

//=================================================================
// ALGORITMOS MATEMATICOS DE DIGITO VERIFICADOR
//=================================================================

/*/{Protheus.doc} BolMod10
Calcula digito verificador pelo Modulo 10.
Multiplica digitos da direita alternando pesos 2 e 1; se resultado > 9 subtrai 9.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String numerica para calculo
@return Character, Digito verificador (0-9)
/*/
Static Function BolMod10(cStr)

    Local nLen  := Len(cStr)
    Local nSoma := 0
    Local nPeso := 2
    Local nPos  := 0
    Local nRes  := 0
    Local nDV   := 0

    Do While nLen > 0
        nPos  := Val(SubStr(cStr, nLen, 1)) * nPeso
        If nPos > 9
            nSoma += nPos - 9
        Else
            nSoma += nPos
        EndIf
        If nPeso == 2
            nPeso := 1
        Else
            nPeso := 2
        EndIf
        nLen--
    EndDo

    nRes := Mod(nSoma, 10)
    If nRes == 0
        nDV := 0
    Else
        nDV := 10 - nRes
    EndIf

Return(AllTrim(Str(nDV)))

/*/{Protheus.doc} BlM11CB
Calculo Modulo 11 base 9 para codigo de barras (Febraban).
Multipla da direita com pesos ciclicos 2..9.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String numerica
@param lCodBar, Logical, .T. = calculo para DV do codigo de barras; .F. = campo livre
@return Character, Digito verificador
/*/
Static Function BlM11CB(cStr, lCodBar)

    Local nLen   := Len(cStr)
    Local nSoma  := 0
    Local nResto := 0
    Local nDV    := 0
    Local nI     := 0
    Local aPesos := {2, 3, 4, 5, 6, 7, 8, 9}

    Default lCodBar := .F.

    //-- soma da direita para a esquerda com pesos ciclicos 2..9 (peso fixo por posicao)
    For nI := 1 To nLen
        nSoma += Val(SubStr(cStr, nLen - nI + 1, 1)) * aPesos[Mod(nI - 1, 8) + 1]
    Next nI

    nResto := Mod(nSoma, 11)

    If lCodBar
        nDV := 11 - nResto
        If nDV == 0 .Or. nDV == 1 .Or. nDV == 10 .Or. nDV == 11
            nDV := 1
        EndIf
    Else
        If nResto == 10
            nDV := 1
        ElseIf nResto == 0 .Or. nResto == 1
            nDV := 0
        Else
            nDV := Abs(11 - nResto)
        EndIf
    EndIf

Return(AllTrim(Str(nDV)))

/*/{Protheus.doc} BlM11B7
Modulo 11 base 2-7 (Bradesco, Fibra). Pesos 2..7 ciclico da direita.
Resto 0 ou 1 ? DV=0; resto 10 ? DV=1 (em alguns bancos "0").
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String numerica
@return Character, Digito verificador (0-9 ou "P" para Bradesco especial)
/*/
Static Function BlM11B7(cStr)

    Local nLen   := Len(cStr)
    Local nSoma  := 0
    Local nPeso  := 2
    Local nResto := 0
    Local nDV    := 0

    Do While nLen > 0
        nSoma += Val(SubStr(cStr, nLen, 1)) * nPeso
        nPeso++
        If nPeso > 7
            nPeso := 2
        EndIf
        nLen--
    EndDo

    nResto := Mod(nSoma, 11)

    If nResto == 0 .Or. nResto == 1
        nDV := 0
    Else
        nDV := 11 - nResto
    EndIf

Return(AllTrim(Str(nDV)))

/*/{Protheus.doc} BlM11B29
Modulo 11 base 2-9 (Caixa Economica, Safra, Sicoob).
Resto 0 ou 1 ? DV=0; caso contrario DV = 11 - resto.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String numerica
@return Character, Digito verificador (0-9)
/*/
Static Function BlM11B29(cStr)

    Local nLen   := Len(cStr)
    Local nSoma  := 0
    Local nPeso  := 2
    Local nResto := 0
    Local nDV    := 0

    Do While nLen > 0
        nSoma += Val(SubStr(cStr, nLen, 1)) * nPeso
        nPeso++
        If nPeso > 9
            nPeso := 2
        EndIf
        nLen--
    EndDo

    nResto := Mod(nSoma, 11)

    If nResto == 0 .Or. nResto == 1
        nDV := 0
    Else
        nDV := 11 - nResto
    EndIf

Return(AllTrim(Str(nDV)))

/*/{Protheus.doc} BlM11B27B
Modulo 11 base 2-7 com logica especial do Banrisul para o segundo DV.
O resultado pode alterar o primeiro DV; retorna os dois DVs concatenados. BlM11
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String com NN (8 dig) + primeiro DV ja calculado (1 dig)
@return Character, Dois digitos verificadores concatenados
/*/
Static Function BlM11B27B(cStr)

    Local nLen    := Len(cStr)
    Local nSoma   := 0
    Local nPeso   := 2
    Local nResto  := 0
    Local nDV2    := 0
    Local cDV1    := Right(cStr, 1)
    Local nDV1    := Val(cDV1)

    Do While nLen > 0
        nSoma += Val(SubStr(cStr, nLen, 1)) * nPeso
        nPeso++
        If nPeso > 7
            nPeso := 2
        EndIf
        nLen--
    EndDo

    nResto := Mod(nSoma, 11)

    If nResto == 0
        nDV2 := 0
    ElseIf nResto == 1
        //-- Incrementa o DV1 e recalcula
        nDV1++
        If nDV1 >= 10
            nDV1 := 0
        EndIf
        cDV1 := AllTrim(Str(nDV1))
        nDV2 := 0
    Else
        nDV2 := 11 - nResto
        If nDV2 >= 10
            nDV2 := 0
        EndIf
    EndIf

Return(cDV1 + AllTrim(Str(nDV2)))

/*/{Protheus.doc} BlM11B92
Modulo 11 com pesos 9..2 ciclico (Banco do Brasil - Nosso Numero).
Resto 0 ? DV=0; resto 1 ? DV=1; resto 10 ? "X"; outros = 11-resto.
@type Static Function
@author BMTEC
@since 01/07/2025
@param cStr, Character, String numerica (convenio + sequencial)
@return Character, Digito verificador
/*/
Static Function BlM11B92(cStr)

    Local nLen   := Len(cStr)
    Local nSoma  := 0
    Local nPeso  := 2
    Local nResto := 0
    Local nDV    := 0
    Local cDV    := ""

    Do While nLen > 0
        nSoma += Val(SubStr(cStr, nLen, 1)) * nPeso
        nPeso++
        If nPeso > 9
            nPeso := 2
        EndIf
        nLen--
    EndDo

    nResto := Mod(nSoma, 11)

    If nResto == 0
        cDV := "0"
    ElseIf nResto == 1
        cDV := "1"
    ElseIf (11 - nResto) == 10
        cDV := "X"
    Else
        cDV := AllTrim(Str(11 - nResto))
    EndIf

Return(cDV)

/*/{Protheus.doc} BlSicoobDV
Calcula o digito verificador do Nosso Numero do Sicoob.
Modulo 11 com pesos ciclicos 3,1,9,7 aplicados da esquerda para a direita
sobre a base agencia(4) + conta/cedente(10) + sequencial(7).
Resto 0 ou 1 (DV 11 ou 10) => DV = 0; caso contrario DV = 11 - resto.
@type Static Function
@author BMTEC
@since 10/07/2025
@param cBase, Character, Base de calculo (agencia + conta + sequencial, 21 digitos)
@return Character, Digito verificador (0-9)
/*/
Static Function BlSicoobDV(cBase)

    Local nLen   := Len(cBase)
    Local nSoma  := 0
    Local nResto := 0
    Local nDV    := 0
    Local nI     := 0
    Local aPesos := {3, 1, 9, 7}

    For nI := 1 To nLen
        nSoma += Val(SubStr(cBase, nI, 1)) * aPesos[Mod(nI - 1, 4) + 1]
    Next nI

    nResto := Mod(nSoma, 11)

    If nResto == 0 .Or. nResto == 1
        nDV := 0
    Else
        nDV := 11 - nResto
    EndIf

Return(AllTrim(Str(nDV)))


//=================================================================
// MODO AUTOMATICO PARA O PAINEL DE DOCUMENTOS POR CARGA (ZPAINFAT)
//=================================================================

/*/{Protheus.doc} FXBOL02A
Imprime os boletos dos titulos informados no objeto de impressao recebido,
sem tela. Pensado para o banco Itau (341), reproduzindo o boleto do IMPRIMEBOL:
 - nosso numero do mesmo contador (SEE->EE_FAXATU) e no mesmo formato
   (E1_NUMBCO com zeros a esquerda); titulo que ja tem nosso numero REAPROVEITA
 - nosso numero impresso como carteira/numero-DV (ex.: 109/00120359-1)
 - valor = saldo - decrescimo - desconto financeiro (E1_DESCFIN %)
 - instrucoes: juros ao dia, multa, nao dispensar juros, protesto
@type User Function
@author Lucas Guimaraes
@since 09/11/2026
@param oPrinter, Object,  FWMSPrinter ja criado (todos os boletos no mesmo PDF)
@param aRecs,    Array,   RECNOs da SE1 a imprimir
@param aCfg,     Array,   {Banco, Agencia, Conta, SubConta, Carteira, Logo, % Multa}
@param aLog,     Array,   mensagens de retorno (por referencia)
@return Numeric, quantidade de boletos impressos
/*/
User Function FXBOL02A(oPrinter, aRecs, aCfg, aLog)

    Local aBanco    := {}
    Local aCedente  := {}
    Local aSacado   := {}
    Local aTitulo   := {}
    Local nQtd      := 0
    Local nValor    := 0
    Local nJuros    := 0
    Local nMulta    := 0
    Local cNNum     := ""
    Local cNN8      := ""
    Local cDVNN     := ""
    Local cTit      := ""
    Local nI        := 0

    Private MV_PAR09  := ""          // _BolImpTit le MV_PAR09 (mensagem financeira)
    Private _cBolLogo := aCfg[6]
    Private _lAuto    := .T.

    Default aLog := {}

    // As datas do boleto sao montadas como texto dd/mm/aaaa e convertidas
    // com CtoD no codigo de barras: garante o formato mesmo dentro de job
    SET DATE BRITISH
    SET CENTURY ON

    If !_BAuBanco(@aBanco, aCfg, @aLog)
        Return 0
    EndIf

    _BolSetCedente(@aCedente)

    For nI := 1 To Len(aRecs)

        SE1->(DbGoTo(aRecs[nI]))
        If SE1->(Eof()) .Or. SE1->(Deleted())
            Loop
        EndIf

        cTit := AllTrim(SE1->E1_PREFIXO) + "/" + AllTrim(SE1->E1_NUM) + ;
                IIf(Empty(SE1->E1_PARCELA), "", "-" + AllTrim(SE1->E1_PARCELA))

        If SE1->E1_SALDO <= 0
            aAdd(aLog, "Boleto: titulo " + cTit + " sem saldo (ja baixado) - ignorado.")
            Loop
        EndIf

        If !Empty(SE1->E1_PORTADO) .And. AllTrim(SE1->E1_PORTADO) <> aBanco[BCO_COD]
            aAdd(aLog, "Boleto: titulo " + cTit + " esta no portador " + AllTrim(SE1->E1_PORTADO) + " - ignorado.")
            Loop
        EndIf

        //-- Nosso numero: reaproveita o existente ou pega o proximo do SEE
        cNNum := _BAuNossoNum(aBanco)
        If Empty(cNNum)
            aAdd(aLog, "Boleto: nao foi possivel obter nosso numero para o titulo " + cTit + ".")
            Loop
        EndIf
        cNN8  := Right(cNNum, 8)
        cDVNN := BolMod10(aBanco[BCO_AGE] + aBanco[BCO_CTA] + aBanco[BCO_CART] + cNN8)

        //-- Valor igual ao boleto atual: saldo - decrescimo - desconto financeiro
        nValor := Round(SE1->E1_SALDO - SE1->E1_DECRESC - (SE1->E1_VALOR * SE1->E1_DESCFIN / 100), 2)

        //-- Instrucoes (calculadas por titulo)
        nJuros := SE1->E1_VALJUR
        If nJuros <= 0 .And. SE1->E1_PORCJUR > 0
            nJuros := Round(nValor * SE1->E1_PORCJUR / 100, 2)
        EndIf
        nMulta := Round(nValor * aCfg[7] / 100, 2)

        aBanco[BCO_MSG1] := IIf(nJuros > 0, "Apos Vencimento Cobrar Juros ao dia R$ " + AllTrim(Transform(nJuros, "@E 999,999,999.99")), "")
        aBanco[BCO_MSG2] := IIf(nMulta > 0, "Cobrar multa de R$ " + AllTrim(Transform(nMulta, "@E 999,999,999.99")), "")
        aBanco[BCO_MSG3] := "NAO DISPENSAR JUROS"
        aBanco[BCO_MSG4] := "PROTESTAR 5 DIAS APOS O VENCIMENTO"

        _BAuSacado(@aSacado)

        aTitulo := AFill(Array(TAM_TIT), "")
        aTitulo[TIT_REC]    := SE1->(RecNo())
        aTitulo[TIT_NUM]    := AllTrim(SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA)
        aTitulo[TIT_DTEMI]  := DToC(SE1->E1_EMISSAO)
        aTitulo[TIT_DTVCTO] := DToC(SE1->E1_VENCTO)          // igual ao boleto atual
        aTitulo[TIT_VALOR]  := nValor
        aTitulo[TIT_NNUM]   := cNN8
        aTitulo[TIT_DVNNUM] := cDVNN
        aTitulo[TIT_NNUMF]  := aBanco[BCO_CART] + "/" + cNN8 + "-" + cDVNN
        aTitulo[TIT_ESPECI] := "DM"

        _BolCodBar(aBanco, @aTitulo)

        If Len(AllTrim(aTitulo[TIT_CODBAR])) == 44
            _BolLinDig(aBanco, @aTitulo)
            _BolImpTit(oPrinter, aBanco, aCedente, aSacado, aTitulo)
            nQtd++

            RecLock("SE1", .F.)
                SE1->E1_BOLIMP := "S"
            SE1->(MsUnlock())
        Else
            aAdd(aLog, "Boleto: codigo de barras invalido para o titulo " + cTit + ".")
        EndIf
    Next nI

Return nQtd

/*/ Monta aBanco a partir da configuracao fixa + SEE (posicionado para o contador) /*/
Static Function _BAuBanco(aBanco, aCfg, aLog)

    Local cBco  := aCfg[1]
    Local cAge  := aCfg[2]
    Local cCta  := aCfg[3]
    Local cSub  := aCfg[4]
    Local cKey  := ""

    cKey := xFilial("SEE") + PadR(cBco, TamSX3("EE_CODIGO")[1]) + PadR(cAge, TamSX3("EE_AGENCIA")[1]) + ;
            PadR(cCta, TamSX3("EE_CONTA")[1]) + PadR(cSub, TamSX3("EE_SUBCTA")[1])

    SEE->(DbSetOrder(1))
    If !SEE->(DbSeek(cKey))
        aAdd(aLog, "Boleto: parametros do banco " + cBco + " ag. " + cAge + " cc " + cCta + " sub " + cSub + " nao encontrados na SEE.")
        Return .F.
    EndIf

    aBanco := AFill(Array(TAM_BCO), "")
    aBanco[BCO_COD]     := cBco
    aBanco[BCO_DVBCO]   := _BolDvBanco(cBco)
    aBanco[BCO_BCOFORM] := cBco + "-" + aBanco[BCO_DVBCO]
    aBanco[BCO_AGE]     := cAge
    aBanco[BCO_CTA]     := cCta
    aBanco[BCO_DVCTA]   := BolMod10(cAge + cCta)          // DAC da conta Itau (mod10 agencia+conta)
    aBanco[BCO_SUBC]    := cSub
    aBanco[BCO_CART]    := aCfg[5]
    aBanco[BCO_ACEITE]  := "N"
    aBanco[BCO_NOME]    := _BolNomeBanco(cBco)
    aBanco[BCO_AGECTA]  := cAge + " / " + cCta + "-" + aBanco[BCO_DVCTA]
    aBanco[BCO_LOC1]    := "PREFERENCIALMENTE NO ITAU ATE O VENCIMENTO. APOS O VENCIMENTO, SOMENTE NO ITAU"

    // Guarda o registro da SEE para o contador do nosso numero
    aBanco[BCO_CEMP]    := cValToChar(SEE->(RecNo()))

Return .T.

/*/ Nosso numero: reaproveita o do titulo ou pega o proximo do SEE (com trava) /*/
Static Function _BAuNossoNum(aBanco)

    Local cNNum := AllTrim(SE1->E1_NUMBCO)
    Local nSeq  := 0

    //-- Ja tem nosso numero (impresso antes pelo IMPRIMEBOL ou por esta rotina):
    //-- reimprime com o MESMO numero, para nao duplicar o registro no banco
    If !Empty(cNNum)
        Return cNNum
    EndIf

    SEE->(DbGoTo(Val(aBanco[BCO_CEMP])))
    If SEE->(Eof())
        Return ""
    EndIf

    //-- Trava ANTES de ler: se alguem gerar boleto ao mesmo tempo (IMPRIMEBOL),
    //-- cada um recebe um numero diferente
    RecLock("SEE", .F.)
        nSeq := Val(SEE->EE_FAXATU)
        SEE->EE_FAXATU := Soma1(SEE->EE_FAXATU)
    SEE->(MsUnlock())

    cNNum := StrZero(nSeq, TamSX3("E1_NUMBCO")[1])      // mesmo formato do IMPRIMEBOL

    RecLock("SE1", .F.)
        SE1->E1_NUMBCO  := cNNum
        SE1->E1_PORTADO := aBanco[BCO_COD]
    SE1->(MsUnlock())

Return cNNum

/*/ Pagador igual ao boleto atual: endereco principal do cliente /*/
Static Function _BAuSacado(aSacado)

    aSacado := AFill(Array(TAM_SAC), "")

    SA1->(DbSetOrder(1))
    If SA1->(DbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))
        aSacado[SAC_NOME]   := AllTrim(SA1->A1_NOME)
        aSacado[SAC_CNPJ]   := AllTrim(SA1->A1_CGC)
        aSacado[SAC_END]    := AllTrim(SA1->A1_END)
        aSacado[SAC_BAIRRO] := AllTrim(SA1->A1_BAIRRO)
        aSacado[SAC_CIDADE] := AllTrim(SA1->A1_MUN) + "-" + SA1->A1_EST
        aSacado[SAC_CEP]    := Transform(SA1->A1_CEP, "@R 99999-999")
    Else
        aSacado[SAC_NOME]   := AllTrim(SE1->E1_NOMCLI)
    EndIf

Return
