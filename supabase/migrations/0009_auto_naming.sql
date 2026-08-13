-- 0009_auto_naming.sql
-- Rinomina automatica dei tornei: "ED n" per eliminazione diretta, "Swiss n"
-- per svizzero, con numerazione sequenziale automatica per formato.
-- Rinomina anche i 13 tornei eliminazione diretta gia' esistenti (ED 1..ED 13,
-- in ordine di creazione) e fa partire la numerazione svizzero da 1.

-- ==========================================================
-- 1. Rinomina i tornei knockout esistenti in ordine di creazione
-- ==========================================================
with numbered as (
	select id, row_number() over (order by created_at) as rn
	from tournaments
	where format = 'knockout'
)
update tournaments t
set name = 'ED ' || numbered.rn
from numbered
where t.id = numbered.id;

-- ==========================================================
-- 2. Sequenze per la numerazione futura (ED riparte dal prossimo numero
--    libero dopo quelli appena rinominati, Swiss parte da 1)
-- ==========================================================
do $$
declare
	v_ed_next integer;
begin
	select coalesce(max(row_number), 0) + 1 into v_ed_next
	from (
		select row_number() over (order by created_at) as row_number
		from tournaments where format = 'knockout'
	) x;

	if v_ed_next is null then
		v_ed_next := 1;
	end if;

	execute format('create sequence if not exists tournament_ed_seq start with %s', v_ed_next);
end;
$$;

create sequence if not exists tournament_swiss_seq start with 1;

-- ==========================================================
-- 3. create_tournament: firma senza p_name, nome auto-generato "ED n"
-- ==========================================================
drop function if exists create_tournament(text, integer, text, uuid[]);

create or replace function create_tournament(
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
	v_name text;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if p_size not in (8, 16, 32, 64) then
		raise exception 'INVALID_SIZE: must be 8, 16, 32 or 64';
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

	if p_draw_mode = 'random' then
		select array_agg(t order by random()) into v_ordered_ids from unnest(p_team_ids) as t;
	else
		v_ordered_ids := p_team_ids;
	end if;

	v_name := 'ED ' || nextval('tournament_ed_seq');

	insert into tournaments (user_id, name, size, status, draw_mode, format, started_at)
	values (v_user_id, v_name, p_size, 'active', p_draw_mode, 'knockout', now())
	returning id into v_tournament_id;

	insert into tournament_teams (tournament_id, team_id, seed_position)
	select v_tournament_id, team_id, ord
	from unnest(v_ordered_ids) with ordinality as u(team_id, ord);

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
	v_matches_in_round := v_matches_in_round / 2;
	v_round := 2;

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
-- 4. create_swiss_tournament: firma senza p_name, nome auto-generato "Swiss n"
-- ==========================================================
drop function if exists create_swiss_tournament(text, uuid[]);

create or replace function create_swiss_tournament(
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
	v_distinct_count integer;
	v_match_number integer;
	v_name text;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	if p_team_ids is null or array_length(p_team_ids, 1) <> 64 then
		raise exception 'INVALID_TEAM_COUNT: il formato svizzero richiede esattamente 64 squadre, ricevute %', coalesce(array_length(p_team_ids, 1), 0);
	end if;

	select count(distinct t) into v_distinct_count from unnest(p_team_ids) as t;
	if v_distinct_count <> 64 then
		raise exception 'DUPLICATE_TEAMS';
	end if;

	select array_agg(t order by random()) into v_ordered_ids from unnest(p_team_ids) as t;

	v_name := 'Swiss ' || nextval('tournament_swiss_seq');

	insert into tournaments (user_id, name, size, status, draw_mode, format, started_at)
	values (v_user_id, v_name, 64, 'active', 'random', 'swiss', now())
	returning id into v_tournament_id;

	insert into tournament_teams (tournament_id, team_id, seed_position)
	select v_tournament_id, team_id, ord
	from unnest(v_ordered_ids) with ordinality as u(team_id, ord);

	for v_match_number in 1..32 loop
		insert into matches (
			tournament_id, round_number, round_name, match_number, bracket_type,
			team_a_id, team_b_id, status, score_group
		) values (
			v_tournament_id, 1, 'Turno 1', v_match_number, 'swiss',
			v_ordered_ids[(v_match_number - 1) * 2 + 1], v_ordered_ids[(v_match_number - 1) * 2 + 2],
			'ready', '0-0'
		);
	end loop;

	return v_tournament_id;
end;
$$;
