defmodule CaptainFact.ExAdmin.Comment do
  use ExAdmin.Register

  register_resource CaptainFact.Comment do
    index do
      selectable_column()

      column :id
      actions()
    end
  end
end
