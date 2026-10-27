#Include "TOTVS.CH"

/*/{Protheus.doc} MT103FIM
PE após a gravação do documento de entrada
@type function
@version  1.0
@author Tiago Faria
@since 22/10/2020
@description PE após a gravação do documento de entrada
@version 1.1
@author juliano.ribeiro
@since 08/10/2026
@description Adicionado a gravação do Centro de Custo no título financeiro (SE2) com base no primeiro item da NF (SD1)
/*/
User Function MT103FIM()
    Local nOpcao    := PARAMIXB[1]   // Opção Escolhida pelo usuario no aRotina
    Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFECODIGO DE APLICAÇÃO DO USUARIO
    Local cFilSE2   := xFilial("SE2")
    Local cFornec   := SF1->F1_FORNECE
    Local cLoja     := SF1->F1_LOJA
    Local cDoc      := SF1->F1_DOC
    Local cSerie    := SF1->F1_SERIE
    Local cCCusto   := ""
    Local cQuerySD1 := GetNextAlias()
    Local cQuerySE2 := GetNextAlias()

    // Protecao para garantir que o SF1 esta corretamente posicionado
    If Empty(cDoc) .Or. Empty(cFornec)
        Return
    EndIf

    // 1. Captura o Centro de Custo fisicamente gravado no primeiro item da NF (SD1)
    BeginSQL Alias cQuerySD1
        SELECT D1_CC
        FROM %Table:SD1% SD1
        WHERE SD1.%NotDel%
          AND D1_FILIAL  = %Exp:xFilial("SD1")%
          AND D1_DOC     = %Exp:cDoc%
          AND D1_SERIE   = %Exp:cSerie%
          AND D1_FORNECE = %Exp:cFornec%
          AND D1_LOJA    = %Exp:cLoja%
    EndSQL
    
    If !(cQuerySD1)->(Eof())
        cCCusto := (cQuerySD1)->D1_CC
    EndIf
    (cQuerySD1)->(DbCloseArea())

    // 2. Localiza o titulo financeiro correspondente e aplica o RecLock
    If !Empty(cCCusto)
        BeginSQL Alias cQuerySE2
            SELECT R_E_C_N_O_ AS RECNO_SE2
            FROM %Table:SE2% SE2
            WHERE SE2.%NotDel%
              AND E2_FILIAL  = %Exp:cFilSE2%
              AND E2_NUM     = %Exp:cDoc%
              AND E2_PREFIXO = %Exp:cSerie%
              AND E2_FORNECE = %Exp:cFornec%
              AND E2_LOJA    = %Exp:cLoja%
        EndSQL

        While !(cQuerySE2)->(Eof())
            SE2->(DbGoto((cQuerySE2)->RECNO_SE2))
            If SE2->(RecLock("SE2", .F.))
                SE2->E2_CCUSTO := cCCusto
                SE2->(MsUnlock())
            EndIf
            (cQuerySE2)->(DbSkip())
        EndDo
        (cQuerySE2)->(DbCloseArea())
    EndIf

    if (nOpcao == 3 .or. nOpcao == 4) .and. nConfirma == 1
        u_grvSF1Modal()
    endif

    Return
