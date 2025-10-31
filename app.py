import streamlit as st
import hashlib
import json
import os
import tempfile
import time
from snowflake.snowpark.context import get_active_session

# --------------------------------------------------------
# Get active Snowflake session
# --------------------------------------------------------
session = get_active_session()

# --------------------------------------------------------
# Navigation setup
# --------------------------------------------------------
if "page" not in st.session_state:
    st.session_state.page = "form"


def go_to_factsheet(company_name):
    st.session_state.page = "factsheet"
    st.session_state.company_name = company_name


# --------------------------------------------------------
# PAGE 1: Loan Form
# --------------------------------------------------------
if st.session_state.page == "form":
    st.title("🏦 Loan Credit Application")

    with st.form("loan_form"):
        company_name = st.text_input("Company Name")
        business_type = st.selectbox("Business Type", ["CV", "PT"])
        industry = st.text_input("Industry / Sector")
        incorporation_date = st.date_input("Incorporation Date")
        business_address = st.text_area("Business Address")
        contact_info = st.text_input("Contact Info (Phone / Email)")
        num_employees = st.number_input("Number of Employees", min_value=1)
        key_customers = st.text_area("Key Customers and Suppliers")
        main_products = st.text_area("Main Products")
        loan_amount = st.text_input("Loan Amount (Rp)", placeholder="e.g. Rp 150.000.000")
        loan_purpose = st.text_area("Loan Purpose")
        financial_statement = st.file_uploader("Upload Financial Statement (PDF)", type=["pdf"])

        submitted = st.form_submit_button("Submit")

    if submitted:
        if not financial_statement:
            st.warning("Please upload your financial statement (PDF).")
        else:
            # ✅ Read file bytes
            file_bytes = financial_statement.read()

            # ✅ Generate SHA256 hash
            file_hash = hashlib.sha256(file_bytes).hexdigest()

            # ✅ Clean filename
            safe_company_name = company_name.replace(" ", "_")
            pdf_filename = f"{safe_company_name}_{file_hash[:8]}.pdf"

            # ✅ Save to temp path
            tmp_dir = tempfile.gettempdir()
            tmp_path = os.path.join(tmp_dir, pdf_filename)

            with open(tmp_path, "wb") as f:
                f.write(file_bytes)

            # ✅ Upload to stage
            st.info("📤 Uploading PDF to Snowflake stage...")
            session.file.put(tmp_path, "@borrower_docs_stage", auto_compress=False, overwrite=True)

            # ✅ Insert borrower record
            st.info("🗄️ Saving borrower data to Snowflake...")

            borrower_data = {
                "company_name": company_name,
                "business_type": business_type,
                "industry": industry,
                "incorporation_date": str(incorporation_date),
                "business_address": business_address,
                "contact_info": contact_info,
                "num_employees": num_employees,
                "key_customers": key_customers,
                "main_products": main_products,
                "loan_amount": loan_amount,
                "loan_purpose": loan_purpose
            }
            borrower_data_json = json.dumps(borrower_data)

            insert_query = f"""
                INSERT INTO borrower_profiles (
                    company_name, business_type, industry,
                    incorporation_date, business_address, contact_info, num_employees,
                    key_customers, main_products, loan_amount, loan_purpose, raw_payload,
                    financial_statement_path, file_hash
                )
                SELECT
                    '{company_name}', '{business_type}', '{industry}',
                    '{incorporation_date}', '{business_address}', '{contact_info}', {num_employees},
                    '{key_customers}', '{main_products}', '{loan_amount}', '{loan_purpose}',
                    PARSE_JSON('{borrower_data_json}'),
                    '@borrower_docs_stage/{pdf_filename}', '{file_hash}';
            """
            session.sql(insert_query).collect()

            st.success(f"✅ Borrower data uploaded: {pdf_filename}")

            # ✅ Simulate processing: OCR + AI Scoring
            with st.spinner("🧠 Processing financial statement and generating credit analysis..."):
                # You can replace this with an actual call to your Snowflake tasks or Cortex model
                for _ in range(10):
                    time.sleep(1)  # simulate async processing delay

            # ✅ Redirect to factsheet page
            go_to_factsheet(company_name)

# --------------------------------------------------------
# PAGE 2: Factsheet
# --------------------------------------------------------
elif st.session_state.page == "factsheet":
    st.title("🏦 Factsheet Results")

    company_name = st.session_state.company_name

    st.info(f"Showing results for: **{company_name}**")

    # ✅ Fetch latest record from Snowflake (replace with your final joined table)
    query = f"""
        SELECT
            company_name,
            key_customers,
            main_products,
            loan_request,
            loan_purpose,
            summary,
            result,
            score,
            classify_borrower
        FROM final_factsheet
        WHERE company_name = '{company_name}'
        LIMIT 1
    """
    df = session.sql(query).to_pandas()

    if df.empty:
        st.warning("⏳ Results are not ready yet. Please refresh in a moment.")
    else:
        record = df.iloc[0]

        st.divider()
        st.header("🏢 Company Information")
        st.subheader("Company Name")
        st.write(record["COMPANY_NAME"])
        st.subheader("Key Customers")
        st.write(record["KEY_CUSTOMERS"])
        st.subheader("Main Products")
        st.write(record["MAIN_PRODUCTS"])
        st.subheader("Loan Request")
        st.write(f"Rp {record['LOAN_REQUEST']:,}")
        st.subheader("Loan Purpose")
        st.write(record["LOAN_PURPOSE"])

        st.divider()
        st.header("📊 Analysis Results")
        st.subheader("Summary")
        st.markdown(record["SUMMARY"].replace("\\n", "\n"))
        st.subheader("Result")
        st.markdown(record["RESULT"].replace("\\n", "\n"))
        st.subheader("Score")
        st.write(record["SCORE"])
        st.subheader("Borrower Classification")
        st.write(record["CLASSIFY_BORROWER"])

        if st.button("⬅️ Back to Form"):
            st.session_state.page = "form"
