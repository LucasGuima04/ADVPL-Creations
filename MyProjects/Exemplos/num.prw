#INCLUDE "protheus.ch"

Static nQtdDecim    := 3 
Static nTamStr      := 20

//------------------------------------------------------------------------------------------------------
/*{protheus.doc} Numeros()
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      02/10/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------

User Function Numeros()

    Local nVlrTotal := 13
    //Programa só reconhece até o 10 caractere
    //Sempre declarar numero começando com 'n'
    //Separação de decimais é feita por ponto
    //Precisão - no maximo 15 algarismos, 63 bits

    //----FUNÇÕES----//
    local nNum1 
    local nNum2
    local nRes
    local cResp

    //Retorna valor absoluto (Modulo)
    nNum1 := -560.23
    nRes := Abs(nNum1) 

    //Retorna valor Inteiro
    nRes := Int(nNum1)

    //Retorna maior de 2 numeros
    nRes := Max(nNum1,nNum2)

    //Retorna menor de 2 numeros
    nRes := Min(nNum1,nNum2)

    //Delimita decimais com arredondamento
    nRes := Round(nNum1, nQtdDecim)

    //Delimita decimais sem arredondamento
    nRes := NoRound(nNum1, nQtdDecim)

    //Gera um numero aleatorio entre 2
    nNum1 := 10
    nNum2 := 50
    nRes := Randomize(nNum1, nNum2)

    //Converter texto em numero
    nRes := Val(cNum)

    //Converter numero em texto
    nRes := cValToChar(nNum1)

    //Converter numero em texto adicinando espaços à esquerda 
    cResp := Str(nNum1, nTamStr, nQtdDecim)

    //Converter número em texto adicionando zeros à esquerda
    cResp := StrZero(nNum1, nTamStr, nQtdDecim)

    //Converter numero em texto usando mascara
    cResp := "Eu gosto de" + Transform(nNum1, "@E 999,999,999.99") + "tomates!"

    //Converter um numero para o carctere correspondente na tabela ASCII
    cResp := Chr (68) 

Return nVlrTotal 
