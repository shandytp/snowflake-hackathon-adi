-- create dynamic table to join the two tables
-- for easier join we're using file hash
-- also we're using window function to make sure there's no duplicate file

CREATE OR REPLACE DYNAMIC TABLE dev_final_joined
TARGET_LAG = '1 MINUTE'  
WAREHOUSE = COMPUTE_WH   
AS
SELECT 
    t.id,
    t.company_name,
    t.business_name,
    t.business_type,
    t.industry,
    t.incorporation_date,
    t.business_address,
    t.phone_number,
    t.num_employees,
    t.key_customers,
    t.main_products,
    t.loan_amount_numeric,
    t.loan_purpose,
    t.file_hash,
    o.file_name,
    o.extracted_layout,
    o.processed_at
FROM dev_transformed_snowflake t
JOIN (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY REGEXP_SUBSTR(file_name, '[0-9a-f]{8}') 
               ORDER BY processed_at DESC
           ) AS rn
    FROM dev_ocr_parsed
) o
    ON SUBSTR(t.file_hash, 1, 8) = REGEXP_SUBSTR(o.file_name, '[0-9a-f]{8}')
WHERE o.rn = 1;