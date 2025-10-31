-- create temporary result
CREATE OR REPLACE TABLE dev_ocr_results (
    file_name STRING,
    file_url STRING,
    reference_hash STRING,
    extracted_layout STRING,
    processed_at STRING,
    file_size NUMBER,
    last_modified STRING,
    content_length NUMBER,
    processing_status STRING
);

-- create SP to run a python code to iterate each files and do OCR
CREATE OR REPLACE PROCEDURE process_ocr_files_proc()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
from snowflake.snowpark import Session
import re

def run(session: Session):
    inserted = 0

    # 1. List all files in stage
    files = session.sql("LIST @borrower_docs_stage").collect()

    for f in files:
        full_path = f["name"]  # e.g. borrower_docs_stage/PT_Kacamata_Dua_701e46e5.pdf
        file_size = f["size"]
        last_modified = f["last_modified"]

        # 2. Extract only the relative path (remove stage prefix)
        match = re.match(r'^[^/]+/(.+)$', full_path)
        if match:
            relative_path = match.group(1)
        else:
            relative_path = full_path

        file_name = relative_path

        # 3. Skip if already processed
        exists = session.sql(f"""
            SELECT COUNT(*) AS c FROM dev_ocr_results WHERE file_name = '{file_name}'
        """).collect()[0]["C"]
        if exists > 0:
            continue

        # 4. Run OCR with Snowflake Cortex
        try:
            result_df = session.sql(f"""
                SELECT TO_VARCHAR(
                    AI_PARSE_DOCUMENT(
                        TO_FILE('@borrower_docs_stage', '{file_name}'),
                        OBJECT_CONSTRUCT('mode', 'layout')
                    ):content
                ) AS extracted_layout
            """)
            result = result_df.collect()

            if not result or result[0]["EXTRACTED_LAYOUT"] is None:
                extracted_layout = ""
                status = "FAILED"
            else:
                extracted_layout = result[0]["EXTRACTED_LAYOUT"]
                status = "PROCESSED"

        except Exception as e:
            extracted_layout = f"Error: {str(e)}"
            status = "FAILED"

        # Escape single quotes in layout text for SQL insert
        extracted_layout_escaped = extracted_layout.replace("'", "''")

        # 5. Insert result into dev_ocr_results
        insert_sql = f"""
            INSERT INTO dev_ocr_results
            (file_name, file_url, reference_hash, extracted_layout, processed_at, 
             file_size, last_modified, content_length, processing_status)
            SELECT
                '{file_name}' AS file_name,
                BUILD_SCOPED_FILE_URL(@borrower_docs_stage, '{file_name}') AS file_url,
                SHA2('{file_name}' || CAST({file_size} AS STRING) || CAST('{last_modified}' AS STRING), 256) AS reference_hash,
                '{extracted_layout_escaped}' AS extracted_layout,
                CURRENT_TIMESTAMP() AS processed_at,
                {file_size} AS file_size,
                '{last_modified}' AS last_modified,
                LENGTH('{extracted_layout_escaped}') AS content_length,
                '{status}' AS processing_status;
        """
        session.sql(insert_sql).collect()
        inserted += 1

    return f"Processed {inserted} new file(s)."
$$;

-- create a task to run the SP
CREATE OR REPLACE TASK auto_process_ocr_files
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON * * * * * UTC'  -- runs every minute
AS
CALL process_ocr_files_proc();

-- store the parsed ocr using dynamic table
CREATE OR REPLACE DYNAMIC TABLE dev_ocr_parsed
  TARGET_LAG = '1 MINUTE'
  WAREHOUSE = COMPUTE_WH
AS
SELECT 
    file_name,
    file_url,
    reference_hash,
    extracted_layout,
    processed_at,
    file_size,
    last_modified,
    content_length,
    processing_status
FROM dev_ocr_results
WHERE processing_status = 'PROCESSED';