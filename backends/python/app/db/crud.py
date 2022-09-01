from sqlalchemy.orm import Session
from . import models, schemas

def get_contests(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Contest).offset(skip).limit(limit).all()

def create_contest(db: Session, contest: schemas.ContestCreate):
    db_contest = models.Contest(name=contest.name, contestants=[])
    db.add(db_contest)
    db.commit()
    db.refresh(db_contest)
    return db_contest

def delete_contest(db: Session, contest_id: str):
    contest = db.get(models.Contest, contest_id)
    db.delete(contest)
    db.commit()
    return


def update_contest(db: Session, contest: schemas.ContestUpdate):
    db_contest = db.get(models.Contest, contest.id)
    db_contest.selected = contest.selected
    db.commit()
    db.refresh(db_contest)
    return db_contest


def add_contestant(db: Session, contest_id: str, contestant_id: str):
    db_contest = db.get(models.Contest, contest_id)
    if db_contest is None:
        return None
    db_contestant = db.get(models.Contestant, contestant_id)
    if db_contestant is None:
        return None
    db_contest.contestants.append(db_contestant)
    db.commit()
    db.refresh(db_contest)
    return db_contest

def create_contestant(db: Session, contestant: schemas.ContestantCreate):
    db_contestant = models.Contestant(name=contestant.name, color=contestant.color, img=contestant.img)
    db.add(db_contestant)
    db.commit()
    db.refresh(db_contestant)
    return db_contestant

def get_contestant(db: Session, contestant_id: str):
    return db.get(models.Contestant, contestant_id)

def get_contestants(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Contestant).offset(skip).limit(limit).all()
