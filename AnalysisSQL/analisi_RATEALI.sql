-- LAST UPDATE: 31/10/2023 IN LEFT INVECE CHE INNER CON LA RISCHIO DIRETTO COME DA MAPING

SELECT
    mutui.cod_abi,
    mutui.cod_cag,
    mutui.cag_gruppo_ccb,
    mutui.cod_servizio,
    mutui.cod_rapporto,
    mutui.data_riferimento,
    NULL AS mft,
    piani.quota_interessi_rate_scad_mora,
    piani.quota_interessi_rate_scad_impaga,
    piani.quota_capitale_rate_scad_mora,
    piani.quota_capitale_rate_scad_impagat,
    piani.numero_rate_mora,
    piani.numero_rate_impagate,
    piani.imp_rate_impagate,
    fidi.fido_operat_contab,
    fidi.fido_residuo,
    mutui.imp_orig_fido,
    piani.imp_rate_mora,
    movimenti.imp_ultima_rata_scad,
    mutui.utilizzato_contab,
    mutui.utilizzato,
    mutui.tipo_prodotto,
    mutui.data_accensione_rapp,
    mutui.data_scadenza_rapp,
    mutui.periodicita_rata,
    mutui.data_estinzione_rapp
FROM
         (
        SELECT
            abi_banca                      AS cod_abi,
            cag_intestatario               AS cod_cag,
            cag_gruppo_intestatario        AS cag_gruppo_ccb,
            servizio                       AS cod_servizio,
            rapporto                       AS cod_rapporto,
            data_riferimento,
            imp_erogato                    AS imp_orig_fido,
            IMP_COSTO_AMMORTIZZATO         AS utilizzato_contab,------
            IMP_DEBITO_RESIDUO             AS utilizzato,       -----
            cod_prodotto                   AS tipo_prodotto,
            least(
			data_erogazione,
			data_inizio_piano_ammortam,
            data_inizio_preammortam)       AS data_accensione_rapp,
            data_scadenza_rapporto         AS data_scadenza_rapp,
            cod_freq_pagamento_ammortam    AS periodicita_rata,
            data_estinzione_rapporto       AS data_estinzione_rapp
        FROM
            S2A.MUTUI_ALL
        WHERE
                abi_banca = '-----'
            AND data_riferimento = '28-feb-2023'
    ) mutui
    JOIN (
        SELECT
            abi_banca
        FROM
            dwhevo.rsk_wk_anagrafica_banche_societa
        WHERE
            cod_gruppo IN ( 1, 2, 3 )
            AND abi_banca = '-----'
            AND data_inizio_validita < '28-feb-2023'
            AND data_fine_validita >= '28-feb-2023'
    ) abs ON mutui.cod_abi = abs.abi_banca
    LEFT JOIN (
        SELECT
            abi_banca,
            data_riferimento,
            servizio,
            rapporto_id_partita,
            SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento
                         AND data_mora IS NOT NULL THEN
                        imp_quota_interessi
                    ELSE
                        NULL
                END
            ) AS quota_interessi_rate_scad_mora,
            SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento THEN
                        imp_quota_interessi
                    ELSE
                        NULL
                END
            ) AS quota_interessi_rate_scad_impaga,
            SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento 
                     AND data_mora IS NOT NULL
                     THEN
                        imp_quota_capitale
                    ELSE
                        NULL
                END
            ) AS quota_capitale_rate_scad_mora,
            SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento THEN
                        imp_quota_capitale
                    ELSE
                        NULL
                END
            ) AS quota_capitale_rate_scad_impagat,
            COUNT(
                CASE
                    WHEN data_scadenza_rata < data_riferimento
                         AND data_mora IS NOT NULL THEN
                        rapporto_id_partita
                END
            ) AS numero_rate_mora,
            COUNT(
                CASE
                    WHEN data_scadenza_rata < data_riferimento THEN
                        rapporto_id_partita
                END
            ) AS numero_rate_impagate,
            ROUND(
                SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento THEN
                        imp_quota_capitale + imp_quota_interessi
                    ELSE
                        NULL
                END
                ),2
            ) AS imp_rate_impagate,
            SUM(
                CASE
                    WHEN data_scadenza_rata < data_riferimento
                         AND data_mora IS NOT NULL THEN
                        imp_quota_capitale + imp_quota_interessi
                    ELSE
                        NULL
                END
            ) AS imp_rate_mora
        FROM
            dwhevo.crewkvw_piani_ammortamento
        WHERE
                abi_banca = '------'
            AND data_riferimento = '28-feb-2023'
        GROUP BY
            abi_banca,
            data_riferimento,
            servizio,
            rapporto_id_partita
    ) piani ON mutui.cod_abi = piani.abi_banca
               AND mutui.data_riferimento = piani.data_riferimento
               AND mutui.cod_servizio = piani.servizio
               AND mutui.cod_rapporto = piani.rapporto_id_partita
    LEFT JOIN ( -- 31/10/2023 LEFT INVECE CHE INNER COME DA TRACCIATO(SUL MAPPING ERA GIà CORRETTO)
        SELECT
            id_fido,
            abi_banca,
            data_riferimento,
            servizio,
            rapporto
        FROM
            s2a.rischio_diretto_all
        WHERE
                abi_banca = '------'
            AND data_riferimento = '28-FEB-2023'
            and tipo_record = 'FR'

    ) rischio ON mutui.cod_abi = rischio.abi_banca
                 AND mutui.data_riferimento = rischio.data_riferimento
                 AND mutui.cod_servizio = rischio.servizio
                 AND mutui.cod_rapporto = rischio.rapporto
    LEFT JOIN (
        SELECT
            importo_accord_operativo_div AS fido_operat_contab,
            importo_accordato_divisa     AS fido_residuo,
            id_fido,
            abi_banca,
            data_riferimento
        FROM
            s2a.fidi_all
        WHERE
                abi_banca = '-----'
            AND data_riferimento = '28-FEB-2023'
    ) fidi ON mutui.cod_abi = fidi.abi_banca
              AND mutui.data_riferimento = fidi.data_riferimento
              AND rischio.id_fido = fidi.id_fido
      LEFT JOIN (
        SELECT
            CASE
                WHEN DATA_MOVIMENTO IS NULL THEN
                    NVL(imp_quota_capitale_cliente,0)
				ELSE 
					NVL(imp_quota_capitale_cliente,0) + NVL(imp_capitale_accontato,0)
            END AS imp_ultima_rata_scad,
            abi_banca,
            data_riferimento,
            rapporto
        FROM
            dwhevo.rsk_wk_movimenti_mutui
        WHERE
            abi_banca = '-----'
            AND data_riferimento = '28-feb-2023'
			and num_rata is not null
			and cod_tipo_movimento = 'PR'
	 AND data_scadenza_rata BETWEEN TRUNC(data_riferimento, 'MM')
                               AND (TRUNC(data_riferimento, 'MM') + INTERVAL '1' MONTH - INTERVAL '1' DAY)
    ) movimenti ON mutui.cod_abi = movimenti.abi_banca
                   AND mutui.data_riferimento = movimenti.data_riferimento
                   AND mutui.cod_rapporto = movimenti.rapporto