CREATE OR REPLACE PACKAGE BRL_AJUSTA_NF_IMPORTACAO_CPROC IS

  -- Purpose : Troca a base tribuitada do ICMS das Notas Fiscais de Importac?o

  /* VARIAVEIS DE CONTROLE DE CABECALHO DE RELAT?RIO */
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
                    pDt_Fim   DATE) RETURN INTEGER;

  PROCEDURE Cabecalho(c_estab varchar2, prel varchar2);

END BRL_AJUSTA_NF_IMPORTACAO_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_AJUSTA_NF_IMPORTACAO_CPROC IS

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

    Lib_Proc.Add_Param(pstr,
                       'Empresa          ',
                       'VARCHAR2',
                       'combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT a.cod_empresa, a.cod_empresa||'' - ''||a.razao_social FROM empresa a ORDER BY a.cod_empresa');
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
                       '  a.cod_empresa = :1 and ident_estado = 73 ORDER BY a.cod_estab');
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
                       '************ Este customizado altera as situacoes abaixo: **************',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

 Lib_Proc.Add_Param(pstr,
                       '1 - Troca base tributada do ICMS para base outras do ICMS.',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
 Lib_Proc.Add_Param(pstr,
                       '2 - Coloca o Valor ICMS para Valor Nao Destacado.',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'AJUSTA NOTAS FISCAIS DE IMPORTACAO SO PARA O RS';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'AJUSTA NOTAS FISCAIS DE IMPORTACAO SO PARA O RS';
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
                    pDt_Fim   DATE) RETURN INTEGER IS

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
             a.vlr_base_icms_1  base_icms_capa,
             a.vlr_base_icms_2  base_icms_capa_2,
             a.vlr_base_icms_3  base_icms_capa_3,
             a.vlr_base_icms_4  base_icms_capa_4,             
             a.vlr_tributo_icms icms_capa,
             b.discri_item,
             b.num_item,
             B.VLR_CONTAB_ITEM,
             b.ident_item_merc,
             b.vlr_base_icms_1,
             b.vlr_base_icms_2,
             b.vlr_Base_icms_3,
             b.vlr_base_icms_4,
             b.vlr_tributo_icms,
             b.vlr_icms_ndestac
        from dwt_docto_fiscal a, dwt_itens_merc b, x2012_cod_fiscal c, x07_docto_fiscal d
       where a.ident_docto_fiscal = b.ident_docto_fiscal
         and a.cod_empresa = d.cod_empresa
         and a.cod_estab = d.cod_estab
         and a.data_fiscal = d.data_fiscal
         and a.movto_e_s = d.movto_E_s
         and a.norm_dev = d.norm_dev
         and a.ident_docto = d.ident_docto
         and a.ident_fis_jur = d.ident_fis_jur
         and a.num_docfis = d.num_docfis
         and a.serie_docfis = d.serie_docfis
         and a.sub_serie_docfis = d.sub_serie_docfis
         and a.situacao = 'N'
         and b.ident_cfo = c.ident_cfo
         and c.cod_cfo like '3%'
         and b.vlr_base_icms_1 > 0
         and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
         and a.cod_estab = nvl(c_estab, a.cod_estab)
         and a.data_fiscal between pDt_Ini and pDt_fim
         order by a.data_fiscal, a.num_docfis, b.num_item;


  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_AJUSTA_NF_IMPORTACAO_CPROC', 48, 150);

    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Notas Fiscais de Importacao so para o RS',
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

  for reg in cur_movtos loop

   IF reg.vlr_base_icms_1 > 0 then

    update dwt_itens_merc set vlr_BASE_ICMS_1 = 0,
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

    update x08_trib_merc
       set vlr_tributo  = 0,
           aliq_tributo = 0
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
       set VLR_ICMS_NDESTAC =  reg.vlr_tributo_icms
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

     -- alterando a capa da nota fiscal

    update dwt_docto_fiscal  set vlr_BASE_ICMS_1 = 0,
       vlr_base_icms_3 = reg.base_icms_capa,
       vlr_tributo_icms = 0,
       VLR_ICMS_NDESTAC = reg.icms_capa
     where ident_docto_fiscal = reg.ident_docto_fiscal;

-- a NF pode ter mais de 1 base na capa, entao vamos precisar somar
-- nf de exemplo na bausch = 000004139 de 05/06/2018

   if  reg.base_icms_capa > 0 and ( reg.base_icms_capa_2+  reg.base_icms_capa_3 +  reg.base_icms_capa_4) >0 then
    -- vamos deletar as demais bases e depois vamos somar todas as bases
       delete x07_base_docfis
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
          AND COD_TRIBUTACAO <> '1'
          AND COD_TRIBUTO IN ('ICMS');
          	 
      update x07_base_docfis
         set COD_TRIBUTACAO = '3',
             vlr_base       = nvl(reg.base_icms_capa,0)   +
                              nvl(reg.base_icms_capa_2,0) +
                              nvl(reg.base_icms_capa_3,0) +
                              nvl(reg.base_icms_capa_4,0)
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
         AND COD_TRIBUTACAO = '1'
         AND COD_TRIBUTO IN ('ICMS');
         
    else     
    update x07_base_docfis
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
       AND COD_TRIBUTACAO = '1'
       AND COD_TRIBUTO IN ('ICMS');

     end if;

    update x07_trib_docfis
       set vlr_tributo  = 0,
           aliq_tributo = 0
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
       AND COD_TRIBUTO IN ('ICMS');

    update x07_docto_fiscal
       set VLR_ICMS_NDESTAC =  reg.icms_capa
     where cod_empresa = reg.cod_empresa
       and cod_estab = reg.cod_estab
       and data_fiscal = reg.data_fiscal
       and movto_e_s = reg.movto_E_s
       and norm_dev = reg.norm_dev
       and ident_docto = reg.ident_docto
       and ident_fis_jur = reg.ident_fis_jur
       and num_docfis = reg.num_docfis
       and serie_docfis = reg.serie_docfis
       and sub_serie_docfis = reg.sub_serie_docfis;

   end if;


   -- todas as notas selecionadas tendo ou nao tendo alterac?o, vao aparecer no relatorio

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,  to_char(reg.data_fiscal,'dd/mm/rrrr'), 2);
      mLinha := LIB_STR.w(mLinha, '|' ||reg.num_docfis, 15);
      mLinha := LIB_STR.w(mLinha, '|' ||reg.num_item, 30);
      mLinha := LIB_STR.w(mLinha, '|' ||formata_valor(reg.vlr_contab_item, 14), 45);
      mLinha := LIB_STR.w(mLinha, '|' ||formata_valor(reg.vlr_base_icms_1, 14), 70);
      mLinha := LIB_STR.w(mLinha, '|' ||formata_valor(reg.vlr_tributo_icms, 14), 100);

      LIB_PROC.add(mLinha, null, null, 1);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 1);


    end loop;

     commit;

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
                            'Notas Fiscais de Importacao',
                            56);
      end if;

      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Data Fiscal', 2);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 15);
        mLinha := LIB_STR.w(mLinha, '|Numero do Item', 30);
        mLinha := LIB_STR.w(mLinha, '|Vlr Contabil do Item', 45);
        mLinha := LIB_STR.w(mLinha, '|Base ICMS Diferido/Outras', 70);
        mLinha := LIB_STR.w(mLinha, '|Valor do ICMS', 100);

        LIB_PROC.add(mLinha, null, null, prel);

      end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      vn_linhas := 7;

      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_AJUSTA_NF_IMPORTACAO_CPROC;
/
