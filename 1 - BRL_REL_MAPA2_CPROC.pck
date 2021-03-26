CREATE OR REPLACE PACKAGE BRL_REL_MAPA2_CPROC IS

  -- Purpose : Gera arquivo de Todas as NF do MSAF

  /* VARIAVEIS DE CONTROLE DE CABECALHO DE RELATORIO */
  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;

  FUNCTION Executar(X_cod_empresa VARCHAR2,
                    x_cod_estab varchar2,
                    pDt_Ini   DATE,
                    pDt_fim   DATE,
                    x_cnpj_cpf varchar2
                    ) RETURN INTEGER;

  PROCEDURE Cabecalho(X_cod_empresa varchar2, prel varchar2);

END BRL_REL_MAPA2_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_REL_MAPA2_CPROC IS

  vs_razao_social estabelecimento.razao_social%TYPE;
  vn_cnpj         varchar2(25);
  mLinha          VARCHAR2(500);
  vn_pagina       number := 1;
  vn_linhas       number := 0;
  cCod_Empresa    EMPRESA.cod_empresa%TYPE;

w_cod_estado_orig           estado.cod_estado%type;
w_descricao_municipio_orig  municipio.descricao%type;
w_cod_estado_dest           estado.cod_estado%type;
w_descricao_municipio_dest  municipio.descricao%type;
w_cod_observacao            x2009_observacao.cod_observacao%type;

w_tipo       brl_lista_material.tipo%TYPE:='0';
w_tipo_desc  varchar2(50):= null;

-- VARIAVEIS PARA GRAVAR O ARQUIVO
  v_arquivo UTL_FILE.FILE_TYPE; -- Data file handle
  v_dir     VARCHAR2(250); -- Directory containing the data file

  CURSOR c_arq is
    select *
      from BRL_REL_MAPA2_T_CPROC;

-- COMECA O PROCEDIMENTO

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN

    cCod_Empresa := Lib_Parametros.RECUPERAR('EMPRESA');

    
    LIB_PROC.add_param(pstr,
                       'Empresa',
                       'Varchar2',
                       'Combobox',
                       'S',
                       null,
                       NULL,
                       'SELECT DISTINCT cod_empresa, cod_empresa||'' - ''||razao_social FROM empresa  WHERE COD_EMPRESA = ''' ||
                    cCod_Empresa || ''' order by 1');

    Lib_Proc.Add_Param(pstr,
                       'Estabelecimento  ',
                       'VARCHAR2(04)',
                       'Combobox',
                       'N',
                       NULL,
                       NULL,
                       'SELECT a.cod_estab, a.cod_estab||'' - ''||a.razao_social|| '' - ''||a.CIDADE FROM estabelecimento a WHERE ' ||
                       '  a.cod_empresa = :1 ORDER BY a.cod_estab');

     Lib_Proc.Add_Param(pstr,
                       'Data Inicial',
                       'DATE',
                       'Textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');

     Lib_Proc.Add_Param(pstr,
                       'Data Final',
                       'DATE',
                       'Textbox',
                       'S',
                       NULL,
                       'DD/MM/YYYY');

  Lib_Proc.Add_Param(pstr,
                       'CNPJ/CPF',
                       'VARCHAR2',
                       'TextBOX',
                       'N',
                       NULL,
                       NULL,
                       NULL);

    Lib_Proc.Add_Param(pstr,
                       '',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    Lib_Proc.Add_Param(pstr,
                       '****************************************************************************************************************************************************************************',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    Lib_Proc.Add_Param(pstr,
                       '   ESTA VERSAO 2 ABRE TELA PARA GRAVAR O ARQUIVO EM QUALQUER DIRETORIO',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    Lib_Proc.Add_Param(pstr,
                       '****************************************************************************************************************************************************************************',
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
    RETURN 'Relatorio MAPA2 das NFs';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorio MAPA2 das NFs';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED';
  END;

  FUNCTION Executar(X_cod_empresa VARCHAR2,
                    x_cod_Estab   Varchar2,
                    pDt_Ini   DATE,
                    pDt_fim   DATE,
                    x_cnpj_cpf varchar2) RETURN INTEGER IS

    /* Variaveis de Trabalho */
    mproc_id        INTEGER;

  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_REL_MAPA2_CPROC', 48, 150);
   /* LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Relatorio MAPA2 das NFs',
                      1);*/
    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Relatorio MAPA2 das NFs',
                      2);


    begin
      select substr(cgc, 1, 2) || '.' || substr(cgc, 3, 3) || '.' ||
             substr(cgc, 6, 3) || '/' || substr(cgc, 9, 4) || '-' ||
             substr(cgc, 13, 2) cgc,
             --cod_estab || ' - ' ||
             estab.razao_social razao_social
        into vn_cnpj, vs_razao_social
        from estabelecimento estab
       where cod_empresa = x_cod_empresa
         AND ind_matriz_filial = 'M'
       order by cod_empresa;
    exception
      when no_data_found then
        vn_cnpj         := null;
        vs_razao_social := null;
    end;

    -- Inicializa variaveis
    vn_pagina := 1;
    vn_linhas := 50;
    Cabecalho(X_cod_empresa, 1); -- cabecalho do relatorio



-- criando relatorio

     delete BRL_REL_MAPA2_T_CPROC where 1 =1;
     commit;

-- inserindo cabe?alho;
insert into  BRL_REL_MAPA2_T_CPROC values('TIPO$CLASS_DOC_FIS$EMPRESA$ESTAB$MOVTO_E_S$NORM_DEV$DATA_FISCAL$DATA_EMISSAO$PESSOA$RAZAO_SOCIAL$CNPJ_CPF$NUM_NF$SERIE_NF$CHAVE_NFE$NUM_ITEM$MATERIAL_SERVICO$DESCRICAO$NCM$CFOP$NATUREZA_OP$DESCRICAO_OP$QUANTIDADE$VLR_DESCONTO$VLR_TOTAL$VLR_ITEM$VLR_BASE_ICMS_1$VLR_BASE_ICMS_2$VLR_BASE_ICMS_3$VLR_BASE_ICMS_4$CST_ICMS$ALIQ_ICMS$VLR_ICMS$VLR_BASE_IPI_1$VLR_BASE_IPI_2$VLR_BASE_IPI_3$VLR_BASE_IPI_4$ALIQ_IPI$VLR_IPI$COD_SITUACAO_PIS$COD_SITUACAO_COFINS$DT_LANCTO_PIS_COFINS$VLR_BASE_PIS$VLR_BASE_COFINS$ALIQ_PIS$ALIQ_COFINS$VLR_PIS$VLR_COFINS$DIF_ALIQ$ICMS_NDESTAC$VLR_ISS$VLR_INSS_RETIDO$DESCRICAO_COMPL$CONTA_CONTABIL$VLR_FCP_UF_DESTINO$VLR_ICMS_UF_DESTINO$VLR_ICMS_UF_ORIGEM$UF_DESTINO$MUNICIPIO_DEST$UF_ORIGEM$MUNICIPIO_ORIG$OBSERVACAO_ICMS$VLR_ICMS_ST$GRUPO_MATERIAL');
                           


      for reg in ( SELECT 'M' TIPO,
       A.IDENT_DOCTO_FISCAL IDENT_DOCTO_FISCAL,
       B.IDENT_ITEM_MERC IDENT_ITEM,
       A.COD_CLASS_DOC_FIS COD_CLASS_DOC_FIS,
       a.cod_empresa cod_empresa,
       a.cod_estab COD_ESTAB,
       A.MOVTO_E_S MOVTO_E_S,
       A.NORM_DEV NORM_DEV,
       A.IDENT_FIS_JUR IDENT_FIS_JUR,
       A.SERIE_DOCFIS SERIE_DOCFIS,
       A.SUB_SERIE_DOCFIS SUB_SERIE_DOCFIS,
       A.IDENT_DOCTO IDENT_DOCTO,
       a.data_fiscal DATA_FISCAL,
       a.data_emissao DATA_eMISSAO,
       C.COD_FIS_JUR COD_FIS_JUR,
       C.RAZAO_SOCIAL RAZAO_SOCIAL,
       C.CPF_CGC CPF_CGC,
       A.NUM_DOCFIS NUM_DOCFIS,
       A.NUM_AUTENTIC_NFE,
       B.NUM_ITEM NUM_ITEM,
       D.COD_PRODUTO MATERIAL,
       D.DESCRICAO DESCRICAO,
       F.COD_NBM COD_NBM,
       E.COD_CFO COD_CFO,
       B.COD_SITUACAO_PIS COD_SITUACAO_PIS,
       B.COD_SITUACAO_COFINS COD_SITUACAO_COFINS,
       b.dat_lanc_pis_cofins dat_lanc_pis_cofins,
       B.VLR_BASE_PIS VLR_BASE_PIS,
       B.VLR_BASE_COFINS VLR_BASE_COFINS,
       B.VLR_DESCONTO VLR_DESCONTO,
       B.VLR_CONTAB_ITEM VLR_TOT,
       B.VLR_ITEM VLR_ITEM,
       B.VLR_TRIBUTO_ICMS VLR_TRIBUTO_ICMS,
       B.VLR_TRIBUTO_IPI VLR_TRIBUTO_IPI,
       B.VLR_ALIQ_PIS ALIQ_PIS,
       B.VLR_ALIQ_COFINS ALIQ_COFINS,
       B.VLR_PIS VLR_PIS,
       B.VLR_COFINS VLR_COFINS,
       b.vlr_outros1 DIF_ALIQ,
       b.vlr_icms_ndestac VLR_ICMS_NNDESTAC,
       0 vlr_tributo_iss,
       0 vlr_inss_retido,
       '0' descricao_compl,
       COD_CONTA,
       b.quantidade quantidade,
       b.vlr_base_icms_1,
       b.vlr_base_icms_2,
       b.vlr_base_icms_3,
       b.vlr_base_icms_4,
       H.COD_SITUACAO_A,
       I.COD_SITUACAO_B,
       b.vlr_fcp_uf_dest,
       b.vlr_icms_uf_dest,
       b.vlr_icms_uf_orig,
       a.ident_uf_orig_dest,
       a.cod_municipio_orig,
       a.ident_uf_destino,
       a.cod_municipio_dest,
       j.cod_natureza_op,
       J.DESCRICAO DESCRICAO_OP,
       B.ALIQ_TRIBUTO_ICMS,
       B.ALIQ_TRIBUTO_IPI,
       b.vlr_base_ipi_1,
       b.vlr_base_ipi_2,
       b.vlr_base_ipi_3,
       b.vlr_base_ipi_4,
       B.IDENT_OBSERVACAO,
       b.vlr_tributo_icmss,
       b.vlr_base_icmss,
       b.VLR_FECP_ICMS_ST       
  FROM DWT_DOCTO_FISCAL   A,
       DWT_ITENS_MERC     B,
       X04_PESSOA_FIS_JUR C,
       X2013_PRODUTO      D,
       X2012_COD_FISCAL   E,
       X2043_COD_NBM      F,
       X2002_PLANO_CONTAS G,
       y2025_sit_trb_uf_a h,
       y2026_sit_trb_uf_b i,
       x2006_natureza_op j
 WHERE b.ident_natureza_op = j.ident_natureza_op(+)
   and B.IDENT_CONTA = G.IDENT_CONTA(+)
   AND A.IDENT_FIS_JUR = C.IDENT_FIS_JUR
   AND B.IDENT_NBM = F.IDENT_NBM(+)
   AND B.IDENT_PRODUTO = D.IDENT_PRODUTO
   AND B.IDENT_CFO = E.IDENT_CFO(+)
   AND A.IDENT_DOCTO_FISCAL = B.IDENT_DOCTO_FISCAL
   AND B.IDENT_SITUACAO_A = H.IDENT_SITUACAO_A
   AND B.IDENT_SITUACAO_B = I.IDENT_SITUACAO_B
   AND A.SITUACAO <> 'S'
   AND A.COD_CLASS_DOC_FIS IN ('1', '3', '4')
   and A.cod_empresa = nvl(X_COD_EMPRESA, A.cod_empresa)
   and A.cod_estab = nvl(x_COD_ESTAB, A.cod_estab)
   AND A.DATA_FISCAL BETWEEN pDt_Ini AND pDt_fIM
-- preferi fazer um IF antes de gravar o arquivo cas,o so X_CNPJ_CPF for diferente de null - pois este aqui no select nao gera o arquivo   
--   AND A.ident_fis_jur in (select x.ident_fis_jur from x04_pessoa_fis_jur X where cpf_cgc in (x_cnpj_cpf, x.ident_fis_jur))

UNION
-- servicos
SELECT 'S' TIPO,
       A.IDENT_DOCTO_FISCAL IDENT_DOCTO_FISCAL,
       B.IDENT_ITEM_SERV IDENT_ITEM,
       A.COD_CLASS_DOC_FIS COD_CLASS_DOC_FIS,
       a.cod_empresa COD_EMPRESA,
       a.cod_estab COD_ESTAB,
       A.MOVTO_E_S MOVTO_E_S,
       A.NORM_DEV NORM_DEV,
       A.IDENT_FIS_JUR IDENT_FIS_JUR,
       A.SERIE_DOCFIS SERIE_DOCFIS,
       A.SUB_SERIE_DOCFIS SUB_SERIE_DOCFIS,
       A.IDENT_DOCTO IDENT_DOCTO,
       a.data_fiscal DATA_FISCAL,
       a.data_emissao DATA_EMISSAO,
       C.COD_FIS_JUR COD_FIS_JUR,
       C.RAZAO_SOCIAL RAZAO_SOCIAL,
       C.CPF_CGC CPF_CGC,
       A.NUM_DOCFIS NUM_DOCFIS,
       A.NUM_AUTENTIC_NFE,
       B.NUM_ITEM NUM_ITEM,
       D.COD_servico MATERIAL,
       D.DESCRICAO DESCRICAO,
       '0' COD_NBM,
       E.COD_CFO COD_CFO,
       B.COD_SITUACAO_PIS COD_SITUACAO_PIS,
       B.COD_SITUACAO_COFINS COD_SITUACAO_COFINS,
       b.dat_lanc_pis_cofins dat_lanc_pis_cofins,
       B.VLR_BASE_PIS VLR_BASE_PIS,
       B.VLR_BASE_COFINS VLR_BASE_COFINS,
       B.VLR_DESCONTO VLR_DESCONTO,
       B.VLR_tot VLR_TOT,
       B.VLR_servico VLR_ITEM,
       B.VLR_TRIBUTO_ICMS VLR_TRIBUTO_ICMS,
       0 VLR_TRIBUTO_IPI,
       B.VLR_ALIQ_PIS ALIQ_PIS,
       B.VLR_ALIQ_COFINS ALIQ_COFINS,
       B.VLR_PIS VLR_PIS,
       B.VLR_COFINS VLR_COFINS,
       0 DIF_ALIQ,
       0 vlr_icms_ndestac,
       b.vlr_tributo_iss VLR_TRIBUTO_ISS,
       a.vlr_inss_retido VLR_INSS_RETIDO,
       b.descricao_compl DESCRICAO_COMPL,
       F.COD_CONTA,
       b.quantidade quantidade,
       0 vlr_base_icms_1,
       0 vlr_base_icms_2,
       0 vlr_base_icms_3,
       0 vlr_base_icms_4,
       '' COD_SITUACAO_A,
       '' COD_SITUACAO_B,
       0 vlr_fcp_uf_dest,-- nao existe estes valores nas NF de servico
       0 vlr_icms_uf_dest,
       0 vlr_icms_uf_orig,
       a.ident_uf_orig_dest,
       a.cod_municipio_orig,
       a.ident_uf_destino,
       a.cod_municipio_dest,
       '' cod_natureza_op,
       '' DESCRICAO_OP,
       0 ALIQ_TRIBUTO_ICMS,
       0 ALIQ_TRIBUTO_IPI,
       0 vlr_base_ipi_1,
       0 vlr_base_ipi_2,
       0 vlr_base_ipi_3,
       0 vlr_base_ipi_4,
       B.IDENT_OBSERVACAO,
       0 vlr_tributo_icmss,
       0 vlr_base_icmss,
       0 VLR_FECP_ICMS_ST  
  FROM DWT_DOCTO_FISCAL   A,
       DWT_ITENS_serv     B,
       X04_PESSOA_FIS_JUR C,
       X2018_servicos     D,
       X2012_COD_FISCAL   E,
       X2002_PLANO_CONTAS F
 WHERE B.IDENT_CONTA = F.IDENT_CONTA(+)
   AND A.IDENT_FIS_JUR = C.IDENT_FIS_JUR
   AND B.IDENT_servico = D.IDENT_servico
   AND B.IDENT_CFO = E.IDENT_CFO(+)
   AND A.IDENT_DOCTO_FISCAL = B.IDENT_DOCTO_FISCAL
   AND A.SITUACAO <> 'S'
   AND A.COD_CLASS_DOC_FIS IN ('2', '3')
   and A.cod_empresa = nvl(X_COD_EMPRESA, A.cod_empresa)
   and A.cod_estab = nvl(x_COD_ESTAB, A.cod_estab)
   AND A.DATA_FISCAL BETWEEN pDt_Ini AND pDt_fIM 
 -- preferi fazer um IF para gravar o arquivo caso so X_CNPJ_CPF for diferente de null - pois este aqui no select nao gera o arquivo
 --  AND A.ident_fis_jur in (select z.ident_fis_jur from x04_pessoa_fis_jur z where z.cpf_cgc in (x_cnpj_cpf, z.ident_fis_jur))
 ) loop



-- ALTERAC?O FEITA EM JULHO, POIS A PARTIR DE JULHO/2014 A INTERFACE SAP COMECOU A BUSCAR ESTE VALOR DA CONTABILIDADE. 
  IF REG.DATA_FISCAL < TO_DATE('01/07/2014', 'DD/MM/YYYY') THEN
    if reg.descricao_compl like'%/MONT' then -- so gera de montadores
       reg.vlr_inss_retido := nvl((nvl(reg.vlr_tot,0) * 0.035),0);
     end if;
  END IF;

-- estado e munipio de origem  
begin

select b.cod_estado, a.descricao
  into w_cod_estado_orig, w_descricao_municipio_orig
  from municipio a, estado b
 where a.ident_estado = b.ident_estado
   and a.ident_estado = reg.ident_uf_orig_dest
   and cod_municipio = reg.cod_municipio_orig;

exception when no_data_found then
w_cod_estado_orig := '';
w_descricao_municipio_orig := '';

end;

-- estado e municipio de destino
begin

select b.cod_estado, a.descricao
  into w_cod_estado_dest, w_descricao_municipio_dest
  from municipio a, estado b
 where a.ident_estado = b.ident_estado
   and a.ident_estado = reg.ident_uf_destino
   and cod_municipio = reg.cod_municipio_dest;

exception when no_data_found then
w_cod_estado_dest := '';
w_descricao_municipio_dest := '';

end;

--pegando a observac?o do icms (este campo serve para o de-para do E115 e GIA do RS
begin
  if reg.ident_observacao is not null then
    select cod_observacao
    into w_cod_observacao
    from x2009_observacao
    where ident_observacao = reg.ident_observacao;
  end if;
end;

-- pegando o tipo de material que e parametrizado pelo customizado para saber se o material e de lista positiva e etc.
w_tipo :='0';
w_tipo_desc := null;

begin
select tipo 
into w_tipo
from brl_lista_material
where cod_produto = reg.material;
exception when no_data_found then
w_tipo := '0';
end;
 IF w_tipo = '1' then
   w_tipo_desc:='CORRELATOS';
 end if;
 IF w_tipo = '2' then
   w_tipo_desc:='COSMETICOS';
 end if;
 IF w_tipo = '3' then
   w_tipo_desc:='Exportac?o';
 end if;
IF w_tipo = '4' then
   w_tipo_desc:='Lista Negativa - Revenda';
 end if;
IF w_tipo = '5' then
   w_tipo_desc:='Lista Negativa - Venda';
 end if;
IF w_tipo = '6' then
   w_tipo_desc:='Generico Monofasico';
 end if;
IF w_tipo = '7' then
   w_tipo_desc:='Lista Positiva - Revenda';
 end if;
IF w_tipo = '8' then
   w_tipo_desc:='Lista Positiva -Venda';
 end if;
 
  
if x_cnpj_cpf is null or reg.cpf_cgc = x_cnpj_cpf then
    
    insert into BRL_REL_MAPA2_T_CPROC values(reg.tipo || '$' || reg.cod_class_doc_fis || '$' ||
                         reg.cod_empresa || '$' || reg.cod_estab || '$' ||
                         reg.movto_E_s || '$' || reg.norm_dev || '$' ||
                         reg.data_fiscal || '$' || reg.data_emissao  || '$' ||
                         reg.cod_fis_jur || '$' ||reg.razao_social || '$' ||
                         reg.cpf_cgc || '$' ||reg.num_docfis || '$' ||
                         reg.serie_docfis || '$' ||reg.num_autentic_nfe || '$' ||
                         reg.num_item || '$' ||
                         reg.material || '$' ||reg.descricao || '$' ||
                         reg.cod_nbm || '$' ||reg.cod_cfo || '$' ||
                         reg.cod_natureza_op || '$' ||
                         reg.descricao_op || '$' ||
                         to_char(reg.quantidade,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''')|| '$' ||
                         
                         to_char(reg.vlr_desconto,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         
                         to_char(reg.vlr_tot,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         to_char(reg.vlr_item,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_icms_1,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_icms_2,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_icms_3,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_icms_4,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         reg.cod_situacao_a || reg.cod_situacao_b || '$' ||
                         
                        to_char(reg.aliq_tributo_icms,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
  
                        to_char(reg.vlr_tributo_icms,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_ipi_1,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_ipi_2,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_ipi_3,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_base_ipi_4,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||


                         to_char(reg.aliq_tributo_ipi,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||


                         to_char(reg.vlr_tributo_ipi,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         reg.cod_situacao_pis || '$' ||
                         reg.cod_situacao_cofins || '$' ||
                         reg.dat_lanc_pis_cofins || '$' ||
                         to_char(reg.vlr_base_pis,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         
                         to_char(reg.vlr_base_cofins,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.aliq_pis,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.aliq_cofins,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_pis,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.vlr_cofins,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         to_char(reg.dif_aliq,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         to_char(reg.vlr_icms_nndestac,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         to_char(reg.vlr_tributo_iss,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||
                         to_char(reg.vlr_inss_retido,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||

                         reg.descricao_compl || '$'||
                         reg.cod_conta || '$'||
                         
                         to_char(reg.vlr_fcp_uf_dest,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||


                         to_char(reg.vlr_icms_uf_dest,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$' ||


                         to_char(reg.vlr_icms_uf_orig,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''') || '$'||
                         w_cod_estado_dest || '$'||
                         w_descricao_municipio_dest || '$'||
                         w_cod_estado_orig || '$'||
                         w_descricao_municipio_orig || '$'||
                         w_cod_observacao || '$'||
                         
                         to_char(reg.vlr_tributo_icmss,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''')  || '$'||
                          
                         to_char(reg.vlr_base_icmss,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''')  || '$'||
                          
                          to_char(reg.VLR_FECP_ICMS_ST,
                                                            '9999G999G999G999D' ||
                                                            RPAD('0', 2, '0'),
                                                            'nls_numeric_characters = '',.''')  || '$'||
                                                                
                          w_tipo_desc
                          );

end if;
  

      mLinha := LIB_STR.w('', ' ', 1);

      -- aqui colocaria os dados do relatorio,mas o relatorio sera salvo em arquivo texto
/*      mLinha := Lib_Str.w(mLinha, reg.cod_estab, 2);
      mLinha := Lib_Str.w(mLinha, '|' || reg.data_fiscal, 7);
*/
      LIB_PROC.add(mLinha, null, null, 1);
      vn_linhas := vn_linhas + 1;
      Cabecalho(X_cod_empresa, 1);


     end loop;

    commit;
-- Gravando o Arquivo no diretorio do MSAF

BEGIN

  v_dir := 'SPOOL';
  v_arquivo := UTL_FILE.FOPEN(v_dir, 'MAPA_'|| x_cod_empresa ||'.TXT', 'w');

   UTL_FILE.put_line(v_arquivo, 'TIPO$CLASS_DOC_FIS$EMPRESA$ESTAB$MOVTO_E_S$NORM_DEV$DATA_FISCAL$DATA_EMISSAO$PESSOA$RAZAO_SOCIAL$CNPJ_CPF$NUM_NF$SERIE_NF$CHAVE_NFE$NUM_ITEM$MATERIAL_SERVICO$DESCRICAO$NCM$CFOP$NATUREZA_OP$DESCRICAO_OP$QUANTIDADE$VLR_DESCONTO$VLR_TOTAL$VLR_ITEM$VLR_BASE_ICMS_1$VLR_BASE_ICMS_2$VLR_BASE_ICMS_3$VLR_BASE_ICMS_4$CST_ICMS$ALIQ_ICMS$VLR_ICMS$VLR_BASE_IPI_1$VLR_BASE_IPI_2$VLR_BASE_IPI_3$VLR_BASE_IPI_4$ALIQ_IPI$VLR_IPI$COD_SITUACAO_PIS$COD_SITUACAO_COFINS$DT_LANCTO_PIS_COFINS$VLR_BASE_PIS$VLR_BASE_COFINS$ALIQ_PIS$ALIQ_COFINS$VLR_PIS$VLR_COFINS$DIF_ALIQ$ICMS_NDESTAC$VLR_ISS$VLR_INSS_RETIDO$DESCRICAO_COMPL$CONTA_CONTABIL$VLR_FCP_UF_DESTINO$VLR_ICMS_UF_DESTINO$VLR_ICMS_UF_ORIGEM$UF_DESTINO$MUNICIPIO_DEST$UF_ORIGEM$MUNICIPIO_ORIG$OBSERVACAO_ICMS$VLR_ICMS_ST$VLR_FECP_ICMS_ST$GRUPO_MATERIAL');


-- Crio um novo processo
     mproc_id := lib_proc.new('MAPA2', 60, 155);
-- crio o arquivo
    lib_proc.add_tipo(mproc_id, 1, 'MAPA2_'||x_cod_empresa||'.TXT',2);


  FOR C in c_arq loop

    BEGIN
     -- UTL_FILE.put_line(v_arquivo, C.TEXT);
      lib_proc.add(c.text);---
      
    EXCEPTION
      WHEN no_data_found THEN
        exit;
    END;

  END LOOP;

  UTL_FILE.FCLOSE(v_arquivo);

  COMMIT;

EXCEPTION
  WHEN UTL_FILE.INVALID_OPERATION THEN
    Dbms_Output.Put_Line('Operac?o invalida no arquivo. ');
    UTL_File.Fclose(v_arquivo);
  WHEN UTL_FILE.WRITE_ERROR THEN
    Dbms_Output.Put_Line(' Erro de gravac?o no arquivo. ');
    UTL_File.Fclose(v_arquivo);
  WHEN UTL_FILE.INVALID_PATH THEN
    Dbms_Output.Put_Line(' Diretorio invalido. ');
    UTL_File.Fclose(v_arquivo);
  WHEN UTL_FILE.INVALID_MODE THEN
    Dbms_Output.Put_Line(' Modo de acesso invalido. ');
    UTL_File.Fclose(v_arquivo);
  WHEN Others THEN
    Dbms_Output.Put_Line(' Problemas na gerac?o do arquivo. ');
    UTL_File.Fclose(v_arquivo);
END;


    LIB_PROC.CLOSE();
    RETURN mproc_id;

  end;

--- criando cabecalho do relatorio

  PROCEDURE Cabecalho(X_cod_empresa varchar2, prel varchar2) IS

  BEGIN

    if vn_linhas >= 49 then

      -- Imprime cabecalho do log
      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha,
                          'Empresa : ' || X_cod_empresa || ' - ' ||
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
                            'Relatorio MAPA das NFs',
                            90 -
                            length('Relatorio MAPA das NFs'));

      end if;

      LIB_PROC.add(mLinha, null, null, prel);

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then
        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'ARQUIVO GERADO COM SUCESSO!', 2);


        LIB_PROC.add(mLinha, null, null, prel);
      end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      if prel = 1 then
        vn_linhas := 7;
     /* else
        vn_linhas := 9;*/
      end if;
      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_REL_MAPA2_CPROC;
/
