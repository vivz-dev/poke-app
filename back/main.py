from fastapi import FastAPI
from fastapi.openapi.models import OAuthFlows as OAuthFlowsModel, SecurityScheme as SecuritySchemeModel
from fastapi.security import OAuth2PasswordBearer
from routers import auth, pokemons, favs
from database import Base, engine
import models.user
from models.fav_pokemon import Favorite

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="PokeAPI con JWT",
    description="Una API para manejar Pokemones",
    version="1.0.0"
)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

app.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
app.include_router(pokemons.router, prefix="/pokemons", tags=["Pokémon"])
app.include_router(favs.router, prefix="/favoritos", tags=["Favoritos"])