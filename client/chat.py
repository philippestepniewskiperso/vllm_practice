"""Client chat OpenAI-compatible vers le serveur vLLM.

Usage:
    uv run python client/chat.py "Explique la quantization en une phrase."
"""

import os
import sys

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()


def main() -> None:
    base_url = os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1")
    api_key = os.environ.get("VLLM_API_KEY", "EMPTY")
    model = os.environ.get("MODEL", "Qwen/Qwen2.5-1.5B-Instruct")

    prompt = " ".join(sys.argv[1:]) or "Dis bonjour en une phrase."

    client = OpenAI(base_url=base_url, api_key=api_key)

    stream = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "Tu es un assistant concis."},
            {"role": "user", "content": prompt},
        ],
        stream=True,
        temperature=0.7,
    )

    for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        print(delta, end="", flush=True)
    print()


if __name__ == "__main__":
    main()
