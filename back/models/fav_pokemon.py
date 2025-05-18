from sqlalchemy import Column, Integer, String, ForeignKey, JSON
# from sqlalchemy.dialects.sqlite import JSON
from database import Base

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    nombre = Column(String)
    imagen = Column(String)
    tipos = Column(JSON)
    habilidades = Column(JSON)
    estadisticas = Column(JSON)