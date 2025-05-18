# docs/responses.py

get_by_region = {
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

get_by_id = {
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

evolucionar = {
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

auth = {
    201: {
            "description": "Usuario creado exitosamente",
            "content": {
                "application/json": {
                    "example": {
                        "id": 1,
                        "username": "usuario123"
                    }
                }
            }
        },
        400: {
            "description": "Usuario ya registrado",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Usuario ya registrado"
                    }
                }
            }
        },
        409: {
            "description": "Conflicto de integridad (duplicado)",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Conflicto al registrar el usuario (duplicado u otro error de integridad)"
                    }
                }
            }
        },
        500: {
            "description": "Error interno del servidor",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Error inesperado al registrar el usuario"
                    }
                }
            }
        }
}

login = {
        200: {
            "description": "Inicio de sesión exitoso",
            "content": {
                "application/json": {
                    "example": {
                        "access_token": "eyJhbGciOiJIUzI1NiIsInR...",
                        "token_type": "bearer"
                    }
                }
            }
        },
        400: {
            "description": "Credenciales inválidas",
            "content": {
                "application/json": {
                    "example": {"detail": "Credenciales inválidas"}
                }
            }
        },
        500: {
            "description": "Error interno del servidor",
            "content": {
                "application/json": {
                    "example": {"detail": "Error inesperado en el servidor"}
                }
            }
        }
    }