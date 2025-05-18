import httpx
from schemas.pokemon import PokemonBase

BASE_URL = "https://pokeapi.co/api/v2"

async def obtener_info_pokemon(nombre: str, client: httpx.AsyncClient) -> PokemonBase:
    res = await client.get(f"{BASE_URL}/pokemon/{nombre}")
    res.raise_for_status()
    data = res.json()
    return PokemonBase(
        id=int(data["id"]),
        nombre=data["name"].capitalize(),
        imagen=data["sprites"]["front_default"],
        tipos=[t["type"]["name"] for t in data["types"]],
        habilidades=[a["ability"]["name"] for a in data["abilities"]],
        estadisticas={
            stat["stat"]["name"]: stat["base_stat"] for stat in data["stats"]
        }
    )

