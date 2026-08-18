-- 0005_create_knowledge_documents.sql
-- Migration: Create knowledge_documents table and multi-tenant RLS policies.
-- Date: July 16, 2026

-- Create knowledge_documents table
CREATE TABLE IF NOT EXISTS public.knowledge_documents (
    id UUID DEFAULT gen_random_uuid(),
    knowledge_base_id UUID NOT NULL,
    workspace_id UUID NOT NULL, -- Denormalized for standard tenant isolation
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    content_format TEXT NOT NULL DEFAULT 'markdown',
    version TEXT NOT NULL DEFAULT '1.0.0',
    search_metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    created_by UUID NOT NULL, -- References auth.users in Supabase
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_knowledge_documents PRIMARY KEY (id),
    CONSTRAINT fk_knowledge_documents_knowledge_base FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_bases(id) ON DELETE CASCADE,
    CONSTRAINT fk_knowledge_documents_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE,
    CONSTRAINT chk_knowledge_documents_content_format CHECK (content_format IN ('markdown', 'text', 'html', 'json'))
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_knowledge_documents_knowledge_base ON public.knowledge_documents(knowledge_base_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_documents_workspace ON public.knowledge_documents(workspace_id);

-- Enable Row-Level Security (RLS)
ALTER TABLE public.knowledge_documents ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can access documents in workspaces they are members of
CREATE POLICY rls_knowledge_documents_select ON public.knowledge_documents
    FOR ALL
    TO authenticated
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM public.workspace_members
            WHERE user_id = auth.uid()
        )
    );
