# import libraries
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from datetime import datetime
from typing import List

from db import DBTrade, Session, get_db

app = FastAPI(
    title="Hybrid EA Reporting API",
    decription="Receives trade data from MQL5 EA forto database for reporting"
)

# Pydantic Data mobel Class
class TradeData(BaseModel):
    # define required fields
    position_id: int = Field(description="Unique indentifier for every trade's lifecycle")
    symbol: str
    order_type: str = Field(decription="BUY or SELL")
    entry_price: float
    ticket: int 
    volume: float
    timestamp: datetime
    

    # define optional fields
    exit_price: float | None = None
    profit: float | None = None
    exit_time: datetime | None = None
    status: str | None = "OPEN"


@app.post("/trades/report/")
def receive_data(trade: TradeData, db: Session = Depends(get_db)):
    """
    Handles and send incomming data 
    """
    
    # VALIDATION
    # if trade.position_id not in {"BUY", "SELL"}:
    #     raise HTTPException(status_code=400, detail="invalid request")
    # check if trade already exit AND UPDATE QUERY rcorresponding query record
    trade_exist = db.query(DBTrade).filter(trade.position_id == DBTrade.position_id).first()
    if trade_exist:
        # update selected db cols only 
        if trade.status == "CLOSED" or trade.exit_price is not None:
            trade_exist.exit_price = trade.exit_price
            trade_exist.profit = trade.profit
            trade_exist.exit_time = trade.exit_time
            trade_exist.status = "CLOSED"
        try:
            db.commit()
            return {"message": f"trade position {trade.position_id} updated successfully", "Status": "CLOSED"}
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code = 500, detail= f"Error updating trade: {e}" )

    # send trade data 
    send = DBTrade(**trade.dict())
    db.add(send)
    db.commit()
    db.refresh(send)
    return {"message": f"New Trade Ticket {trade.ticket} created successfully", "Status": "OPEN"}


# create bulk request endpoint 
@app.post("/trades/bulk_imports/")
async def bulk_insert_data(trades: List[TradeData], db: Session = Depends(get_db)):

    counter = 0
    # loop through list of json records and add records
    for trade in trades:
        # check if posID already exists in database
        if db.query(DBTrade).filter(DBTrade.position_id == trade.position_id).first():
            print(f"skipping: {trade.position_id} already exits")
            continue

        send = DBTrade(
            position_id = trade.position_id,
            ticket = trade.ticket,
            symbol = trade.symbol,
            order_type = trade.order_type,
            volume = trade.volume,
            entry_price = trade.entry_price,
            timestamp = trade.timestamp,
            status = trade.status,
            exit_price = trade.exit_price if trade.status == "CLOSED" else None,
            profit = trade.profit if trade.status == "CLOSED" else None,
            exit_time = trade.exit_time if trade.status == "CLOSED" else None
            )

        db.add(send)
        counter += 1
        
    # upload to database
    db.commit()
    return {"message": f"Successfullly inserted {counter} new trades records"}
    
    
    
    