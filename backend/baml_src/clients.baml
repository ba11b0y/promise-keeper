// Learn more about clients at https://docs.boundaryml.com/docs/snippets/clients/overview

client<llm> OpenAI {
  provider openai
  options {
    model "gpt-4o"
    api_key env.OPENAI_API_KEY
  }
}

client<llm> LlamaAPI {
  provider openai
  options {
    model "Llama-4-Maverick-17B-128E-Instruct-FP8"
    base_url "https://api.llama.com/compat/v1/"
    api_key env.LLAMA_API_KEY
    default_role user
  }
}