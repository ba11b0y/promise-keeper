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

function CheckExistingPromises(newPotentialPromises: Promise[], existingPromisesInDB: Promise[]) -> Promise[] | null {
  client LlamaAPI
  prompt #"
    You are a promise keeper assistant that helps filter new promises against existing ones to avoid duplicates.

    TASK: Compare the new potential promises from a screenshot against existing promises in the database. Return ONLY the genuinely NEW promises that should be added. If ALL new promises are duplicates, return an EMPTY ARRAY.

    NEW POTENTIAL PROMISES from screenshot:
    {{ newPotentialPromises }}

    EXISTING PROMISES in database:
    {{ existingPromisesInDB }}

    DUPLICATE DETECTION CRITERIA:
    A new promise is considered a DUPLICATE if it matches an existing promise on these key fields:
    - **content** (the main promise text - exact or very similar meaning)
    - **to_whom** (same recipient)  
    - **deadline** (same or very similar timeframe)

    FILTERING RULES:
    1. **Exact duplicates**: If a new promise has the same content, recipient, and deadline as an existing one → EXCLUDE IT
    2. **Similar promises**: If a new promise has very similar content and same recipient/deadline → EXCLUDE IT  
    3. **Updated deadlines**: If same content/recipient but different deadline → INCLUDE IT (it's an update)
    4. **Different recipients**: If same content/deadline but different recipient → INCLUDE IT
    5. **Different content**: If different commitment but same recipient → INCLUDE IT

    EXAMPLES:
    - Existing: "I'll send the report by Friday" to "John" → New: "I'll send the report by Friday" to "John" = DUPLICATE (exclude)
    - Existing: "I'll send the report by Friday" to "John" → New: "I'll get you that report by Friday" to "John" = DUPLICATE (exclude - same meaning)
    - Existing: "I'll call mom this weekend" → New: "I'll call mom Sunday" = UPDATE (include - more specific deadline)
    - Existing: "I'll review the document for John" → New: "I'll review the document for Sarah" = DIFFERENT (include - different recipient)

    IMPORTANT: 
    - If NO new promises pass the duplicate check, return an empty array []
    - Only include promises from the new potential promises list that are genuinely different from existing ones
    - The "reasoning" field should NOT be used for duplicate detection - focus on content, recipient, and deadline

    {{ ctx.output_format }}
  "#
}

test TestName {
  functions [ExtractPromises]
  args {
    userImage { url "https://imgs.xkcd.com/comics/standards.png" }
  }
}

test TestName2 {
  functions [CheckExistingPromises]
  args {
    newPotentialPromises[ {
      content "I'll send the report by Friday"
      reasoning "I'll get you that report by Friday"
      to_whom "John"
      deadline "2025-06-21"
    }
    ]
    existingPromisesInDB [{
      content "I'll send the report by Friday"
      reasoning "I'll get you that report by Friday"
      to_whom "John"
      deadline "2025-06-21"
    }]
  }
}
