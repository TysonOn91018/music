-- ============================================
-- Mood Player 网站完整数据库设置
-- 在 Supabase Dashboard 的 SQL Editor 中执行此文件
-- ============================================

-- ============================================
-- 1. 创建 users 表（用户信息）
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  name text,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 2. 创建 chat_messages 表（聊天消息）
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id text NOT NULL,
  user_id text NOT NULL,
  user_name text NOT NULL,
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 3. 启用 Row Level Security (RLS)
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. 启用 Realtime（用于聊天功能）
-- ============================================
-- 安全地添加表到 Realtime（如果已存在则跳过）
DO $$
BEGIN
  -- 检查表是否已经在 Realtime 中
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
  END IF;
END $$;

-- ============================================
-- 5. RLS 策略：users 表
-- ============================================

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view all users" ON users;

-- 用户可以查看自己的信息
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT
  USING (auth.uid() = id);

-- 用户可以更新自己的信息
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE
  USING (auth.uid() = id);

-- 用户可以插入自己的信息
CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 用户可以查看所有用户（用于搜索功能，如果需要的话）
CREATE POLICY "Users can view all users" ON users
  FOR SELECT
  USING (true);

-- ============================================
-- 6. RLS 策略：chat_messages 表
-- ============================================

-- 删除可能存在的旧策略
DROP POLICY IF EXISTS "Allow all for chat_messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can read chat messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert chat messages" ON chat_messages;

-- 允许所有人读取聊天消息（同一房间的人可以看到消息）
CREATE POLICY "Users can read chat messages" ON chat_messages
  FOR SELECT
  USING (true);

-- 允许所有人插入聊天消息（登录用户可以发送消息）
CREATE POLICY "Users can insert chat messages" ON chat_messages
  FOR INSERT
  WITH CHECK (true);

-- ============================================
-- 7. 创建索引（提高查询性能）
-- ============================================

-- chat_messages 表的索引
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- users 表的索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================
-- 8. 验证设置
-- ============================================

-- 检查表是否创建成功
SELECT 
  'Tables created' as status,
  COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'chat_messages');

-- 检查 RLS 是否启用
SELECT 
  'RLS status' as status,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'chat_messages');

-- 检查 Realtime 是否启用
SELECT 
  'Realtime status' as status,
  schemaname,
  tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename IN ('chat_messages');

-- 检查策略
SELECT 
  'Policies' as status,
  tablename,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'chat_messages')
ORDER BY tablename, policyname;

-- ============================================
-- 完成！
-- ============================================
-- 执行此脚本后，你的网站应该可以正常使用：
-- 1. 用户登录/注册功能
-- 2. 聊天功能（需要至少2人同时听同一首歌）
-- 
-- 如果遇到问题，请检查：
-- 1. Supabase Dashboard → Database → Realtime 是否启用
-- 2. 浏览器控制台的错误信息
-- 3. Network 标签页中的请求状态
-- ============================================
