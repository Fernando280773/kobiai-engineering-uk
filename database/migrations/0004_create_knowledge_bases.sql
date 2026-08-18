-- 0004_create_knowledge_bases.sql
-- Migration: Create knowledge_bases table and multi-tenant RLS policies.
-- Date: July 16, 2026

-- Create knowledge_bases table
CREATE TABLE IF NOT EXISTS public.knowledge_bases (
    id UUID DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    project_id UUID,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_by UUID NOT NULL, -- References auth.users in Supabase
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_knowledge_bases PRIMARY KEY (id),
    CONSTRAINT fk_knowledge_bases_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_knowledge_bases_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL,
    CONSTRAINT chk_knowledge_bases_status CHECK (status IN ('active', 'inactive'))
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_workspace ON public.knowledge_bases(workspace_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_project ON public.knowledge_bases(project_id);

-- Enable Row-Level Security (RLS)
ALTER TABLE public.knowledge_bases ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can access knowledge bases in workspaces they are members of
CREATE POLICY rls_knowledge_bases_select ON public.knowledge_bases
    FOR ALL
    TO authenticated
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM public.workspace_members
            WHERE user_id = auth.uid()
        )
    );
