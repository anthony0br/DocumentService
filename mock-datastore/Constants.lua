return {
	MAX_NAME_LENGTH = 50,
	MAX_SCOPE_LENGTH = 50,
	MAX_KEY_LENGTH = 50,

	MAX_THROTTLE_QUEUE_SIZE = 30, -- The amount of requests that can be throttled per request type at once before the request will error.

	BUDGET_UPDATE_INTERVAL = 1,

	GET_CACHE_DURATION = 4,

	REQUEST_BUDGETS = {
		[0] = {
			INITIAL_BUDGET = 100,
			RATE = 60,
			RATE_PER_PLAYER = 10,
			MAX_BUDGET_FACTOR = 3,
		},

		[1] = {
			INITIAL_BUDGET = 100,
			RATE = 60,
			RATE_PER_PLAYER = 10,
			MAX_BUDGET_FACTOR = 3,
		},

		[4] = {
			INITIAL_BUDGET = 50,
			RATE = 30,
			RATE_PER_PLAYER = 5,
			MAX_BUDGET_FACTOR = 3,
		},

		[5] = {
			INITIAL_BUDGET = 30,
			RATE = 30,
			RATE_PER_PLAYER = 5,
			MAX_BUDGET_FACTOR = 1,
		},

		[3] = {
			INITIAL_BUDGET = 10,
			RATE = 5,
			RATE_PER_PLAYER = 2,
			MAX_BUDGET_FACTOR = 3,
		},
	},
}
