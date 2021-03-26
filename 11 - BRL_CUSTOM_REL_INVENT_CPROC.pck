CREATE OR REPLACE PACKAGE BRL_CUSTOM_REL_INVENT_CPROC IS

  FUNCTION PARAMETROS RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;
  FUNCTION Orientacao RETURN VARCHAR2;
  FUNCTION Executar(P_COD_EMPRESA VARCHAR2,
                    P_COD_ESTAB   VARCHAR2,
                    P_DATA_INICIO VARCHAR2,
                    P_DATA_FIM    VARCHAR2,
                    P_OPCAO       VARCHAR2) RETURN INTEGER;
end;
/
CREATE OR REPLACE PACKAGE BODY BRL_CUSTOM_REL_INVENT_CPROC IS

  cCod_Estab   ESTABELECIMENTO.cod_estab%TYPE;
  cCod_Empresa EMPRESA.cod_empresa%TYPE;
  cCod_Usuario USUARIO_ESTAB.cod_usuario%TYPE;
  W_COD_CONTA X2002_PLANO_CONTAS.COD_CONTA%TYPE;

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
    LIB_PROC.add_param(pstr,
                       'Empresa',
                       'Varchar2',
                       'Combobox',
                       'N',
                       null,
                       NULL,
                       'SELECT cod_empresa, cod_empresa||'' - ''||razao_social FROM empresa WHERE  cod_empresa = ''' ||
                       ccod_empresa || '''');

    LIB_PROC.add_param(pstr,
                       'Estabelecimento',
                       'Varchar2',
                       'Combobox',
                       'N',
                       null,
                       NULL,
                       'SELECT cod_estab, cod_estab||'' - ''||razao_social FROM estabelecimento WHERE  cod_empresa = ''' ||
                       ccod_empresa || '''');

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
                       '______________________________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');


    Lib_Proc.Add_Param(pstr,
                       'Tipo de Relatorio :',
                       'VARCHAR2',
                       'RadioButton',
                       'S',
                       '1',
                       NULL,
                       '1= 1 - So estoques Proprios,' || '2= 2 - So estoques em Terceiros, ' ||
                       '3= 3 - Todos os estoques');
    Lib_Proc.Add_Param(pstr,
                       '______________________________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    --
    RETURN pstr;
  END;
  --
  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorio do Inventario para Apoio ao Bloco K200';
  END;
  --
  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'BLOCO K - para o SPED Fiscal';
  END;
  --
  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;
  --
  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorio do Inventario para Apoio ao Bloco K200';
  END;
  --
  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Espec?ficos';
  END;
  --
  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Espec?ficos';
  END;
  --
  FUNCTION Orientacao RETURN VARCHAR2 IS
  BEGIN
    -- Orienta??o da impress?o
    RETURN 'PORTRAIT';
  END;
  --
  FUNCTION Executar(P_COD_EMPRESA VARCHAR2,
                    P_COD_ESTAB   VARCHAR2,
                    P_DATA_INICIO VARCHAR2,
                    P_DATA_FIM    VARCHAR2,
                    P_OPCAO       VARCHAR2) RETURN INTEGER IS


  BEGIN

    nProc_id   := Lib_Proc.NEW('BRL_CUSTOM_REL_INVENT_CPROC', 48, 150);
    cDescricao := 'Relatorio do Inventario para Apoio ao Bloco K200';
    Lib_Proc.add_tipo(nProc_id, 1, cDescricao, 1, 48, 150, 9);

    Lib_Proc.new_page(1);
    nFolha := nFolha + 1;

    if (p_opcao = 1) then

      cLinha := Lib_Str.w('', ' ', 1);
      cLinha := Lib_Str.w(cLinha, cCod_Empresa, 1);
     /* cLinha := Lib_Str.w(cLinha, cDescricao, (70 - LENGTH(cDescricao)) / 2);
      Lib_Proc.add_header(cLinha);
      Lib_Proc.add_footer(RPAD('-', 70, '-'));
      Lib_Proc.add_footer(cDescricao || ' - Emitido em: ' ||
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH:MI'));
     */
      cLinha := '';

      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);
      cLinha := '';

      cLinha := Lib_Str.w(cLinha, RPAD('|ESTAB', 6, ' '), 0);
      cLinha := Lib_Str.w(cLinha, RPAD('|FORNEC', 7, ' '), 7);
      cLinha := Lib_Str.w(cLinha, RPAD('|CONTA', 16, ' '), 14);
      cLinha := Lib_Str.w(cLinha, RPAD('|PRODUTO', 25, ' '), 29);
      cLinha := Lib_Str.w(cLinha, RPAD('|DESCRI??O_PROD', 25, ' '), 62);
      cLinha := Lib_Str.w(cLinha, RPAD('|NCM', 10, ' '), 81);
      cLinha := Lib_Str.w(cLinha, RPAD('|CLASS', 6, ' '),91);
      cLinha := Lib_Str.w(cLinha, RPAD('|QUANTIDADE',15 , ' '), 97);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_UNIT', 15, ' '), 112);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_TOTAL', 15, ' '), 127);

      Lib_Proc.ADD(cLinha);
      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);

      for reg in (SELECT  X.cod_estab,    Z.Cod_Fis_Jur,
                        Z.CPF_CGC,
                        Z.RAZAO_SOCIAL,
                        Y.COD_PRODUTO,
                        Y.Descricao,
                        A.COD_NBM,
                        y.clas_item,
                        X.GRUPO_CONTAGEM,
                        X.QUANTIDADE,
                        X.VLR_UNIT,
                        X.VLR_TOT,
                        X.IDENT_CONTA
          FROM X52_INVENT_PRODUTO X, X2013_PRODUTO y, X04_PESSOA_FIS_JUR Z, X2043_COD_NBM A
         WHERE X.IDENT_PRODUTO = Y.IDENT_PRODUTO
           AND X.IDENT_NBM = A.IDENT_NBM
           AND X.IDENT_FIS_JUR = Z.IDENT_FIS_JUR(+)
           AND X.DATA_INVENTARIO BETWEEN P_DATA_INICIO and P_DATA_FIM
           and X.cod_empresa =  nvl(P_COD_EMPRESA, x.cod_Empresa)
           and x.cod_estab = nvl(P_COD_ESTAB, x.cod_Estab)
           and X.GRUPO_CONTAGEM = '1'
order by cod_estab, cod_produto, grupo_contagem, cod_fis_jur ) loop

     IF REG.IDENT_CONTA IS NOT NULL THEN
       SELECT COD_CONTA
       INTO W_COD_CONTA
       FROM X2002_PLANO_CONTAS
       WHERE IDENT_CONTA = REG.IDENT_CONTA;
     ELSE
      W_COD_CONTA := '';
     END IF;

        cLinha := '';
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_ESTAB, 5, ' '), 0);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_FIS_JUR, 7, ' '),7);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(W_COD_CONTA, 16, ' '), 14);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_PRODUTO, 25, ' '),29);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.DESCRICAO, 25, ' '), 62);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_NBM, 10, ' '), 81);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.CLAS_ITEM, 6, ' '),91);
        cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.QUANTIDADE,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              97);

          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_UNIT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              112);
          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_TOT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              127);
        Lib_Proc.ADD(cLinha);

      end loop;




    elsif (p_opcao = 2) then


      cLinha := Lib_Str.w('', ' ', 1);
      cLinha := Lib_Str.w(cLinha, cCod_Empresa, 1);
     /* cLinha := Lib_Str.w(cLinha, cDescricao, (70 - LENGTH(cDescricao)) / 2);
      Lib_Proc.add_header(cLinha);
      Lib_Proc.add_footer(RPAD('-', 70, '-'));
      Lib_Proc.add_footer(cDescricao || ' - Emitido em: ' ||
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH:MI'));
     */
      cLinha := '';

      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);
      cLinha := '';



      cLinha := Lib_Str.w(cLinha, RPAD('|ESTAB', 6, ' '), 0);
      cLinha := Lib_Str.w(cLinha, RPAD('|FORNEC', 7, ' '), 7);
      cLinha := Lib_Str.w(cLinha, RPAD('|CONTA', 16, ' '), 14);
      cLinha := Lib_Str.w(cLinha, RPAD('|PRODUTO', 25, ' '), 29);
      cLinha := Lib_Str.w(cLinha, RPAD('|DESCRICAO_PROD', 25, ' '), 62);
      cLinha := Lib_Str.w(cLinha, RPAD('|NCM', 10, ' '), 81);
      cLinha := Lib_Str.w(cLinha, RPAD('|CLASS', 6, ' '),91);
      cLinha := Lib_Str.w(cLinha, RPAD('|QUANTIDADE',15 , ' '), 97);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_UNIT', 15, ' '), 112);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_TOTAL', 15, ' '), 127);

      Lib_Proc.ADD(cLinha);
      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);

      for reg in (SELECT  X.cod_estab,    Z.Cod_Fis_Jur,
                        Z.CPF_CGC,
                        Z.RAZAO_SOCIAL,
                        Y.COD_PRODUTO,
                        Y.Descricao,
                        A.COD_NBM,
                        y.clas_item,
                        X.GRUPO_CONTAGEM,
                        X.QUANTIDADE,
                        X.VLR_UNIT,
                        X.VLR_TOT,
                        X.IDENT_CONTA
          FROM X52_INVENT_PRODUTO X, X2013_PRODUTO y, X04_PESSOA_FIS_JUR Z, X2043_COD_NBM A
         WHERE X.IDENT_PRODUTO = Y.IDENT_PRODUTO
           AND X.IDENT_NBM = A.IDENT_NBM
           AND X.IDENT_FIS_JUR = Z.IDENT_FIS_JUR(+)
           AND X.DATA_INVENTARIO BETWEEN P_DATA_INICIO and P_DATA_FIM
           and X.cod_empresa =  nvl(P_COD_EMPRESA, x.cod_Empresa)
           and x.cod_estab = nvl(P_COD_ESTAB, x.cod_Estab)
           and X.GRUPO_CONTAGEM <> '1'
order by cod_estab, cod_produto, grupo_contagem, cod_fis_jur ) loop


     IF REG.IDENT_CONTA IS NOT NULL THEN
       SELECT COD_CONTA
       INTO W_COD_CONTA
       FROM X2002_PLANO_CONTAS
       WHERE IDENT_CONTA = REG.IDENT_CONTA;
     ELSE
      W_COD_CONTA := '';
     END IF;

        cLinha := '';
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_ESTAB, 5, ' '), 0);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_FIS_JUR, 7, ' '),7);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(W_COD_CONTA, 16, ' '), 14);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_PRODUTO, 25, ' '),29);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.DESCRICAO, 25, ' '), 62);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_NBM, 10, ' '), 81);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.CLAS_ITEM, 6, ' '),91);
        cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.QUANTIDADE,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              97);

          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_UNIT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              112);
          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_TOT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              127);
        Lib_Proc.ADD(cLinha);

      end loop;



    elsif (p_opcao = 3) then
      cLinha := Lib_Str.w('', ' ', 1);
      cLinha := Lib_Str.w(cLinha, cCod_Empresa, 1);
     /* cLinha := Lib_Str.w(cLinha, cDescricao, (70 - LENGTH(cDescricao)) / 2);
      Lib_Proc.add_header(cLinha);
      Lib_Proc.add_footer(RPAD('-', 70, '-'));
      Lib_Proc.add_footer(cDescricao || ' - Emitido em: ' ||
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH:MI'));
     */
      cLinha := '';

      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);
      cLinha := '';

      cLinha := Lib_Str.w(cLinha, RPAD('|ESTAB', 6, ' '), 0);
      cLinha := Lib_Str.w(cLinha, RPAD('|FORNEC', 7, ' '), 7);
      cLinha := Lib_Str.w(cLinha, RPAD('|CONTA', 16, ' '), 14);
      cLinha := Lib_Str.w(cLinha, RPAD('|PRODUTO', 25, ' '), 29);
      cLinha := Lib_Str.w(cLinha, RPAD('|DESCRICAO_PROD', 25, ' '), 62);
      cLinha := Lib_Str.w(cLinha, RPAD('|NCM', 10, ' '), 81);
      cLinha := Lib_Str.w(cLinha, RPAD('|CLASS', 6, ' '),91);
      cLinha := Lib_Str.w(cLinha, RPAD('|QUANTIDADE',15 , ' '), 97);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_UNIT', 15, ' '), 112);
      cLinha := Lib_Str.w(cLinha, RPAD('|VLR_TOTAL', 15, ' '), 127);

      Lib_Proc.ADD(cLinha);
      cLinha := Lib_Str.w(cLinha, RPAD('-', 150, '-') || ' ', 1);
      Lib_Proc.ADD(cLinha);

      for reg in (SELECT  X.cod_estab,    Z.Cod_Fis_Jur,
                        Z.CPF_CGC,
                        Z.RAZAO_SOCIAL,
                        Y.COD_PRODUTO,
                        Y.Descricao,
                        A.COD_NBM,
                        y.clas_item,
                        X.GRUPO_CONTAGEM,
                        X.QUANTIDADE,
                        X.VLR_UNIT,
                        X.VLR_TOT,
                        X.IDENT_CONTA
          FROM X52_INVENT_PRODUTO X, X2013_PRODUTO y, X04_PESSOA_FIS_JUR Z, X2043_COD_NBM A
         WHERE X.IDENT_PRODUTO = Y.IDENT_PRODUTO
           AND X.IDENT_NBM = A.IDENT_NBM
           AND X.IDENT_FIS_JUR = Z.IDENT_FIS_JUR(+)
           AND X.DATA_INVENTARIO BETWEEN P_DATA_INICIO and P_DATA_FIM
           and X.cod_empresa =  nvl(P_COD_EMPRESA, x.cod_Empresa)
           and x.cod_estab = nvl(P_COD_ESTAB, x.cod_Estab)
order by cod_estab, cod_produto, grupo_contagem, cod_fis_jur ) loop


     IF REG.IDENT_CONTA IS NOT NULL THEN
       SELECT COD_CONTA
       INTO W_COD_CONTA
       FROM X2002_PLANO_CONTAS
       WHERE IDENT_CONTA = REG.IDENT_CONTA;
     ELSE
      W_COD_CONTA := '';
     END IF;

        cLinha := '';
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_ESTAB, 5, ' '), 0);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_FIS_JUR, 7, ' '),7);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(W_COD_CONTA, 16, ' '), 14);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_PRODUTO, 25, ' '),29);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.DESCRICAO, 25, ' '), 62);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.COD_NBM, 10, ' '), 81);
        cLinha := Lib_Str.w(cLinha,'|' || RPAD(REG.CLAS_ITEM, 6, ' '),91);
        cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.QUANTIDADE,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              97);

          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_UNIT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              112);
          cLinha := Lib_Str.w(cLinha,
                              '|' || RPAD(TO_CHAR(REG.VLR_TOT,
                                                  '9999G999G999G999D' ||
                                                  RPAD('0', 2, '0'),
                                                  'nls_numeric_characters = '',.'''),
                                          15,
                                          ' '),
                              127);
        Lib_Proc.ADD(cLinha);

      end loop;

    end if;

    RETURN 0;

  END; --EXECUTAR

end;
/
