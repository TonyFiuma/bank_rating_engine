-- DWHEVO.CREDITIDIFIRMA

-- LAST UPDATE: 04/03/2024


-- controllo numeriche

select DATA_RIFERIMENTO
    ,ABI_BANCA
    ,SERVIZIO
    ,RAPPORTO
    ,CAG_INTESTATARIO 
from (
    select 
        sorgente.*,
        rank() over(partition by DATA_RIFERIMENTO,ABI_BANCA,SERVIZIO,RAPPORTO order by RAPPORTO_ID_PARTITA) dedup
    from (
        select 
            DATA_RIFERIMENTO
            ,ABI_BANCA
            ,SERVIZIO
            ,RAPPORTO
            ,CAG_INTESTATARIO
            ,RAPPORTO_ID_PARTITA
        from s2a.crediti_firma_all
        where abi_banca = '----'
            and data_riferimento = to_date('20230630','yyyymmdd')
            AND COD_STATO_RAPPORTO != 'E'
            AND SERVIZIO = 'F90'
            AND NVL(COD_CATEGORIA,'-1') NOT  IN('11','31')
        union all
        select 
            DATA_RIFERIMENTO
            ,ABI_BANCA
            ,SERVIZIO
            ,RAPPORTO
            ,CAG_INTESTATARIO
            ,RAPPORTO_ID_PARTITA
        from s2a.CREDITI_FIRMA_ESTERO_all
        where abi_banca = '----'
            and data_riferimento = to_date('20230630','yyyymmdd')
            AND COD_STATO_RAPPORTO != 'E'
            AND SERVIZIO = 'EP6'
    ) sorgente
)
where dedup = 1
minus
select DATA_RIFERIMENTO
    ,cod_Abi
    ,cod_SERVIZIO
    ,cod_RAPPORTO
    ,cod_CAG
from dwhevo.rsk_dm_andint_creditidifirma
where cod_Abi = '----'
    and data_riferimento = to_date('20230630','yyyymmdd')
;






-- controllo campi

SELECT
    cf.cod_abi,
    cf.cod_cag,
    cf.cag_gruppo_ccb,
    cf.cod_servizio,
    cf.cod_rapporto,
    cf.data_riferimento,
    cf.data_accensione_rapp,
    cf.data_scadenza_rapp,
    cf.data_estinzione_rapp,
    IMP_ESPOSIZIONE_RAPP as UTILIZZATO_FIRMA,
    IMP_ACCORDATO_FIDO_RAPP as FIDO_OPERATIVO_FIRMA
FROM (
select *
from (
    select 
        sorgente.*,
        rank() over(partition by DATA_RIFERIMENTO,cod_abi,cod_servizio,cod_rapporto order by RAPPORTO_ID_PARTITA) dedup
    from (
        select 
            abi_banca                    AS cod_abi,
            cag_intestatario             AS cod_cag,
            cag_gruppo_intestatario      AS cag_gruppo_ccb,
            servizio                     AS cod_servizio,
            rapporto                     AS cod_rapporto,
            data_riferimento,
            data_apertura_rapporto       AS data_accensione_rapp,
            data_scadenza_rapporto       AS data_scadenza_rapp,
            nvl(rapporto_id_partita,-1)  AS RAPPORTO_ID_PARTITA,
            data_estinzione_rapporto      AS data_estinzione_rapp
        from s2a.crediti_firma_all
        where abi_banca = '08883'
            and data_riferimento = to_date('20230630','yyyymmdd')
            AND COD_STATO_RAPPORTO != 'E'
            AND SERVIZIO = 'F90'
            AND NVL(COD_CATEGORIA,'-1') NOT  IN('11','31')
        union all
        select 
            abi_banca                    AS cod_abi,
            cag_intestatario             AS cod_cag,
            cag_gruppo_intestatario      AS cag_gruppo_ccb,
            servizio                     AS cod_servizio,
            rapporto                     AS cod_rapporto,
            data_riferimento,
            data_apertura_rapporto       AS data_accensione_rapp,
            data_scadenza_rapporto       AS data_scadenza_rapp,
            nvl(rapporto_id_partita,-1)  AS RAPPORTO_ID_PARTITA,
            data_estinzione_rapporto      AS data_estinzione_rapp
        from s2a.CREDITI_FIRMA_ESTERO_all
        where abi_banca = '08883'
            and data_riferimento = to_date('20230630','yyyymmdd')
            AND COD_STATO_RAPPORTO != 'E'
            AND SERVIZIO = 'EP6'
        ) sorgente
    )
    where dedup = 1
) cf
LEFT JOIN (
    SELECT
        data_riferimento,
        abi_banca,
        servizio,
        rapporto,
        round(sum(
            case
                when TIPO_RECORD = 'R' then IMP_ESPOSIZIONE_RAPP
                else 0
            end
            ), 2
          ) IMP_ESPOSIZIONE_RAPP,
        round(sum(
            case
                when TIPO_RECORD = 'FR' then IMP_ACCORDATO_FIDO_RAPP
                else 0
            end
            ), 2
          ) IMP_ACCORDATO_FIDO_RAPP
    FROM s2a.rischio_diretto_all
    WHERE abi_banca = '08883'
        AND data_riferimento = to_date('20230630','yyyymmdd')
        AND COD_CATEGORIA_CR != 'N'
        and SERVIZIO in ('F90', 'EP6')
    group by 
        data_riferimento,
        abi_banca,
        servizio,
        rapporto
    ) rischio 
    ON cf.cod_servizio = rischio.servizio
    AND cf.cod_rapporto = rischio.rapporto
    AND cf.cod_abi = rischio.abi_banca
minus
select 
    cod_abi,
    cod_cag,
    cag_gruppo_ccb,
    cod_servizio,
    cod_rapporto,
    data_riferimento,
    data_accensione_rapp,
    data_scadenza_rapp,
    data_estinzione_rapp,
    UTILIZZATO_FIRMA,
    FIDO_OPERATIVO_FIRMA
from dwhevo.rsk_dm_andint_creditidifirma
where cod_Abi = '08883'
    and data_riferimento = to_date('20230630','yyyymmdd')
--    and cod_rapporto = '0011073'