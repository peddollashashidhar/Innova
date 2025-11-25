#!/usr/bin/env python3
"""Chat fetcher

Simple CLI to send prompts to the OpenAI Chat API and store responses in a CSV file.

Usage examples:
  # single prompt
  python python-gpt/chat_fetcher.py --prompt "Translate to French: Hello" --output responses.csv

  # from file (one prompt per line)
  python python-gpt/chat_fetcher.py --prompts-file prompts.txt --output responses.csv

Set your OpenAI API key in environment variable `OPENAI_API_KEY` or in a `.env` file.
"""
from __future__ import annotations

import csv
import datetime
import time
import argparse
import os
import sys
from typing import List

try:
    from dotenv import load_dotenv
except Exception:
    load_dotenv = None

try:
    import openai
    from openai.error import RateLimitError, ServiceUnavailableError, APIError, Timeout
except Exception as e:
    print("Missing required dependency 'openai'. Install from requirements.txt and try again.")
    raise


def load_env():
    # load .env if python-dotenv available
    if load_dotenv:
        load_dotenv()


def get_api_key() -> str:
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        raise RuntimeError("OPENAI_API_KEY not set in environment. Set it or add a .env file with OPENAI_API_KEY=...")
    return key


def read_prompts_from_file(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as fh:
        lines = [l.strip() for l in fh.readlines()]
    return [l for l in lines if l]


def chat_completion_with_retries(prompt: str, model: str, temperature: float, max_tokens: int, retries: int = 5):
    attempt = 0
    backoff = 1.0
    while True:
        try:
            resp = openai.ChatCompletion.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=max_tokens,
            )
            return resp
        except (RateLimitError, ServiceUnavailableError, Timeout, APIError) as e:
            attempt += 1
            if attempt > retries:
                raise
            sleep = backoff * (2 ** (attempt - 1))
            print(f"Transient API error (attempt {attempt}/{retries}): {e}. Retrying in {sleep:.1f}s...")
            time.sleep(sleep)


def ensure_csv_header(path: str, fieldnames: List[str]):
    exists = os.path.exists(path)
    if not exists:
        with open(path, "w", encoding="utf-8", newline="") as fh:
            writer = csv.DictWriter(fh, fieldnames=fieldnames)
            writer.writeheader()


def append_response_to_csv(path: str, row: dict, fieldnames: List[str]):
    with open(path, "a", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writerow(row)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Query OpenAI Chat API and save responses to CSV")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--prompt", type=str, help="Single prompt to send")
    group.add_argument("--prompts-file", type=str, help="Path to file with one prompt per line")
    parser.add_argument("--output", "-o", type=str, default="responses.csv", help="CSV output file")
    parser.add_argument("--model", type=str, default=os.getenv("OPENAI_MODEL", "gpt-3.5-turbo"), help="Model to use (env OPENAI_MODEL)")
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--max-tokens", type=int, default=1024)
    parser.add_argument("--retries", type=int, default=5)
    args = parser.parse_args(argv)

    load_env()
    api_key = get_api_key()
    openai.api_key = api_key

    if args.prompts_file:
        prompts = read_prompts_from_file(args.prompts_file)
    else:
        prompts = [args.prompt]

    fieldnames = ["prompt", "response", "model", "created_at", "id", "status"]
    ensure_csv_header(args.output, fieldnames)

    for idx, prompt in enumerate(prompts, start=1):
        print(f"[{idx}/{len(prompts)}] Sending prompt: {prompt[:60]!r}...")
        try:
            resp = chat_completion_with_retries(prompt=prompt, model=args.model, temperature=args.temperature, max_tokens=args.max_tokens, retries=args.retries)
            # extract text
            text = ""
            try:
                text = resp.choices[0].message.content
            except Exception:
                # fallback for other response shapes
                text = getattr(resp.choices[0], "text", "")

            created_at = datetime.datetime.utcnow().isoformat() + "Z"
            row = {
                "prompt": prompt,
                "response": text,
                "model": resp.model if hasattr(resp, "model") else args.model,
                "created_at": created_at,
                "id": getattr(resp, "id", ""),
                "status": "ok",
            }
            append_response_to_csv(args.output, row, fieldnames)
            print(f"Saved response to {args.output}")
        except Exception as e:
            print(f"Failed to fetch response for prompt: {e}")
            row = {"prompt": prompt, "response": "", "model": args.model, "created_at": datetime.datetime.utcnow().isoformat() + "Z", "id": "", "status": f"error: {e}"}
            append_response_to_csv(args.output, row, fieldnames)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
