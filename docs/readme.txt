Documentation: Hybrid Trading Workflow (EA - FastAPI - SQLite - PowerBI)

1. Introduction

This project integrates MetaTrader 5 (MQL5 Expert Advisor) with a FastAPI service and a SQLite3 database, enabling real‑time trade logging and reporting. Data is visualized in Power BI, creating a hybrid workflow for trading telemetry and analytics.

Key Components:

	a. API: FastAPI (Python 3.13)

	b. Database (SQLAlchemy): SQLite3 (trades table) 

	c. Writer: MT5 EA (MQL5)

	d. Include files: common_utils.mqh (helper functions)

	e. Reader: Power BI via ODBC (Christian Werner SQLite driver recommended)

	f. Writer 2: Jupyter notebook (automatic data generation)


2. System Architecture 
	Flow:

	a. EA (MQL5) executes trades and calls SendTradeReport() from common_utils.mqh.

	b. FastAPI receives JSON payloads via POST requests.
	
	c. SQLite3 stores trade data in the trades table.

	d. Power BI connects via ODBC, imports data, and visualizes reports.

MT5 EA (MQL5) → FastAPI (Python 3.13) → SQLite3 (trades table) → Power BI (ODBC)

3. Database Schema 
	Table:trades
	
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

4. EA integration (MQL5)
	Include file: common_utils.mqh defines SendTradeReport(), dateTimeISOToString()

	Payload format: JSON with ISO‑8601 timestamps.

	Headers: Content-Type: application/json\r\nAccept: application/json\r\n.

	Critical fix: Use StringLen(payload) instead of ArraySize(data) to avoid null terminator (\u0000) errors.

	Trade events: OnTrade() captures DEAL_ENTRY_IN and DEAL_ENTRY_OUT, sending OPEN and CLOSED reports.

Note: Prior to calling trade histry use HistorySelect() or HistorySelectPositionID() and specify time range

5. API (FastAPI)
Endpoint: /trades/report/

Endpoint(for jupyter notebook automation): /trades/bulk_imports/ 

Validation: Pydantic model enforces schema (ISO‑8601 timestamps required).

Error handling: Returns 422 if payload invalid.

Logging: Store incoming trades in SQLite.


6. Power BI Integration
	a. Driver: Christian Werner SQLite ODBC driver.

	b. Connection: ODBC DSN or DSN‑less string.
	
	c. Mode: Import mode recommended (snapshot, avoids DB locks).

	d. Refresh: Manual or scheduled (30–60 min).

	e. Concurrency: Enable WAL mode in SQLite:

	f. PRAGMA journal_mode=WAL;

	g. Trasnformations: Use DAX for calculated columns (recommended)


7. Funture enhancements 
	a. more tables to be added

	b. Migrate to postreSQL or SQL Server

	c. Automate pipeline via A.I tokens 

	d. Expand reporting with KPI, risk metrics etc

