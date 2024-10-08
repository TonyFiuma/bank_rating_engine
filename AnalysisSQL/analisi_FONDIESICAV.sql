--DWHEVO.FONDIESICAV 
--LAST UPDATE: 09/03/2024

SELECT 
    DT.DATA_RIFERIMENTO, DT.ABI_BANCA, DT.SERVIZIO, DT.ID_DOSSIER, DT.CAG_INTESTATARIO, 
    DT.CAG_GRUPPO_INTESTATARIO, SDT.CODICE_ISIN, sum(SDT.IMP_CONTROV_SECCO_EUR) as IMP_CONTROV_SECCO_EUR
--    ,DT.COD_STATO_DOSSIER, ATB.FLAG_TITOLO_ESTINTO, AT.FLAG_TITOLO_ESTINTO
FROM (
    SELECT DATA_RIFERIMENTO, ABI_BANCA, SERVIZIO, ID_DOSSIER, CAG_INTESTATARIO, CAG_GRUPPO_INTESTATARIO, COD_STATO_DOSSIER
    FROM S2A.DOSSIER_TITOLI_ALL
    WHERE DATA_RIFERIMENTO = TO_DATE('20230630','YYYYMMDD')
        and (cod_stato_dossier is null or cod_stato_dossier = 'N')
        AND ABI_BANCA = '-----'
    ) DT
JOIN (
    SELECT * --DATA_RIFERIMENTO, ABI_BANCA, SERVIZIO, ID_DOSSIER, CODICE_ISIN, IMP_CONTROV_SECCO_EUR
    FROM S2A.SALDI_DOSSIER_TITOLI_ALL
    WHERE DATA_RIFERIMENTO = TO_DATE('20230630','YYYYMMDD')
        AND ABI_BANCA = '-----'
        AND IMP_CONTROV_SECCO_EUR > 0
    ) SDT
ON DT.ABI_BANCA = SDT.ABI_BANCA
AND DT.ID_DOSSIER = SDT.ID_DOSSIER
JOIN (
    SELECT DATA_RIFERIMENTO, ABI_BANCA, CODICE_ISIN, FLAG_TITOLO_ESTINTO
    FROM S2A.ANAGRAFICA_TITOLI_BANCA_ALL
    WHERE DATA_RIFERIMENTO = TO_DATE('20230630','YYYYMMDD')
        AND FLAG_TITOLO_ESTINTO != 'S'
   ) ATB
ON ATB.CODICE_ISIN = SDT.CODICE_ISIN
AND ATB.ABI_BANCA = SDT.ABI_BANCA
JOIN (
    SELECT DATA_RIFERIMENTO, CODICE_ISIN, FLAG_TITOLO_ESTINTO
    FROM S2A.ANAGRAFICA_TITOLI
    WHERE DATA_RIFERIMENTO = TO_DATE('20230630','YYYYMMDD')
        AND FLAG_TITOLO_ESTINTO != 'S'
   ) AT
ON ATB.CODICE_ISIN = AT.CODICE_ISIN
GROUP BY DT.DATA_RIFERIMENTO, DT.ABI_BANCA, DT.SERVIZIO, DT.ID_DOSSIER, DT.CAG_INTESTATARIO, DT.CAG_GRUPPO_INTESTATARIO,  SDT.CODICE_ISIN
MINUS
SELECT DATA_RIFERIMENTO, COD_ABI, COD_SERVIZIO, COD_RAPPORTO, COD_CAG, CAG_GRUPPO_CCB, CODICE_ISIN, IMP_CONTROV_SECCO_EUR
FROM DWHEVO.RSK_DM_ANDINT_FONDIESICAV
WHERE DATA_RIFERIMENTO = TO_DATE('20230630','YYYYMMDD')
    AND COD_ABI = '-----'
;