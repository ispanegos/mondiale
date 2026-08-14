-- 0012_swiss_allow_correction.sql
-- Permette di correggere il risultato di una partita svizzera gia' segnata,
-- ma SOLO finche' il turno a cui appartiene non e' ancora stato chiuso
-- (cioe' finche' il turno successivo non e' ancora stato generato). Una
-- volta che il turno avanza, i risultati di quel turno diventano definitivi:
-- correggerli dopo richiederebbe ricalcolare a cascata tutti i turni
-- successivi gia' generati, e non e' supportato.

create or replace function select_swiss_match_winner(p_match_id uuid, p_winner_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_tournament_id uuid;
	v_round_number integer;
	v_round_name text;
	v_match_id uuid;
	v_team_a uuid;
	v_team_b uuid;
	v_status text;
	v_old_winner uuid;
	v_old_loser uuid;
	v_loser uuid;
	v_remaining integer;
	v_loser_losses integer;
	v_stage_advanced boolean;
	v_reverted_losses integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select mt.tournament_id, mt.round_number, mt.round_name, mt.id, mt.team_a_id, mt.team_b_id,
		mt.status, mt.winner_team_id, mt.loser_team_id
	into v_tournament_id, v_round_number, v_round_name, v_match_id, v_team_a, v_team_b,
		v_status, v_old_winner, v_old_loser
	from matches mt
	join tournaments tr on tr.id = mt.tournament_id
	where mt.id = p_match_id and tr.user_id = v_user_id and mt.bracket_type = 'swiss'
	for update of mt;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if p_winner_team_id is distinct from v_team_a and p_winner_team_id is distinct from v_team_b then
		raise exception 'WINNER_NOT_IN_MATCH';
	end if;

	-- nessuna modifica reale: stessa squadra gia' segnata come vincitrice
	if v_status = 'completed' and v_old_winner = p_winner_team_id then
		return;
	end if;

	if v_status = 'completed' then
		-- il turno e' gia' stato chiuso (turno successivo/finali gia' generati)?
		select exists (
			select 1 from matches
			where tournament_id = v_tournament_id
			and (
				(bracket_type = 'swiss' and round_number > v_round_number)
				or bracket_type = 'main'
			)
		) into v_stage_advanced;

		if v_stage_advanced then
			raise exception 'ROUND_ALREADY_ADVANCED: il turno e'' gia'' stato chiuso e il successivo generato, non e'' piu'' possibile correggere questa partita';
		end if;

		-- annulla il risultato precedente prima di applicare quello nuovo
		update tournament_teams set swiss_wins = swiss_wins - 1
		where tournament_id = v_tournament_id and team_id = v_old_winner;

		update tournament_teams
		set swiss_losses = swiss_losses - 1
		where tournament_id = v_tournament_id and team_id = v_old_loser
		returning swiss_losses into v_reverted_losses;

		update tournament_teams
		set swiss_eliminated = (v_reverted_losses >= 2),
			swiss_eliminated_round = case when v_reverted_losses >= 2 then swiss_eliminated_round else null end
		where tournament_id = v_tournament_id and team_id = v_old_loser;

		delete from point_events where match_id = v_match_id and event_type = 'match_win';
	end if;

	v_loser := case when p_winner_team_id = v_team_a then v_team_b else v_team_a end;

	update matches
	set winner_team_id = p_winner_team_id, loser_team_id = v_loser, status = 'completed', played_at = now()
	where id = v_match_id;

	update tournament_teams set swiss_wins = swiss_wins + 1
	where tournament_id = v_tournament_id and team_id = p_winner_team_id;

	update tournament_teams
	set swiss_losses = swiss_losses + 1
	where tournament_id = v_tournament_id and team_id = v_loser
	returning swiss_losses into v_loser_losses;

	update tournament_teams
	set swiss_eliminated = (v_loser_losses >= 2),
		swiss_eliminated_round = case when v_loser_losses >= 2 then v_round_number else null end
	where tournament_id = v_tournament_id and team_id = v_loser;

	insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, metadata)
	values (v_user_id, v_tournament_id, p_winner_team_id, v_match_id, 'match_win', 3, jsonb_build_object('round_name', v_round_name))
	on conflict (match_id, team_id) where event_type = 'match_win' do nothing;

	select count(*) into v_remaining
	from matches
	where tournament_id = v_tournament_id and bracket_type = 'swiss' and round_number = v_round_number and status <> 'completed';

	if v_remaining = 0 then
		perform advance_swiss_stage(v_tournament_id, v_round_number);
	end if;
end;
$$;
