# Hybrid-Real-time-trading-reporting-MQL5-FastAPI-SQLite-PowerBI
Developed a full-stack, low-latency data pipeline to capture execution data from a MetaTrader 5 Expert Advisor (MQL5) and present real-time performance analytics in a customizable Power BI dashboard. The solution enforces data integrity by using an API (FastAPI) to validate, clean, and store trade data in a centralized database.

## 📖 Introduction
This project integrates **MetaTrader 5 (MQL5 Expert Advisor)** with a **FastAPI service** and a **SQLite3 database**, enabling real‑time trade logging and reporting. Data is visualized in **Power BI**, creating a hybrid workflow for trading telemetry and analytics.

**Key Components**
- API: FastAPI (Python 3.13)
- Database: SQLite3 (`trades` table)
- Writer: MT5 EA (MQL5)
- Include files: `common_utils.mqh`
- Reader: Power BI via ODBC (Christian Werner SQLite driver recommended)

---

## 🏗 Architecture
```text
MT5 EA (MQL5) → FastAPI (Python 3.13) → SQLite3 (trades table) → Power BI (ODBC)
```
## Database Schema 
	Table: trades
	
CREATE TABLE trades (
    	position_id INTEGER,
    	ticket INTEGER,
    	symbol TEXT,
    	order_type TEXT,
    	volume REAL,
    	entry_price REAL,
    	timestamp TEXT,
    	exit_price REAL,
    	exit_time TEXT,
    	profit REAL,
    	status TEXT
);

## EA integration (MQL5)
	Include file: common_utils.mqh defines SendTradeReport(), dateTimeISOToString()

	Payload format: JSON with ISO‑8601 timestamps.

	Headers: Content-Type: application/json\r\nAccept: application/json\r\n.

	Critical fix: Use StringLen(payload) instead of ArraySize(data) to avoid null terminator (\u0000) errors.

	Trade events: OnTrade() captures DEAL_ENTRY_IN and DEAL_ENTRY_OUT, sending OPEN and CLOSED reports.

Note: Prior to calling trade histry use HistorySelect() or HistorySelectPositionID() and specify time range

## API (FastAPI)
    Endpoint: /trades/report/

    Endpoint(for jupyter notebook automation): /trades/bulk_imports/ 

    Validation: Pydantic model enforces schema (ISO‑8601 timestamps required).

    Error handling: Returns 422 if payload invalid.

    Logging: Store incoming trades in SQLite.


## Power BI Integration
	a. Driver: Christian Werner SQLite ODBC driver.

	b. Connection: ODBC DSN or DSN‑less string.
	
	c. Mode: Import mode recommended (snapshot, avoids DB locks).

	d. Refresh: Manual or scheduled (30–60 min).

	e. Concurrency: Enable WAL mode in SQLite:

	f. PRAGMA journal_mode=WAL;

	g. Trasnformations: Use DAX for calculated columns (recommended)


## Funture enhancements 
	a. more tables to be added

	b. Migrate to postreSQL or SQL Server

	c. Automate pipeline via A.I tokens 

	d. Expand reporting with KPI, risk metrics etc



Below is a video evidence of how the system worked in real time

https://1drv.ms/v/c/8735f78c849049dd/IQBhJfcAPZkWS6cN6z0HZ63OASCMuupC7a0Q73nimM0OEl8
