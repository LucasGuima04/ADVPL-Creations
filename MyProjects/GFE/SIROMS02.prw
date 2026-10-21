#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

user function TSOMS02()
	//rpcSetType(3)
	//rpcClearEnv()
	//rpcSetEnv("01" ,"0101")

	u_SIROMS02()
return

user function SIROMS02(cCagarDe, cCargaAte)
	local lBold		     := .t.
	local lNotBold	     := .f.
	local lSublinhado    := .t.
	local lNotSublinhado := .f.
	local cAlias		 := getConsulta(cCagarDe, cCargaAte)

	private o10Arial   := tFont():New("Arial"	,,10,,lNotBold	,,,,,lNotSublinhado)
	private o10BArial  := tFont():New("Arial"	,,10,,lBold		,,,,,lNotSublinhado)
	private o10BSArial := tFont():New("Arial"	,,12,,lBold		,,,,,lSublinhado)
	private o12Arial   := tFont():New("Arial"	,,12,,lNotBold	,,,,,lNotSublinhado)
	private o12BArial  := tFont():New("Arial"	,,12,,lBold		,,,,,lNotSublinhado)
	private o14BArial  := tFont():New("Arial"	,,14,,lBold		,,,,,lNotSublinhado)
	private o14Arial   := tFont():New("Arial"	,,14,,lNotBold	,,,,,lNotSublinhado)
	private o18BArial  := tFont():New("Arial"	,,18,,lBold		,,,,,lNotSublinhado)
	
	private nPagRod := 1  

	oRel:StartPage()
		impCabec(cAlias)
		impNota(cAlias)
	oRel:EndPage()
return

static function impCabec(cAlias)
	local nLinha	:= 0
	local nColum1	:= 0
	local nColum2	:= 0
	local cTransp	:= (cAlias)->DAK_TRANSP
	local cRomaneio	:= (cAlias)->DAK_COD
	local cCGC		:= (cAlias)->A4_CGC
	local cCodMun	:= (cAlias)->A4_COD_MUN
	local cNomeTra  := (cAlias)->A4_NOME

	oRel:IPline(nLinha + 0.3 ,nColum1 + 0.5 ,nLinha + 0.3 ,nColum2 + 0.5 ,,,.t.)

	oRel:IPSay(nLinha + 0.5 ,nColum1 + 0.5 ,"ALCOOL SAFRA" ,o18BArial ,,.t.)
	oRel:IPSay(nLinha - 0.5 ,nColum1 + 12 ,"Número Página 0" + cValToChar(nPagRod) ,o18BArial ,,.t.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 0.5 ,"Relatório de Entregas" ,o14BArial ,,.f.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 12 ,"Romaneio nº "+cRomaneio ,o14BArial ,,.t.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 0.5 ,"Transportador: "+cTransp + " " + cNomeTra ,o12BArial ,,.t.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 0.5 ,"CNPJ/CPF: " +cCGC ,o12BArial ,,.f.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 12 ,"Insc. Est. / RG: "+cCodMun ,o12BArial ,,.t.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 0.5 ,"Veiculo:_______________________________" ,o12BArial ,,.f.)
	oRel:IPSay(nLinha + 0.5 ,nColum1 + 12 ,"Assinatura:_______________________________" ,o12BArial ,,.t.)
return

static function impNota(cAlias)
	local nLinha	:= 0
	local nColum1	:= 0
	local nColum2	:= 0
	local cDesc		:= ""
	local nQtd		:= 25
	local aDesc		:= {}
	local cNota		:= ""
	local cCidade	:= ""
	local cPeso		:= ""
	local nQtdItem  := 0

	oRel:IPSay(nLinha + 0.7, nColum1 + 0.5, "Nota", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.7, nColum1 + 3, "Cliente", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.7, nColum1 + 8.5, "Cidade", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 13.5, "Hora de", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.9, nColum1 + 13.5, "Chegada", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.5, nColum1 + 15.5, "Hora de", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.9, nColum1 + 15.5, "Saída", o12BArial,, .f.)
	oRel:IPSay(nLinha + 0.7, nColum1 + 17.5, "Peso Bruto", o12BArial,, .f.)
	oRel:IPline(nLinha + 1.4 ,nColum1 + 0.5 ,nLinha + 1.4 ,nColum2 + 20 ,,,.t.)

	while (cAlias)->(!eof())
		cDesc	:= alltrim((cAlias)->A1_NOME)
		aDesc	:= charToImp(cDesc ,nQtd)
		cNota	:= (cAlias)->DAI_NFISCA
		cCidade	:= (cAlias)->A1_MUN
		//cPeso	:= (cAlias)->DAK_PESO
		cPeso	:= (cAlias)->F2_PBRUTO

		cPeso	:= transform(cPeso, "@E 999,999.99")

		oRel:IPSay(nLinha + 0.2, nColum1 + 0.5, cNota, o10Arial,, .f.)
		oRel:IPSay(nLinha + 0.2, nColum1 + 3, aDesc[1], o10Arial,, .f.)
		oRel:IPSay(nLinha + 0.2, nColum1 + 8.5, cCidade, o10Arial,, .f.)
		oRel:IPSay(nLinha + 0.2, nColum1 + 13.5, "____:____", o10Arial,, .f.)
		oRel:IPSay(nLinha + 0.2, nColum1 + 15.5, "____:____", o10Arial,, .f.)
		oRel:IPSay(nLinha + 0.2, nColum1 + 17.5, cPeso, o10Arial,, .f.)
		oRel:IPline(nLinha + 0.7 ,nColum1 + 0.5 ,nLinha + 0.7 ,nColum2 + 20 ,,,.t.)
		
		nQtdItem++
		
		if nQtdItem >= 33
			nPagRod++
			nQtdItem := 0
			nLinha   := 0
			oRel:EndPage()
			oRel:StartPage()
			impCabec(cAlias)			
		endif

		(cAlias)->(dbSkip())
	enddo
return

/*
Converte string em array considerando o limite de caracteres recebido no parametro nQtdChar, a quebra é realizada sem cortar as palavras
Autor: Tiago Faria
Data: 06/08/2018
*/
static function charToImp(cString, nQtdChar)
	local aRet 			:= {}
	local nLine 		:= 0
	local nCount 		:= MlCount(cString, nQtdChar)

	if nCount == 0
		aRet := {""}
	else
		for nLine := 1 to nCount
			aadd(aRet, MemoLine(cString, nQtdChar, nLine))
		next nLine
	endif
return aRet

static function getConsulta(cCagarDe, cCargaAte)
	local cQuery	:= ""
	local cAlias	:= getNextAlias()

	cQuery := "SELECT" + CRLF
	cQuery += "		DAK_COD," + CRLF
	cQuery += "		DAK_TRANSP," + CRLF
	cQuery += "		DAK_PESO," + CRLF
	cQuery += "		DAI_NFISCA," + CRLF
	cQuery += "		A1_NOME," + CRLF
	cQuery += "		A4_CGC," + CRLF
	cQuery += "		A4_COD_MUN," + CRLF
	cQuery += "		A4_NOME," + CRLF
	cQuery += "		A1_MUN," + CRLF
	cQuery += "		F2_PBRUTO" + CRLF

	cQuery += "FROM"+RetSqlTab("DAK")+""+ CRLF

	cQuery += "INNER JOIN"+RetSqlTab("DAI")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("DAI")+"" + CRLF
	cQuery += " 	AND DAI_COD = DAK_COD" + CRLF
	cQuery += " 	AND"+RetSqlDel("DAI")+"" + CRLF

	cQuery += "INNER JOIN"+RetSqlTab("SA1")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("SA1")+"" + CRLF
	cQuery += " 	AND A1_COD = DAI_CLIENT" + CRLF
	cQuery += "     AND A1_LOJA = DAI_LOJA" + CRLF
	cQuery += " 	AND"+RetSqlDel("SA1")+"" + CRLF

	cQuery += "INNER JOIN"+RetSqlTab("SC5")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("SC5")+"" + CRLF
	cQuery += " 	AND C5_NUM = DAI_PEDIDO" + CRLF
	cQuery += " 	AND C5_LOJACLI = DAI_LOJA" + CRLF
	cQuery += " 	AND"+RetSqlDel("SC5")+"" + CRLF
	
	cQuery += "INNER JOIN" + RetSqlTab("SF2") + " ON F2_DOC = C5_NOTA " + CRLF 
	cQuery += " 	AND F2_SERIE = C5_SERIE "+ CRLF
	cQuery += " 	AND F2_CLIENTE = C5_CLIENTE "+ CRLF
	cQuery += " 	AND F2_LOJA = C5_LOJACLI "+ CRLF
	cQuery += " 	AND SF2.D_E_L_E_T_ = ' '"+ CRLF

	cQuery += "INNER JOIN"+RetSqlTab("SC6")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("SC6")+"" + CRLF
	cQuery += " 	AND C6_NUM = C5_NUM" + CRLF
	cQuery += " 	AND C6_LOJA = C5_LOJACLI" + CRLF
	cQuery += " 	AND"+RetSqlDel("SC6")+"" + CRLF

	cQuery += "INNER JOIN"+RetSqlTab("SB1")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("SB1")+"" + CRLF
	cQuery += " 	AND B1_COD = C6_PRODUTO" + CRLF
	cQuery += " 	AND"+RetSqlDel("SB1")+"" + CRLF

	cQuery += "INNER JOIN"+RetSqlTab("SA4")+"ON 1 = 1"+ CRLF
	cQuery += " 	AND "+RetSqlFil("SA4")+"" + CRLF
	cQuery += " 	AND A4_COD = DAK_TRANSP" + CRLF
	cQuery += " 	AND"+RetSqlDel("SA4")+"" + CRLF

	cQuery += " WHERE 1 = 1" + CRLF
	cQuery += " 	AND "+RetSqlFil("DAK")+"" + CRLF
	cQuery += " 	AND DAK_COD = '"+cCagarDe+"'" + CRLF
	cQuery += " 	AND "+RetSqlDel("DAK")+"" + CRLF

	cQuery += "GROUP BY" + CRLF
	cQuery += "		DAK_COD," + CRLF
	cQuery += "		DAK_TRANSP," + CRLF
	cQuery += "		DAK_PESO," + CRLF
	cQuery += "		DAI_NFISCA," + CRLF
	cQuery += "		A1_NOME," + CRLF
	cQuery += "		A4_CGC," + CRLF
	cQuery += "		A4_COD_MUN," + CRLF
	cQuery += "		A1_MUN," + CRLF
	cQuery += "		A4_NOME," + CRLF
	cQuery += "		F2_PBRUTO" + CRLF

	tcQuery cQuery new alias &cAlias
return cAlias