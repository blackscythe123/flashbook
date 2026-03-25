"""Recommendation API routes."""

from fastapi import APIRouter, HTTPException, Query

from ml.recommendation import get_recommendations

router = APIRouter()


@router.get("/recommend/{book_index}")
async def recommend_books(book_index: int, top_k: int = Query(default=3, ge=1, le=10)):
    """Return top similar books for the given dummy dataset index."""
    try:
        recommendations = get_recommendations(book_index=book_index, top_k=top_k)
        return {
            "book_index": book_index,
            "recommendations": [item["title"] for item in recommendations],
            "details": recommendations,
        }
    except IndexError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
