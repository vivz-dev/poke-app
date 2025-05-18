from pydantic import BaseModel

class PokemonBase(BaseModel):
    id: int
    nombre: str
    imagen: str
    tipos: list[str]
    habilidades: list[str]
    estadisticas: dict