from fastapi import APIRouter, HTTPException, Path, Query
import httpx
import math
from models.pokemon import PokemonBase
from utils.pokemonAPI import obtener_info_pokemon
import docs.responses as responses


router = APIRouter()

@router.get(
    "/getPokemonsByRegion/{region}",
    summary="Obtener Pokémon según región",
    responses=responses.get_by_region
    )
async def get_pokemons_by_region(
    region: str = Path(..., description="Nombre de la región: kanto, johto, hoenn, sinnoh, unova, kalos, alola, galar, paldea"),
    offset: int = Query(0, ge=0, description="Número de Pokémon a omitir desde el inicio")
    ):
    limit = 20 # Número máximo de pokemones a retornar por petición
    base_url = "https://pokeapi.co/api/v2"
    regiones_validas = {"kanto", "johto", "hoenn", "sinnoh", "unova", "kalos", "alola", "galar", "paldea"}

    # Validar si es una región válida
    region = region.lower()
    if region not in regiones_validas:
        raise HTTPException(
            status_code=400,
            detail=f"La región '{region}' no es válida. Usa: {', '.join(regiones_validas)}"
        )

    try:
        async with httpx.AsyncClient() as client:
            # Obtener lista de generaciones
            res_gen = await client.get(f"{base_url}/generation/")
            res_gen.raise_for_status()
            generaciones = res_gen.json()["results"]

            # Buscar generación que tenga la región dada
            region = region.lower()
            url_generacion = None
            for gen in generaciones:
                detalle = await client.get(gen["url"])
                detalle.raise_for_status()
                gen_data = detalle.json()
                if gen_data["main_region"]["name"] == region:
                    url_generacion = gen["url"]
                    break

            if not url_generacion:
                raise HTTPException(status_code=404, detail="Región no encontrada")

            # Obtener especie de Pokémon en esa región
            gen_data = (await client.get(url_generacion)).json()
            especies = gen_data["pokemon_species"]
            total = len(especies)

            # paginacion
            especies_paginadas = especies[offset:offset + limit]
            nombres = [e["name"] for e in especies_paginadas]

            # Obtener detalles de cada Pokémon en la página actual
            pokemones = []
            for nombre in nombres:
                try:
                    info = await obtener_info_pokemon(nombre, client)
                    pokemones.append(info)
                except httpx.HTTPStatusError:
                    continue

            total_pages = math.ceil(total / limit)
            pagina_actual = offset // limit + 1
            existe_siguiente = offset + limit < total
            existe_anterior = offset > 0

            return {
                "total": total,
                "total_pages": total_pages,
                "pagina_actual": pagina_actual,
                "pagina_siguiente": pagina_actual + 1 if existe_siguiente else None,
                "offset_siguiente": offset + limit if existe_siguiente else None,
                "existe_siguiente": existe_siguiente,
                "existe_anterior": existe_anterior,
                "pokemones": pokemones
                }

    except httpx.HTTPStatusError:
        raise HTTPException(status_code=502, detail="Error al obtener datos desde la API externa")
    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Falla de red con la API externa")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno inesperado: {str(e)}")

@router.get(
        "/getPokemon/{id}",
        summary="Obtener detalles de un Pokémon por nombre o ID",
        responses=responses.get_by_id
    )
async def obtener_detalles_pokemon(id: str):
    base_url = "https://pokeapi.co/api/v2"

    try:
        async with httpx.AsyncClient() as client:
            # Obtener especie
            res_species = await client.get(f"{base_url}/pokemon-species/{id}")
            if res_species.status_code == 404:
                raise HTTPException(status_code=404, detail="Pokémon no encontrado")
            res_species.raise_for_status()
            species_data = res_species.json()

            # Obtener cadena evolutiva
            res_chain = await client.get(species_data["evolution_chain"]["url"])
            res_chain.raise_for_status()
            chain_data = res_chain.json()

            # Obtener nombres de la cadena evolutiva
            def recorrer_cadena(chain_node):
                nombres = [chain_node["species"]["name"]]
                for evolucion in chain_node["evolves_to"]:
                    nombres += recorrer_cadena(evolucion)
                return nombres

            nombres_cadena = recorrer_cadena(chain_data["chain"])

            # Obtener la información detallada de cada Pokémon
            detalles_cadena = []
            for nombre in nombres_cadena:
                try:
                    detalles = await obtener_info_pokemon(nombre, client)
                    detalles_cadena.append(detalles)
                except httpx.HTTPStatusError:
                    continue  # Si uno falla, simplemente lo omite

            return {"cadena_evolutiva": detalles_cadena}

    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail="Error al obtener datos desde la API externa")
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail="Falla de red con la API externa")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")


# Vamos a ejecutar la evolución de un Pokémon
@router.post(
    "/evolucionarPokemon/{id}",
    summary="Evolucionar un Pokémon al siguiente de su cadena evolutiva",
    responses=responses.evolucionar
)
async def evolucionar_pokemon(id: str = Path(..., description="ID o nombre del Pokémon")):
    base_url = "https://pokeapi.co/api/v2"

    try:
        async with httpx.AsyncClient() as client:
            # Obtener especie
            res_pokemon = await client.get(f"{base_url}/pokemon/{id}")
            if res_pokemon.status_code == 404:
                raise HTTPException(status_code=404, detail="Pokémon no encontrado")
            data = res_pokemon.json()
            nombre_actual = data["name"]

            res_species = await client.get(data["species"]["url"])
            res_species.raise_for_status()
            species_data = res_species.json()

            res_chain = await client.get(species_data["evolution_chain"]["url"])
            res_chain.raise_for_status()
            chain = res_chain.json()["chain"]

            # Buscar la siguiente evolución directa
            def buscar_evolucion(chain_node, objetivo):
                if chain_node["species"]["name"] == objetivo:
                    return chain_node["evolves_to"][0]["species"]["name"] if chain_node["evolves_to"] else None
                for evo in chain_node["evolves_to"]:
                    resultado = buscar_evolucion(evo, objetivo)
                    if resultado:
                        return resultado
                return None

            siguiente = buscar_evolucion(chain, nombre_actual)
            if not siguiente:
                return {
                    "evolucionado": False,
                    "mensaje": "Este Pokémon ya está en su forma final"
                }

            info_evolucion = await obtener_info_pokemon(siguiente, client)
            return {
                "evolucionado": True,
                "pokemon": info_evolucion
            }

    except httpx.HTTPStatusError:
        raise HTTPException(status_code=502, detail="Error al obtener datos desde la API externa")
    except httpx.RequestError:
        raise HTTPException(status_code=503, detail="Falla de red con la API externa")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error inesperado: {str(e)}")