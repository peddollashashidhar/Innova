# python-gpt — LLM CLI utility

This small CLI allows sending prompts to the OpenAI Chat API and saving responses into a CSV file.

Quickstart

1. Install dependencies into a virtual environment:

   python -m venv .venv; .\.venv\Scripts\Activate; pip install -r requirements.txt

2. Set your OpenAI API key in the environment (Windows PowerShell):

   $env:OPENAI_API_KEY="sk-..."

3. Run the script:

   python chat_fetcher.py --prompt "Translate to French: Hello" --output responses.csv

Or use a file with prompts (one per line):

   python chat_fetcher.py --prompts-file prompts.txt --output responses.csv

Docker build & run

Build:

  docker build -t python-gpt:latest .

Run (interactive):

  docker run --rm -e OPENAI_API_KEY="sk-..." python-gpt:latest --prompt "Hello world" --output /tmp/output.csv

Notes

- The defaults use gpt-3.5-turbo; set OPENAI_MODEL to use a different model.
- Output CSV will contain columns: prompt, response, model, created_at, id, status.


How you can check locally (commands)

Run unit tests:

cd python-gpt
python -m pytest -q
Build & run the container in mock mode:

docker build -t python-gpt:pr-mock-local .
mkdir -p pr-outputs
docker run --rm -e OPENAI_MOCK=1 -v "
(pwd)/pr − outputs :
/app/outputs" − v"
(pwd)/pr−outputs:/app/outputs"−v"(pwd)/sample_prompts.txt:/app/sample_prompts.txt" python-gpt:pr-mock-local --prompts-file sample_prompts.txt --output /app/outputs/pr.csv
cat pr-outputs/pr.csv