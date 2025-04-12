-- 提取符合条件的患者
WITH eligible_stays AS (
    -- 选择首次入ICU的患者，并且ICU住院时间≥1天
    SELECT 
        id.subject_id,
        id.hadm_id,
        id.stay_id,
        id.admittime,
        id.dischtime,
        id.icu_intime,
        id.icu_outtime
    FROM 
        mimiciv_derived.icustay_detail id
    WHERE 
        id.first_icu_stay = TRUE
        AND id.los_icu >= 1
),

digoxin_med_criteria AS (
    -- 筛选条件1: 入ICU后使用地高辛的情况
    SELECT DISTINCT
        es.subject_id,
        es.hadm_id,
        es.stay_id
    FROM 
        eligible_stays es
    JOIN 
        mimiciv_hosp.digoxin_patients dp ON es.subject_id = dp.subject_id AND es.hadm_id = dp.hadm_id
    WHERE 
        -- 地高辛用药开始时间在入ICU之后
        (dp.starttime >= es.icu_intime) 
        OR 
        -- 地高辛用药时间段包含了ICU入住时间
        (dp.starttime <= es.icu_intime AND dp.stoptime >= es.icu_intime)
        AND
        -- 确保用药时间在当次住院期间内
        (dp.starttime <= es.dischtime)
),

digoxin_conc_criteria AS (
    -- 筛选条件2: 入ICU后有地高辛浓度检测的情况
    SELECT DISTINCT
        es.subject_id,
        es.hadm_id,
        es.stay_id
    FROM 
        eligible_stays es
    JOIN 
        mimiciv_hosp.digoxin_concentrate dc ON es.subject_id = dc.subject_id
    WHERE 
        -- 地高辛浓度采血时间在入ICU之后
        dc.charttime >= es.icu_intime
        AND
        -- 确保采血时间在当次住院期间内
        dc.charttime <= es.dischtime
        AND
        -- 处理digoxin_concentrate表中hadm_id可能缺失的情况
        (dc.hadm_id IS NULL OR dc.hadm_id = es.hadm_id)
),

-- 新增：检查是否有地高辛中毒记录
overdose_check AS (
    SELECT 
        es.subject_id,
        es.hadm_id,
        es.stay_id,
        CASE WHEN MAX(dc.overdose) = 1 THEN 1 ELSE 0 END AS dig_overdose
    FROM 
        eligible_stays es
    JOIN 
        mimiciv_hosp.digoxin_concentrate dc ON es.subject_id = dc.subject_id
    WHERE 
        -- 地高辛浓度采血时间在入ICU之后
        dc.charttime >= es.icu_intime
        AND
        -- 确保采血时间在当次住院期间内
        dc.charttime <= es.dischtime
        AND
        -- 处理digoxin_concentrate表中hadm_id可能缺失的情况
        (dc.hadm_id IS NULL OR dc.hadm_id = es.hadm_id)
    GROUP BY 
        es.subject_id, es.hadm_id, es.stay_id
),

-- 新增：检查给药途径
route_check AS (
    SELECT 
        es.subject_id,
        es.hadm_id,
        es.stay_id,
        CASE 
            -- 如果同时有静脉给药和口服给药，则为3
            WHEN SUM(CASE WHEN dp.route IN ('IJ', 'IV') THEN 1 ELSE 0 END) > 0 
                 AND SUM(CASE WHEN dp.route NOT IN ('IJ', 'IV') THEN 1 ELSE 0 END) > 0 THEN 3
            -- 如果只有静脉给药，则为1
            WHEN SUM(CASE WHEN dp.route IN ('IJ', 'IV') THEN 1 ELSE 0 END) > 0 THEN 1
            -- 如果只有口服给药，则为2
            WHEN SUM(CASE WHEN dp.route NOT IN ('IJ', 'IV') THEN 1 ELSE 0 END) > 0 THEN 2
            -- 默认情况（不应该出现）
            ELSE NULL
        END AS route_type
    FROM 
        eligible_stays es
    JOIN 
        mimiciv_hosp.digoxin_patients dp ON es.subject_id = dp.subject_id AND es.hadm_id = dp.hadm_id
    WHERE 
        -- 确保用药时间在ICU入住后到出院前
        ((dp.starttime >= es.icu_intime) OR (dp.starttime <= es.icu_intime AND dp.stoptime >= es.icu_intime))
        AND dp.starttime <= es.dischtime
    GROUP BY 
        es.subject_id, es.hadm_id, es.stay_id
)

-- 最终结果：同时满足条件的患者，并增加地高辛中毒标记和给药途径标记
SELECT DISTINCT
    es.subject_id,
    es.hadm_id,
    es.stay_id,
    es.admittime,
    es.dischtime,
    es.icu_intime,
    es.icu_outtime,
    COALESCE(oc.dig_overdose, 0) AS dig_overdose,
    COALESCE(rc.route_type, 0) AS route_type
FROM 
    eligible_stays es
JOIN 
    digoxin_med_criteria dmc ON es.stay_id = dmc.stay_id
JOIN 
    digoxin_conc_criteria dcc ON es.stay_id = dcc.stay_id
LEFT JOIN 
    overdose_check oc ON es.stay_id = oc.stay_id
LEFT JOIN 
    route_check rc ON es.stay_id = rc.stay_id
ORDER BY 
    es.subject_id, es.hadm_id;