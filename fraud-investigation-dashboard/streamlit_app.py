import json
import os
import streamlit as st

st.set_page_config(page_title="Fraud Investigation Dashboard", page_icon=":shield:", layout="wide")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data(ttl=300)
def get_case_summary():
    return conn.query("""
        SELECT CASE_STATUS, COUNT(*) AS CASE_COUNT, 
               SUM(ESTIMATED_LOSS) AS TOTAL_EXPOSURE,
               AVG(RISK_SCORE) AS AVG_RISK
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES
        GROUP BY CASE_STATUS ORDER BY CASE_COUNT DESC
    """)


@st.cache_data(ttl=300)
def get_fraud_by_type():
    return conn.query("""
        SELECT FRAUD_TYPE, COUNT(*) AS TXN_COUNT, 
               SUM(AMOUNT) AS TOTAL_AMOUNT, AVG(AMOUNT) AS AVG_AMOUNT
        FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS
        WHERE IS_FRAUD = TRUE
        GROUP BY FRAUD_TYPE ORDER BY TXN_COUNT DESC
    """)


@st.cache_data(ttl=300)
def get_kpis():
    return conn.query("""
        SELECT
            (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED')) AS ACTIVE_CASES,
            (SELECT SUM(ESTIMATED_LOSS) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED')) AS TOTAL_EXPOSURE,
            (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS WHERE STATUS = 'NEW') AS PENDING_ALERTS,
            (SELECT ROUND(SUM(CASE WHEN IS_FRAUD THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS) AS FRAUD_RATE,
            (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE PRIORITY = 'P1' AND CASE_STATUS NOT LIKE 'CLOSED%') AS CRITICAL_CASES,
            (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS) AS TOTAL_TXNS
    """)


@st.cache_data(ttl=300)
def get_daily_trend():
    return conn.query("""
        SELECT DATE_TRUNC('day', TRANSACTION_DATE)::DATE AS TXN_DATE,
               COUNT(*) AS TOTAL_TXNS,
               SUM(CASE WHEN IS_FRAUD THEN 1 ELSE 0 END) AS FRAUD_TXNS,
               SUM(CASE WHEN IS_FRAUD THEN AMOUNT ELSE 0 END) AS FRAUD_AMOUNT
        FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS
        GROUP BY TXN_DATE ORDER BY TXN_DATE
    """)


@st.cache_data(ttl=300)
def get_analyst_workload():
    return conn.query("""
        SELECT ASSIGNED_TO, 
               COUNT(*) AS TOTAL_CASES,
               SUM(CASE WHEN CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED') THEN 1 ELSE 0 END) AS ACTIVE_CASES,
               SUM(ESTIMATED_LOSS) AS TOTAL_EXPOSURE,
               AVG(RISK_SCORE) AS AVG_RISK
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES
        GROUP BY ASSIGNED_TO ORDER BY ACTIVE_CASES DESC
    """)


@st.cache_data(ttl=300)
def get_recent_alerts():
    return conn.query("""
        SELECT a.ALERT_ID, a.CUSTOMER_ID, a.ALERT_TYPE, a.SEVERITY, 
               a.SCORE, a.STATUS, a.CREATED_AT,
               t.AMOUNT, t.CHANNEL
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS a
        JOIN FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS t ON a.TRANSACTION_ID = t.TRANSACTION_ID
        ORDER BY a.CREATED_AT DESC
        LIMIT 50
    """)


@st.cache_data(ttl=300)
def get_cases_list(status_filter, priority_filter):
    query = """
        SELECT fc.CASE_ID, fc.CUSTOMER_ID, fc.CASE_STATUS, fc.PRIORITY,
               fc.FRAUD_TYPE, fc.ESTIMATED_LOSS, fc.RISK_SCORE,
               fc.ASSIGNED_TO, fc.OPENED_AT, fc.AI_RECOMMENDATION
        FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES fc
        WHERE 1=1
    """
    if status_filter and "All" not in status_filter:
        status_list = ",".join([f"'{s}'" for s in status_filter])
        query += f" AND fc.CASE_STATUS IN ({status_list})"
    if priority_filter and "All" not in priority_filter:
        pri_list = ",".join([f"'{p}'" for p in priority_filter])
        query += f" AND fc.PRIORITY IN ({pri_list})"
    query += " ORDER BY fc.OPENED_AT DESC LIMIT 100"
    return conn.query(query)


def clear_all_caches():
    get_case_summary.clear()
    get_fraud_by_type.clear()
    get_kpis.clear()
    get_daily_trend.clear()
    get_analyst_workload.clear()
    get_recent_alerts.clear()
    get_cases_list.clear()


# Header
st.title(":shield: Fraud Investigation Dashboard")
st.caption("AI-Powered Financial Fraud Detection & Investigation")

st.button(":arrows_counterclockwise: Refresh Data", on_click=clear_all_caches)

# KPIs
kpis = get_kpis()
if not kpis.empty:
    row = kpis.iloc[0]
    with st.container(horizontal=True):
        st.metric("Active Cases", f"{int(row['ACTIVE_CASES']):,}", border=True)
        st.metric("Total Exposure", f"${row['TOTAL_EXPOSURE']:,.0f}", border=True)
        st.metric("Pending Alerts", f"{int(row['PENDING_ALERTS']):,}", border=True)
        st.metric("Fraud Rate", f"{row['FRAUD_RATE']:.2f}%", border=True)
        st.metric("Critical (P1)", f"{int(row['CRITICAL_CASES']):,}", border=True)
        st.metric("Total Transactions", f"{int(row['TOTAL_TXNS']):,}", border=True)

# Tabs
tab1, tab2, tab3, tab4, tab5 = st.tabs(["Cases", "Fraud Analysis", "Alerts", "Team", "AI Chat"])

with tab1:
    st.subheader("Fraud Cases")
    col_f1, col_f2 = st.columns(2)
    with col_f1:
        status_filter = st.multiselect(
            "Status", ["All", "OPEN", "IN_PROGRESS", "ESCALATED", "CLOSED_FRAUD", "CLOSED_LEGITIMATE"],
            default=["All"]
        )
    with col_f2:
        priority_filter = st.multiselect("Priority", ["All", "P1", "P2", "P3"], default=["All"])

    cases = get_cases_list(tuple(status_filter), tuple(priority_filter))
    if not cases.empty:
        st.dataframe(
            cases,
            use_container_width=True,
            hide_index=True,
            column_config={
                "ESTIMATED_LOSS": st.column_config.NumberColumn("Est. Loss", format="$%.2f"),
                "RISK_SCORE": st.column_config.ProgressColumn("Risk", min_value=0, max_value=100),
                "OPENED_AT": st.column_config.DatetimeColumn("Opened", format="YYYY-MM-DD HH:mm"),
            },
        )

    st.subheader("Cases by Status")
    case_summary = get_case_summary()
    if not case_summary.empty:
        col1, col2 = st.columns(2)
        with col1:
            with st.container(border=True):
                st.bar_chart(case_summary, x="CASE_STATUS", y="CASE_COUNT", horizontal=True)
        with col2:
            with st.container(border=True):
                st.bar_chart(case_summary, x="CASE_STATUS", y="TOTAL_EXPOSURE", horizontal=True, color="#ff6b6b")

with tab2:
    st.subheader("Fraud Pattern Analysis")
    fraud_types = get_fraud_by_type()
    if not fraud_types.empty:
        col1, col2 = st.columns(2)
        with col1:
            with st.container(border=True):
                st.markdown("**Fraud by Type (Count)**")
                st.bar_chart(fraud_types, x="FRAUD_TYPE", y="TXN_COUNT")
        with col2:
            with st.container(border=True):
                st.markdown("**Fraud by Type (Amount)**")
                st.bar_chart(fraud_types, x="FRAUD_TYPE", y="TOTAL_AMOUNT", color="#ff6b6b")

    st.subheader("Daily Fraud Trend")
    trend = get_daily_trend()
    if not trend.empty:
        with st.container(border=True):
            st.line_chart(trend, x="TXN_DATE", y=["FRAUD_TXNS", "FRAUD_AMOUNT"])

with tab3:
    st.subheader("Recent Alerts")
    alerts = get_recent_alerts()
    if not alerts.empty:
        severity_counts = alerts["SEVERITY"].value_counts()
        with st.container(horizontal=True):
            for sev in ["CRITICAL", "HIGH", "MEDIUM"]:
                cnt = severity_counts.get(sev, 0)
                st.metric(f"{sev}", cnt, border=True)

        st.dataframe(
            alerts,
            use_container_width=True,
            hide_index=True,
            column_config={
                "AMOUNT": st.column_config.NumberColumn("Amount", format="$%.2f"),
                "SCORE": st.column_config.ProgressColumn("Score", min_value=0, max_value=100),
                "CREATED_AT": st.column_config.DatetimeColumn("Created", format="YYYY-MM-DD HH:mm"),
            },
        )

with tab4:
    st.subheader("Analyst Workload")
    workload = get_analyst_workload()
    if not workload.empty:
        st.dataframe(
            workload,
            use_container_width=True,
            hide_index=True,
            column_config={
                "TOTAL_EXPOSURE": st.column_config.NumberColumn("Exposure", format="$%.2f"),
                "AVG_RISK": st.column_config.ProgressColumn("Avg Risk", min_value=0, max_value=100),
            },
        )
        with st.container(border=True):
            st.markdown("**Active Cases by Analyst**")
            st.bar_chart(workload, x="ASSIGNED_TO", y="ACTIVE_CASES")

with tab5:
    st.subheader(":robot_face: Fraud Investigation AI Assistant")
    st.caption("Ask questions about fraud cases, transactions, patterns, and get AI-powered analysis.")

    if "chat_messages" not in st.session_state:
        st.session_state.chat_messages = []

    SUGGESTIONS = {
        "What are the top fraud types by total amount?": "What are the top fraud types by total amount?",
        "How many P1 cases are still open?": "How many P1 cases are still open?",
        "Which analyst has the most active cases?": "Which analyst has the most active cases?",
        "Summarize the current fraud situation": "Summarize the current fraud situation",
    }

    if not st.session_state.chat_messages:
        selected = st.pills("Try asking:", list(SUGGESTIONS.keys()), label_visibility="collapsed")
        if selected:
            st.session_state.chat_messages.append({"role": "user", "content": SUGGESTIONS[selected]})
            st.rerun()

    for msg in st.session_state.chat_messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])

    if prompt := st.chat_input("Ask about fraud cases, transactions, or patterns..."):
        st.session_state.chat_messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)

        with st.chat_message("assistant"):
            with st.spinner("Analyzing..."):
                context = conn.query("""
                    SELECT OBJECT_CONSTRUCT(
                        'active_cases', (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED')),
                        'total_exposure', (SELECT SUM(ESTIMATED_LOSS) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED')),
                        'fraud_rate', (SELECT ROUND(SUM(CASE WHEN IS_FRAUD THEN 1 ELSE 0 END)*100.0/COUNT(*),2) FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS),
                        'top_fraud_types', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('type', FRAUD_TYPE, 'count', CNT, 'amount', AMT)) FROM (SELECT FRAUD_TYPE, COUNT(*) CNT, SUM(AMOUNT) AMT FROM FRAUD_INVESTIGATION_DB.RAW.TRANSACTIONS WHERE IS_FRAUD=TRUE GROUP BY FRAUD_TYPE ORDER BY CNT DESC)),
                        'cases_by_status', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('status', CASE_STATUS, 'count', CNT)) FROM (SELECT CASE_STATUS, COUNT(*) CNT FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES GROUP BY CASE_STATUS)),
                        'analyst_workload', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('analyst', ASSIGNED_TO, 'active', ACT)) FROM (SELECT ASSIGNED_TO, SUM(CASE WHEN CASE_STATUS IN ('OPEN','IN_PROGRESS','ESCALATED') THEN 1 ELSE 0 END) ACT FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES GROUP BY ASSIGNED_TO)),
                        'critical_cases', (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.FRAUD_CASES WHERE PRIORITY='P1' AND CASE_STATUS NOT LIKE 'CLOSED%'),
                        'pending_alerts', (SELECT COUNT(*) FROM FRAUD_INVESTIGATION_DB.ANALYTICS.ALERTS WHERE STATUS='NEW')
                    )::VARCHAR AS CTX
                """)
                ctx_str = context.iloc[0]["CTX"] if not context.empty else "{}"

                system_prompt = (
                    "You are a senior financial fraud investigation AI assistant. "
                    "You have access to real-time fraud investigation data. Use it to answer questions accurately. "
                    "Format currency as dollars. Use markdown tables for structured data. Be concise and actionable.\n\n"
                    f"Current fraud investigation data:\n{ctx_str}"
                )

                messages = [{"role": "system", "content": system_prompt}]
                for m in st.session_state.chat_messages[-10:]:
                    messages.append({"role": m["role"], "content": m["content"]})

                session = conn.session()
                messages_json = json.dumps(messages)
                result_df = session.sql(
                    "SELECT SNOWFLAKE.CORTEX.COMPLETE(?, PARSE_JSON(?), PARSE_JSON('{}')) AS RESPONSE",
                    params=["llama3.3-70b", messages_json],
                ).collect()
                raw = result_df[0]["RESPONSE"] if result_df else "{}"
                parsed = json.loads(raw)
                response = parsed.get("choices", [{}])[0].get("messages", "I couldn't generate a response.")
                st.markdown(response)

        st.session_state.chat_messages.append({"role": "assistant", "content": response})
