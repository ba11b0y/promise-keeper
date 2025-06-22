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
  action Action? @description(#"
    You have the opportunity to pass this agent with an Apple MCP server to take actions on the user's behalf.
    If you think this is the case, you can pass the agent with the action you want to take, and the parameters you would need to pass to the agent to take that action.
  "#)
} 

enum ActionType {
  // Messages_compose_message @description(#"
  //   messages_compose_message
  // "#)
  System_Launch_App @description(#"
    system_launch_app
  "#)
  Calendar_Add @description(#"
    calendar_add
  "#)
  NoAction @description(#"
    No action needed
  "#)
}

class Action {
  actionType ActionType @description(#"
    The type of action to take based on the promise
    For example, if the promise mentions something like "Do you want me to schedule a meeting tomorrow at 8?"
    tyou might want to use Calendar_Add to add an event to the calendar.
    But if you don't see any action to take, you can use NoAction.
  "#)
  start_time string? @description(#"
    When the action should start (if applicable), format it in datetime format (e.g., "2025-06-21T20:00:00Z")
  "#)
  end_time string? @description(#"
    When the action should end (if applicable), format it in datetime format (e.g., "2025-06-21T21:00:00Z")
  "#)
  whom_to string? @description(#"
    Who the action is directed to (if applicable), usually the top of the window contains the name of the person or entity
  "#)
  app_name string? @description(#"
    The name of the app to launch if the action is to launch an app, for example, "Spotify", "Discord", etc.
  "#)
}


class ResolvedPromise {
  original_promise Promise @description(#"
    The original promise that has been resolved
  "#)
  resolution_reasoning string @description(#"
    Detailed explanation of why this promise is considered resolved based on what was observed in the image
  "#)
  resolution_evidence string? @description(#"
    Specific evidence from the image that shows the promise was fulfilled (e.g., "sent email confirmation", "meeting completed", etc.)
  "#)
}

class PromiseListResponse {
  promises Promise[]
}

class ResolvedPromisesResponse {
  resolved_promises ResolvedPromise[] @description(#"
    List of promises that have been resolved based on the screenshot analysis
  "#)
}

class NoPromisesResolvedResponse {
  reason string? @description(#"
    The reason why no promises were detected as resolved in this image
  "#)
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

    IMPORTANT: If you see the Promise Keeper application itself (showing existing promises, app interface, settings, etc.), IGNORE everything in it.
    Do not extract any promises from the Promise Keeper app interface to avoid recursive issues.
    Do not consider duplicate texts as two different promises, even if they are repeated in the screenshot.
    Also, make sure that you check the last of the messages in the screenshot to get the latest promises made by the user.

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

function ShouldSaveNewPromise(existingPromises: Promise[], newPotentialPromise: Promise) -> ShouldSaveNewPromiseEnum {
  client LlamaAPI
  prompt #"
    You are a promise keeper assistant that evaluates whether a single new promise should be saved by comparing it against existing promises.

    TASK: Analyze the new potential promise against all existing promises and determine if it should be saved to avoid duplicates.

    NEW POTENTIAL PROMISE:
    {{ newPotentialPromise }}

    EXISTING PROMISES in database:
    {{ existingPromises }}

    EVALUATION CRITERIA:
    A new promise should be evaluated based on similarity to existing promises considering:
    - **content** (the main promise text - exact or very similar meaning)
    - **to_whom** (same recipient)  
    - **deadline** (same or very similar timeframe)

    DECISION RULES:
    1. **DEFINITELY_NOT_SAVE**: If the new promise is essentially identical to an existing promise
       - Same content/meaning, same recipient, same deadline
       - Minor wording differences but same commitment, person, and timeframe
    
    2. **DEFINITELY_SAVE**: If the new promise is clearly different from all existing promises
       - Different content/commitment entirely
       - Same content but different recipient
       - Same content/recipient but significantly different deadline
       - New type of commitment not covered by existing promises
    
    3. **POSSIBLY_SAVE**: If there's some similarity but meaningful differences
       - Similar content but with additional details or specificity
       - Same general commitment but refined deadline (e.g., "this week" → "Friday")
       - Minor variations that might represent updates or clarifications

    EXAMPLES:
    - Existing: "I'll send the report by Friday" to "John" → New: "I'll send the report by Friday" to "John" = DEFINITELY_NOT_SAVE
    - Existing: "I'll call mom this weekend" → New: "I'll call mom Sunday at 3pm" = POSSIBLY_SAVE (more specific)
    - Existing: "I'll review the document for John" → New: "I'll review the document for Sarah" = DEFINITELY_SAVE (different recipient)
    - Existing: "I'll send the budget analysis" → New: "I'll email you the quarterly budget analysis by tomorrow" = POSSIBLY_SAVE (more details)

    IMPORTANT: 
    - Focus on the practical impact: would saving this promise provide value to the user?
    - Consider that slight variations might represent important updates or clarifications
    - The "reasoning" field should NOT be the primary factor - focus on content, recipient, and deadline

    {{ ctx.output_format }}
  "#
}

enum ShouldSaveNewPromiseEnum {
  DEFINITELY_SAVE
  DEFINITELY_NOT_SAVE
  POSSIBLY_SAVE
}

function CheckResolvedPromises(userImage: image, existingPromises: Promise[]) -> ResolvedPromisesResponse | NoPromisesResolvedResponse {
  client LlamaAPI
  prompt #"
    You are a promise keeper assistant that monitors screenshots to detect when users have fulfilled their commitments to others.

    CONTEXT: This screenshot is from a user's screen monitoring system. You need to analyze the image to see if any of the user's existing promises have been resolved/fulfilled.

    EXISTING PROMISES TO CHECK:
    {{ existingPromises }}

    WHAT COUNTS AS PROMISE RESOLUTION:
    - **Email/Message sent**: Screenshot shows the user sent an email, text, or message that fulfills a communication promise
    - **Meeting completed**: Evidence of a meeting or call that was promised
    - **Document delivered**: Screenshots showing files being shared, reports being sent, or documents being completed
    - **Task completion**: Clear evidence that a promised task or deliverable has been finished
    - **Follow-up actions**: Screenshots showing the user taking the specific action they promised

    WHAT TO LOOK FOR:
    - Sent emails/messages with content related to promises
    - Completed calendar events or meetings
    - File sharing or document delivery activities  
    - Applications showing task completion
    - Any interface showing the user has taken the promised action

    WHAT IS NOT RESOLUTION:
    - Just drafting emails (unless clearly indicates sending)
    - Planning or scheduling future actions
    - General work that doesn't specifically fulfill a promise
    - Browsing or research that doesn't complete the commitment

    IMPORTANT GUIDELINES:
    1. Only mark promises as resolved if you see CLEAR EVIDENCE of fulfillment in the screenshot
    2. Be specific about what evidence you observed that indicates resolution
    3. If you see the Promise Keeper application itself, IGNORE it to avoid recursive issues
    4. Match the evidence in the screenshot to the specific content and recipient of existing promises
    5. Don't make assumptions - only mark as resolved if genuinely evident from the image

    For each resolved promise, provide:
    - The original promise details
    - Clear reasoning explaining why it's considered resolved
    - Specific evidence from the screenshot that supports this conclusion

    If no promises appear to be resolved in this screenshot, return NoPromisesResolvedResponse.

    Analyze the image: {{ userImage }}

    {{ ctx.output_format }}
  "#
}

test TestName {
  functions [ExtractPromises]
  args {
    userImage { url "https://i.postimg.cc/ZYN8vMzd/Screenshot-2025-06-22-at-8-44-35-AM.png" }
  }
}

test TestName2 {
  functions [CheckExistingPromises]
  args {
    newPotentialPromises[ {
      content "Hey! Wanna catch up on Zoom tomorrow at 8? "
      reasoning ""
      to_whom ""
      deadline "2025-06-21"
      action {
        actionType Calendar_Add
        start_time "2025-06-21T20:00:00Z"
        end_time "2025-06-21T21:00:00Z"
        whom_to "John"
      }
    },
    ]
    existingPromisesInDB [{
      content "I'll send you the playlist in a minute"
      reasoning "The user promised to send a playlist"
      to_whom "John"
      deadline "2025-06-21"
      action {
        actionType System_Launch_App
        action_dependencies "recipient, body"
        action_details "I'll send the report by Friday"
        app_name "Spotify"
      }
    }]
  }
}
