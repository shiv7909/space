-- ============================================================
-- create_space RPC
-- Called by Flutter's SpaceService.createSpace() instead of a
-- direct INSERT which is blocked by RLS (code 42501).
--
-- Runs as SECURITY DEFINER so it bypasses RLS entirely and
-- handles the space row + membership row atomically.
--
-- Parameters:
--   p_name  TEXT  — display name for the space
--   p_type  TEXT  — 'solo' | 'couple' | 'group'
--
-- Returns JSON:
--   { "success": true,  "space": { ...space row... } }
--   { "success": false, "message": "..." }
-- ============================================================

CREATE OR REPLACE FUNCTION create_space(
  p_name TEXT,
  p_type TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id  UUID := auth.uid();
  v_space_id UUID;
  v_space    RECORD;
BEGIN
  -- ── Validate caller is authenticated ──────────────────────
  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Not authenticated'
    );
  END IF;

  -- ── Validate type ──────────────────────────────────────────
  IF p_type NOT IN ('solo', 'couple', 'group') THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Invalid space type: ' || p_type
    );
  END IF;

  -- ── Prevent duplicate solo spaces ─────────────────────────
  IF p_type = 'solo' THEN
    SELECT id INTO v_space_id
    FROM spaces
    WHERE created_by = v_user_id
      AND type = 'solo'
    LIMIT 1;

    IF v_space_id IS NOT NULL THEN
      -- Return the existing solo space rather than error
      SELECT * INTO v_space FROM spaces WHERE id = v_space_id;
      RETURN json_build_object(
        'success', true,
        'space',   row_to_json(v_space)
      );
    END IF;
  END IF;

  -- ── Create the space ───────────────────────────────────────
  INSERT INTO spaces (name, type, created_by)
  VALUES (p_name, p_type, v_user_id)
  RETURNING id INTO v_space_id;

  -- ── Add creator as first member ────────────────────────────
  INSERT INTO space_members (space_id, user_id)
  VALUES (v_space_id, v_user_id)
  ON CONFLICT DO NOTHING;

  -- ── Return the full space row ──────────────────────────────
  SELECT * INTO v_space FROM spaces WHERE id = v_space_id;

  RETURN json_build_object(
    'success', true,
    'space',   row_to_json(v_space)
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'message', SQLERRM,
    'code',    SQLSTATE
  );
END;
$$;

-- Grant execute to authenticated users
REVOKE ALL ON FUNCTION create_space(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION create_space(TEXT, TEXT) TO authenticated;


