create or replace package brl_replica_x2101_cproc is

 -- Purpose : Replica X2101
  -- criado em Maio/2020 - empresa BRL - Andr?ia Ferreira

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;
  function orientacao return varchar2;
  function executar(p_versao_ant  varchar2,
                    p_versao_nova varchar2,
                    p_tipo     varchar2) return integer;
end;
/
create or replace package body brl_replica_x2101_cproc is

 -- Purpose : Replica X2101
  -- criado em Maio/2020 - empresa BRL - Andr?ia Ferreira

  ccod_estab   estabelecimento.cod_estab%type;
  ccod_empresa empresa.cod_empresa%type;
  ccod_usuario usuario_estab.cod_usuario%type;

  cDescricao VARCHAR2(100);
  cLinha     VARCHAR2(250);
  nFolha     NUMBER := 0;
  nProc_id   INTEGER;

  -- vari?veis da importa??o autom?tica...
  PAR_COD_EMPRESA_W   VARCHAR2(3);
  PAR_COD_PROG_W      NUMBER;
  PAR_DATA_PROC_W     DATE;
  PAR_IND_GRAVA_W     CHAR(1);
  PAR_IND_DATA_W      CHAR(1);
  PAR_GRAVA_LOG_W     CHAR(1);
  PAR_DSC_DIRETORIO_W VARCHAR2(500);
  PAR_MENS_ERR        VARCHAR2(500);

  --
  FUNCTION PARAMETROS RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN
    cCod_Empresa := Lib_Parametros.RECUPERAR('EMPRESA');
    cCod_Estab   := NVL(Lib_Parametros.RECUPERAR('ESTABELECIMENTO'), '');
    cCod_Usuario := Lib_Parametros.Recuperar('Usuario');
    --

    Lib_Proc.Add_Param(pstr,
                       'Vers?o Ref Antiga',
                       'VARCHAR2',
                       'Textbox',
                       'S',
                       NULL,
                       NULL,
                       'select distinct versao from  sped_contas_ref  order by versao');

    Lib_Proc.Add_Param(pstr,
                       'Vers?o Ref Nova',
                       'VARCHAR2',
                       'Textbox',
                       'S',
                       NULL,
                       NULL,
                       'select distinct versao from  sped_contas_ref  order by versao');

    Lib_Proc.Add_Param(pstr,
                       'Inclusao/Visualizar',
                       'VARCHAR2',
                       'RadioButton',
                       'S',
                       null,
                       NULL,
                       'I=Inclusao,V=Visualizar');
    --
    RETURN pstr;
  END;
  --
  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ECD - Replica o Plano Referencial da RFB de uma Vers?o para Outra';
  END;
  --
   FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Contabilidade';
  END;
  --
  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;
  --
  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ECD - Replica o Plano Referencial da RFB de uma Vers?o para Outra';
  END;
  --
  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;
  --
  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Contabilidade';
  END;
  --
  FUNCTION Orientacao RETURN VARCHAR2 IS
  BEGIN
    -- Orienta??o da impress?o
    RETURN 'PORTRAIT';
  END;
  --
  function executar(p_versao_ant  varchar2,
                    p_versao_nova varchar2,
                    p_tipo        varchar2) return integer is

  begin
 -- incluir
    if (p_tipo like '%I%') then
       delete safx2101;
       commit;

       for reg in (select c.cod_conta, b.cod_conta_ref, b.cod_entidade_resp,d.cod_custo
        from x2101_contas_ref_ccusto a, sped_contas_ref b, x2002_plano_contas c, x2003_centro_custo d
        where a.ident_conta_ref = b.ident_conta_ref and a.ident_conta = c.ident_conta and a.ident_custo = d.ident_custo(+) and
        b.versao = p_versao_ant) loop

        insert into safx2101(cod_conta,ind_conta,cod_conta_ref,versao_ref,cod_entidade_resp,cod_custo,dat_gravacao)
        values(reg.cod_conta, 'A', reg.cod_conta_ref, p_versao_nova, reg.cod_entidade_resp, reg.cod_custo, sysdate);
        end loop;
        commit;

-- chama a importa??o autom?tica para importar esta safx2101
-- IMPORTACAO AUTOMATICA
    If ccod_empresa = '003'then
      PAR_COD_PROG_W  := 6;
    end if;

    If ccod_empresa = '002'then
      PAR_COD_PROG_W  := 6;
    end if;

    If ccod_empresa = '001'then
      PAR_COD_PROG_W  := 15;
    end if;

    If ccod_empresa = '004'then
      PAR_COD_PROG_W  := 1;
    end if;


      PAR_COD_EMPRESA_W   := ccod_empresa;
     -- PAR_COD_PROG_W      := ? -- Este codigo est? no IF acima -- Codigo da programacao feita no MasterSAF para importacao da safx2101
      PAR_DATA_PROC_W     := sysdate;
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

end if;

--    elsif (p_tipo like '%V%') then
      nProc_id   := Lib_Proc.NEW('brl_replica_x2101_cproc', 48, 150);
      cDescricao := 'Rela??o da Parametriza??o do Plano Referencial da RFB';
      Lib_Proc.add_tipo(nProc_id, 1, cDescricao, 1, 48, 150, 9);

      Lib_Proc.new_page(1);
      nFolha := nFolha + 1;

      cLinha := Lib_Str.w(cLinha, RPAD('|Conta Cont?bil', 15, ' '), 0);
      cLinha := Lib_Str.w(cLinha, RPAD('|Vers?o', 7, ' '), 16);
      cLinha := Lib_Str.w(cLinha, RPAD('|Conta Referencial', 44, ' '), 23);
      cLinha := Lib_Str.w(cLinha, RPAD('|Centro Custo', 37, ' '), 67);


      Lib_Proc.ADD(cLinha);

      for reg in (select c.cod_conta, b.cod_conta_ref, b.cod_entidade_resp,d.cod_custo, b.versao
        from x2101_contas_ref_ccusto a, sped_contas_ref b, x2002_plano_contas c, x2003_centro_custo d
        where a.ident_conta_ref = b.ident_conta_ref and a.ident_conta = c.ident_conta and a.ident_custo = d.ident_custo(+)
        order by b.versao,c.cod_conta ) loop

        cLinha := LIB_STR.w('', ' ', 0);
        clinha := lib_str.w(clinha, '|' ||rpad(reg.cod_conta, 15, ' '), 0);
        clinha := lib_str.w(clinha, '|' ||rpad(reg.versao, 7, ' '), 16);
        clinha := lib_str.w(clinha, '|' || rpad(reg.cod_conta_ref, 44, ' '), 23);
        clinha := lib_str.w(clinha, '|' || rpad(reg.cod_custo,37,' '), 67);

      LIB_PROC.add(cLinha, null, null, 1);

      end loop;
--    end if;

    return 0;

  end; --executar

end  brl_replica_x2101_cproc;
/
