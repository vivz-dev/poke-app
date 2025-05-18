from pydantic import BaseModel

class PokemonBase(BaseModel):
    nombre: str
    imagen: str
    tipos: list[str]
    habilidades: list[str]
    estadisticas: dict