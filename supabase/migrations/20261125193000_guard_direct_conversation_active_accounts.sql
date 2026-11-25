CREATE OR REPLACE FUNCTION public.tg_open_direct_conversation(p_peer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_user_id uuid := auth.uid();
  v_conversation_id uuid;
begin
  if v_user_id is null then
    raise exception 'Требуется авторизация';
  end if;
  if not private.is_topgram_account_active(v_user_id) then
    raise exception 'Аккаунт не активен';
  end if;
  if p_peer_id is null or p_peer_id = v_user_id then
    raise exception 'Нельзя открыть чат с этим пользователем';
  end if;
  if not private.is_topgram_account_active(p_peer_id) then
    raise exception 'Пользователь не найден или аккаунт не активен';
  end if;
  if exists (select 1 from public.tg_user_blocks b where (b.blocker_id=v_user_id and b.blocked_user_id=p_peer_id) or (b.blocker_id=p_peer_id and b.blocked_user_id=v_user_id)) then
    raise exception 'Невозможно открыть чат: один из пользователей заблокировал другого';
  end if;
  select c.id into v_conversation_id
  from public.tg_conversations c
  join public.tg_conversation_members m1 on m1.conversation_id=c.id and m1.user_id=v_user_id
  join public.tg_conversation_members m2 on m2.conversation_id=c.id and m2.user_id=p_peer_id
  where c.kind='direct'
  limit 1;
  if v_conversation_id is not null then return v_conversation_id; end if;
  insert into public.tg_conversations(kind,created_by) values('direct',v_user_id) returning id into v_conversation_id;
  insert into public.tg_conversation_members(conversation_id,user_id,role)
    values(v_conversation_id,v_user_id,'owner'),(v_conversation_id,p_peer_id,'member');
  return v_conversation_id;
end;
$function$;
