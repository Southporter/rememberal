from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from sqlalchemy.sql.schema import ForeignKey, Table
from .connection import Base

intermediary = Table(
    "contest_contestants",
    Base.metadata,
    Column("contest_id", ForeignKey("contest.id"), primary_key=True),
    Column("contestant_id", ForeignKey("contestant.id"), primary_key=True),
)

class Contest(Base):
    __tablename__ = 'contest'

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    selected = Column("selected", ForeignKey("contest.id"))

    contestants = relationship("Contestant", secondary=intermediary)


class Contestant(Base):
    __tablename__ = 'contestant'

    id = Column(Integer(), primary_key=True, index=True)
    name = Column(String, index=True)
    img = Column(String)
    color = Column(String)
