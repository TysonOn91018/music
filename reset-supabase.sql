-- ============================================
-- Supabase 完全重置脚本
-- 在 Supabase Dashboard 的 SQL Editor 中执行此文件
-- ============================================
-- ⚠️ 警告：此脚本会删除所有现有数据！
-- 包括：users, chat_messages, friend_requests, friends
-- ============================================

-- ============================================
-- 1. 删除所有现有表（按依赖顺序）
-- ============================================

-- 删除聊天消息表
DROP TABLE IF EXISTS chat_messages CASCADE;

-- 删除好友相关表（如果存在）
DROP TABLE IF EXISTS friend_requests CASCADE;
DROP TABLE IF EXISTS friends CASCADE;

-- 删除用户表（最后删除，因为其他表可能依赖它）
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- 2. 重新创建 users 表
-- ============================================

CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  name text,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 3. 重新创建 chat_messages 表
-- ============================================

CREATE TABLE chat_messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id text NOT NULL,
  user_id text NOT NULL,
  user_name text NOT NULL,
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 4. 启用 Row Level Security (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. 创建 RLS 策略：users 表
-- ============================================

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
-- 6. 创建 RLS 策略：chat_messages 表
-- ============================================

-- 允许所有人读取聊天消息（同一房间的人可以看到消息）
CREATE POLICY "Users can read chat messages" ON chat_messages
  FOR SELECT
  USING (true);

-- 允许所有人插入聊天消息（登录用户可以发送消息）
CREATE POLICY "Users can insert chat messages" ON chat_messages
  FOR INSERT
  WITH CHECK (true);

-- ============================================
-- 7. 启用 Realtime（用于聊天功能）
-- ============================================

-- 安全地添加表到 Realtime
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
    RAISE NOTICE 'chat_messages テーブルを Realtime に追加しました。';
  ELSE
    RAISE NOTICE 'chat_messages テーブルは既に Realtime に追加されています。';
  END IF;
END $$;

-- ============================================
-- 8. 创建索引（提高查询性能）
-- ============================================

-- chat_messages 表的索引
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id_created_at ON chat_messages(room_id, created_at);

-- users 表的索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);

-- ============================================
-- 9. 验证设置
-- ============================================

-- 检查表是否创建成功
SELECT 
  'Tables created' as status,
  table_name,
  CASE 
    WHEN table_name = 'users' THEN '✓ 用户表'
    WHEN table_name = 'chat_messages' THEN '✓ 聊天消息表'
    ELSE '?'
  END as description
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'chat_messages')
ORDER BY table_name;

-- 检查 RLS 是否启用
SELECT 
  'RLS status' as status,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✓ 已启用'
    ELSE '✗ 未启用'
  END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'chat_messages')
ORDER BY tablename;

-- 检查 Realtime 是否启用
SELECT 
  'Realtime status' as status,
  tablename,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND tablename = 'chat_messages'
    ) THEN '✓ 已启用'
    ELSE '✗ 未启用'
  END as realtime_status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'chat_messages';

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
-- 数据库已完全重置并重新设置。
-- 
-- 现在你的数据库包含：
-- 1. users 表 - 用户信息（登录/注册）
-- 2. chat_messages 表 - 聊天消息
-- 
-- 所有 RLS 策略和 Realtime 都已正确配置。
-- 
-- 如果遇到问题，请检查：
-- 1. Supabase Dashboard → Database → Realtime 是否启用
-- 2. 浏览器控制台的错误信息
-- 3. Network 标签页中的请求状态
-- ============================================
