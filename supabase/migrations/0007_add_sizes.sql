-- 0007_add_sizes.sql
-- Aggiunge le taglie 8 e 16 squadre (prima erano ammesse solo 32 e 64)

alter table tournaments drop constraint if exists tournaments_size_check;
alter table tournaments add constraint tournaments_size_check check (size in (8, 16, 32, 64));

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

	insert into tournaments (user_id, name, size, status, draw_mode, started_at)
	values (v_user_id, p_name, p_size, 'active', p_draw_mode, now())
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
