CREATE OR REPLACE PACKAGE BRL_CRIA_E113_CPROC IS

  -- Purpose : Cria lancamento para o E113 do SPED Fiscal para empresas no RS

  /* VARIaVEIS DE CONTROLE DE CABE?ALHO DE RELAToRIO */
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

END BRL_CRIA_E113_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_CRIA_E113_CPROC IS

  mcod_empresa    empresa.cod_empresa%TYPE;
  vs_razao_social estabelecimento.razao_social%TYPE;
  vn_cnpj         varchar2(25);
  mLinha          VARCHAR2(500);
  vn_pagina       number := 1;
  vn_linhas       number := 0;
  w_sequencial    number :=0;

 -- variaveis da importac?o automatica...
  PAR_COD_EMPRESA_W   VARCHAR2(3);
  PAR_COD_PROG_W      NUMBER;
  PAR_DATA_PROC_W     DATE;
  PAR_IND_GRAVA_W     VARCHAR(1);
  PAR_IND_DATA_W      VARCHAR(1);
  PAR_GRAVA_LOG_W     VARCHAR(1);
  PAR_DSC_DIRETORIO_W VARCHAR2(500);
  PAR_MENS_ERR        VARCHAR2(500);

-- variaveis necessarias
W_AUX                NUMBER:=0;


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
                        'SELECT cod_empresa, cod_empresa||'' - ''||razao_social FROM empresa WHERE  cod_empresa = ''' ||
                       mcod_empresa || '''');

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
                       '  a.cod_empresa = :1 and ident_estado in (select ident_estado from estado where cod_estado = ''RS'') ORDER BY a.cod_estab');

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


    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Gera o Lancamento no livro de Apurac?o do ICMS e o Registro E113 do SPED FISCAL';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Seleciona todas as NF de importac?o do mes e faz os lancamentos automaticos.';
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
                    pDt_Fim   DATE)
                    RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id     INTEGER;


    cursor cur_e111 is
     select  a.cod_empresa,
             a.cod_estab,
             sum(b.VLR_ICMS_NDESTAC) valor
        from dwt_docto_fiscal a, dwt_itens_merc b, x2012_cod_fiscal c
       where a.ident_docto_fiscal = b.ident_docto_fiscal
         and a.situacao = 'N'
         and b.ident_cfo = c.ident_cfo
         and (c.cod_cfo like '3%' and c.cod_cfo not in ('3551', '3556','3949'))
         and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
   and a.cod_estab = nvl(c_estab, a.cod_estab)
         and a.data_fiscal between pDt_Ini and pDt_fim
       group by a.cod_empresa, a.cod_estab;



    cursor cur_e113 is
      select a.cod_empresa,
                   a.cod_estab,
                   a.data_fiscal,
                   a.movto_e_s,
                   a.norm_dev,
                   e.cod_docto,
                   d.ind_fis_jur,
                   d.cod_fis_jur,
                   d.razao_social,
                   a.num_docfis,
                   a.serie_docfis,
                   a.sub_serie_docfis,
                   a.ident_docto_fiscal,
                   b.discri_item,
                   b.num_item,
                   a.num_controle_docto,
                   c.cod_cfo,
                   b.VLR_ICMS_NDESTAC valor
              from dwt_docto_fiscal a, dwt_itens_merc b, x2012_cod_fiscal c, x04_pessoa_fis_jur d, x2005_tipo_docto e
             where a.ident_docto_fiscal = b.ident_docto_fiscal
               and a.ident_fis_jur = d.ident_fis_jur
               and a.ident_docto = e.ident_docto
               and a.situacao = 'N'
               and b.ident_cfo = c.ident_cfo
               and (c.cod_cfo like '3%' and c.cod_cfo not in ('3551', '3556','3949'))
               and a.cod_empresa = nvl(c_empresa, a.cod_empresa)
               and a.cod_estab = nvl(c_estab, a.cod_estab)
               and a.data_fiscal between pDt_Ini and pDt_fim
       order by a.data_fiscal, a.num_docfis, b.num_item;



  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_CRIA_E113_CPROC', 48, 150);

    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Notas Fiscais incluidas no Livro P9',
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

-- primeiro deleta dados que houver de importac?o anteriores
delete safx216 where cod_empresa = mcod_empresa
         and cod_estab = c_estab;
delete safx218 where cod_empresa = mcod_empresa
         and cod_estab = c_estab;

commit;




--  ******************** insere dados das notas fiscais *************
for reg111 in cur_e111 loop

    insert into safx216
      (COD_EMPRESA,
       COD_ESTAB,
       COD_TIPO_LIVRO,
       DAT_APURACAO,
       IND_TP_APUR,
       COD_OPER_APUR,
       NUM_DISCRIMINACAO,
       VAL_ITEM_DISCRIM,
       DSC_ITEM_APURACAO,
       COD_AJUSTE_ICMS,
       IND_TIPO_LANC,
       DAT_GRAVACAO
)
    VALUES
      (reg111.cod_empresa,
       reg111.cod_estab,
       '108',
       to_char(last_day (pDt_fim), 'yyyymmdd'),
       '1', -- Apurac?o do ICMS
       '006', -- Outros Creditos
       '1', -- apenas este lancamento
       trunc(reg111. valor * 100),
       'CREDITOS REF IMPORTAC?ES',
       'RS020002', -- codigo definido na legislac?o do RS para o sped fiscal
       '2', -- pois existe safx218
       SYSDATE);

end loop;

commit;


 for reg113 in cur_e113 loop

 w_sequencial := w_sequencial + 1;

 insert into safx218
      (COD_EMPRESA,
       COD_ESTAB,
       COD_TIPO_LIVRO,
       DAT_APURACAO,
       IND_TP_APUR,
       COD_OPER_APUR,
       NUM_DISCRIMINACAO,
       DATA_FISCAL,
       MOVTO_E_S,
       NORM_DEV,
       COD_DOCTO,
       IND_FIS_JUR,
       COD_FIS_JUR,
       NUM_DOCFIS,
       SERIE_DOCFIS,
       SUB_SERIE_DOCFIS,
       NUM_ITEM,
       VLR_AJUSTE,
       DAT_GRAVACAO,
       NUM_SEQUENCIAL)
    VALUES
      (reg113.cod_empresa,
       reg113.cod_estab,
       '108', -- livro p9
       to_char(last_day(pDt_fim), 'yyyymmdd'),
       '1', --Apurac?o do ICMS
       '006', --Outros Creditos
       '1', -- apenas este lancamento. este campo e chave com a safx216
       to_char(reg113.data_fiscal, 'yyyymmdd'),
       reg113.MOVTO_E_s,
       reg113.norm_dev,
       reg113.cod_docto,
       reg113.ind_fis_jur,
       reg113.cod_fis_jur,
       reg113.num_docfis,
       reg113.serie_docfis,
       reg113.sub_serie_docfis,
       reg113.num_item,
       trunc(reg113.valor*100),
       sysdate,
       w_sequencial);

   -- criando o relatorio

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  reg113.cod_estab, 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||to_char(reg113.data_fiscal, 'dd/mm/rrrr'), 7);
          mLinha := LIB_STR.w(mLinha,  '|' ||reg113.num_docfis, 18);
          mLinha := LIB_STR.w(mLinha,  '|' ||reg113.cod_fis_jur, 30);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(reg113.razao_social,1,30), 42);
          mLinha := LIB_STR.w(mLinha,  '|' ||reg113.cod_cfo, 72);
          mLinha := LIB_STR.w(mLinha,  '|' ||reg113.num_item, 80);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(reg113.valor, 14), 90);


      LIB_PROC.add(mLinha, null, null, 1);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 1);


 end loop;

  commit;



-- chama a importac?o automatica para importar esta safx216 e 218
-- IMPORTAC?O AUTOMATICA


      SELECT COUNT(*)
      INTO W_AUX
      FROM SAFX216;

  IF W_AUX > 0 THEN
  null;

   IF c_empresa = '004' THEN
      PAR_COD_EMPRESA_W   := '004';
      PAR_COD_PROG_W      := 8; -- COdigo da programac?o feita no MasterSAF para importac?o da safx216 e 218
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

    END IF;

  END IF;

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
                            'Notas Fiscais incluidas no Livro P9',
                            50);
      end if;


      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Estab', 2);
        mLinha := LIB_STR.w(mLinha, '|Dt Fiscal', 7);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 18);
        mLinha := LIB_STR.w(mLinha, '|Cod Fis Jur', 30);
        mLinha := LIB_STR.w(mLinha, '|Razao Social', 42);
        mLinha := LIB_STR.w(mLinha, '|CFOP', 72);
        mLinha := LIB_STR.w(mLinha, '|Num Item', 80);
        mLinha := LIB_STR.w(mLinha, '|Valor', 90);

        LIB_PROC.add(mLinha, null, null, prel);

     end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      vn_linhas := 7;

      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_CRIA_E113_CPROC;
/
