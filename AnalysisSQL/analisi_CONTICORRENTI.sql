-- CHECK DATI CONTI CORRENTI NON AGGREGATI

select 
    DATA_RIFERIMENTO
    ,ABI_BANCA
    ,SERVIZIO
    ,RAPPORTO
    ,CAG_GRUPPO_INTESTATARIO
    ,CAG_INTESTATARIO
    ,DATA_APERTURA_RAPPORTO
    ,DATA_ESTINZIONE_RAPPORTO
    ,DIVISA
from S2A.CONTI_CORRENTI_ALL
where ABI_BANCA = '-----'
    and DATA_RIFERIMENTO = to_date('20230630','yyyymmdd')
    and COD_TIPO_CONTO_CORRENTE IN ('0','2','3')
    and SERVIZIO = 'C01'
    and COD_CATEGORIA_COLLEGAMENTO not IN('PAVI','WMUT','WTE1','WTE2','GPAT')
    and cod_classif_applicativa != '014'
    and COD_STATO_RAPPORTO != 'E'
    and IMP_SALDO_CONTABILE_NEGATIVO <= 0
    and NOT(COD_CATEGORIA_COLLEGAMENTO = 'ORDI' and  IMP_SALDO_CONTABILE_IN_DIVISA = 0)
    and RAPPORTO = '11000060460'
minus
select 
    DATA_RIFERIMENTO
    ,COD_ABI
    ,COD_SERVIZIO
    ,COD_RAPPORTO
    ,CAG_GRUPPO_CCB
    ,COD_CAG
    ,DATA_APERTURA_RAPPORTO
    ,DATA_ESTINZIONE_RAPPORTO
    ,DIVISA
from dwhevo.rsk_dm_andint_conticorrenti
where data_riferimento = TO_DATE('20230630','YYYYMMDD')
    and COD_RAPPORTO = '11000060460'
;



-- CHECK IMPORTI

select 
    ABI_BANCA
    ,SERVIZIO
    ,RAPPORTO
    ,UTILIZZATO
    ,round(SALDO_MEDIO_CONTABILE_A_NUM/greatest(SALDO_MEDIO_CONTABILE_A_DEN,1),2) as SALDO_MEDIO_CONTABILE_A
    ,round(SALDO_MEDIO_CONTABILE_D_NUM/greatest(SALDO_MEDIO_CONTABILE_D_DEN,1),2) as SALDO_MEDIO_CONTABILE_D
    ,DIVISA
from (
    select
        ABI_BANCA
        ,SERVIZIO
        ,RAPPORTO
        ,max(case when DATA_RIFERIMENTO=TO_DATE('20230331','YYYYMMDD') then IMP_SALDO_CONTABILE_NEGATIVO else -999999999999 end) AS UTILIZZATO
        ,max(case when DATA_RIFERIMENTO=TO_DATE('20230331','YYYYMMDD') then IMP_SALDO_CONTABILE else -999999999999 end) as SALDO_CONTABILE
        ,sum(case when IMP_SALDO_CONTABILE>=0 then IMP_SALDO_CONTABILE else 0 end) as SALDO_MEDIO_CONTABILE_A_NUM
        ,sum(case when IMP_SALDO_CONTABILE>=0 then 1 else 0 end) as SALDO_MEDIO_CONTABILE_A_DEN
        ,sum(case when IMP_SALDO_CONTABILE<0 then IMP_SALDO_CONTABILE else 0 end) as SALDO_MEDIO_CONTABILE_D_NUM
        ,sum(case when IMP_SALDO_CONTABILE<0 then 1 else 0 end) as SALDO_MEDIO_CONTABILE_D_DEN
        ,DIVISA
    from (
        select 
            cc.DATA_RIFERIMENTO
            ,ABI_BANCA
            ,SERVIZIO
            ,RAPPORTO
            ,IMP_SALDO_CONTABILE_NEGATIVO
            ,case when TASSO_CAMBIO_BCE is null then 0 else IMP_SALDO_CONTABILE_IN_DIVISA/TASSO_CAMBIO_BCE end as IMP_SALDO_CONTABILE
            ,cc.DIVISA
        from (
            select DATA_RIFERIMENTO,ABI_BANCA,SERVIZIO,RAPPORTO,IMP_SALDO_CONTABILE_IN_DIVISA,DIVISA,IMP_SALDO_CONTABILE_NEGATIVO
            from S2A.CONTI_CORRENTI_ALL
            where ABI_BANCA = '-----'
                and DATA_RIFERIMENTO between to_date('20230601','yyyymmdd') and  to_date('20230630','yyyymmdd')
--                and DATA_RIFERIMENTO = to_date('20230331','yyyymmdd')
                and COD_TIPO_CONTO_CORRENTE IN ('0','2','3')
                and SERVIZIO = 'C01'
                and COD_CATEGORIA_COLLEGAMENTO not IN('PAVI','WMUT','WTE1','WTE2','GPAT')
                and cod_classif_applicativa != '014'
                and COD_STATO_RAPPORTO != 'E'
                and IMP_SALDO_CONTABILE_NEGATIVO <= 0
                and NOT(COD_CATEGORIA_COLLEGAMENTO = 'ORDI' and  IMP_SALDO_CONTABILE_IN_DIVISA = 0)
                and RAPPORTO = '38000382326'
            ) CC
        LEFT join (
            select DATA_RIFERIMENTO, DIVISA, TASSO_CAMBIO_BCE
            from s2a.tassi_cambio
            where data_riferimento between to_date('20230301','yyyymmdd') and  to_date('20230331','yyyymmdd')
            ) tc
            on cc.data_riferimento = tc.data_riferimento
            and cc.divisa = tc.divisa
        )
    group by ABI_BANCA
        ,SERVIZIO
        ,RAPPORTO
        ,DIVISA
    )
minus
select 
    cod_ABI
    ,cod_SERVIZIO
    ,cod_RAPPORTO    
    ,UTILIZZATO
    ,SALDO_MEDIO_CONTABILE_A
    ,SALDO_MEDIO_CONTABILE_D
    ,DIVISA
from dwhevo.rsk_dm_andint_conticorrenti
where data_riferimento = TO_DATE('20230331','YYYYMMDD')
--    and cod_rapporto = '10000101525'
;



-- CHECK GIORNI SCONFINAMENTO
select 
    cc.ABI_BANCA, cc.SERVIZIO, cc.RAPPORTO, NVL(sc.NUM_GG_SCONFINO,0), NVL(sc.NUM_MAX_GG_SCONF_CONSEC,0) 
from (
    select DATA_RIFERIMENTO,ABI_BANCA,SERVIZIO,RAPPORTO,IMP_SALDO_CONTABILE_IN_DIVISA,DIVISA
    from S2A.CONTI_CORRENTI_ALL
    where ABI_BANCA = '----'
        and DATA_RIFERIMENTO = to_date('20230630','yyyymmdd')
        and COD_TIPO_CONTO_CORRENTE IN ('0','2','3')
        and SERVIZIO = 'C01'
        and COD_CATEGORIA_COLLEGAMENTO not IN('PAVI','WMUT','WTE1','WTE2','GPAT')
        and cod_classif_applicativa != '014'
        and COD_STATO_RAPPORTO != 'E'
        and IMP_SALDO_CONTABILE_NEGATIVO <= 0
        and NOT(COD_CATEGORIA_COLLEGAMENTO = 'ORDI' and  IMP_SALDO_CONTABILE_IN_DIVISA = 0)
--                and RAPPORTO = '11000060460'
    ) CC
LEFT join (
    select ABI_BANCA, SERVIZIO, RAPPORTO, count(1) as NUM_GG_SCONFINO, max(NUM_GIORNI_SCONFINO) as NUM_MAX_GG_SCONF_CONSEC 
    from S2A.sconfinamenti_all s
    where data_riferimento between to_date('20230601','yyyymmdd') and to_date('20230630','yyyymmdd')
        AND abi_banca = '----'
        AND NUM_GIORNI_SCONFINO > 0
    group by ABI_BANCA, SERVIZIO, RAPPORTO
    ) sc
    on cc.ABI_BANCA = sc.ABI_BANCA
    and cc.SERVIZIO = sc.SERVIZIO
    and cc.RAPPORTO = sc.RAPPORTO
minus
select COD_ABI, COD_SERVIZIO, COD_RAPPORTO, NVL(NUM_GG_SCONFINO,0), NVL(NUM_MAX_GG_SCONF_CONSEC,0)
from dwhevo.rsk_dm_andint_conticorrenti
where data_riferimento = TO_DATE('20230630','YYYYMMDD')
    AND COD_ABI = '----'
;