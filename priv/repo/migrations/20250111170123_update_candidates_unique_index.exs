defmodule Wttj.Repo.Migrations.UpdateCandidateUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:candidates, [:job_id, :position, :status])
    create unique_index(:candidates, [:id, :job_id, :position, :status])
  end
end
