from fastapi import FastAPI
from routers import auth, pokemons, favs
from database import Base, engine
import models.user

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
app.include_router(pokemons.router, prefix="/pokemons", tags=["Pokémon"])
# app.include_router(favs.router, prefix="/favoritos", tags=["Favoritos"])