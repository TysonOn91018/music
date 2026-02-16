-- 好友系统所需表结构
-- 在 Supabase SQL Editor 中执行以下 SQL

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

-- 6. RLS 策略：用户可以查看自己的信息
create policy "Users can view own profile" on users
  for select using (auth.uid() = id);

-- 7. RLS 策略：用户可以更新自己的信息
create policy "Users can update own profile" on users
  for update using (auth.uid() = id);

-- 8. RLS 策略：用户可以插入自己的信息
create policy "Users can insert own profile" on users
  for insert with check (auth.uid() = id);

-- 9. RLS 策略：用户可以查看所有用户（用于搜索）
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
