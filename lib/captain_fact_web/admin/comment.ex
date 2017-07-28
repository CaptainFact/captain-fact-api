defmodule CaptainFactWeb.ExAdmin.Comment do
  use ExAdmin.Register

  register_resource CaptainFactWeb.Comment do
    index do
      selectable_column()

      column :id
      column :text
      column :approve

      column :user, fields: [:username]
      column :statement_id
      column :reply_to_id
      column :source, fields: [:url]

      column :is_banned
      actions()
    end
  end
end
