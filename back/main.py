from fastapi import FastAPI, Query, HTTPException, Path
import httpx
import math

app = FastAPI()

@app.get(
    "/getPokemonsByRegion/{region}",
    summary="Obtener Pokémon según región",
    responses={
        200: {
            "description": "Lista de Pokémon de la región",
            "content": {
                "application/json": {
                    "example": {
                        "region": "kanto",
                        "pokemones": [
                            {
                                "nombre": "Bulbasaur",
                                "imagen": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png",
                                "tipos": ["grass", "poison"],
                                "habilidades": ["overgrow", "chlorophyll"],
                                "estadisticas": {
                                    "hp": 45,
                                    "attack": 49,
                                    "defense": 49,
                                    "special-attack": 65,
                                    "special-defense": 65,
                                    "speed": 45
                                }
                            }
                        ]
                    }
                }
            }
        },
        400: {
            "description": "Región inválida",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "La región 'xyz' no es válida. Usa: kanto, johto, hoenn, sinnoh, unova, kalos, alola, galar, paldea"
                    }
                }
            }
        },
        404: {
            "description": "Región no encontrada en la API",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "No se encontró información para la región proporcionada"
                    }
                }
            }
        },
        502: {
            "description": "Error de datos inválidos desde la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "La API de PokeAPI no devolvió datos válidos"
                    }
                }
            }
        },
        503: {
            "description": "Falla de red al conectar con la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Falla de red con la API externa"
                    }
                }
            }
        },
        500: {
            "description": "Error interno inesperado",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error interno inesperado: KeyError: 'sprites'"
                        }
                    }
                }
            }
        }
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

    async def obtener_detalles_pokemon(nombre):
        res = await client.get(f"{base_url}/pokemon/{nombre}")
        res.raise_for_status()
        data = res.json()
        return {
            "id": int(data["id"]),
            "nombre": data["name"].capitalize(),
            "imagen": data["sprites"]["front_default"],
            "tipos": [t["type"]["name"] for t in data["types"]],
            "habilidades": [a["ability"]["name"] for a in data["abilities"]],
            "estadisticas": {
                stat["stat"]["name"]: stat["base_stat"] for stat in data["stats"]
            }
        }

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
                    info = await obtener_detalles_pokemon(nombre)
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


@app.get(
        "/getAllPokemons",
        summary="Obtener listado de Pokemones",
        responses={
        200: {
            "description": "Lista paginada de Pokemones obtenida exitosamente",
            "content": {
                "application/json": {
                    "example": {
                        "total": 1302,
                        "total_pages": 66,
                        "pagina_actual": 2,
                        "pagina_siguiente": 3,
                        "offset_siguiente": 40,
                        "existe_siguiente": True,
                        "existe_anterior": True,
                        "pokemones": [
                            {
                                "id": 21,
                                "nombre": "Spearow",
                                "imagen": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/21.png"
                            }
                        ]
                    }
                }
            }
        },
        400: {
            "description": "Parámetro inválido",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "El parámetro 'offset' debe ser mayor o igual a 0"
                    }
                }
            }
        },
        401: {
            "description": "No autenticado",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Token de autenticación faltante"
                    }
                }
            }
        },
        404: {
            "description": "Página sin resultados",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "No se encontraron Pokemones para este offset"
                    }
                }
            }
        },
        502: {
            "description": "Bad Gateway",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "La API de PokeAPI no devolvió datos válidos"
                    }
                }
            }
        },
        503: {
            "description": "Falla de red al conectarse con la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error de red al intentar conectar con PokeAPI"
                    }
                }
            }
        },
        500: {
            "description": "Error interno del servidor",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error interno del servidor."
                        }
                    }
                }
            }
        }
        )
async def obtener_pokemones(
    offset: int = Query(0, description="Desplazamiento para paginación")
    ):
    """
    Consulta pokemones desde la API pública de PokeAPI.

    Este endpoint permite obtener un listado de pokemones con soporte para paginación
    utilizando los parámetros `limit` y `offset`.

    - **limit**: Número máximo de pokemones a retornar por petición (por defecto: 20)
    - **offset**: Número de elementos a omitir desde el inicio de la lista (por defecto: 0)

    Devuelve un JSON con los siguientes campos:
    - `count`: número total de pokemones disponibles en la API
    - `next`: URL para la siguiente página de resultados (si existe)
    - `previous`: URL para la página anterior (si existe)
    - `results`: lista de pokemones, cada uno con nombre y URL

    #### Ejemplo de uso:
    `/getAllPokemons?limit=20&offset=20`
    """
    limit = 20 # Número máximo de pokemones a retornar por petición

    # Validar el parámetro offset
    if offset < 0:
        raise HTTPException(status_code=400, detail="El parámetro 'offset' debe ser mayor o igual a 0")
    
    url = f"https://pokeapi.co/api/v2/pokemon/?limit={limit}&offset={offset}"
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            response.raise_for_status()
            data =  response.json()

            # Validar errores en la respuesta
            if "results" not in data or "count" not in data:
                raise HTTPException(status_code=502, detail="La API de PokeAPI no devolvió datos válidos")

            if not data["results"]:
                raise HTTPException(status_code=404, detail="No se encontraron Pokemones.")

            # Transformar resultados
            pokemones_mostrar = []
            for pokemon in data["results"]:
                id_pokemon = pokemon["url"].split("/")[-2]  # obtener el ID desde la URL
                pokemones_mostrar.append({
                    "id": int(id_pokemon),
                    "nombre": pokemon["name"].capitalize(),
                    "imagen": f"https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/{id_pokemon}.png"
                })

            # Calcular la cantidad total de paginas
            total_pages = math.ceil(data["count"] / limit)

            return {
                "total": data["count"],
                "total_pages": total_pages,
                "pagina_actual": offset // limit + 1,
                "pagina_siguiente": (offset // limit + 2) if data["next"] else None,
                "offset_siguiente": (offset + limit) if data["next"] else None,
                "existe_siguiente": data["next"] is not None,
                "existe_anterior": data["previous"] is not None,
                "pokemones": pokemones_mostrar
            }
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=f"Error al conectar con PokeAPI: {e}")
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Error de red al intentar conectar con PokeAPI: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")
    
@app.get(
        "/getPokemon/{id}",
        summary="Obtener detalles de un Pokémon por nombre o ID",
        responses={
        200: {
            "description": "Detalles del Pokémon obtenidos correctamente",
            "content": {
                "application/json": {
                    "example": {
                        "nombre": "Clefairy",
                        "imagen": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/35.png",
                        "tipos": ["fairy"],
                        "habilidades": ["cute-charm", "magic-guard", "friend-guard"],
                        "estadisticas": {
                            "hp": 70,
                            "attack": 45,
                            "defense": 48,
                            "special-attack": 60,
                            "special-defense": 65,
                            "speed": 35
                        },
                        "evoluciones": ["Cleffa", "Clefairy", "Clefable"]
                    }
                }
            }
        },
        400: {
            "description": "Parámetro inválido",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "El parámetro proporcionado no es válido"
                    }
                }
            }
        },
        404: {
            "description": "Pokémon no encontrado",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Pokémon no encontrado"
                    }
                }
            }
        },
        502: {
            "description": "Falla al obtener datos de la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error al obtener datos desde la API externa"
                    }
                }
            }
        },
        500: {
            "description": "Error interno del servidor",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error interno del servidor."
                        }
                    }
                }
            }
        }
    )

async def obtener_detalles_pokemon(id: str):
    base_url = "https://pokeapi.co/api/v2"

    # Obtener información del Pokémon
    async def obtener_info_pokemon(nombre):
        res = await client.get(f"{base_url}/pokemon/{nombre}")
        res.raise_for_status()
        data = res.json()
        return {
            "nombre": data["name"].capitalize(),
            "imagen": data["sprites"]["front_default"],
            "tipos": [t["type"]["name"] for t in data["types"]],
            "habilidades": [a["ability"]["name"] for a in data["abilities"]],
            "estadisticas": {
                stat["stat"]["name"]: stat["base_stat"] for stat in data["stats"]
            }
        }

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
                    detalles = await obtener_info_pokemon(nombre)
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
@app.post(
    "/evolucionarPokemon/{id}",
    summary="Evolucionar un Pokémon al siguiente de su cadena evolutiva",
    responses={
        200: {
            "description": "Evolución realizada o mensaje si no es posible",
            "content": {
                "application/json": {
                    "example": {
                        "evolucionado": True,
                        "pokemon": {
                            "nombre": "Charmeleon",
                            "imagen": "https://pokeapi.co/media/sprites/pokemon/5.png",
                            "tipos": ["fire"],
                            "habilidades": ["blaze", "solar-power"],
                            "estadisticas": {
                                "hp": 58,
                                "attack": 64,
                                "defense": 58,
                                "special-attack": 80,
                                "special-defense": 65,
                                "speed": 80
                            }
                        }
                    }
                }
            }
        },
        404: {
            "description": "Pokémon no encontrado o sin evolución disponible",
            "content": {
                "application/json": {
                    "example": {
                        "evolucionado": False,
                        "mensaje": "Este Pokémon ya está en su forma final"
                    }
                }
            }
        },
        502: {
            "description": "Error al obtener datos desde la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error al obtener datos desde la API externa"
                    }
                }
            }
        },
        503: {
            "description": "Falla de red con la API externa",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Falla de red con la API externa"
                    }
                }
            }
        },
        500: {
            "description": "Error interno del servidor",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error inesperado: KeyError 'species'"
                    }
                }
            }
        }
    }
)
async def evolucionar_pokemon(id: str = Path(..., description="ID o nombre del Pokémon")):
    base_url = "https://pokeapi.co/api/v2"

    async def obtener_info(nombre):
        res = await client.get(f"{base_url}/pokemon/{nombre}")
        res.raise_for_status()
        data = res.json()
        return {
            "nombre": data["name"].capitalize(),
            "imagen": data["sprites"]["front_default"],
            "tipos": [t["type"]["name"] for t in data["types"]],
            "habilidades": [a["ability"]["name"] for a in data["abilities"]],
            "estadisticas": {
                stat["stat"]["name"]: stat["base_stat"] for stat in data["stats"]
            }
        }

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

            info_evolucion = await obtener_info(siguiente)
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
