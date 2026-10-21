#INCLUDE "protheus.ch"

//------------------------------------------------------------------------------------------------------
/*{protheus.doc} Operadores()
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      02/10/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------

User Function Operadores()

    local cResp
    local nNum1
    local nNum2
    local cChar1
    local cChar2
    local lComp

    //Operadores String
    lComp := cChar1 $ cChar2 //Comparação de string(Está contido)

    //Indentificador de Apelido
    //SA1 -> A1_COD
    //cAliasTop := "SA1"
    //(cAliasTop)->A1_COD


    //& MacroSubstituição
    cChar1 := "1+2"
    nResp := &cChar1

    //@ Passagem de parâmetro por referência
    U_VarEscop(@nNum1) 

Return
