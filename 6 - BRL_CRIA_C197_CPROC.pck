CREATE OR REPLACE PACKAGE BRL_CRIA_C197_CPROC IS

  -- Purpose : Ler a parametrizac?o do cod C197 e gerar safx112 e 113 dos codigos parametrizados lendo as notas fiscais do mes
  --           alem disso gera as guias de pagamento para o registro E300

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

END BRL_CRIA_C197_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_CRIA_C197_CPROC IS

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
w_ident_estado       estado.ident_estado%type;
w_cod_ajuste_icms    ITEM_APURAC_DIFAL.COD_AJUSTE_ICMS%type;
w_dsc_lanc           ITEM_APURAC_DIFAL.Dsc_Lanc%type;
w_ident_receita_est  X223_GUIA_RECOL_DIFAL.IDENT_RECEITA_EST%TYPE;
W_AUX                NUMBER:=0;

w_vlr_icms_uf_orig   dwt_itens_merc.vlr_icms_uf_orig%type;
w_vlr_fcp_uf_dest    dwt_itens_merc.vlr_fcp_uf_dest%type;

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
                       '  a.cod_empresa = :1  ORDER BY a.cod_estab');

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
    RETURN 'GERA O REGISTRO C197 e E300 - guias de pagamento - PARA SPED FISCAL';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'GERA O REGISTRO C197 e E300 - guias de pagamento - PARA SPED FISCAL';
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

    cursor cur_c197 is
      select b.cod_empresa,
                     b.cod_estab,
                     TO_CHAR(b.data_fiscal, 'YYYYMMDD') DATA_FISCAL,
                     B.MOVTO_e_s,
                     b.norm_dev,
                     b.ident_docto,
                     b.ident_fis_jur,
                     b.num_docfis,
                     b.serie_docfis,
                     b.sub_serie_docfis,
                     a.num_item,
                     a.VLR_OUTROS1,
                     c.cod_obs,
                     c.cod_c197,
                     f.cod_docto,
                     g.ind_fis_jur,
                     g.cod_fis_jur,
                     a.descricao_compl
                from dwt_itens_merc   a,
                     x2012_cod_fiscal d,
                     dwt_docto_fiscal b,
                     brl_param_c197t_cproc c,
                     x2006_natureza_op e,
                     x2005_tipo_docto f,
                     x04_pessoa_fis_jur g
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.situacao = 'N'
                 and a.ident_cfo = d.ident_cfo
                 and c.cod_cfop = d.cod_cfo
                 and a.cod_empresa = c.cod_empresa
                 and a.cod_estab = c.cod_estab
                 and a.ident_natureza_op = e.ident_natureza_op
                 and c.cod_natureza = e.cod_natureza_op
                 and a.ident_docto = f.ident_docto
                 and a.ident_fis_jur = g.ident_fis_jur
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim;
               --  and a.VLR_OUTROS1 >0;

     cursor cur_destino is
       select b.cod_empresa,
                     b.cod_estab,
                     c.ident_estado,
                     sum(a.vlr_icms_uf_dest) vlr_icms_uf_dest
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and a.ident_fis_jur = c.ident_fis_jur
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_icms_uf_dest >0
               group by  b.cod_empresa,
                     b.cod_estab,
                     c.ident_estado;

     cursor cur_fcp is
       select b.cod_empresa,
                     b.cod_estab,
                     c.ident_estado,
                     sum(a.vlr_fcp_uf_dest) vlr_fcp_uf_dest
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and a.ident_fis_jur = c.ident_fis_jur
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_fcp_uf_dest >0
                 and a.movto_e_s = '9' -- so saidas, pois as entradas e a devoluc?o
               group by  b.cod_empresa,
                     b.cod_estab,
                     c.ident_estado;


  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('BRL_CRIA_C197_CPROC', 48, 150);

    LIB_PROC.add_tipo(mproc_id,
                      1,
                      'Notas Fiscais para o C197',
                      1);

LIB_PROC.add_tipo(mproc_id,
                      2,
                      'Notas fiscais com o Dif Aliq Origem - Devoluc?es - E300',
                      1);

LIB_PROC.add_tipo(mproc_id,
                      3,
                      'Notas fiscais com o Dif Aliq Destino - E300',
                      1);

LIB_PROC.add_tipo(mproc_id,
                      4,
                      'Notas fiscais com o FCP - E300',
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

-- primeiro deleta dados que houver de importa??o anteriores
delete safx112 WHERE cod_empresa = mcod_empresa and cod_estab = c_estab;
delete safx113 WHERE cod_empresa = mcod_empresa and cod_estab = c_estab;

commit;
	

 w_sequencial := w_sequencial + 1;

--  ******************** insere dados das notas fiscais *************
for reg in cur_c197 loop

    insert into safx112
      (cod_empresa,
       cod_estab,
       data_fiscal,
       movto_e_s,
       norm_dev,
       cod_docto,
       ind_fis_jur,
       cod_fis_jur,
       num_docfis,
       serie_docfis,
       sub_serie_docfis,
       cod_obs_lancto_fiscal,
       ind_icompl_lancto,
       dsc_complementar,
       dat_gravacao,
       vinculacao)
    VALUES
      (reg.cod_empresa,
       reg.cod_estab,
       reg.data_fiscal,
       REG.MOVTO_E_S,
       reg.norm_dev,
       reg.cod_docto,
       reg.ind_fis_jur,
       reg.cod_fis_jur,
       reg.num_docfis,
       reg.serie_docfis,
       reg.sub_serie_docfis,
       reg.cod_obs,
       'L',
       '',
       SYSDATE,
       '');


   if reg.VLR_OUTROS1 = 0 then -- as notas de credito presumido so tem o valor nas observac?es. Entao colocamos 1 centavo para que o
                               -- MSAF possa importar estas notas e o pessoal coloca o valor no C197 que foi importado ja dentro do DW
      reg.VLR_OUTROS1 :=0.01;

   end if;

    insert into safx113
      (cod_empresa,
       cod_estab,
       data_fiscal,
       movto_e_s,
       norm_dev,
       cod_docto,
       ind_fis_jur,
       cod_fis_jur,
       num_docfis,
       serie_docfis,
       sub_serie_docfis,
       cod_obs_lancto_fiscal,
       cod_ajuste_sped,
       num_item,
       dsc_comp_ajuste,
       vlr_base_icms,
       aliquota_icms,
       vlr_icms,
       dat_gravacao)
    VALUES
      (reg.cod_empresa,
       reg.cod_estab,
       reg.data_fiscal,
       REG.MOVTO_E_s,
       reg.norm_dev,
       reg.cod_docto,
       reg.ind_fis_jur,
       reg.cod_fis_jur,
       reg.num_docfis,
       reg.serie_docfis,
       reg.sub_serie_docfis,
       reg.cod_obs,
       reg.cod_c197,
       reg.num_item,
       reg.descricao_compl,
       0,
       '0',
      trunc(reg.VLR_OUTROS1*100),
       SYSDATE);

 end loop;

  commit;


for reg3 in cur_destino loop
begin

select max(ident_receita_est)
into w_ident_receita_est
from X223_GUIA_RECOL_DIFAL
 where
cod_empresa = reg3.cod_empresa
  and cod_Estab = reg3.cod_estab
  and dat_apuracao <= last_day(ADD_MONTHS(pDt_fim, - 1))
  and ident_estado = reg3.ident_estado
  and cod_obrigacao = '020';
  
  exception when no_data_found then
 
  select ident_receita_est
   into w_ident_receita_est
    from X2080_COD_REC_UF 
   where ident_estado = reg3.ident_estado
    and  cod_receita_est = '100110';
 end;
 

   -- antes de inserir tem que deletar se ja houver um anterior... assim vai garantir que o usuario pode gerar quantas vezes quiser
delete X223_GUIA_RECOL_DIFAL where
cod_empresa = reg3.cod_empresa
  and cod_Estab = reg3.cod_estab
  and dat_apuracao = last_day(pDt_fim)
  and ident_estado = reg3.ident_estado
  and cod_obrigacao = '020'; -- 020 e fixo para o dif aliquota


-- todos os valores de origem s?o valores de devoluc?o... entao cada estado que tem valor a pagar tem que
-- diminiur o valor da devoluc?o antes de criar a gria de pagamento
-- quando o estado so tiver devoluc?o, o MSAF vai deixar em saldo credor...
-- o que este customizado faz e o pagamento... a guia...
w_vlr_icms_uf_orig :=0;

begin
        select nvl(sum(a.vlr_icms_uf_orig),0)
        into  w_vlr_icms_uf_orig
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.situacao = 'N'
                 and b.ident_fis_jur = c.ident_fis_jur 
                 and c.ident_estado = reg3.ident_estado
                 and b.cod_empresa = reg3.cod_empresa
                 and b.cod_estab =  reg3.cod_estab
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_icms_uf_orig >0
               group by  b.cod_empresa,
                     b.cod_estab;
 exception when no_data_found then
 w_vlr_icms_uf_orig:=0;
 end ;
                     
insert into X223_GUIA_RECOL_DIFAL
  (COD_EMPRESA,
   COD_ESTAB,
   COD_TIPO_LIVRO,
   DAT_APURACAO,
   IDENT_ESTADO,
   NUM_GUIA_RECOL,
   VAL_GUIA_RECOL,
   DAT_VENCTO,
   MES_ANO_REF,
   COD_OBRIGACAO,
   IDENT_RECEITA_EST,
   NUM_PROCESSO,
   IND_GRAVACAO)
values
  (reg3.cod_empresa,
   reg3.cod_estab,
   '108',
   last_day(pDt_fim),
   reg3.ident_estado,
   to_char(last_day(pDt_fim), 'yyyymmdd'),
   reg3.vlr_icms_uf_dest - w_vlr_icms_uf_orig,
   last_day(pDt_fim),
   trunc(pDt_fim, 'mm'),
   '020',
   W_IDENT_RECEITA_EST,
   0,
   4);

end loop;
commit;




for reg4 in cur_fcp loop

begin
select max(ident_receita_est)
into w_ident_receita_est
from X223_GUIA_RECOL_DIFAL
 where
cod_empresa = reg4.cod_empresa
  and cod_Estab = reg4.cod_estab
  and dat_apuracao <= last_day(ADD_MONTHS(pDt_fim, - 1))
  and ident_estado = reg4.ident_estado
  and cod_obrigacao = '006';

exception when no_data_found then
  select ident_receita_est
   into w_ident_receita_est
    from X2080_COD_REC_UF 
   where ident_estado = reg4.ident_estado
    and  cod_receita_est = '100137';
 end;
  
  
   -- antes de inserir tem que deletar se ja houver um anterior... assim vai garantir que o usuario pode gerar quantas vezes quiser
delete X223_GUIA_RECOL_DIFAL where
cod_empresa = reg4.cod_empresa
  and cod_Estab = reg4.cod_estab
  and dat_apuracao = last_day(pDt_fim)
  and ident_estado = reg4.ident_estado
  and cod_obrigacao = '006'; -- 006 e fixo para o dif aliquota
  
  -- verificando as devoluc?es
  begin
   select  nvl(sum(a.vlr_fcp_uf_dest),0)
   into w_vlr_fcp_uf_dest
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and a.ident_fis_jur = c.ident_fis_jur
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_fcp_uf_dest >0
                 and a.movto_e_s <> '9' -- so saidas, pois as entradas e a devoluc?o
                 and c.ident_estado = reg4.ident_estado;
                     
   exception when no_data_found then 
    w_vlr_fcp_uf_dest := 0;
   end;
   

insert into X223_GUIA_RECOL_DIFAL
  (COD_EMPRESA,
   COD_ESTAB,
   COD_TIPO_LIVRO,
   DAT_APURACAO,
   IDENT_ESTADO,
   NUM_GUIA_RECOL,
   VAL_GUIA_RECOL,
   DAT_VENCTO,
   MES_ANO_REF,
   COD_OBRIGACAO,
   IDENT_RECEITA_EST,
   NUM_PROCESSO,
   IND_GRAVACAO)
values
  (reg4.cod_empresa,
   reg4.cod_estab,
   '108',
   last_day(pDt_fim),
   reg4.ident_estado,
   to_char(last_day(pDt_fim), 'yyyymmdd'),
   reg4.vlr_fcp_uf_dest - w_vlr_fcp_uf_dest,
   last_day(pDt_fim),
   trunc(pDt_fim, 'mm'),
   '006',
   W_IDENT_RECEITA_EST,
   0,
   4);

end loop;
commit;



-- criando o relatorio
-- relatorio 1

begin

   for rel in ( select b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     B.MOVTO_e_s,
                     b.norm_dev,
                     b.ident_docto,
                     b.ident_fis_jur,
                     g.razao_social,
                     b.num_docfis,
                     b.serie_docfis,
                     b.sub_serie_docfis,
                     a.num_item,
                     a.VLR_OUTROS1,
                     c.cod_obs,
                     c.cod_c197,
                     f.cod_docto,
                     g.ind_fis_jur,
                     g.cod_fis_jur,
                     d.cod_cfo,
                     e.cod_natureza_op
                from dwt_itens_merc   a,
                     x2012_cod_fiscal d,
                     dwt_docto_fiscal b,
                     brl_param_c197t_cproc c,
                     x2006_natureza_op e,
                     x2005_tipo_docto f,
                     x04_pessoa_fis_jur g
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.situacao = 'N'
                 and a.ident_cfo = d.ident_cfo
                 and c.cod_cfop = d.cod_cfo
                 and a.cod_empresa = c.cod_empresa
                 and a.cod_estab = c.cod_estab
                 and a.ident_natureza_op = e.ident_natureza_op
                 and c.cod_natureza = e.cod_natureza_op
                 and a.ident_docto = f.ident_docto
                 and a.ident_fis_jur = g.ident_fis_jur
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim) loop
               --  and a.VLR_OUTROS1 >0

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  rel.cod_estab, 2);
          mLinha := LIB_STR.w(mLinha,  '|' || to_char(rel.data_fiscal, 'dd/mm/rrrr'), 7);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.num_docfis, 18);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_fis_jur, 30);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel.razao_social,1,30), 42);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel.cod_cfo, 72);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel.cod_natureza_op, 80);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel.cod_c197, 90);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel.vlr_outros1, 14), 108);


      LIB_PROC.add(mLinha, null, null, 1);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 1);

      end loop;



      -- relatorio 2
    vn_pagina := 1;
    vn_linhas := 50;
    Cabecalho(c_estab, 2);

       for rel2 in (select b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado,
                     sum(a.vlr_icms_uf_orig) vlr_icms_uf_orig
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c,
                     x2012_cod_fiscal d,
                     estado f
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_fis_jur = c.ident_fis_jur
                 and a.ident_cfo = d.ident_cfo
                 and c.ident_estado = f.ident_estado
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_icms_uf_orig >0
               group by  b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado
                order by b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis) loop

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  rel2.cod_estab, 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||to_char(rel2.data_fiscal, 'dd/mm/rrrr'), 7);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel2.num_docfis, 18);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel2.cod_fis_jur, 30);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel2.razao_social,1,30), 42);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel2.cod_cfo, 72);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel2.cod_estado, 80);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel2.vlr_icms_uf_orig, 14), 88);


      LIB_PROC.add(mLinha, null, null, 2);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 2);

      end loop;

      --relatorio 3

      vn_pagina := 1;
      vn_linhas := 50;
      Cabecalho(c_estab, 3);

      for rel3 in (select b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado,
                     sum(a.vlr_icms_uf_dest) vlr_icms_uf_dest
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c,
                     x2012_cod_fiscal d,
                     estado f
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_fis_jur = c.ident_fis_jur
                 and a.ident_cfo = d.ident_cfo
                 and c.ident_estado = f.ident_estado
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_icms_uf_dest >0
               group by  b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado
                order by b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis) loop

         mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  rel3.cod_estab, 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||to_char(rel3.data_fiscal, 'dd/mm/rrrr'), 7);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel3.num_docfis, 18);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel3.cod_fis_jur, 30);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel3.razao_social,1,30), 42);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel3.cod_cfo, 72);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel3.cod_estado, 80);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel3.vlr_icms_uf_dest, 14), 88);


      LIB_PROC.add(mLinha, null, null, 3);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 3);

      end loop;

   --relatorio 4

      vn_pagina := 1;
      vn_linhas := 50;
      Cabecalho(c_estab, 4);

      for rel4 in (select b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado,
                     sum(a.vlr_fcp_uf_dest) vlr_fcp_uf_dest
                from dwt_itens_merc   a,
                     dwt_docto_fiscal b,
                     x04_pessoa_fis_jur c,
                     x2012_cod_fiscal d,
                     estado f
               where a.ident_docto_fiscal = b.ident_docto_fiscal
                 and b.ident_fis_jur = c.ident_fis_jur
                 and a.ident_cfo = d.ident_cfo
                 and c.ident_estado = f.ident_estado
                 and b.situacao = 'N'
                 and b.cod_empresa = nvl(c_empresa, a.cod_empresa)
                 and b.cod_estab =  nvl(c_estab, a.cod_estab)
                 and b.data_fiscal between pDt_Ini and pDt_fim
                 and a.vlr_fcp_uf_dest >0
               group by  b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis,
                     c.cod_fis_jur,
                     c.razao_social,
                     d.cod_cfo,
                     f.cod_estado
                order by b.cod_empresa,
                     b.cod_estab,
                     b.data_fiscal,
                     b.num_docfis) loop

         mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha,  rel4.cod_estab, 2);
          mLinha := LIB_STR.w(mLinha,  '|' ||to_char(rel4.data_fiscal, 'dd/mm/rrrr'), 7);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel4.num_docfis, 18);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel4.cod_fis_jur, 30);
          mLinha := LIB_STR.w(mLinha,  '|' ||substr(rel4.razao_social,1,30), 42);
          mLinha := LIB_STR.w(mLinha,  '|' ||rel4.cod_cfo, 72);
          mLinha := LIB_STR.w(mLinha,  '| ' ||rel4.cod_estado, 80);
          mLinha := LIB_STR.w(mLinha,  '|' ||formata_valor(rel4.vlr_fcp_uf_dest, 14), 88);


      LIB_PROC.add(mLinha, null, null, 4);

      vn_linhas := vn_linhas + 1;
      Cabecalho(c_estab, 4);

      end loop;
end;


-- chama a importac?o automatica para importar esta safx112 e 113
-- IMPORTAC?O AUTOMATICA

/*
      SELECT COUNT(*)
      INTO W_AUX
      FROM SAFX112;

  IF W_AUX > 0 THEN

   IF c_empresa = '001' THEN
      PAR_COD_EMPRESA_W   := '001';
      PAR_COD_PROG_W      := 14; -- COdigo da programac?o feita no MasterSAF para importac?o da safx112 e 113
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

  IF c_empresa = '002' THEN
      PAR_COD_EMPRESA_W   := '002';
      PAR_COD_PROG_W      := 4; -- COdigo da programac?o feita no MasterSAF para importac?o da safx112 e 113
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

*/    LIB_PROC.CLOSE();
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
                            'Notas que tiveram C197 geradas',
                            50);
      end if;

       if prel = 2 then
        mLinha := LIB_STR.w(mLinha,
                            'Notas fiscais com o Dif Aliq Origem - Devoluc?es - E300',
                            50);
      end if;

       if prel = 3 then
        mLinha := LIB_STR.w(mLinha,
                            'Notas fiscais com o Dif Aliq Destino - E300',
                            50);
      end if;

       if prel = 4 then
        mLinha := LIB_STR.w(mLinha,
                            'Notas fiscais com o FCP - E300',
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
        mLinha := LIB_STR.w(mLinha, '|Extenc?o', 80);
        mLinha := LIB_STR.w(mLinha, '|Cod C197', 90);
        mLinha := LIB_STR.w(mLinha, '|Valor do C197', 108);

        LIB_PROC.add(mLinha, null, null, prel);

     elsif prel = 2 then
       mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Estab', 2);
        mLinha := LIB_STR.w(mLinha, '|Dt Fiscal', 7);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 18);
        mLinha := LIB_STR.w(mLinha, '|Cod Fis Jur', 30);
        mLinha := LIB_STR.w(mLinha, '|Razao Social', 42);
        mLinha := LIB_STR.w(mLinha, '|CFOP', 72);
        mLinha := LIB_STR.w(mLinha, '| UF', 80);
        mLinha := LIB_STR.w(mLinha, '|Valor Dif Orgiem', 88);


        LIB_PROC.add(mLinha, null, null, prel);

     elsif prel = 3 then
        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Estab', 2);
        mLinha := LIB_STR.w(mLinha, '|Dt Fiscal', 7);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 18);
        mLinha := LIB_STR.w(mLinha, '|Cod Fis Jur', 30);
        mLinha := LIB_STR.w(mLinha, '|Razao Social', 42);
        mLinha := LIB_STR.w(mLinha, '|CFOP', 72);
        mLinha := LIB_STR.w(mLinha, '| UF', 80);
        mLinha := LIB_STR.w(mLinha, '|Valor Dif Destino', 88);

        LIB_PROC.add(mLinha, null, null, prel);


     elsif prel = 4 then
       mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, 'Estab', 2);
        mLinha := LIB_STR.w(mLinha, '|Dt Fiscal', 7);
        mLinha := LIB_STR.w(mLinha, '|Nota Fiscal', 18);
        mLinha := LIB_STR.w(mLinha, '|Cod Fis Jur', 30);
        mLinha := LIB_STR.w(mLinha, '|Razao Social', 42);
        mLinha := LIB_STR.w(mLinha, '|CFOP', 72);
        mLinha := LIB_STR.w(mLinha, '| UF', 80);
        mLinha := LIB_STR.w(mLinha, '|Valor FCP', 88);

        LIB_PROC.add(mLinha, null, null, prel);

      end if;

      mLinha := LIB_STR.w('', ' ', 1);
      mLinha := LIB_STR.w(mLinha, LPAD('-', 200, '-'), 1);
      LIB_PROC.add(mLinha, null, null, prel);

      vn_linhas := 7;

      vn_pagina := vn_pagina + 1;

    end if;

  END;

END BRL_CRIA_C197_CPROC;
/
