// Defining a data model for individual promises.
class Promise {
  content string
  to_whom string? // Who the promise is made to (optional, could be "myself", "family", "work", etc.)
  deadline string? // When the promise should be fulfilled (optional, could be specific date or relative time)
}

class PromiseList {
  promises Promise[]
}

function ExtractPromises(userImage: image) -> PromiseList {
  client LlamaAPI // Set OPENAI_API_KEY to use this client.
  prompt #"
    You are a promise keeper assistant. Your job is to analyze images (screenshots, notes, text, etc.) and extract clear, specific, and actionable promises from them.

    A promise should be:
    - Specific and concrete (not vague or general)
    - Actionable (something that can actually be done)
    - Clear about what will be accomplished
    - Written in first person ("I will...")

    For each promise you extract, identify:
    1. Content: The specific promise being made
    2. To whom: Who the promise is made to (could be "myself", "family", "work colleague", "friend", specific person's name, etc. - leave null if unclear)
    3. Deadline: When the promise should be fulfilled (could be specific date, relative time like "this week", "by Friday", etc. - leave null if no deadline mentioned)

    Analyze the image: {{ userImage }}

    Extract ALL promises you can identify from the image. This could include:
    - Commitments mentioned in text
    - Todo items that imply promises
    - Deadlines or scheduled tasks
    - Commitments in messages or emails
    - Meeting notes with action items
    - Any other commitments or promises

    Examples of what you might extract:
    - From "Call mom this weekend": Promise("I will call my mom this weekend", "family", "this weekend")
    - From "Finish presentation by Friday": Promise("I will complete the presentation by Friday", "work", "Friday")
    - From "Remember to water plants": Promise("I will water the plants", "myself", null)
    - From "Meet John at 3pm tomorrow": Promise("I will meet with John at 3pm", "John", "tomorrow")

    If no clear promises can be identified from the image, return an empty list.

    {{ ctx.output_format }}
  "#
}
