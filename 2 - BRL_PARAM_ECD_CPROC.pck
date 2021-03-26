CREATE OR REPLACE PACKAGE BRL_PARAM_ECD_CPROC IS

  -- Purpose : Conferencia das contas n?o parametrizadas para o SPED Contabil
  -- Criado em julho/2012 - BRL Consultores

  /* VARIAVEIS DE CONTROLE DE CABECALHO DE RELATORIO */
  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;

  FUNCTION Executar(ps_estab VARCHAR2, pd_periodo VARCHAR2) RETURN INTEGER;

  PROCEDURE Cabecalho(ps_estab varchar2, prel varchar2);

END BRL_PARAM_ECD_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_PARAM_ECD_CPROC IS

  mcod_empresa    empresa.cod_empresa%TYPE;
  vs_razao_social estabelecimento.razao_social%TYPE;
  vn_cnpj         varchar2(25);
  mLinha          VARCHAR2(500);
  vn_pagina       number := 1;
  vn_linhas       number := 0;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');

    LIB_PROC.add_param(pstr,
                       'Empresa',
                       'Varchar2',
                       'Combobox',
                       'S',
                       null,
                       NULL,
                       'SELECT DISTINCT cod_empresa, cod_empresa||'' - ''||razao_social FROM   empresa WHERE  cod_empresa = ''' ||
                       mcod_empresa || '''');

    LIB_PROC.add_param(pstr,
                       'Ano',
                       'varchar2',
                       'textbox',
                       'S',
                       NULL,
                       'YYYY');

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil - Validac?o da parametrizac?o do modulo';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil - Validac?o da parametrizac?o do modulo';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil';
  END;

  FUNCTION Executar(ps_estab VARCHAR2, pd_periodo VARCHAR2) RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id        INTEGER;
    vs_descricao    x2002_plano_contas.descricao%TYPE;
    vs_descricao_cc x2003_centro_custo.descricao%TYPE;

    x_data_ini date;
    x_data_fim date;

    vc_tem_movto VARchar(1) := 'N';

    -- para o Plano Referencial da Receita
    cursor referencial is

/*    -- apenas conta contabil
      select cod_conta, null cod_custo
        from x2002_plano_contas a, x02_saldos b
       where a.ident_conta = b.ident_conta
         and b.data_saldo between x_data_ini and x_data_fim
         and b.cod_empresa = mcod_empresa
      minus
      select cod_conta, null cod_custo
        from x2002_plano_contas c, x2101_contas_ref_ccusto d
       where c.ident_conta = d.ident_conta

      UNION ALL
*/
      -- conta contabil e centro de custo
      select cod_conta, cod_custo
        From x80_saldos_ccusto  a,
             x2003_centro_custo b,
             x2002_plano_contas c
       where a.ident_custo = b.ident_custo
         and a.ident_conta = c.ident_conta
         and a.dat_saldo between x_data_ini and x_data_fim
         and a.cod_empresa = mcod_empresa
      minus
      select cod_conta, cod_custo
        from x2101_contas_ref_ccusto d,
             x2003_centro_custo      e,
             x2002_plano_contas      f
       where d.ident_custo = e.ident_custo
         and d.ident_conta = f.ident_conta;

      -- Para os Demonstrativos Contabeis (Balanco e DRE)
       cursor
       demonstrativo is
       -- balanco nao tem CC
              select cod_conta, null cod_custo
                from x2002_plano_contas a, x02_saldos b
               where a.ident_conta = b.ident_conta
                 and a.ind_natureza in ('1','2', '7')
                 and b.data_saldo between x_data_ini and x_data_fim
                 and b.cod_empresa = mcod_empresa
              minus
              select cod_conta, NULL cod_custo
                from x2002_plano_contas c, x2103_contas_aglut_emp d
               where c.ident_conta = d.ident_conta
        -- DRE tem CC
              UNION ALL
              select cod_conta, cod_custo
                From x80_saldos_ccusto  a,
                     x2003_centro_custo b,
                     x2002_plano_contas c
               where a.ident_custo = b.ident_custo
                 and a.ident_conta = c.ident_conta
                 and c.ind_natureza not in ('1','2', '7')
                 and a.dat_saldo between x_data_ini and x_data_fim
                 and a.cod_empresa = mcod_empresa
              minus
              select x2002.cod_conta cod_conta, x2003.cod_custo cod_custo
                from x2103_contas_aglut_emp_custos x2103,
                     x2002_plano_contas            x2002,
                     x2003_centro_custo            x2003
               where x2103.ident_conta = x2002.ident_conta
                 and x2103.cod_custo = x2003.cod_custo
                 and x2103.cod_empresa = mcod_empresa
                 and x2103.cod_estab = ps_estab;

  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_PARAM_ECD_CPROC', 48, 150);
    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Validac?o do Plano de Contas Referencial (X2101)',
                      1);
    LIB_PROC.add_tipo(mproc_id,
                      2,
                      'Validac?o do Demonstrativo Contabil - DRE/BALANCO (X2103)',
                      1);

    x_data_ini := to_date(TO_CHAR('01/01/' || pd_periodo), 'DD/MM/YYYY');
    x_data_fim := to_date(TO_CHAR('31/12/' || pd_periodo), 'DD/MM/YYYY');

    begin
      select substr(cgc, 1, 2) || '.' || substr(cgc, 3, 3) || '.' ||
             substr(cgc, 6, 3) || '/' || substr(cgc, 9, 4) || '-' ||
             substr(cgc, 13, 2) cgc,
             cod_estab || ' - ' || estab.razao_social razao_social
        into vn_cnpj, vs_razao_social
        from estabelecimento estab
       where cod_empresa = mcod_empresa
         and cod_estab = ps_estab
       order by cod_estab;
    exception
      when no_data_found then
        vn_cnpj         := null;
        vs_razao_social := null;
    end;

    /*---------------------------------------------------------------------------
              Contas n?o parametrizadas no plano de contas referencial
    ---------------------------------------------------------------------------*/
    -- Inicializa variaveis
    vn_pagina := 1;
    vn_linhas := 50;
    Cabecalho(ps_estab, 1); -- cabecalho do relatorio
    vc_tem_movto := 'N';

    for reg in referencial loop

      vc_tem_movto := 'S';

      -- Busca descric?o da conta
      begin
        select distinct descricao
          into vs_descricao
          from x2002_plano_contas
         where cod_conta = reg.cod_conta
           and valid_conta =
               (select max(valid_conta)
                  from x2002_plano_contas
                 where cod_conta = reg.cod_conta);
      exception
        when others then
          vs_descricao := NULL;
      end;
      -- busca descric?o do centro de custo
      begin
        select distinct descricao
          into vs_descricao_cc
          from x2003_centro_custo
         where cod_custo = reg.cod_custo
           and valid_custo =
               (select max(valid_custo)
                  from x2003_centro_custo
                 where cod_custo = reg.cod_custo);
      exception
        when others then
          vs_descricao := NULL;
      end;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, reg.cod_conta, 2);
      mLinha := LIB_STR.w(mLinha, substr(vs_descricao, 1, 49), 20);
      mLinha := LIB_STR.w(mLinha, reg.cod_custo, 70);
      mLinha := LIB_STR.w(mLinha, substr(vs_descricao_cc, 1, 49), 95);
      LIB_PROC.add(mLinha, null, null, 1);
      vn_linhas := vn_linhas + 1;
      Cabecalho(ps_estab, 1);

    end loop;

    if vc_tem_movto = 'N' then
      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'TODAS AS CONTAS EST?O PARAMETRIZADAS!',
                          55);
      LIB_PROC.add(mLinha, null, null, 1);
    end if;

    /*---------------------------------------------------------------------------
              Contas n?o parametrizadas nos demonstrativos contabeis
    ---------------------------------------------------------------------------*/
    vn_pagina := 1;
    vn_linhas := 50;
    Cabecalho(ps_estab, 2);
    vc_tem_movto := 'N';

    for reg in demonstrativo loop

      vc_tem_movto := 'S';

      -- Busca descric?o da conta
      begin
        select distinct descricao
          into vs_descricao
          from x2002_plano_contas
         where cod_conta = reg.cod_conta
           and valid_conta =
               (select max(valid_conta)
                  from x2002_plano_contas
                 where cod_conta = reg.cod_conta);
      exception
        when others then
          vs_descricao := NULL;
      end;

      -- busca descric?o do centro de custo
      begin
        select descricao
          into vs_descricao_cc
          from x2003_centro_custo
         where cod_custo  = reg.cod_custo
           and valid_custo =
               (select max(valid_custo)
                  from x2003_centro_custo
                 where cod_custo = reg.cod_custo);
      exception
        when others then
          vs_descricao_cc := NULL;
      end;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, reg.cod_conta, 2);
      mLinha := LIB_STR.w(mLinha, substr(vs_descricao, 1, 49), 20);
      mLinha := LIB_STR.w(mLinha, reg.cod_custo, 70);
      mLinha := LIB_STR.w(mLinha, substr(vs_descricao_cc, 1, 49), 95);
      LIB_PROC.add(mLinha, null, null, 2);

      vn_linhas := vn_linhas + 1;
      Cabecalho(ps_estab, 2);

    end loop;

    if vc_tem_movto = 'N' then
      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'TODAS AS CONTAS EST?O PARAMETRIZADAS!',
                          55);
      LIB_PROC.add(mLinha, null, null, 2);
    end if;

    LIB_PROC.CLOSE();
    RETURN mproc_id;

  end;

  PROCEDURE Cabecalho(ps_estab varchar2, prel varchar2) IS

  BEGIN

    if vn_linhas >= 49 then

      -- Imprime cabecalho do log
      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'Empresa : ' || mcod_empresa || ' - ' ||
                          vs_razao_social,
                          2);
      mLinha := LIB_STR.w(mLinha,
                          'Pagina : ' || lpad(vn_pagina, 5, '0'),
                          136);
      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'Data de Processamento : ' ||
                          to_char(sysdate, 'dd/mm/rrrr hh24:mi:ss'),
                          2);
      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      if prel = 1 then
        mLinha := LIB_STR.w(mLinha,
                            'PARAMETRIZAC?O - Plano de Contas Referencial (2101)',
                            100 -
                            length('PARAMETRIZAC?O - Plano de Contas Referencial (2101)'));
      elsif prel = 2 then
        mLinha := LIB_STR.w(mLinha,
                            'PARAMETRIZAC?O - Demonstrativo Contabil - DRE/BALANCO (X2103)',
                            100 -
                            length('PARAMETRIZAC?O - Demonstrativo Contabil - DRE/BALANCO (2103)'));
      end if;
      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then
        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Conta', 2);
        mLinha := LIB_STR.w(mLinha, 'Descric?o', 20);
        mLinha := LIB_STR.w(mLinha, 'Centro de Resultado', 70);
        mLinha := LIB_STR.w(mLinha, 'Descric?o', 95);
        LIB_PROC.add(mLinha, null, null, prel);

      elsif prel = 2 then

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Conta', 2);
        mLinha := LIB_STR.w(mLinha, 'Descric?o', 20);
        mLinha := LIB_STR.w(mLinha, 'Centro de Resultado', 70);
        mLinha := LIB_STR.w(mLinha, 'Descric?o', 95);
        LIB_PROC.add(mLinha, null, null, prel);

      end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then
        vn_linhas := 9;
      else
        vn_linhas := 7;
      end if;
      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_PARAM_ECD_CPROC;
/
