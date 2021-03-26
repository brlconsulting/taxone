CREATE OR REPLACE PACKAGE BRL_E115_CPROC IS

  -- Purpose : altera base de ICMS e CST, e ainda gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)
  -- empresa BRL - Andreia Ferreira

  /* VARI?VEIS DE CONTROLE DE CABE?ALHO DE RELAT?RIO */
  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;

   FUNCTION Executar(c_empresa Varchar2,
                    c_Estab   Varchar2,
                    pDt_Ini   DATE,
                    pDt_Fim   DATE,
                    vlr_faturamento NUMBER,
                    vlr_salarios NUMBER,
                    nr_func NUMBER) RETURN INTEGER;

  PROCEDURE Cabecalho(c_estab varchar2, prel varchar2);

END BRL_E115_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_E115_CPROC IS

  -- Purpose : altera base de ICMS e CST, e ainda gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)
  -- empresa BRL - Andreia Ferreira

  mcod_empresa    empresa.cod_empresa%TYPE;
  vs_razao_social estabelecimento.razao_social%TYPE;
  vn_cnpj         varchar2(25);
  mLinha          VARCHAR2(500);
  vn_pagina       number := 1;
  vn_linhas       number := 0;
  w_sequencial    number :=0;
  W_e115          varchar2(20);


 -- vari?veis da importa??o autom?tica...
  PAR_COD_EMPRESA_W   VARCHAR2(3);
  PAR_COD_PROG_W      NUMBER;
  PAR_DATA_PROC_W     DATE;
  PAR_IND_GRAVA_W     VARCHAR(1);
  PAR_IND_DATA_W      VARCHAR(1);
  PAR_GRAVA_LOG_W     VARCHAR(1);
  PAR_DSC_DIRETORIO_W VARCHAR2(500);
  PAR_MENS_ERR        VARCHAR2(500);


  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');

    Lib_Proc.Add_Param(pstr,
                       'Empresa          ',
                       'VARCHAR2',
                       'combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT a.cod_empresa, a.cod_empresa||'' - ''||a.razao_social FROM empresa a where a.cod_empresa = ''' ||
                    mcod_empresa || ''' ORDER BY a.cod_empresa');
    Lib_Proc.Add_Param(pstr,
                       '______________________________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    Lib_Proc.Add_Param(pstr,
                       'Estabelecimento  ',
                       'VARCHAR2(04)',
                       'Combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT a.cod_estab, a.cod_estab||'' - ''||a.razao_social|| '' - ''||a.CIDADE FROM estabelecimento a WHERE ' ||
                       '  a.cod_empresa = :1 and ident_estado in (select ident_estado from estado where cod_Estado = '''||
                       'RS'|| ''') ORDER BY a.cod_estab');
    Lib_Proc.Add_Param(pstr,
                       '______________________________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    Lib_Proc.Add_Param(pstr,
                       'Data Inicial  (DD/MM/AAAA)',
                       'DATE',
                       'Textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');
    Lib_Proc.Add_Param(pstr,
                       'Data Final    (DD/MM/AAAA)',
                       'DATE',
                       'Textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');
    Lib_Proc.Add_Param(pstr,
                       '______________________________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');


 Lib_Proc.Add_Param(pstr,
                       'Valor do Faturamento do mes',
                       'Number',
                       'Textbox',
                       'N',
                       NULL,
                       '#,###,###,###,###.00',
                       'S');

 Lib_Proc.Add_Param(pstr,
                       'Valor da Folha de Salarios do mes.',
                       'Number',
                       'Textbox',
                       'N',
                       NULL,
                       '#,###,###,###,###.00',
                        'S');

 Lib_Proc.Add_Param(pstr,
                       'Numero de Empregados do mes.',
                       'Number',
                       'Textbox',
                       'N',
                       NULL,
                       '#,###,###,###,###.00',
                        'S');

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Altera base de ICMS e CST e gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Altera base de ICMS e CST e gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED FISCAL';
  END;

  FUNCTION Executar(c_empresa varchar2,
                    c_estab    VARCHAR2,
                    pDt_Ini   DATE,
                    pDt_Fim   DATE,
                    vlr_faturamento NUMBER,
                    vlr_salarios NUMBER,
                    nr_func number) RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id     INTEGER;

    cursor cur_movtos is

      select a.cod_empresa,
                     a.cod_estab,
                     a.data_fiscal,
                     a.movto_e_s,
                     a.norm_dev,
                     a.ident_docto,
                     a.ident_fis_jur,
                     a.num_docfis,
                     a.serie_docfis,
                     a.sub_serie_docfis,
                     a.ident_docto_fiscal,
                     b.discri_item,
                     B.VLR_CONTAB_ITEM,
                     b.ident_item_merc,
                     c.cod_cfo,
                     b.vlr_base_icms_1,
                     b.vlr_base_icms_2,
                     b.vlr_Base_icms_3,
                     b.vlr_base_icms_4,
                     b.ident_situacao_b,
                     b.vlr_tributo_icms,
                     b.vlr_tributo_icmss,
                     d.base_1,
                     d.base_2ou3,
                     d.cst_icms,
                     d.base_st,
                     d.cst_st,
                     e.cod_situacao_b
                from dwt_itens_merc b, dwt_docto_fiscal a, x2012_cod_fiscal c, brl_param_e115t_cproc d,
                     y2026_sit_trb_uf_b e
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                  and c.cod_cfo = d.cfop
                  and b.ident_cfo = c.ident_cfo
                  and b.ident_situacao_b =  e.ident_situacao_b
                  and a.situacao = 'N'
                  and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
                  and a.cod_estab = nvl(c_estab, a.cod_estab)
                  and a.data_fiscal between pDt_Ini and pDt_fim;


  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_E115_CPROC', 48, 150);

    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Altera base de ICMS e CST e gera a SAFX245 para o E115 do SPED Fiscal e GIA do RS (VA e VB)',
                      1);

    begin
      select substr(cgc, 1, 2) || '.' || substr(cgc, 3, 3) || '.' ||
             substr(cgc, 6, 3) || '/' || substr(cgc, 9, 4) || '-' ||
             substr(cgc, 13, 2) cgc,
             cod_estab || ' - ' || estab.razao_social razao_social
        into vn_cnpj, vs_razao_social
        from estabelecimento estab
       where cod_empresa = mcod_empresa
         and cod_estab = c_estab
       order by cod_estab;
    exception
      when no_data_found then
        vn_cnpj         := null;
        vs_razao_social := null;
    end;

    -- Inicializa variaveis
    vn_pagina := 1;
    vn_linhas := 50;
    Cabecalho(c_estab, 1);

--  ******************** altera base e CST  das notas fiscais *************
for reg in cur_movtos loop

           -- base tributada
               if reg.base_1  = 'S' then
                 if reg.vlr_base_icms_1> 0 and reg.vlr_base_icms_4 > 0 and reg.cod_situacao_b <> '20' then
                 -- coloquei o ident fixo para nao demorar no processamento
                 --select * from y2026_sit_trb_uf_b where grupo_situacao_b = '002'
                     update dwt_itens_merc set ident_situacao_b = 3
                      where ident_item_merc = reg.ident_item_merc
                        and ident_docto_fiscal = reg.ident_docto_fiscal;

                     update x08_itens_merc set ident_situacao_b = 3
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;

                 end if;

                 if reg.vlr_base_icms_1> 0 and reg.vlr_base_icms_4 = 0 and reg.cod_situacao_b <> '00' then
                  --select * from y2026_sit_trb_uf_b where grupo_situacao_b = '002'
                     update dwt_itens_merc set ident_situacao_b = 1
                      where ident_item_merc = reg.ident_item_merc
                        and ident_docto_fiscal = reg.ident_docto_fiscal;

                     update x08_itens_merc set ident_situacao_b = 1
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;

                 end if;

               end if;

               if reg.base_1  = 'N' and reg.vlr_base_icms_1> 0 then -- altera a base

                if reg.base_2ou3  = '3' then
                    update dwt_itens_merc
                       set vlr_BASE_ICMS_1 = 0,
                           vlr_base_icms_3 = reg.vlr_base_icms_1,
                           vlr_tributo_icms = 0,
                           VLR_ICMS_NDESTAC = reg.vlr_tributo_icms
                     where ident_docto_fiscal = reg.ident_docto_fiscal
                       and ident_item_merc = reg.ident_item_merc;

                    update x08_BASE_merc
                       set COD_TRIBUTACAO = '3'
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item
                       AND COD_TRIBUTACAO = '1'
                       AND COD_TRIBUTO IN ('ICMS');
                   else
                       update dwt_itens_merc
                       set vlr_BASE_ICMS_1 = 0,
                           vlr_base_icms_2 = reg.vlr_base_icms_1,
                           vlr_tributo_icms = 0,
                           VLR_ICMS_NDESTAC = reg.vlr_tributo_icms
                     where ident_docto_fiscal = reg.ident_docto_fiscal
                       and ident_item_merc = reg.ident_item_merc;

                    update x08_BASE_merc
                       set COD_TRIBUTACAO = '2'
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item
                       AND COD_TRIBUTACAO = '1'
                       AND COD_TRIBUTO IN ('ICMS');

                    end if;

                 update x08_trib_merc
                     set vlr_tributo = 0
                   where cod_empresa = reg.cod_empresa
                     and cod_estab = reg.cod_estab
                     and data_fiscal = reg.data_fiscal
                     and movto_e_s = reg.movto_E_s
                     and norm_dev = reg.norm_dev
                     and ident_docto = reg.ident_docto
                     and ident_fis_jur = reg.ident_fis_jur
                     and num_docfis = reg.num_docfis
                     and serie_docfis = reg.serie_docfis
                     and sub_serie_docfis = reg.sub_serie_docfis
                     and discri_item = reg.discri_item
                     AND COD_TRIBUTO IN ('ICMS');

              update x08_itens_merc
                     set vlr_icms_ndestac = reg.vlr_tributo_icms
                   where cod_empresa = reg.cod_empresa
                     and cod_estab = reg.cod_estab
                     and data_fiscal = reg.data_fiscal
                     and movto_e_s = reg.movto_E_s
                     and norm_dev = reg.norm_dev
                     and ident_docto = reg.ident_docto
                     and ident_fis_jur = reg.ident_fis_jur
                     and num_docfis = reg.num_docfis
                     and serie_docfis = reg.serie_docfis
                     and sub_serie_docfis = reg.sub_serie_docfis
                     and discri_item = reg.discri_item;

               end if;

               -- termino da base tributada

             -- tratando base isenta
               if reg.base_2ou3  = '2'  then
                  if  reg.vlr_Base_icms_3 > 0 then -- altera base
                      update dwt_itens_merc
                         set vlr_BASE_ICMS_3 = 0,
                             vlr_base_icms_2 = reg.vlr_base_icms_3
                      where ident_docto_fiscal = reg.ident_docto_fiscal
                        and ident_item_merc = reg.ident_item_merc;

                      update x08_BASE_merc
                         set COD_TRIBUTACAO = '2'
                       where cod_empresa = reg.cod_empresa
                         and cod_estab = reg.cod_estab
                         and data_fiscal = reg.data_fiscal
                         and movto_e_s = reg.movto_E_s
                         and norm_dev = reg.norm_dev
                         and ident_docto = reg.ident_docto
                         and ident_fis_jur = reg.ident_fis_jur
                         and num_docfis = reg.num_docfis
                         and serie_docfis = reg.serie_docfis
                         and sub_serie_docfis = reg.sub_serie_docfis
                         and discri_item = reg.discri_item
                         AND COD_TRIBUTACAO = '3'
                         AND COD_TRIBUTO IN ('ICMS');
                   end if;
                  end if;
               -- termino da base isenta

               --  tratando base outras

                  if reg.base_2ou3  = '3'  then
                   if  reg.vlr_Base_icms_2 > 0 then -- altera base
                      update dwt_itens_merc
                         set vlr_BASE_ICMS_2 = 0,
                             vlr_base_icms_3 = reg.vlr_base_icms_2
                      where ident_docto_fiscal = reg.ident_docto_fiscal
                        and ident_item_merc = reg.ident_item_merc;

                       update x08_BASE_merc
                         set COD_TRIBUTACAO = '3'
                       where cod_empresa = reg.cod_empresa
                         and cod_estab = reg.cod_estab
                         and data_fiscal = reg.data_fiscal
                         and movto_e_s = reg.movto_E_s
                         and norm_dev = reg.norm_dev
                         and ident_docto = reg.ident_docto
                         and ident_fis_jur = reg.ident_fis_jur
                         and num_docfis = reg.num_docfis
                         and serie_docfis = reg.serie_docfis
                         and sub_serie_docfis = reg.sub_serie_docfis
                         and discri_item = reg.discri_item
                         AND COD_TRIBUTACAO = '2'
                         AND COD_TRIBUTO IN ('ICMS');
                   end if;
                  end if;
                  -- termino da base outras

              -- altera o CST so se for diferente do que esta parametrizado e so se tiver base 2 ou 3
                  if reg.vlr_Base_icms_2 > 0 or reg.vlr_Base_icms_3 > 0 then

                   update dwt_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = reg.cst_icms)
                     where ident_item_merc = reg.ident_item_merc
                       and ident_docto_fiscal = reg.ident_docto_fiscal;

                    update x08_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = reg.cst_icms)
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;
                 end if;
           -- termino do cst da base isenta e outras

           -- tratando a substituic?o tributaria
            if reg.base_st  = 'S' and  reg.vlr_tributo_icmss > 0 then

                   update dwt_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = reg.cst_st)
                     where ident_item_merc = reg.ident_item_merc
                       and ident_docto_fiscal = reg.ident_docto_fiscal;

                    update x08_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = reg.cst_st)
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;

            end if;
              -- termino do cst de st

-- tratamento especifico para o CFOP 5201 para base isentas e outras
                 if reg.cod_cfo = '5201' then
                    if reg.vlr_Base_icms_2 > 0  then

                   update dwt_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = '51')
                     where ident_item_merc = reg.ident_item_merc
                       and ident_docto_fiscal = reg.ident_docto_fiscal;

                    update x08_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = '51')
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;
                      end if;

                  if  reg.vlr_Base_icms_3 > 0 then
                   update dwt_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = '90')
                     where ident_item_merc = reg.ident_item_merc
                       and ident_docto_fiscal = reg.ident_docto_fiscal;

                    update x08_itens_merc set ident_situacao_b =
                                 (select ident_situacao_b
                                    from y2026_sit_trb_uf_b
                                   where cod_situacao_b = '90')
                     where cod_empresa = reg.cod_empresa
                       and cod_estab = reg.cod_estab
                       and data_fiscal = reg.data_fiscal
                       and movto_e_s = reg.movto_E_s
                       and norm_dev = reg.norm_dev
                       and ident_docto = reg.ident_docto
                       and ident_fis_jur = reg.ident_fis_jur
                       and num_docfis = reg.num_docfis
                       and serie_docfis = reg.serie_docfis
                       and sub_serie_docfis = reg.sub_serie_docfis
                       and discri_item = reg.discri_item;
                      end if;
              end if;

      end loop;

     commit;

--  ****************************** gerando a SAFX245 ************************

-- primeiro deleta dados que houver de importac?o anterior
delete safx245 where cod_Empresa = c_empresa
   and cod_Estab = c_estab;

delete efd_reg_e115
 where cod_Empresa = c_empresa
   and cod_Estab = c_estab
   and data_ini = pDt_Ini
   and data_fim = pDt_Fim;
commit;

-- ******************   insere dados da tela *********
 -- valor do faturamento
 w_sequencial := w_sequencial + 1;
insert into safx245
  (cod_empresa,
   cod_estab,
   insc_estadual,
   data_ini,
   data_fim,
   sequencial,
   cod_inf_adic,
   vlr_inf_adic,
   dsc_compl,
   ind_sub_apur,
   dat_gravacao)
values
  (c_empresa,
   c_estab,
   '@',
   to_char(pDt_Ini, 'yyyymmdd'),
   to_char(pDt_Fim, 'yyyymmdd'),
   w_sequencial,
   'RS000031',
   trunc(vlr_faturamento * 100),
   'Valor Faturamento',
   '@',
   sysdate);

-- valor da folha
 w_sequencial := w_sequencial + 1;
insert into safx245
  (cod_empresa,
   cod_estab,
   insc_estadual,
   data_ini,
   data_fim,
   sequencial,
   cod_inf_adic,
   vlr_inf_adic,
   dsc_compl,
   ind_sub_apur,
   dat_gravacao)
values
  (c_empresa,
   c_estab,
   '@',
   to_char(pDt_Ini, 'yyyymmdd'),
   to_char(pDt_Fim, 'yyyymmdd'),
   w_sequencial,
   'RS000033',
   trunc(vlr_salarios * 100),
   'Valor Folha de Salarios',
   '@',
   sysdate);

   -- numero de empregados
    w_sequencial := w_sequencial + 1;
   insert into safx245
  (cod_empresa,
   cod_estab,
   insc_estadual,
   data_ini,
   data_fim,
   sequencial,
   cod_inf_adic,
   vlr_inf_adic,
   dsc_compl,
   ind_sub_apur,
   dat_gravacao)
values
  (c_empresa,
   c_estab,
   '@',
   to_char(pDt_Ini, 'yyyymmdd'),
   to_char(pDt_Fim, 'yyyymmdd'),
   w_sequencial,
   'RS000032',
   trunc(nr_func * 100),
   'Nr de Funcionarios',
   '@',
   sysdate);

-- criando a SAFX245 depois da alterac?o das bases e CST
-- Primeiro todos os CFOPs menos os 949 que devem ser abertos por natureza (e tambem tirei o cfop 5201 pois tem tratamento diferenciado)
begin
for reg2 in ( select a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     f.e115,
                     sum(b.vlr_base_icms_2 + b.vlr_base_icms_4) base_isenta,
                     sum(b.vlr_Base_icms_3) base_outras
                from dwt_itens_merc b, dwt_docto_fiscal a, x2012_cod_fiscal c,
                     brl_param_e115t_cproc f -- tabela criada para o deXpara
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_cfo = c.ident_cfo
                 and c.cod_cfo = f.cfop
                 and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and a.cod_estab = nvl(c_estab, a.cod_estab)
                 and a.data_fiscal between pDt_Ini and pDt_fim
                 and a.situacao = 'N'
                 and (a.movto_e_S  = '9' and substr(c.cod_cfo,2,3) not in ('949') and c.cod_cfo <> '5201')
                 group by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     f.e115
                 order by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo) loop

               if reg2.base_isenta > 0 then

                 w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        reg2.e115,
                        trunc((reg2.base_isenta) * 100),
                        reg2.cod_cfo || '- Base Isentas',
                        '@',
                        sysdate);
                 end if;
                 if reg2.base_outras > 0 then
                   w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        reg2.e115,
                        trunc((reg2.base_outras) * 100),
                        reg2.cod_cfo || '- Base Outras',
                        '@',
                        sysdate);
                   end if;

   end loop;

-- segundo - os CFOPs 949 que devem ser abertos por natureza


for reg3 in ( select a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     d.descricao,
                     f.e115,
                     sum(b.vlr_base_icms_2 + b.vlr_base_icms_4) base_isenta,
                     sum(b.vlr_Base_icms_3) base_outras
                from dwt_itens_merc b, dwt_docto_fiscal a, x2012_cod_fiscal c, x2006_natureza_op d,
                     brl_param_e115t_cproc f -- tabela criada para o deXpara
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_natureza_op = d.ident_natureza_op
                 and b.ident_cfo = c.ident_cfo
                 and c.cod_cfo = f.cfop
                 and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and a.cod_estab = nvl(c_estab, a.cod_estab)
                 and a.data_fiscal between pDt_Ini and pDt_fim
                 and a.situacao = 'N'
                 and (a.movto_e_S  = '9' and substr(c.cod_cfo,2,3)  in ('949'))
                 group by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     d.descricao,
                     f.e115
                 order by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo) loop

               if reg3.base_isenta > 0 then

                 w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        reg3.e115,
                        trunc((reg3.base_isenta) * 100),
                        reg3.cod_cfo || reg3.descricao,
                        '@',
                        sysdate);
                 end if;
                 if reg3.base_outras > 0 then
                   w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        reg3.e115,
                        trunc((reg3.base_outras) * 100),
                        reg3.cod_cfo || reg3.descricao,
                        '@',
                        sysdate);
                   end if;

   end loop;

  -- terceiro - tratando o cfop 5201
  for reg4 in ( select a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     sum(b.vlr_base_icms_2 + b.vlr_base_icms_4) base_isenta,
                     sum(b.vlr_Base_icms_3 + b.vlr_tributo_ipi) base_outras -- soma o valor do IPI
                from dwt_itens_merc b, dwt_docto_fiscal a, x2012_cod_fiscal c
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_cfo = c.ident_cfo
                 and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and a.cod_estab = nvl(c_estab, a.cod_estab)
                 and a.data_fiscal between pDt_Ini and pDt_fim
                 and a.situacao = 'N'
                 and a.movto_e_S  = '9'
                 and c.cod_cfo = '5201'
                 group by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo
                 order by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo) loop

               if reg4.base_isenta > 0 then

                 w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        'RS051091',
                        trunc((reg4.base_isenta) * 100),
                        reg4.cod_cfo || '- Base Isentas',
                        '@',
                        sysdate);
                 end if;
                 if reg4.base_outras > 0 then
                   w_sequencial := w_sequencial + 1;
                     insert into safx245
                       (cod_empresa,
                        cod_estab,
                        insc_estadual,
                        data_ini,
                        data_fim,
                        sequencial,
                        cod_inf_adic,
                        vlr_inf_adic,
                        dsc_compl,
                        ind_sub_apur,
                        dat_gravacao)
                     values
                       (c_empresa,
                        c_estab,
                        '@',
                        to_char(pDt_Ini, 'yyyymmdd') ,
                        to_char(pDt_Fim, 'yyyymmdd') ,
                        w_sequencial,
                        'RS052999',
                        trunc((reg4.base_outras) * 100),
                        reg4.cod_cfo || '- Base Outras',
                        '@',
                        sysdate);
                   end if;

   end loop;

   end;

       commit;

-- criando o relatorio

begin

   for rel in ( select a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     a.num_docfis,
                     b.num_item,
                     a.data_fiscal,
                     g.cod_fis_jur,
                     g.razao_social,
                     e.cod_situacao_b,
                     sum(b.vlr_base_icms_2 + b.vlr_base_icms_4) base_isenta,
                     sum(b.vlr_Base_icms_3) base_outras,
                     sum(b.vlr_tributo_ipi) vlr_ipi
                from dwt_itens_merc b, dwt_docto_fiscal a, x2012_cod_fiscal c,
                      y2026_sit_trb_uf_b e,  x04_pessoa_fis_jur g
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_cfo = c.ident_cfo
                 and b.ident_situacao_b = e.ident_situacao_b
                 and a.ident_fis_jur =g.ident_fis_jur
                 and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and a.cod_estab = nvl(c_estab, a.cod_estab)
                 and a.data_fiscal between pDt_Ini and pDt_fim
                 and a.situacao = 'N'
                 and a.movto_e_S  = '9'
                 and (b.vlr_base_icms_2 + b.vlr_base_icms_4 + b.vlr_Base_icms_3) > 0
                 group by a.cod_empresa,
                     a.cod_estab,
                     c.cod_cfo,
                     e.cod_situacao_b,
                     a.num_docfis,
                     b.num_item,
                     a.data_fiscal,
                     g.cod_fis_jur,
                     g.razao_social
                 order by a.cod_empresa,
                     a.cod_estab,
                     a.data_fiscal,
                     a.num_docfis,
                     b.num_item,
                     c.cod_cfo
                     ) loop

     BEGIN
      SELECT e115
        INTO W_e115
        FROM brl_param_e115t_cproc
       WHERE CFOP = REL.COD_CFO;
     EXCEPTION WHEN NO_DATA_FOUND THEN
       w_e115 := 'FALTA PARAMETRIZACAO';
     END;

      IF rel.base_isenta > 0 THEN -- ABRI PARA APARECER O VA OU O VB
          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  to_char(rel.data_fiscal, 'dd/mm/rrrr'), 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.num_docfis, 12);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.num_item, 24);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_fis_jur, 29);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel.razao_social,1,30), 41);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_cfo, 71);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel.cod_situacao_b, 77);
          mLinha := LIB_STR.w(mLinha,  '| ' ||formata_valor(rel.base_isenta, 14), 81);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel.base_outras, 14), 98);
          if rel.cod_cfo = '5201' then
             mLinha := LIB_STR.w(mLinha,  '|' ||'RS051091', 115);
          else
             mLinha := LIB_STR.w(mLinha,  '|' ||w_e115, 115);
          end if;
     ELSE
          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  to_char(rel.data_fiscal, 'dd/mm/rrrr'), 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.num_docfis, 12);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.num_item, 24);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_fis_jur, 29);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel.razao_social,1,30), 41);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_cfo, 71);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel.cod_situacao_b, 77);
          mLinha := LIB_STR.w(mLinha,  '| ' ||formata_valor(rel.base_isenta, 14), 81);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel.base_outras, 14), 98);
          if rel.cod_cfo = '5201' then
             mLinha := LIB_STR.w(mLinha,  '|' ||'RS052999', 115);
          else
             mLinha := LIB_STR.w(mLinha,  '|' ||w_e115, 115);
          end if;
     END IF;

      LIB_PROC.add(mLinha, null, null, 1);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 1);

      end loop;
end;


-- chama a importac?o automatica para importar esta safx245
-- IMPORTACAO AUTOMATICA

      PAR_COD_EMPRESA_W   := mcod_empresa;

      PAR_COD_PROG_W      := 1; -- Codigo da programacao feita no MasterSAF para importacao da safx245

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


    LIB_PROC.CLOSE();
    RETURN mproc_id;

  end;

  PROCEDURE Cabecalho(c_estab varchar2, prel varchar2) IS

  BEGIN

    if vn_linhas >= 49 then

      -- Imprime cabecalho do log
      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'Filial : ' || c_estab || ' - ' ||
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
                            'Dados gerados na SAFX245 para o E115 do SPED Fiscal para GIA do RS',
                            50);
      end if;

      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Dt Fiscal', 2);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 12);
        mLinha := LIB_STR.w(mLinha, '|Item', 24);
        mLinha := LIB_STR.w(mLinha, '|Cod Fis Jur', 29);
        mLinha := LIB_STR.w(mLinha, '|Razao Social', 41);
        mLinha := LIB_STR.w(mLinha, '|CFOP', 71);
        mLinha := LIB_STR.w(mLinha, '|CST', 77);
        mLinha := LIB_STR.w(mLinha, '|Vlr Base Isentas', 81);
        mLinha := LIB_STR.w(mLinha, '|Vlr Base Outras', 98);
        mLinha := LIB_STR.w(mLinha, '|COD E115 - VA/VB', 115);

        LIB_PROC.add(mLinha, null, null, prel);

      end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      vn_linhas := 7;

      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_E115_CPROC;
/
