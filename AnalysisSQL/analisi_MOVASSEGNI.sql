
SELECT
    abi_banca               AS cod_abi,
    cag_intestatario        AS cod_cag,
    cag_gruppo_intestatario AS cag_gruppo_ccb,
    servizio                AS cod_servizio,
    rapporto                AS cod_rapporto,
    data_riferimento
FROM s2a.conti_correnti_all
WHERE abi_banca = '----'
    AND data_riferimento = to_Date('20230630','yyyymmdd')
    AND COD_STATO_RAPPORTO != 'E'
    AND COD_TIPO_CONTO_CORRENTE IN('0', '2', '3')
    AND SERVIZIO = 'C01'
    and cod_classif_applicativa != '014'
    and cod_categoria_collegamento not in ('PAVI','WMUT','WTE1','WTE2','GPAT')
minus
select
    cod_abi,
    cod_cag,
    cag_gruppo_ccb,
    cod_servizio,
    cod_rapporto,
    data_riferimento	
from dwhevo.rsk_dm_andint_movassegni
where data_riferimento = to_date('20230630','yyyymmdd')
    and cod_abi = '-----'
--    and cod_rapporto = '14000073621'
;




SELECT
    cc.cod_abi,
    cc.cod_cag,
    cc.cag_gruppo_ccb,
    cc.cod_servizio,
    cc.cod_rapporto,
    cc.data_riferimento,
    assegni.importo_assegni_impagati, 	        
    assegni.importo_assegni_protestati, 	    
    assegni.importo_assegni_sospesi,	  	    
    movimenti.importo_movimenti_avere,  	    
    movimenti.importo_movimenti_dare, 		    
    assegni.numero_assegni_impagati,       	    
    assegni.numero_assegni_protestati,     	    
    assegni.numero_assegni_sospesi,        	    
    movimenti.numero_movimenti_avere, 			
    movimenti.numero_movimenti_dare		    	
FROM (
        SELECT
            abi_banca               AS cod_abi,
            cag_intestatario        AS cod_cag,
            cag_gruppo_intestatario AS cag_gruppo_ccb,
            servizio                AS cod_servizio,
            rapporto                AS cod_rapporto,
            data_riferimento
        FROM s2a.conti_correnti_all
        WHERE abi_banca = '------'
            AND data_riferimento = to_Date('20230630','yyyymmdd')
            AND COD_STATO_RAPPORTO != 'E'
            AND COD_TIPO_CONTO_CORRENTE IN('0', '2', '3')
            AND SERVIZIO = 'C01'
            and cod_classif_applicativa != '014'
            and cod_categoria_collegamento not in ('PAVI','WMUT','WTE1','WTE2','GPAT')
    ) cc
    LEFT JOIN (
        SELECT
            SUM(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'J'
                         AND imp_facciale >= 0 
                         AND imp_facciale IS NOT NULL THEN -- modifica 19/10/2023
                        imp_facciale
                END
            ) AS importo_assegni_impagati,
            SUM(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'T'
                         AND imp_facciale >= 0 
                         AND imp_facciale IS NOT NULL THEN -- modifica 19/10/2023
                        imp_facciale
                END
            ) AS importo_assegni_protestati,
            SUM(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'L'
                         AND imp_facciale >= 0 
                         AND imp_facciale IS NOT NULL THEN -- modifica 19/10/2023
                        imp_facciale
                END
            ) AS importo_assegni_sospesi,
            COUNT(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'J' 
                    AND imp_facciale >= 0 
                    AND num_assegno IS NOT NULL THEN    -- modifica 19/10/2023
                        num_assegno
                END
            ) AS numero_assegni_impagati,
            COUNT(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'T' 
                    AND imp_facciale >= 0 
                    AND num_assegno IS NOT NULL THEN  -- modifica 19/10/2023
                        num_assegno
                END
            ) AS numero_assegni_protestati,
            COUNT(
                CASE
                    WHEN cod_stato_aggregato_assegno = 'L' 
                    AND imp_facciale >= 0 
                    AND num_assegno IS NOT NULL THEN   -- modifica 19/10/2023
                        num_assegno
                END
            ) AS numero_assegni_sospesi,
            abi_banca,
            data_riferimento,
            servizio_conto_versamento,
            rapporto_conto_versamento
        FROM s2a.assegni_negoziati_all
        WHERE abi_banca = '-----'
            AND DATA_RIFERIMENTO <= TO_DATE('20230630','YYYYMMDD') 
            AND DATA_RIFERIMENTO > ADD_MONTHS(TO_DATE('20230630','YYYYMMDD'),-1)
        GROUP BY
            abi_banca,
            data_riferimento,
            servizio_conto_versamento,
            rapporto_conto_versamento
    ) assegni ON cc.cod_abi = assegni.abi_banca
                 AND cc.data_riferimento = assegni.data_riferimento
                 AND cc.cod_servizio = assegni.servizio_conto_versamento
                 AND cc.cod_rapporto = assegni.rapporto_conto_versamento
    LEFT JOIN (
        SELECT
            round(SUM(
                CASE
                    WHEN cod_segno_monetario = 'A'
                         AND cod_spesa = '1'
                         AND imp_operazione is not null THEN
                        imp_operazione
                    ELSE
                        NULL
                END
            ), 3) AS importo_movimenti_avere,-- MODIFICA 16/10/2023 
            round(SUM(
                CASE
                    WHEN cod_segno_monetario = 'D'
                         AND cod_spesa = '1'
                         AND imp_operazione is not null THEN
                        imp_operazione
                    ELSE
                        NULL
                END
            ), 3) AS importo_movimenti_dare, -- MODIFICA 16/10/2023
            COUNT(
                CASE
                    WHEN cod_segno_monetario = 'A'
                         AND cod_spesa = '1'
                         AND imp_operazione is not null THEN
                        rapporto
                END
            )     AS numero_movimenti_avere,-- modifica 17/10/2023
            COUNT(
                CASE
                    WHEN cod_segno_monetario = 'D'
                         AND cod_spesa = '1'
                         AND imp_operazione is not null THEN
                        rapporto
                END
            )     AS numero_movimenti_dare,-- modifica 17/10/2023
            abi_banca,
            data_riferimento,
            servizio,
            rapporto
        FROM s2a.movimenti_conto_corrente_all
        WHERE  abi_banca = '------'
            AND DATA_RIFERIMENTO <= TO_DATE('20230630','YYYYMMDD') 
            AND DATA_RIFERIMENTO > ADD_MONTHS(TO_DATE('20230630','YYYYMMDD'),-1)
        GROUP BY
            rapporto,
            servizio,
            data_riferimento,
            abi_banca
    ) movimenti ON cc.cod_abi = movimenti.abi_banca
                   AND cc.data_riferimento = movimenti.data_riferimento
                   AND cc.cod_servizio = movimenti.servizio
                   AND cc.cod_rapporto = movimenti.rapporto
minus
select
    cod_abi,
    cod_cag,
    cag_gruppo_ccb,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    importo_assegni_impagati, 	        
    importo_assegni_protestati, 	    
    importo_assegni_sospesi,	  	    
    importo_movimenti_avere,  	    
    importo_movimenti_dare, 		    
    numero_assegni_impagati,       	    
    numero_assegni_protestati,     	    
    numero_assegni_sospesi,        	    
    numero_movimenti_avere, 			
    numero_movimenti_dare	
from dwhevo.rsk_dm_andint_movassegni
where data_riferimento = to_date('20230630','yyyymmdd')
    and cod_abi = '-----'
--    and cod_rapporto = '14000141406'