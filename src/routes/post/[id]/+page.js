import { getPost } from '$lib/posts.js';
import { error } from '@sveltejs/kit';

export async function load({ params }) {
	const post = await getPost(params.id).catch(() => null);
	if (!post) error(404, 'Case not found');
	return { post };
}
