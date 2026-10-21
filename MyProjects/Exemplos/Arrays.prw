#INCLUDE "protheus.ch"

//------------------------------------------------------------------------------------------------------
/*{protheus.doc} Arrays()
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      02/10/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------


User Function Arrays()
Local aArray[4][4]
local nPos
//Adicionar na matriz
AAdd(aArray, {"Banana",7, "quilo", CToD("25/10/2019")})

//localizar posição de um dado
nPos := aScan(aArray, {|x| x[1] == ""})

//Ordenar array
//ASort

Return
