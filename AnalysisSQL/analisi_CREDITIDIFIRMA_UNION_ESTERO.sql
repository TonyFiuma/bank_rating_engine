-- DWHEVO.CREDITIDIFIRMA UNION ALL 

-- DATE CREATED: 25/01/2024
-- LAST UPDATE: 25/01/2023


SELECT
    cod_abi,
    cod_cag,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    cod_rapp_partita,
    COUNT(*)
FROM
    (
        SELECT
            cf.cod_abi,
            cf.cod_cag,
            cf.cag_gruppo_ccb,
            cf.cod_servizio,
            cf.cod_rapporto,
            cf.data_riferimento,
            cf.utilizzato_firma,
            fidi.fido_operativo_firma,
            cf.data_accensione_rapp,
            cf.data_scadenza_rapp,
            cf.cod_rapp_partita,
            cf.data_estinzione_rapp
        FROM
                 (
                SELECT
                    abi_banca                    AS cod_abi,
                    cag_intestatario             AS cod_cag,
                    cag_gruppo_intestatario      AS cag_gruppo_ccb,
                    servizio                     AS cod_servizio,
                    rapporto                     AS cod_rapporto,
                    data_riferimento,
                    imp_saldo_contab_partita_div AS utilizzato_firma,
                    data_apertura_rapporto       AS data_accensione_rapp,
                    data_scadenza_rapporto       AS data_scadenza_rapp,
                    CASE
                        WHEN rapporto_id_partita IS NULL THEN -- MODIFICA
                            - 1
                        ELSE
                            rapporto_id_partita
                    END                          AS cod_rapp_partita,
                    data_estinzione_partita      AS data_estinzione_rapp
                FROM
                    dwhevo.crewkvw_crediti_firma
                WHERE
                        abi_banca = '----'
                    AND data_riferimento = '31-GEN-2023'
                    AND servizio = 'F90'
                    AND cod_stato_rapporto != 'E' -- AGGIUNTA 25/01/2025
                    AND nvl(cod_categoria, '-1') IN ( '11', '31' ) -- AGGIUNTA 25/01/2025
                UNION ALL
                SELECT
                    abi_banca                    AS cod_abi,
                    cag_intestatario             AS cod_cag,
                    cag_gruppo_intestatario      AS cag_gruppo_ccb,
                    servizio                     AS cod_servizio,
                    rapporto                     AS cod_rapporto,
                    data_riferimento,
                    imp_saldo_contab_partita_div AS utilizzato_firma,
                    data_apertura_rapporto       AS data_accensione_rapp,
                    data_scadenza_rapporto       AS data_scadenza_rapp,
                    CASE
                        WHEN rapporto_id_partita IS NULL THEN
                            - 1
                        ELSE
                            rapporto_id_partita
                    END                          AS cod_rapp_partita,
                    data_estinzione_partita      AS data_estinzione_rapp
                FROM
                    s2a.crediti_firma_estero_all
                WHERE
                        abi_banca = '----'
                    AND data_riferimento = '31-GEN-2023'
                    AND servizio = 'EP6' -- MODIFICA 25/01/2025
                    AND cod_stato_rapporto != 'E' --AGGIUNTA 25/01/2025
                    AND nvl(cod_categoria, '-1')NOT IN ( '11', '31' )
            ) cf
            JOIN (
                SELECT
                    abi_banca
                FROM
                    dwhevo.rsk_wk_anagrafica_banche_societa
                WHERE
                    cod_gruppo IN ( 1, 2, 3 )
                    AND abi_banca = '08883'
                    AND data_inizio_validita < '31-GEN-2023'
                    AND data_fine_validita >= '31-GEN-2023'
            ) abs ON cf.cod_abi = abs.abi_banca
            LEFT JOIN (
                SELECT
                    abi_banca,
                    data_riferimento,
                    rapporto,
                    servizio,
                    id_fido,
                    cag_intestatario
                FROM
                    s2a.rischio_diretto_all
                WHERE
                        abi_banca = '----'
                    AND data_riferimento = '31-GEN-2023'
                    AND tipo_record = 'FR' -- MODIFICA
            ) rischio ON cf.cod_servizio = rischio.servizio
                         AND cf.cod_rapporto = rischio.rapporto
                         AND cf.cod_abi = rischio.abi_banca
                         AND cf.cod_cag = rischio.cag_intestatario
            LEFT JOIN (
                SELECT
                    abi_banca,
                    data_riferimento,
                    id_fido,
                    importo_accord_operativo_div AS fido_operativo_firma
                FROM
                    s2a.fidi_all
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-GEN-2023'
                    AND importo_accord_operativo_div >= 0 -- MODIFICA 
                    AND importo_accord_operativo_div IS NOT NULL
            ) fidi ON cf.cod_abi = fidi.abi_banca
                      AND cf.data_riferimento = fidi.data_riferimento
                      AND rischio.id_fido = fidi.id_fido)
   GROUP BY
    cod_abi,
    cod_cag,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    cod_rapp_partita
HAVING
    COUNT(*) > 1



--------------------------- aggiunta di un'altra union con crediti_firma_estero che prende rapporto_id_partita come cod_rapporto

-- crediti di firma e crediti di firma estero in union all come  X2 nel mapping ci sono dei duplicati

-- DWHEVO.CREDITIDIFIRMA UNION ALL CREDITI_FIRMA_ESTERO X 2..  25/10/2024 
SELECT
    cod_abi,
    cod_cag,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    cod_rapp_partita,
    COUNT(*)
FROM
    (
        SELECT
            cf.cod_abi,
            cf.cod_cag,
            cf.cag_gruppo_ccb,
            cf.cod_servizio,
            cf.cod_rapporto,
            cf.data_riferimento,
            cf.utilizzato_firma,
            fidi.fido_operativo_firma,
            cf.data_accensione_rapp,
            cf.data_scadenza_rapp,
            cf.cod_rapp_partita,
            cf.data_estinzione_rapp
        FROM
                 (
                SELECT
                    abi_banca                    AS cod_abi,
                    cag_intestatario             AS cod_cag,
                    cag_gruppo_intestatario      AS cag_gruppo_ccb,
                    servizio                     AS cod_servizio,
                    rapporto                     AS cod_rapporto,
                    data_riferimento,
                    imp_saldo_contab_partita_div AS utilizzato_firma,
                    data_apertura_rapporto       AS data_accensione_rapp,
                    data_scadenza_rapporto       AS data_scadenza_rapp,
                    CASE
                        WHEN rapporto_id_partita IS NULL THEN -- MODIFICA
                            - 1
                        ELSE
                            rapporto_id_partita
                    END                          AS cod_rapp_partita,
                    data_estinzione_partita      AS data_estinzione_rapp
                FROM
                    dwhevo.crewkvw_crediti_firma
                WHERE
                        abi_banca = '03599'
                    AND data_riferimento = '28-FEB-2023'
                    AND servizio = 'F90'
                    AND cod_stato_rapporto != 'E' -- AGGIUNTA 25/01/2025
                    AND nvl(cod_categoria, '-1') IN ( '11', '31' ) -- AGGIUNTA 25/01/2025
                UNION ALL
                SELECT
                    abi_banca                    AS cod_abi,
                    cag_intestatario             AS cod_cag,
                    cag_gruppo_intestatario      AS cag_gruppo_ccb,
                    servizio                     AS cod_servizio,
                    rapporto                     AS cod_rapporto,
                    data_riferimento,
                    imp_saldo_contab_partita_div AS utilizzato_firma,
                    data_apertura_rapporto       AS data_accensione_rapp,
                    data_scadenza_rapporto       AS data_scadenza_rapp,
                    CASE
                        WHEN rapporto_id_partita IS NULL THEN
                            - 1
                        ELSE
                            rapporto_id_partita
                    END                          AS cod_rapp_partita,
                    data_estinzione_partita      AS data_estinzione_rapp
                FROM
                    s2a.crediti_firma_estero_all
                WHERE
                        abi_banca = '03599'
                    AND data_riferimento = '28-FEB-2023'
                    AND servizio ='EP6'  -- MODIFICA 25/01/2025
                    AND cod_stato_rapporto != 'E' --AGGIUNTA 25/01/2025
                    AND nvl(cod_categoria, '-1') NOT IN ( '11', '31' ) -- AGGIUNTA 25/01/2025
                    UNION ALL
                     SELECT
                    abi_banca                    AS cod_abi,
                    cag_intestatario             AS cod_cag,
                    cag_gruppo_intestatario      AS cag_gruppo_ccb,
                    servizio                     AS cod_servizio,
                    NVL(TO_CHAR(rapporto_id_partita), '-1') AS cod_rapporto,
                    data_riferimento,
                    imp_saldo_contab_partita_div AS utilizzato_firma,
                    data_apertura_rapporto       AS data_accensione_rapp,
                    data_scadenza_rapporto       AS data_scadenza_rapp,
                    CASE
                        WHEN rapporto_id_partita IS NULL THEN
                            - 1
                        ELSE
                            rapporto_id_partita
                    END                          AS cod_rapp_partita,
                    data_estinzione_partita      AS data_estinzione_rapp
                FROM
                    s2a.crediti_firma_estero_all
                WHERE
                        abi_banca = '03599'
                    AND data_riferimento = '28-FEB-2023'
                    AND servizio ='EP6'  -- MODIFICA 25/01/2025
                    AND cod_stato_rapporto != 'E' --AGGIUNTA 25/01/2025
                    AND nvl(cod_categoria, '-1') NOT IN ( '11', '31' ) -- AGGIUNTA 25/01/2025
            ) cf
            JOIN (
                SELECT
                    abi_banca
                FROM
                    dwhevo.rsk_wk_anagrafica_banche_societa
                WHERE
                    cod_gruppo IN ( 1, 2, 3 )
                    AND abi_banca = '03599'
                    AND data_inizio_validita < '28-FEB-2023'
                    AND data_fine_validita >= '28-FEB-2023'
            ) abs ON cf.cod_abi = abs.abi_banca
            LEFT JOIN (
                SELECT
                    abi_banca,
                    data_riferimento,
                    rapporto,
                    servizio,
                    id_fido,
                    cag_intestatario
                FROM
                    s2a.rischio_diretto_all
                WHERE
                        abi_banca = '03599'
                    AND data_riferimento = '28-FEB-2023'
                    AND tipo_record = 'FR' -- MODIFICA
            ) rischio ON cf.cod_servizio = rischio.servizio
                         AND cf.cod_rapporto = rischio.rapporto
                         AND cf.cod_abi = rischio.abi_banca
                         AND cf.cod_cag = rischio.cag_intestatario
            LEFT JOIN (
                SELECT
                    abi_banca,
                    data_riferimento,
                    id_fido,
                    importo_accord_operativo_div AS fido_operativo_firma
                FROM
                    s2a.fidi_all
                WHERE
                        abi_banca = '03599'
                    AND data_riferimento = '28-FEB-2023'
                    AND importo_accord_operativo_div >= 0 -- MODIFICA 
                    AND importo_accord_operativo_div IS NOT NULL
            ) fidi ON cf.cod_abi = fidi.abi_banca
                      AND cf.data_riferimento = fidi.data_riferimento
                      AND rischio.id_fido = fidi.id_fido
    )
GROUP BY
    cod_abi,
    cod_cag,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    cod_rapp_partita
HAVING
    COUNT(*) > 1