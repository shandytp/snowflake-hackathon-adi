CREATE OR REPLACE DYNAMIC TABLE dev_transformed_snowflake
TARGET_LAG = 'DOWNSTREAM'
WAREHOUSE = compute_wh
AS
select
    cast(id as string) as id,
    company_name,
    business_name,
    business_type,
    industry,
    incorporation_date,
    business_address,
    contact_info as phone_number,
    num_employees,
    key_customers,
    main_products,
    TO_NUMBER(
        REPLACE(
            REPLACE(LOAN_AMOUNT, 'Rp ', ''), 
            '.', ''
        )
    ) AS LOAN_AMOUNT_NUMERIC,
    loan_purpose,
    raw_payload,
    file_hash,
    created_at
from streamlit_apps.public.borrower_profiles;