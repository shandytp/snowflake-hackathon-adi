-- If you want to create a new database for Streamlit Apps, run
CREATE DATABASE STREAMLIT_APPS;

-- If you want to create a specific schema under the database, run
CREATE SCHEMA STREAMLIT_APPS.PUBLIC;

-- If you want all roles to create Streamlit apps in the PUBLIC schema, run
GRANT USAGE ON DATABASE STREAMLIT_APPS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA STREAMLIT_APPS.PUBLIC TO ROLE PUBLIC;
GRANT CREATE STREAMLIT ON SCHEMA STREAMLIT_APPS.PUBLIC TO ROLE PUBLIC;
GRANT CREATE STAGE ON SCHEMA STREAMLIT_APPS.PUBLIC TO ROLE PUBLIC;

-- Don't forget to grant USAGE on a warehouse.
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PUBLIC;

-- create stages
CREATE OR REPLACE STAGE borrower_docs_stage
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

-- 2️⃣ Create table for borrower metadata
CREATE TABLE streamlit_apps.public.borrower_profiles (
    id INT AUTOINCREMENT,
    company_name STRING,
    business_name STRING,
    business_type STRING,
    industry STRING,
    incorporation_date DATE,
    business_address STRING,
    contact_info STRING,
    num_employees INT,
    key_customers STRING,
    main_products STRING,
    loan_amount STRING,
    loan_purpose STRING,
    raw_payload VARIANT,
    financial_statement_path STRING,
    file_hash STRING,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- turn on cortex
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';