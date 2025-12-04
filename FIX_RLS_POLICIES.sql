-- ============================================================================
-- FIX RLS POLICIES - Remove infinite recursion
-- ============================================================================

-- Drop problematic policies
DROP POLICY IF EXISTS "Teachers can view own record" ON teachers;
DROP POLICY IF EXISTS "Teachers can update own record" ON teachers;
DROP POLICY IF EXISTS "Admins can view all teachers" ON teachers;

-- Create new policies without recursion
CREATE POLICY "Teachers can view own record"
  ON teachers FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Teachers can update own record"
  ON teachers FOR UPDATE
  USING (auth.uid() = id);

-- For now, disable admin viewing all teachers to avoid recursion
-- Admins can still view their own record via the first policy
