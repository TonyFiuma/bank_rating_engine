-- NEW QUERY PORTAFOGLIO EFFETTI 

-- LAST UPDATE: 20/10/2023
SELECT
    rapp.cod_abi,
    rapp.cod_cag,
    rapp.cag_gruppo_ccb,
    rapp.cod_servizio,
    rapp.cod_rapporto,
    rapp.data_riferimento,
    NULL AS mft,
    sconf.num_massivo_gg_sconf_cons,
    disp.num_fatture_stornate,
    disp.num_fatture_scadute,
    disp.numero_fatture_prorogate,
    pp.num_distinte_presentate,
    disp.imp_anticipato_fatt_stornate,
    sbf.imp_anticipato_fatt_scadute,
    disp.imp_anticipato_fatture_prorogate,
    pp.imp_anticipato_distinte_presenta,
    rischio.utilizzato_contabile,
    rischio.fido_operativo_contabile,
    rapp.data_accensione_rapp,
    rapp.data_scadenza_rapp,
    master.flag_anticipo_estero,
    finanziamenti.flag_finanziamenti_importaz,
    rapp.data_estinzione_rapp,
    NULL AS cod_rapporto_partita
FROM
         (
        SELECT
            abi_banca                AS cod_abi,
            cag_intestatario         AS cod_cag,
            cag_gruppo_intestatario  AS cag_gruppo_ccb,
            servizio                 AS cod_servizio,
            rapporto                 AS cod_rapporto,
            data_riferimento,
            data_apertura_rapp_pf    AS data_accensione_rapp,
            data_scadenza_rapporto   AS data_scadenza_rapp,
            data_estinzione_rapporto AS data_estinzione_rapp
        FROM
            dwhevo.crewkvw_rapporti_portafoglio
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-feb-2023'
            AND servizio = 'P01'
            AND cod_servizio_conto_anticipi IS NULL
    ) rapp
    JOIN (
        SELECT
            abi_banca
        FROM
            dwhevo.rsk_wk_anagrafica_banche_societa
        WHERE
            cod_gruppo IN ( 1, 2, 3 )
            AND abi_banca = '----'
            AND data_inizio_validita < '28-feb-2023'
            AND data_fine_validita >= '28-feb-2023'
    ) abs ON rapp.cod_abi = abs.abi_banca
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
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
            AND num_giorni_sconfino IS NOT NULL
            AND num_giorni_sconfino > 0
        GROUP BY
            data_riferimento,
            abi_banca,
            rapporto,
            servizio,
            cag_rischio
    ) sconf ON rapp.cod_abi = sconf.abi_banca
               AND rapp.data_riferimento = sconf.data_riferimento
               AND rapp.cod_servizio = sconf.servizio
               AND rapp.cod_rapporto = sconf.rapporto
               AND rapp.cod_cag = sconf.cag_rischio
    LEFT JOIN (
        SELECT
            COUNT(
                CASE
                    WHEN to_date(data_riferimento, 'YYYY-MM-DD') = last_day(to_date(data_scadenza_disposizione, 'YYYY-MM-DD'))
                         AND cod_stato_record = 'S' THEN
                        id_disposizione
                END
            ) AS num_fatture_stornate, -- MODIFICA 20/10/2023
            COUNT(
                CASE
                    WHEN(EXTRACT(YEAR FROM data_riferimento) <= EXTRACT(YEAR FROM data_scadenza_disposizione)
                         AND EXTRACT(MONTH FROM data_riferimento) < EXTRACT(MONTH FROM data_scadenza_disposizione))
                        AND(EXTRACT(YEAR FROM data_scadenza_disposizione) >= EXTRACT(YEAR FROM data_riferimento)
                            AND EXTRACT(MONTH FROM data_scadenza_disposizione) > EXTRACT(MONTH FROM data_riferimento) - 1) THEN
                        id_disposizione 
                END
            ) AS num_fatture_scadute,  -- MODIFICA 20/10/2023
            COUNT(
                CASE
                    WHEN info_stati_disposizione = 'V' THEN
                        id_disposizione
                END
            ) AS numero_fatture_prorogate, -- in questo momento 8/09/2023 INFO_STATI_DISPOSIZIONE non è mai valorizzato a 'V'
            SUM(
                CASE
                    WHEN data_riferimento = data_scadenza_disposizione
                         AND cod_stato_record = 'S' THEN
                        imp_disposizione
                END
            ) AS imp_anticipato_fatt_stornate,
            SUM(
                CASE
                    WHEN info_stati_disposizione = 'V' THEN
                        imp_disposizione
                END
            ) AS imp_anticipato_fatture_prorogate,
            abi_banca,
            data_riferimento,
            rapporto,
            servizio
        FROM
            s2a.disposizioni_portafoglio_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-feb-2023'
        GROUP BY
            data_riferimento,
            abi_banca,
            servizio,
            rapporto
    ) disp ON rapp.cod_abi = disp.abi_banca
              AND rapp.data_riferimento = disp.data_riferimento
              AND rapp.cod_servizio = disp.servizio
              AND rapp.cod_rapporto = disp.rapporto
    LEFT JOIN (
        SELECT
            SUM(
                CASE
                    WHEN num_disposizioni_distinta >= 0
                         AND num_disposizioni_distinta IS NOT NULL THEN  -- MODIFICA 19/10/2023
                        num_disposizioni_distinta
                END
            ) AS num_distinte_presentate,
            SUM(
                CASE
                    WHEN imp_anticipato >= 0
                         AND imp_anticipato IS NOT NULL THEN
                        imp_anticipato
                END
            ) AS imp_anticipato_distinte_presenta,-- MODIFICA 19/10/2023
            data_riferimento,
            abi_banca,
            rapporto,
            servizio
        FROM
            s2a.partite_portafoglio_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
        GROUP BY
            data_riferimento,
            abi_banca,
            rapporto,
            servizio
    ) pp ON rapp.cod_abi = pp.abi_banca
            AND rapp.data_riferimento = pp.data_riferimento
            AND rapp.cod_servizio = pp.servizio
            AND rapp.cod_rapporto = pp.rapporto
    LEFT JOIN (
  SELECT
            SUM(imp_anticipato_partita) AS imp_anticipato_fatt_scadute,
            abi_banca,
            data_riferimento,
            servizio,
            rapporto
        FROM
            s2a.partite_sbf_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
            AND ( EXTRACT(MONTH FROM data_valuta_partita) = EXTRACT(MONTH FROM data_riferimento)) -- MODIFICA 20/10/11
            AND ( EXTRACT(YEAR FROM data_valuta_partita) = EXTRACT(YEAR FROM data_riferimento))
            AND imp_anticipato_partita IS NOT NULL
            AND imp_anticipato_partita >= 0
        GROUP BY
            data_riferimento,
            abi_banca,
            rapporto,
            servizio
    ) sbf ON rapp.cod_abi = sbf.abi_banca
             AND rapp.data_riferimento = sbf.data_riferimento
             AND rapp.cod_servizio = sbf.servizio
             AND rapp.cod_rapporto = sbf.rapporto
    LEFT JOIN (
        SELECT
            CASE
                WHEN imp_utilizzato_fido_rapp IS NOT NULL
                     AND imp_utilizzato_fido_rapp >= 0 THEN
                    imp_utilizzato_fido_rapp
            END AS utilizzato_contabile,
            CASE
                WHEN imp_accordato_fido_rapp IS NOT NULL
                     AND imp_accordato_fido_rapp >= 0 THEN
                    imp_accordato_fido_rapp
            END AS fido_operativo_contabile,
            abi_banca,
            data_riferimento,
            servizio,
            rapporto
        FROM
            s2a.rischio_diretto_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
            AND tipo_record = 'FR'-- MODIFICA 20/10/2023
    ) rischio ON rapp.cod_abi = rischio.abi_banca
                 AND rapp.data_riferimento = rischio.data_riferimento
                 AND rapp.cod_servizio = rischio.servizio
                 AND rapp.cod_rapporto = rischio.rapporto
    LEFT JOIN (
        SELECT
            CASE
                WHEN servizio = 'EP5' THEN
                    'SI'
                ELSE
                    'NO'
            END AS flag_anticipo_estero,
            abi_banca,
            cag_intestatario,
            servizio,
            rapporto,
            data_riferimento
        FROM
            s2a.master_crediti_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
    ) master ON rapp.cod_abi = master.abi_banca
                AND rapp.cod_cag = master.cag_intestatario
                AND rapp.data_riferimento = master.data_riferimento
                AND rapp.cod_servizio = master.servizio
                AND rapp.cod_rapporto = master.rapporto
    LEFT JOIN (
        SELECT
            CASE
                WHEN servizio = 'EP5'
                     AND cod_prodotto IN ( 'FINIMP22', 'TRAIMP22' ) THEN
                    cod_prodotto
                ELSE
                    NULL
            END AS flag_finanziamenti_importaz,
            abi_banca,
            cag_intestatario,
            servizio,
            rapporto,
            data_riferimento
        FROM
            s2a.finanziamenti_estero_all
        WHERE
                abi_banca = '----'
            AND data_riferimento = '28-FEB-2023'
            AND cod_prodotto IN ( 'FINIMP22', 'TRAIMP22' )
    ) finanziamenti ON rapp.cod_abi = finanziamenti.abi_banca
                       AND rapp.cod_cag = finanziamenti.cag_intestatario
                       AND rapp.data_riferimento = finanziamenti.data_riferimento
                       AND rapp.cod_servizio = finanziamenti.servizio
                       AND rapp.cod_rapporto = finanziamenti.rapporto