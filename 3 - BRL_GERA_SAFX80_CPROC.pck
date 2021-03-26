CREATE OR REPLACE PACKAGE BRL_GERA_SAFX80_CPROC IS

   -- Autor   : Andreia Ferreira
   -- Created : 05/2019
   -- Purpose : Gerar SAFX80 apartir dos Lancamentos Contabeis e Saldos Contabeis

   mCod_empresa ESTABELECIMENTO.COD_EMPRESA%TYPE;

   /* VARIAVEIS DE CONTROLE DE CABECALHO DE RELATORIO */

   FUNCTION Parametros RETURN VARCHAR2;
   FUNCTION Nome RETURN VARCHAR2;
   FUNCTION Tipo RETURN VARCHAR2;
   FUNCTION Versao RETURN VARCHAR2;
   FUNCTION Descricao RETURN VARCHAR2;
   FUNCTION Modulo RETURN VARCHAR2;
   FUNCTION Classificacao RETURN VARCHAR2;
   FUNCTION Orientacao RETURN VARCHAR2;

   FUNCTION Executar ( PDATA_INI  DATE,
                       PDATA_FIM  DATE
                       )
   RETURN INTEGER;

END BRL_GERA_SAFX80_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_GERA_SAFX80_CPROC IS

   -- Autor   : Andreia Ferreira
   -- Created : 05/2019
   -- Purpose : Gerar SAFX80 apartir dos Lancamentos Contabeis e Saldos Contabeis

    mproc_id  INTEGER;

    -----------------------------------------------------------------------------------------------
-- variaveis da importac?o automatica...
  PAR_COD_EMPRESA_W   VARCHAR2(3);
  PAR_COD_PROG_W      NUMBER;
  PAR_DATA_PROC_W     DATE;
  PAR_IND_GRAVA_W     VARCHAR(1);
  PAR_IND_DATA_W      VARCHAR(1);
  PAR_GRAVA_LOG_W     VARCHAR(1);
  PAR_DSC_DIRETORIO_W VARCHAR2(500);
  PAR_MENS_ERR        VARCHAR2(500);


    FUNCTION Parametros RETURN VARCHAR2
    IS
      pstr     VARCHAR2(5000);
      w_razao  EMPRESA.RAZAO_SOCIAL%type;
    BEGIN

      mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');

      SELECT RAZAO_SOCIAL
        INTO W_RAZAO
        FROM EMPRESA
       WHERE COD_EMPRESA = mcod_empresa;

      Lib_Proc.Add_Param ( pparam => pstr
                         , ptitulo =>  lpad(' ', 44, ' ') || 'Empresa :   ' || mcod_empresa || ' - ' || w_razao
                         , ptipo => 'varchar2'
                         , pcontrole => 'text'
                         , pmandatorio => 'N' );


      Lib_Proc.Add_Param ( pparam => pstr
                         , ptitulo => 'Periodo Inicial '
                         , ptipo => 'date'
                         , pcontrole => 'Textbox'
                         , pmandatorio => 'S'
                         , pmascara => 'DD/MM/YYYY' );

      Lib_Proc.Add_Param ( pparam => pstr
                         , ptitulo => 'Periodo Final '
                         , ptipo => 'date'
                         , pcontrole => 'Textbox'
                         , pmandatorio => 'S'
                         , pmascara => 'DD/MM/YYYY' );


      RETURN pstr;

    END;

    FUNCTION Nome RETURN VARCHAR2 IS
    BEGIN
      RETURN 'ECD - Gerac?o dos Saldos por Centro de Custo - SAFX80';
    END;

    FUNCTION Tipo RETURN VARCHAR2 IS
    BEGIN
      RETURN 'Contabilidade';
    END;

    FUNCTION Versao RETURN VARCHAR2 IS
    BEGIN
      RETURN '1.0';
    END;

    FUNCTION Descricao RETURN VARCHAR2 IS
    BEGIN
      RETURN 'ECD - Gerac?o dos Saldos por Centro de Custo - SAFX80';
    END;

    FUNCTION Modulo RETURN VARCHAR2 IS
    BEGIN
      RETURN 'Processos Customizados';
    END;

    FUNCTION Classificacao RETURN VARCHAR2 IS
    BEGIN
      RETURN 'Contabilidade';
    END;

    FUNCTION Orientacao RETURN VARCHAR2 IS
    BEGIN
      RETURN 'LANDSCAPE';
    END;

    PROCEDURE INSERE_SAFX80( p_origem        in varchar2,
                             p_cod_empresa   in varchar2,
                             p_cod_estab     in varchar2,
                             p_cod_conta     in varchar2,
                             p_cod_custo     in varchar2,
                             p_data_saldo    in date,
                             p_vlr_saldo_ini in number,
                             p_ind_saldo_ini in varchar2,
                             p_vlr_saldo_fim in number,
                             p_ind_saldo_fim in char,
                             p_vlr_tot_cre   in number,
                             p_vlr_tot_deb   in number )
    is
    begin

     INSERT INTO BRL_GERA_SAFX80T_TMP_CPROC
                            (cod_empresa                      , -- 01
                             cod_estab                        , -- 02
                             cod_conta                        , -- 03
                             cod_custo                        , -- 04
                             dat_saldo                        , -- 05
                             vlr_saldo_cont_ant               , -- 06
                             ind_deb_cred_ant                 , -- 07
                             vlr_saldo_cont_atu               , -- 08
                             ind_deb_cred_atu                 , -- 09
                             vlr_tot_cred                     , -- 10
                             vlr_tot_deb                      , -- 11
                             cod_sistema_orig                   -- 12
                             )
                          values
                            (p_cod_empresa                                            , -- 01
                             p_cod_estab                                              , -- 02
                             p_cod_conta                                              , -- 03
                             p_cod_custo                                              , -- 04
                             TO_CHAR(TO_DATE(p_data_saldo, 'DD/MM/RRRR'), 'RRRRMMDD') , -- 05
                             ROUND(p_vlr_saldo_ini,2)                                 , -- 06
                             p_ind_saldo_ini                                          , -- 07
                             ROUND(p_vlr_saldo_fim,2)                                 , -- 08
                             p_ind_saldo_fim                                          , -- 09
                             ROUND(p_vlr_tot_cre,2)                                   , -- 10
                             ROUND(p_vlr_tot_deb,2)                                   , -- 11
                             p_origem                                                   -- 12
                             );

    exception when others then
      Lib_Proc.Add_Log ( plog => ' Ocorreu um erro ao executar o processo (' || Nome || ')' || CHR(13) || CHR(10) ||
                                 ' Favor entrar em contato com a equipe tZcnica informando a descri??o do erro abaixo. ' || CHR(13) || CHR(10) ||
                                 ' Descri??o do erro: '|| SQLERRM(SQLCODE) || CHR(13) || CHR(10) || dbms_utility.format_error_backtrace
                       , pnivel => 1);
    end INSERE_SAFX80;


   FUNCTION Executar ( PDATA_INI  DATE,
                       PDATA_FIM  DATE
                       )
   RETURN INTEGER
   IS


     vs_cod_custo       SAFX2003.COD_CUSTO%TYPE;
     vs_custo           SAFX2003.COD_CUSTO%TYPE;
     vs_conta           SAFX2002.COD_CONTA%TYPE;

     vs_ind_saldo_ini   VARchar(1);
     vs_ind_saldo_fim   VARchar(1);
     vn_saldo_ini       number:=0;
     vn_saldo_fim       number:=0;
     vn_inserts         pls_integer :=0;
     vn_count           pls_integer :=0;

    IDENT_CUSTO_W       X01_CONTABIL.IDENT_CUSTO%TYPE;

   BEGIN

     -- Cria Processo Inicial
     mproc_id := Lib_Proc.New ( psp_nome => 'BRL_GERA_SAFX80_CPROC' );

     -- Nome do arquivo
     Lib_Proc.Add_Tipo ( pproc_id =>  mproc_id
                       , ptipo => 1
                       , ptitulo => 'SAFX80'
                       , ptipo_arq => 1 );


     mcod_empresa := LIB_Parametros.Recuperar ( pNome => 'EMPRESA' );

     -- Deleta os registros na tabela temporaria, para nao haver divergencia nos calculos
     EXECUTE IMMEDIATE 'TRUNCATE TABLE BRL_GERA_SAFX80_TMP';

     IF TO_CHAR( TO_DATE( PDATA_INI, 'dd/mm/rrrr' ), 'dd/mm' ) <> '01/01' THEN
         Lib_Proc.Add_Log ( plog => ' O per?odo inicial informado esta incorreto, sempre deve ser informado 01/JAN'
                          , pnivel => 1);
     END IF;

     -- definindo o centro de custo
    if mcod_empresa = '001' then -- valeant
     vs_cod_custo := 'WWCOBR11_0000';
    else
     vs_cod_custo := 'BRCABR14_0000'; -- bausch
    end if;
    
    -- colocando centro de custo unico nos lancamnentos que nao tem centro de custo.
    -- tambem coloca centro de custo unico nos lancamentos que a conta contabil seja de Balanco


    SELECT IDENT_CUSTO
      INTO IDENT_CUSTO_W
            FROM   X2003_CENTRO_CUSTO
            WHERE  VALID_CUSTO  =
                   (SELECT MAX(VALID_CUSTO)
                    FROM   X2003_CENTRO_CUSTO
                    WHERE  VALID_CUSTO <= PDATA_INI
                    AND    COD_CUSTO    = vs_cod_custo
                    AND    GRUPO_CUSTO  in (select grupo_estab
                                              from RELAC_TAB_GRUPO
                                             where cod_tabela = '2003' and
                                                   cod_empresa = mcod_empresa and
                                                   valid_inicial <= PDATA_INI and
                                                   cod_estab = (select cod_estab
                                                                  from estabelecimento
                                                                 where cod_empresa = mcod_empresa and
                                                                       ind_matriz_filial = 'M' )))
            AND    COD_CUSTO   = vs_cod_custo;

    update x01_contabil set ident_custo = IDENT_CUSTO_W
    where ident_custo is null
    and data_lancto between PDATA_INI and PDATA_FIM
    and cod_empresa = mcod_empresa;

    update x01_contabil set ident_custo = IDENT_CUSTO_W
    where ident_conta in (select ident_Conta
                            from x2002_plano_Contas
                           where ind_natureza  in ('1', '2', '7'))
    and data_lancto between PDATA_INI and PDATA_FIM
    and cod_empresa = mcod_empresa;

    -- DELETE DA SAFX80 PARA QUE NAO TENHA NENHUM REGISTRO PARA ESTA EMPRESA NA TABELA TEMPORARIA

    DELETE SAFX80 WHERE COD_eMPRESA = mcod_empresa;

    commit;



     -- Realizaca a insercao dos dados contidos nos Saldos Contabeis
     for xSal in ( select x02.cod_empresa
                        , x02.cod_estab
                        , x02.data_saldo
                        , x02.vlr_saldo_ini, x02.ind_saldo_ini
                        , x02.vlr_saldo_fim, x02.ind_saldo_fim
                        , x02.vlr_tot_cre
                        , x02.vlr_tot_deb
                        , x2002.cod_conta
                     from X02_SALDOS x02
                        , x2002_plano_contas x2002
                    where 1=1
                      and x02.ident_conta = x2002.ident_conta
                      and x2002.ind_natureza in ( '1', '2', '7' )
                      and x02.cod_empresa = mcod_empresa
                      and x02.data_saldo between PDATA_INI and PDATA_FIM
                      order by x02.data_saldo asc )
     loop

          INSERE_SAFX80( 'X02'
                        , xSal.cod_empresa
                        , xSal.cod_estab
                        , xSal.COD_CONTA
                        , vs_cod_custo
                        , xSal.Data_Saldo
                        , xSal.Vlr_Saldo_Ini
                        , xSal.Ind_Saldo_Ini
                        , xSal.Vlr_Saldo_Fim
                        , xSal.Ind_Saldo_Fim
                        , xSal.Vlr_Tot_Cre
                        , xSal.Vlr_Tot_Deb
                        );

     end loop;



     FOR xCur IN ( SELECT X01.COD_EMPRESA
                        , X01.COD_ESTAB
                        , SUM(DECODE( X01.IND_DEB_CRE, 'D', NVL(X01.VLR_LANCTO,0), 0 )) AS DEBITO
                        , SUM(DECODE( X01.IND_DEB_CRE, 'C', NVL(X01.VLR_LANCTO,0), 0 )) AS CREDITO
                        , X2003.COD_CUSTO
                        , X2002.COD_CONTA
                        , LAST_DAY(x01.data_lancto) PERIODO
                     FROM X01_CONTABIL        X01
                        , X2002_PLANO_CONTAS  X2002
                        , X2003_CENTRO_CUSTO  X2003
                    WHERE 1=1
                      AND X01.COD_EMPRESA = mcod_empresa
                      AND X01.DATA_LANCTO between PDATA_INI and PDATA_FIM
                      AND X2002.IND_NATUREZA NOT IN ( '1', '2', '7' )
                      AND X01.IDENT_CONTA = X2002.IDENT_CONTA
                      AND X01.IDENT_CUSTO = X2003.IDENT_CUSTO
                    GROUP BY X01.COD_EMPRESA
                           , X01.COD_ESTAB
                           , x2003.COD_CUSTO
                           , X2002.COD_CONTA
                           , LAST_DAY(x01.data_lancto)
                    order by LAST_DAY(x01.data_lancto

                    ) asc
               )
     LOOP

         INSERE_SAFX80( 'X01'
                      , xCur.COD_EMPRESA
                      , xCur.COD_ESTAB
                      , xCur.COD_CONTA
                      , xCur.COD_CUSTO
                      , xCur.Periodo
                      , 0
                      , 'D'
                      , 0
                      , 'D'
                      , xCur.CREDITO
                      , xCur.DEBITO
                      );

        
     end loop;
     commit;

     ------ Insere registros com saldos porem sem lancamentos para o periodo
     for LancZ in (
        select cod_empresa, cod_estab, cod_conta, cod_custo, periodo
        from (
              select f.cod_empresa, f.cod_estab, f.cod_conta, cod_custo, r.periodo
                from
                   ( select distinct cod_empresa, cod_estab, cod_conta, cod_custo
                       from BRL_GERA_SAFX80T_TMP_CPROC) f,
                   ( select last_day(to_char(add_months(to_date(PDATA_INI , 'DD/MM/RRRR'), ind.l-1), 'dd/mm/rrrr')) as periodo
                          from dual descr,
                               (select l
                                  from (select level l
                                          from dual
                                        connect by level <= ( to_number(to_char(to_date(PDATA_FIM,'dd/mm/rrrr'), 'mm')) - to_number(to_char(to_date(PDATA_INI,'dd/mm/rrrr'), 'mm')) )+1
                                       )
                               ) ind ) r
              where 1=1 ) pp
       where 1=1
         and not exists ( select 1
                            from BRL_GERA_SAFX80T_TMP_CPROC tp
                           where 1=1
                             and tp.cod_conta = pp.cod_conta
                             and tp.cod_custo = pp.cod_custo
                             and tp.cod_estab = pp.cod_Estab
                             and tp.cod_empresa = pp.cod_empresa
                             and to_date(tp.dat_saldo, 'rrrrmmdd') = to_date(pp.periodo, 'dd/mm/rrrr') ) )

     loop

           INSERE_SAFX80( 'X03'
                        , LancZ.COD_EMPRESA
                        , LancZ.COD_ESTAB
                        , LancZ.COD_CONTA
                        , LancZ.COD_CUSTO
                        , LancZ.Periodo
                        , 0
                        , 'D'
                        , 0
                        , 'D'
                        , 0
                        , 0
                        );

     end loop;

     commit;

     --- RECALCULA VALORES DOS SALDOS INICIAIS E FINAIS
     vn_count := 0;
     vs_conta := null;
     vs_custo := null;

     for xCur in ( select *
                     from BRL_GERA_SAFX80T_TMP_CPROC d
                    where 1=1
                    order by cod_conta asc
                           , cod_custo asc
                           , dat_saldo asc )
     loop

       vn_count := vn_count + 1;

       if vs_conta <> xCur.cod_conta
           or vs_custo <> xCur.cod_custo
           or vn_count = 1
       then
          vn_saldo_fim := 0;
          vs_ind_saldo_fim := 'D';
          vn_saldo_ini := 0;
          vs_ind_saldo_ini := 'D';
       end if;

       if substr( xCur.dat_saldo, -4 ) = '0131' then
          if xCur.cod_sistema_orig = 'X01' then
             vn_saldo_fim := 0;
             vs_ind_saldo_fim := 'D';
          else
             vn_saldo_fim := xCur.vlr_saldo_cont_ant;
             vs_ind_saldo_fim := xCur.ind_deb_cred_ant;
          end if;
       end if;

       vn_saldo_ini := vn_saldo_fim;
       vs_ind_saldo_ini := vs_ind_saldo_fim;

       if xCur.Vlr_Tot_Deb >= xCur.Vlr_Tot_Cred then
           vn_saldo_fim := xCur.Vlr_Tot_Deb - xCur.Vlr_Tot_Cred;
           vs_ind_saldo_fim := 'D';
       else
           vn_saldo_fim := xCur.Vlr_Tot_Cred - xCur.Vlr_Tot_Deb;
           vs_ind_saldo_fim := 'C';
       end if;


       IF vs_ind_saldo_ini = vs_ind_saldo_fim then
           vn_saldo_fim := vn_saldo_fim + vn_saldo_ini;
       else
           if vn_saldo_fim > vn_saldo_ini then
              vn_saldo_fim := vn_saldo_fim - vn_saldo_ini;
           else
              vn_saldo_fim := vn_saldo_ini - vn_saldo_fim;
              vs_ind_saldo_fim := vs_ind_saldo_ini;
           end if;
       end if;


       update BRL_GERA_SAFX80T_TMP_CPROC cc
          set cc.vlr_saldo_cont_atu = vn_saldo_Fim
            , cc.ind_deb_cred_atu = vs_ind_saldo_fim
            , cc.vlr_saldo_cont_ant = vn_saldo_ini
            , cc.ind_deb_cred_ant = vs_ind_saldo_ini
        where 1=1
          and cc.cod_empresa = xCur.Cod_Empresa
          and cc.cod_estab = xCur.cod_estab
          and cc.dat_saldo = xCur.dat_saldo
          and cc.cod_conta = xCur.cod_conta
          and cc.cod_custo = xCur.Cod_Custo;


       vs_conta := xCur.cod_conta;
       vs_custo := xCur.cod_custo;

     END LOOP;

     commit;


     -- Insere os registros na tabela tempor?ria SAFX80 a partir da tabela de c?lculos.

     INSERT INTO SAFX80( cod_empresa                      , -- 01
                         cod_estab                        , -- 02
                         cod_conta                        , -- 03
                         cod_custo                        , -- 04
                         dat_saldo                        , -- 05
                         vlr_saldo_cont_ant               , -- 06
                         ind_deb_cred_ant                 , -- 07
                         vlr_saldo_cont_atu               , -- 08
                         ind_deb_cred_atu                 , -- 09
                         vlr_tot_cred                     , -- 10
                         vlr_tot_deb                      , -- 11
                         cod_sistema_orig                 ) -- 12
                  select cod_empresa                      , -- 01
                         cod_estab                        , -- 02
                         cod_conta                        , -- 03
                         cod_custo                        , -- 04
                         dat_saldo                        , -- 05
                         lpad((round(vlr_saldo_cont_ant,2)*100), 17, '0' )  , -- 06
                         ind_deb_cred_ant                                   , -- 07
                         lpad((round(vlr_saldo_cont_atu,2)*100), 17, '0' )  , -- 08
                         ind_deb_cred_atu                                   , -- 09
                         lpad((round(vlr_tot_cred,2)*100), 17, '0' )        , -- 10
                         lpad((round(vlr_tot_deb,2)*100), 17, '0' )         , -- 11
                         cod_sistema_orig                                     -- 12
                    from BRL_GERA_SAFX80T_TMP_CPROC
                   where 1=1;

     commit;

     select count(*)
       into vn_inserts
       from BRL_GERA_SAFX80T_TMP_CPROC;


     LIB_PROC.add ( 'Empresa: ' || mcod_empresa );
     LIB_PROC.add ( 'Inserido ' || vn_inserts || ' registros para a SAFX80' );

-- chama a importac?o automatica para importar esta safx80
-- IMPORTACAO AUTOMATICA

/*      PAR_COD_EMPRESA_W   := mcod_empresa;
      PAR_COD_PROG_W      := 3; -- Codigo da programacao feita no MasterSAF para importacao da safx80
      PAR_DATA_PROC_W     := pDt_fim;
      PAR_IND_GRAVA_W     := 'S'; -- Para manter o erro na SAFX, passar 'S'
      PAR_IND_DATA_W      := 'N';
      PAR_GRAVA_LOG_W     := 'N';
      PAR_DSC_DIRETORIO_W := NULL;

      SAF_IMPORTA_BAT(PAR_COD_EMPRESA_W,
                      PAR_COD_PROG_W,
                      PAR_DATA_PROC_W,
                      PAR_IND_GRAVA_W,
                      PAR_IND_DATA_W,
                      PAR_GRAVA_LOG_W,
                      PAR_DSC_DIRETORIO_W,
                      PAR_MENS_ERR);
*/


     Lib_Proc.CLOSE();

     RETURN mproc_id;

   Exception When Others Then

      Lib_Proc.Add_Log ( plog => ' Ocorreu um erro ao executar o processo (' || Nome || ')' || CHR(13) || CHR(10) ||
                                 ' Favor entrar em contato com a equipe tZcnica informando a descri??o do erro abaixo. ' || CHR(13) || CHR(10) ||
                                 ' Descri??o do erro: '|| SQLERRM(SQLCODE) || CHR(13) || CHR(10) || dbms_utility.format_error_backtrace
                       , pnivel => 1);
      Lib_Proc.CLOSE();
      RETURN mproc_id;

   END Executar;

END BRL_GERA_SAFX80_CPROC;
/
