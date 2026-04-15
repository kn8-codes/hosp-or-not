import { supabase } from './supabase.js';

function requireSupabase() {
	if (!supabase) throw new Error('Supabase env vars are not configured');
	return supabase;
}

export async function getPosts() {
	const { data, error } = await requireSupabase()
		.from('posts')
		.select(`
			id,
			photo_url,
			description,
			exif_verified,
			status,
			created_at,
			votes(vote)
		`)
		.order('exif_verified', { ascending: false })
		.order('created_at', { ascending: false });

	if (error) throw error;
	return data;
}

export async function getPost(id) {
	const { data, error } = await requireSupabase()
		.from('posts')
		.select(`
			*,
			votes(id, vote, blurb, created_at)
		`)
		.eq('id', id)
		.single();

	if (error) throw error;
	return data;
}

export async function createPost({ photoFile, description, exifVerified, exifData }) {
	const client = requireSupabase();
	const ext = photoFile.name.split('.').pop();
	const filename = `${crypto.randomUUID()}.${ext}`;

	const { error: uploadError } = await client.storage
		.from('photos')
		.upload(filename, photoFile);

	if (uploadError) throw uploadError;

	const {
		data: { publicUrl }
	} = client.storage.from('photos').getPublicUrl(filename);

	const { data, error } = await client
		.from('posts')
		.insert({
			photo_url: publicUrl,
			description,
			exif_verified: exifVerified,
			exif_data: exifData
		})
		.select('id')
		.single();

	if (error) throw error;
	return data.id;
}

export async function closePost(id, outcome) {
	const { error } = await requireSupabase()
		.from('posts')
		.update({
			status: 'closed',
			outcome: outcome || null,
			closed_at: new Date().toISOString()
		})
		.eq('id', id);

	if (error) throw error;
}
