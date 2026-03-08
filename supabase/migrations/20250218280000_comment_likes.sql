-- comment_likes: 댓글 좋아요
create table public.comment_likes (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index idx_comment_likes_user on public.comment_likes(user_id);
create index idx_comment_likes_comment on public.comment_likes(comment_id);

alter table public.comment_likes enable row level security;

create policy "Members can view comment likes"
  on public.comment_likes for select
  using (
    comment_id in (
      select c.id from public.comments c
      join public.posts p on p.id = c.post_id
      where p.group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );

create policy "Members can like comments"
  on public.comment_likes for all
  using (
    user_id = auth.uid()
    and comment_id in (
      select c.id from public.comments c
      join public.posts p on p.id = c.post_id
      where p.group_id in (select group_id from public.group_members where user_id = auth.uid())
    )
  );
