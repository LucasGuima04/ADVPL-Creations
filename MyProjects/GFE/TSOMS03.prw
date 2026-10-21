#INCLUDE 'TOTVS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} User Function TSOMS03
	Romaneio OMS - RELATÓRIO DE CARGA
	@type  Function
	@author TOTVSIP
	@since 23/01/2020
	@version 1.0
	@history 02/02/2022, Vinicius Franceschi - CRM Services, Realizada a correção da filial no cadastro de transportadora para nao duplicar registros na impressao
	@history 02/06/2022, Muriel Zounar - Realizado alteração nas consultas das funções qIteSafra e qNotas, pois estavam trazendo dados excluídos
	/*/
User Function TSOMS03()
	U_SIROMS03()
Return

User Function SIROMS03()
	Local lBold					 := .T.
	Local lNotBold			 := .F.
	Local lSublinhado		 := .T.
	Local lNotSublinhado := .F.
	Local cQryRomaneio	 := ""
	Local aParBox   		 := {}
	
	Public cArquivo := "\relCargas1_"+RetCodUSR()+STRTran(Time() ,":" ,"")+".jpg"
	Public oRel 	  := IpFwMsPrinter():New(cArquivo ,,,,.F.)
	
	Private o10Arial		:= tFont():New("Arial"	,,10,,lNotBold	,,,,,lNotSublinhado)
	Private o10BArial		:= tFont():New("Arial"	,,10,,lBold		,,,,,lNotSublinhado)
	Private o10BSArial	:= tFont():New("Arial"	,,12,,lBold		,,,,,lSublinhado)
	Private o12Arial		:= tFont():New("Arial"	,,12,,lNotBold	,,,,,lNotSublinhado)
	Private o12BArial		:= tFont():New("Arial"	,,12,,lBold		,,,,,lNotSublinhado)
	Private o14BArial		:= tFont():New("Arial"	,,14,,lBold		,,,,,lNotSublinhado)
	Private o14Arial		:= tFont():New("Arial"	,,14,,lNotBold	,,,,,lNotSublinhado)
	Private o18BArial		:= tFont():New("Arial"	,,18,,lBold		,,,,,lNotSublinhado)
	Private lRet			  := .F.
	Private cRomaneio		:= ""
	Private cTsDeCarga	:= ""
	Private cTsAteCarga := ""
	Private nVlrTtl			:= {}
	Private aImpostos		:= {}

	aAdd(aParBox,{1, "Carga de? "      , space(TamSX3("DAK_COD")[1])		, "", "", ""			, "", 50, .F.}) //MV_PAR01
	aAdd(aParBox,{1, "Carga até? "     , "ZZZZZZ"											, "", "", ""			, "", 50, .F.}) //MV_PAR02
	aAdd(aParBox,{1, "Sequencia de? "  , space(TamSX3("DAK_SEQCAR")[1]), "", "", ""			, "", 50, .F.}) //MV_PAR03
	aAdd(aParBox,{1, "Sequencia até? " , "ZZ"													, "", "", ""			, "", 50, .F.}) //MV_PAR04
	aAdd(aParBox,{1, "Data de? "       , stod("20010101")							, "", "", ""			, "", 50, .F.}) //MV_PAR05
	aAdd(aParBox,{1, "Data até? "      , (DATE())											, "", "", ""			, "", 50, .F.}) //MV_PAR06
	aAdd(aParBox,{1, "Município? "     , space(TamSX3("A1_MUN")[1])		, "", "", "SA1MUN", "", 70, .F.}) //MV_PAR07
	aAdd(aParBox,{3, "Imprimi conferência de carga s/n?", 1, {"Sim", "Não"}, 50, "", .F.}) //MV_PAR07

	If ParamBox(aParBox,"RELATÓRIO DE CARGA",,,,,,,,,.T.,.T.)
		cTsDeCarga	 := MV_PAR01
		cTsAteCarga	 := MV_PAR02
		cImpCarga		 := MV_PAR08
		cQryRomaneio := qryRom1()
		cRomaneio		 := (cQryRomaneio)->DAK_COD

		oRel:StartPage()
		Processa({|| ImpRel()}, 'Gerando Relatório...')
		oRel:EndPage()

		If lRet .and. (cImpCarga == 1)
			u_SIROMS02(cTsDeCarga, cTsAteCarga)
		Endif

		fErase(cArquivo)
		oRel:print()
		freeobj(oRel)
		oRel := Nil
	Endif
Return

//? Função criada para que o usuário possa acompanhar o processamento. - Muriel Zounar (02/06/2023)
Static Function ImpRel()
	ProcRegua(3)
	IncProc('Imprimindo cabeçalho...')
	impCabec()

	IncProc('Imprimindo produtos...')
	impCodigo()
	
	IncProc('Imprimindo totalizadores...')
	impTotal()
Return

Static Function impCabec()
	Local nLinha	:= 0
	Local nColum1	:= 0
	Local nColum2	:= 0

	oRel:IPline(nLinha + 0.3 , nColum1 + 0.5 ,nLinha + 0.3 ,nColum2 + 0.5 ,,,.T.)
	
	oRel:IPSay(nLinha + 0.5, nColum1 + 0.5, "ALCOOL SAFRA" 						 , o12Arial,, .T.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 0.5, "Romaneio nº " + cRomaneio , o12Arial,, .T.)
Return

Static Function impCodigo()
	Local nLinha	 := 0
	Local nColum1	 := 0
	Local nColum2	 := 0
	Local cQryAli	 := qIteSafra(cRomaneio)
	Local cQryNota := ""
	Local cProduto := ""
	Local cDesc    := ""
	Local cSoma    := ""
	
	//--- Inicializa a funcao fiscal
	MaFisSave()
	MaFisEnd()

	While (cQryAli)->(!Eof())
		SA1->(dbSeek(xFilial('SA1') + (cQryAli)->C9_CLIENTE + (cQryAli)->C9_LOJA))
		SB1->(dbSeek(xFilial('SB1') + (cQryAli)->C9_PRODUTO))

		MaFisIni(SA1->A1_COD, SA1->A1_LOJA, 'C', 'N', SA1->A1_TIPO,,,, 'SB1')
		MaFisAdd(SB1->B1_COD, (cQryAli)->C6_TES, (cQryAli)->C9_QTDLIB, (cQryAli)->C9_PRCVEN, 0, '', '',, 0, 0, 0, 0, (cQryAli)->TOTITEM, 0, SB1->(RecNo()))
		
		aImpostos := MaFisRet(, 'NF_IMPOSTOS')

		if cProduto <> (cQryAli)->C9_PRODUTO
			cProduto := (cQryAli)->C9_PRODUTO
			cDesc		 := (cQryAli)->B1_DESC
			cSoma		 := allTrim(str(qSomaProd(cRomaneio, cProduto)))
			cQryNota := qNotas(cRomaneio, cProduto)

			oRel:IPSay(nLinha + 0.5, nColum1 + 0.5  , "Codigo" 							 , o12BArial,, .F.)
			oRel:IPSay(nLinha + 0.5, nColum1 + 4.5  , "Descrição do Produto" , o12BArial,, .F.)
			oRel:IPSay(nLinha + 0.5, nColum1 + 14.5 , "Quantidade" 					 , o12BArial,, .F.)
			
			oRel:IPline(nLinha + 0.9, nColum1 + 0.5, nLinha + 0.9, nColum2 + 15,,, .T.)
			
			oRel:IPSay(nLinha + 0.1, nColum1 + 0.5 , cProduto, o12BArial,, .F.)
			oRel:IPSay(nLinha + 0.1, nColum1 + 4.5 , cDesc	 , o12BArial,, .F.)
			oRel:IPSay(nLinha + 0.1, nColum1 + 14.5, cSoma	 , o12BArial,, .T.)

			impNotas(cQryNota)
		endif

		(cQryAli)->(dbSkip())
	Enddo

	//--- Encerra a funcao fiscal
	MaFisEnd()
	MaFisRestore()
Return

Static Function impNotas(cQryNota)
	Local nLinha			:= 0
	Local nColum1			:= 0
	Local nColum2			:= 0
	Local cQtde				:= ""
	Local cDesc				:= ""
	Local cTransp			:= ''
	Local cNomeTransp := ''
	Local nQtd				:= 25
	Local aDesc				:= {}
	Local cNota				:= ""
	Local cSerie			:= ''
	Local cCidade			:= ""
	Local lVertical		:= .T.

	oRel:IPSay(nLinha + 0.5, nColum1 + 0.5 , 'Qtd'					 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 1.5 , 'Nota/Pedi'		 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 4.5 , 'Cidade'				 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 8.5 , 'Cliente'			 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 14.5, 'Transportadora', o12Arial,, .F.)
	
	oRel:IPline(nLinha + 0.9, nColum1 + 0.5, nLinha + 0.9, nColum2 + 20,,, .T.)

	While (cQryNota)->(!eof())
		cQtde				:= allTrim(str((cQryNota)->C9_QTDLIB))
		cNota				:= (cQryNota)->C9_NFISCAL
		cSerie			:= (cQryNota)->C9_SERIENF
		cCidade			:= (cQryNota)->A1_MUN
		cCliente		:= (cQryNota)->A1_NOME
		cTransp			:= (cQryNota)->DAK_TRANSP
		cNomeTransp := (cQryNota)->A4_NOME
		cPedido			:= (cQryNota)->DAI_PEDIDO
		cDesc				:= alltrim((cQryNota)->A1_NOME)
		aDesc				:= charToImp(cDesc, nQtd)

		If (!empty(cNota) .AND. !empty(cSerie)) .OR. !empty(cPedido) .AND. !empty(cTransp)
			oRel:IPSay(nLinha + 0.5, nColum1 + 0.5, cQtde, o10Arial,, .F.)
			
			If !empty(cNota)
				oRel:IPSay(nLinha + 0.5, nColum1 + 1.5, cNota, o10Arial,, .F.)

				lRet := .T.
			elseIf !empty(cPedido)
				oRel:IPSay(nLinha + 0.5, nColum1 + 1.5, cPedido, o10Arial,, .F.)
			Endif

			oRel:IPSay(nLinha + 0.5, nColum1 + 4.5 , cCidade		, o10Arial,, .F.)
			oRel:IPSay(nLinha + 0.5, nColum1 + 8.5 , aDesc[1]		, o10Arial,, .F.)
			oRel:IPSay(nLinha + 0.5, nColum1 + 14.5, cNomeTransp, o10Arial,, .T.)
		Endif

		If !oRel:isPrint(3 ,lVertical)
			oRel:endPage()
			oRel:startPage()

			impCabec()
		Endif

		(cQryNota)->(dbSkip())
	Enddo
Return

Static Function impTotal()
	Local nLinha		:= 0
	Local nColum1		:= 0
	Local nColum2		:= 0
	Local i					:= 0
	Local nI				:= 0
	Local cQryRoda	:= qRodape(cRomaneio)
	Local cQtdPed 	:= AllTrim(STR(qConPed(cRomaneio)))
	Local cPesoBrut	:= (cQryRoda)->DAK_PESO
	Local nTotal		:= (cQryRoda)->DAK_VALOR
	Local cQtdUni		:= qSomUni(cRomaneio)
	Local nQtd			:= 125
	Local cTexto		:= "Declaro ter conferido e acompanhado o carregamento das quantidades de caixas acima descritas. Estou ciente da responsabilidade de retornar com todos os 'canhotos' devidamente assinados, devendo responder por qualquer irregularidade ou danos na carga."
	Local aDesc			:= charToImp(cTexto, nQtd)
	Local lVertical	:= .T.

	oRel:IPline(nLinha + 0.3, nColum1 + 0.5, nLinha + 0.3, nColum2 + 0.5,,, .T.)

	cPesoBrut	:= transform(cPesoBrut, "@E 999,999,999.99")
	cQtdUni		:= transform(cQtdUni	, "@E 999,999,999")
	cTotal		:= transform(nTotal		, "@E 999,999,999.99")

	oRel:IPSay(nLinha + 0.5, nColum1 + 0.5 , "Total de Pedidos: " + cQtdPed, o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 4.5 , "Peso Bruto: " + cPesoBrut		 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 8.5 , "Unidades: " + cQtdUni				 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 12.5, "Valor Pedido:"							 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 17.0, "R$ " + cTotal								 , o12Arial,, .F.)

	For nI := 1 to Len(aImpostos)
		cTexto := Upper(Alltrim(aImpostos[nI, 02]))
		
		If !(Upper("apuracao") $ cTexto)
			If (Upper("ipi") $ cTexto) .OR. (Upper("retido") $ cTexto)
				nTotal += aImpostos[nI, 05]
			Endif
		Endif
	Next

	oRel:IPSay(nLinha + 1, nColum1 + 12.5, "Valor Total:"																 , o12Arial,, .F.)
	oRel:IPSay(nLinha + 1, nColum1 + 17.0, "R$ " + Transform(nTotal, "@E 999,999,999.99"), o12Arial,, .F.)

	oRel:IPline(nLinha + 1, nColum1 + 0.5, nLinha + 1, nColum2 + 0.5,,, .T.)

	for i := 1 to len(aDesc)
		oRel:IPSay(nLinha + 0.5, nColum1 + 0.5, aDesc[i], o12Arial,, .T.)
	next i

	oRel:IPline(nLinha + 1, nColum1 + 0.5, nLinha + 1, nColum2 + 0.5,,, .T.)

	If !oRel:isPrint(1.5, lVertical)
		oRel:endPage()
		oRel:startPage()

		impCabec()
	Endif

	oRel:IPSay(nLinha + 0.5, nColum1 + 8 , "_____________________________", o12Arial,, .T.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 10, "Motorista"										, o12Arial,, .F.)
Return

Static Function charToImp(cString, nQtdChar)
	Local aRet   := {}
	Local nLine  := 0
	Local nCount := MlCount(cString, nQtdChar)

	If nCount == 0
		aRet := {""}
	else
		for nLine := 1 to nCount
			aadd(aRet, MemoLine(cString, nQtdChar, nLine))
		next nLine
	Endif
Return aRet

Static Function qryRom1()
	Local cQuery    := ""
	Local cQryRom1  := GetNextAlias()
	Local cCargaDe  := MV_PAR01       // CÓDIGO DE CARGA DE
	Local cCargaAte := MV_PAR02       // CÓDIGO DE CARGA ATÉ
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       //Municipio

	cQuery := "SELECT" + CRLF
	cQuery += " DISTINCT DAK.DAK_COD, DAK.DAK_SEQCAR, DAK.DAK_DATA" + CRLF
	cQuery += "FROM "+ RetSqlName("DAK") +" DAK" + CRLF
	cQuery += "INNER JOIN " +RetSqlName("DAI") +" DAI ON" + CRLF
	cQuery += " DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
	cQuery += " DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
	cQuery += " DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " +RetSqlName("SA1") +" SA1 ON" + CRLF
	cQuery += " SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND " + CRLF
	cQuery += " SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
	cQuery += " SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
	cQuery += " SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE"
	cQuery +=	" DAK.DAK_COD >= '" + cCargaDe + "' AND DAK.DAK_COD <= '" + cCargaAte + "' AND" + CRLF
	cQuery += " DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
	cQuery += " DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
	
	If !Empty(cMunicip)
		cQuery += " SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
	Endif
	
	cQuery += " DAK.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "ORDER BY DAK.DAK_COD, DAK.DAK_SEQCAR, DAK.DAK_DATA"

	TCQUERY cQuery NEW ALIAS &cQryRom1

	dbSelectArea(cQryRom1)

	(cQryRom1)->(DbGoTop())
Return cQryRom1

Static Function qIteSafra(cRomaneio)
	Local cQuery    := ""
	Local cQryIte   := GetNextAlias()
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       //Municipio

	//* Consulta alterada por: Muriel Zounar (02/06/2023)

	cQuery := "SELECT" + CRLF
	cQuery += "	DISTINCT " + CRLF
	cQuery += "	SC9.C9_CLIENTE, " + CRLF
	cQuery += "	SC9.C9_LOJA, " + CRLF
	cQuery += "	SC9.C9_PRODUTO, " + CRLF
	cQuery += "	SC9.C9_QTDLIB, " + CRLF
	cQuery += "	SC9.C9_PRCVEN, " + CRLF
	cQuery += "	(SC9.C9_QTDLIB * SC9.C9_PRCVEN) AS TOTITEM, " + CRLF
	cQuery += "	SC6.C6_TES, " + CRLF
	cQuery += "	SB1.B1_DESC" + CRLF
	cQuery += "FROM " + CRLF
	cQuery += "	" + RetSqlName('DAK') + " DAK" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('DAI') + " DAI " + CRLF
	cQuery += "	ON DAI.DAI_FILIAL = DAK.DAK_FILIAL" + CRLF
	cQuery += "	AND DAI.DAI_COD = DAK.DAK_COD" + CRLF
	cQuery += "	AND DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA1') + " SA1" + CRLF
	cQuery += "	ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'" + CRLF
	cQuery += "	AND SA1.A1_COD = DAI.DAI_CLIENT" + CRLF
	cQuery += "	AND SA1.A1_LOJA = DAI.DAI_LOJA" + CRLF
	cQuery += "	AND SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('SC9') + " SC9" + CRLF
	cQuery += "	ON SC9.C9_FILIAL = DAI.DAI_FILIAL" + CRLF
	cQuery += "	AND DAI.DAI_COD = SC9.C9_CARGA" + CRLF
	cQuery += "	AND SC9.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('SC6') + " SC6" + CRLF
	cQuery += "	ON SC6.C6_NUM = SC9.C9_PEDIDO" + CRLF
	cQuery += "	AND SC6.C6_ITEM = SC9.C9_ITEM" + CRLF
	cQuery += "	AND SC6.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('SB1') + " SB1" + CRLF
	cQuery += "	ON SB1.B1_COD = SC9.C9_PRODUTO" + CRLF
	cQuery += "	AND SB1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE " + CRLF
	cQuery += "	DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += "	AND DAK.DAK_COD = '" + cRomaneio + "'" + CRLF
	cQuery += "	AND DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
	cQuery += "	AND DAK.DAK_DATA BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	
	If !Empty(cMunicip)
		cQuery += "	AND SA1.A1_MUN = '" + cMunicip + "'" + CRLF
	Endif
	
	cQuery += "	AND DAK.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "ORDER BY " + CRLF
	cQuery += "	SC9.C9_PRODUTO" + CRLF

	TCQUERY cQuery NEW ALIAS &cQryIte

	/*
	* ************************************************************************************************************************************************
		? Conteúdo substituído:
		? Obs: Mantido a pedido do CP para possíveis análises posteriores.
		
		! Consulta anterior:

		// cQuery := "SELECT" + CRLF
		// cQuery += "DISTINCT SC5.C5_CLIENTE, SC5.C5_LOJACLI, SC6.C6_PRODUTO, SC6.C6_QTDVEN, SC6.C6_PRCVEN, SC6.C6_VALOR, SC6.C6_TES, SB1.B1_DESC" + CRLF
		// cQuery += "FROM " + RetSqlName("DAK") +" DAK" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("DAI") +" DAI ON" + CRLF
		// cQuery += "DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
		// cQuery += "DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
		// cQuery += "DAI.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SA1") +" SA1 ON" + CRLF
		// cQuery += "SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND " + CRLF
		// cQuery += "SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
		// cQuery += "SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
		// cQuery += "SA1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SC5") +" SC5 ON" + CRLF
		// cQuery += "SC5.C5_FILIAL = DAI.DAI_FILIAL AND" + CRLF
		// cQuery += "SC5.C5_NUM = DAI.DAI_PEDIDO AND " + CRLF
		// cQuery += "SC5.D_E_L_E_T_ = ' '"  + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SC6") +" SC6 ON" + CRLF
		// cQuery += "SC6.C6_FILIAL = SC5.C5_FILIAL AND" + CRLF
		// cQuery += "SC6.C6_NUM = SC5.C5_NUM AND" + CRLF
		// cQuery += "SC6.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SB1") +" SB1 ON" + CRLF
		// cQuery += "SB1.B1_COD = SC6.C6_PRODUTO AND" + CRLF
		// cQuery += "SB1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "WHERE" + CRLF
		// cQuery += "DAK.DAK_COD = '" + cRomaneio + "' AND" + CRLF
		// cQuery += "DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
		// cQuery += "DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
		
		// If !Empty(cMunicip)
		// 	cQuery += " SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
		// Endif
		
		// cQuery += "DAK.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "ORDER BY SC6.C6_PRODUTO"
		* ************************************************************************************************************************************************
	*/
Return cQryIte

Static Function qSomaProd(cRomaneio, cCodIte)
	Local cQuery    := ""
	Local cQrySPd   := GetNextAlias()
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       //Municipio
	Local nQtdTot   := 0

	//* Consulta alterada por: Muriel Zounar (02/06/2023)

	cQuery := "SELECT" + CRLF
	cQuery += "	SUM(C9_QTDLIB) AS QUANTIDADE" + CRLF
	cQuery += "FROM " + CRLF
	cQuery += "	" + RetSqlName('DAK') + " DAK" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('DAI') + " DAI" + CRLF
	cQuery += "	ON DAI.DAI_FILIAL = DAK.DAK_FILIAL" + CRLF
	cQuery += "	AND DAI.DAI_COD = DAK.DAK_COD" + CRLF
	cQuery += "	AND DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA1') + " SA1" + CRLF
	cQuery += "	ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'" + CRLF
	cQuery += "	AND SA1.A1_COD = DAI.DAI_CLIENT" + CRLF
	cQuery += "	AND SA1.A1_LOJA = DAI.DAI_LOJA" + CRLF
	cQuery += "	AND SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SC9') + " SC9" + CRLF
	cQuery += "	ON SC9.C9_FILIAL = DAI.DAI_FILIAL" + CRLF
	cQuery += "	AND SC9.C9_PEDIDO = DAI.DAI_PEDIDO" + CRLF
	cQuery += "	AND SC9.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SB1') + " SB1" + CRLF
	cQuery += "	ON SB1.B1_COD = SC9.C9_PRODUTO" + CRLF
	cQuery += "	AND SB1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE" + CRLF
	cQuery += "	DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += "	AND DAK.DAK_COD = '" + cRomaneio + "'" + CRLF
	cQuery += "	AND DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
	cQuery += "	AND DAK.DAK_DATA BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	
	If !Empty(cMunicip)
		cQuery += "	AND SA1.A1_MUN = '" + cMunicip + "'" + CRLF
	Endif
	
	cQuery += "	AND SC9.C9_PRODUTO = '" + cCodIte + "'" + CRLF
	cQuery += "	AND DAK.D_E_L_E_T_ = ' '" + CRLF

	TCQUERY cQuery NEW ALIAS &cQrySPd

	/*
		* ************************************************************************************************************************************************
		? Conteúdo substituído:
		? Obs: Mantido a pedido do CP para possíveis análises posteriores.
		
		! Consulta anterior:

		// cQuery := "SELECT" + CRLF
		// cQuery += " SUM(C6_QTDVEN) AS QUANTIDADE" + CRLF
		// cQuery += "FROM " + RetSqlName("DAK") +" DAK" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("DAI") +" DAI ON" + CRLF
		// cQuery += " DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
		// cQuery += " DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
		// cQuery += " DAI.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " +RetSqlName("SA1") +" SA1 ON" + CRLF
		// cQuery += " SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND " + CRLF
		// cQuery += " SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
		// cQuery += " SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
		// cQuery += " SA1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " +RetSqlName("SC5") +" SC5 ON" + CRLF
		// cQuery += " SC5.C5_FILIAL = DAI.DAI_FILIAL AND" + CRLF
		// cQuery += " SC5.C5_NUM = DAI.DAI_PEDIDO AND " + CRLF
		// cQuery += " SC5.D_E_L_E_T_ = ' '"  + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SC6") +" SC6 ON" + CRLF
		// cQuery += " SC6.C6_FILIAL = SC5.C5_FILIAL AND" + CRLF
		// cQuery += " SC6.C6_NUM = SC5.C5_NUM AND" + CRLF
		// cQuery += " SC6.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " +RetSqlName("SB1") +" SB1 ON" + CRLF
		// cQuery += " SB1.B1_COD = SC6.C6_PRODUTO AND" + CRLF
		// cQuery += " SB1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "WHERE" + CRLF
		// cQuery += " DAK.DAK_COD = '" + cRomaneio + "' AND" + CRLF
		// cQuery += " DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
		// cQuery += " DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
	
		// If !Empty(cMunicip)
		// 	cQuery += " SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
		// Endif
		
		// cQuery += " SC6.C6_PRODUTO = '" + cCodIte + "' AND"
		// cQuery += " DAK.D_E_L_E_T_ = ' '" + CRLF

		* ************************************************************************************************************************************************
	*/

	dbSelectArea(cQrySPd)

	(cQrySPd)->(DbGoTop())
	
	If (cQrySPd)->(!eof())
		nQtdTot := (cQrySPd)->QUANTIDADE
	Endif
	
	(cQrySPd)->(dbCloseArea())
Return nQtdTot

Static Function qNotas(cRomaneio, cCodIte)
	Local cQuery    := ""
	Local cQryNota  := GetNextAlias()
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       // MUNICÍPIO

	//* Consulta alterada por: Muriel Zounar (02/06/2023)

	cQuery := "SELECT" + CRLF
	cQuery += "	SC9.C9_NFISCAL, " + CRLF
	cQuery += "	SC9.C9_SERIENF," + CRLF
	cQuery += "	SC9.C9_CLIENTE, " + CRLF
	cQuery += "	SA1.A1_NOME, " + CRLF
	cQuery += "	SA1.A1_MUN, " + CRLF
	cQuery += "	SA4.A4_NOME, " + CRLF
	cQuery += "	DAK.DAK_TRANSP, " + CRLF
	cQuery += "	DAK.DAK_COD, " + CRLF
	cQuery += "	DAI.DAI_COD, " + CRLF
	cQuery += "	DAI.DAI_PEDIDO, " + CRLF
	cQuery += "	SC9.C9_QTDLIB, " + CRLF
	cQuery += "	SB1.B1_DESC" + CRLF
	cQuery += "FROM " + CRLF
	cQuery += "	" + RetSqlName('DAK') + " DAK" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('DAI') + " DAI " + CRLF
	cQuery += "	ON DAI.DAI_FILIAL = DAK.DAK_FILIAL" + CRLF
	cQuery += "	AND DAI.DAI_COD = DAK.DAK_COD" + CRLF
	cQuery += "	AND DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA1') + " SA1" + CRLF
	cQuery += "	ON SA1.A1_FILIAL = '" + xFilial('SA1') + "'" + CRLF
	cQuery += "	AND SA1.A1_COD = DAI.DAI_CLIENT" + CRLF
	cQuery += "	AND SA1.A1_LOJA = DAI.DAI_LOJA" + CRLF
	cQuery += "	AND SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('SC9') + " SC9" + CRLF
	cQuery += "	ON SC9.C9_FILIAL = DAI.DAI_FILIAL" + CRLF
	cQuery += "	AND SC9.C9_CARGA = DAI.DAI_COD" + CRLF
	cQuery += "	AND SC9.C9_PEDIDO = DAI.DAI_PEDIDO" + CRLF
	cQuery += "	AND SC9.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "LEFT OUTER JOIN " + RetSqlName('SB1') + " SB1" + CRLF
	cQuery += "	ON SB1.B1_COD = SC9.C9_PRODUTO" + CRLF
	cQuery += "	AND SB1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA4') + " SA4" + CRLF
	cQuery += "	ON SA4.A4_FILIAL = DAK.DAK_FILIAL" + CRLF
	cQuery += "	AND SA4.A4_COD = DAK.DAK_TRANSP" + CRLF
	cQuery += "	AND SA4.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE " + CRLF
	cQuery += "	DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += "	AND DAK.DAK_COD = '" + cRomaneio + "'" + CRLF
	cQuery += "	AND DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
	cQuery += "	AND DAK.DAK_DATA BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	
	If !Empty(cMunicip)
		cQuery += "	AND SA1.A1_MUN = '" + cMunicip + "'" + CRLF
	Endif

	cQuery += "	AND SB1.B1_COD = '" + cCodIte + "'" + CRLF
	cQuery += "	AND DAK.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "ORDER BY " + CRLF
	cQuery += "	SC9.C9_NFISCAL" + CRLF

	TCQUERY cQuery NEW ALIAS &cQryNota

	/*
		* ************************************************************************************************************************************************
		? Conteúdo substituído:
		? Obs: Mantido a pedido do CP para possíveis análises posteriores.
		
		! Consulta anterior:

		// cQuery := " SELECT" + CRLF
		// cQuery += " DAI.DAI_NFISCA, DAI.DAI_SERIE, DAI.DAI_CLIENT, SA1.A1_NOME, SA1.A1_MUN, SA4.A4_NOME, DAK.DAK_TRANSP, DAK.DAK_COD, DAI.DAI_COD, DAI.DAI_PEDIDO, SC6.C6_QTDVEN, SB1.B1_COD " + CRLF
		// cQuery += " FROM " + RetSqlName("DAK") + " DAK" + CRLF
		// cQuery += " INNER JOIN " + RetSqlName("DAI") +" DAI ON" + CRLF
		// cQuery += " DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
		// cQuery += " DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
		// cQuery += " DAI.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " INNER JOIN " +RetSqlName("SA1") +" SA1 ON" + CRLF
		// cQuery += " SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND " + CRLF
		// cQuery += " SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
		// cQuery += " SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
		// cQuery += " SA1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " INNER JOIN " +RetSqlName("SC5") +" SC5 ON" + CRLF
		// cQuery += " SC5.C5_FILIAL = DAI.DAI_FILIAL AND" + CRLF
		// cQuery += " SC5.C5_NUM = DAI.DAI_PEDIDO AND " + CRLF
		// cQuery += " SC5.D_E_L_E_T_ = ' '"  + CRLF
		// cQuery += " INNER JOIN " + RetSqlName("SC6") +" SC6 ON" + CRLF
		// cQuery += " SC6.C6_FILIAL = SC5.C5_FILIAL AND" + CRLF
		// cQuery += " SC6.C6_NUM = SC5.C5_NUM AND" + CRLF
		// cQuery += " SC6.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " INNER JOIN " + RetSqlName("SB1") +" SB1 ON" + CRLF
		// cQuery += " SB1.B1_COD = SC6.C6_PRODUTO AND" + CRLF
		// cQuery += " SB1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " INNER JOIN " +RetSqlName("SA4") +" SA4 ON" + CRLF
		// cQuery += " SA4.A4_FILIAL = DAK.DAK_FILIAL AND" + CRLF
		// cQuery += " SA4.A4_COD = DAK.DAK_TRANSP AND" + CRLF
		// cQuery += " SA4.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " WHERE" + CRLF
		// cQuery += " DAK.DAK_COD = '" + cRomaneio + "' AND" + CRLF
		// cQuery += " DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
		// cQuery += " DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
		
		// If !Empty(cMunicip)
		// 	cQuery += 	" SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
		// Endif
		
		// cQuery += 		" SB1.B1_COD = '" + cCodIte + "' AND" + CRLF
		// cQuery += 		" DAK.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += " ORDER BY DAI.DAI_NFISCA"		
		* ************************************************************************************************************************************************
	*/
Return cQryNota

Static Function qRodape(cRomaneio)
	Local cQuery    := ""
	Local cQryRod   := GetNextAlias()
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       // MUNICÍPIO

	cQuery := "SELECT" + CRLF
	cQuery += " DISTINCT DAK.DAK_COD, DAI.DAI_COD, DAI.DAI_SERIE, DAK.DAK_PESO, DAK.DAK_VALOR" + CRLF
	cQuery += "FROM " + RetSqlName("DAK") +" DAK" + CRLF
	cQuery += "INNER JOIN " + RetSqlName("DAI") +" DAI ON" + CRLF
	cQuery += " DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
	cQuery += " DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
	cQuery += " DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName("SA1") +" SA1 ON" + CRLF
	cQuery += " SA1.A1_FILIAL = '" + xFilial("SA1") + "' AND " + CRLF
	cQuery += " SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
	cQuery += " SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
	cQuery += " SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE" + CRLF
	cQuery += "	DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += " AND DAK.DAK_COD = '" + cRomaneio + "' AND" + CRLF
	cQuery += " DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
	cQuery += " DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
	
	If !Empty(cMunicip)
		cQuery += " SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
	Endif
	
	cQuery += " DAK.D_E_L_E_T_ = ' '" + CRLF

	TCQUERY cQuery NEW ALIAS &cQryRod
Return cQryRod

Static Function qConPed(cRomaneio)
	Local cQuery    := ""
	Local cQryCPd   := GetNextAlias()
	Local SeqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local SeqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       // MUNICÍPIO
	Local nTotPed   := 0

	//* Consulta alterada por: Muriel Zounar (02/06/2023)

	cQuery += "SELECT" + CRLF
	cQuery += "	COUNT(DISTINCT SC9.C9_PEDIDO) AS PEDIDOS" + CRLF
	cQuery += "FROM " + CRLF
	cQuery += "	" + RetSqlName('DAK') + " DAK" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('DAI') + " DAI" + CRLF
	cQuery += "	ON DAI.DAI_FILIAL = DAK.DAK_FILIAL " + CRLF
	cQuery += "	AND DAI.DAI_COD = DAK.DAK_COD " + CRLF
	cQuery += "	AND DAI.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA1') + " SA1" + CRLF
	cQuery += "	ON SA1.A1_FILIAL = '0101'" + CRLF
	cQuery += "	AND SA1.A1_COD = DAI.DAI_CLIENT " + CRLF
	cQuery += "	AND SA1.A1_LOJA = DAI.DAI_LOJA " + CRLF
	cQuery += "	AND SA1.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SC9') + " SC9" + CRLF
	cQuery += "	ON SC9.C9_FILIAL = DAI.DAI_FILIAL " + CRLF
	cQuery += "	AND SC9.C9_PEDIDO = DAI.DAI_PEDIDO " + CRLF
	cQuery += "	AND SC9.D_E_L_E_T_ = ' '" + CRLF
	cQuery += "WHERE" + CRLF
	cQuery += "	DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += "	AND DAK.DAK_COD = '" + cRomaneio + "'" + CRLF
	cQuery += "	AND DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
	cQuery += "	AND DAK.DAK_DATA BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	
	If !Empty(cMunicip)
		cQuery += "	AND SA1.A1_MUN = '" + cMunicip + "'" + CRLF
	Endif
	
	cQuery += "	AND DAK.D_E_L_E_T_ = ' '" + CRLF

	TCQUERY cQuery NEW ALIAS &cQryCPd

	dbSelectArea(cQryCPd)

	(cQryCPd)->(DbGoTop())
	
	if (cQryCPd)->(!EOF())
		nTotPed := (cQryCPd)->PEDIDOS
	endif

	/*
		* ************************************************************************************************************************************************
		? Conteúdo substituído:
		? Obs: Mantido a pedido do CP para possíveis análises posteriores.
		
		! Consulta anterior:
		// cQuery := "SELECT" + CRLF
		// cQuery += " SC5.C5_NUM AS PEDIDOS " + CRLF
		// cQuery += "FROM " + RetSqlName("DAK") +" DAK" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("DAI") +" DAI ON" + CRLF
		// cQuery += " DAI.DAI_FILIAL = DAK.DAK_FILIAL AND" + CRLF
		// cQuery += " DAI.DAI_COD = DAK.DAK_COD AND" + CRLF
		// cQuery += " DAI.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SA1") +" SA1 ON" + CRLF
		// cQuery += " SA1.A1_FILIAL = '"+ xFilial("SA1") +"' AND " + CRLF
		// cQuery += " SA1.A1_COD = DAI.DAI_CLIENT AND " + CRLF
		// cQuery += " SA1.A1_LOJA = DAI.DAI_LOJA AND" + CRLF
		// cQuery += " SA1.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "INNER JOIN " + RetSqlName("SC5") +" SC5 ON" + CRLF
		// cQuery += " SC5.C5_FILIAL = DAI.DAI_FILIAL AND" + CRLF
		// cQuery += " SC5.C5_NUM = DAI.DAI_PEDIDO AND " + CRLF
		// cQuery += " SC5.D_E_L_E_T_ = ' '"  + CRLF
		// cQuery += "WHERE" + CRLF
		// cQuery += " DAK.DAK_COD = '" + cRomaneio + "' AND" + CRLF
		// cQuery += " DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "' AND" + CRLF
		// cQuery += " DAK.DAK_DATA >= '" + cDataDe + "' AND DAK.DAK_DATA <= '" + cDataAte + "' AND" + CRLF
		
		// If !Empty(cMunicip)
		// 	cQuery += " SA1.A1_MUN = '" + cMunicip + "' AND" + CRLF
		// Endif
		
		// cQuery += " DAK.D_E_L_E_T_ = ' '" + CRLF
		// cQuery += "GROUP BY SC5.C5_NUM" + CRLF

		// While (cQryCPd)->(!eof())
		// 	nTotPed++
		// 	(cQryCPd)->(dbSkip())
		// Enddo
		* ************************************************************************************************************************************************
	*/
	
	(cQryCPd)->(dbCloseArea())
Return nTotPed

Static Function qSomUni(cRomaneio)
	Local cQuery    := ""
	Local cQrySUni	:= getNextAlias()
	Local seqCarDe  := MV_PAR03       // SEQUENCIA DE CARGAR DE
	Local seqCarAte := MV_PAR04       // SEQUENCIA DE CARGA ATÉ
	Local cDataDe   := dtos(MV_PAR05) // DATA INICIAL
	Local cDataAte  := dtos(MV_PAR06) // DATA FINAL
	Local cMunicip  := MV_PAR07       // MUNICÍPIO
	Local nTotUni   := 0

	//* Consulta alterada por: Muriel Zounar (02/06/2023)

	cQuery += "SELECT" + CRLF
	cQuery += "	SUM(C9_QTDLIB) AS UNIDADES" + CRLF
	cQuery += "FROM " + RetSqlName('DAK') + " DAK " + CRLF
	cQuery += "INNER JOIN " + RetSqlName('DAI') + " DAI" + CRLF
	cQuery += "	ON 1 = 1" + CRLF
	cQuery += "	AND DAI_FILIAL = '" + xFilial('DAI') + "'" + CRLF
	cQuery += "	AND DAI_COD = DAK_COD" + CRLF
	cQuery += "	AND DAI.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SA1') + " SA1" + CRLF
	cQuery += "	ON 1 = 1" + CRLF
	cQuery += "	AND A1_FILIAL = '" + xFilial('SA1') + "'" + CRLF
	cQuery += "	AND A1_COD = DAI_CLIENT" + CRLF
	cQuery += "	AND A1_LOJA = DAI_LOJA" + CRLF
	cQuery += "	AND SA1.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "INNER JOIN " + RetSqlName('SC9') + " SC9" + CRLF
	cQuery += "	ON 1 = 1" + CRLF
	cQuery += "	AND C9_FILIAL = '" + xFilial('SC9') + "'" + CRLF
	cQuery += "	AND C9_PEDIDO = DAI_PEDIDO" + CRLF
	cQuery += "	AND C9_LOJA = DAI_LOJA" + CRLF
	cQuery += "	AND  SC9.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "WHERE 1 = 1" + CRLF
	cQuery += "	AND DAK.DAK_FILIAL = '" + xFilial('DAK') + "'" + CRLF
	cQuery += "	AND DAK.DAK_COD = '" + cRomaneio + "'" + CRLF
	cQuery += "	AND DAK.DAK_SEQCAR >= '" + SeqCarDe + "' AND DAK.DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
	cQuery += "	AND DAK.DAK_DATA BETWEEN '" + cDataDe + "' AND '" + cDataAte + "'" + CRLF
	
	If !Empty(cMunicip)
		cQuery += " AND A1_MUN = '" + cMunicip + "'" + CRLF
	Endif
	
	cQuery += "	AND DAK.D_E_L_E_T_ = ' ' " + CRLF

	/*
		* ************************************************************************************************************************************************
		? Conteúdo substituído:
		? Obs: Mantido a pedido do CP para possíveis análises posteriores.
		
		! Consulta anterior:
		// cQuery := "SELECT" + CRLF
		// cQuery += "	SUM(C9_QTDLIB) AS UNIDADES" + CRLF
		// cQuery += "FROM " + RetSqlTab("DAK") + CRLF
		// cQuery += "INNER JOIN " + RetSqlTab("DAI") + " ON 1 = 1" + CRLF
		// cQuery += "	AND " + RetSqlFil("DAI") + "" + CRLF
		// cQuery += "	AND DAI_COD = DAK_COD" + CRLF
		// cQuery += "	AND " + RetSqlDel("DAI") + "" + CRLF
		// cQuery += "INNER JOIN " + RetSqlTab("SA1") + " ON 1 = 1" + CRLF
		// cQuery += "	AND " + RetSqlFil("SA1") + "" + CRLF
		// cQuery += "	AND A1_COD = DAI_CLIENT" + CRLF
		// cQuery += "	AND A1_LOJA = DAI_LOJA" + CRLF
		// cQuery += "	AND " + RetSqlDel("SA1") + "" + CRLF
		// cQuery += "INNER JOIN " + RetSqlTab("SC9") + " ON 1 = 1" + CRLF
		// cQuery += "	AND " + RetSqlFil("SC9") + "" + CRLF
		// cQuery += "	AND C9_NUM = C5_NUM" + CRLF
		// cQuery += "	AND C9_LOJA = DAI_LOJA" + CRLF
		// cQuery += "	AND " + RetSqlDel("SC6") + "" + CRLF
		// cQuery += "WHERE 1 = 1" + CRLF
		// cQuery += "	AND " + RetSqlFil("DAK") + "" + CRLF
		// cQuery += "	AND DAK_COD = '" + cRomaneio + "'" + CRLF
		// cQuery += "	AND DAK_SEQCAR >= '" + SeqCarDe + "'" + CRLF
		// cQuery += "	AND DAK_SEQCAR <= '" + SeqCarAte + "'" + CRLF
		// cQuery += "	AND DAK_DATA >= '" + cDataDe + "'" + CRLF
		// cQuery += "	AND DAK_DATA <= '" + cDataAte + "'" + CRLF

		// If !Empty(cMunicip)
		// 	cQuery += " AND A1_MUN = '" + cMunicip + "'" + CRLF
		// Endif
	
		// cQuery += " AND " + RetSqlDel("DAK") + "" + CRLF
		* ************************************************************************************************************************************************
	*/

	TCQUERY cQuery NEW ALIAS &cQrySUni

	dbSelectArea(cQrySUni)

	(cQrySUni)->(dbGoTop())
	
	If (cQrySUni)->(!eof())
		nTotUni := (cQrySUni)->UNIDADES
	Endif
	
	(cQrySUni)->(dbCloseArea())
Return nTotUni
