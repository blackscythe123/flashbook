"""Run MLflow experiments for Flashbook recommendation settings."""

from __future__ import annotations

from pathlib import Path

import mlflow

try:
    from .recommendation import average_cosine_similarity
except ImportError:
    from recommendation import average_cosine_similarity


def run_experiments() -> None:
    """Run a small parameter grid and log runs to MLflow."""
    tracking_uri = (Path(__file__).resolve().parents[1] / "mlruns").as_uri()
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("flashbook-recommendation")

    max_features_options = [20, 50, 100]
    ngram_options = [(1, 1), (1, 2)]

    for max_features in max_features_options:
        for ngram_range in ngram_options:
            with mlflow.start_run():
                avg_similarity = average_cosine_similarity(
                    max_features=max_features,
                    ngram_range=ngram_range,
                )

                mlflow.log_param("max_features", max_features)
                mlflow.log_param("ngram_range", str(ngram_range))
                mlflow.log_metric("average_cosine_similarity", avg_similarity)

                print(
                    f"Run complete | max_features={max_features}, "
                    f"ngram_range={ngram_range}, score={avg_similarity:.4f}"
                )


if __name__ == "__main__":
    run_experiments()
