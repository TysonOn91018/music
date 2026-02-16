-- ============================================
-- 保存歌曲功能 - 数据库设置
-- 在 Supabase Dashboard 的 SQL Editor 中执行此文件
-- ============================================

-- ============================================
-- 1. 创建 saved_songs 表（保存的歌曲）
-- ============================================
CREATE TABLE IF NOT EXISTS saved_songs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  track_title text NOT NULL,
  track_url text NOT NULL,
  track_artist text,
  mood text,
  saved_at timestamptz DEFAULT now(),
  UNIQUE(user_id, track_url) -- 防止重复保存同一首歌
);

-- ============================================
-- 2. 启用 Row Level Security (RLS)
-- ============================================
ALTER TABLE saved_songs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. RLS 策略：saved_songs 表
-- ============================================

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Users can view own saved songs" ON saved_songs;
DROP POLICY IF EXISTS "Users can insert own saved songs" ON saved_songs;
DROP POLICY IF EXISTS "Users can delete own saved songs" ON saved_songs;

-- 用户只能查看自己保存的歌曲
CREATE POLICY "Users can view own saved songs" ON saved_songs
  FOR SELECT
  USING (auth.uid() = user_id);

-- 用户只能保存歌曲到自己的列表
CREATE POLICY "Users can insert own saved songs" ON saved_songs
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 用户只能删除自己保存的歌曲
CREATE POLICY "Users can delete own saved songs" ON saved_songs
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 4. 创建索引（提高查询性能）
-- ============================================
CREATE INDEX IF NOT EXISTS idx_saved_songs_user_id ON saved_songs(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_songs_saved_at ON saved_songs(saved_at DESC);

-- ============================================
-- 5. 验证设置
-- ============================================
SELECT 
  'saved_songs table created' as status,
  COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'saved_songs';

SELECT 
  'RLS status' as status,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'saved_songs';

SELECT 
  'Policies' as status,
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'saved_songs'
ORDER BY policyname;

-- ============================================
-- 完成！
-- ============================================
-- 执行此脚本后，用户可以：
-- 1. 保存喜欢的歌曲
-- 2. 在"我的页面"查看保存的歌曲列表
-- 3. 取消保存歌曲
-- ============================================
