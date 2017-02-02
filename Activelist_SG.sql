With securev

as

(SELECT DISTINCT PERSON_ID 
 FROM PER_PERSON_SECURED_LIST_V

)
,

AOL AS

(

SELECT pp.person_id MAIN_PERSON_ID
      , pp.BLOOD_TYPE
      , pp.Date_of_birth

                    ,(SELECT PERSON_NUMBER
            FROM PER_ALL_PEOPLE_F
           WHERE PERSON_ID = PP.PERSON_ID
             AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
       ) person_number
                    
					,(SELECT FLV.meaning
            FROM per_person_names_f pn, fnd_lookup_values flv
           WHERE pn.PERSON_ID = PP.PERSON_ID
             AND :D1 BETWEEN pn.EFFECTIVE_START_DATE AND pn.EFFECTIVE_END_DATE
             AND pn.name_type = 'GLOBAL'
             AND flv.lookup_type = 'TITLE'
             and flv.lookup_code = pn.title
             and flv.language = 'US'
             AND ROWNUM = 1
        ) pp_title
        
		-- ,(SELECT first_name
         -- FROM per_person_names_f
         -- WHERE PERSON_ID = PP.PERSON_ID
         -- AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         -- AND name_type = 'GLOBAL'
         -- AND ROWNUM = 1
        -- ) pp_first_name
		
		,ppnf.first_name pp_first_name
		,ppnf.last_name pp_last_name

       -- ,(SELECT last_name
         -- FROM per_person_names_f
         -- WHERE PERSON_ID = PP.PERSON_ID
         -- AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         -- AND name_type = 'GLOBAL'
         -- AND ROWNUM = 1
        -- ) pp_last_name
		,ppnf.middle_names pp_middle_names
		
         -- ,(SELECT middle_names
         -- FROM per_person_names_f
         -- WHERE PERSON_ID = PP.PERSON_ID
         -- AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         -- AND name_type = 'GLOBAL'
         -- AND ROWNUM = 1
        -- ) pp_middle_names

        ,(SELECT PEA.EMAIL_ADDRESS
		  FROM PER_EMAIL_ADDRESSES PEA
          WHERE pp.person_id=PEA.person_id
          AND PEA.EMAIL_TYPE = 'W1'
          AND :D1 BETWEEN DATE_FROM AND   NVL(DATE_TO,'4712-12-31')
          AND ROWNUM = 1
          ) pp_EMAIL_ADDRESS

         ,(SELECT ph.phone_number
           FROM PER_PHONES ph
           WHERE pp.person_id=ph.person_id
           AND ph.PHONE_TYPE = 'HM'
           AND :D1 BETWEEN DATE_FROM AND NVL(DATE_TO,'4712-12-31')
           AND ROWNUM = 1
			) pp_primary_phone
			
	,(SELECT ph.COUNTRY_CODE_NUMBER
           FROM PER_PHONES ph
           WHERE pp.person_id=ph.person_id
           AND ph.PHONE_TYPE = 'HM'
           AND :D1 BETWEEN DATE_FROM AND NVL(DATE_TO,'4712-12-31')
           AND ROWNUM = 1
			) pp_COUNTRY_CODE_NUMBER
			
				,(SELECT ph.AREA_CODE
           FROM PER_PHONES ph
           WHERE pp.person_id=ph.person_id
           AND ph.PHONE_TYPE = 'HM'
           AND :D1 BETWEEN DATE_FROM AND NVL(DATE_TO,'4712-12-31')
           AND ROWNUM = 1
			) pp_AREA_CODE

  

              , pp.TOWN_OF_BIRTH pp_TOWN_OF_BIRTH
              , pp.REGION_OF_BIRTH pp_REGION_OF_BIRTH
              , pp.country_of_birth

              ,( SELECT meaning
                 FROM fnd_lookup_values flt
                 WHERE flt.lookup_type   = 'PER_CORRESP_LANG'
                 and flt.lookup_code = pp.CORRESPONDENCE_LANGUAGE
                 AND LANGUAGE = 'US'
                 AND ROWNUM = 1
                 ) pp_lang
				 
				 
				 		 		,(SELECT VISA_PERMIT_TYPE
		FROM PER_VISAS_PERMITS_F
		WHERE PERSON_ID = pp.PERSON_ID
		AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
		AND ROWNUM = 1) visa_type
				 
			



FROM PER_PERSONS PP
,securev SV
,per_person_names_f ppnf
Where pp.person_id = sv.person_id
AND ppnf.person_id = sv.person_id
AND :D1 BETWEEN ppnf.EFFECTIVE_START_DATE AND ppnf.EFFECTIVE_END_DATE

and Exists
( SELECT 1
    FROM per_all_assignments_m paam
   WHERE paam.person_id = pp.person_id
     AND PAAM.WORK_TERMS_ASSIGNMENT_ID IS NOT NULL
	 AND PAAM.PRIMARY_FLAG = 'Y'
 AND :D1 BETWEEN PAAM.EFFECTIVE_START_DATE AND PAAM.EFFECTIVE_END_DATE
 AND PAAM.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'  
 AND PAAM.PRIMARY_WORK_RELATION_FLAG = 'Y'
 AND PAAM.SYSTEM_PERSON_TYPE IN ('EMP','CWK')


)

),

BOL AS

(

SELECT  AL.*

				    ,(SELECT manager_id
     FROM   PER_ASSIGNMENT_SUPERVISORS_F  PASF 
	 WHERE  PASF.PERSON_ID = PAAM.PERSON_ID
	 AND    PASF.ASSIGNMENT_ID = PAAM.ASSIGNMENT_ID
	 AND    :D1 BETWEEN PASF.EFFECTIVE_START_DATE AND PASF.EFFECTIVE_END_DATE
     AND MANAGER_TYPE = 'LINE_MANAGER'
     AND ROWNUM=1
	) manager_id
	
			,(SELECT USER_STATUS
            FROM PER_ASSIGNMENT_STATUS_TYPES_TL
	       WHERE ASSIGNMENT_STATUS_TYPE_ID = PAAM.ASSIGNMENT_STATUS_TYPE_ID
	         AND LANGUAGE = 'US'
		     AND ROWNUM = 1
		
	   	) ASSIGNMENT_STATUS_CODE
				,(SELECT PER_SYSTEM_STATUS
            FROM PER_ASSIGNMENT_STATUS_TYPES
	       WHERE ASSIGNMENT_STATUS_TYPE_ID = PAAM.ASSIGNMENT_STATUS_TYPE_ID
		   AND PER_SYSTEM_STATUS = 'ACTIVE'
		     AND ROWNUM = 1
	   	) asg_system_code
		,(SELECT DECODE(default_flag, 'N','No','Y','Yes')
            FROM PER_ASSIGNMENT_STATUS_TYPES
	       WHERE ASSIGNMENT_STATUS_TYPE_ID = PAAM.ASSIGNMENT_STATUS_TYPE_ID
		     AND ROWNUM = 1
	   	) asg_status_default_code
		
				,(Case PPOS.ORIGINAL_DATE_OF_HIRE
		WHEN PPOS.ADJUSTED_SVC_DATE THEN PPOS.DATE_START
		ELSE PPOS.ORIGINAL_DATE_OF_HIRE END) GROUP_HIRE_DATE


				 
       ,PPOS.date_start
       ,PPOS.legislation_code pp_legislation_code
       ,PPOS.original_date_of_hire
       ,PPOS.legal_entity_id PPOS_LEGAL_ENTITY_ID
       ,DECODE(PAAM.MANAGER_FLAG,'Y','Yes','N','No','No') pp_mgr_flag
	   ,ppos.ADJUSTED_SVC_DATE
       ,PAAM.*
	   ,ppos.worker_number
	   ,ppos.ACTUAL_TERMINATION_DATE
	   
	   
FROM AOL AL
    ,per_periods_of_service PPOS
    ,per_all_assignments_m  PAAM
WHERE PPOS.person_id = AL.main_person_id
AND   PAAM.WORK_TERMS_ASSIGNMENT_ID IS NOT NULL
AND   PAAM.period_of_service_id = PPOS.period_of_service_id
AND   :D1 BETWEEN PAAM.EFFECTIVE_START_DATE AND PAAM.EFFECTIVE_END_DATE
	 AND PAAM.PRIMARY_FLAG = 'Y'
AND PAAM.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'  
AND PAAM.PRIMARY_WORK_RELATION_FLAG = 'Y'
AND PAAM.SYSTEM_PERSON_TYPE IN ('EMP','CWK')


)



,

COL AS

(
SELECT DISTINCT  
       TO_CHAR(pp.date_of_birth , 'DD-MON-YYYY') pp_date_of_birth
	   
	   	       ,(SELECT NAME
           FROM   HR_ALL_ORGANIZATION_UNITS_TL
          WHERE  organization_id = PP.business_unit_id
            AND LANGUAGE = 'US'
		AND TRUNC(SYSDATE) BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         ) business_unit
		 
		 ,pp.notice_period
		 ,pp.ACTUAL_TERMINATION_DATE
		 ,pp.DATE_PROBATION_END
		 ,PP.ASS_ATTRIBUTE22 COST_TO_MALAYSIA
		 ,pp.ASS_ATTRIBUTE4 SOCSO_NO
		 ,pp.ASS_ATTRIBUTE_NUMBER1 EPF_NO
		 ,pp.ASS_ATTRIBUTE26 TAX_NUMBER
		 

		 

		
,(  
select  
dsdep0.name Department 

FROM per_dept_tree_node_cf cft,  
fnd_tree_vl treeName,  
fnd_tree_version_vl treeVersion,  
(select (SELECT MAX(effective_end_date) FROM hr_all_organization_units_f  WHERE organization_id = d.organization_id ) as MAX_EFFECTIVE_END_DATE,  
effective_end_date, effective_start_date, organization_id,name from per_departments d) dsdep0,  
(select (SELECT MAX(effective_end_date) FROM hr_all_organization_units_f  WHERE organization_id = d.organization_id ) as MAX_EFFECTIVE_END_DATE,  
effective_end_date, effective_start_date, organization_id,name from per_departments d) dsdep1  
WHERE cft.tree_structure_code = 'PER_DEPT_TREE_STRUCTURE'  
AND cft.tree_code = treeVersion.tree_code  
AND cft.tree_version_id = treeVersion.tree_version_id  
AND cft.tree_structure_code = treeVersion.tree_structure_code  
AND cft.tree_code = treeName.tree_code  
AND cft.tree_structure_code = treeName.tree_structure_code  
and dsdep0.organization_id  = cft.dep30_pk1_value  
and dsdep1.organization_id  = cft.dep29_pk1_value 
and pp.organization_id = dsdep1.organization_id 
 
and (  
  ( 1 =  CASE WHEN  (dsdep0.MAX_EFFECTIVE_END_DATE < = treeVersion.effective_end_date  
  and dsdep0.MAX_EFFECTIVE_END_DATE between treeVersion.effective_start_date  
  and treeVersion.effective_end_date and dsdep0.effective_end_date = dsdep0.MAX_EFFECTIVE_END_DATE  
  ) THEN 1 ELSE 0 End  
  )  
  OR  
  ( 1 = CASE WHEN  (dsdep0.MAX_EFFECTIVE_END_DATE > treeVersion.effective_end_date  
  and  treeVersion.EFFECTIVE_END_DATE between dsdep0.effective_start_date and dsdep0.effective_end_date )    THEN 1    ELSE 0 End )  
  )  
and ( ( 1 =  CASE WHEN  (dsdep1.MAX_EFFECTIVE_END_DATE < = treeVersion.effective_end_date and dsdep1.MAX_EFFECTIVE_END_DATE between treeVersion.effective_start_date and treeVersion.effective_end_date and dsdep1.effective_end_date = dsdep1.MAX_EFFECTIVE_END_DATE ) THEN 1 ELSE 0 End )
OR ( 1 = CASE WHEN  (dsdep1.MAX_EFFECTIVE_END_DATE > treeVersion.effective_end_date and  treeVersion.EFFECTIVE_END_DATE between dsdep1.effective_start_date and dsdep1.effective_end_date ) THEN 1    ELSE 0 End ) )  
AND ROWNUM = 1)  department_name

,(  
select  

 dsdep1.name node1  

FROM per_dept_tree_node_cf cft,  
fnd_tree_vl treeName,  
fnd_tree_version_vl treeVersion,  
(select (SELECT MAX(effective_end_date) FROM hr_all_organization_units_f  WHERE organization_id = d.organization_id ) as MAX_EFFECTIVE_END_DATE,  
effective_end_date, effective_start_date, organization_id,name from per_departments d) dsdep0,  
(select (SELECT MAX(effective_end_date) FROM hr_all_organization_units_f  WHERE organization_id = d.organization_id ) as MAX_EFFECTIVE_END_DATE,  
effective_end_date, effective_start_date, organization_id,name from per_departments d) dsdep1  
WHERE cft.tree_structure_code = 'PER_DEPT_TREE_STRUCTURE'  
AND cft.tree_code = treeVersion.tree_code  
AND cft.tree_version_id = treeVersion.tree_version_id  
AND cft.tree_structure_code = treeVersion.tree_structure_code  
AND cft.tree_code = treeName.tree_code  
AND cft.tree_structure_code = treeName.tree_structure_code  
and dsdep0.organization_id  = cft.dep30_pk1_value  
and dsdep1.organization_id  = cft.dep29_pk1_value 
and pp.organization_id = dsdep1.organization_id 
 
and (  
  ( 1 =  CASE WHEN  (dsdep0.MAX_EFFECTIVE_END_DATE < = treeVersion.effective_end_date  
  and dsdep0.MAX_EFFECTIVE_END_DATE between treeVersion.effective_start_date  
  and treeVersion.effective_end_date and dsdep0.effective_end_date = dsdep0.MAX_EFFECTIVE_END_DATE  
  ) THEN 1 ELSE 0 End  
  )  
  OR  
  ( 1 = CASE WHEN  (dsdep0.MAX_EFFECTIVE_END_DATE > treeVersion.effective_end_date  
  and  treeVersion.EFFECTIVE_END_DATE between dsdep0.effective_start_date and dsdep0.effective_end_date )    THEN 1    ELSE 0 End )  
  )  
and ( ( 1 =  CASE WHEN  (dsdep1.MAX_EFFECTIVE_END_DATE < = treeVersion.effective_end_date and dsdep1.MAX_EFFECTIVE_END_DATE between treeVersion.effective_start_date and treeVersion.effective_end_date and dsdep1.effective_end_date = dsdep1.MAX_EFFECTIVE_END_DATE ) THEN 1 ELSE 0 End )
OR ( 1 = CASE WHEN  (dsdep1.MAX_EFFECTIVE_END_DATE > treeVersion.effective_end_date and  treeVersion.EFFECTIVE_END_DATE between dsdep1.effective_start_date and dsdep1.effective_end_date ) THEN 1    ELSE 0 End ) )  
AND ROWNUM = 1)  sub_department
		
				,(SELECT meaning
         FROM fnd_lookup_values 
         WHERE lookup_type = 'PER_VISA_PERMIT_TYPE'
         and lookup_code = PP.visa_type
         and language = 'US'
		  AND ROWNUM = 1
        ) pp_visa_type
		 
		 	    ,(SELECT NAME
         FROM   PER_JOBS_F_TL
         WHERE  job_id = PP.job_id
         AND LANGUAGE = 'US'
		  AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
		   AND ROWNUM = 1
        ) Job_name
		,pp.worker_number
		
		,(SELECT USER_PERSON_TYPE
		FROM PER_PERSON_TYPES_TL
		WHERE LANGUAGE = 'US'
		AND PERSON_TYPE_ID = pp.PERSON_TYPE_ID
		AND ROWNUM = 1) person_type
				
				,(SELECT NAME
         FROM   PER_GRADES_F_TL 
         WHERE  grade_id = PP.grade_id
         AND LANGUAGE = 'US'
		  AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
		   AND ROWNUM = 1
        )grade_name
				,(SELECT LOCATION_NAME
             FROM   HR_LOCATIONS_ALL_F_VL
            WHERE  LOCATION_ID = PP.LOCATION_ID
              AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE   
			   AND ROWNUM = 1
            ) LOCATION_NAME
	   ,pp.ASSIGNMENT_STATUS_CODE asg_status_code
	   ,pp.asg_system_code
	   ,pp.asg_status_default_code
	   ,TO_CHAR(pp.GROUP_HIRE_DATE,'DD-MON-YYYY') GROUP_HIRE_DATE
	   ,pp.pp_legislation_code
                   , pp.BLOOD_TYPE
                   ,pp.pp_lang
				   ,pp.pp_primary_phone

				   ,pp.pp_COUNTRY_CODE_NUMBER
				   ,pp.pp_AREA_CODE

                   ,pp.pp_EMAIL_ADDRESS
                   ,pp.pp_TOWN_OF_BIRTH
                   ,pp.pp_REGION_OF_BIRTH
                   ,pp.pp_middle_names
                   ,pp.pp_title
                   ,pp.pp_first_name
				   ,pp.pp_last_name
                   ,pp.person_number
				   ,pp.ASSIGNMENT_NUMBER
 
                   ,TO_CHAR(LEAST(pp.DATE_START , NVL(pp.original_date_of_hire, pp.date_start)),'DD-MON-YYYY') ent_hire_date
                   ,(SELECT TERRITORY_SHORT_NAME
                     FROM FND_TERRITORIES_TL
                     WHERE pp.country_of_birth = TERRITORY_CODE
                     AND   LANGUAGE = 'US'
                     AND ROWNUM = 1
                     )  pp_country_of_birth
					 
        ,(SELECT NAME
         FROM HR_LEGAL_ENTITIES
         WHERE ORGANIZATION_ID = PP.LEGAL_ENTITY_ID
         AND CLASSIFICATION_CODE = 'HCM_LEMP'
         AND STATUS = 'A'
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
        ) legal_entity

        ,(SELECT TERRITORY_SHORT_NAME
         FROM FND_TERRITORIES_TL
         WHERE pp.pp_legislation_code = TERRITORY_CODE
         AND LANGUAGE = 'US'
         AND ROWNUM = 1
         )  le_country

         ,( select flv.Meaning
            FROM fnd_lookup_values flv , PER_PEOPLE_LEGISLATIVE_F ppl
            WHERE ppl.person_id = pp.person_id
            AND flv.lookup_code = ppl.SEX
            AND flv.lookup_type = 'SEX'
            AND flv.language = 'US'
            AND :D1 BETWEEN ppl.effective_start_date and ppl.effective_end_date
			AND ROWNUM = 1
            ) GENDER



            ,(SELECT paf.ADDRESS_LINE_1 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) ADDRESS_LINE_1
			  
			 ,(SELECT paf.ADDRESS_LINE_2
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) ADDRESS_LINE_2
			  
			              ,(SELECT paf.ADDRESS_LINE_3 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) ADDRESS_LINE_3
			  
			  ,(SELECT paf.BUILDING 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) BUILDING
			  
			  ,(SELECT paf.POSTAL_CODE 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) POSTAL_CODE
			  
			  ,(SELECT paf.COUNTRY 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) COUNTRY
			  

			  
			,(SELECT paf.TOWN_OR_CITY 
              FROM PER_ADDRESSES_F paf,
              PER_PERSON_ADDR_USAGES_F ppauf
              WHERE paf.address_id=ppauf.address_id
              AND pp.person_id=ppauf.person_id
              AND :D1 BETWEEN ppauf.EFFECTIVE_START_DATE AND ppauf.EFFECTIVE_END_DATE
              AND :D1 BETWEEN paf.EFFECTIVE_START_DATE AND paf.EFFECTIVE_END_DATE
              AND ppauf.address_type = 'HOME'
              AND ROWNUM = 1
              ) CITY



                                                
            ,( SELECT flv.Meaning
            FROM PER_ETHNICITIES pe , fnd_lookup_values flv
            WHERE pp.person_id = pe.person_id
            AND lookup_type = 'PER_ETHNICITY'
            AND flv.lookup_code = pe.ethnicity
            AND flv.language = 'US'
            and pe.primary_flag = 'Y'
            AND ROWNUM = 1
            ) PP_ETHNICITY

            ,(SELECT flv.meaning 
             FROM per_national_identifiers pni , fnd_lookup_values flv , per_all_people_f papf
             WHERE pni.person_id = pp.person_id
             AND papf.person_id = pp.person_id
             AND lookup_type = 'PER_NATIONAL_IDENTIFIER_TYPE'
             AND flv.lookup_code = pni.NATIONAL_IDENTIFIER_TYPE
             AND flv.language = 'US'
             and papf.PRIMARY_NID_ID = pni.NATIONAL_IDENTIFIER_ID
             AND :D1 between papf.effective_start_Date and papf.effective_end_date
             AND ROWNUM = 1
             ) ni_type

            ,( SELECT national_identifier_number
            FROM per_national_identifiers pni , per_all_people_f papf
            WHERE pni.person_id = pp.person_id
            AND papf.person_id = pp.person_id
            and papf.PRIMARY_NID_ID = pni.NATIONAL_IDENTIFIER_ID
            AND :D1 between papf.effective_start_Date and papf.effective_end_date
            AND ROWNUM = 1
            ) ni_number

            ,( SELECT meaning
             FROM PER_RELIGIONS pr , fnd_lookup_values flv
             WHERE pr.person_id = pp.person_id
             AND pr.legislation_code = pp.pp_legislation_code
             AND flv.lookup_code = pr.RELIGION
             AND flv.lookup_type = 'PER_RELIGION'
             AND flv.language = 'US'
             and pr.primary_flag = 'Y'
             AND ROWNUM = 1
             ) pp_religion

            ,(SELECT FLV.meaning
            FROM per_person_names_f pn, fnd_lookup_values flv
            WHERE pn.PERSON_ID = PP.PERSON_ID
            AND :D1 BETWEEN pn.EFFECTIVE_START_DATE AND pn.EFFECTIVE_END_DATE
            AND pn.name_type = pp.pp_legislation_code
            AND flv.lookup_type = 'TITLE'
            and flv.lookup_code = pn.title
            and flv.language = 'US'
            AND ROWNUM = 1
        ) pp_local_title
		
		    ,( SELECT flv.Meaning
            FROM fnd_lookup_values flv , PER_PEOPLE_LEGISLATIVE_F ppl
            WHERE ppl.person_id = pp.person_id
            AND flv.lookup_code = ppl.MARITAL_STATUS
            AND flv.lookup_type = 'MARITAL_STATUS'
            AND flv.language = 'US'
            AND SYSDATE BETWEEN ppl.effective_start_date and ppl.effective_end_date
			AND ROWNUM = 1
            ) MARITAL_STATUS

            ,(SELECT first_name
         FROM per_person_names_f
         WHERE PERSON_ID = PP.PERSON_ID
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         AND name_type = pp.pp_legislation_code
         AND ROWNUM = 1
        ) pp_local_first_name

       ,(SELECT last_name
         FROM per_person_names_f
         WHERE PERSON_ID = PP.PERSON_ID
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         AND name_type = pp.pp_legislation_code
         AND ROWNUM = 1
        ) pp_local_last_name

        ,(SELECT middle_names
         FROM per_person_names_f
         WHERE PERSON_ID = PP.PERSON_ID
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         AND name_type = pp.pp_legislation_code
         AND ROWNUM = 1
        ) pp_local_middle_names

        , pp.main_person_id person_id

        ,(SELECT TERRITORY_SHORT_NAME
          FROM PER_CITIZENSHIPS ppct, FND_TERRITORIES_TL
          WHERE ppct.person_id = pp.person_id
          and ppct.legislation_code = TERRITORY_CODE
          and ppct.CITIZENSHIP_STATUS = 'A'
          AND LANGUAGE = 'US'                         
		  AND ROWNUM = 1   
          )  pp_nationality

        ,( select flv.Meaning
         FROM fnd_lookup_values flv , PER_PEOPLE_LEGISLATIVE_F ppl
         WHERE ppl.person_id = pp.person_id
         AND flv.lookup_code = ppl.HIGHEST_EDUCATION_LEVEL
         AND flv.lookup_type = 'PER_HIGHEST_EDUCATION_LEVEL'
         AND :D1 BETWEEN ppl.effective_start_date and ppl.effective_end_date
         AND flv.language = 'US'
		 AND ROWNUM = 1
         ) pp_education
		 
		 				 		,((SELECT first_name
         FROM per_person_names_f
         WHERE PERSON_ID = pp.manager_id
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         AND name_type = 'GLOBAL'
        ) ||' '|| (SELECT last_name
         FROM per_person_names_f
         WHERE PERSON_ID = pp.MANAGER_ID
         AND :D1 BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
         AND name_type = 'GLOBAL'
        )) Line_Manager

FROM BOL pp

)

SELECT

					pp.worker_number "OLD_EMPLOYEE_ID"
                    ,pp.person_number "EMPLOYEE_ID"
                   ,pp.legal_entity "LEGAL_EMPLOYER_NAME"
                   ,pp.le_country "COUNTRY"
                   ,pp.ent_hire_date "EMPLOYEE_HIRE_DATE"
                   ,PP.person_type "PERSON_TYPE"
                   --,pp.pp_title "TITLE"
                   ,pp.pp_first_name "FIRST_NAME"
                   ,pp.pp_middle_names "MIDDLE_NAME"
                   ,pp.pp_last_name "LAST_NAME"
 
                   ,pp.pp_EMAIL_ADDRESS "Primary Email"
                   -- ,pp.ni_type "NATIONAL_IDENTIFIER_TYPE"
                   --,pp.ni_number "OLD_EMPLOYEE_ID"
                   ,pp.pp_date_of_birth "DATE_OF_BIRTH"

                   ,pp.GENDER "EMPLOYEE_GENDER"

                   ,pp.PP_ETHNICITY "EMPLOYEE_ETHNICITY"

				   ,pp.Line_Manager "MANAGER_NAME"
				   ,pp.business_unit "BUSINESS_UNIT_NAME"
				   ,pp.Job_name "JOB_NAME"
				   ,pp.grade_name "GRADE_NAME"
				   ,pp.LOCATION_NAME "LOCATION_NAME"
				   ,pp.ADDRESS_LINE_1 "ADDRESS_LINE1"
				   ,pp.ADDRESS_LINE_2 "ADDRESS_LINE2"
				   ,pp.ADDRESS_LINE_3 "ADDRESS_LINE3"
				   ,pp.BUILDING "BUILDING"
				   ,pp.POSTAL_CODE "POSTAL_CODE"
				   ,pp.COUNTRY "COUNTRY_ADD"
				   ,pp.CITY "CITY"
				   ,pp.pp_primary_phone "PRIMARY_PHONE"
				   ,pp.pp_COUNTRY_CODE_NUMBER "PRIMARY_PHONE_COUNTRY_CODE"
				   ,pp.pp_AREA_CODE "PRIMARY_PHONE_AREA_CODE"
				   ,pp.asg_status_code "ASSIGNMENT_STATUS"
			,pp.department_name "DEPARTMENT"
				   ,pp.pp_visa_type "VISA_TYPE"
				  ,pp.sub_department "SUB_DEPARTMENT"
				   ,pp.GROUP_HIRE_DATE "GROUP_HIRE_DATE"
				   ,PP.DATE_PROBATION_END "PROBATION_END_DATE"
				   ,pp.assignment_number "ASSIGNMENT_NUMBER"
				   ,pp.NOTICE_PERIOD "NOTICE_PERIOD"
				   ,pp.pp_legislation_code "LEGISLATION"
				   ,PP.ACTUAL_TERMINATION_DATE "TERMINATION_DATE"
				   		 ,PP.COST_TO_MALAYSIA "COST_TO_MALAYSIA"
		 ,pp.SOCSO_NO "EMPLOYEE_SOCSO_NO"
		 ,pp.EPF_NO "EMPLOYEE_EPF_NO"
		 ,pp.TAX_NUMBER "EMPLOYEE_TAX_NUMBER"
		 ,pp.MARITAL_STATUS "MARITAL_STATUS"
		 





FROM COL pp
WHERE pp.pp_legislation_code = 'SG'
AND pp.asg_status_code = 'Active - Payroll Eligible'
AND pp.legal_entity <> 'GLOBAL FASHION GROUP SGP SERVICES PTE. LTD'



ORDER BY pp.person_number