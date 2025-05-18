from fastapi.openapi.models import OAuthFlows as OAuthFlowsModel, SecurityScheme as SecuritySchemeModel
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import logging

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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger = logging.getLogger("uvicorn.error")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

app.include_router(auth.router, prefix="/auth", tags=["Autenticación"])
app.include_router(pokemons.router, prefix="/pokemons", tags=["Pokémon"])
app.include_router(favs.router, prefix="/favoritos", tags=["Favoritos"])

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "Ocurrió un error inesperado en el servidor."
        }
    )