-- Add new fields to the promises table
ALTER TABLE public.promises 
ADD COLUMN IF NOT EXISTS due_date timestamp with time zone,
ADD COLUMN IF NOT EXISTS person text,
ADD COLUMN IF NOT EXISTS platform text;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_promises_due_date ON public.promises(due_date);
CREATE INDEX IF NOT EXISTS idx_promises_person ON public.promises(person);
CREATE INDEX IF NOT EXISTS idx_promises_platform ON public.promises(platform);

-- Add missing columns that are already used in the backend
ALTER TABLE public.promises 
ADD COLUMN IF NOT EXISTS resolved boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS extracted_from_screenshot boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS screenshot_id text,
ADD COLUMN IF NOT EXISTS screenshot_timestamp text,
ADD COLUMN IF NOT EXISTS extraction_data jsonb,
ADD COLUMN IF NOT EXISTS action jsonb,
ADD COLUMN IF NOT EXISTS metadata jsonb,
ADD COLUMN IF NOT EXISTS potential_actions jsonb,
ADD COLUMN IF NOT EXISTS resolved_screenshot_id text,
ADD COLUMN IF NOT EXISTS resolved_screenshot_time text,
ADD COLUMN IF NOT EXISTS resolved_reason text;

-- Add index for resolved promises
CREATE INDEX IF NOT EXISTS idx_promises_resolved ON public.promises(resolved);
CREATE INDEX IF NOT EXISTS idx_promises_owner_resolved ON public.promises(owner_id, resolved);