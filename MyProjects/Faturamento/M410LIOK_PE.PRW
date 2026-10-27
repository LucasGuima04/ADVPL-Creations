#Include "TOTVS.ch"
#INCLUDE 'PARMTYPE.CH'

/*/{Protheus.doc} M410LIOK
Ponto de entrada de validacao de linha do Pedido de Venda.
Bloqueia a insercao de itens caso o saldo disponivel (SB2) 
fique abaixo do estoque minimo estipulado (SB1).
@type function
@version 1.1 
@author juliano.ribeiro / Lucas Guimarães
@since 19/10/2026
@return lRet, Retorna .T. se a linha for valida, .F. caso contrario
/*/
User Function M410LIOK()
	Local lRet      := .T. // .T. permite que a linha seja aceite. .F. bloquearia a inserção.
    Local nI
 	// Em M410LIOK, as variaveis de memoria estao disponiveis durante a digitacao
	Local cProduto  := ""
	Local nQtdVen   := 0
	Local cLocal    := ""
	Local nPosProd  := aScan(aHeader,{|x| allTrim(x[2]) == "C6_PRODUTO"})
	Local nPosQtdVen:= aScan(aHeader,{|x| allTrim(x[2]) == "C6_QTDVEN"})
	Local nPosLocal := aScan(aHeader,{|x| allTrim(x[2]) == "C6_LOCAL"})
	Local nSaldUtil := 0
	Local nEstMin   := 0	

	Local nPosPesL := 0
	Local nX	   := 0
	Local nPosPesB := 0
	Local nTotPesl := 0
	Local nTotPesb := 0
	Local nTam		 := len(aCols)
	// local nVolume	:= 0 

	nPosPesL := aScan(aHeader,{|x| allTrim(x[2]) == "C6_ZZPTLIQ"})	// Aqui trocar para o campo de usuário para o Peso Liquido
	nPosPesB := aScan(aHeader,{|x| allTrim(x[2]) == "C6_ZZPTBRU"})	// Aqui trocar para o campo de usuário para o Peso Bruto
	//! Comentado pois não está correto colocar o Volume no Pedido de Venda.
	// nPosPesQ := aScan(aHeader,{|x| allTrim(x[2]) == "C6_QTDVEN"}) 	// Aqui trocar para o campo de usuário para o Volume
	//nPosPesQ := SC6->C6_QTDENT 

	For nX := 1 to nTam
		//--Verifica se Nao esta Deletado no aCols
		If !aCols[nx][len(aCols[nX])] .AND. nPosPesL > 0 .AND.	nPosPesB > 0		
			//! Comentado pois não está correto colocar o Volume no Pedido de Venda.
			// nVolume		+= aCols[nX][nPosPesQ]
			//nVolume		+= nPosPesQ
			nTotPesl	+= aCols[nX][nPosPesL]
			nTotPesb	+= aCols[nX][nPosPesB]
			//--Em M410LIOK, as variaveis de memoria estao disponiveis durante a digitacao
		EndIf
		cProduto  := aCols[nX][nPosProd]
		nQtdVen   := aCols[nX][nPosQtdVen]
		cLocal    := aCols[nX][nPosLocal]
        // 1. Consulta ao cadastro de Produto para obter o Estoque Minimo
        SB1->(DbSetOrder(1)) // B1_FILIAL + B1_COD
        If SB1->(DbSeek(xFilial("SB1") + cProduto))
            nEstMin := SB1->B1_ESTMIN
        EndIf

        // 2. Consulta de Saldo Fisico e Financeiro Atual
        SB2->(DbSetOrder(1)) // B2_FILIAL + B2_COD + B2_LOCAL
        If SB2->(DbSeek(xFilial("SB2") + cProduto + cLocal))
            
            // Calculo estrutural do Saldo Util (Quantidade Atual - Quantidade Empenhada)
            nSaldUtil := SB2->B2_QATU - SB2->B2_RESERVA
            
            // Subtrai a quantidade digitada na linha em curso para avaliar o saldo residual
            If (nSaldUtil - nQtdVen) < nEstMin
                Help("", 1, "SALDO_INSUF", , "Saldo util insuficiente. Esta operacao viola o estoque minimo do produto.", 1, 0)
                lRet := .F.
                Break
            EndIf
        Else
            Help("", 1, "SEM_SALDO", , "Produto sem saldo fisico cadastrado neste armazem.", 1, 0)
            lRet := .F.
            Break
        EndIf

		//Objetivo: Avisar o usuario em caso de inserção de produto duplicado.
		If !Empty(cProduto) .And. nPosProd > 0
			// Percorre as linhas do grid em memória
			For nI := 1 To Len(aCols)
				// Ignora a linha em que o utilizador está (n) e as linhas marcadas como eliminadas
				If nI != n .And. !aCols[nI][Len(aCols[nI])]
					// Se encontrar o mesmo código de produto noutra linha válida
					If aCols[nI][nPosProd] == cProduto
						MsgAlert("O produto " + AllTrim(cProduto) + " já se encontra inserido na linha " + StrZero(nI, 2) + " deste pedido!", "Aviso de Duplicidade")
						Exit
					EndIf
				EndIf
			Next nI
		EndIf

	Next nX

	//! Comentado pois não está correto colocar o Volume no Pedido de Venda.
	// M->C5_VOLUME1	:= nVolume
	M->C5_PESOL  	:= nTotPesl
	M->C5_PBRUTO 	:= nTotPesB

Return lRet


