from pydantic import BaseModel


class ContestantBase(BaseModel):
    name: str
    color: str
    img: str

    class Config:
        orm_mode = True

class ContestantCreate(ContestantBase):
    pass

class Contestant(ContestantBase):
    id: int 


class ContestBase(BaseModel):
    name: str

class ContestCreate(ContestBase):
    pass

class ContestUpdate(ContestBase):
    id: int
    selected: str

class Contest(ContestBase):
    id: int 
    contestants: list[Contestant] = []
    selected: int | None

    class Config:
        orm_mode = True
