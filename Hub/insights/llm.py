import os

class LLMClient:
    def __init__(self):
        import openai
        self.api_key = os.environ.get('OPENAI_API_KEY', '')
        openai.api_key = self.api_key

    def complete(self, system: str, user: str, max_tokens: int = 40) -> str:
        if not self.api_key:
            return ""
        import openai
        resp = openai.chat.completions.create(
            model='gpt-4o-mini',           # ~$0.15 / 1M input tokens
            messages=[
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
            ],
            max_tokens=max_tokens,
            temperature=0.4,
        )
        return resp.choices[0].message.content or ""
