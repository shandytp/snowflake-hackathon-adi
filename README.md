# Snowflake Hackathon: AI-Powered Credit Scoring System

## 🎯 Project Overview

This project demonstrates an end-to-end AI-powered credit scoring system built for the Snowflake Hackathon. The solution leverages Snowflake's advanced features including Dynamic Tables, OCR capabilities, Cortex AI, and Snowflake Intelligence to automate credit risk assessment for loan applications.

## 🏗️ Architecture

The system processes PDF loan applications through a sophisticated pipeline that extracts, transforms, and analyzes financial data to generate credit scores and risk classifications.

### Key Components:
- **PDF Processing**: OCR extraction of financial documents
- **Data Pipeline**: Multi-stage transformation using Dynamic Tables
- **AI Analysis**: Cortex LLM for credit scoring and reasoning
- **Intelligence Layer**: Snowflake Intelligence for validation
- **User Interface**: Streamlit app for results visualization

## 🔄 Data Pipeline

### Stage 1: Identity Transformation (`1_pipeline_transform_identity.sql`)
- Creates `dev_transformed_snowflake` Dynamic Table
- Transforms raw company data into standardized format
- Handles data type casting and normalization

### Stage 2: OCR Processing (`2_pipeline_extract_ocr_transform.sql`)
- Extracts text content from PDF documents using Snowflake OCR
- Creates `dev_ocr_results` table with extracted layout data
- Processes file metadata and content structure

### Stage 3: Data Integration (`3_pipeline_join_final_data.sql`)
- Joins transformed identity data with OCR results
- Creates unified dataset for analysis
- Prepares data for LLM processing

### Stage 4: AI-Powered Analysis (`4_pipeline_modeling_llm.sql`)
- Utilizes **Snowflake Cortex** for LLM-based credit analysis
- Generates credit scores using AI reasoning
- Creates `final_factsheet` Dynamic Table with:
  - Company information extraction
  - Financial metrics analysis
  - Risk assessment and classification
  - Loan recommendations

## 🤖 AI & Intelligence Features

### Snowflake Cortex Integration
- **LLM Prompting**: Advanced prompts for financial analysis
- **Credit Scoring**: Automated scoring based on financial health
- **Risk Classification**: Categorizes borrowers (Good/Bad/High Risk)
- **Reasoning Engine**: Provides detailed explanations for decisions

### Snowflake Intelligence
- **Validation Layer**: Ensures accuracy of AI-generated scores
- **Credit Analyst Support**: Provides reasoning for manual review
- **Quality Assurance**: Validates model outputs against business rules

## 📊 Dynamic Tables

The pipeline uses Snowflake Dynamic Tables for real-time data processing:

```sql
CREATE OR REPLACE DYNAMIC TABLE final_factsheet
TARGET_LAG = '1 MINUTE'  
WAREHOUSE = COMPUTE_WH   
AS SELECT ...
```

Benefits:
- **Real-time Updates**: Automatic refresh as new data arrives
- **Cost Optimization**: Incremental processing reduces compute costs
- **Scalability**: Handles large volumes of loan applications

## 🖥️ Streamlit Applications

### Main Application (`app.py`)
- **File Upload**: PDF loan application submission
- **Data Processing**: Triggers Snowflake pipeline
- **Credit Score Display**: Visual representation of scores
- **Risk Analysis**: Detailed breakdown of assessment factors
- **Loan Recommendations**: AI-generated lending suggestions

## 🏆 Hackathon Innovation

This project showcases cutting-edge Snowflake capabilities:
- **Dynamic Tables** for real-time data processing
- **Cortex AI** for intelligent document analysis
- **Snowflake Intelligence** for decision validation
- **Integrated OCR** for document processing
- **Streamlit** for interactive user experience

---

*Built for Snowflake Hackathon - Demonstrating the future of AI-powered financial services*
