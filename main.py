import sys
import openai

client = openai.OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="unused"
)

def ask_pocket_genie(prompt):
    response = client.chat.completions.create(
        model="qwen",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7
    )
    print(response.choices[0].message.content)

if __name__ == "__main__":
    query = " ".join(sys.argv[1:])
    if not query:
        print("Usage: pocket-genie <your question>")
    else:
        ask_pocket_genie(query)
