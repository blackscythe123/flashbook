"""Simple TF-IDF based recommendation utilities."""

from __future__ import annotations

from typing import Dict, List, Tuple

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

try:
    from .data import BOOKS
except ImportError:
    from data import BOOKS


def build_similarity_matrix(
    max_features: int = 50,
    ngram_range: Tuple[int, int] = (1, 1),
):
    """Build and return pairwise cosine similarity matrix for book content."""
    texts = [book["content"] for book in BOOKS]
    vectorizer = TfidfVectorizer(max_features=max_features, ngram_range=ngram_range)
    tfidf_matrix = vectorizer.fit_transform(texts)
    return cosine_similarity(tfidf_matrix)


def average_cosine_similarity(
    max_features: int = 50,
    ngram_range: Tuple[int, int] = (1, 1),
) -> float:
    """Return average pairwise cosine similarity used as a simple objective metric."""
    similarity_matrix = build_similarity_matrix(
        max_features=max_features,
        ngram_range=ngram_range,
    )
    return float(similarity_matrix.mean())


def get_recommendations(book_index: int, top_k: int = 3) -> List[Dict[str, object]]:
    """Return top-k similar books for a given dataset index."""
    if not 0 <= book_index < len(BOOKS):
        raise IndexError(f"book_index must be between 0 and {len(BOOKS) - 1}")

    similarity_matrix = build_similarity_matrix()
    scores = list(enumerate(similarity_matrix[book_index]))
    scores = sorted(scores, key=lambda item: item[1], reverse=True)

    recommendations: List[Dict[str, object]] = []
    for idx, score in scores:
        if idx == book_index:
            continue
        recommendations.append(
            {
                "index": idx,
                "title": BOOKS[idx]["title"],
                "score": float(score),
            }
        )
        if len(recommendations) >= top_k:
            break

    return recommendations


if __name__ == "__main__":
    print(get_recommendations(book_index=0, top_k=3))
