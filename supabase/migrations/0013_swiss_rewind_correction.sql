-- 0013_swiss_rewind_correction.sql
-- Nuova funzione: correct_swiss_match_and_rewind. Permette di correggere il
-- vincitore di una partita svizzera anche se il turno a cui appartiene e'
-- gia' stato chiuso (turno successivo gia' generato). A differenza della
-- correzione "semplice" di select_swiss_match_winner (che funziona solo se
-- il turno e' ancora aperto), questa:
--
--   1. Cancella tutto cio' che viene DOPO il turno corretto: turni svizzeri
--      successivi ed eventuale tabellone finale (semifinali/finale/3°-4°),
--      con relativi punti (il cascade su point_events/match_bonuses e'
--      automatico via foreign key).
--   2. Applica il nuovo vincitore alla partita corretta.
--   3. Ricalcola da zero vittorie/sconfitte/eliminazioni di TUTTE le
--      squadre rigiocando in ordine tutte le partite svizzere rimaste.
--   4. Rigenera il turno successivo (o le finali) esattamente come se il
--      turno corretto fosse appena stato completato ora.
--
-- Se il torneo era gia' stato dichiarato completo, lo riporta attivo e
-- azzera il podio (dovrai chiuderlo di nuovo alla fine).

create or replace function correct_swiss_match_and_rewind(p_match_id uuid, p_winner_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
	v_user_id uuid := auth.uid();
	v_tournament_id uuid;
	v_round_number integer;
	v_team_a uuid;
	v_team_b uuid;
	v_bracket_type text;
	v_new_loser uuid;
	rec record;
	v_loser_losses integer;
	v_remaining integer;
begin
	if v_user_id is null then
		raise exception 'AUTH_REQUIRED' using errcode = '28000';
	end if;

	select mt.tournament_id, mt.round_number, mt.team_a_id, mt.team_b_id, mt.bracket_type
	into v_tournament_id, v_round_number, v_team_a, v_team_b, v_bracket_type
	from matches mt
	join tournaments tr on tr.id = mt.tournament_id
	where mt.id = p_match_id and tr.user_id = v_user_id and tr.format = 'swiss'
	for update of mt;

	if not found then
		raise exception 'MATCH_NOT_FOUND_OR_FORBIDDEN';
	end if;

	if v_bracket_type <> 'swiss' then
		raise exception 'NOT_A_SWISS_STAGE_MATCH: questa partita fa parte delle finali, correggila dalla schermata normale';
	end if;

	if p_winner_team_id is distinct from v_team_a and p_winner_team_id is distinct from v_team_b then
		raise exception 'WINNER_NOT_IN_MATCH';
	end if;

	-- 1. elimina tutto cio' che viene dopo questo turno (cascade automatico
	--    su point_events e match_bonuses grazie alle foreign key)
	delete from matches
	where tournament_id = v_tournament_id
	and (
		(bracket_type = 'swiss' and round_number > v_round_number)
		or bracket_type in ('main', 'third_place')
	);

	update tournaments
	set champion_team_id = null, runner_up_team_id = null, third_team_id = null, fourth_team_id = null,
		status = 'active', completed_at = null
	where id = v_tournament_id;

	delete from point_events
	where tournament_id = v_tournament_id and event_type = 'placement_bonus';

	update tournament_teams
	set final_position = null, placement_points = 0
	where tournament_id = v_tournament_id;

	-- 2. applica il nuovo vincitore alla partita corretta (i bonus non si toccano)
	v_new_loser := case when p_winner_team_id = v_team_a then v_team_b else v_team_a end;

	update matches
	set winner_team_id = p_winner_team_id, loser_team_id = v_new_loser, status = 'completed', played_at = now()
	where id = p_match_id;

	delete from point_events where match_id = p_match_id and event_type = 'match_win';

	insert into point_events (user_id, tournament_id, team_id, match_id, event_type, points, metadata)
	values (v_user_id, v_tournament_id, p_winner_team_id, p_match_id, 'match_win', 3, '{}'::jsonb);

	-- 3. ricalcola da zero vittorie/sconfitte/eliminazioni rigiocando in
	--    ordine tutte le partite svizzere rimaste (turno corretto incluso)
	update tournament_teams
	set swiss_wins = 0, swiss_losses = 0, swiss_eliminated = false, swiss_eliminated_round = null, swiss_bye = false
	where tournament_id = v_tournament_id;

	for rec in
		select round_number, winner_team_id, loser_team_id
		from matches
		where tournament_id = v_tournament_id and bracket_type = 'swiss' and status = 'completed'
		order by round_number, match_number
	loop
		update tournament_teams set swiss_wins = swiss_wins + 1
		where tournament_id = v_tournament_id and team_id = rec.winner_team_id;

		update tournament_teams
		set swiss_losses = swiss_losses + 1
		where tournament_id = v_tournament_id and team_id = rec.loser_team_id
		returning swiss_losses into v_loser_losses;

		update tournament_teams
		set swiss_eliminated = (v_loser_losses >= 2),
			swiss_eliminated_round = case when v_loser_losses >= 2 then rec.round_number else swiss_eliminated_round end
		where tournament_id = v_tournament_id and team_id = rec.loser_team_id;
	end loop;

	-- se il turno 7 esiste ancora (correzione dentro il turno 7 stesso), la
	-- squadra col bye va ri-marcata: e' l'unica rimasta a 0 sconfitte
	if exists (select 1 from matches where tournament_id = v_tournament_id and bracket_type = 'swiss' and round_number = 7) then
		update tournament_teams
		set swiss_bye = true
		where tournament_id = v_tournament_id and swiss_losses = 0 and swiss_eliminated = false;
	end if;

	-- 4. se il turno corretto e' completo, rigenera il turno successivo (o le finali)
	select count(*) into v_remaining
	from matches
	where tournament_id = v_tournament_id and bracket_type = 'swiss' and round_number = v_round_number and status <> 'completed';

	if v_remaining = 0 then
		perform advance_swiss_stage(v_tournament_id, v_round_number);
	end if;
end;
$$;
