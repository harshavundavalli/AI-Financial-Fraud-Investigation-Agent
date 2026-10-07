-- ============================================================================
-- AI Financial Fraud Investigation Agent - Complete Setup Script
-- ============================================================================
-- This script creates the entire fraud investigation project from scratch:
--   1. Database, schemas, and tables
--   2. Synthetic data (customers, merchants, devices)
--   3. Transactions with injected fraud patterns
--   4. Alerts and fraud cases
--   5. Cortex AI analysis functions
-- ============================================================================
-- Prerequisites: ACCOUNTADMIN role, COMPUTE_WH warehouse
-- Estimated runtime: ~2 minutes
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- 1. DATABASE & SCHEMAS
-- ============================================================================

CREATE OR REPLACE DATABASE FRAUD_INVESTIGATION_DB
    COMMENT = 'AI Financial Fraud Investigation Agent Project';

USE DATABASE FRAUD_INVESTIGATION_DB;

CREATE SCHEMA IF NOT EXISTS RAW COMMENT = 'Raw synthetic data';
CREATE SCHEMA IF NOT EXISTS ANALYTICS COMMENT = 'Derived analytics and investigation data';
CREATE SCHEMA IF NOT EXISTS AI COMMENT = 'AI models, agents, and semantic layers';

-- ============================================================================
-- 2. TABLES
-- ============================================================================

CREATE OR REPLACE TABLE RAW.CUSTOMERS (
    CUSTOMER_ID VARCHAR(20) PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    EMAIL VARCHAR(100),
    PHONE VARCHAR(20),
    DATE_OF_BIRTH DATE,
    SSN_LAST4 VARCHAR(4),
    ADDRESS_LINE1 VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(2),
    ZIP_CODE VARCHAR(10),
    COUNTRY VARCHAR(3) DEFAULT 'USA',
    ACCOUNT_OPEN_DATE DATE,
    ACCOUNT_STATUS VARCHAR(20) DEFAULT 'ACTIVE',
    RISK_SCORE NUMBER(5,2) DEFAULT 0,
    RISK_TIER VARCHAR(10) DEFAULT 'LOW',
    ANNUAL_INCOME NUMBER(12,2),
    CREDIT_SCORE NUMBER(3),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RAW.MERCHANTS (
    MERCHANT_ID VARCHAR(20) PRIMARY KEY,
    MERCHANT_NAME VARCHAR(200),
    CATEGORY VARCHAR(50),
    MCC_CODE VARCHAR(4),
    ADDRESS VARCHAR(300),
    CITY VARCHAR(100),
    STATE VARCHAR(2),
    ZIP_CODE VARCHAR(10),
    COUNTRY VARCHAR(3) DEFAULT 'USA',
    LATITUDE NUMBER(10,7),
    LONGITUDE NUMBER(10,7),
    RISK_LEVEL VARCHAR(10) DEFAULT 'LOW',
    IS_ONLINE BOOLEAN DEFAULT FALSE,
    REGISTERED_DATE DATE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE RAW.DEVICES (
    DEVICE_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20),
    DEVICE_TYPE VARCHAR(30),
    DEVICE_MODEL VARCHAR(100),
    OS_TYPE VARCHAR(30),
    OS_VERSION VARCHAR(20),
    BROWSER VARCHAR(50),
    IP_ADDRESS VARCHAR(45),
    DEVICE_FINGERPRINT VARCHAR(64),
    FIRST_SEEN_AT TIMESTAMP_NTZ,
    LAST_SEEN_AT TIMESTAMP_NTZ,
    IS_TRUSTED BOOLEAN DEFAULT FALSE,
    LOCATION_CITY VARCHAR(100),
    LOCATION_STATE VARCHAR(2),
    LOCATION_COUNTRY VARCHAR(3) DEFAULT 'USA',
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES RAW.CUSTOMERS(CUSTOMER_ID)
);

CREATE OR REPLACE TABLE RAW.TRANSACTIONS (
    TRANSACTION_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20),
    MERCHANT_ID VARCHAR(20),
    DEVICE_ID VARCHAR(20),
    TRANSACTION_DATE TIMESTAMP_NTZ,
    AMOUNT NUMBER(12,2),
    CURRENCY VARCHAR(3) DEFAULT 'USD',
    TRANSACTION_TYPE VARCHAR(20),
    CHANNEL VARCHAR(20),
    STATUS VARCHAR(20) DEFAULT 'COMPLETED',
    IS_INTERNATIONAL BOOLEAN DEFAULT FALSE,
    IS_CARD_PRESENT BOOLEAN DEFAULT TRUE,
    RESPONSE_CODE VARCHAR(10),
    AUTH_CODE VARCHAR(20),
    IP_ADDRESS VARCHAR(45),
    LATITUDE NUMBER(10,7),
    LONGITUDE NUMBER(10,7),
    IS_FRAUD BOOLEAN DEFAULT FALSE,
    FRAUD_TYPE VARCHAR(50),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES RAW.CUSTOMERS(CUSTOMER_ID),
    FOREIGN KEY (MERCHANT_ID) REFERENCES RAW.MERCHANTS(MERCHANT_ID)
);

CREATE OR REPLACE TABLE ANALYTICS.ALERTS (
    ALERT_ID VARCHAR(20) PRIMARY KEY,
    TRANSACTION_ID VARCHAR(20),
    CUSTOMER_ID VARCHAR(20),
    ALERT_TYPE VARCHAR(50),
    SEVERITY VARCHAR(10),
    RULE_NAME VARCHAR(100),
    RULE_DESCRIPTION TEXT,
    SCORE NUMBER(5,2),
    STATUS VARCHAR(20) DEFAULT 'NEW',
    REVIEWED_BY VARCHAR(100),
    REVIEWED_AT TIMESTAMP_NTZ,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE ANALYTICS.FRAUD_CASES (
    CASE_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20),
    TRANSACTION_ID VARCHAR(20),
    ALERT_ID VARCHAR(20),
    CASE_STATUS VARCHAR(20) DEFAULT 'OPEN',
    PRIORITY VARCHAR(10) DEFAULT 'MEDIUM',
    ASSIGNED_TO VARCHAR(100),
    FRAUD_TYPE VARCHAR(50),
    ESTIMATED_LOSS NUMBER(12,2),
    ACTUAL_LOSS NUMBER(12,2),
    RISK_SCORE NUMBER(5,2),
    AI_CONFIDENCE_SCORE NUMBER(5,4),
    AI_RECOMMENDATION VARCHAR(500),
    OPENED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CLOSED_AT TIMESTAMP_NTZ,
    RESOLUTION VARCHAR(50),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE ANALYTICS.INVESTIGATION_NOTES (
    NOTE_ID VARCHAR(20) PRIMARY KEY,
    CASE_ID VARCHAR(20),
    NOTE_TYPE VARCHAR(30),
    AUTHOR VARCHAR(100),
    CONTENT TEXT,
    AI_GENERATED BOOLEAN DEFAULT FALSE,
    SENTIMENT_SCORE NUMBER(5,4),
    KEY_ENTITIES VARIANT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- 3. SYNTHETIC BASE DATA
-- ============================================================================

-- 3a. 5,000 Customers
INSERT INTO RAW.CUSTOMERS
SELECT
    'CUST-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 6, '0'),
    CASE MOD(ABS(HASH(SEQ8())), 50)
        WHEN 0 THEN 'James' WHEN 1 THEN 'Mary' WHEN 2 THEN 'Robert' WHEN 3 THEN 'Patricia' WHEN 4 THEN 'John'
        WHEN 5 THEN 'Jennifer' WHEN 6 THEN 'Michael' WHEN 7 THEN 'Linda' WHEN 8 THEN 'David' WHEN 9 THEN 'Elizabeth'
        WHEN 10 THEN 'William' WHEN 11 THEN 'Barbara' WHEN 12 THEN 'Richard' WHEN 13 THEN 'Susan' WHEN 14 THEN 'Joseph'
        WHEN 15 THEN 'Jessica' WHEN 16 THEN 'Thomas' WHEN 17 THEN 'Sarah' WHEN 18 THEN 'Christopher' WHEN 19 THEN 'Karen'
        WHEN 20 THEN 'Charles' WHEN 21 THEN 'Lisa' WHEN 22 THEN 'Daniel' WHEN 23 THEN 'Nancy' WHEN 24 THEN 'Matthew'
        WHEN 25 THEN 'Betty' WHEN 26 THEN 'Anthony' WHEN 27 THEN 'Margaret' WHEN 28 THEN 'Mark' WHEN 29 THEN 'Sandra'
        WHEN 30 THEN 'Donald' WHEN 31 THEN 'Ashley' WHEN 32 THEN 'Steven' WHEN 33 THEN 'Dorothy' WHEN 34 THEN 'Andrew'
        WHEN 35 THEN 'Kimberly' WHEN 36 THEN 'Paul' WHEN 37 THEN 'Emily' WHEN 38 THEN 'Joshua' WHEN 39 THEN 'Donna'
        WHEN 40 THEN 'Kenneth' WHEN 41 THEN 'Michelle' WHEN 42 THEN 'Kevin' WHEN 43 THEN 'Carol' WHEN 44 THEN 'Brian'
        WHEN 45 THEN 'Amanda' WHEN 46 THEN 'George' WHEN 47 THEN 'Melissa' WHEN 48 THEN 'Timothy' ELSE 'Deborah'
    END AS FIRST_NAME,
    CASE MOD(ABS(HASH(SEQ8() * 7)), 50)
        WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams' WHEN 3 THEN 'Brown' WHEN 4 THEN 'Jones'
        WHEN 5 THEN 'Garcia' WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis' WHEN 8 THEN 'Rodriguez' WHEN 9 THEN 'Martinez'
        WHEN 10 THEN 'Hernandez' WHEN 11 THEN 'Lopez' WHEN 12 THEN 'Gonzalez' WHEN 13 THEN 'Wilson' WHEN 14 THEN 'Anderson'
        WHEN 15 THEN 'Thomas' WHEN 16 THEN 'Taylor' WHEN 17 THEN 'Moore' WHEN 18 THEN 'Jackson' WHEN 19 THEN 'Martin'
        WHEN 20 THEN 'Lee' WHEN 21 THEN 'Perez' WHEN 22 THEN 'Thompson' WHEN 23 THEN 'White' WHEN 24 THEN 'Harris'
        WHEN 25 THEN 'Sanchez' WHEN 26 THEN 'Clark' WHEN 27 THEN 'Ramirez' WHEN 28 THEN 'Lewis' WHEN 29 THEN 'Robinson'
        WHEN 30 THEN 'Walker' WHEN 31 THEN 'Young' WHEN 32 THEN 'Allen' WHEN 33 THEN 'King' WHEN 34 THEN 'Wright'
        WHEN 35 THEN 'Scott' WHEN 36 THEN 'Torres' WHEN 37 THEN 'Nguyen' WHEN 38 THEN 'Hill' WHEN 39 THEN 'Flores'
        WHEN 40 THEN 'Green' WHEN 41 THEN 'Adams' WHEN 42 THEN 'Nelson' WHEN 43 THEN 'Baker' WHEN 44 THEN 'Hall'
        WHEN 45 THEN 'Rivera' WHEN 46 THEN 'Campbell' WHEN 47 THEN 'Mitchell' WHEN 48 THEN 'Carter' ELSE 'Roberts'
    END AS LAST_NAME,
    LOWER(FIRST_NAME) || '.' || LOWER(LAST_NAME) || ROW_NUMBER() OVER (ORDER BY SEQ8()) || '@' ||
        CASE MOD(ABS(HASH(SEQ8() * 3)), 5) WHEN 0 THEN 'gmail.com' WHEN 1 THEN 'yahoo.com' WHEN 2 THEN 'outlook.com' WHEN 3 THEN 'hotmail.com' ELSE 'email.com' END,
    '555-' || LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0'),
    DATEADD('day', -UNIFORM(6570, 25550, RANDOM()), CURRENT_DATE()),
    LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0'),
    UNIFORM(100, 9999, RANDOM())::VARCHAR || ' ' ||
        CASE MOD(ABS(HASH(SEQ8() * 11)), 6) WHEN 0 THEN 'Oak St' WHEN 1 THEN 'Maple Ave' WHEN 2 THEN 'Pine Blvd' WHEN 3 THEN 'Elm Dr' WHEN 4 THEN 'Cedar Ln' ELSE 'Main St' END,
    CASE MOD(ABS(HASH(SEQ8() * 13)), 20)
        WHEN 0 THEN 'Los Angeles' WHEN 1 THEN 'New York' WHEN 2 THEN 'Houston' WHEN 3 THEN 'Miami' WHEN 4 THEN 'Chicago'
        WHEN 5 THEN 'Phoenix' WHEN 6 THEN 'Seattle' WHEN 7 THEN 'Denver' WHEN 8 THEN 'Atlanta' WHEN 9 THEN 'Boston'
        WHEN 10 THEN 'Dallas' WHEN 11 THEN 'San Francisco' WHEN 12 THEN 'Portland' WHEN 13 THEN 'Nashville' WHEN 14 THEN 'Charlotte'
        WHEN 15 THEN 'Detroit' WHEN 16 THEN 'Philadelphia' WHEN 17 THEN 'Las Vegas' WHEN 18 THEN 'Orlando' ELSE 'Austin'
    END AS CITY,
    CASE CITY
        WHEN 'Los Angeles' THEN 'CA' WHEN 'San Francisco' THEN 'CA' WHEN 'New York' THEN 'NY' WHEN 'Houston' THEN 'TX'
        WHEN 'Dallas' THEN 'TX' WHEN 'Austin' THEN 'TX' WHEN 'Miami' THEN 'FL' WHEN 'Orlando' THEN 'FL'
        WHEN 'Chicago' THEN 'IL' WHEN 'Phoenix' THEN 'AZ' WHEN 'Seattle' THEN 'WA' WHEN 'Denver' THEN 'CO'
        WHEN 'Atlanta' THEN 'GA' WHEN 'Boston' THEN 'MA' WHEN 'Portland' THEN 'OR' WHEN 'Nashville' THEN 'TN'
        WHEN 'Charlotte' THEN 'NC' WHEN 'Detroit' THEN 'MI' WHEN 'Philadelphia' THEN 'PA' WHEN 'Las Vegas' THEN 'NV'
        ELSE 'CA'
    END,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0'),
    'USA',
    DATEADD('day', -UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()),
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 92 THEN 'ACTIVE' WHEN UNIFORM(1, 100, RANDOM()) <= 97 THEN 'SUSPENDED' ELSE 'CLOSED' END,
    CASE
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN UNIFORM(0, 30, RANDOM())
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN UNIFORM(31, 60, RANDOM())
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN UNIFORM(61, 85, RANDOM())
        ELSE UNIFORM(86, 100, RANDOM())
    END AS RISK_SCORE,
    CASE
        WHEN RISK_SCORE <= 30 THEN 'LOW'
        WHEN RISK_SCORE <= 60 THEN 'MEDIUM'
        WHEN RISK_SCORE <= 85 THEN 'HIGH'
        ELSE 'CRITICAL'
    END,
    UNIFORM(20000, 250000, RANDOM())::NUMBER(12,2),
    UNIFORM(300, 850, RANDOM()),
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- 3b. 500 Merchants
INSERT INTO RAW.MERCHANTS
SELECT
    'MERCH-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    CASE MOD(ABS(HASH(SEQ8())), 30)
        WHEN 0 THEN 'Walmart' WHEN 1 THEN 'Target' WHEN 2 THEN 'Amazon' WHEN 3 THEN 'Best Buy' WHEN 4 THEN 'Costco'
        WHEN 5 THEN 'Home Depot' WHEN 6 THEN 'Starbucks' WHEN 7 THEN 'McDonalds' WHEN 8 THEN 'Shell Gas' WHEN 9 THEN 'CVS Pharmacy'
        WHEN 10 THEN 'Uber' WHEN 11 THEN 'Netflix' WHEN 12 THEN 'Apple Store' WHEN 13 THEN 'Nike' WHEN 14 THEN 'Whole Foods'
        WHEN 15 THEN 'Chevron' WHEN 16 THEN 'Walgreens' WHEN 17 THEN 'Chipotle' WHEN 18 THEN 'Subway' WHEN 19 THEN 'FedEx'
        WHEN 20 THEN 'Delta Airlines' WHEN 21 THEN 'Hilton Hotels' WHEN 22 THEN 'Lyft' WHEN 23 THEN 'DoorDash' WHEN 24 THEN 'Sephora'
        WHEN 25 THEN 'GameStop' WHEN 26 THEN 'Nordstrom' WHEN 27 THEN 'TJ Maxx' WHEN 28 THEN 'Dollar General' ELSE 'QuickMart'
    END || ' #' || UNIFORM(100, 999, RANDOM())::VARCHAR,
    CASE MOD(ABS(HASH(SEQ8() * 3)), 12)
        WHEN 0 THEN 'GROCERY' WHEN 1 THEN 'GAS_STATION' WHEN 2 THEN 'RESTAURANT' WHEN 3 THEN 'RETAIL'
        WHEN 4 THEN 'ONLINE_SHOPPING' WHEN 5 THEN 'TRAVEL' WHEN 6 THEN 'ENTERTAINMENT' WHEN 7 THEN 'HEALTHCARE'
        WHEN 8 THEN 'ATM' WHEN 9 THEN 'ELECTRONICS' WHEN 10 THEN 'CRYPTOCURRENCY' ELSE 'WIRE_TRANSFER'
    END AS CATEGORY,
    LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0'),
    UNIFORM(1, 999, RANDOM())::VARCHAR || ' Commerce Blvd',
    CASE MOD(ABS(HASH(SEQ8() * 7)), 15)
        WHEN 0 THEN 'Los Angeles' WHEN 1 THEN 'New York' WHEN 2 THEN 'Houston' WHEN 3 THEN 'Miami' WHEN 4 THEN 'Chicago'
        WHEN 5 THEN 'Phoenix' WHEN 6 THEN 'Seattle' WHEN 7 THEN 'Denver' WHEN 8 THEN 'Atlanta' WHEN 9 THEN 'Boston'
        WHEN 10 THEN 'Dallas' WHEN 11 THEN 'San Francisco' WHEN 12 THEN 'Portland' WHEN 13 THEN 'Las Vegas' ELSE 'Nashville'
    END AS CITY,
    CASE CITY
        WHEN 'Los Angeles' THEN 'CA' WHEN 'San Francisco' THEN 'CA' WHEN 'New York' THEN 'NY' WHEN 'Houston' THEN 'TX'
        WHEN 'Dallas' THEN 'TX' WHEN 'Miami' THEN 'FL' WHEN 'Chicago' THEN 'IL' WHEN 'Phoenix' THEN 'AZ'
        WHEN 'Seattle' THEN 'WA' WHEN 'Denver' THEN 'CO' WHEN 'Atlanta' THEN 'GA' WHEN 'Boston' THEN 'MA'
        WHEN 'Portland' THEN 'OR' WHEN 'Las Vegas' THEN 'NV' ELSE 'TN'
    END,
    LPAD(UNIFORM(10001, 99999, RANDOM())::VARCHAR, 5, '0'),
    'USA',
    UNIFORM(25, 48, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0,
    -(UNIFORM(70, 122, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0),
    CASE
        WHEN CATEGORY IN ('CRYPTOCURRENCY', 'WIRE_TRANSFER', 'ATM') THEN 'HIGH'
        WHEN CATEGORY IN ('ONLINE_SHOPPING', 'ENTERTAINMENT') AND UNIFORM(1,100,RANDOM()) > 70 THEN 'MEDIUM'
        ELSE 'LOW'
    END,
    CASE WHEN CATEGORY IN ('ONLINE_SHOPPING', 'ENTERTAINMENT', 'CRYPTOCURRENCY') THEN TRUE ELSE FALSE END,
    DATEADD('day', -UNIFORM(365, 3650, RANDOM()), CURRENT_DATE()),
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- 3c. 10,000 Devices
INSERT INTO RAW.DEVICES
SELECT
    'DEV-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 6, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 5000) + 1)::VARCHAR, 6, '0'),
    CASE MOD(ABS(HASH(SEQ8() * 3)), 5)
        WHEN 0 THEN 'MOBILE' WHEN 1 THEN 'DESKTOP' WHEN 2 THEN 'TABLET' WHEN 3 THEN 'POS_TERMINAL' ELSE 'ATM'
    END AS DEVICE_TYPE,
    CASE DEVICE_TYPE
        WHEN 'MOBILE' THEN CASE MOD(ABS(HASH(SEQ8()*7)),4) WHEN 0 THEN 'iPhone 15' WHEN 1 THEN 'Samsung Galaxy S24' WHEN 2 THEN 'Google Pixel 8' ELSE 'iPhone 14' END
        WHEN 'DESKTOP' THEN CASE MOD(ABS(HASH(SEQ8()*11)),3) WHEN 0 THEN 'Windows PC' WHEN 1 THEN 'MacBook Pro' ELSE 'Chromebook' END
        WHEN 'TABLET' THEN CASE MOD(ABS(HASH(SEQ8()*13)),3) WHEN 0 THEN 'iPad Pro' WHEN 1 THEN 'Samsung Tab' ELSE 'Surface Pro' END
        WHEN 'POS_TERMINAL' THEN 'Verifone VX520'
        ELSE 'NCR SelfServ'
    END,
    CASE
        WHEN DEVICE_TYPE = 'MOBILE' THEN CASE WHEN DEVICE_MODEL LIKE 'iPhone%' THEN 'iOS' ELSE 'Android' END
        WHEN DEVICE_TYPE = 'DESKTOP' THEN CASE WHEN DEVICE_MODEL = 'MacBook Pro' THEN 'macOS' WHEN DEVICE_MODEL = 'Chromebook' THEN 'ChromeOS' ELSE 'Windows' END
        WHEN DEVICE_TYPE = 'TABLET' THEN CASE WHEN DEVICE_MODEL = 'iPad Pro' THEN 'iPadOS' WHEN DEVICE_MODEL = 'Surface Pro' THEN 'Windows' ELSE 'Android' END
        ELSE 'Embedded'
    END AS OS_TYPE,
    CASE OS_TYPE WHEN 'iOS' THEN '17.' || UNIFORM(0,5,RANDOM()) WHEN 'Android' THEN '14.' || UNIFORM(0,3,RANDOM()) WHEN 'Windows' THEN '11.0' WHEN 'macOS' THEN '14.' || UNIFORM(0,3,RANDOM()) ELSE '1.0' END,
    CASE WHEN DEVICE_TYPE IN ('MOBILE','DESKTOP','TABLET') THEN
        CASE MOD(ABS(HASH(SEQ8()*17)),4) WHEN 0 THEN 'Chrome' WHEN 1 THEN 'Safari' WHEN 2 THEN 'Firefox' ELSE 'Edge' END
    ELSE NULL END,
    UNIFORM(1,255,RANDOM())::VARCHAR || '.' || UNIFORM(0,255,RANDOM())::VARCHAR || '.' || UNIFORM(0,255,RANDOM())::VARCHAR || '.' || UNIFORM(0,255,RANDOM())::VARCHAR,
    MD5(SEQ8()::VARCHAR || RANDOM()::VARCHAR),
    DATEADD('day', -UNIFORM(1, 730, RANDOM()), CURRENT_TIMESTAMP()),
    DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_TIMESTAMP()),
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 75 THEN TRUE ELSE FALSE END,
    CASE MOD(ABS(HASH(SEQ8() * 19)), 15)
        WHEN 0 THEN 'Los Angeles' WHEN 1 THEN 'New York' WHEN 2 THEN 'Houston' WHEN 3 THEN 'Miami' WHEN 4 THEN 'Chicago'
        WHEN 5 THEN 'Phoenix' WHEN 6 THEN 'Seattle' WHEN 7 THEN 'Denver' WHEN 8 THEN 'Atlanta' WHEN 9 THEN 'Boston'
        WHEN 10 THEN 'Dallas' WHEN 11 THEN 'San Francisco' WHEN 12 THEN 'Portland' WHEN 13 THEN 'Las Vegas' ELSE 'Nashville'
    END AS LOCATION_CITY,
    CASE LOCATION_CITY
        WHEN 'Los Angeles' THEN 'CA' WHEN 'San Francisco' THEN 'CA' WHEN 'New York' THEN 'NY' WHEN 'Houston' THEN 'TX'
        WHEN 'Dallas' THEN 'TX' WHEN 'Miami' THEN 'FL' WHEN 'Chicago' THEN 'IL' WHEN 'Phoenix' THEN 'AZ'
        WHEN 'Seattle' THEN 'WA' WHEN 'Denver' THEN 'CO' WHEN 'Atlanta' THEN 'GA' WHEN 'Boston' THEN 'MA'
        WHEN 'Portland' THEN 'OR' WHEN 'Las Vegas' THEN 'NV' ELSE 'TN'
    END,
    'USA',
    CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 10000));

-- ============================================================================
-- 4. TRANSACTIONS (73K legitimate + 6 fraud patterns)
-- ============================================================================

-- 4a. 73,000 Legitimate transactions
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 7, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 5000) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8() * 3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8() * 7)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('second', -UNIFORM(0, 15552000, RANDOM()), CURRENT_TIMESTAMP()),
    CASE MOD(ABS(HASH(SEQ8() * 11)), 10)
        WHEN 0 THEN ROUND(UNIFORM(1, 15, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 1 THEN ROUND(UNIFORM(15, 50, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 2 THEN ROUND(UNIFORM(50, 150, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 3 THEN ROUND(UNIFORM(150, 500, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 4 THEN ROUND(UNIFORM(5, 80, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 5 THEN ROUND(UNIFORM(20, 200, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 6 THEN ROUND(UNIFORM(2, 30, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 7 THEN ROUND(UNIFORM(100, 1000, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        WHEN 8 THEN ROUND(UNIFORM(10, 60, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
        ELSE ROUND(UNIFORM(25, 300, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2)
    END,
    'USD',
    CASE MOD(ABS(HASH(SEQ8() * 13)), 5) WHEN 0 THEN 'PURCHASE' WHEN 1 THEN 'PURCHASE' WHEN 2 THEN 'PURCHASE' WHEN 3 THEN 'WITHDRAWAL' ELSE 'TRANSFER' END,
    CASE MOD(ABS(HASH(SEQ8() * 17)), 4) WHEN 0 THEN 'ONLINE' WHEN 1 THEN 'IN_STORE' WHEN 2 THEN 'MOBILE_APP' ELSE 'ATM' END AS CHANNEL,
    'COMPLETED',
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5 THEN TRUE ELSE FALSE END,
    CASE WHEN CHANNEL IN ('IN_STORE', 'ATM') THEN TRUE ELSE FALSE END,
    '00',
    'AUTH-' || UNIFORM(100000, 999999, RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25, 48, RANDOM()) + UNIFORM(0, 999999, RANDOM()) / 1000000.0,
    -(UNIFORM(70, 122, RANDOM()) + UNIFORM(0, 999999, RANDOM()) / 1000000.0),
    FALSE, NULL, CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 73000));

-- 4b. Fraud: UNUSUAL_AMOUNT (500) - transactions 10x+ normal spending
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F1-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 500) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8() * 3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8() * 5)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('second', -UNIFORM(0, 7776000, RANDOM()), CURRENT_TIMESTAMP()),
    ROUND(UNIFORM(5000, 25000, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2),
    'USD', 'PURCHASE', 'ONLINE', 'COMPLETED',
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 40 THEN TRUE ELSE FALSE END,
    FALSE, '00', 'AUTH-' || UNIFORM(100000, 999999, RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25,48,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0,
    -(UNIFORM(70,122,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0),
    TRUE, 'UNUSUAL_AMOUNT', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- 4c. Fraud: GEOGRAPHIC_IMPOSSIBILITY (300) - London/Sydney impossible travel
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F2-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 200) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8() * 3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8() * 5)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('minute', -UNIFORM(5, 120, RANDOM()), CURRENT_TIMESTAMP()),
    ROUND(UNIFORM(200, 3000, RANDOM()) + UNIFORM(0, 99, RANDOM()) / 100.0, 2),
    'USD', 'PURCHASE',
    CASE WHEN UNIFORM(1,2,RANDOM()) = 1 THEN 'IN_STORE' ELSE 'ATM' END,
    'COMPLETED', TRUE, TRUE, '00', 'AUTH-' || UNIFORM(100000, 999999, RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    CASE WHEN MOD(ABS(HASH(SEQ8())),2)=0 THEN 51.5074 ELSE -33.8688 END,
    CASE WHEN MOD(ABS(HASH(SEQ8())),2)=0 THEN -0.1278 ELSE 151.2093 END,
    TRUE, 'GEOGRAPHIC_IMPOSSIBILITY', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 300));

-- 4d. Fraud: VELOCITY_SPIKE (400) - rapid successive transactions
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F3-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 300) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8()*3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8()*5)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('second', -UNIFORM(0, 300, RANDOM()), DATEADD('day', -UNIFORM(0, 90, RANDOM()), CURRENT_TIMESTAMP())),
    ROUND(UNIFORM(50, 800, RANDOM()) + UNIFORM(0,99,RANDOM())/100.0, 2),
    'USD', 'PURCHASE', 'ONLINE', 'COMPLETED',
    FALSE, FALSE, '00', 'AUTH-' || UNIFORM(100000,999999,RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25,48,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0,
    -(UNIFORM(70,122,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0),
    TRUE, 'VELOCITY_SPIKE', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 400));

-- 4e. Fraud: NEW_DEVICE (350) - unrecognized device
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F4-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 350) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8()*3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8()*7)), 2000) + 8001)::VARCHAR, 6, '0'),
    DATEADD('hour', -UNIFORM(0, 2160, RANDOM()), CURRENT_TIMESTAMP()),
    ROUND(UNIFORM(500, 5000, RANDOM()) + UNIFORM(0,99,RANDOM())/100.0, 2),
    'USD', 'PURCHASE', 'ONLINE', 'COMPLETED',
    CASE WHEN UNIFORM(1,100,RANDOM())<=30 THEN TRUE ELSE FALSE END,
    FALSE, '00', 'AUTH-' || UNIFORM(100000,999999,RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25,48,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0,
    -(UNIFORM(70,122,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0),
    TRUE, 'NEW_DEVICE', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 350));

-- 4f. Fraud: ROUND_DOLLAR_ODD_HOURS (300) - round amounts at 1-5 AM
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F5-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 300) + 1)::VARCHAR, 6, '0'),
    'MERCH-' || LPAD((MOD(ABS(HASH(SEQ8()*3)), 500) + 1)::VARCHAR, 5, '0'),
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8()*5)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('hour', UNIFORM(1, 5, RANDOM()), DATEADD('day', -UNIFORM(0, 90, RANDOM()), DATE_TRUNC('day', CURRENT_TIMESTAMP()))),
    UNIFORM(1, 50, RANDOM()) * 100.00,
    'USD', 'TRANSFER', 'ONLINE', 'COMPLETED',
    CASE WHEN UNIFORM(1,100,RANDOM())<=20 THEN TRUE ELSE FALSE END,
    FALSE, '00', 'AUTH-' || UNIFORM(100000,999999,RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25,48,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0,
    -(UNIFORM(70,122,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0),
    TRUE, 'ROUND_DOLLAR_ODD_HOURS', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 300));

-- 4g. Fraud: HIGH_RISK_MERCHANT (350) - crypto/wire/ATM merchants
INSERT INTO RAW.TRANSACTIONS
SELECT
    'TXN-F6-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ8())::VARCHAR, 5, '0'),
    'CUST-' || LPAD((MOD(ABS(HASH(SEQ8())), 350) + 1)::VARCHAR, 6, '0'),
    m.MERCHANT_ID,
    'DEV-' || LPAD((MOD(ABS(HASH(SEQ8()*5)), 10000) + 1)::VARCHAR, 6, '0'),
    DATEADD('hour', -UNIFORM(0, 2160, RANDOM()), CURRENT_TIMESTAMP()),
    ROUND(UNIFORM(1000, 15000, RANDOM()) + UNIFORM(0,99,RANDOM())/100.0, 2),
    'USD',
    CASE WHEN m.CATEGORY = 'WIRE_TRANSFER' THEN 'TRANSFER' WHEN m.CATEGORY = 'ATM' THEN 'WITHDRAWAL' ELSE 'PURCHASE' END,
    CASE WHEN m.CATEGORY IN ('CRYPTOCURRENCY','WIRE_TRANSFER') THEN 'ONLINE' ELSE 'ATM' END,
    'COMPLETED',
    CASE WHEN UNIFORM(1,100,RANDOM())<=50 THEN TRUE ELSE FALSE END,
    CASE WHEN m.CATEGORY = 'ATM' THEN TRUE ELSE FALSE END,
    '00', 'AUTH-' || UNIFORM(100000,999999,RANDOM())::VARCHAR,
    UNIFORM(1,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR||'.'||UNIFORM(0,255,RANDOM())::VARCHAR,
    UNIFORM(25,48,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0,
    -(UNIFORM(70,122,RANDOM()) + UNIFORM(0,999999,RANDOM())/1000000.0),
    TRUE, 'HIGH_RISK_MERCHANT', CURRENT_TIMESTAMP()
FROM TABLE(GENERATOR(ROWCOUNT => 350)) g
JOIN (SELECT MERCHANT_ID, CATEGORY FROM RAW.MERCHANTS WHERE RISK_LEVEL = 'HIGH' ORDER BY RANDOM() LIMIT 350) m
  ON MOD(ABS(HASH(SEQ8()*11)), (SELECT COUNT(*) FROM RAW.MERCHANTS WHERE RISK_LEVEL = 'HIGH')) = 0
LIMIT 350;

-- ============================================================================
-- 5. ALERTS (from all fraud transactions)
-- ============================================================================

INSERT INTO ANALYTICS.ALERTS
SELECT
    'ALT-' || LPAD(ROW_NUMBER() OVER (ORDER BY TRANSACTION_DATE)::VARCHAR, 6, '0'),
    TRANSACTION_ID, CUSTOMER_ID, FRAUD_TYPE,
    CASE FRAUD_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN CASE WHEN AMOUNT > 15000 THEN 'CRITICAL' WHEN AMOUNT > 10000 THEN 'HIGH' ELSE 'MEDIUM' END
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN 'HIGH'
        WHEN 'VELOCITY_SPIKE' THEN 'HIGH'
        WHEN 'NEW_DEVICE' THEN CASE WHEN AMOUNT > 3000 THEN 'HIGH' ELSE 'MEDIUM' END
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN 'MEDIUM'
        WHEN 'HIGH_RISK_MERCHANT' THEN CASE WHEN AMOUNT > 8000 THEN 'CRITICAL' WHEN AMOUNT > 3000 THEN 'HIGH' ELSE 'MEDIUM' END
    END,
    CASE FRAUD_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN 'RULE-AMT-001'
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN 'RULE-GEO-001'
        WHEN 'VELOCITY_SPIKE' THEN 'RULE-VEL-001'
        WHEN 'NEW_DEVICE' THEN 'RULE-DEV-001'
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN 'RULE-RND-001'
        WHEN 'HIGH_RISK_MERCHANT' THEN 'RULE-MRC-001'
    END,
    CASE FRAUD_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN 'Transaction amount exceeds 10x customer average spending pattern'
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN 'Transaction location impossible given prior transaction timing and distance'
        WHEN 'VELOCITY_SPIKE' THEN 'Multiple transactions in rapid succession exceeding normal frequency'
        WHEN 'NEW_DEVICE' THEN 'Transaction from previously unseen or untrusted device'
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN 'Round dollar amount transaction during unusual hours (1AM-5AM)'
        WHEN 'HIGH_RISK_MERCHANT' THEN 'Transaction at high-risk merchant category (crypto, wire transfer, ATM)'
    END,
    CASE FRAUD_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN LEAST(ROUND(60 + (AMOUNT / 25000.0) * 40, 2), 99)
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN ROUND(UNIFORM(80, 98, RANDOM()), 2)
        WHEN 'VELOCITY_SPIKE' THEN ROUND(UNIFORM(70, 95, RANDOM()), 2)
        WHEN 'NEW_DEVICE' THEN ROUND(UNIFORM(55, 85, RANDOM()), 2)
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN ROUND(UNIFORM(45, 75, RANDOM()), 2)
        WHEN 'HIGH_RISK_MERCHANT' THEN ROUND(UNIFORM(65, 92, RANDOM()), 2)
    END,
    CASE
        WHEN UNIFORM(1,100,RANDOM()) <= 40 THEN 'REVIEWED'
        WHEN UNIFORM(1,100,RANDOM()) <= 60 THEN 'ESCALATED'
        WHEN UNIFORM(1,100,RANDOM()) <= 80 THEN 'DISMISSED'
        ELSE 'NEW'
    END AS STATUS,
    CASE WHEN STATUS != 'NEW' THEN
        CASE MOD(ABS(HASH(TRANSACTION_ID)), 5)
            WHEN 0 THEN 'analyst.jones' WHEN 1 THEN 'analyst.smith' WHEN 2 THEN 'analyst.garcia'
            WHEN 3 THEN 'senior.williams' ELSE 'senior.chen'
        END
    ELSE NULL END,
    CASE WHEN STATUS != 'NEW' THEN DATEADD('hour', UNIFORM(1, 72, RANDOM()), TRANSACTION_DATE) ELSE NULL END,
    DATEADD('second', UNIFORM(1, 300, RANDOM()), TRANSACTION_DATE)
FROM RAW.TRANSACTIONS
WHERE IS_FRAUD = TRUE;

-- ============================================================================
-- 6. FRAUD CASES (from reviewed/escalated alerts)
-- ============================================================================

INSERT INTO ANALYTICS.FRAUD_CASES
WITH alert_data AS (
    SELECT
        a.ALERT_ID, a.CUSTOMER_ID, a.TRANSACTION_ID, a.ALERT_TYPE, a.SEVERITY, a.SCORE, a.CREATED_AT AS ALERT_CREATED,
        t.AMOUNT,
        CASE
            WHEN UNIFORM(1,100,RANDOM()) <= 25 THEN 'OPEN'
            WHEN UNIFORM(1,100,RANDOM()) <= 50 THEN 'IN_PROGRESS'
            WHEN UNIFORM(1,100,RANDOM()) <= 70 THEN 'ESCALATED'
            WHEN UNIFORM(1,100,RANDOM()) <= 90 THEN 'CLOSED_FRAUD'
            ELSE 'CLOSED_LEGITIMATE'
        END AS CS
    FROM ANALYTICS.ALERTS a
    JOIN RAW.TRANSACTIONS t ON a.TRANSACTION_ID = t.TRANSACTION_ID
    WHERE a.STATUS IN ('REVIEWED', 'ESCALATED')
)
SELECT
    'CASE-' || LPAD(ROW_NUMBER() OVER (ORDER BY ALERT_CREATED)::VARCHAR, 6, '0'),
    CUSTOMER_ID, TRANSACTION_ID, ALERT_ID, CS,
    CASE SEVERITY WHEN 'CRITICAL' THEN 'P1' WHEN 'HIGH' THEN 'P2' ELSE 'P3' END,
    CASE MOD(ABS(HASH(ALERT_ID)), 5)
        WHEN 0 THEN 'analyst.jones' WHEN 1 THEN 'analyst.smith' WHEN 2 THEN 'analyst.garcia'
        WHEN 3 THEN 'senior.williams' ELSE 'senior.chen'
    END,
    ALERT_TYPE, AMOUNT,
    CASE WHEN CS = 'CLOSED_FRAUD' THEN AMOUNT * UNIFORM(50,100,RANDOM()) / 100.0 ELSE NULL END,
    SCORE,
    ROUND(UNIFORM(6000,9900,RANDOM()) / 10000.0, 4),
    CASE ALERT_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN 'Recommend immediate account freeze and customer verification'
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN 'Recommend card block and identity verification call'
        WHEN 'VELOCITY_SPIKE' THEN 'Recommend temporary hold and pattern analysis review'
        WHEN 'NEW_DEVICE' THEN 'Recommend device verification and step-up authentication'
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN 'Recommend enhanced monitoring and customer outreach'
        WHEN 'HIGH_RISK_MERCHANT' THEN 'Recommend transaction reversal review and merchant investigation'
    END,
    ALERT_CREATED,
    CASE WHEN CS LIKE 'CLOSED%' THEN DATEADD('day', UNIFORM(1,30,RANDOM()), ALERT_CREATED) ELSE NULL END,
    CASE WHEN CS = 'CLOSED_FRAUD' THEN 'CONFIRMED_FRAUD' WHEN CS = 'CLOSED_LEGITIMATE' THEN 'FALSE_POSITIVE' ELSE NULL END,
    ALERT_CREATED,
    CURRENT_TIMESTAMP()
FROM alert_data;

-- ============================================================================
-- 7. INVESTIGATION NOTES
-- ============================================================================

-- 7a. AI assessment notes
INSERT INTO ANALYTICS.INVESTIGATION_NOTES
SELECT
    'NOTE-' || LPAD((ROW_NUMBER() OVER (ORDER BY CASE_ID))::VARCHAR, 6, '0'),
    CASE_ID, 'AI_ASSESSMENT', 'system.ai',
    CASE FRAUD_TYPE
        WHEN 'UNUSUAL_AMOUNT' THEN 'AI Analysis: Transaction of $' || ESTIMATED_LOSS::VARCHAR || ' detected for customer ' || CUSTOMER_ID || '. Amount exceeds typical spending by >10x. Risk score: ' || RISK_SCORE::VARCHAR || '. Recommend immediate review and potential account freeze.'
        WHEN 'GEOGRAPHIC_IMPOSSIBILITY' THEN 'AI Analysis: Geographic anomaly detected for customer ' || CUSTOMER_ID || '. Transaction originated from a location incompatible with prior activity. Risk score: ' || RISK_SCORE::VARCHAR || '.'
        WHEN 'VELOCITY_SPIKE' THEN 'AI Analysis: Velocity anomaly for customer ' || CUSTOMER_ID || '. Multiple rapid transactions detected. Pattern suggests automated fraud. Risk score: ' || RISK_SCORE::VARCHAR || '.'
        WHEN 'NEW_DEVICE' THEN 'AI Analysis: Unrecognized device used by customer ' || CUSTOMER_ID || '. Transaction of $' || ESTIMATED_LOSS::VARCHAR || ' from untrusted device. Possible account takeover. Risk score: ' || RISK_SCORE::VARCHAR || '.'
        WHEN 'ROUND_DOLLAR_ODD_HOURS' THEN 'AI Analysis: Suspicious pattern for customer ' || CUSTOMER_ID || '. Round-dollar transfer of $' || ESTIMATED_LOSS::VARCHAR || ' during off-hours. Possible money mule activity. Risk score: ' || RISK_SCORE::VARCHAR || '.'
        WHEN 'HIGH_RISK_MERCHANT' THEN 'AI Analysis: High-risk merchant transaction for customer ' || CUSTOMER_ID || '. Transaction of $' || ESTIMATED_LOSS::VARCHAR || ' at crypto/wire/ATM merchant. Risk score: ' || RISK_SCORE::VARCHAR || '.'
    END,
    TRUE,
    ROUND(UNIFORM(-100, -20, RANDOM()) / 100.0, 4),
    PARSE_JSON('{"customer_id": "' || CUSTOMER_ID || '", "fraud_type": "' || FRAUD_TYPE || '", "amount": ' || ESTIMATED_LOSS::VARCHAR || '}'),
    DATEADD('minute', UNIFORM(1, 30, RANDOM()), OPENED_AT)
FROM ANALYTICS.FRAUD_CASES;

-- 7b. Analyst notes for non-new cases
INSERT INTO ANALYTICS.INVESTIGATION_NOTES
SELECT
    'NOTE-A-' || LPAD(ROW_NUMBER() OVER (ORDER BY CASE_ID)::VARCHAR, 5, '0'),
    CASE_ID, 'ANALYST_NOTE', ASSIGNED_TO,
    CASE MOD(ABS(HASH(CASE_ID)), 8)
        WHEN 0 THEN 'Contacted customer via phone. Customer confirms they did not authorize this transaction. Proceeding with dispute process and temporary card block.'
        WHEN 1 THEN 'Reviewed transaction history for past 90 days. Multiple anomalies detected in the last week. Recommending escalation to senior investigator.'
        WHEN 2 THEN 'Customer reached via email. Stated they were traveling but transaction location does not match their itinerary. Flagging for further review.'
        WHEN 3 THEN 'Cross-referenced with known fraud ring patterns. Merchant ID matches a cluster of recently reported fraudulent merchants. Escalating to law enforcement liaison.'
        WHEN 4 THEN 'Device fingerprint analysis complete. Device was used in 3 other flagged accounts within 48 hours. Strong indicator of organized fraud operation.'
        WHEN 5 THEN 'Customer provided documentation confirming legitimate travel. Transaction appears valid despite initial alert. Recommending closure as false positive.'
        WHEN 6 THEN 'Reviewed IP geolocation data. IP associated with known VPN/proxy service frequently used in fraud schemes. Maintaining high risk classification.'
        ELSE 'Account activity review complete. Found additional suspicious transactions not initially flagged. Adding supplementary alerts and expanding investigation scope.'
    END,
    FALSE,
    ROUND(UNIFORM(-80, 40, RANDOM()) / 100.0, 4),
    NULL,
    DATEADD('hour', UNIFORM(2, 96, RANDOM()), OPENED_AT)
FROM ANALYTICS.FRAUD_CASES
WHERE CASE_STATUS NOT IN ('OPEN');

-- ============================================================================
-- 8. CORTEX AI FUNCTIONS
-- ============================================================================

-- Note: These use llama3.3-70b. If unavailable in your region, replace with
-- another supported model (e.g., mistral-large2, llama3.1-70b).

CREATE OR REPLACE FUNCTION AI.ANALYZE_TRANSACTION_PATTERN(P_CUSTOMER_ID VARCHAR)
RETURNS VARCHAR
AS
$$
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.3-70b',
    'You are a financial fraud analyst AI. Analyze this customer transaction summary and provide:
1. Risk assessment (LOW/MEDIUM/HIGH/CRITICAL)
2. Key suspicious patterns identified
3. Recommended investigation actions
4. Confidence level

Transaction data: ' || (
        SELECT OBJECT_CONSTRUCT(
            'customer_id', P_CUSTOMER_ID,
            'total_transactions', COUNT(*),
            'total_amount', SUM(AMOUNT),
            'avg_amount', ROUND(AVG(AMOUNT), 2),
            'max_amount', MAX(AMOUNT),
            'fraud_count', SUM(CASE WHEN IS_FRAUD THEN 1 ELSE 0 END),
            'channels', ARRAY_AGG(DISTINCT CHANNEL),
            'fraud_types', ARRAY_AGG(DISTINCT FRAUD_TYPE),
            'international_pct', ROUND(SUM(CASE WHEN IS_INTERNATIONAL THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 1)
        )::VARCHAR
        FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS
        WHERE CUSTOMER_ID = P_CUSTOMER_ID
    )
)
$$;

CREATE OR REPLACE FUNCTION AI.GENERATE_CASE_SUMMARY(P_CASE_ID VARCHAR)
RETURNS VARCHAR
AS
$$
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.3-70b',
    'You are a fraud investigation case summarizer. Generate a concise executive summary including: current status, key findings, risk level, financial impact, and next steps.

Case data: ' || (
        SELECT OBJECT_CONSTRUCT(
            'case_id', fc.CASE_ID,
            'status', fc.CASE_STATUS,
            'priority', fc.PRIORITY,
            'fraud_type', fc.FRAUD_TYPE,
            'estimated_loss', fc.ESTIMATED_LOSS,
            'risk_score', fc.RISK_SCORE,
            'ai_confidence', fc.AI_CONFIDENCE_SCORE,
            'assigned_to', fc.ASSIGNED_TO,
            'customer_id', fc.CUSTOMER_ID,
            'notes', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('type', NOTE_TYPE, 'content', LEFT(CONTENT, 200), 'author', AUTHOR))
                       FROM FRAUD_INVESTIGATION_DB.ANALYTICS.INVESTIGATION_NOTES n WHERE n.CASE_ID = fc.CASE_ID)
        )::VARCHAR
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES fc
        WHERE fc.CASE_ID = P_CASE_ID
    )
)
$$;

CREATE OR REPLACE FUNCTION AI.CLASSIFY_TRANSACTION_RISK(P_TRANSACTION_ID VARCHAR)
RETURNS VARCHAR
AS
$$
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.3-70b',
    'Classify the fraud risk of this transaction as exactly one of: LOW_RISK, MEDIUM_RISK, HIGH_RISK, CRITICAL_RISK. Then provide a one-sentence justification. Format: RISK_LEVEL: justification

Transaction: ' || (
        SELECT OBJECT_CONSTRUCT(
            'transaction_id', t.TRANSACTION_ID,
            'amount', t.AMOUNT,
            'type', t.TRANSACTION_TYPE,
            'channel', t.CHANNEL,
            'is_international', t.IS_INTERNATIONAL,
            'is_card_present', t.IS_CARD_PRESENT,
            'hour_of_day', HOUR(t.TRANSACTION_DATE),
            'customer_risk_tier', c.RISK_TIER,
            'customer_avg_income', c.ANNUAL_INCOME,
            'merchant_category', m.CATEGORY,
            'merchant_risk', m.RISK_LEVEL
        )::VARCHAR
        FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS t
        LEFT JOIN FRAUD_INVESTIGATION_DB.RAW.CUSTOMERS c ON t.CUSTOMER_ID = c.CUSTOMER_ID
        LEFT JOIN FRAUD_INVESTIGATION_DB.RAW.MERCHANTS m ON t.MERCHANT_ID = m.MERCHANT_ID
        WHERE t.TRANSACTION_ID = P_TRANSACTION_ID
    )
)
$$;

CREATE OR REPLACE FUNCTION AI.RECOMMEND_ESCALATION(P_CASE_ID VARCHAR)
RETURNS VARCHAR
AS
$$
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.3-70b',
    'You are a fraud investigation supervisor. Determine:
1. Should this case be escalated? (YES/NO)
2. Escalation priority (P1-IMMEDIATE, P2-URGENT, P3-STANDARD)
3. Recommended target (Senior Analyst, Fraud Manager, Legal Team, Law Enforcement)
4. Key reasons for decision
5. Suggested timeline for resolution

Case data: ' || (
        SELECT OBJECT_CONSTRUCT(
            'case_id', fc.CASE_ID,
            'status', fc.CASE_STATUS,
            'current_priority', fc.PRIORITY,
            'fraud_type', fc.FRAUD_TYPE,
            'estimated_loss', fc.ESTIMATED_LOSS,
            'risk_score', fc.RISK_SCORE,
            'days_open', DATEDIFF('day', fc.OPENED_AT, CURRENT_TIMESTAMP()),
            'note_count', (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.INVESTIGATION_NOTES n WHERE n.CASE_ID = fc.CASE_ID),
            'customer_risk_tier', (SELECT RISK_TIER FROM FRAUD_INVESTIGATION_DB.RAW.CUSTOMERS c WHERE c.CUSTOMER_ID = fc.CUSTOMER_ID),
            'related_alerts', (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS a WHERE a.CUSTOMER_ID = fc.CUSTOMER_ID)
        )::VARCHAR
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES fc
        WHERE fc.CASE_ID = P_CASE_ID
    )
)
$$;

CREATE OR REPLACE PROCEDURE AI.OPEN_INVESTIGATION(
    P_ALERT_ID VARCHAR, P_ASSIGNED_TO VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_case_id VARCHAR;
    v_customer_id VARCHAR;
    v_txn_id VARCHAR;
    v_alert_type VARCHAR;
    v_amount NUMBER(12,2);
    v_score NUMBER(5,2);
BEGIN
    SELECT CUSTOMER_ID, TRANSACTION_ID, ALERT_TYPE, SCORE
    INTO :v_customer_id, :v_txn_id, :v_alert_type, :v_score
    FROM FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS WHERE ALERT_ID = :P_ALERT_ID;

    SELECT AMOUNT INTO :v_amount
    FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS WHERE TRANSACTION_ID = :v_txn_id;

    LET v_case_id := 'CASE-' || TO_VARCHAR(UNIFORM(100000, 999999, RANDOM()));

    INSERT INTO FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES
    (CASE_ID, CUSTOMER_ID, TRANSACTION_ID, ALERT_ID, CASE_STATUS, PRIORITY, ASSIGNED_TO,
     FRAUD_TYPE, ESTIMATED_LOSS, RISK_SCORE, AI_CONFIDENCE_SCORE, AI_RECOMMENDATION,
     OPENED_AT, CREATED_AT, UPDATED_AT)
    VALUES (
        :v_case_id, :v_customer_id, :v_txn_id, :P_ALERT_ID, 'OPEN',
        CASE WHEN :v_score >= 80 THEN 'P1' WHEN :v_score >= 60 THEN 'P2' ELSE 'P3' END,
        :P_ASSIGNED_TO, :v_alert_type, :v_amount, :v_score, NULL, NULL,
        CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()
    );

    UPDATE FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS SET STATUS = 'ESCALATED' WHERE ALERT_ID = :P_ALERT_ID;

    RETURN 'Investigation ' || :v_case_id || ' opened for alert ' || :P_ALERT_ID;
END
$$;

-- ============================================================================
-- 9. VERIFICATION
-- ============================================================================

SELECT 'CUSTOMERS' AS TBL, COUNT(*) AS CNT FROM RAW.CUSTOMERS
UNION ALL SELECT 'MERCHANTS', COUNT(*) FROM RAW.MERCHANTS
UNION ALL SELECT 'DEVICES', COUNT(*) FROM RAW.DEVICES
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM RAW.TRANSACTIONS
UNION ALL SELECT 'ALERTS', COUNT(*) FROM ANALYTICS.ALERTS
UNION ALL SELECT 'FRAUD_CASES', COUNT(*) FROM ANALYTICS.FRAUD_CASES
UNION ALL SELECT 'INVESTIGATION_NOTES', COUNT(*) FROM ANALYTICS.INVESTIGATION_NOTES
ORDER BY TBL;

SELECT COALESCE(FRAUD_TYPE, 'LEGITIMATE') AS TYPE, COUNT(*) AS CNT,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PCT
FROM RAW.TRANSACTIONS GROUP BY ALL ORDER BY CNT DESC;

-- ============================================================================
-- DONE! Next steps:
--   1. Create the Semantic View and Cortex Agent via CoCo or Snowsight UI
--   2. Deploy the Streamlit dashboard from the fraud-investigation-dashboard/ folder
--   3. Test AI functions:
--      SELECT AI.CLASSIFY_TRANSACTION_RISK('TXN-F1-00001');
--      SELECT AI.GENERATE_CASE_SUMMARY('CASE-000001');
--      SELECT AI.ANALYZE_TRANSACTION_PATTERN('CUST-000001');
-- ============================================================================
