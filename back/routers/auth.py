from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from database import get_db
from models.user import User
from schemas.user import UserRegister, UserResponse  # Define un esquema de respuesta sin la contraseña
from utils.auth import hash_password
import docs.responses as responses

router = APIRouter()

@router.post(
        "/register",
        response_model=UserResponse,
        summary="Registrar un nuevo usuario",
        responses= responses.auth
        )
def register_user(
    user: UserRegister,
    db: Session = Depends(get_db)
    ):
    try: 
        # Verificar si el email o username ya existen
        existing_user = db.query(User).filter(
            (User.email == user.email) | (User.username == user.username)
        ).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Usuario o email ya registrado"
            )

        hashed_pw = hash_password(user.password)
        new_user = new_user = User(
            username=user.username,
            email=user.email,
            hashed_password=hashed_pw
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return new_user
    
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Conflicto al registrar el usuario: {str(e)}"
        )
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error interno en la base de datos: {str(e)}"
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error inesperado al registrar el usuario: {str(e)}"
        )
