-- 快速修复 RLS 策略问题
-- 在 Supabase Dashboard 的 SQL Editor 中执行此文件

-- 如果策略已存在，先删除
DROP POLICY IF EXISTS "Users can view all users" ON users;

-- 创建允许所有用户查看所有用户的策略（用于搜索功能）
CREATE POLICY "Users can view all users" ON users
  FOR SELECT
  USING (true);

-- 验证策略
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
