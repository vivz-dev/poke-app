from utils.auth import get_current_user
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm import Session
from database import get_db
from schemas.pokemon import PokemonBase
from models.fav_pokemon import Favorite
from models.user import User
import logging
logger = logging.getLogger(__name__)

router = APIRouter()

@router.get(
        "/favs",
        summary="Obtener Pokémon favoritos",
        tags=["Favoritos"]
        )
def get_favoritos(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
    ):
    try:
        favoritos = db.query(Favorite).filter(Favorite.user_id == user.id).all()
        return [PokemonBase(
            id=f.id,
            nombre=f.nombre,
            imagen=f.imagen,
            tipos=f.tipos,
            habilidades=f.habilidades,
            estadisticas=f.estadisticas
        ) for f in favoritos]

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener favoritos: {str(e)}")
    except NoResultFound:
        raise HTTPException(status_code=404, detail="No se encontraron favoritos para este usuario")
    except AttributeError:
        raise HTTPException(status_code=500, detail="Error accediendo a datos del usuario")

@router.post(
        "/favs",
        summary="Agregar Pokémon a favoritos",
        tags=["Favoritos"]
        )
def add_favorito(
    pokemon: PokemonBase,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        nuevo_fav = Favorite(
            user_id=user.id,
            nombre=pokemon.nombre,
            imagen=pokemon.imagen,
            tipos=pokemon.tipos,
            habilidades=pokemon.habilidades,
            estadisticas=pokemon.estadisticas
        )

        existe = db.query(Favorite).filter_by(user_id=user.id, nombre=nuevo_fav.nombre).first()

        # Verificar si el pokemon ya está en favoritos
        if existe:
            raise HTTPException(status_code=400, detail="Este Pokémon ya está en tus favoritos")
        
        # Guardar el nuevo favorito en la base de datos
        db.add(nuevo_fav)
        db.commit()
        db.refresh(nuevo_fav)
        return {"msg": f"{pokemon.nombre} agregado a favoritos", "id": nuevo_fav.id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error al guardar favorito: {str(e)}")