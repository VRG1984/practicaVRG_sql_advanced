CREATE OR REPLACE TABLE keepcoding.ivr_sumary AS
WITH detail
  AS (SELECT detail.* FROM keepcoding.ivr_detail detail)
   , rellamadas
  AS (SELECT detail.calls_ivr_id
           , MAX(IF (DATETIME_DIFF(detail.calls_start_date, detail_bis.calls_start_date, MINUTE) < 1440 AND DATETIME_DIFF(detail.calls_start_date, detail_bis.calls_start_date, MINUTE) >= 0, 1, 0)) AS repeated_phone_24H 
           , MAX(IF (DATETIME_DIFF(detail.calls_start_date, detail_bis.calls_start_date, MINUTE) > -1440 AND DATETIME_DIFF(detail.calls_start_date, detail_bis.calls_start_date, MINUTE) <= 0 , 1, 0)) AS cause_recall_phone_24H
           
           FROM keepcoding.ivr_detail detail LEFT JOIN keepcoding.ivr_detail detail_bis ON detail.calls_phone_number = detail_bis.calls_phone_number AND detail.calls_ivr_id <> detail_bis.calls_ivr_id GROUP BY detail.calls_ivr_id)

SELECT detail.calls_ivr_id AS ivr_id
     , detail.calls_phone_number AS phone_number
     , detail.calls_ivr_result AS ivr_result
     , CASE WHEN STARTS_WITH(detail.calls_vdn_label, 'ATC') THEN 'FRONT'
            WHEN STARTS_WITH(detail.calls_vdn_label, 'TECH') THEN 'TECH'
            WHEN STARTS_WITH(detail.calls_vdn_label, 'ABSORPTION') THEN 'ABSORPTION'
            ELSE 'RESTO'
            END AS vdn_aggregation
     , detail.calls_start_date AS start_date
     , detail.calls_end_date AS end_date
     , detail.calls_total_duration AS total_duration
     , detail.calls_customer_segment AS customer_segment
     , detail.calls_ivr_language AS ivr_language
     , detail.calls_steps_module AS steps_module
     , detail.calls_module_aggregation AS module_aggregation
     , MIN(IF(detail.document_type = 'NULL', 'zzzzzNULLzzzzz', detail.document_type)) AS document_type
     , MIN(IF(detail.document_identification = 'NULL', 'zzzzzNULLzzzzz', detail.document_identification)) AS document_identification
     , MIN(IF(detail.customer_phone = 'NULL', 'zzzzzNULLzzzzz', detail.customer_phone)) AS customer_phone
     , MIN(detail.billing_account_id) AS billing_account_id
     , MAX(IF(detail.module_name = 'AVERIA_MASIVA', 1, 0)) AS masiva_lg
     , MAX(IF(detail.step_name = 'CUSTOMERINFOBYPHONE.TX' AND step_description_error = 'NULL', 1, 0)) AS info_by_phone_lg
     , MAX(IF(detail.step_name = 'CUSTOMERINFOBYDNI.TX' AND step_description_error = 'NULL', 1, 0)) AS info_by_dni_lg
     , rellamadas.repeated_phone_24H AS repeated_phone_24H
     , rellamadas.cause_recall_phone_24H AS cause_recall_phone_24H
     

FROM detail 
LEFT JOIN rellamadas ON detail.calls_ivr_id = rellamadas.calls_ivr_id 
GROUP BY ivr_id, phone_number, ivr_result, vdn_aggregation, start_date, end_date, total_duration, customer_segment, ivr_language, steps_module, module_aggregation, repeated_phone_24H, cause_recall_phone_24H