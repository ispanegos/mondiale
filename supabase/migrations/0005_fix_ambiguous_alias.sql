-- 0005_fix_ambiguous_alias.sql
-- Corregge "column reference is ambiguous": la variabile plpgsql "m" e
-- l'alias di tabella "m" nella stessa query si confondevano tra loro.
-- Rieseguibile in sicurezza (create or replace).

create or replace function select_match_winner(p_match_id uuid, p_winner_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	m matches%rowtype;
	v_loser uuid;
	v_next matches%rowtype;
	v_is_semifinal boolean := false;
	v_third_place_id uuid;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select mm.* into m
	from matches mm
	join tournaments t on t.id = mm.tournament_id
	where mm.id = p_match_id and t.user_id = v_user_id
	for update;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_winner_team_id is distinct from m.team_a_id and p_winner_team_id is distinct from m.team_b_id then
		raise exception 'WINNER_NOT_IN_MATCH';
	end if;

	if m.team_a_id is null or m.team_b_id is null then
		raise exception 'MATCH_NOT_READY';
	end if;

	if m.status = 'completed' and m.winner_team_id is distinct from p_winner_team_id then
		if m.next_match_id is not null then
			update matches
			set team_a_id = case when m.next_match_slot = 'A' then null else team_a_id end,
				team_b_id = case when m.next_match_slot = 'B' then null else team_b_id end
			where id = m.next_match_id;

			perform clear_match_result(m.next_match_id);
		end if;

		perform clear_third_place_slot(m.id);

		delete from point_events where match_id = m.id and event_type = 'match_win';
	end if;

	v_loser := case when p_winner_team_id = m.team_a_id then m.team_b_id else m.team_a_id end;

	update matches
	set winner_team_id = p_winner_team_id,
		loser_team_id = v_loser,
		status = 'completed',
		played_at = now()
	where id = m.id;

	insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, metadata)
	values (v_user_id, m.tournament_id, p_winner_team_id, m.id, 'match_win', 3, jsonb_build_object('round_name', m.round_name))
	on conflict (match_id, team_id) where event_type = 'match_win' do nothing;

	if m.next_match_id is not null then
		update matches
		set team_a_id = case when m.next_match_slot = 'A' then p_winner_team_id else team_a_id end,
			team_b_id = case when m.next_match_slot = 'B' then p_winner_team_id else team_b_id end
		where id = m.next_match_id;

		select * into v_next from matches where id = m.next_match_id;

		update matches
		set status = case when v_next.team_a_id is not null and v_next.team_b_id is not null then 'ready' else status end
		where id = m.next_match_id;

		select true into v_is_semifinal
		from matches
		where id = m.next_match_id and next_match_id is null and bracket_type = 'main';
	end if;

	if v_is_semifinal then
		select id into v_third_place_id
		from matches
		where tournament_id = m.tournament_id
			and bracket_type = 'third_place'
			and round_number = (select round_number from matches where id = m.next_match_id);

		if v_third_place_id is not null then
			update matches
			set team_a_id = case when m.match_number = 1 then v_loser else team_a_id end,
				team_b_id = case when m.match_number = 2 then v_loser else team_b_id end
			where id = v_third_place_id;

			update matches
			set status = case when team_a_id is not null and team_b_id is not null then 'ready' else 'pending' end
			where id = v_third_place_id;
		end if;
	end if;
end;
$$;

create or replace function toggle_match_bonus(p_match_id uuid, p_team_id uuid, p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	m matches%rowtype;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select mm.* into m
	from matches mm
	join tournaments t on t.id = mm.tournament_id
	where mm.id = p_match_id and t.user_id = v_user_id;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_team_id is distinct from m.team_a_id and p_team_id is distinct from m.team_b_id then
		raise exception 'TEAM_NOT_IN_MATCH';
	end if;

	if p_enabled then
		insert into match_bonuses (match_id, team_id, points)
		values (p_match_id, p_team_id, 1)
		on conflict (match_id, team_id) do nothing;

		insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points)
		values (v_user_id, m.tournament_id, p_team_id, p_match_id, 'match_bonus', 1)
		on conflict (match_id, team_id) where event_type = 'match_bonus' do nothing;
	else
		delete from match_bonuses where match_id = p_match_id and team_id = p_team_id;
		delete from point_events
		where match_id = p_match_id and team_id = p_team_id and event_type = 'match_bonus';
	end if;
end;
$$;
