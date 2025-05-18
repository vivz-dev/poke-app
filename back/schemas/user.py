from pydantic import BaseModel, EmailStr, Field

class UserRegister(BaseModel):
    username: str = Field(..., example="pikachu_user", description="Nombre de usuario")
    email: EmailStr = Field(..., example="pikachu@example.com", description="Correo electrónico válido")
    password: str = Field(..., example="securepassword", description="Contraseña del usuario")

class UserResponse(BaseModel):
    id: int
    username: str
    email: str

    class Config:
        orm_mode = True

class UserLogin(BaseModel):
    username: str
    password: str