defmodule CF.Actions.ValidatorBase do
  @moduledoc """
  Define macros and functions to specify `Validator` rules in a clean way. Do
  not use this module directly !
  """

  # Define check functions in __using__ so we can later use them in macros
  defmacro __using__(_) do
    quote do
      require Logger
      import CF.Actions.ValidatorBase
      alias DB.Schema.UserAction

      @doc """
      Check all actions from DB.

      Returns a list of errors like [{action, errors}, ...]. Only returns the
      actions for which errors list is not empty
      """
      @spec check_all() :: list(String.t())
      def check_all() do
        UserAction
        |> DB.Repo.all()
        |> Enum.map(&check_action/1)
        |> Enum.filter(&(!match?({_, []}, &1)))
      end

      @doc """
      Check a single action. Returns {action, errors_list}
      """
      def check_action(action = %UserAction{}) do
        {action, []}
        |> do_check_entity_wildcard()
        |> do_check_action_changes()
      end

      defp add_error({action, errors}, message) do
        {action, [message | errors]}
      end

      defp assert(res = {action, _}, is_truthy, message) do
        if is_truthy, do: res, else: add_error(res, message)
      end

      # Ignore if nil changes has error would already be there from previous check
      defp ensure_changes_have_keys(res = {%{changes: nil}, _}, keys),
        do: res

      defp ensure_changes_have_keys(res = {%{changes: changes}, _}, keys) do
        Enum.reduce(keys, res, fn key, res ->
          assert(res, Map.has_key?(changes, key), "Missing key from changes: #{key}")
        end)
      end

      defp reject_changes_unknown_keys(res = {%{changes: nil}, _}, _),
        do: res

      defp reject_changes_unknown_keys(res = {%{changes: changes}, _}, whitelist) do
        changes
        |> Map.keys()
        |> Enum.reduce(res, fn key, res ->
          assert(res, key in whitelist, "Unknow changes key: #{key}")
        end)
      end
    end
  end

  defmacro check_entity_wildcard(entity, keys, opts \\ []) do
    excluded_types = Keyword.get(opts, :exclude, [])

    quote do
      defp do_check_entity_wildcard(
             base = {action = %{entity: unquote(entity), type: type}, errors}
           )
           when type not in unquote(excluded_types) do
        Enum.reduce(unquote(keys), base, fn key, res = {action, _} ->
          assert(res, !is_nil(Map.get(action, key)), "Key #{key} should not be nil")
        end)
      end
    end
  end

  defmacro check_action_changes(entity, type, opts \\ []) do
    has_changes = Keyword.get(opts, :has_changes, true)
    required = Keyword.get(opts, :required, [])
    whitelist = Keyword.get(opts, :whitelist, [])
    full_whitelist = required ++ whitelist
    nil_comparator = if has_changes, do: &Kernel.!=/2, else: &Kernel.==/2

    nil_comparator_error =
      if has_changes, do: "Should have change", else: "Should not have changes"

    quote do
      defp do_check_action_changes(
             res = {%{entity: unquote(entity), type: unquote(type), changes: changes}, _}
           ) do
        res
        |> assert(unquote(nil_comparator).(changes, nil), unquote(nil_comparator_error))
        |> ensure_changes_have_keys(unquote(required))
        |> reject_changes_unknown_keys(unquote(full_whitelist))
      end
    end
  end

  defmacro ignore_others_actions do
    quote do
      defp do_check_entity_wildcard(res),
        do: res

      defp do_check_action_changes(res) do
        # Logger.info("Unchecked action #{inspect(res)}")
        res
      end
    end
  end
end
