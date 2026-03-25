"""Structured dataset loader for content-based recommendation experiments."""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Dict, List


DATASET_PATH = Path(__file__).resolve().parents[1] / "data" / "books.csv"


FALLBACK_BOOKS: List[Dict[str, str]] = [
    {
        "title": "Practical Python for Data Analysis",
        "content": "python data analysis pandas data cleaning visualization statistics",
    },
    {
        "title": "Machine Learning Foundations",
        "content": "supervised learning regression classification model evaluation",
    },
    {
        "title": "Deep Learning Fundamentals",
        "content": "deep learning neural networks computer vision nlp",
    },
    {
        "title": "FastAPI Backend Development",
        "content": "fastapi python backend rest api async pydantic",
    },
    {
        "title": "Data Engineering Pipelines",
        "content": "etl airflow batch streaming warehouse analytics",
    },
    {
        "title": "Cloud Computing Essentials",
        "content": "aws cloud architecture scalability microservices deployment",
    },
    {
        "title": "System Design Interview Notes",
        "content": "load balancing caching database reliability scalability",
    },
    {
        "title": "Building Mobile Apps with Flutter",
        "content": "flutter dart widgets state management mobile ui",
    },
    {
        "title": "DevOps Automation Guide",
        "content": "ci cd docker kubernetes monitoring infrastructure as code",
    },
    {
        "title": "Generative AI in Practice",
        "content": "llm prompt engineering rag evaluation safety",
    },
]


def load_books() -> List[Dict[str, str]]:
    """Load book records from CSV; fallback to embedded examples if unavailable."""
    if not DATASET_PATH.exists():
        return FALLBACK_BOOKS

    books: List[Dict[str, str]] = []
    with DATASET_PATH.open("r", encoding="utf-8", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        for row in reader:
            title = (row.get("title") or "").strip()
            content = (row.get("description") or row.get("content") or "").strip()
            if title and content:
                books.append({"title": title, "content": content})

    return books or FALLBACK_BOOKS


BOOKS = load_books()
