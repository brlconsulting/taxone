create or replace PACKAGE BRL_GE_PC_CALCULO_X02_CPROC IS

  -- Autor   : BRL CONSULTORES
  -- Created : 29/07/2009 - Nome Original MSAF_GE_PC_CALCULO_X02_CPROC
  -- Migrado para TAXONE em 03/2022
  -- Purpose : Calculo do Saldo da X02

  /* Declaração de Variáveis Públicas */
  cgc_estab_p                estabelecimento.cgc%TYPE;
  w_cod_emp                   estabelecimento.cod_empresa%type;
  w_cod_estab                estabelecimento.cod_estab%type;
  w_razao                    estabelecimento.razao_social%type;


  USUARIO_P     VARCHAR2(20);

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */

  FUNCTION Parametros      RETURN VARCHAR2;
  FUNCTION Nome            RETURN VARCHAR2;
  FUNCTION Tipo            RETURN VARCHAR2;
  FUNCTION Versao          RETURN VARCHAR2;
  FUNCTION Descricao       RETURN VARCHAR2;
  FUNCTION Modulo          RETURN VARCHAR2;
  FUNCTION Classificacao   RETURN VARCHAR2;
  FUNCTION Executar(PCod_Estab     varchar2,
                    pDataIni       Date,
                    pDataFim       Date) return INTEGER;

      Procedure Cabecalho (p_cgc          varchar2,
                           p_razao_social varchar2,
                           p_dat_ini    DATE,
                           p_dat_fim    DATE,
                           p_pagina     varchar2);


END BRL_GE_PC_CALCULO_X02_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_GE_PC_CALCULO_X02_CPROC IS
  --variáveis de status

  mcod_estab   estabelecimento.cod_estab%TYPE;
  mcod_empresa empresa.cod_empresa%TYPE;
  mcod_usuario usuario_estab.cod_usuario%TYPE;

  mLinha varchar2(4000);

  vi_ident_conta integer;
  vn_vlr_debito  number;
  vn_vlr_credito number;

  vn_vlr_saldo_ini number;
  vc_ind_saldo_ini char;

  vn_vlr_saldo_fim number;
  vc_ind_saldo_fim char;

  V_ESTAB        varchar2(20);
  V_CGC          varchar2(20);
  V_RAZAO_SOCIAL varchar2(100);

  v_linha number(20) := 0;
  v_folha number(6) := 1;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN
  
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
    mcod_usuario := LIB_PARAMETROS.Recuperar('Usuario');
  
    LIB_PROC.add_param(pstr,
                       'Estabelecimento',
                       'Varchar2',
                       'Combobox',
                       'S',
                       null,
                       NULL,
                       'SELECT DISTINCT cod_estab, cod_estab||'' - ''||razao_social ' ||
                       'FROM estabelecimento WHERE COD_EMPRESA = ''' ||
                       mcod_empresa || ''' and cod_estab = nvl(''' ||
                       mcod_estab || ''', cod_estab) ORDER BY 1');
    LIB_PROC.add_param(pstr,
                       'Data Inicial',
                       'Date',
                       'textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');
    LIB_PROC.add_param(pstr,
                       'Data Final',
                       'Date',
                       'textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');
  
    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Calculo de Saldos Contábeis - X02_SALDOS';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Calculo de Saldos Contábeis';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Calculo de Saldos Contábeis - X02_SALDOS';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Customizados';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Customizados';
  END;

  FUNCTION orientacao RETURN VARCHAR2 IS
  BEGIN
    /* Orientação do Papel. */
    RETURN 'LANDSCAPE';
  END;

  FUNCTION Executar(PCod_Estab varchar2, pDataIni Date, PDataFim Date)
    return INTEGER is
  
    /* Variaveis de Trabalho */
    mproc_id INTEGER;
    mLinha   VARCHAR2(160);
  
  BEGIN
    -- Cria Processo / Procedure
  
    DECLARE
    
      -- Inicio Cursor de Contas
      cursor cur_contas(ccd_estab varchar2, pdataini date) is
      
        select ident_conta, cod_conta, descricao
          from x2002_plano_contas x2002
         where ind_situacao = 'A'
           and x2002.valid_conta <= pdataini
              --       and    x2002.valid_conta  = (SELECT
              --            MAX(VALID_CONTA)
              --        FROM
              --            X2002_PLANO_CONTAS
              --        WHERE
              --            IDENT_CONTA IN (
              --                SELECT
              --                    X01.IDENT_CONTA
              --                FROM
              --                    X01_CONTABIL X01
              --                WHERE
              --                    X01.COD_EMPRESA = mcod_empresa
              --                    AND X01.COD_ESTAB = ccd_estab
              --                    AND X01.DATA_LANCTO BETWEEN  pdataini and pdatafim
              --        ))
           and x2002.grupo_conta =
               (select a.grupo_estab
                  from relac_tab_grupo a
                 where a.cod_tabela = '2002'
                   and a.cod_empresa = mcod_empresa
                   and a.cod_estab = ccd_estab
                   and a.valid_inicial in
                       (select max(valid_inicial)
                          from relac_tab_grupo
                         where cod_tabela = '2002'
                           and cod_empresa = mcod_empresa
                           and cod_estab = ccd_estab))
         order by x2002.cod_conta;
    
    BEGIN
      -- Cria Processo / Procedure
      mproc_id := LIB_PROC.new('MSAF_GE_HC_CALCULO_X02_CPROC', 47, 160);
    
      LIB_PROC.add_tipo(mproc_id, 1, 'Calculo de Saldos', 1);
    
      mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
      mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
      mcod_usuario := LIB_PARAMETROS.Recuperar('Usuario');
    
      --localiza os campos para geração do cabeçalho
      BEGIN
        SELECT EST.COD_ESTAB    AS COD_ESTAB,
               EST.CGC          AS CNPJ,
               EST.RAZAO_SOCIAL AS RAZAO_SOCIAL
          INTO V_ESTAB, V_CGC, V_RAZAO_SOCIAL
          FROM ESTABELECIMENTO EST
         WHERE EST.COD_EMPRESA = mcod_empresa
           AND EST.COD_ESTAB =
               decode(PCod_Estab, 'TODOS', EST.cod_estab, PCod_Estab);
      EXCEPTION
        WHEN OTHERS THEN
          V_ESTAB        := '@';
          V_CGC          := '@';
          V_RAZAO_SOCIAL := '@';
      END;
    
      --monta o cabeçalho
      Cabecalho(v_cgc,
                v_estab || ' - ' || V_RAZAO_SOCIAL,
                pDataIni,
                pDataFim,
                v_folha);
    
      v_folha := v_folha + 1;
      v_linha := v_linha + 8;
    
      --inicia o processamento do relatório.
      FOR mreg IN cur_contas(pcod_estab, pDataIni) LOOP
      
        -- Pegar os valores de lançamentos de débito e credito de cada conta no período
        begin
          select ident_conta, sum(vlr_debito), sum(vlr_credito)
            into vi_ident_conta, vn_vlr_debito, vn_vlr_credito
            from (select x01.ident_conta,
                         0 vlr_debito,
                         sum(x01.vlr_lancto) vlr_credito
                    from x01_contabil x01
                   where x01.cod_empresa = mcod_empresa
                     and x01.cod_estab = pcod_estab
                     and x01.data_lancto between pdataini and pdatafim
                     and x01.ind_deb_cre = 'C'
                     and x01.ident_conta = mreg.ident_conta
                   group by x01.ident_conta
                  
                  union all
                  
                  select x01.ident_conta,
                         sum(x01.vlr_lancto) vlr_debito,
                         0 vlr_credito
                    from x01_contabil x01
                   where x01.cod_empresa = mcod_empresa
                     and x01.cod_estab = pcod_estab
                     and x01.data_lancto between pdataini and pdatafim
                     and x01.ind_deb_cre = 'D'
                     and x01.ident_conta = mreg.ident_conta
                   group by x01.ident_conta)
           group by ident_conta;
        exception
          when no_data_found then
            vi_ident_conta := mreg.ident_conta;
            vn_vlr_debito  := 0;
            vn_vlr_credito := 0;
        end;
      
        -- Pegar o valor de saldo do mês anterior
        begin
          select x02.vlr_saldo_fim, x02.ind_saldo_fim
            into vn_vlr_saldo_ini, vc_ind_saldo_ini
            from x02_saldos x02
           where x02.ident_conta = mreg.ident_conta
             and x02.data_saldo = (pDataIni - 1)
             and x02.cod_empresa = mcod_empresa
             and x02.cod_estab = pcod_estab;
        exception
          when no_data_found then
            vn_vlr_saldo_ini := 0;
            vc_ind_saldo_ini := 'C';
        end;
      
        -- Calcula saldo do mês
      
        if vc_ind_saldo_ini = 'C' then
          vn_vlr_saldo_fim := (vn_vlr_saldo_ini + vn_vlr_credito) -
                              (vn_vlr_debito);
          if vn_vlr_saldo_fim < 0 then
            vc_ind_saldo_fim := 'D';
          else
            vc_ind_saldo_fim := 'C';
          end if;
        else
          vn_vlr_saldo_fim := (vn_vlr_saldo_ini + vn_vlr_debito) -
                              (vn_vlr_credito);
          if vn_vlr_saldo_fim > 0 then
            vc_ind_saldo_fim := 'D';
          else
            vc_ind_saldo_fim := 'C';
          end if;
        end if;
      
        vn_vlr_saldo_fim := abs(vn_vlr_saldo_fim);
      
        -- Inserior o novo saldo.
      
        insert into safx02
          (cod_empresa,
           cod_estab,
           cod_conta, --
           data_saldo,
           vlr_saldo_ini,
           ind_saldo_ini,
           vlr_saldo_fim,
           ind_saldo_fim,
           vlr_tot_cre,
           vlr_tot_deb,
           dat_gravacao) --
        values
          (mcod_empresa,
           pcod_estab,
           mreg.cod_conta,
           to_char(PDataFim, 'yyyymmdd'),
           vn_vlr_saldo_ini,
           vc_ind_saldo_ini,
           vn_vlr_saldo_fim,
           vc_ind_saldo_fim,
           vn_vlr_credito,
           vn_vlr_debito,
           trunc(sysdate));
        /* -- BRL
        begin
        insert into x02_saldos (cod_empresa,
                                cod_estab,
                                ident_conta,
                                data_saldo,
                                vlr_saldo_ini,
                                ind_saldo_ini,
                                vlr_saldo_fim,
                                ind_saldo_fim,
                                vlr_tot_cre,
                                vlr_tot_deb,
                                num_processo)
                     values (mcod_empresa,
                             pcod_estab,
                             vi_ident_conta,
                             PDataFim,
                             vn_vlr_saldo_ini,
                             vc_ind_saldo_ini,
                             vn_vlr_saldo_fim,
                             vc_ind_saldo_fim,
                             vn_vlr_credito,
                             vn_vlr_debito,
                             99999);
        exception when dup_val_on_index then
                  begin
                    update x02_saldos set vlr_saldo_ini = vn_vlr_saldo_ini,
                                          ind_saldo_ini = vc_ind_saldo_ini,
                                          vlr_saldo_fim = vn_vlr_saldo_fim,
                                          ind_saldo_fim = vc_ind_saldo_fim,
                                          vlr_tot_cre   = vn_vlr_credito,
                                          vlr_tot_deb   = vn_vlr_debito,
                                          num_processo  = 99999
                    where cod_empresa = mcod_empresa
                    and   cod_estab   = pcod_estab
                    and   ident_conta = vi_ident_conta
                    and   data_saldo  = PDataFim;
                  exception when others then
                            null;
                  end;
                  
                  
        end; FIM BRL */
      
        begin
          /* BRL delete X02_SALDOS
          where nvl(vlr_saldo_ini,0) = '0'
            and nvl(vlr_saldo_fim,0) = '0'
            and nvl(vlr_tot_cre,0)   = '0'
            and nvl(vlr_tot_deb,0)   = '0'
            and data_saldo  between pdataini and pdatafim
            and cod_empresa = mcod_empresa
            and  cod_estab   = pcod_estab;*/
        
          delete SAFX02
           where nvl(vlr_saldo_ini, 0) = '0'
             and nvl(vlr_saldo_fim, 0) = '0'
             and nvl(vlr_tot_cre, 0) = '0'
             and nvl(vlr_tot_deb, 0) = '0'
             and cod_empresa = mcod_empresa
             and cod_estab = pcod_estab;
        
        end;
      
        --insere linha
      
        mLinha := LIB_STR.w(mLinha, mreg.COD_CONTA, 2);
        mLinha := LIB_STR.w(mlinha, '|', 18);
        mLinha := LIB_STR.w(mLinha, substr(MREG.DESCRICAO, 1, 30), 20);
        mLinha := LIB_STR.w(mlinha, '|', 57);
        mLinha := LIB_STR.w(mLinha,
                            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(TO_CHAR(vn_vlr_saldo_ini,
                                                                        '999,999,999,999,990.00'))),
                                                    '.',
                                                    '-'),
                                            ',',
                                            '.'),
                                    '-',
                                    ','),
                            60);
        mLinha := LIB_STR.w(mlinha, '|', 80);
        mLinha := LIB_STR.w(mlinha,
                            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(TO_CHAR(vn_vlr_credito,
                                                                        '999,999,999,999,900.00'))),
                                                    '.',
                                                    '-'),
                                            ',',
                                            '.'),
                                    '-',
                                    ','),
                            83);
        mLinha := LIB_STR.w(mlinha, '|', 100);
        mLinha := LIB_STR.w(mLinha,
                            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(TO_CHAR(vn_vlr_debito,
                                                                        '999,999,999,999,990.00'))),
                                                    '.',
                                                    '-'),
                                            ',',
                                            '.'),
                                    '-',
                                    ','),
                            103);
        mLinha := LIB_STR.w(mlinha, '|', 120);
        mLinha := LIB_STR.w(mlinha,
                            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(TO_CHAR(vn_vlr_saldo_fim,
                                                                        '999,999,999,999,900.00'))),
                                                    '.',
                                                    '-'),
                                            ',',
                                            '.'),
                                    '-',
                                    ','),
                            125);
      
        LIB_PROC.add(mLinha);
      
        v_linha := v_linha + 1;
      
        if v_linha >= 43 then
          lib_proc.new_page();
          Cabecalho(v_cgc,
                    v_estab || ' - ' || V_RAZAO_SOCIAL,
                    pDataIni,
                    pDataFim,
                    v_folha);
        
          v_folha := v_folha + 1;
          v_linha := 0;
        
          -- Quantidade de linhas suficientes para a montagem do cabeçalho
          v_linha := v_linha + 8;
        
        end if;
      
        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, LPAD(' ', 158, ' ') || ' ', 2);
        LIB_PROC.add(mLinha);
      
        v_linha := v_linha + 1;
      
      END LOOP;
    
    END;
  
    LIB_PROC.CLOSE();
  
    RETURN mproc_id;
  END;

  Procedure Cabecalho(p_cgc          varchar2,
                      p_razao_social varchar2,
                      p_dat_ini      DATE,
                      p_dat_fim      DATE,
                      p_pagina       varchar2) is
  
    mLinha varchar2(160);
  
  begin
  
    mLinha := LIB_STR.w('', ' ', 1);
    mLinha := LIB_STR.w(mLinha, LPAD(' ', 158, ' ') || ' ', 2);
    LIB_PROC.add(mLinha);
  
    mLinha := LIB_STR.w('', ' ', 1);
    mLinha := LIB_STR.w(mLinha, 'EMPRESA: ' || p_razao_social, 2);
    mLinha := LIB_STR.w(mLinha, 'C.N.P.J.:  ' || p_cgc, 115);
    mLinha := LIB_STR.w(mLinha, ' ', 160);
    LIB_PROC.add(mLinha);
  
    mLinha := LIB_STR.w('', ' ', 1);
    mLinha := LIB_STR.w(mLinha,
                        'Data Geração: ' ||
                        to_char(sysdate, 'dd/mm/rrrr hh24:mi'),
                        2);
    mLinha := LIB_STR.w(mLinha,
                        'Período : ' || p_dat_ini || ' a ' || p_dat_fim,
                        115);
    LIB_PROC.add(mLinha);
  
    mLinha := LIB_STR.w('', ' ', 1);
    mLinha := LIB_STR.w(mLinha, 'Pagina  : ' || lpad(p_pagina, 4, 0), 115);
    LIB_PROC.add(mLinha);
    --
  
    mLinha := LIB_STR.w('', ' ', 1);
    mLinha := LIB_STR.wcenter(mLinha,
                              'B A L A N C E T E   A N A L I T I C O   D E   V E R I F I C A C Ã O',
                              150);
    LIB_PROC.add(mLinha);
  
    mLinha := LIB_STR.w(mLinha, RPAD('=', 150, '=') || ' ', 1);
    LIB_PROC.add(mLinha);
  
    mLinha := null;
  
    mLinha := LIB_STR.w(mlinha, 'CONTA CONTABIL', 2);
  
    mLinha := LIB_STR.w(mlinha, '|', 18);
    mLinha := LIB_STR.w(mlinha, 'DESCRIÇÃO', 30);
  
    mLinha := LIB_STR.w(mlinha, '|', 57);
    mLinha := LIB_STR.w(mLinha, 'SALDO ANTERIOR', 61);
  
    mLinha := LIB_STR.w(mlinha, '|', 80);
    mLinha := LIB_STR.w(mLinha, 'TOTAL CREDITO', 84);
  
    mLinha := LIB_STR.w(mlinha, '|', 100);
    mLinha := LIB_STR.w(mLinha, 'TOTAL DEBITO', 104);
  
    mLinha := LIB_STR.w(mlinha, '|', 120);
    mLinha := LIB_STR.w(mLinha, 'SALDO ATUAL', 129);
  
    LIB_PROC.add(mLinha);
    mLinha := LIB_STR.w(mLinha, RPAD('=', 150, '=') || ' ', 1);
    LIB_PROC.add(mLinha);
  
    v_linha := v_linha + 1;
  
  end;

END BRL_GE_PC_CALCULO_X02_CPROC;
/
