-- 0006_create_knowledge_relationships.sql
-- Migration: Create knowledge_relationships table and multi-tenant RLS policies.
-- Date: July 16, 2026

-- Create knowledge_relationships table
CREATE TABLE IF NOT EXISTS public.knowledge_relationships (
    id UUID DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL, -- Denormalized for standard tenant isolation
    source_document_id UUID NOT NULL,
    target_document_id UUID NOT NULL,
    relationship_type TEXT NOT NULL,
    created_by UUID NOT NULL, -- References auth.users in Supabase
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT pk_knowledge_relationships PRIMARY KEY (id),
    CONSTRAINT fk_knowledge_relationships_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_knowledge_relationships_source FOREIGN KEY (source_document_id) REFERENCES public.knowledge_documents(id) ON DELETE CASCADE,
    CONSTRAINT fk_knowledge_relationships_target FOREIGN KEY (target_document_id) REFERENCES public.knowledge_documents(id) ON DELETE CASCADE,
    CONSTRAINT chk_knowledge_relationships_type CHECK (relationship_type IN ('references', 'depends_on', 'duplicates', 'part_of')),
    CONSTRAINT chk_knowledge_relationships_self CHECK (source_document_id <> target_document_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_knowledge_relationships_workspace ON public.knowledge_relationships(workspace_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_relationships_source ON public.knowledge_relationships(source_document_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_relationships_target ON public.knowledge_relationships(target_document_id);

-- Enable Row-Level Security (RLS)
ALTER TABLE public.knowledge_relationships ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can access relationships in workspaces they are members of
CREATE POLICY rls_knowledge_relationships_select ON public.knowledge_relationships
    FOR ALL
    TO authenticated
    USING (
        workspace_id IN (
            SELECT workspace_id
            FROM public.workspace_members
            WHERE user_id = auth.uid()
        )
    );
