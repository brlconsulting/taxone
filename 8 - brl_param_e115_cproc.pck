create or replace package brl_param_e115_cproc is

 -- Purpose : PArametrizac?o para alterar base de ICMS e CST, e ainda gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)
  -- empresa BRL - Andreia Ferreira

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;
  function orientacao return varchar2;
  function executar(p_cod_cfop varchar2,
                    p_base1    varchar2,
                    p_base2ou3 varchar2,
                    p_cst_ICMS varchar2,
                    p_base_st  varchar2,
                    p_cst_st   varchar2,
                    p_e115     varchar2,
                    p_tipo     varchar2) return integer;
end;
/
create or replace package body brl_param_e115_cproc is

 -- Purpose : PArametrizac?o para alterar base de ICMS e CST, e ainda gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)
  -- empresa BRL - Andreia Ferreira


  ccod_estab   estabelecimento.cod_estab%type;
  ccod_empresa empresa.cod_empresa%type;
  ccod_usuario usuario_estab.cod_usuario%type;

  cDescricao VARCHAR2(100);
  cLinha     VARCHAR2(250);
  nFolha     NUMBER := 0;
  nProc_id   INTEGER;
  --
  FUNCTION PARAMETROS RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN
    cCod_Empresa := Lib_Parametros.RECUPERAR('EMPRESA');
    cCod_Estab   := NVL(Lib_Parametros.RECUPERAR('ESTABELECIMENTO'), '');
    cCod_Usuario := Lib_Parametros.Recuperar('Usuario');
    --
    Lib_Proc.Add_Param(pstr,
                       'CFOP',
                       'VARCHAR2',
                       'Textbox',
                       'S',
                       NULL,
                       NULL,
                       'select distinct cod_cfo, descricao from  x2012_cod_fiscal order by cod_cfo');

    Lib_Proc.Add_Param(pstr,
                       'Base Tributada - Pode ter?',
                        'VARCHAR2',
                       'RadioButton',
                       'S',
                       null,
                       NULL,
                       'S=Sim,N=N?o');

    LIB_PROC.add_param(pstr,
                       'Base Isenta ou Diferida-Outras',
                        'VARCHAR2',
                       'RadioButton',
                       'S',
                       null,
                       NULL,
                       '2=Isenta,3=Diferida');

    LIB_PROC.add_param(pstr,
                       'CST do ICMS',
                       'Varchar2',
                       'Textbox',
                       'S',
                       null,
                       NULL,
                       'select distinct cod_situacao_b, descricao from y2026_sit_trb_uf_b where grupo_situacao_b = ''002'' order by cod_situacao_b');

   LIB_PROC.add_param(pstr,
                       'Base ST - Pode ter?' ,
                       'VARCHAR2',
                       'RadioButton',
                       'S',
                       null,
                       NULL,
                       'S=Sim,N=N?o');

    LIB_PROC.add_param(pstr,
                       'CST quanto tiver ST',
                       'Varchar2',
                       'Textbox',
                       'N',
                       null,
                       NULL,
                       'select distinct cod_situacao_b, descricao from y2026_sit_trb_uf_b where grupo_situacao_b = ''002'' order by cod_situacao_b');


    LIB_PROC.add_param(pstr,
                       'Cod E115',
                       'Varchar2',
                       'Textbox',
                       'N',
                       null,
                       NULL,
                       'select distinct cod_inf_adic, dsc_inf from efd_inf_adic_apur a, estado b
 where a.ident_estado = b.ident_estado and
 b.cod_estado = ''RS''  and cod_inf_adic like ''RS%'' order by cod_inf_adic '); -- coloquei o RS pois e so pra o RS


    Lib_Proc.Add_Param(pstr,
                       'Inclusao/Exclusao/Visualizar',
                       'VARCHAR2',
                       'RadioButton',
                       'S',
                       null,
                       NULL,
                       'I=Inclusao,E=Exclusao,V=Visualizar');

    --
    RETURN pstr;
  END;
  --
  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PARAMETRIZAC?O PARA BASE de ICMS e CST, E E115 do SPED Fiscal e GIA do RS';
  END;
  --
   FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;
  --
  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;
  --
  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PARAMETRIZAC?O PARA BASE de ICMS e CST, E E115 do SPED Fiscal e GIA do RS';
  END;
  --
  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;
  --
  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;
  --
  FUNCTION Orientacao RETURN VARCHAR2 IS
  BEGIN
    -- Orienta??o da impress?o
    RETURN 'PORTRAIT';
  END;
  --
  function executar(p_cod_cfop varchar2,
                    p_base1    varchar2,
                    p_base2ou3 varchar2,
                    p_cst_ICMS varchar2,
                    p_base_st  varchar2,
                    p_cst_st   varchar2,
                    p_e115     varchar2,
                    p_tipo     varchar2) return integer is

  begin

    -- incluir
    if (p_tipo like '%I%') then
      begin    
        insert into brl_param_e115t_cproc
          (cfop, base_1, base_2ou3, cst_icms, base_st, cst_st, e115)
        values
          (p_cod_cfop, p_base1, p_base2ou3, p_cst_icms, p_base_st, p_cst_st, p_e115);

        commit;
      exception
        when dup_val_on_index then
          raise_application_error(-20000,
                                  'Registros ja existente na tabela.');
        when others then
          raise_application_error(-20000,
                                  'Ocorreu um erro ao incluir o registro na tabela.');
      end;
      -- EXCLUIR
    elsif (p_tipo like '%E%') then

      delete brl_param_e115t_cproc
       where 1 = 1
         and cfop = p_cod_cfop;
      commit;

      -- VISUALIZAR
    elsif (p_tipo like '%V%') then
      nProc_id   := Lib_Proc.NEW('Param_spedupdate_Cproc', 48, 150);
      cDescricao := 'Relac?o da Pametrizac?o para BASE de ICMS e CST, E E115 do SPED Fiscal e GIA do RS';
      Lib_Proc.add_tipo(nProc_id, 1, cDescricao, 1, 48, 150, 9);

      Lib_Proc.new_page(1);
      nFolha := nFolha + 1;

      cLinha := Lib_Str.w(cLinha, RPAD('CFOP', 14, ' '), 0);
      cLinha := Lib_Str.w(cLinha, RPAD('|Base_1', 15, ' '), 5);
      cLinha := Lib_Str.w(cLinha, RPAD('|Base 2 ou 3', 30, ' '), 21);
      cLinha := Lib_Str.w(cLinha, RPAD('|CST do ICMS', 12, ' '), 51);
      cLinha := Lib_Str.w(cLinha, RPAD('|Base ST', 19, ' '), 63);
      cLinha := Lib_Str.w(cLinha, RPAD('|CST quando houver ST', 19, ' '), 82);
      cLinha := Lib_Str.w(cLinha, RPAD('|Cod do E115', 19, ' '), 92);

      Lib_Proc.ADD(cLinha);

      for reg in (select cfop, base_1, base_2ou3, cst_icms, base_st, cst_st, e115
                    from brl_param_e115t_cproc ) loop

        cLinha := LIB_STR.w('', ' ', 0);
        clinha := lib_str.w(clinha, rpad(reg.cfop, 14, ' '), 0);
        clinha := lib_str.w(clinha, '|' || rpad(reg.base_1, 14, ' '), 5);
        clinha := lib_str.w(clinha, '|' || rpad(reg. base_2ou3,30,' '), 21);
        clinha := lib_str.w(clinha, '|' || rpad(reg.cst_icms,12,' '), 51);
        clinha := lib_str.w(clinha, '|' || rpad(reg.base_st,19,' '), 63);
        clinha := lib_str.w(clinha, '|' || rpad(reg.cst_st,19,' '), 82);
        clinha := lib_str.w(clinha, '|' || rpad(reg.e115,19,' '), 92);

      LIB_PROC.add(cLinha, null, null, 1);

      end loop;
    end if;

    return 0;

  end; --executar

end brl_param_e115_cproc;
/
