# poke-app
Aplicación móvil en Flutter que consuma la API pública de Pokémon (https://pokeapi.co/) y también un backend propio para gestionar los datos de usuarios y sus Pokémon favoritos.

Explicar como lanzar el codigo (en visual studio code, con virtual environment)
Mencionar que se usó la arquitectura BFF
FastAPI porque es rapido, openAI usa fast api, Azure también lo usa por detrás.
Es moderno, sencillo y la documentación con Swagger es muy sencilla de usar

Levantar un virtual environment para salvaguardar versionesß

1. main.py ✅
Solo orquesta e importa routers:

python
Copiar
Editar


# 🛠️ Configuración del entorno y ejecución del servidor
### 1. Elimina el entorno virtual anterior (si existe)
```
rm -rf .venv
```

### 2. Crea un nuevo entorno virtual
```
python3 -m venv .venv
```

### 3. Activa el entorno virtual
```
source .venv/bin/activate
```

### 4. Actualiza pip e instala dependencias
```
pip install -r requirements.txt
```

### 5. Inicia el servidor FastAPI (desde el directorio back)
```
cd back && uvicorn main:app --reload
```