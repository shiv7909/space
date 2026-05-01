-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRATION: Profile Photos
-- Run this in the Supabase SQL editor
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create the profile_photos table
CREATE TABLE IF NOT EXISTS public.profile_photos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  photo_key   TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT  profile_photos_user_id_key UNIQUE (user_id)
);

ALTER TABLE public.profile_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own photos"
  ON public.profile_photos FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own photos"
  ON public.profile_photos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own photos"
  ON public.profile_photos FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos"
  ON public.profile_photos FOR DELETE
  USING (auth.uid() = user_id);

-- Allow other users to see profile photos (for spaces / member lists)
CREATE POLICY "Anyone can view profile photos"
  ON public.profile_photos FOR SELECT
  USING (true);

-- 2. Add photo_id column to profiles (nullable — null = using avatar)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS photo_id UUID REFERENCES public.profile_photos(id) ON DELETE SET NULL;

-- 3. RPC: update_profile_photo
--    Upserts photo_key in profile_photos, links photo_id on profiles.
--    Returns JSON: { success: true, photo_id: UUID }
CREATE OR REPLACE FUNCTION public.update_profile_photo(p_photo_key TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_photo_id  UUID;
BEGIN
  INSERT INTO public.profile_photos (user_id, photo_key, updated_at)
  VALUES (v_user_id, p_photo_key, NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET photo_key = EXCLUDED.photo_key, updated_at = NOW()
  RETURNING id INTO v_photo_id;

  UPDATE public.profiles
  SET photo_id   = v_photo_id,
      updated_at = NOW()
  WHERE id = v_user_id;

  RETURN json_build_object(
    'success',  true,
    'photo_id', v_photo_id
  );
END;
$$;

-- 4. RPC: delete_profile_photo
--    Clears photo_id, deletes profile_photos row, returns photo_key for Storage cleanup.
--    Returns JSON: { success: true, photo_key: TEXT } or { success: false }
CREATE OR REPLACE FUNCTION public.delete_profile_photo()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_photo_key TEXT;
BEGIN
  -- Get the photo_key before deleting
  SELECT pp.photo_key INTO v_photo_key
  FROM public.profiles pr
  JOIN public.profile_photos pp ON pp.id = pr.photo_id
  WHERE pr.id = v_user_id;

  IF v_photo_key IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'No photo found');
  END IF;

  -- Clear photo_id on profiles first
  UPDATE public.profiles
  SET photo_id   = NULL,
      updated_at = NOW()
  WHERE id = v_user_id;

  -- Delete the profile_photos row
  DELETE FROM public.profile_photos
  WHERE user_id = v_user_id;

  RETURN json_build_object(
    'success',   true,
    'photo_key', v_photo_key
  );
END;
$$;
