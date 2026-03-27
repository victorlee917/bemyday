-- regexp_matches + FROM 별칭 컬럼 접근(42703) 회피: 루프 + 중복 제거
create or replace function public.extract_mention_tokens(p_content text)
returns table (mention text)
language plpgsql
stable
set search_path = public
as $$
declare
  r text[];
  seen text[] := array[]::text[];
  v text;
begin
  for r in select regexp_matches(coalesce(p_content, ''), '@([^\s@]+)', 'g')
  loop
    v := trim(r[1]);
    if v = '' then
      continue;
    end if;
    if v = any(seen) then
      continue;
    end if;
    seen := array_append(seen, v);
    mention := v;
    return next;
  end loop;
  return;
end;
$$;
