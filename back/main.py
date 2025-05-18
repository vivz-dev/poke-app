from fastapi import FastAPI
from routers import auth, pokemons, favs

app = FastAPI()

app.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
app.include_router(pokemons.router, prefix="/pokemons", tags=["Pokémon"])
app.include_router(favs.router, prefix="/favoritos", tags=["Favoritos"])