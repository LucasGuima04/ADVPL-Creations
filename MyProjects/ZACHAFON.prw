#Include "Protheus.ch"

/*/{Protheus.doc} ZACHAFON
Descobre em qual fonte (.prw) esta compilada uma funcao do RPO.
Uso: colocar no menu (ou executar pelo VS Code) e informar o nome da funcao.
Aceita curinga: U_*BOL*  |  U_PRTNFESEF  |  *DANFE*
@type User Function
@author     Lucas Guimarães
@since      09/10/2026
/*/
User Function ZACHAFON()

    Local aPergs := {}
    Local aRet   := {}
    Local aType  := {}
    Local aFile  := {}
    Local aLine  := {}
    Local aDate  := {}
    Local aTime  := {}
    Local aFunc  := {}
    Local cMsg   := ""
    Local nI

    aAdd(aPergs, {1, "Funcao (aceita *)", PadR("U_*BOL*", 40), "", "", "", "", 100, .T.})

    If !ParamBox(aPergs, "Localizar fonte de uma funcao", @aRet)
        Return
    EndIf

    aFunc := GetFuncArray(AllTrim(Upper(aRet[1])), @aType, @aFile, @aLine, @aDate, @aTime)

    If Empty(aFunc)
        MsgInfo("Nenhuma funcao encontrada para " + AllTrim(aRet[1]), "Resultado")
        Return
    EndIf

    For nI := 1 To Len(aFunc)
        cMsg += aFunc[nI] + "  ->  fonte: " + aFile[nI] + ;
                "  (linha " + cValToChar(aLine[nI]) + ", compilado em " + DToC(aDate[nI]) + ")" + CRLF
    Next nI

    MsgInfo(cMsg, "Resultado")

Return
