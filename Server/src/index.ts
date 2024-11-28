interface RequestBody {
	token: string;
}

interface ResponseBody {
	id: number;
	token: string;
	success: boolean;
}

const InsertStatement = `INSERT
  INTO tokens (id, token, created_at)
  VALUES (?, ?, ?)
  ON CONFLICT (id)
  DO UPDATE SET token = excluded.token, created_at = excluded.created_at;`;

async function readRequestBody(request): RequestBody | null {
	const contentType = request.headers.get('content-type');

	if (contentType.includes('application/json')) {
		let requestBody: RequestBody = await request.json();

		return requestBody;
	}

	return null;
}

export default {
	async fetch(request, env, ctx): Promise<Response> {
		switch (request.method) {
			case 'POST': {
				const requestBody = await readRequestBody(request);

				if (!requestBody) {
					return Response.json({
						id: -1,
						token: '',
						success: false,
					});
				}

				const id = 1000 + (Math.floor(Math.random() * 9000) - 1);
				const now = new Date();
				const insertStatement = env.DB.prepare(InsertStatement).bind(id, requestBody.token, now.toISOString());
				const { success } = await insertStatement.run();

				return Response.json({
					id: id,
					token: requestBody.token,
					success: success,
				});
			}
			case 'GET': {
				const { pathname } = new URL(request.url);
				const id = pathname.slice(1);
				const { results, success } = await env.DB.prepare(`SELECT token FROM tokens WHERE id = ?`).bind(id).all();

				if (results.length < 1) {
					return Response.json({
						id: parseInt(id),
						token: '',
						success: false,
					});
				}

				return Response.json({
					id: parseInt(id),
					token: results[0].token,
					success: success,
				});
			}
			default:
				break;
		}
		return new Response('Hello World!');
	},
} satisfies ExportedHandler<Env>;
