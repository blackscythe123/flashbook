"""
Cache service for storing and retrieving generated summaries.
Uses in-memory cache by default, designed to be swapped for Redis/Firestore later.
"""

import hashlib
import json
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from dataclasses import dataclass, field

from ..core.config import get_settings
from ..core.schemas import SummaryRequest, SummaryResponse

logger = logging.getLogger(__name__)


@dataclass
class CacheEntry:
    """A single cache entry with metadata."""
    data: Dict[str, Any]
    created_at: datetime
    expires_at: datetime
    hit_count: int = 0


class CacheService:
    """
    In-memory cache for summary responses.
    
    Design notes:
    - Key = hash(book_id + chapter_title + text_chunk + mode)
    - Cache at chunk level, not user level
    - TTL-based expiration
    - Easy to swap for Redis/Firestore by implementing same interface
    """
    
    def __init__(self):
        self.settings = get_settings()
        self._cache: Dict[str, CacheEntry] = {}
        self._stats = {
            "hits": 0,
            "misses": 0,
            "stores": 0,
            "evictions": 0
        }
    
    def _generate_key(self, request: SummaryRequest) -> str:
        """
        Generate a deterministic cache key from request parameters.
        
        Key components:
        - book_id (or "none")
        - chapter_title (or "none")
        - text_chunk (first 500 + last 500 chars for efficiency)
        - mode
        """
        components = [
            request.book_id or "none",
            request.chapter_title or "none",
            request.text_chunk[:500] + request.text_chunk[-500:] if len(request.text_chunk) > 1000 else request.text_chunk,
            request.mode.value
        ]
        
        key_string = "|".join(components)
        return hashlib.sha256(key_string.encode()).hexdigest()[:32]
    
    def _is_expired(self, entry: CacheEntry) -> bool:
        """Check if a cache entry has expired."""
        return datetime.utcnow() > entry.expires_at
    
    def _cleanup_expired(self) -> None:
        """Remove expired entries (called periodically)."""
        expired_keys = [
            key for key, entry in self._cache.items()
            if self._is_expired(entry)
        ]
        for key in expired_keys:
            del self._cache[key]
            self._stats["evictions"] += 1
        
        if expired_keys:
            logger.info(f"Cleaned up {len(expired_keys)} expired cache entries")
    
    def get(self, request: SummaryRequest) -> Optional[SummaryResponse]:
        """
        Retrieve a cached response if available and not expired.
        
        Args:
            request: The summary request to look up
            
        Returns:
            SummaryResponse if cached and valid, None otherwise
        """
        key = self._generate_key(request)
        
        entry = self._cache.get(key)
        
        if entry is None:
            self._stats["misses"] += 1
            logger.debug(f"Cache miss for key: {key[:8]}...")
            return None
        
        if self._is_expired(entry):
            del self._cache[key]
            self._stats["misses"] += 1
            self._stats["evictions"] += 1
            logger.debug(f"Cache expired for key: {key[:8]}...")
            return None
        
        # Cache hit!
        entry.hit_count += 1
        self._stats["hits"] += 1
        
        logger.info(f"Cache hit for key: {key[:8]}... (hits: {entry.hit_count})")
        
        # Reconstruct response with cached=True
        response = SummaryResponse(**entry.data)
        response.cached = True
        return response
    
    def store(self, request: SummaryRequest, response: SummaryResponse) -> None:
        """
        Store a response in the cache.
        
        Args:
            request: The original request (used for key generation)
            response: The response to cache
        """
        key = self._generate_key(request)
        
        ttl = timedelta(seconds=self.settings.CACHE_TTL_SECONDS)
        now = datetime.utcnow()
        
        # Store response data (without cached flag)
        response_data = response.model_dump()
        response_data["cached"] = False  # Will be set to True on retrieval
        
        self._cache[key] = CacheEntry(
            data=response_data,
            created_at=now,
            expires_at=now + ttl
        )
        
        self._stats["stores"] += 1
        logger.info(f"Cached response for key: {key[:8]}... (total entries: {len(self._cache)})")
        
        # Periodic cleanup (every 100 stores)
        if self._stats["stores"] % 100 == 0:
            self._cleanup_expired()
    
    def invalidate(self, request: SummaryRequest) -> bool:
        """
        Remove a specific entry from cache.
        
        Args:
            request: The request to invalidate
            
        Returns:
            True if entry was found and removed, False otherwise
        """
        key = self._generate_key(request)
        if key in self._cache:
            del self._cache[key]
            logger.info(f"Invalidated cache for key: {key[:8]}...")
            return True
        return False
    
    def clear(self) -> int:
        """
        Clear all cache entries.
        
        Returns:
            Number of entries cleared
        """
        count = len(self._cache)
        self._cache.clear()
        logger.info(f"Cleared {count} cache entries")
        return count
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total_requests = self._stats["hits"] + self._stats["misses"]
        hit_rate = (self._stats["hits"] / total_requests * 100) if total_requests > 0 else 0
        
        return {
            **self._stats,
            "entries": len(self._cache),
            "hit_rate_percent": round(hit_rate, 2)
        }


# Singleton instance
_cache: Optional[CacheService] = None


def get_cache_service() -> CacheService:
    """Get the singleton cache service instance."""
    global _cache
    if _cache is None:
        _cache = CacheService()
    return _cache
