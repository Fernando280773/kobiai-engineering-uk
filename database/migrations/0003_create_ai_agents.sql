-- 0003_create_ai_agents.sql
-- Migration: Create ai_agents table and multi-tenant RLS policies.
-- Date: July 16, 2026

-- Create ai_agents table
CREATE TABLE IF NOT EXISTS public.ai_agents (
    id UUID DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    project_id UUID,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    model TEXT NOT NULL,
    system_prompt TEXT NOT NULL,
    configuration JSONB DEFAULT '{}'::jsonb NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    version TEXT NOT NULL DEFAULT '1.0.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT pk_ai_agents PRIMARY KEY (id),
    CONSTRAINT fk_ai_agents_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_agents_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL,
    CONSTRAINT chk_ai_agents_status CHECK (status IN ('active', 'inactive'))
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_agents_workspace ON public.ai_agents(workspace_id);
CREATE INDEX IF NOT EXISTS idx_ai_agents_project ON public.ai_agents(project_id);

-- Enable Row-Level Security (RLS)
ALTER TABLE public.ai_agents ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can access AI agents in workspaces they are members of
CREATE POLICY rls_ai_agents_select ON public.ai_agents
    FOR ALL
    TO authenticated
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM public.workspace_members
            WHERE user_id = auth.uid()
        )
    );
