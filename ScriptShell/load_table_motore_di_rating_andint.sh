#!/usr/bin/ksh
#
# =====================================================
# Nuovo Motore di Rating - Modulo Andamentale Interno 
# Progetto PRO220083 
#
# Creation Date: 26.06.2023
# Author       : AF
# Version      : 1.0 
# =====================================================
#
# Path principale
ROOT_DIR=/opt/dwhevo

#
# Librerie
#
. ${ROOT_DIR}/script/lib/setenv_$ID_APPLICATION.sh
. ${ROOT_DIR}/script/lib/lib_file.sh
. ${ROOT_DIR}/script/lib/lib_log.sh

#
# Directories di lavoro
#
DIR_SCRIPT=${ROOT_DIR}/script/motore_di_rating
DIR_BAD=${ROOT_DIR}/work/
DIR_STOR=${ROOT_DIR}/work/dati/storico
DIR_WORK=${ROOT_DIR}/work/dati/motore_di_rating
DIR_WORK_BCK=${ROOT_DIR}/work/dati/motore_di_rating/bck
DIR_CTL=${ROOT_DIR}/script/motore_di_rating
DIR_LOG=${ROOT_DIR}/log
DIR_PARAM=${ROOT_DIR}/script/param/motore_di_rating

NOME_ELABORAZIONE="Popolamento tabella fisica DWHEVO per Modulo Andamentale Interno + Controlli quantitativi su ABI"
VERSION="1.0"

#$5 se passati -d e -s
if [ -z "$5" ]; then
	if [ -z "$4" ]; then
		P_COD_PROD=
		PROCESSO_DINAMICO=
	else
		P_COD_PROD=$4
		PROCESSO_DINAMICO=$4
	fi
else
	P_COD_PROD=$5
	PROCESSO_DINAMICO=$5
fi


usage() {
     echo "${NOME_ELABORAZIONE}"
     echo "${VERSION} "
     echo "Usage $0 [ -d DATE ] [ -s SCOPE ]" 1>&2
     echo " <DATE> data di riferimento del flusso in formato YYYYMMDD"
     echo "        (19000101 tutte le date)"
     echo " <SCOPE> ABI"
}

check_param() {
     if [ -z "$DATA_DA_ELABORARE" ]; then
      	echo "Parametro data da elaborare assente"
      	usage
      	exit
     fi
     if [ -z "$COD_SOC" ]; then
      	echo "Parametro ABI assente"
      	usage
      	exit
     fi
	SCOPE=${COD_SOC}
}

do_work()
{
	log_work_start
	check_param

	log_info "${NOME_ELABORAZIONE}: elaborazione in data ${DATA_DA_ELABORARE}"
	log_info "Versione: "${VERSION}

	# Imposta nome file e parametri del WorkFlow
	WF_FOLDER="MOTORE_DI_RATING"
	WF_NAME="wf_LOAD_ANDAMENTALE_INTERNO"
	WF_PARAMFILE_TEMPLATE=${DIR_PARAM}/MOTORE_DI_RATING_ANDINT.par
	WF_PARAMFILE=${DIR_PARAM}/MOTORE_DI_RATING_ANDINT_${COD_SOC}.par
	
	# Valorizzo il paramfile
	awk -v DT_RIF=${DATA_DA_ELABORARE} -v ABI=${COD_SOC} '{ gsub("DT_RIFERIMENTO=(........)","DT_RIFERIMENTO="DT_RIF); gsub("ABI=(.....)","ABI="ABI); print }' ${WF_PARAMFILE_TEMPLATE} > ${DIR_PARAM}/tmp_MOTORE_DI_RATING_ANDINT_${COD_SOC}.par && mv ${DIR_PARAM}/tmp_MOTORE_DI_RATING_ANDINT_${COD_SOC}.par ${WF_PARAMFILE}
	if [[ $? != 0 ]]; then
		log_error "Modifica file parametri ${WF_PARAMFILE} terminata con errore"
		log_work_failure
		return 1
	fi
				
	log_info "Modifica file parametri ${WF_PARAMFILE} completata"
	
	# Avvio il workflow
	set -A lv_nome_proc_list $WF_NAME
	lv_param_list[0]="-f ${WF_FOLDER} -paramfile ${WF_PARAMFILE}"

	typeset -i i=0
	while (( $i < ${#lv_nome_proc_list[*]} )) 
	do
		log_info "Inizio esecuzione ${lv_nome_proc_list[i]}(${lv_param_list[i]})"
		
		${INFORMATICA_INSTALL_DIR}/pmcmd startworkflow -wait -sv ${INFORMATICA_SERVICE} -d ${INFORMATICA_DOMAIN} -u ${INFORMATICA_USER} -p ${INFORMATICA_PASSWORD} -rin ${COD_SOC} ${lv_param_list[i]} ${lv_nome_proc_list[i]} 
		if [[ $? != 0 ]]; then
			log_error "Esecuzione ${lv_nome_proc_list[i]} terminata con errore"
			log_work_failure
			return 1
		fi

		(( i=i+1 ))
	done
				
	log_info "Esecuzione PowerCenter completata con successo"
	
	# Workflow controlli
	WF_NAME="wf_CONTROLLI_ANDAMENTALE_INTERNO"
	
	# Avvio il workflow
	set -A lv_nome_proc_list $WF_NAME
	lv_param_list[0]="-f ${WF_FOLDER} -paramfile ${WF_PARAMFILE}"

	typeset -i i=0
	while (( $i < ${#lv_nome_proc_list[*]} )) 
	do
		log_info "Inizio esecuzione ${lv_nome_proc_list[i]}(${lv_param_list[i]})"
		
		${INFORMATICA_INSTALL_DIR}/pmcmd startworkflow -wait -sv ${INFORMATICA_SERVICE} -d ${INFORMATICA_DOMAIN} -u ${INFORMATICA_USER} -p ${INFORMATICA_PASSWORD} -rin ${COD_SOC} ${lv_param_list[i]} ${lv_nome_proc_list[i]} 
		if [[ $? != 0 ]]; then
			log_error "Esecuzione ${lv_nome_proc_list[i]} terminata con errore"
			log_work_failure
			return 1
		fi

		(( i=i+1 ))
	done
	
	log_info "Esecuzione PowerCenter completata con successo"
	
	log_work_success
}

#
# Corpo dello script
#
log_start
set_log_debug

. ${ROOT_DIR}/script/lib/lib_leggi_opt.sh

if ! lib_log_opzioni $USA_STORICO $ORA_LIMITE; then
  log_error "Passaggio parametri alle funzioni di log --> OK"
fi

log_info "Elaborazione dati (do_work)..."
if ! do_work ; then
  log_error "Esecuzione funzione do_work --> FALLITA"
  lib_log_flusso_elab_error
  log_and_exit_error
fi

log_and_exit_success
