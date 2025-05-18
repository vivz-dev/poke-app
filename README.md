# poke-app
Aplicación móvil en Flutter que consuma la API pública de Pokémon (https://pokeapi.co/) y también un backend propio para gestionar los datos de usuarios y sus Pokémon favoritos.

Explicar como lanzar el codigo (en visual studio code, con virtual environment)
Mencionar que se usó la arquitectura BFF
FastAPI porque es rapido, openAI usa fast api, Azure también lo usa por detrás.
Es moderno, sencillo y la documentación con Swagger es muy sencilla de usar

Levantar un virtual environment para salvaguardar versiones

requirements

pip install bcrypt

1. main.py ✅
Solo orquesta e importa routers:

python
Copiar
Editar



@router.get(
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
    
