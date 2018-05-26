
defmodule Flux.UserController do
  use Flux.Web, :controller

  alias Flux.User

  def create(conn, params) do
    changeset = User.registration_changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> Flux.Guardian.Plug.sign_in(user)
        |> render(Flux.UserView, "create.json", user: user)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Flux.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def read(conn, _params) do
    id = Flux.Guardian.Plug.current_resource(conn)

    with {:ok, user} <- user_exists(conn, id), do:
      conn 
      |> put_status(:ok)
      |> render(Flux.UserView, "read.json", user: user)
  end

  def delete(conn, _params) do
    id = Flux.Guardian.Plug.current_resource(conn)

    with {:ok, user} <- user_exists(conn, id), do: 
      Repo.delete(user)
      conn 
      |> put_status(:ok)
      |> render(Flux.UserView, "delete.json")
  end

  def rooms(conn, _params) do
    %{id: id} = Flux.Guardian.Plug.current_resource(conn)
    import Ecto.Query, only: [from: 2]

    query = from r in Flux.Room, 
            join: ur in Flux.UserRoom,
            where: ur.user_id == ^id, where: ur.room_id == r.id,
            select: r

    rooms = Repo.all(query)

    conn 
    |> put_status(:ok)
    |> render(Flux.UserView, "rooms.json", rooms: rooms)
  end

  def user_exists(conn, id) do
    user = Repo.get_by(Flux.User, id)
    case user do
      nil -> 
        conn
        |> put_status(:not_found)
        |> render(Flux.UserView, "not_found.json")
      _ -> {:ok, user}
    end
  end
end