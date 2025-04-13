with cohort AS
(SELECT subject_id, hadm_id, stay_id,dig_overdose,route_type 
FROM mimiciv_derived.digoxin_cohort )--入ICU后使用了地高辛的病人，ICU时长＞1天，首次入ICU
SELECT c.subject_id,c.hadm_id,c.stay_id,i.gender,i.los_hospital,i.admission_age,i.race,i.hospital_expire_flag,i.los_icu,
       EXTRACT(DAY FROM (i.dod - i.admittime)) AS surtime_from_admit,    --入院起的生存时间
       EXTRACT(DAY FROM (i.dod - i.icu_intime)) AS surtime_from_icu,     --入ICU起的生存时间
			 c.dig_overdose,c.route_type, b.lactate_max as lactate, b.ph_min as ph, b.po2_min as po2,b.pco2_max as pco2,b.pao2fio2ratio_min as pao2fio2ratio, 
       gc.gcs_min as gcs, fh.height, fw.weight,(fl.hematocrit_min+fl.hematocrit_max)/2 as hematocrit, 
       (fl.hemoglobin_min+fl.hemoglobin_max)/2 as hemoglobin,(fl.platelets_min+fl.platelets_max)/2 as platelets,
       (fl.wbc_min+fl.wbc_max)/2 as wbc, (fl.albumin_min+fl.albumin_max)/2 as albumin,
       (fl.aniongap_min+fl.aniongap_max)/2 as aniongap, (fl.bicarbonate_min+fl.bicarbonate_max)/2 as bicarbonate,
       (fl.bun_min+fl.bun_max)/2 as bun, (fl.calcium_min+fl.calcium_max)/2 as calcium, (fl.chloride_min+fl.chloride_max)/2 as chloride,
			 (fl.creatinine_min+fl.creatinine_max)/2 as creatinine, (fl.sodium_min+fl.sodium_max)/2 as sodium,
       (fl.potassium_min+fl.potassium_max)/2 as potassium,(fl.abs_lymphocytes_min+fl.abs_lymphocytes_max)/2 as abs_lymphocytes,
       (fl.pt_min+fl.pt_max)/2 as pt,(fl.ptt_min+fl.ptt_max)/2 as ptt,(fl.alt_min+fl.alt_max)/2 as alt,(fl.ast_min+fl.ast_max)/2 as ast,
			 (fl.bilirubin_total_min+fl.bilirubin_total_max)/2 as bilirubin_total,(fl.ck_cpk_min+fl.ck_cpk_max)/2 as ck_cpk,
			 fr.dialysis_active, fa.has_antibiotic as f24_antibiotic, fs.sofa, fo.urineoutput, fv.heart_rate_mean as hr, fv.mbp_mean as mbp, fv.resp_rate_mean as resp, 
       fv.temperature_mean as temperature, fv.spo2_mean as spO2,fv.glucose_mean as glucose, dr.heart_rhythm as heart_rhythm,oa.oasis, ap.apsiii,
			 CASE WHEN ve.ventilation = 1 THEN 1 ELSE 0 END  as ventilation, --第一天是否启动机械通气
			 CASE WHEN va.vasoactive = 1 THEN 1 ELSE 0 END  as vasoactive,     --第一天是否启动血管活性药物
			 CASE WHEN ch.myocardial_infarct > 0 THEN 1 ELSE 0 END  as myocardial_infarct, --以下均为既往史
			 CASE WHEN ch.congestive_heart_failure > 0 THEN 1 ELSE 0 END  as congestive_heart_failure,
			 CASE WHEN ch.peripheral_vascular_disease > 0 THEN 1 ELSE 0 END  as peripheral_vascular_disease,
			 CASE WHEN ch.cerebrovascular_disease > 0 THEN 1 ELSE 0 END  as cerebrovascular_disease,
			 CASE WHEN ch.dementia > 0 THEN 1 ELSE 0 END  as dementia,
       CASE WHEN ch.chronic_pulmonary_disease > 0 THEN 1 ELSE 0 END  as chronic_pulmonary_disease,
			 CASE WHEN ch.rheumatic_disease > 0 THEN 1 ELSE 0 END  as rheumatic_disease,
			 CASE WHEN ch.peptic_ulcer_disease > 0 THEN 1 ELSE 0 END  as peptic_ulcer_disease,
			 CASE WHEN ch.mild_liver_disease > 0 THEN 1 ELSE 0 END  as mild_liver_disease,
			 CASE WHEN ch.diabetes_with_cc > 0 THEN 1 ELSE 0 END  as diabetes_with_cc,
			 CASE WHEN ch.diabetes_without_cc > 0 THEN 1 ELSE 0 END  as diabetes_without_cc,
			 CASE WHEN ch.paraplegia > 0 THEN 1 ELSE 0 END  as paraplegia,
			 CASE WHEN ch.renal_disease > 0 THEN 1 ELSE 0 END  as renal_disease,
			 CASE WHEN ch.malignant_cancer > 0 THEN 1 ELSE 0 END  as malignant_cancer,
			 CASE WHEN ch.severe_liver_disease > 0 THEN 1 ELSE 0 END  as severe_liver_disease,
			 CASE WHEN ch.metastatic_solid_tumor > 0 THEN 1 ELSE 0 END  as metastatic_solid_tumor,
			 CASE WHEN ch.aids > 0 THEN 1 ELSE 0 END  as aids, 
       ch.charlson_comorbidity_index as charlson
FROM cohort c 
LEFT JOIN mimiciv_derived.icustay_detail i 
ON c.stay_id = i.stay_id
LEFT JOIN mimiciv_derived.digoxin_rhythm dr
ON c.stay_id = dr.stay_id
LEFT JOIN first_day_bg_art b
ON c.stay_id = b.stay_id
LEFT JOIN first_day_gcs gc
ON c.stay_id = gc.stay_id
LEFT JOIN first_day_height fh
ON c.stay_id = fh.stay_id
LEFT JOIN first_day_weight fw
ON c.stay_id = fw.stay_id
LEFT JOIN first_day_lab fl
ON c.stay_id = fl.stay_id
LEFT JOIN first_day_rrt fr
ON c.stay_id = fr.stay_id
LEFT JOIN first_day_sofa fs
ON c.stay_id = fs.stay_id
LEFT JOIN first_day_urine_output fo
ON c.stay_id = fo.stay_id
LEFT JOIN first_day_vitalsign fv
ON c.stay_id = fv.stay_id
LEFT JOIN apsiii ap
ON c.stay_id = ap.stay_id
LEFT JOIN first_day_vasoactive va
ON c.stay_id = va.stay_id
LEFT JOIN first_day_ventilation ve
ON c.stay_id = ve.stay_id
LEFT JOIN oasis oa
ON c.stay_id = oa.stay_id
LEFT JOIN first_day_antibiotic fa
ON c.stay_id = fa.stay_id
LEFT JOIN charlson ch
ON c.hadm_id = ch.hadm_id


