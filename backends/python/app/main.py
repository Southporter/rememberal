from fastapi import FastAPI, Depends, HTTPException
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from starlette.responses import RedirectResponse

from .db import crud, models, schemas
from .db.connection import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()



@app.get('/api/contests', response_model=list[schemas.Contest])
def get_contests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    contests = crud.get_contests(skip=skip, limit=limit, db=db)
    return contests

@app.post('/api/contest', response_model=schemas.Contest)
def create_contest(contest: schemas.ContestCreate, db: Session = Depends(get_db)):
    return crud.create_contest(contest=contest, db=db)


@app.post('/api/contest/{contest_id}', response_model=schemas.Contest)
def update_contest(contest: schemas.ContestUpdate, db: Session = Depends(get_db)):
    return crud.update_contest(contest=contest, db=db)

@app.delete('/api/contest/{contest_id}')
def delete_contest(contest_id: str, db: Session = Depends(get_db)):
    return crud.delete_contest(contest_id=contest_id, db=db)

@app.post('/api/contest/{contest_id}/contestants/{contestant_id}', response_model=schemas.Contest)
def add_contestant(contest_id: str, contestant_id: str, db: Session = Depends(get_db)):
    update = crud.add_contestant(contest_id=contest_id, contestant_id=contestant_id, db=db)
    print(update)
    if update is None:
        raise HTTPException(status_code=404, detail='Contest or contestant doesn\'t exist')
    return update

@app.get('/api/contestants', response_model=list[schemas.Contestant])
def get_contestants(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_contestants(db=db, skip=skip, limit=limit)

@app.post('/api/contestant', response_model=schemas.Contestant)
def create_contestant(contestant: schemas.ContestantCreate, db: Session = Depends(get_db)):
    return crud.create_contestant(contestant=contestant, db=db)


@app.get('/api/contestant/{contestant_id}', response_model=schemas.Contestant)
def get_contestant(contestant_id: str, db: Session = Depends(get_db)):
    return crud.get_contestant(contestant_id=contestant_id, db=db)

@app.get('/')
def index():
    return RedirectResponse("/index.html")

app.mount("/", StaticFiles(directory="public"), name="frontend")


