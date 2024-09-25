spool cr_prc_RSK_PRC_TRAS_MOT_RATING_TRUNC_PART_ABI.log
 
WHENEVER OSERROR  EXIT 9;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
SET SERVEROUTPUT ON
SET TIMING ON

create or replace PROCEDURE DWHEVO.RSK_PRC_TRAS_MOT_RATING_TRUNC_PART_ABI (p_table_name varchar2, p_field_abi varchar2)
IS
	v_long_value 			varchar2(300 char);
	v_partition_name 		varchar2(300 char);
	v_pk_constraint_name	varchar2(300 char);
	 
BEGIN
	
	-- Individuare la partizione con ABI = p_field_abi
	FOR i IN 
	(
		SELECT partition_name, 
			high_value 
		FROM all_tab_partitions
		WHERE table_owner = 'DWHEVO'
			and table_name = upper(p_table_name)
	) 
	LOOP
		v_long_value := i.high_value;
		-- Controllo sul valore
		IF v_long_value like '%'||p_field_abi||'%' THEN
			-- Salvare il nome della partizione in una variabile
			v_partition_name := i.partition_name;
			-- Truncate partition by name
			execute immediate 'alter table DWHEVO.'||p_table_name||' truncate partition '||v_partition_name;
		END IF;
	END LOOP;

END; 
/

spool off