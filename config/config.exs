import Config

# Configure ex_openai to use environment variables
config :ex_openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  # Optional: Use custom base URL if needed
  http_options: [recv_timeout: 60_000]

# Disable HTTPoison debug logging in production
config :logger, level: :info

# You can also set a custom organization ID if needed
# organization_key: System.get_env("OPENAI_ORGANIZATION_ID")
