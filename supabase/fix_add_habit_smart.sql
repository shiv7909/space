-- ============================================================
-- FIX: add_habit_smart
-- Error: column "role" of relation "space_members" does not exist (42703)
--
-- The previous version tried to INSERT a "role" column into
-- space_members which doesn't exist in the schema.
-- This corrected version removes that reference.
--
-- Run this in the Supabase SQL Editor to apply the fix.
-- ============================================================

CREATE OR REPLACE FUNCTION add_habit_smart(
  p_name          TEXT,
  p_why_reason    TEXT    DEFAULT NULL,
  p_emoji         TEXT    DEFAULT '🔥',
  p_mode          TEXT    DEFAULT 'infinite',
  p_target_days   INT     DEFAULT NULL,
  p_scheduled_days INT[]  DEFAULT ARRAY[1,2,3,4,5,6,7],
  p_space_id      UUID    DEFAULT NULL,
  p_category_id   UUID    DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_space_id  UUID;
  v_habit_id  UUID;
  v_habit     RECORD;
BEGIN
  -- ── Auth check ────────────────────────────────────────────
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Not authenticated');
  END IF;

  -- ── Resolve space ─────────────────────────────────────────
  IF p_space_id IS NOT NULL THEN
    -- Verify the caller is actually a member of this space
    IF NOT EXISTS (
      SELECT 1 FROM space_members
      WHERE space_id = p_space_id AND user_id = v_user_id
    ) THEN
      RETURN json_build_object('success', false, 'message', 'You are not a member of this space');
    END IF;
    v_space_id := p_space_id;
  ELSE
    -- Default to the caller's solo space
    SELECT id INTO v_space_id
    FROM spaces
    WHERE created_by = v_user_id AND type = 'solo'
    LIMIT 1;

    IF v_space_id IS NULL THEN
      RETURN json_build_object('success', false, 'message', 'No solo space found. Please complete onboarding.');
    END IF;
  END IF;

  -- ── Duplicate name guard ──────────────────────────────────
  IF EXISTS (
    SELECT 1 FROM habits
    WHERE space_id = v_space_id
      AND name    = p_name
      AND is_archived = false
  ) THEN
    RETURN json_build_object(
      'success', false,
      'code',    '23505',
      'message', 'A habit with this name already exists in this space.'
    );
  END IF;

  -- ── Insert habit ──────────────────────────────────────────
  INSERT INTO habits (
    space_id,
    created_by,
    name,
    why_reason,
    emoji,
    mode,
    target_days,
    scheduled_days,
    category_id,
    is_archived
  ) VALUES (
    v_space_id,
    v_user_id,
    p_name,
    p_why_reason,
    p_emoji,
    p_mode,
    p_target_days,
    p_scheduled_days,
    p_category_id,
    false
  )
  RETURNING id INTO v_habit_id;

  SELECT * INTO v_habit FROM habits WHERE id = v_habit_id;

  RETURN json_build_object(
    'success',    true,
    'habit_id',   v_habit_id,
    'space_id',   v_space_id,
    'space_type', (SELECT type FROM spaces WHERE id = v_space_id),
    'habit',      row_to_json(v_habit)
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'code',    SQLSTATE,
    'message', SQLERRM
  );
END;
$$;

-- Grant execute to authenticated users
REVOKE ALL ON FUNCTION add_habit_smart(TEXT, TEXT, TEXT, TEXT, INT, INT[], UUID, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION add_habit_smart(TEXT, TEXT, TEXT, TEXT, INT, INT[], UUID, UUID) TO authenticated;
