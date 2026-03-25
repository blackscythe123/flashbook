"""Optuna tuning for TF-IDF recommendation hyperparameters."""

from __future__ import annotations

import optuna

try:
    from .recommendation import average_cosine_similarity
except ImportError:
    from recommendation import average_cosine_similarity


def objective(trial: optuna.Trial) -> float:
    """Objective to maximize average cosine similarity."""
    max_features = trial.suggest_int("max_features", 10, 200)
    ngram_max = trial.suggest_int("ngram_range", 1, 2)

    return average_cosine_similarity(
        max_features=max_features,
        ngram_range=(1, ngram_max),
    )


def run_tuning(n_trials: int = 20) -> None:
    """Run Optuna study and print best settings."""
    study = optuna.create_study(direction="maximize")
    study.optimize(objective, n_trials=n_trials)

    print("Best parameters:", study.best_params)
    print(f"Best score: {study.best_value:.4f}")


if __name__ == "__main__":
    run_tuning()
