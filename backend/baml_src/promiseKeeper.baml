// Defining a data model.
class Promise {
  content string
}

// Create a function to extract the resume from a string.
function CreatePromise(userRequest: string) -> Promise {
  // Specify a client as provider/model-name
  // you can use custom LLM params with a custom client name from clients.baml like "client CustomHaiku"
  client LlamaAPI // Set OPENAI_API_KEY to use this client.
  prompt #"
    You are a promise keeper assistant. Your job is to help users create clear, specific, and actionable promises from their input.

    A promise should be:
    - Specific and concrete (not vague or general)
    - Actionable (something that can actually be done)
    - Clear about what will be accomplished
    - Written in first person ("I will...")

    User input: {{ userRequest }}

    Based on the user's input, create a specific, actionable promise. If the input is vague, make it more specific while staying true to the user's intent. If the input contains multiple potential promises, focus on the most important or urgent one.

    Examples:
    - Input: "I need to call my mom" → Promise: "I will call my mom this week to check in and see how she's doing"
    - Input: "work on presentation" → Promise: "I will complete the quarterly sales presentation by Friday afternoon"
    - Input: "exercise more" → Promise: "I will go for a 30-minute walk every morning this week"

    {{ ctx.output_format }}
  "#
}