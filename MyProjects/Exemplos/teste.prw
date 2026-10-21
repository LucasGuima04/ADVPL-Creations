#Include "protheus.ch"


//------------------------------------------------------------------------------------------------------
/*{protheus.doc} teste ->user function só pode ser até 10 carcteres.
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      24/09/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------

User Function Input1()
	Local oDlg
	Local cNome   := Space(30)
	Local nIdade  := 0

	DEFINE MSDIALOG oDlg TITLE "Entrada" FROM 0,0 TO 300,600 PIXEL

	@ 10,10 SAY "Nome:"   PIXEL
	@ 10,60 GET cNome     PICTURE "@!" PIXEL

	@ 30,10 SAY "Idade:"  PIXEL
	@ 30,60 GET nIdade    PICTURE "999" PIXEL

	DEFINE SBUTTON FROM 60,10 TYPE 1 ACTION (oDlg:End()) ENABLE OF oDlg

	ACTIVATE MSDIALOG oDlg CENTERED

	MsgInfo("Olá " + AllTrim(cNome) + ", você tem: " + cValToChar(nIdade) + " anos!", "Teste")
Return

User Function Saudacao(cNome, nIdade)
	MsgInfo("Olá " + cNome + ", você tem: " + cValToChar(nIdade) + " anos!", "Teste")
Return
