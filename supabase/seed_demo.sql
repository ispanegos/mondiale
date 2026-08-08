-- seed_demo.sql
-- Dati demo SOLO per sviluppo locale. Non eseguire in produzione.
-- Richiede un utente autenticato di test: sostituisci :demo_user_id
-- Esempio: psql ... -v demo_user_id="'00000000-0000-0000-0000-000000000000'"

do $$
declare
	v_user_id uuid := :demo_user_id;
	v_team_ids uuid[];
	v_tournament_id uuid;
	v_match record;
begin
	select array_agg(id order by random()) into v_team_ids from teams limit 32;
	select array_agg(id) into v_team_ids from (select id from teams order by random() limit 32) s;

	-- torneo attivo con alcune partite completate
	perform set_config('request.jwt.claim.sub', v_user_id::text, true);
	v_tournament_id := create_tournament('Torneo Demo 32', 32, 'random', v_team_ids);

	for v_match in
		select id, team_a_id, team_b_id
		from matches
		where tournament_id = v_tournament_id and round_number = 1
		order by match_number
		limit 8
	loop
		perform select_match_winner(v_match.id, v_match.team_a_id);
	end loop;

	-- secondo torneo, completato interamente, per popolare albo d'oro e classifica
	select array_agg(id) into v_team_ids from (select id from teams order by random() limit 32) s;
	v_tournament_id := create_tournament('Coppa Demo Passata', 32, 'random', v_team_ids);

	while exists (
		select 1 from matches
		where tournament_id = v_tournament_id and status = 'ready'
	) loop
		for v_match in
			select id, team_a_id from matches
			where tournament_id = v_tournament_id and status = 'ready'
		loop
			perform select_match_winner(v_match.id, v_match.team_a_id);
		end loop;
	end loop;

	perform complete_tournament(v_tournament_id);
end $$;
