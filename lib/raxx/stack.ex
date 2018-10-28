defmodule Raxx.Stack do
  alias Raxx.Server
  alias Raxx.Middleware

  @behaviour Server

  @enforce_keys [:middlewares, :server]
  defstruct @enforce_keys

  @moduledoc """
  `Raxx.Stack` implements `Raxx.Server` behaviour that works with
  `t:Raxx.Stack.t/0` as its state.
  """

  @typedoc """
  A `t:Raxx.Stack.t/0` represents a pipeline of middlewares attached to a server.

  NOTE: Don't rely on the internal structure of this type. It can be modified
  at an arbitrary moment to improve performance or capabilities.
  """
  # DEBT: compare struct t() performance to a (tagged) tuple implementation
  @opaque t :: %__MODULE__{
            middlewares: [Middleware.t()],
            server: Server.t()
          }

  @type server :: {__MODULE__, t()}

  @spec new([Middleware.t()], Server.t()) :: t()
  def new(middlewares \\ [], server) when is_list(middlewares) do
    %__MODULE__{
      middlewares: middlewares,
      server: server
    }
  end

  def server(stack = %__MODULE__{}) do
    {__MODULE__, stack}
  end

  @spec set_middlewares(t(), [Middleware.t()]) :: t()
  def set_middlewares(stack = %__MODULE__{}, middlewares) when is_list(middlewares) do
    %__MODULE__{stack | middlewares: middlewares}
  end

  @spec set_server(t(), Server.t()) :: t()
  def set_server(stack = %__MODULE__{}, {_, _} = server) do
    %__MODULE__{stack | server: server}
  end

  @spec get_server(t()) :: Server.t()
  def get_server(%__MODULE__{server: server}) do
    server
  end

  @spec get_middlewares(t()) :: [Middleware.t()]
  def get_middlewares(%__MODULE__{middlewares: middlewares}) do
    middlewares
  end

  @spec push_middleware(t(), Middleware.t()) :: t()
  def push_middleware(stack, middleware) do
    middlewares = get_middlewares(stack)

    set_middlewares(stack, [middleware | middlewares])
  end

  @spec pop_middleware(t()) :: {Middleware.t() | nil, t()}
  def pop_middleware(stack) do
    case get_middlewares(stack) do
      [] ->
        {nil, stack}

      [topmost | rest] ->
        new_stack = set_middlewares(stack, rest)
        {topmost, new_stack}
    end
  end

  # NOTE those 4 can be rewritten using macros instead of apply for a minor performance increase
  @impl Server
  def handle_head(request, stack) do
    handle_anything(request, stack, :handle_head, :process_head)
  end

  @impl Server
  def handle_data(data, stack) do
    handle_anything(data, stack, :handle_data, :process_data)
  end

  @impl Server
  def handle_tail(tail, stack) do
    handle_anything(tail, stack, :handle_tail, :process_tail)
  end

  @impl Server
  def handle_info(message, stack) do
    handle_anything(message, stack, :handle_info, :process_info)
  end

  defp handle_anything(input, stack, server_function, middleware_function) do
    case pop_middleware(stack) do
      {nil, ^stack} ->
        # time for the inner server to handle input
        server = get_server(stack)
        {parts, new_server} = apply(Server, server_function, [server, input])

        new_stack = set_server(stack, new_server)
        {parts, new_stack}

      {middleware, smaller_stack} ->
        # the top middleware was popped off the stack
        {middleware_module, middleware_state} = middleware

        {parts, middleware_state, {__MODULE__, smaller_stack}} =
          apply(middleware_module, middleware_function, [
            input,
            middleware_state,
            {__MODULE__, smaller_stack}
          ])

        new_stack = push_middleware(smaller_stack, {middleware_module, middleware_state})
        {parts, new_stack}
    end
  end
end
