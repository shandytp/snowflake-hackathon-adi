CREATE OR REPLACE DYNAMIC TABLE final_factsheet
TARGET_LAG = '1 MINUTE'  
WAREHOUSE = COMPUTE_WH   
AS
SELECT 
    id,
    file_name,
    company_name,
    key_customers,
    main_products,
    loan_amount_numeric as loan_request,
    loan_purpose,
    AI_COMPLETE(
        'claude-4-sonnet',  -- or another available model
        CONCAT('Create a brief summary of this document, and, from your understanding, conclude whether the company is eligible for the loan they requested:\n', extracted_layout)
    ) AS summary,
    AI_COMPLETE(
        'claude-4-sonnet',
        CONCAT('Analyse company financial statements across 6 areas (profitability, liquidity, solvency, cash flow, growth, efficiency) using weighted scoring. The weighted scoring algorithm evaluates companies using six financial areas with specific weights, as explained here: Profitability (25%) scored by net profit margin (≥15%=30pts, 10-15%=25pts, 5-10%=20pts, 2-5%=15pts, 0-2%=10pts) and ROA (≥15%=20pts, 10-15%=16pts, 5-10%=12pts, 2-5%=8pts, 0-2%=4pts); Liquidity (20%) using current ratio (≥2.0=40pts, 1.5-2.0=32pts, 1.2-1.5=24pts, 1.0-1.2=16pts, 0.8-1.0=8pts); Solvency (20%) via debt-to-equity (≤0.5=40pts, 0.5-1.0=32pts, 1.0-1.5=24pts, 1.5-2.0=16pts, 2.0-3.0=8pts) and debt-to-assets (≤30%=20pts, 30-50%=16pts, 50-60%=12pts, 60-70%=8pts, 70-80%=4pts); Cash Flow (15%) with operating cash flow ratio (≥0.5=30pts, 0.3-0.5=24pts, 0.2-0.3=18pts, 0.1-0.2=12pts, 0-0.1=6pts), positive operating cash flow (20pts), and cash flow adequacy (≥1.0=10pts, 0.8-1.0=8pts, 0.6-0.8=6pts, 0.4-0.6=4pts); Growth (10%) based on revenue scale (>1B=25pts, 500M-1B=20pts, 200M-500M=15pts, 100M-200M=10pts, <100M=5pts) and profit stability (positive net income=15pts, positive operating income=10pts, positive gross profit=5pts); and Operational Efficiency (10%) using asset turnover (≥1.5=60pts, 1.2-1.5=48pts, 1.0-1.2=36pts, 0.8-1.0=24pts, 0.5-0.8=12pts) and operating expense ratio (≤20%=40pts, 20-30%=32pts, 30-40%=24pts, 40-50%=16pts, 50-60%=8pts). Final scores determine risk grades: A (85-100)=8% interest/70% LTV/36 months, B (70-84)=12%/50%/24 months, C (55-69)=18%/30%/12 months, D (40-54)=24%/20%/6 months, F (0-39)=rejected. Assume the loan amount is in IDR: \n', extracted_layout, num_employees, main_products, loan_amount_numeric, loan_purpose)
    ) as result,
    AI_COMPLETE(
        'claude-4-sonnet',
        CONCAT('Based on column `result`, extract the Credit Score and only show the numeric value: \n', result)
    ) as score,
    AI_COMPLETE(
        'claude-4-sonnet',
        CONCAT('Based on column `score`, classify the result when `score` >= 50 give label "Good Borrower"
        and if `score` < 50 give label "Bad Borrower". Only show the result, no need reasoning: \n', score)
    ) as classify_borrower
FROM dev_final_joined;
