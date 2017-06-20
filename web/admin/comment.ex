defmodule CaptainFact.ExAdmin.Comment do
  use ExAdmin.Register

  register_resource CaptainFact.Comment do
    index do
      selectable_column()

      column :id
      column :text
      column :approve
      column :is_banned

      column :statement_id
      column :user, fields: [:username]
      column :source, fields: [:url]
      actions()
    end
  end
end
