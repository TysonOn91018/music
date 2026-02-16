# Supabase 设置指南

## 📋 设置步骤

### 1. 确认 Supabase 项目配置

你的 Supabase 配置已经在 `index.html` 中设置好了：
- URL: `https://nlavqjsztdfxksjusyky.supabase.co`
- Anon Key: 已配置

### 2. 创建数据库表

在 Supabase Dashboard 中执行以下步骤：

1. 打开 Supabase Dashboard: https://supabase.com/dashboard
2. 选择你的项目
3. 进入 **SQL Editor** (左侧菜单)
4. 点击 **New Query**
5. 复制并执行 `friends-setup.sql` 文件中的所有 SQL 语句

或者直接执行以下 SQL：

```sql
-- 1. 创建 users 表（存储用户信息）
create table if not exists users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text,
  created_at timestamptz default now()
);

-- 2. 创建 friend_requests 表（好友请求）
create table if not exists friend_requests (
  id uuid default gen_random_uuid() primary key,
  from_user_id uuid not null references users(id) on delete cascade,
  to_user_id uuid not null references users(id) on delete cascade,
  status text not null default 'pending', -- 'pending' | 'accepted' | 'rejected'
  created_at timestamptz default now(),
  unique(from_user_id, to_user_id)
);

-- 3. 创建 friends 表（好友关系）
create table if not exists friends (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references users(id) on delete cascade,
  friend_id uuid not null references users(id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, friend_id)
);

-- 4. 启用 Realtime（可选，用于实时通知）
alter publication supabase_realtime add table friend_requests;
alter publication supabase_realtime add table friends;

-- 5. 设置 Row Level Security (RLS)
alter table users enable row level security;
alter table friend_requests enable row level security;
alter table friends enable row level security;
```

### 3. 设置 RLS (Row Level Security) 策略

继续在 SQL Editor 中执行以下 SQL：

```sql
-- 6. RLS 策略：用户可以查看自己的信息
create policy "Users can view own profile" on users
  for select using (auth.uid() = id);

-- 7. RLS 策略：用户可以更新自己的信息
create policy "Users can update own profile" on users
  for update using (auth.uid() = id);

-- 8. RLS 策略：用户可以插入自己的信息
create policy "Users can insert own profile" on users
  for insert with check (auth.uid() = id);

-- 9. RLS 策略：用户可以查看所有用户（用于搜索）⭐ 重要！
create policy "Users can view all users" on users
  for select using (true);

-- 10. RLS 策略：用户可以查看自己收到或发送的好友请求
create policy "Users can view own requests" on friend_requests
  for select using (auth.uid() = from_user_id or auth.uid() = to_user_id);

-- 11. RLS 策略：用户可以发送好友请求
create policy "Users can send requests" on friend_requests
  for insert with check (auth.uid() = from_user_id);

-- 12. RLS 策略：用户可以更新自己收到的请求
create policy "Users can update received requests" on friend_requests
  for update using (auth.uid() = to_user_id);

-- 13. RLS 策略：用户可以查看自己的好友列表
create policy "Users can view own friends" on friends
  for select using (auth.uid() = user_id);

-- 14. RLS 策略：用户可以添加好友
create policy "Users can add friends" on friends
  for insert with check (auth.uid() = user_id);
```

### 4. 验证设置

在 SQL Editor 中执行以下查询来验证表是否创建成功：

```sql
-- 检查表是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'friend_requests', 'friends');

-- 检查 RLS 策略
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('users', 'friend_requests', 'friends')
ORDER BY tablename, policyname;
```

## ✅ 检查清单

- [ ] 已创建 `users` 表
- [ ] 已创建 `friend_requests` 表
- [ ] 已创建 `friends` 表
- [ ] 已启用 RLS 对所有表
- [ ] 已创建所有 RLS 策略（特别是 "Users can view all users" 策略）
- [ ] 已启用 Realtime（可选）

## 🔧 如果遇到问题

### 问题：无法搜索用户

如果搜索用户时出现错误，执行 `fix-rls-policy.sql` 中的 SQL：

```sql
-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Users can view all users" ON users;

-- 重新创建策略
CREATE POLICY "Users can view all users" ON users
  FOR SELECT
  USING (true);
```

### 问题：无法创建用户记录

确保 `users` 表的 RLS 策略允许用户插入自己的记录（策略 #8）。

## 📝 注意事项

1. **重要**：策略 #9 "Users can view all users" 是必需的，否则无法搜索其他用户
2. 用户注册/登录时，系统会自动在 `users` 表中创建记录
3. 如果表已存在，使用 `create table if not exists` 不会报错，可以安全执行

## 🚀 完成设置后

设置完成后，你可以：
1. 注册新用户
2. 登录
3. 搜索其他用户
4. 发送好友请求
5. 接受/拒绝好友请求
6. 查看好友列表
