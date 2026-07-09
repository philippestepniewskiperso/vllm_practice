"""Benchmark simple du serveur vLLM: latence, TTFT, throughput tokens/s.

Lance N requetes concurrentes en streaming et agrege les metriques.

Usage:
    uv run python client/benchmark.py --requests 20 --concurrency 4
"""

import argparse
import asyncio
import os
import statistics
import time

import httpx
from dotenv import load_dotenv

load_dotenv()

PROMPT = "Ecris un court paragraphe sur l'inference de LLM a grande echelle."


async def one_request(
    client: httpx.AsyncClient, base_url: str, api_key: str, model: str, max_tokens: int
) -> dict:
    """Une requete streaming. Retourne ttft, latence totale, nb tokens."""
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": PROMPT}],
        "max_tokens": max_tokens,
        "stream": True,
        "temperature": 0.7,
    }
    headers = {"Authorization": f"Bearer {api_key}"}

    start = time.perf_counter()
    ttft = None
    tokens = 0

    async with client.stream(
        "POST", f"{base_url}/chat/completions", json=payload, headers=headers
    ) as resp:
        resp.raise_for_status()
        async for line in resp.aiter_lines():
            if not line.startswith("data: "):
                continue
            data = line[len("data: ") :]
            if data.strip() == "[DONE]":
                break
            if ttft is None:
                ttft = time.perf_counter() - start
            tokens += 1

    total = time.perf_counter() - start
    return {"ttft": ttft or total, "latency": total, "tokens": tokens}


async def run(args: argparse.Namespace) -> None:
    base_url = os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1")
    api_key = os.environ.get("VLLM_API_KEY", "EMPTY")
    model = os.environ.get("MODEL", "Qwen/Qwen2.5-1.5B-Instruct")

    sem = asyncio.Semaphore(args.concurrency)
    results: list[dict] = []

    async with httpx.AsyncClient(timeout=httpx.Timeout(120.0)) as client:

        async def guarded() -> None:
            async with sem:
                results.append(
                    await one_request(client, base_url, api_key, model, args.max_tokens)
                )

        wall_start = time.perf_counter()
        await asyncio.gather(*(guarded() for _ in range(args.requests)))
        wall = time.perf_counter() - wall_start

    latencies = sorted(r["latency"] for r in results)
    ttfts = sorted(r["ttft"] for r in results)
    total_tokens = sum(r["tokens"] for r in results)

    def pct(values: list[float], p: float) -> float:
        idx = min(len(values) - 1, int(p * len(values)))
        return values[idx]

    print(f"Requetes        : {args.requests} (concurrency {args.concurrency})")
    print(f"Wall time       : {wall:.2f}s")
    print(f"Latence  p50/p95: {statistics.median(latencies):.2f}s / {pct(latencies, 0.95):.2f}s")
    print(f"TTFT     p50/p95: {statistics.median(ttfts):.3f}s / {pct(ttfts, 0.95):.3f}s")
    print(f"Throughput      : {total_tokens / wall:.1f} tokens/s (agrege)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark vLLM")
    parser.add_argument("--requests", type=int, default=20)
    parser.add_argument("--concurrency", type=int, default=4)
    parser.add_argument("--max-tokens", type=int, default=128)
    asyncio.run(run(parser.parse_args()))


if __name__ == "__main__":
    main()
