// Defining a data model for individual promises.
class Promise {
  content string
  reasoning string? @description(#"
    The reasoning behind the promise - whatever you think is relevant for why you created this promise from the data
  "#)
  to_whom string? @description(#"
    Who the promise is made to (could be "myself", "family", "work", etc.)
  "#)
  deadline string? @description(#"
    When the promise should be fulfilled (could be specific date or relative time)
  "#)
}

class PromiseListResponse {
  promises Promise[]
}

class NoPromisesFoundResponse {
  reason string? @description(#"
    The reason why no promises were found in the image if none. Whatever you think is relevant for why you didn't find any promises from the data
  "#)
}

function ExtractPromises(userImage: image) -> PromiseListResponse| NoPromisesFoundResponse {
  client LlamaAPI // Set OPENAI_API_KEY to use this client.
  prompt #"
    You are a promise keeper assistant that monitors screenshots to help users remember important commitments they make to others.

    CONTEXT: This screenshot is from a user's screen monitoring system that captures images every 5 seconds. The vast majority of screenshots will contain NO promises - just normal work, browsing, or other activities. That's completely expected and normal.

    You should ONLY extract promises when you see explicit commitments or promises that the user is making to other people in their communications (texts, emails, chats, messages, etc.).

    WHAT QUALIFIES AS A PROMISE:
    - Explicit commitments: "I'll send you the report by Friday"
    - Direct promises: "I promise to call you back today" 
    - Scheduled commitments to others: "I'll meet you at 3pm tomorrow"
    - Follow-up commitments: "I'll get back to you on this by end of week"
    - Delivery commitments: "I'll have the draft ready by Monday"

    WHAT IS NOT A PROMISE:
    - General tasks or todos: "Need to buy groceries"
    - Offers without commitment: "Let me know if you need help"
    - Vague statements: "We should hang out sometime"
    - Calendar events or reminders (unless they represent commitments to others)
    - Work tasks that aren't explicit commitments to specific people

    Only extract promises from communication contexts where the user is actively making a commitment to someone else that they might forget about.

    IMPORTANT: If you see the Promise Keeper application itself (showing existing promises, app interface, settings, etc.), IGNORE everything in it. Do not extract any promises from the Promise Keeper app interface to avoid recursive issues.

    If you see normal browsing, working, or any content without clear interpersonal commitments, return NoPromisesFoundResponse.

    Analyze the image: {{ userImage }}

    {{ ctx.output_format }}
  "#
}

test TestName {
  functions [ExtractPromises]
  args {
    userImage { url "https://imgs.xkcd.com/comics/standards.png" }
  }
}
