-- Keep document metadata readable according to the documents table policies,
-- but make uploaded files private and grant access only to owners/viewers/editors.

ALTER TABLE public.documents
  ADD COLUMN IF NOT EXISTS file_path text;

-- Preserve paths from URLs created by the old public bucket implementation.
UPDATE public.documents
SET file_path = regexp_replace(
      file_url,
      '^.*/storage/v1/object/public/documents/',
      ''
    ),
    file_url = NULL
WHERE file_path IS NULL
  AND file_url LIKE '%/storage/v1/object/public/documents/%';

UPDATE storage.buckets
SET public = false
WHERE id = 'documents';

-- Keep app ownership checks aligned with the canonical ID from public.users.
CREATE OR REPLACE FUNCTION public.current_app_user_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.id::text
  FROM public.users u
  WHERE lower(u.email) = lower(auth.jwt() ->> 'email')
  LIMIT 1
$$;

GRANT EXECUTE ON FUNCTION public.current_app_user_id() TO anon, authenticated;

DROP POLICY IF EXISTS documents_insert ON public.documents;
CREATE POLICY documents_insert ON public.documents
FOR INSERT
WITH CHECK (
  owner_id::text = public.current_app_user_id()
  OR owner_id::text = (auth.jwt() ->> 'sub')
);

DROP POLICY IF EXISTS documents_select ON public.documents;
CREATE POLICY documents_select ON public.documents
FOR SELECT
USING (
  owner_id::text = public.current_app_user_id()
  OR is_public = true
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = documents.id
      AND p.shared_with_user_id::text = public.current_app_user_id()
  )
);

DROP POLICY IF EXISTS documents_update ON public.documents;
CREATE POLICY documents_update ON public.documents
FOR UPDATE
USING (
  owner_id::text = public.current_app_user_id()
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = documents.id
      AND p.shared_with_user_id::text = public.current_app_user_id()
      AND p.permission_level = 'edit'
  )
)
WITH CHECK (
  owner_id::text = public.current_app_user_id()
  OR EXISTS (
    SELECT 1 FROM public.permissions p
    WHERE p.document_id = documents.id
      AND p.shared_with_user_id::text = public.current_app_user_id()
      AND p.permission_level = 'edit'
  )
);

DROP POLICY IF EXISTS documents_delete ON public.documents;
CREATE POLICY documents_delete ON public.documents
FOR DELETE
USING (owner_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS permissions_select ON public.permissions;
CREATE POLICY permissions_select ON public.permissions
FOR SELECT
USING (
  owner_id::text = public.current_app_user_id()
  OR shared_with_user_id::text = public.current_app_user_id()
);

DROP POLICY IF EXISTS permissions_insert ON public.permissions;
CREATE POLICY permissions_insert ON public.permissions
FOR INSERT
WITH CHECK (
  owner_id::text = public.current_app_user_id()
  AND EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = permissions.document_id
      AND d.owner_id::text = public.current_app_user_id()
  )
);

DROP POLICY IF EXISTS permissions_update ON public.permissions;
CREATE POLICY permissions_update ON public.permissions
FOR UPDATE
USING (owner_id::text = public.current_app_user_id())
WITH CHECK (owner_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS permissions_delete ON public.permissions;
CREATE POLICY permissions_delete ON public.permissions
FOR DELETE
USING (owner_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS requester_insert ON public.borrow_requests;
CREATE POLICY requester_insert ON public.borrow_requests
FOR INSERT
WITH CHECK (
  requester_id::text = public.current_app_user_id()
  AND requester_id::text <> owner_id::text
  AND EXISTS (
    SELECT 1 FROM public.documents d
    WHERE d.id = borrow_requests.document_id
      AND d.owner_id::text = borrow_requests.owner_id::text
      AND d.is_public = true
  )
);

DROP POLICY IF EXISTS requester_select ON public.borrow_requests;
CREATE POLICY requester_select ON public.borrow_requests
FOR SELECT
USING (requester_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS owner_select ON public.borrow_requests;
CREATE POLICY owner_select ON public.borrow_requests
FOR SELECT
USING (owner_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS owner_update ON public.borrow_requests;
CREATE POLICY owner_update ON public.borrow_requests
FOR UPDATE
USING (owner_id::text = public.current_app_user_id())
WITH CHECK (owner_id::text = public.current_app_user_id());

DROP POLICY IF EXISTS delete_own ON public.borrow_requests;
CREATE POLICY delete_own ON public.borrow_requests
FOR DELETE
USING (
  requester_id::text = public.current_app_user_id()
  OR owner_id::text = public.current_app_user_id()
);

-- The permissive policy grants valid access. Restrictive guards prevent any
-- older broad storage policy from bypassing the owner/permission checks.
DROP POLICY IF EXISTS documents_bucket_file_read ON storage.objects;
CREATE POLICY documents_bucket_file_read
ON storage.objects FOR SELECT TO public
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1
          FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level IN ('view', 'edit')
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_read_guard ON storage.objects;
CREATE POLICY documents_bucket_file_read_guard
ON storage.objects AS RESTRICTIVE FOR SELECT TO public
USING (
  bucket_id <> 'documents'
  OR EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1
          FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level IN ('view', 'edit')
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_insert ON storage.objects;
CREATE POLICY documents_bucket_file_insert
ON storage.objects FOR INSERT TO public
WITH CHECK (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_insert_guard ON storage.objects;
CREATE POLICY documents_bucket_file_insert_guard
ON storage.objects AS RESTRICTIVE FOR INSERT TO public
WITH CHECK (
  bucket_id <> 'documents'
  OR EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_update ON storage.objects;
CREATE POLICY documents_bucket_file_update
ON storage.objects FOR UPDATE TO public
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
)
WITH CHECK (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_update_guard ON storage.objects;
CREATE POLICY documents_bucket_file_update_guard
ON storage.objects AS RESTRICTIVE FOR UPDATE TO public
USING (
  bucket_id <> 'documents'
  OR EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
)
WITH CHECK (
  bucket_id <> 'documents'
  OR EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND (
        d.owner_id::text = public.current_app_user_id()
        OR EXISTS (
          SELECT 1 FROM public.permissions p
          WHERE p.document_id = d.id
            AND p.shared_with_user_id::text = public.current_app_user_id()
            AND p.permission_level = 'edit'
        )
      )
  )
);

DROP POLICY IF EXISTS documents_bucket_file_delete ON storage.objects;
CREATE POLICY documents_bucket_file_delete
ON storage.objects FOR DELETE TO public
USING (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND d.owner_id::text = public.current_app_user_id()
  )
);

DROP POLICY IF EXISTS documents_bucket_file_delete_guard ON storage.objects;
CREATE POLICY documents_bucket_file_delete_guard
ON storage.objects AS RESTRICTIVE FOR DELETE TO public
USING (
  bucket_id <> 'documents'
  OR EXISTS (
    SELECT 1
    FROM public.documents d
    WHERE d.id::text = (storage.foldername(name))[1]
      AND d.owner_id::text = public.current_app_user_id()
  )
);
