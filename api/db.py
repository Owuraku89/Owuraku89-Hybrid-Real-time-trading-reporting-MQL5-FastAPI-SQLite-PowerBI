import os 
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime
from datetime import datetime


# database url for sqlite
sqlalchemy_url = "sqlite:///./EAtrades.db"

# create database engine
engine = create_engine(
    sqlalchemy_url,
    connect_args = {"check_same_thread": False}
)
# instantiate parent class for model creation
Base = declarative_base()

class DBTrade(Base):
    __tablename__ = "trades"

    # primary key
    position_id = Column(Integer, primary_key=True, index=True)

    ticket = Column(Integer, default=0, index=True)
    symbol = Column(String, index=True)
    order_type = Column(String, index=True)
    volume = Column(Float)
    entry_price = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow().replace(microsecond=0))
    status = Column(String)

    # non mandatory fields
    exit_price = Column(Float, nullable=True)
    profit = Column(Float, nullable=True)
    exit_time = Column(DateTime, nullable=True)

    def __repr__(self):
        return f"Trade(position_id={self.position_id}, ticket='{self.ticket}', symbol ='{self.symbol}', type='{self.order_type}')"

# Drop table
# Base.metadata.drop_all(bind=engine)

# creates databse talbes if they don't exsits
Base.metadata.create_all(bind=engine)
                         
print(f"Database created and table name 'trades' created at: {sqlalchemy_url}")

# session management
Session = sessionmaker(bind=engine, autoflush=False, autocommit=False)
def get_db():
    """
    Provides a database session to route function(API) and ensures it stays closed
    """
    db = Session()
    try:
       yield db
    finally:
        db.close()
    