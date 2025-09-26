#!/usr/bin/env python3
"""
Redis replay helper for DLQ handler.

- Computes a stable payload hash (SHA256) for deduplication.
- Uses Redis SET NX with an expiry to ensure a payload is only enqueued once within the TTL.
- RPUSHes the serialized payload to the role-sync queue on success.
- Returns True on success or duplicate-detected, False on Redis failure (caller should fallback to DB).
"""
from __future__ import annotations

import hashlib
import json
import os
from typing import Dict

try:
    from redis import Redis, RedisError
except Exception:  # pragma: no cover - guard for environments without redis installed
    Redis = None  # type: ignore
    RedisError = Exception  # type: ignore

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
ROLE_SYNC_QUEUE = os.getenv("ROLE_SYNC_QUEUE", "role_sync")
DEDUP_TTL = int(os.getenv("DEDUP_TTL", "3600"))  # seconds

_redis_client: "Redis | None" = None

def _get_redis() -> "Redis | None":
    global _redis_client
    if _redis_client is not None:
        return _redis_client
    if Redis is None:
        return None
    try:
        _redis_client = Redis.from_url(REDIS_URL, socket_timeout=5, socket_connect_timeout=5)
        return _redis_client
    except Exception:
        return None


def payload_hash(payload: str) -> str:
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def replay_to_redis(payload_obj: Dict) -> bool:
    payload = json.dumps(payload_obj, separators=("," ,":"), sort_keys=True)
    ph = payload_hash(payload)
    dedup_key = f"role_sync_dedup:{ph}"

    r = _get_redis()
    if r is None:
        return False

    try:
        was_set = r.set(dedup_key, "1", nx=True, ex=DEDUP_TTL)
        if was_set:
            r.rpush(ROLE_SYNC_QUEUE, payload)
        return True
    except RedisError:
        return False
    except Exception:
        return False
"}