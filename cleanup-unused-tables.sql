-- ============================================
-- 清理不需要的表（好友功能已移除）
-- 在 Supabase Dashboard 的 SQL Editor 中执行此文件
-- ============================================
-- 注意：此脚本会删除 friend_requests 和 friends 表
-- 如果这些表中有重要数据，请先备份
-- ============================================

-- 删除 friend_requests 表（如果存在）
DROP TABLE IF EXISTS friend_requests CASCADE;

-- 删除 friends 表（如果存在）
DROP TABLE IF EXISTS friends CASCADE;

-- 验证删除结果
SELECT 
  'Remaining tables' as status,
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'chat_messages', 'friend_requests', 'friends')
ORDER BY table_name;

-- ============================================
-- 完成！
-- ============================================
-- 现在数据库中只保留：
-- 1. users - 用户信息
-- 2. chat_messages - 聊天消息
-- ============================================
