#Include "protheus.ch"

//------------------------------------------------------------------------------------------------------
/*{protheus.doc} Strings()
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      02/10/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------

User Function Strings()
    Local cHtml
    Local cTexto
    Local cResp
    Local nAt
    Local lResp
    //Exemplo de quando usar aspas simples para string
    cHtml := '<a href="https://youtube.com/" target="_self">Youtube</a>'

    //Converter string padrão ANSI para OEM
    cTexto := "Lucas"
    cResp := ANSIToOEM(cTexto)

    //Converte um caractere para seu valor mais À esquerda da tabela ASCII
    cResp := Asc("A")

    //Pesquisa a posição de um texto dentro de outro
    cTexto := "Bom dia a todos ouvintes"
    nAt := AT("dia", cTexto)

    //Valida se o caracter é letra
    lResp := IsAlpha(cTexto)

    //Tamanho da string
    nAt := Len(cTexto)

    //Left() Right)()

    //Lower() e Upper()

    //Centraliza adicinando adicionando carateres à esq e dir
    cResp := PadC(cTexto, 20, "-")

    //PadR e PadL

    //Replicate()

    //StrTokArr() e Separar()
    cTexto := "meu , pai, gosta, de, viajar."
    cResp := Separa(cTexto, ",")

    //Tranforma um caractere em outro
    cTexto := "1.255.634,25"
    Cresp := StrTran(StrTran(cTexto,".", ""),",",".")

    
Return
