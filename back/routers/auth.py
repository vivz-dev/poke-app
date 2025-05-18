from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from database import get_db
from models.user import User
from schemas.user import UserRegister, UserResponse, UserLogin
from schemas.token import Token
from utils.auth import hash_password, verify_password, create_access_token
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
        new_user = User(
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


@router.post(
        "/login",
        response_model=Token,
        responses = responses.login
    )
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        user = db.query(User).filter(User.username == form_data.username).first()
        if not user or not verify_password(form_data.password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Credenciales inválidas")

        token = create_access_token(data={"sub": str(user.id)})
        return {"access_token": token, "token_type": "bearer"}
    except HTTPException:
        raise 
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Error inesperado en el servidor: {str(e)}")