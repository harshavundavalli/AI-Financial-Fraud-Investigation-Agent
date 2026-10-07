# AI Financial Fraud Investigation Agent

AI-powered fraud detection and investigation system built on Snowflake using Cortex AI, a Cortex Agent, and Streamlit.

## Architecture

```
Synthetic Data → Core Tables → Cortex AI Analysis → Investigation Agent → Streamlit Dashboard
```

## Components

### Database: `FRAUD_INVESTIGATION_DB`

| Schema | Purpose |
|--------|---------|
| `RAW` | Customers, Merchants, Devices, Transactions |
| `ANALYTICS` | Fraud Cases, Alerts, Investigation Notes |
| `AI` | Cortex AI functions, Semantic View, Agent |

### Data (Synthetic)
- **5,000** customers with risk profiles
- **500** merchants across 12 categories
- **10,000** device fingerprints
- **75,195** transactions (~2.9% fraud rate)
- **2,195** alerts from 6 detection rules
- **1,693** fraud cases across 5 statuses
- **2,955** investigation notes (AI + analyst)

### 6 Fraud Patterns
| Pattern | Count | Description |
|---------|-------|-------------|
| UNUSUAL_AMOUNT | 500 | Transactions 10x+ normal spending |
| VELOCITY_SPIKE | 400 | Rapid successive transactions |
| NEW_DEVICE | 350 | Unrecognized devices |
| HIGH_RISK_MERCHANT | 345 | Crypto, wire transfer, ATM |
| GEOGRAPHIC_IMPOSSIBILITY | 300 | Impossible travel (London/Sydney) |
| ROUND_DOLLAR_ODD_HOURS | 300 | Round amounts at 1-5 AM |

### Cortex AI Functions
- `ANALYZE_TRANSACTION_PATTERN(customer_id)` — AI pattern analysis
- `GENERATE_CASE_SUMMARY(case_id)` — Executive case summary
- `CLASSIFY_TRANSACTION_RISK(txn_id)` — Risk classification
- `RECOMMEND_ESCALATION(case_id)` — Escalation recommendation
- `OPEN_INVESTIGATION(alert_id, analyst)` — Create case from alert

### Cortex Agent
- `FRAUD_INVESTIGATION_AGENT` — Natural language fraud investigation queries
- `FRAUD_INVESTIGATION_SV` — Semantic view over all fraud tables

### Streamlit Dashboard
5-tab dashboard: Cases, Fraud Analysis, Alerts, Team, AI Chat

## Setup

1. Run `setup.sql` in a Snowflake worksheet to create the database, tables, data, and AI functions
2. Deploy the Streamlit app from the `fraud-investigation-dashboard/` folder
3. The Cortex Agent and Semantic View are created by the setup script

## Requirements
- Snowflake account with Cortex AI enabled
- `ACCOUNTADMIN` role (or equivalent privileges)
- A warehouse (e.g., `COMPUTE_WH`)

## Testing

```sql
-- Test AI risk classification
SELECT FRAUD_INVESTIGATION_DB.AI.CLASSIFY_TRANSACTION_RISK('TXN-F1-00001');

-- Test case summary generation
SELECT FRAUD_INVESTIGATION_DB.AI.GENERATE_CASE_SUMMARY('CASE-000001');

-- Query the Cortex Agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'FRAUD_INVESTIGATION_DB.AI.FRAUD_INVESTIGATION_AGENT',
    'How many fraud cases are open vs closed?'
);
```
