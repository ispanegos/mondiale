import type { PageServerLoad } from './$types';
import { listHallOfFame, listAllTeams } from '$lib/server/tournaments';

export const load: PageServerLoad = async ({ locals }) => {
	const [tournaments, teams] = await Promise.all([listHallOfFame(locals.supabase), listAllTeams(locals.supabase)]);

	const teamsById = new Map(teams.map((t) => [t.id, t]));

	const mostTitled = [...teamsById.values()]
		.map((team) => ({ team, titles: tournaments.filter((t) => t.champion_team_id === team.id).length }))
		.filter((e) => e.titles > 0)
		.sort((a, b) => b.titles - a.titles)[0];

	const mostFinals = [...teamsById.values()]
		.map((team) => ({
			team,
			finals: tournaments.filter((t) => t.champion_team_id === team.id || t.runner_up_team_id === team.id).length
		}))
		.filter((e) => e.finals > 0)
		.sort((a, b) => b.finals - a.finals)[0];

	const mostPodiums = [...teamsById.values()]
		.map((team) => ({
			team,
			podiums: tournaments.filter(
				(t) => t.champion_team_id === team.id || t.runner_up_team_id === team.id || t.third_team_id === team.id
			).length
		}))
		.filter((e) => e.podiums > 0)
		.sort((a, b) => b.podiums - a.podiums)[0];

	return {
		tournaments,
		teamsById: Object.fromEntries(teamsById),
		mostTitled: mostTitled ?? null,
		mostFinals: mostFinals ?? null,
		mostPodiums: mostPodiums ?? null,
		mostRecent: tournaments[0] ?? null
	};
};
