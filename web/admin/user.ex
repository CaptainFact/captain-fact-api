defmodule CaptainFact.ExAdmin.User do
  use ExAdmin.Register

  register_resource CaptainFact.User do
    index do
      selectable_column()

      column :id
      column :username
      column :name
      column :email
      column :inserted_at
      column :updated_at
      actions()
    end

    form user do
      inputs do
        input user, :username
        input user, :name
        input user, :email
        input user, :password, type: :password
        input user, :passwordRepeat, type: :password, label: "Repeat password"
      end
    end
  end
end
