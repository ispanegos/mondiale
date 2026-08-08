-- 0006_uk_flags.sql
-- Inghilterra, Scozia, Galles e Irlanda del Nord non hanno una bandiera
-- unicode ufficiale affidabile su tutti i dispositivi: usiamo un'immagine
-- SVG reale (libreria open-source flag-icons) al posto dell'emoji.

update teams set flag_url = 'https://cdn.jsdelivr.net/npm/flag-icons@7/flags/4x3/gb-eng.svg'
where slug = 'inghilterra';

update teams set flag_url = 'https://cdn.jsdelivr.net/npm/flag-icons@7/flags/4x3/gb-sct.svg'
where slug = 'scozia';

update teams set flag_url = 'https://cdn.jsdelivr.net/npm/flag-icons@7/flags/4x3/gb-wls.svg'
where slug = 'galles';

update teams set flag_url = 'https://cdn.jsdelivr.net/npm/flag-icons@7/flags/4x3/gb-nir.svg'
where slug = 'irlanda-del-nord';
