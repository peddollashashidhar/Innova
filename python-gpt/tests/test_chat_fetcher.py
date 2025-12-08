import os
import csv
import tempfile
import io
import pathlib

import pytest

import sys
import types

# If the real openai package is not installed in the test environment, create
# a lightweight fake module so importing chat_fetcher doesn't fail. Tests use
# OPENAI_MOCK so we don't need a full client implementation here.
if "openai" not in sys.modules:
    fake_openai = types.ModuleType("openai")
    err_mod = types.ModuleType("openai.error")
    # define the exception names chat_fetcher imports
    for name in ("RateLimitError", "ServiceUnavailableError", "APIError", "Timeout"):
        setattr(err_mod, name, type(name, (Exception,), {}))
    fake_openai.error = err_mod
    # register the submodule as well so imports like 'from openai.error import ...' work
    sys.modules["openai.error"] = err_mod
    sys.modules["openai"] = fake_openai

import chat_fetcher as cf


def test_read_prompts_from_file(tmp_path):
    p = tmp_path / "prompts.txt"
    p.write_text("Hello\n\nWorld\n")
    prompts = cf.read_prompts_from_file(str(p))
    assert prompts == ["Hello", "World"]


def test_chat_completion_with_retries_mock(monkeypatch):
    monkeypatch.setenv("OPENAI_MOCK", "1")
    resp = cf.chat_completion_with_retries("Say hi", model="mock-model", temperature=0.0, max_tokens=10)
    # ensure we get a mock response object with expected content
    assert hasattr(resp, "choices")
    assert resp.choices[0].message.content.startswith("MOCK:")


def test_main_creates_csv_when_mock(tmp_path, monkeypatch):
    # Use a temporary output file
    out = tmp_path / "out.csv"
    prompt = "Translate this"

    monkeypatch.setenv("OPENAI_MOCK", "1")
    # main() verifies OPENAI_API_KEY; set a dummy value so it doesn't fail
    monkeypatch.setenv("OPENAI_API_KEY", "dummy")

    rc = cf.main(["--prompt", prompt, "--output", str(out)])
    assert rc == 0

    # Ensure CSV exists and has the expected header and row
    assert out.exists()
    with open(out, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        rows = list(reader)
    assert len(rows) == 1
    assert rows[0]["prompt"] == prompt
    assert rows[0]["response"].startswith("MOCK:")


if __name__ == "__main__":
    pytest.main([str(pathlib.Path(__file__))])
