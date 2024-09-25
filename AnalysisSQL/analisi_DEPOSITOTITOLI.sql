--DWHEVO.DEPOSITOTITOLI 
-- LAST UPDATE 22/01/2024 aggiornamento deposito_titoli

--DEPOSITO TITOLI 22/01/2024
SELECT
    dt.abi_banca               AS cod_abi,
    dt.cag_intestatario        AS cod_cag,
    dt.cag_gruppo_intestatario AS cag_gruppo_ccb,
    dt.servizio                AS cod_servizio,
    dt.id_dossier              AS cod_rapporto,
    dt.data_riferimento,
    controvalore_titoli,
    NULL                       AS mft,
    NULL                       AS saldo_ias,
    NULL                       AS controvalore_titoli,
    'W8'                       AS flag_prodotto,
    NULL                       AS ft_prodotto
FROM
    (
        SELECT
            abi_banca,
            CASE
                WHEN cag_intestatario IS NOT NULL THEN
                    cag_intestatario
                ELSE
                    '-1'
            END AS cag_intestatario,
            cag_gruppo_intestatario,
            servizio,
            id_dossier,
            data_riferimento,
            cod_categoria -- aggiunta 22/01/2024 per andare in join con la categorie polizze
        FROM
            s2a.dossier_titoli_all
        WHERE
                abi_banca = '-----'
            AND data_riferimento = '31-GEN-2023'
            AND servizio = 'T02'
            AND cod_tipo_dossier <> 'G' -- aggiunta 22/01/2024 dalla loro query
            AND ( cod_stato_dossier IS NULL
                  OR cod_stato_dossier = 'N' )
    ) dt
    INNER JOIN (
        SELECT
            SUM(imp_controv_secco_eur) AS controvalore_titoli,
            abi_banca,
            data_riferimento,
            id_dossier,
            servizio,
            codice_isin -- aggiunta dell 22/01/2024 per andare in join con la titoli
        FROM
            s2a.saldi_dossier_titoli_all
        WHERE
                abi_banca = '-----'
            AND data_riferimento = '31-GEN-2023'
            AND servizio = 'T02'
			and IMP_CONTROV_SECCO_EUR != 0
        GROUP BY
            abi_banca,
            data_riferimento,
            id_dossier,
            servizio,
            codice_isin
    ) sdt ON dt.abi_banca = sdt.abi_banca
             AND dt.data_riferimento = sdt.data_riferimento
             AND dt.id_dossier = sdt.id_dossier
             AND dt.servizio = sdt.servizio
    JOIN ( -- inner PER I FILTRI
        SELECT
            codice_isin
        FROM
            s2a.anagrafica_titoli
        WHERE
                data_riferimento = '31-GEN-2023'
            AND flag_titolo_nostro = 'S'
            AND flag_titolo_estinto != 'S'
            AND cod_tipo_valore_mobiliare IN ( 'O', 'Z' )
    ) titoli ON sdt.codice_isin = titoli.codice_isin
    JOIN (-- il filtro per cod_tipologia_polizza è qui , quindi rispetto alla loro query noi mettiamo una INNER ivece che una left
        SELECT
            cod_elemento,
            abi_banca,
            data_riferimento
        FROM
            s2a.categorie_polizze_all
        WHERE
                data_riferimento = '31-GEN-23'
            AND cod_tipologia_polizza NOT IN ( 'P', 'T' ) -- aggiunta 22/01/2024 dalla loro query
    ) polizze ON dt.cod_categoria = polizze.cod_elemento
                 AND dt.abi_banca = polizze.abi_banca
                 AND dt.data_riferimento = polizze.data_riferimento

----------- CERTIFICATI DI DEPOSITO

SELECT
    abi_banca                   AS cod_abi,
    cag_intestatario            AS cod_cag,
    cag_gruppo_intestatario     AS cag_gruppo_ccb,
    servizio                    AS cod_servizio,
    rapporto                    AS cod_rapporto,
    data_riferimento,
    NULL                        AS mft,
    imp_costo_ammortizzato_mese AS saldo_ias,
    imp_sotoscritto             AS controvalore_titoli,
    'W24'                       AS flag_prodotto,
    NULL                        AS ft_prodotto
FROM
    s2a.certificati_deposito_all
WHERE
        abi_banca = '-----'
    AND data_riferimento = '28-feb-2023'
    AND servizio = 'D50';

------------ DEPOSITO A RISPARMIO

SELECT
    abi_banca               AS cod_abi,
    cag_intestatario        AS cod_cag,
    cag_gruppo_intestatario AS cag_gruppo_ccb,
    servizio                AS cod_servizio,
    rapporto                AS cod_rapporto,
    data_riferimento,
    NULL                    AS mft,
    NULL                    AS saldo_ias,
    imp_saldo_rapporto      AS controvalore_titoli,
    'W23'                   AS flag_prodotto,
    NULL                    AS ft_prodotto
FROM
    s2a.depositi_risparmio_all
WHERE
        abi_banca = '-----'
    AND data_riferimento = '28-feb-2023'
    AND servizio = 'D01';

------------- CONTO_TITOLI

SELECT
    abi_banca                     AS cod_abi,
    cag_intestatario              AS cod_cag,
    cag_gruppo_intestatario       AS cag_gruppo_ccb,
    servizio                      AS cod_servizio,
    rapporto                      AS cod_rapporto,
    data_riferimento,
    NULL                          AS mft,
    NULL                          AS saldo_ias,
    imp_saldo_contabile_in_divisa AS controvalore_titoli,
    'CDEP00'                      AS flag_prodotto,
    NULL                          AS ft_prodotto
FROM
    s2a.conti_correnti_all
WHERE
        abi_banca = '-----'
    AND data_riferimento = '28-feb-2023'
    AND servizio = 'C01';

-------------------------------------------------------------------- 22/01/2023 UNION ALL tutte e 4

--DEPOSITO TITOLI
SELECT
    dt.ABI_BANCA AS COD_ABI,
    dt.CAG_INTESTATARIO AS COD_CAG,
    dt.CAG_GRUPPO_INTESTATARIO AS CAG_GRUPPO_CCB,
    dt.SERVIZIO AS COD_SERVIZIO,
    dt.ID_DOSSIER AS COD_RAPPORTO,
    dt.DATA_RIFERIMENTO,
    CONTROVALORE_TITOLI,
    NULL AS MFT,
    NULL AS SALDO_IAS,
    NULL AS CONTROVALORE_TITOLI,
    'W8' AS FLAG_PRODOTTO,
    NULL AS FT_PRODOTTO
FROM (
    SELECT
        ABI_BANCA,
        CAG_INTESTATARIO,
        CAG_GRUPPO_INTESTATARIO,
        SERVIZIO,
        ID_DOSSIER,
        DATA_RIFERIMENTO
    FROM
        S2A.DOSSIER_TITOLI_ALL
    WHERE
        ABI_BANCA = '-----'
        AND DATA_RIFERIMENTO = '28-feb-2023'
        AND servizio = 'T02'
) dt
left JOIN (
    SELECT
        SUM(IMP_CONTROV_SECCO_EUR) AS CONTROVALORE_TITOLI,
        ABI_BANCA,
        DATA_RIFERIMENTO,
        ID_DOSSIER,
        SERVIZIO
    FROM
        s2a.SALDI_DOSSIER_TITOLI_ALL
    WHERE
        ABI_BANCA = '-----'
        AND DATA_RIFERIMENTO = '28-feb-2023'
        AND servizio = 'T02'
    GROUP BY
        ABI_BANCA,
        DATA_RIFERIMENTO,
        ID_DOSSIER,
        SERVIZIO
) sdt ON dt.ABI_BANCA = sdt.ABI_BANCA
    AND dt.DATA_RIFERIMENTO = sdt.DATA_RIFERIMENTO
    AND dt.ID_DOSSIER = sdt.ID_DOSSIER
    AND dt.SERVIZIO = sdt.SERVIZIO

-- CERTIFICATI DI DEPOSITO
UNION ALL
SELECT
    ABI_BANCA AS COD_ABI,
    CAG_INTESTATARIO AS COD_CAG,
    CAG_GRUPPO_INTESTATARIO AS CAG_GRUPPO_CCB,
    SERVIZIO AS COD_SERVIZIO,
    RAPPORTO AS COD_RAPPORTO,
    DATA_RIFERIMENTO,
    NULL AS CONTROVALORE_TITOLI,
    NULL AS MFT,
    IMP_COSTO_AMMORTIZZATO_MESE AS SALDO_IAS,
    IMP_SOTOSCRITTO AS CONTROVALORE_TITOLI,
    'W24' AS FLAG_PRODOTTO,
    NULL AS FT_PRODOTTO
FROM
    S2A.CERTIFICATI_DEPOSITO_ALL
WHERE
    ABI_BANCA = '-----'
    AND DATA_RIFERIMENTO = '28-feb-2023'
    AND SERVIZIO = 'D50'

-- DEPOSITO A RISPARMIO
UNION ALL
SELECT
    ABI_BANCA AS COD_ABI,
    CAG_INTESTATARIO AS COD_CAG,
    CAG_GRUPPO_INTESTATARIO AS CAG_GRUPPO_CCB,
    SERVIZIO AS COD_SERVIZIO,
    RAPPORTO AS COD_RAPPORTO,
    DATA_RIFERIMENTO,
     NULL AS CONTROVALORE_TITOLI,
    NULL AS MFT,
    NULL AS SALDO_IAS,
    IMP_SALDO_RAPPORTO AS CONTROVALORE_TITOLI,
    'W23' AS FLAG_PRODOTTO,
    NULL AS FT_PRODOTTO
FROM
    S2A.DEPOSITI_RISPARMIO_ALL
WHERE
    ABI_BANCA = '-----'
    AND DATA_RIFERIMENTO = '28-feb-2023'
    AND SERVIZIO = 'D01'

-- CONTO_TITOLI
UNION ALL
SELECT
    ABI_BANCA AS COD_ABI,
    CAG_INTESTATARIO AS COD_CAG,
    CAG_GRUPPO_INTESTATARIO AS CAG_GRUPPO_CCB,
    SERVIZIO AS COD_SERVIZIO,
    RAPPORTO AS COD_RAPPORTO,
    DATA_RIFERIMENTO,
     NULL AS CONTROVALORE_TITOLI,
    NULL AS MFT,
    NULL AS SALDO_IAS,
    IMP_SALDO_CONTABILE_IN_DIVISA AS CONTROVALORE_TITOLI,
    'CDEP00' AS FLAG_PRODOTTO,
    NULL AS FT_PRODOTTO
FROM
    S2A.CONTI_CORRENTI_ALL
WHERE
    ABI_BANCA = '-----'
    AND DATA_RIFERIMENTO = '28-feb-2023'
    AND SERVIZIO = 'C01';
