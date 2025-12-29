from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
import pypdf
import io
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

class TextExtractionResponse(BaseModel):
    text: str
    page_count: int
    filename: str

@router.post("/extractText", response_model=TextExtractionResponse)
async def extract_text(file: UploadFile = File(...)):
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(status_code=400, detail="File must be a PDF")

    try:
        contents = await file.read()
        pdf_file = io.BytesIO(contents)
        reader = pypdf.PdfReader(pdf_file)
        
        text_content = []
        for page in reader.pages:
            text = page.extract_text()
            if text:
                text_content.append(text)
        
        full_text = "\n\n".join(text_content)
        
        return TextExtractionResponse(
            text=full_text,
            page_count=len(reader.pages),
            filename=file.filename
        )
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to extract text: {str(e)}")
