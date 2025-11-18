from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from .ai import AiGateway
from .auth import get_current_user
from .schemas import User

router = APIRouter()

@router.post("/images/generate", tags=["AI"])
async def generate_image(prompt: str, user: User = Depends(get_current_user)):
    """
    Generate an image from a prompt.
    """
    ai_gateway = AiGateway()
    image_bytes = await ai_gateway.generate_image(prompt)

    if image_bytes:
        return Response(content=image_bytes, media_type="image/png")
    
    raise HTTPException(status_code=500, detail="Image generation failed.")
