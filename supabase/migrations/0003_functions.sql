-- 0003_functions.sql
-- RPC: create_tournament, select_match_winner, toggle_match_bonus,
--      complete_tournament, reopen_tournament + helper interni

-- ==========================================================
-- helper: nome turno in base a squadre rimaste nel turno (main bracket)
-- ==========================================================
create or replace function round_name_for(p_matches_in_round integer)
returns text
language sql
immutable
as $$
	select case p_matches_in_round
		when 32 then 'Trentaduesimi di finale'
		when 16 then 'Sedicesimi di finale'
		when 8 then 'Ottavi di finale'
		when 4 then 'Quarti di finale'
		when 2 then 'Semifinali'
		when 1 then 'Finale'
		else 'Turno'
	end;
$$;

-- ==========================================================
-- create_tournament
-- ==========================================================
create or replace function create_tournament(
	p_name text,
	p_size integer,
	p_draw_mode text,
	p_team_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_tournament_id uuid;
	v_ordered_ids uuid[];
	v_rounds integer;
	v_round integer;
	v_matches_in_round integer;
	v_match_number integer;
	v_final_match_id uuid;
	v_third_place_id uuid;
	v_prev_match_ids uuid[];
	v_this_match_ids uuid[];
	v_id uuid;
	v_team_a uuid;
	v_team_b uuid;
	v_distinct_count integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if p_size not in (32, 64) then
		raise exception 'INVALID_SIZE: must be 32 or 64';
	end if;

	if p_team_ids is null or array_length(p_team_ids, 1) <> p_size then
		raise exception 'INVALID_TEAM_COUNT: expected % teams, got %', p_size, coalesce(array_length(p_team_ids, 1), 0);
	end if;

	select count(distinct t) into v_distinct_count from unnest(p_team_ids) as t;
	if v_distinct_count <> p_size then
		raise exception 'DUPLICATE_TEAMS';
	end if;

	if p_draw_mode not in ('random', 'manual') then
		raise exception 'INVALID_DRAW_MODE';
	end if;

	-- ordine dei seed: casuale o rispetta l'ordine passato dal client (manuale)
	if p_draw_mode = 'random' then
		select array_agg(t order by random()) into v_ordered_ids from unnest(p_team_ids) as t;
	else
		v_ordered_ids := p_team_ids;
	end if;

	insert into tournaments (user_id, name, size, status, draw_mode, started_at)
	values (v_user_id, p_name, p_size, 'active', p_draw_mode, now())
	returning id into v_tournament_id;

	insert into tournament_teams (tournament_id, team_id, seed_position)
	select v_tournament_id, team_id, ord
	from unnest(v_ordered_ids) with ordinality as u(team_id, ord);

	-- ==================================================
	-- generazione turno 1: coppie consecutive di seed (1v2, 3v4, ...)
	-- ==================================================
	v_matches_in_round := p_size / 2;
	v_this_match_ids := array[]::uuid[];

	for v_match_number in 1..v_matches_in_round loop
		select team_id into v_team_a from tournament_teams where tournament_id = v_tournament_id and seed_position = (v_match_number - 1) * 2 + 1;
		select team_id into v_team_b from tournament_teams where tournament_id = v_tournament_id and seed_position = (v_match_number - 1) * 2 + 2;

		insert into matches (
			tournament_id, round_number, round_name, match_number, bracket_type,
			team_a_id, team_b_id, status
		) values (
			v_tournament_id, 1, round_name_for(v_matches_in_round), v_match_number, 'main',
			v_team_a, v_team_b, 'ready'
		)
		returning id into v_id;

		v_this_match_ids := array_append(v_this_match_ids, v_id);
	end loop;

	v_prev_match_ids := v_this_match_ids;
	v_rounds := 1;
	v_matches_in_round := v_matches_in_round / 2;
	v_round := 2;

	-- ==================================================
	-- turni successivi: partite vuote, collegate al turno precedente
	-- ==================================================
	while v_matches_in_round >= 1 loop
		v_this_match_ids := array[]::uuid[];

		for v_match_number in 1..v_matches_in_round loop
			insert into matches (
				tournament_id, round_number, round_name, match_number, bracket_type, status
			) values (
				v_tournament_id, v_round, round_name_for(v_matches_in_round), v_match_number, 'main', 'pending'
			)
			returning id into v_id;

			v_this_match_ids := array_append(v_this_match_ids, v_id);
		end loop;

		-- collega ogni partita del turno precedente alla partita corrispondente di questo turno
		for v_match_number in 1..array_length(v_prev_match_ids, 1) loop
			update matches
			set next_match_id = v_this_match_ids[((v_match_number - 1) / 2) + 1],
				next_match_slot = case when v_match_number % 2 = 1 then 'A' else 'B' end
			where id = v_prev_match_ids[v_match_number];
		end loop;

		if v_matches_in_round = 1 then
			v_final_match_id := v_this_match_ids[1];
		end if;

		v_prev_match_ids := v_this_match_ids;
		v_round := v_round + 1;
		exit when v_matches_in_round = 1;
		v_matches_in_round := v_matches_in_round / 2;
	end loop;

	-- ==================================================
	-- finale terzo/quarto posto: stesso round_number della finale
	-- ==================================================
	select round_number into v_round from matches where id = v_final_match_id;

	insert into matches (
		tournament_id, round_number, round_name, match_number, bracket_type, status
	) values (
		v_tournament_id, v_round, 'Finale 3°/4° posto', 1, 'third_place', 'pending'
	)
	returning id into v_third_place_id;

	return v_tournament_id;
end;
$$;

-- ==========================================================
-- helper interno: azzera il risultato di una partita e propaga
-- l'invalidazione a valle (usato per correggere risultati passati)
-- ==========================================================
create or replace function clear_match_result(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	m matches%rowtype;
begin
	select * into m from matches where id = p_match_id;
	if not found then
		return;
	end if;

	if m.status <> 'completed' and m.winner_team_id is null then
		return; -- niente da annullare
	end if;

	-- propaga l'invalidazione al turno successivo prima di azzerare questa partita
	if m.next_match_id is not null and m.winner_team_id is not null then
		update matches
		set team_a_id = case when next_match_slot = 'A' then null else team_a_id end,
			team_b_id = case when next_match_slot = 'B' then null else team_b_id end
		from (select next_match_slot from matches where id = p_match_id) s
		where matches.id = m.next_match_id;

		perform clear_match_result(m.next_match_id);
	end if;

	-- se questa partita era una semifinale, azzera anche lo slot nella finalina
	perform clear_third_place_slot(m.id);

	delete from point_events where match_id = m.id and event_type in ('match_win', 'match_bonus');
	delete from match_bonuses where match_id = m.id;

	update matches
	set winner_team_id = null,
		loser_team_id = null,
		played_at = null,
		status = case when team_a_id is not null and team_b_id is not null then 'ready' else 'pending' end
	where id = m.id;
end;
$$;

-- ==========================================================
-- helper interno: se p_match_id e' una semifinale, ripulisce lo
-- slot corrispondente nella finalina (terzo/quarto posto)
-- ==========================================================
create or replace function clear_third_place_slot(p_semifinal_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	sf matches%rowtype;
	tp matches%rowtype;
begin
	select * into sf from matches where id = p_semifinal_id and bracket_type = 'main';
	if not found then
		return;
	end if;

	-- e' semifinale solo se il turno successivo e' la finale (next match senza ulteriore next)
	if sf.next_match_id is null then
		return;
	end if;

	select * into tp
	from matches
	where tournament_id = sf.tournament_id
		and bracket_type = 'third_place'
		and round_number = (select round_number from matches where id = sf.next_match_id);

	if not found then
		return;
	end if;

	update matches
	set team_a_id = case when sf.match_number = 1 then null else team_a_id end,
		team_b_id = case when sf.match_number = 2 then null else team_b_id end
	where id = tp.id;

	if tp.status = 'completed' then
		perform clear_match_result(tp.id);
	else
		update matches
		set status = case when team_a_id is not null and team_b_id is not null then 'ready' else 'pending' end
		where id = tp.id;
	end if;
end;
$$;

-- ==========================================================
-- select_match_winner
-- ==========================================================
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

	select m.* into m
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.id = p_match_id and t.user_id = v_user_id
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

	-- correzione di un risultato gia' esistente: invalida tutto cio' che
	-- dipendeva dal vecchio vincitore prima di applicare il nuovo
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

	-- propaga il vincitore al turno successivo
	if m.next_match_id is not null then
		update matches
		set team_a_id = case when m.next_match_slot = 'A' then p_winner_team_id else team_a_id end,
			team_b_id = case when m.next_match_slot = 'B' then p_winner_team_id else team_b_id end
		where id = m.next_match_id;

		select * into v_next from matches where id = m.next_match_id;

		update matches
		set status = case when v_next.team_a_id is not null and v_next.team_b_id is not null then 'ready' else status end
		where id = m.next_match_id;

		-- e' semifinale se il turno successivo e' la finale (bracket_type main, ultimo turno)
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

-- ==========================================================
-- toggle_match_bonus
-- ==========================================================
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

	select m.* into m
	from matches m
	join tournaments t on t.id = m.tournament_id
	where m.id = p_match_id and t.user_id = v_user_id;

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

-- ==========================================================
-- complete_tournament
-- ==========================================================
create or replace function complete_tournament(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	t tournaments%rowtype;
	v_final matches%rowtype;
	v_third matches%rowtype;
	v_champion uuid;
	v_runner_up uuid;
	v_third_place uuid;
	v_fourth_place uuid;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select * into t from tournaments where id = p_tournament_id and user_id = v_user_id for update;
	if not found then
		raise exception 'TOURNAMENT_NOT_FOUND_OR_FORBIDDEN';
	end if;

	select * into v_final from matches
	where tournament_id = p_tournament_id and bracket_type = 'main' and next_match_id is null;

	select * into v_third from matches
	where tournament_id = p_tournament_id and bracket_type = 'third_place';

	if v_final.status <> 'completed' or v_third.status <> 'completed' then
		raise exception 'TOURNAMENT_NOT_READY: final e finalina devono essere entrambe complete';
	end if;

	v_champion := v_final.winner_team_id;
	v_runner_up := v_final.loser_team_id;
	v_third_place := v_third.winner_team_id;
	v_fourth_place := v_third.loser_team_id;

	update tournament_teams set final_position = 1, placement_points = 7 where tournament_id = p_tournament_id and team_id = v_champion;
	update tournament_teams set final_position = 2, placement_points = 5 where tournament_id = p_tournament_id and team_id = v_runner_up;
	update tournament_teams set final_position = 3, placement_points = 1 where tournament_id = p_tournament_id and team_id = v_third_place;
	update tournament_teams set final_position = 4, placement_points = 0 where tournament_id = p_tournament_id and team_id = v_fourth_place;

	insert into point_events (user_id, tournament_id, team_id, event_type, points, metadata)
	values
		(v_user_id, p_tournament_id, v_champion, 'placement_bonus', 7, jsonb_build_object('position', 1)),
		(v_user_id, p_tournament_id, v_runner_up, 'placement_bonus', 5, jsonb_build_object('position', 2)),
		(v_user_id, p_tournament_id, v_third_place, 'placement_bonus', 1, jsonb_build_object('position', 3)),
		(v_user_id, p_tournament_id, v_fourth_place, 'placement_bonus', 0, jsonb_build_object('position', 4))
	on conflict (tournament_id, team_id) where event_type = 'placement_bonus' do nothing;

	update tournaments
	set status = 'completed',
		completed_at = now(),
		champion_team_id = v_champion,
		runner_up_team_id = v_runner_up,
		third_team_id = v_third_place,
		fourth_team_id = v_fourth_place
	where id = p_tournament_id;
end;
$$;

-- ==========================================================
-- reopen_tournament
-- ==========================================================
create or replace function reopen_tournament(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if not exists (select 1 from tournaments where id = p_tournament_id and user_id = v_user_id) then
		raise exception 'TOURNAMENT_NOT_FOUND_OR_FORBIDDEN';
	end if;

	delete from point_events where tournament_id = p_tournament_id and event_type = 'placement_bonus';

	update tournament_teams set final_position = null, placement_points = 0 where tournament_id = p_tournament_id;

	update tournaments
	set status = 'active',
		completed_at = null,
		champion_team_id = null,
		runner_up_team_id = null,
		third_team_id = null,
		fourth_team_id = null
	where id = p_tournament_id;
end;
$$;
