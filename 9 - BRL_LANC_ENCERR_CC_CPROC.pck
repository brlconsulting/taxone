CREATE OR REPLACE PACKAGE BRL_LANC_ENCERR_CC_CPROC IS
  --
  -- Declarac?o de Variaveis Publicas
  --
  COD_EMPRESA_P        ESTABELECIMENTO.COD_EMPRESA%TYPE;
  COD_ESTAB_P          ESTABELECIMENTO.COD_ESTAB%TYPE;
  nome_estab_P         ESTABELECIMENTO.razao_social%TYPE;
  cgc_estab_P          ESTABELECIMENTO.cgc%TYPE;
  INSCRICAO_ESTADUAL_P REGISTRO_ESTADUAL.inscricao_estadual%TYPE;
  nome_empresa_P       EMPRESA.razao_social%TYPE;
  USUARIO_P            VARCHAR2(20);
  TOTAL_ESTAB_P        NUMBER(4);
  --
  -- Variaveis de controle de cabecalho de relatorio
  --
  FUNCTION PARAMETROS RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;
  FUNCTION Orientacao RETURN VARCHAR2;
  FUNCTION Executar(C_EMPRESA    Varchar2,
                    CONTA_CONTAB Varchar2,
                    W_DT_FIM     DATE,
                    pTipo_Vis    NUMBER,
                    num_lanc     varchar2) RETURN INTEGER;
  --
END BRL_LANC_ENCERR_CC_CPROC;
/
CREATE OR REPLACE PACKAGE BODY BRL_LANC_ENCERR_CC_CPROC IS
  --
  -- Variaveis de status
  --
  cCCod_Empresa EMPRESA.cod_empresa%TYPE;

  cCod_Usuario USUARIO_ESTAB.cod_usuario%TYPE;
  --
  FUNCTION PARAMETROS RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN
    cCCod_Empresa := Lib_Parametros.RECUPERAR('EMPRESA');
    cCod_Usuario := Lib_Parametros.Recuperar('Usuario');
    --
    --  DEFINIC?ES DA TELA E DAS VARIAVEIS DO PROCESSO CUSTOMIZADO
    --
    Lib_Proc.Add_Param(pstr,
                       '___________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    --
    Lib_Proc.Add_Param(pstr,
                       'Empresa          ',
                       'VARCHAR2',
                       'combobox',
                       'S',
                       NULL,
                       NULL,
                       'SELECT a.cod_empresa, a.cod_empresa||'' - ''||a.razao_social
FROM empresa a where cod_empresa = ''004'' ORDER BY a.cod_empresa');
    --
    Lib_Proc.Add_Param(pstr,
                       '___________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    --
    Lib_Proc.Add_Param(pstr,
                       'Conta Contabil   ',
                       'VARCHAR2',
                       'textbox',
                       'S',
                       NULL,
                       NULL,
                       '');
    --
    Lib_Proc.Add_Param(pstr,
                       '___________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    --
    LIB_PROC.ADD_PARAM(PSTR,
                       'Data do Encerramento  ',
                       'DATE',
                       'TEXTBOX',
                       'S',
                       NULL,
                       'DD/MM/YYYY');
    --
    Lib_Proc.Add_Param(pstr,
                       '___________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');
    --
    Lib_Proc.Add_Param(pstr,
                       'Normal / Excel',
                       'VARCHAR2',
                       'RadioButton',
                       'S',
                       'V',
                       NULL,
                       '1= 1 - Normal, 2= 2 - Arquivo Texto ');
    --
    Lib_Proc.Add_Param(pstr,
                       '___________________________________________________________________________________________________________',
                       'VARCHAR2',
                       'Text',
                       'N',
                       NULL,
                       NULL,
                       '');

    Lib_Proc.Add_Param(pstr,
                       'Num. Lancamento  ',
                       'VARCHAR2',
                       'textbox',
                       'S',
                       NULL,
                       NULL,
                       '');

    RETURN pstr;

  END;
  --
  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Inclus?o Dos Lancamentos de Encerramento por Centro de Custo - SO EMPRESA BAUSCH';
  END;
  --
  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SPED Contabil';
  END;
  --
  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;
  --
  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN ' * ' ; --'Inclus?o Dos Lancamentos de Encerramento por Centro de Custo';
  END;
  --
  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Especificos';
  END;
  --
  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Especificos';
  END;
  --
  FUNCTION Orientacao RETURN VARCHAR2 IS
  BEGIN
    -- Orientac?o da impress?o
    RETURN 'PORTRAIT';
  END;
  --
  FUNCTION Executar(c_empresa    VARCHAR2,
                    conta_contab VARCHAR2,
                    W_DT_FIM     DATE,
                    pTipo_Vis    NUMBER,
                    num_lanc     VARCHAR2) RETURN INTEGER IS

    -- VARI?VEIS LOCAIS
    CDESCRICAO VARCHAR2(100);
    CLINHA     VARCHAR2(250);
    NFOLHA     NUMBER := 0;
    NLINE      NUMBER := 0;
    NPROC_ID   INTEGER;
    C_CONTAB   VARCHAR2(10);
    --
    LV_COD_EMPRESA X01_CONTABIL.COD_EMPRESA%TYPE;
    LV_VLR_TOT_CRE X02_SALDOS.VLR_TOT_CRE%TYPE;
    LV_VLR_TOT_DEB X02_SALDOS.VLR_TOT_DEB%TYPE;
    W_IDENT_CONTA  X2002_PLANO_CONTAS.IDENT_CONTA%TYPE;
    --
    CONT       NUMBER(4) := 0;
    LN_RETORNO NUMBER;
    NUM_REG    NUMBER;

    --
    -- Cursor do Plano de contas
    --
    CURSOR CPLANO_CONTAS IS
      SELECT X02.COD_EMPRESA,
             X02.COD_ESTAB,
             X2002.IDENT_CONTA,
             X02.VLR_SALDO_FIM,
             X02.IND_SALDO_FIM,
             X02.IND_GRAVACAO,
             X02.DATA_SALDO
        FROM X2002_PLANO_CONTAS X2002, X02_SALDOS X02
       WHERE X2002.IDENT_CONTA = X02.IDENT_CONTA
         AND X2002.IND_NATUREZA IN (3, 4, 8, 9)
         AND X02.VLR_SALDO_FIM > 0
         AND X02.COD_EMPRESA = LV_COD_EMPRESA
         AND X02.DATA_SALDO = W_DT_FIM;
    --
    -- Valor Transportado para a Conta do Patrimonio
    --                    SO E PRECISO DEMONSTRAR ESTES TRES CAMPOS
    --
    CURSOR TRANSP IS
      SELECT
             nvl(sum(decode(ind_deb_cre, 'C', VLR_LANCTO * -1, vlr_lancto)),0)
vlr_lancto
        FROM X01_CONTABIL a
       WHERE
             TIPO_LANCTO = 'E'
         AND DATA_LANCTO = W_DT_FIM
         and COD_EMPRESA = LV_COD_EMPRESA
         AND IDENT_CONTA =
             (SELECT IDENT_CONTA
                FROM X2002_PLANO_CONTAS
               WHERE COD_CONTA = C_CONTAB
                 AND VALID_CONTA = (select max(valid_conta)
                                      from x2002_plano_contas
                                     where cod_conta = c_contab
                                       and valid_conta <= w_dt_fim));

    --
    -- Valor Transportado para a Conta do Patrimonio
    --      LAN?AMENTO DE ENCERRAMENTO DE CONTA DE RESULTADO
    --
    CURSOR RESULTADO IS
      SELECT COD_CONTA, COD_CUSTO, IND_DEB_CRE, VLR_LANCTO
        FROM X01_CONTABIL A, X2002_PLANO_CONTAS B, X2003_CENTRO_CUSTO C
       WHERE A.IDENT_CONTA = B.IDENT_CONTA
         AND A.IDENT_CUSTO = C.IDENT_CUSTO
         AND COD_EMPRESA = LV_COD_EMPRESA
         AND TIPO_LANCTO = 'E'
         AND DATA_LANCTO = W_DT_FIM
       ORDER BY COD_CONTA, COD_CUSTO;

  BEGIN

    LV_COD_EMPRESA := c_empresa;
    C_CONTAB       := conta_contab;
    NUM_REG        := 0;

    -- Select para identificar se ja existe registros do Tipo de Encerramento na data .
    BEGIN
      SELECT COUNT(*) -- SE COUNT(*) > 0 E QUE EXISTE LAN?AMENTO, ENTAO N?O FAZ O
--PROCESSO DE NOVO...
        INTO NUM_REG
        FROM X01_CONTABIL A
       WHERE TIPO_LANCTO = 'E'
         AND COD_EMPRESA = LV_COD_EMPRESA
         AND DATA_LANCTO = W_DT_FIM;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NUM_REG := 0;
    END;

    -- Se N?O encontar nenhum registro executa a procedure de calculo .
    IF NUM_REG = 0 THEN
      BRL_LANC_ENCERR_CC_EXEC(lv_cod_empresa,
                                   conta_contab,
                                   num_lanc,
                                   w_DT_fim,
                                   ln_retorno);
    END IF;

    -- Inicio do relatorio de apresentac?o dos Dados

    NPROC_ID   := LIB_PROC.NEW('BRL_LANC_ENCERR_CC_CPROC', 48, 150);
    CDESCRICAO := 'RELATORIO LANCAMENTO DE ENCERRAMENTO POR CENTRO DE CUSTO  - SO EMPRESA BAUSCH';
    Lib_Proc.add_tipo(nProc_id, 1, cDescricao, 1, 48, 150, 9);

    CLINHA := LIB_STR.W('', ' ', 1);
    CLINHA := LIB_STR.W(CLINHA, C_EMPRESA, 1);
    CLINHA := LIB_STR.W(CLINHA, CDESCRICAO, (70 - LENGTH(CDESCRICAO)) / 2);
    LIB_PROC.ADD(CLINHA);

    IF pTipo_Vis = 1 THEN
      CLINHA := '';
      CLINHA := LIB_STR.W(CLINHA, RPAD('=', 150, '=') || ' ', 1);
      LIB_PROC.ADD(CLINHA);
      --
      CLINHA := '';
      LIB_PROC.ADD(CLINHA);
    END IF;

    --
    FOR REGS IN TRANSP LOOP
      --

      IF pTipo_Vis = 2 then
        CLINHA := '';
        CLINHA := LIB_STR.W(CLINHA,
                            RPAD('Valor Transportado para a Conta ' ||
                                 substr(C_CONTAB, 1, 10) || ' : ;',
                                 49,
                                 ' '),
                            1);
        CLINHA := LIB_STR.W(CLINHA,
                            LPAD(LTRIM(RTRIM(TO_CHAR(REGS.VLR_LANCTO,
                                                     '9999G999G999G999D' ||
                                                     RPAD('0', 2, '0'),
                                                     'NLS_NUMERIC_CHARACTERS =
'',.'''))),
                                 17,
                                 ' '),
                            51) || ';';
        LIB_PROC.ADD(CLINHA);
      ELSE
        CLINHA := '';
        CLINHA := LIB_STR.W(CLINHA,
                            RPAD('Valor Transportado para a Conta ' ||
                                 substr(C_CONTAB, 1, 10) || ' : ',
                                 49,
                                 ' '),
                            1);
        CLINHA := LIB_STR.W(CLINHA,
                            LPAD(LTRIM(RTRIM(TO_CHAR(REGS.VLR_LANCTO,
                                                     '9999G999G999G999D' ||
                                                     RPAD('0', 2, '0'),
                                                     'NLS_NUMERIC_CHARACTERS =
'',.'''))),
                                 17,
                                 ' '),
                            51);
        LIB_PROC.ADD(CLINHA);
      END IF;

    --
    END LOOP;

    IF pTipo_Vis = 1 THEN
      CLINHA := LIB_STR.W(CLINHA, RPAD('-', 150, '-') || ' ', 1);
      LIB_PROC.ADD(CLINHA);
      --
      CDESCRICAO := 'LANCAMENTO DE ENCERRAMENTO DE CONTA DE RESULTADO POR CENTRO DE
CUSTO  - SO EMPRESA BAUSCH';
      CLINHA     := '';
      CLINHA     := LIB_STR.W(CLINHA,
                              CDESCRICAO,
                              (70 - LENGTH(CDESCRICAO)) / 2);
      LIB_PROC.ADD(CLINHA);
      --
      CLINHA := '';
      CLINHA := LIB_STR.W(CLINHA, RPAD('-', 150, '-') || ' ', 1);
      LIB_PROC.ADD(CLINHA);
      --
      CLINHA := '';
      CLINHA := LIB_STR.W(CLINHA, RPAD('Cod Conta ', 20, ' '), 1);
      CLINHA := LIB_STR.W(CLINHA, RPAD('Cod Custo ', 20, ' '), 21);
      CLINHA := LIB_STR.W(CLINHA, RPAD('Ind D/C  ', 20, ' '), 41);
      CLINHA := LIB_STR.W(CLINHA, RPAD('VALOR    ', 20, ' '), 61);
      LIB_PROC.ADD(CLINHA);
      --
      CLINHA := '';
      CLINHA := LIB_STR.W(CLINHA, RPAD('-', 150, '-') || ' ', 1);
      LIB_PROC.ADD(CLINHA);
      --
    ELSE
      CLINHA := '';
      CLINHA := LIB_STR.W(CLINHA, RPAD('Cod Conta ;', 20, ' '), 1);
      CLINHA := LIB_STR.W(CLINHA, RPAD('Cod Custo ;', 20, ' '), 21);
      CLINHA := LIB_STR.W(CLINHA, RPAD('Ind D/C   ;', 20, ' '), 41);
      CLINHA := LIB_STR.W(CLINHA, RPAD('VALOR     ;', 20, ' '), 61);
      LIB_PROC.ADD(CLINHA);
    END IF;

    FOR REGS1 IN RESULTADO LOOP

      IF pTipo_Vis = 1 THEN
        CLINHA := '';
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.cod_conta, 20, ' '), 1);
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.cod_custo, 20, ' '), 21);
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.ind_deb_cre, 20, ' '), 41);
        CLINHA := LIB_STR.W(CLINHA,
                            LPAD(LTRIM(RTRIM(TO_CHAR(REGS1.VLR_LANCTO,
                                                     '9999G999G999G999D' ||
                                                     RPAD('0', 2, '0'),
                                                     'NLS_NUMERIC_CHARACTERS =
'',.'''))),
                                 17,
                                 ' '),
                            61);
        LIB_PROC.ADD(CLINHA);
      ELSE
        CLINHA := '';
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.cod_conta, 15, ' '), 1) || ';';
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.cod_custo, 15, ' '), 21) || ';';
        CLINHA := LIB_STR.W(CLINHA, RPAD(regs1.ind_deb_cre, 5, ' '), 41) || ';';
        CLINHA := LIB_STR.W(CLINHA,
                            LPAD(LTRIM(RTRIM(TO_CHAR(REGS1.VLR_LANCTO,
                                                     '9999G999G999G999D' ||
                                                     RPAD('0', 2, '0'),
                                                     'NLS_NUMERIC_CHARACTERS =
'',.'''))),
                                 17,
                                 ' '),
                            61) || ';';
        LIB_PROC.ADD(CLINHA);
      END IF;

    END LOOP;
    --
    if ln_retorno = -1 then
      return - 1;
    else
      return 1;
    end if;

  END;

END BRL_LANC_ENCERR_CC_CPROC;
/
