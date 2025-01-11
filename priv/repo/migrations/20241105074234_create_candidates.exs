defmodule Wttj.Repo.Migrations.CreateCandidates do
  use Ecto.Migration

  def change do
    create table(:candidates) do
      add :email, :string, null: false
      add :status, :string, default: "new", null: false
      add :position, :integer, null: false
      add :job_id, references(:jobs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:candidates, [:job_id])
    create unique_index(:candidates, [:job_id, :position, :status])
  end
end
