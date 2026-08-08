import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

// Home rimossa su richiesta: si entra direttamente nell'elenco tornei.
export const load: PageServerLoad = async () => {
	throw redirect(303, '/tournaments');
};
