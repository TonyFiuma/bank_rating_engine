-- ANTICIPI ESTERO  

-- LAST UPDATE 17/10/2023

SELECT
    cod_abi,
    cod_cag,
    cag_gruppo_ccb,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    COUNT(*)
FROM
    (
        SELECT
            esteroa.cod_abi,
            esteroa.cod_cag,
            esteroa.cag_gruppo_ccb,
            esteroa.cod_servizio,
            esteroa.cod_rapporto,
            esteroa.data_riferimento,
            sconf.num_massivo_gg_sconf_cons,
            pp.num_distinte_presentate,
            pp.imp_anticipato_distinte_presenta,
            rischio.utilizzato_contabile,
            rischio.fido_operativo_contabile,
            esteroa.data_accensione_rapp,
            esteroa.data_scadenza_rapp,
            rapp.flag_anticipo_estero,
            esteroa.flag_finanziamenti_importaz,
            esteroa.data_estinzione_rapp
        FROM
                 (
                SELECT DISTINCT --ANTICIPI ESTERO SCHIACCIAMO A LIVELLO DI RAPPORTO
                    abi_banca                AS cod_abi,
                    cag_intestatario         AS cod_cag,
                    cag_gruppo_intestatario  AS cag_gruppo_ccb,
                    servizio                 AS cod_servizio,
                    rapporto                 AS cod_rapporto,
                    data_riferimento,
                    data_apertura_rapporto   AS data_accensione_rapp,
                    data_scadenza_rapporto   AS data_scadenza_rapp,
                    CASE
                        WHEN cod_prodotto IN ( 'FINIMP22', 'TRAIMP22' ) THEN
                            cod_prodotto
                    END                      AS flag_finanziamenti_importaz,
                    data_estinzione_rapporto AS data_estinzione_rapp
                FROM
                    s2a.finanziamenti_estero_all
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-gen-2023'
            ) esteroa
            JOIN (
                SELECT
                    abi_banca
                FROM
                    dwhevo.rsk_wk_anagrafica_banche_societa
                WHERE
                    cod_gruppo IN ( 1, 2, 3 )
                    AND abi_banca = '----'
                    AND data_inizio_validita < '31-gen-2023'
                    AND data_fine_validita >= '31-gen-2023'
            ) abs ON esteroa.cod_abi = abs.abi_banca
            LEFT JOIN (
                SELECT
                    SUM(num_giorni_sconfino) AS num_massivo_gg_sconf_cons,
                    data_riferimento,
                    abi_banca,
                    rapporto,
                    servizio,
                    cag_rischio
                FROM
                    dwhevo.crewkvw_sconfinamenti
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-gen-2023'
                    AND num_giorni_sconfino IS NOT NULL
                    AND num_giorni_sconfino >= 0
                GROUP BY
                    data_riferimento,
                    abi_banca,
                    rapporto,
                    servizio,
                    cag_rischio
            ) sconf ON esteroa.cod_abi = sconf.abi_banca
                       AND esteroa.data_riferimento = sconf.data_riferimento
                       AND esteroa.cod_servizio = sconf.servizio
                       AND esteroa.cod_rapporto = sconf.rapporto
                       AND esteroa.cod_cag = sconf.cag_rischio
            LEFT JOIN (
                SELECT
                    COUNT(rapporto_id_partita) AS num_distinte_presentate,  
                    SUM(
                        CASE
                            WHEN imp_saldo_contab_partita_div < 0 THEN
                                NULL
                            ELSE
                                imp_saldo_contab_partita_div
                        END
                    )                          AS imp_anticipato_distinte_presenta,---------
                    data_riferimento,
                    abi_banca,
                    rapporto,
                    servizio,
                    cag_intestatario
                FROM
                    s2a.finanziamenti_estero_partite_all
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-gen-2023'
                GROUP BY
                    data_riferimento,
                    abi_banca,
                    rapporto,
                    servizio,
                    cag_intestatario
            ) pp ON esteroa.cod_abi = pp.abi_banca
                    AND esteroa.data_riferimento = pp.data_riferimento
                    AND esteroa.cod_servizio = pp.servizio
                    AND esteroa.cod_rapporto = pp.rapporto
                    AND esteroa.cod_cag = pp.cag_intestatario
            LEFT JOIN (
                SELECT
                    imp_utilizzato_fido_rapp AS utilizzato_contabile,     
                    imp_accordato_fido_rapp  AS fido_operativo_contabile, 
                    abi_banca,
                    data_riferimento,
                    servizio,
                    rapporto
                FROM
                    s2a.rischio_diretto_all a 
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-gen-2023'
                    AND imp_utilizzato_fido_rapp IS NOT NULL
                    AND imp_utilizzato_fido_rapp > 0        -- 17/10/2023 MODIFICHE DA TRACCIATO PER NON DUPLICARE DA >= 0 A > 0 
                    AND imp_accordato_fido_rapp IS NOT NULL -- 17/10/2023 MODIFICHE DA TRACCIATO PER NON DUPLICARE DA >= 0 A > 0 
                    AND imp_accordato_fido_rapp > 0
                    AND tipo_record = 'FR'
            ) rischio ON esteroa.cod_abi = rischio.abi_banca
                         AND esteroa.data_riferimento = rischio.data_riferimento
                         AND esteroa.cod_servizio = rischio.servizio
                         AND esteroa.cod_rapporto = rischio.rapporto
            LEFT JOIN (
                SELECT
                    data_apertura_rapporto AS data_accensione_rapp,
                    CASE
                        WHEN cod_categoria IN ( 050, 051 ) THEN
                            'SI'
                        ELSE
                            'NO'
                    END                    AS flag_anticipo_estero,
                    abi_banca,
                    data_riferimento,
                    cag_intestatario,
                    servizio,
                    rapporto
                FROM
                    s2a.finanziamenti_estero_rapporti_all
                WHERE
                        abi_banca = '-----'
                    AND data_riferimento = '31-gen-2023'
            ) rapp ON esteroa.cod_abi = rapp.abi_banca
                      AND esteroa.data_riferimento = rapp.data_riferimento
                      AND esteroa.cod_cag = rapp.cag_intestatario
                      AND esteroa.cod_servizio = rapp.servizio
                      AND esteroa.cod_rapporto = rapp.rapporto
    )
GROUP BY
    cod_abi,
    cod_cag,
    cag_gruppo_ccb,
    cod_servizio,
    cod_rapporto,
    data_riferimento
HAVING
    COUNT(*) > 1;