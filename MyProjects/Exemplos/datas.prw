#INCLUDE "protheus.ch"

//------------------------------------------------------------------------------------------------------
/*{protheus.doc} Datas()
Exemplo de função em ADVPL
@author     Lucas Guimarães
@since      02/10/2026
@version    12/superior
*/
//------------------------------------------------------------------------------------------------------

User Function Datas()
    Local dDataAtual := Date()
    //Local cHora := Time()
    Local cData := ""
    //Local nDiasAcres := 0
    Local dDataRes := SToD("")
    Local nResp := 0
    //Local cResp := ""

    //Converte uma data para testo no fomato DD/MM/AAAA
    cData := DToC(dDataAtual)

    //Converte um texto no formato data
    dDataRes := CToD("31/12/2004")

    //Converte uma data para texto no formado AAAAMMDD -> Formato das tabelas do protheus
    cData := DToS("20230819")

    //Retornar uma data sem considerar final de semana e feriado - Apenas exec o protheus
    dDataRes := DataValida(CToD("20/12/2026"), .T.) //Prox dia util
    dDataRes := DataValida(CToD("20/12/2026"), .F.) //Dia útil anterior

    //Retorna dia Day() mes Month() Ano Year()
    //MesExtenso() AnoMes() AAAAMM
    //MesDia() MMDD
    //Day2Str string com dia DD -> mesmo para mes e ano

    //Adicionar ou remover dias na data
    //DaySum() ou DaySub() -> mesmo para mes e ano

    //Diferença de dias, mes e ano
    //DateDiffDay(CToD("01/02/2026"), Date())

    //Retorna o numero de dia da semana
    nResp := Dow(dDataAtual)

    //Desc do dia da semana
    nResp := DiaSemana(dDataAtual)

    //Primeiro dia do mes ou ultima do mes seguinte
    FirstDate()
    LastDate()

    //Ultimo dia do mes
    Last_Day()

    //Primeiro dia do ano ou ultimo
    FirstYDate()
    LastYDate()

Return
