#INCLUDE 'TOTVS.CH'

/*/{protheus.doc} MT410TOK()
Função que proibe lançar pedidos sem estoque de produto(s) selecionado(s)
@type       user function
@author     Lucas Guimarães
@since      09/10/2026
/*/

User Function MT410TOK()
	Local lRetorno := .T.
	Local nPosProd := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local nPosLoc  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_LOCAL"})
	Local nPosQtd  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local nPosTes  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local aNecess  := {}	// {produto, local, qtd total necessária}
	Local cMsg     := ""
	Local nSaldo   := 0
	Local nX       := 0
	Local nPos     := 0

	// Só valida pedidos normais (ignora devolução, complemento, etc.)
	If M->C5_TIPO <> "N" .Or. nPosProd == 0 .Or. nPosLoc == 0 .Or. nPosQtd == 0 .Or. nPosTes == 0
		Return .T.
	EndIf

	// 1) Soma a quantidade por produto+armazém (o mesmo produto pode repetir em várias linhas)
	For nX := 1 To Len(aCols)
		If !aCols[nX][Len(aCols[nX])]	// linha não deletada

			// Só considera TES que movimenta estoque
			If Posicione("SF4", 1, xFilial("SF4") + aCols[nX][nPosTes], "F4_ESTOQUE") == "S"

				nPos := aScan(aNecess, {|x| x[1] == aCols[nX][nPosProd] .And. x[2] == aCols[nX][nPosLoc]})
				If nPos == 0
					aAdd(aNecess, {aCols[nX][nPosProd], aCols[nX][nPosLoc], aCols[nX][nPosQtd]})
				Else
					aNecess[nPos][3] += aCols[nX][nPosQtd]
				EndIf
			EndIf
		EndIf
	Next nX

	// 2) Compara com o saldo disponível na SB2
	DbSelectArea("SB2")
	SB2->(DbSetOrder(1))	// B2_FILIAL + B2_COD + B2_LOCAL

	For nX := 1 To Len(aNecess)
		If SB2->(DbSeek(xFilial("SB2") + aNecess[nX][1] + aNecess[nX][2]))
			nSaldo := SaldoSB2()	// saldo disponível (atual - reservas - empenhos)
		Else
			nSaldo := 0
		EndIf

		If nSaldo < aNecess[nX][3]
			cMsg += AllTrim(aNecess[nX][1]) + " (Arm. " + aNecess[nX][2] + ")" + ;
			        " - Necessário: " + cValToChar(aNecess[nX][3] - nSaldo) + ;
			        " | Disponível: " + cValToChar(nSaldo) + CRLF
		EndIf
	Next nX

	If !Empty(cMsg)
		lRetorno := .F.
		Aviso("Estoque insuficiente", ;
		      "Não é possível salvar o pedido. Produtos sem saldo:" + CRLF + CRLF + cMsg, ;
		      {"OK"}, 3)
	EndIf
Return lRetorno
